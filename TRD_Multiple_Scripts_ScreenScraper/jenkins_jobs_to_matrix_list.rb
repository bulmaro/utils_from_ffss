require 'selenium-webdriver'
require 'csv'

# Get the script list from a file
def read_jenkins_job_list(file_name)
  field_names = [:owner, :job_name]

  jenkins_jobs = []
  File.open(file_name, "r") do |file|
    is_first = true
    file.each_line do |line|
      if is_first
        is_first = false
        next
      end
      next if line.strip.empty?
      # Add a hash of pairs, where for each pair, the key is the field name, and the value is field value
      values = line.split(",")
      jenkins_job = {}
      field_names.each_index do |index|
        jenkins_job[field_names[index]] = values[index].strip
      end
      jenkins_jobs << jenkins_job
    end
  end

  jenkins_jobs
end

# Read all the matrix file names from the jenkins job configuration pages
def retrieve_matrix_list(jenkins_jobs_list)
  driver = Selenium::WebDriver.for :firefox

  jenkins_server_url = "http://sweng-jenkins.sonosite.com:8080/"

  # Login
  driver.navigate.to "#{jenkins_server_url}/login"
  driver.find_element(:xpath, "//*[@id='j_username']").send_keys "bulmaro.herrera"
  driver.find_element(:xpath, "/html/body/div/div/form/div[2]/input").send_keys "Fuji2com!"
  driver.find_element(:xpath, "/html/body/div/div/form/div[3]/input").click

  matrix_list = []
  jenkins_jobs_list.each do |job|
    # Get URL
    job_config_url = "#{jenkins_server_url}/job/#{job[:job_name]}/configure"
    # Navigate to job page
    driver.navigate.to job_config_url
    # Read matrix file name
    matrix_label_locator = "//input[@type='text' and contains(@value, 'MATRIX_NAME')]"
    matrix_label_element = driver.find_element(:xpath, matrix_label_locator)
    matrix_value_element = matrix_label_element.find_element(:xpath, "../../..").find_element(:name, "parameter.defaultValue")
    matrix_file_name = matrix_value_element.attribute('value')
    # Add
    matrix_list << {:owner => job[:owner], :matrix_file_name => matrix_file_name}
  end

  driver.quit

  matrix_list
end

# Create CSV file
def write_matrix_file(matrix_file_name_list, matrix_list_file_name)
  CSV.open(matrix_list_file_name, 'w') do |csv|

    # Write the header row to the CSV file
    csv << matrix_file_name_list.first.keys

    # Write each data row to the CSV file
    matrix_file_name_list.each do |matrix_file_name|
      csv << matrix_file_name.values
    end
  end
end

# Main task implementation
def jenkins_jobs_to_matrix_list(jenkins_jobs_file_name, matrix_list_file_name)
  jenkins_jobs_list = read_jenkins_job_list(jenkins_jobs_file_name)
  matrix_list = retrieve_matrix_list(jenkins_jobs_list)
  write_matrix_file(matrix_list, matrix_list_file_name)
end

if __FILE__ == $0
  jenkins_jobs_to_matrix_list("jenkins_jobs_list.csv", "matrix_list.csv")
end
