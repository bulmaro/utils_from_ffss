require 'nokogiri'
require 'open-uri'
require 'fileutils'
require_relative 'global_settings'
require_relative 'utilities'

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
  print "Retrieving results from '#{TRD_ROOT_URL}'"
  # Set the maximum age for a result
  today = Time.now.to_date
  starting_from = today - days_ago
  puts " from last #{days_ago} days (#{starting_from} - #{today})"

  # Fields we want to extract from table
  field_names_on_page = %w[product bom build start_time result failure_reasons name]
  field_names_on_file = %w[prod_type bom version time_stamp result reasons link]
  default_values = %w[_ _ _ _ _ n/a _]
  extra_field_names_on_file = %w[analyzed_on jira_bug_link]

  # Visit the 'results page' for all scripts
  script_results = []
  scripts.each do |script|
    print "Retrieving results for '#{script["script_name"]}' (from Jenkins job '#{script["job_name"]}')"

    # build the URL for the TRD query
    trd_results_url = "#{TRD_ROOT_URL}/script_results?script_path=#{script["script_name"]}&start_date=#{starting_from}"
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
          value = TRD_ROOT_URL + get_field_link(result_info, field_name_on_page)
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
def write_results_to_csv_file(file_name, script_results)
  all_results = []
  script_results.each do |script_result|
    result_header = script_result.reject { |k,v| k == "results" }
    script_result["results"].each do |result_detail|
      all_results << result_header.merge(result_detail)
    end
  end

  write_csv_file(file_name, all_results)

  puts "Generated '#{file_name}' (referencing #{script_results.size} scripts, totaling #{all_results.length} results)"
end

# Main task implementation
def test_results_from_script_list(script_list_file_name, days_ago)
  this_dir = Dir.pwd
  Dir.chdir(DATA_FILE_LOCATION)
  # Read the script list
  script_list = read_csv_file(script_list_file_name)
  # Read the results from TRD
  results_all = get_results(script_list, days_ago)
  # Filter some results
  results_always_passing = select_with_result(results_all, "pass")
  results_always_failing = select_with_result(results_all, "fail") # could be "fail|aborted|unrun"
  results_inconsistent = results_all - results_always_passing - results_always_failing
  Dir.chdir(this_dir)

  # Generate result files
  FileUtils.mkdir_p(RESULTS_FILE_LOCATION)
  Dir.chdir(RESULTS_FILE_LOCATION) do
    write_results_to_csv_file("for_all_scripts.csv", results_all)
    write_results_to_csv_file("for_scripts_always_passing.csv", results_always_passing)
    write_results_to_csv_file("for_scripts_always_failing.csv", results_always_failing)
    write_results_to_csv_file("for_scripts_inconsistently_failing.csv", results_inconsistent)
  end
end

if __FILE__ == $0
  days_ago = (ARGV[0] || DEFAULT_DAYS_AGO).to_i
  test_results_from_script_list(SCRIPT_LIST, days_ago)
end
