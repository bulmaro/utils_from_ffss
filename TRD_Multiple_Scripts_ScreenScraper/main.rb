require 'nokogiri'
require 'open-uri'
require 'date'

# Get the script list from a file
def read_script_list(file_name)
  scripts = []
  File.open(file_name, "r") do |file|
    file.each_line do |line|
      next if line.strip.empty?
      fields = line.split(" ")
      scripts << { :owner => fields[0], :job => fields[1], :script_name => fields[2] }
    end
  end
  scripts
end

# Extract a field by name
def get_field_value(result_info, field_name)
  field = result_info.at_css("[id=#{field_name}]")
  # Remove leading & trailing spaces, tabs & new lines, multiple contiguous spaces and HTML tags
  field.inner_html.strip.gsub(/[\n\t]/, '').gsub(/\s+/, ' ').gsub(/<\/?[^>]*>/, '')
end

# Read all the results for all the 'scripts'
def get_results(scripts, days_ago)
  # Set the maximum age for a result
  today = Time.now.to_date
  starting_from_date = today - days_ago
  puts "Retrieving results from last #{days_ago} days (from #{starting_from_date} to #{today})"

  # TRD root
  trd_root_url = "http://phx-test-results.sonosite.com"

  # Visit the 'results page' for all scripts
  script_results = []
  scripts.each do |script|
    print "Retrieving results for '#{script[:script_name]}' (from Jenkins job '#{script[:job]}')"

    # build the URL for the TRD query
    trd_results_url = "#{trd_root_url}/script_results?script_path=#{script[:script_name]}"
    # navigate to the page and get the HTML content
    page_content = Nokogiri::HTML(open(trd_results_url))
    # extract the table
    results_table = page_content.css('#script_results').first

    # Initialize the 'script result' hash with same fields as the 'script'
    script_result = script.clone

    # Select recent results from the table
    results = []
    results_table.xpath('.//tr').each do |result_row|
      result_info = result_row.css('td')
      time_stamp = DateTime.parse(get_field_value(result_info, "start_time"))
      if time_stamp.to_date >= starting_from_date
        # Extract certain fields from the current 'result'
        result = {}
        result["product"] = get_field_value(result_info, "product")
        result["bom"] = get_field_value(result_info, "bom")
        result["sw_ver"] = get_field_value(result_info, "build")
        result["time_stamp"] = time_stamp.to_s
        result["result"] = get_field_value(result_info, "result")
        failure_reason = get_field_value(result_info, "failure_reasons")
        result["reason"] = (failure_reason.empty? ? "n/a" : failure_reason)
        result["detail_link"] = "#{trd_root_url}#{result_info.at_css("[id=#{'name'}]").inner_html.match(/href="([^"]+)"/)[1]}"
        results << result
      end
    end

    puts " - #{results.size} results"

    script_result["results"] = results
    script_results << script_result
  end

  script_results
end

# Select results that ALL have the expected result
def select_with_result(script_results, expected_result)
  script_results.select do |script_result|
    selected = true
    script_result["results"].each do |result|
      selected &= (result["result"] =~ /#{expected_result}/)
    end
    selected
  end
end

# Dump the results on a CSV file
def generate_csv_file(file_name, script_results)
  File.open(file_name, "w" ) do |file|
    total_results = 0

    if script_results.length > 0
      # Generate header using first result's keys
      header = script_results.first
      file.write("#{(header.keys[0...-1] | header['results'].first.keys).join(',')}\n")

      # Write each result
      script_results.each do |script_result|
        results = script_result["results"]
        results.each do |result|
          file.write("#{(script_result.values[0...-1] | result.values).join(",")}\n")
        end
        total_results += results.size
      end
    end

    puts "Generated '#{file_name}' (referencing #{script_results.size} scripts, with #{total_results} results)"
  end
end

# Read the script list
script_list = read_script_list("script_list.txt")

# Read the results from TRD
days_ago = (ARGV.size == 0 ? 30 : ARGV[0].to_i)
results_all = get_results(script_list, days_ago)

# Filter some results
results_always_passing = select_with_result(results_all, "pass")
results_always_failing = select_with_result(results_all, "fail") # could be "fail|aborted|unrun"
results_inconsistent = results_all - results_always_passing - results_always_fail_failing

# Generate result files
results_file_location = "results"
FileUtils.mkdir_p(results_file_location)
Dir.chdir(results_file_location) do
  generate_csv_file("for_all_scripts.csv", results_all)
  generate_csv_file("for_scripts_always_passing.csv", results_always_passing)
  generate_csv_file("for_scripts_always_failing.csv", results_always_failing)
  generate_csv_file("for_scripts_inconsistently_failing.csv", results_inconsistent)
end
