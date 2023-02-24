require 'nokogiri'
require 'open-uri'
require 'date'

# Get the script list from a file
def read_script_list(file_name)
  scripts = []
  File.open(file_name, "r") do |file|
    file.each_line do |line|
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
DAYS_AGO = 30 # from these last days
def get_results(scripts)
  # Set the maximum age for a result
  starting_from_date = Time.now - (DAYS_AGO * 24 * 60 * 60)

  # TRD root
  trd_root_url = "http://phx-test-results.sonosite.com"

  # Visit the 'results page' for all scripts
  script_results = []
  scripts.each do |script|
    # build the URL for the TRD query
    trd_results_url = "#{trd_root_url}/script_results?script_path=#{script[:script_name]}"
    # navigate to the page and get the HTML content
    doc = Nokogiri::HTML(open(trd_results_url))
    # extract the table
    results_table = doc.css('#script_results').first
    # Initialize the 'script result' hash with same fields as the 'script'
    script_result = script.clone
    # Select recent results from the table
    results = []
    results_table.xpath('.//tr').each do |result_row|
      result_info = result_row.css('td')
      time_stamp = DateTime.parse(get_field_value(result_info, "start_time")).to_time
      if time_stamp > starting_from_date
        # Extract certain fields from the current 'result'
        result = {}
        result["product"] = get_field_value(result_info, "product")
        result["bom"] = get_field_value(result_info, "bom")
        result["sw_ver"] = get_field_value(result_info, "build")
        result["time_stamp"] = time_stamp
        result["result"] = get_field_value(result_info, "result")
        failure_reason = get_field_value(result_info, "failure_reasons")
        result["reason"] = (failure_reason.empty? ? "n/a" : failure_reason)
        result["detail_link"] = "#{trd_root_url}#{result_info.at_css("[id=#{'name'}]").inner_html.match(/href="([^"]+)"/)[1]}"
        results << result
      end
      script_result["results"] = results
    end
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
    file.write("owner,job,script_name,product,bom,sw_ver,time_stamp,pass,reason,detail_link\n")
    script_results.each do |script_result|
      script_result["results"].each do |result|
        file.write("#{script_result[:owner]},#{script_result[:job]},#{script_result[:script_name]},#{result.values.join(",")}\n")
      end
    end
  end
end

# Read the results from TRD
script_list = read_script_list("script_list.txt")
results_all = get_results(script_list)

# Filter some results
results_always_passing = select_with_result(results_all, "pass")
results_always_fail_failing = select_with_result(results_all, "fail") # could be "fail|aborted|unrun"
results_inconsistent = results_all - results_always_passing - results_always_fail_failing

# Generate result files
generate_csv_file("results_all.csv", results_all)
generate_csv_file("results_always_passing.csv", results_always_passing)
generate_csv_file("results_always_failing.csv", results_always_fail_failing)
generate_csv_file("results_inconsistent.csv", results_inconsistent)
