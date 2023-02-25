require 'nokogiri'
require 'open-uri'
require 'date'

# Get the script list from a file
def read_script_list(file_name)
  script_list_field_names = [:owner, :job, :script_name]

  scripts = []
  File.open(file_name, "r") do |file|
    file.each_line do |line|
      next if line.strip.empty?
      # Add a hash of pairs, where for each pair, the key is the field name, and the value is field value
      values = line.split(" ")
      script = {}
      script_list_field_names.each_index do |index|
        script[script_list_field_names[index]] = values[index]
      end
      scripts << script
    end
  end

  scripts
end

# Extract the value (from inner_html) from a cell by field_name
def get_field_value(result_info, field_name)
  field = result_info.at_css("[id=#{field_name}]").inner_html
  # Remove tabs & new lines, multiple contiguous spaces and HTML tags
  field.gsub(/[\n\t]/, '').gsub(/\s+/, ' ').gsub(/<\/?[^>]*>/, '').strip
end

# Extract the link from a cell by field_name
def get_field_link(result_info, field_name)
  "#{result_info.at_css("[id=#{field_name}]").inner_html.match(/href="([^"]+)"/)[1]}"
end

# Read all the results for all the 'scripts'
def get_results(scripts, days_ago)
  # Set the maximum age for a result
  today = Time.now.to_date
  starting_from = today - days_ago
  puts "Retrieving results from last #{days_ago} days (from #{starting_from} to #{today})"

  # TRD root
  trd_root_url = "http://phx-test-results.sonosite.com"

  # Fields we want to extract from table
  field_names_on_page = %w[product bom build start_time result failure_reasons name]
  field_names_on_file = %w[prod_type bom version time_stamp result reasons link]
  default_values = %w[_ _ _ _ _ n/a _]
  extra_field_names_on_file = %w[analyzed_on jira_bug_link]

  # Visit the 'results page' for all scripts
  script_results = []
  scripts.each do |script|
    print "Retrieving results for '#{script[:script_name]}' (from Jenkins job '#{script[:job]}')"

    # build the URL for the TRD query
    trd_results_url = "#{trd_root_url}/script_results?script_path=#{script[:script_name]}&start_date=#{starting_from}"
    # navigate to the page and get the HTML content
    page_content = Nokogiri::HTML(open(trd_results_url))
    # extract the table
    results_table = page_content.css('#script_results').first

    # Select recent results from the table
    results = []
    results_table.xpath('.//tr').each do |result_row|
      result_info = result_row.css('td')
      # Extract selected fields from the current 'result_info'
      result = {}
      field_names_on_page.length.times do |i|
        field_name_on_page = field_names_on_page[i]
        if field_name_on_page == "name"
          value = trd_root_url + get_field_link(result_info, field_name_on_page)
        else
          value = get_field_value(result_info, field_name_on_page)
        end
        result[field_names_on_file[i]] = value.empty? ? default_values[i] : value
      end
      extra_field_names_on_file.each do |extra_field_name_on_file|
        result[extra_field_name_on_file] = "TBD"
      end
      results << result
    end

    puts " - #{results.size} results"

    script_result = script.clone
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
      file.write("#{(header.keys[0...-1] + header['results'].first.keys).join(',')}\n")

      # Write each result
      script_results.each do |script_result|
        results = script_result["results"]
        results.each do |result|
          file.write("#{(script_result.values[0...-1] + result.values).join(",")}\n")
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
days_ago = (ARGV[0] || "30").to_i
results_all = get_results(script_list, days_ago)

# Filter some results
results_always_passing = select_with_result(results_all, "pass")
results_always_failing = select_with_result(results_all, "fail") # could be "fail|aborted|unrun"
results_inconsistent = results_all - results_always_passing - results_always_failing

# Generate result files
results_file_location = "results"
FileUtils.mkdir_p(results_file_location)
Dir.chdir(results_file_location) do
  generate_csv_file("for_all_scripts.csv", results_all)
  generate_csv_file("for_scripts_always_passing.csv", results_always_passing)
  generate_csv_file("for_scripts_always_failing.csv", results_always_failing)
  generate_csv_file("for_scripts_inconsistently_failing.csv", results_inconsistent)
end
