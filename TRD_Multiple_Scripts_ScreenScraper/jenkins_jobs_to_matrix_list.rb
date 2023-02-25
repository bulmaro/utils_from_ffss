require 'selenium-webdriver'
require_relative 'global_settings'
require_relative 'jenkins_credentials'
require_relative 'utilities'

# Read all the matrix file names from the jenkins job configuration pages
def retrieve_matrix_list(jenkins_jobs_list)
  driver = Selenium::WebDriver.for :firefox

  # Login
  driver.navigate.to "#{JENKINS_SERVER_URL}/login"
  driver.find_element(:xpath, "//*[@id='j_username']").send_keys JENKINS_USER_ID
  driver.find_element(:xpath, "/html/body/div/div/form/div[2]/input").send_keys JENKINS_PASSWORD
  driver.find_element(:xpath, "/html/body/div/div/form/div[3]/input").click

  matrix_list = []
  jenkins_jobs_list.each do |job|
    # Get URL
    job_config_url = "#{JENKINS_SERVER_URL}/job/#{job['job_name'].strip}/configure"
    # Navigate to job page
    driver.navigate.to job_config_url
    # Read matrix file name
    matrix_label_locator = "//input[@type='text' and contains(@value, 'MATRIX_NAME')]"
    matrix_label_element = driver.find_element(:xpath, matrix_label_locator)
    matrix_value_element = matrix_label_element.find_element(:xpath, "../../..").find_element(:name, "parameter.defaultValue")
    matrix_file_name = matrix_value_element.attribute('value')
    # Add
    matrix_list << {"owner" => job["owner"], "job_name" => job["job_name"], "matrix_file_name" => matrix_file_name}

    puts "Getting matrix file for job '#{job["job_name"]}': '#{matrix_file_name}'"
  end

  driver.quit

  matrix_list
end

# Main task implementation
def jenkins_jobs_to_matrix_list(jenkins_jobs_file_name, matrix_list_file_name)
  jenkins_jobs_list = read_csv_file(jenkins_jobs_file_name)
  matrix_list = retrieve_matrix_list(jenkins_jobs_list)
  write_csv_file(matrix_list_file_name, matrix_list)
end

if __FILE__ == $0
  jenkins_jobs_to_matrix_list(JENKINS_JOB_LIST, MATRIX_LIST)
end
