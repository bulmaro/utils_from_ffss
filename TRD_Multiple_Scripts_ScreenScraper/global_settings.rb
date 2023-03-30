require 'dotenv/load'

TRD_ROOT_URL = "http://phx-test-results.sonosite.com"
JENKINS_SERVER_URL = "http://sweng-jenkins.sonosite.com:8080/"
TEST_SCRIPTS_ROOT = 'C:\Users\bulmaro.herrera\work\test_scripts_1'
RESULTS_FILE_LOCATION = "results"
DATA_FILE_LOCATION = "data"
DEFAULT_DAYS_AGO = 30
JENKINS_JOB_LIST = "jenkins_jobs_list.csv"
MATRIX_LIST = "matrix_list.csv"
SCRIPT_LIST = "script_list.csv"
RESULTS_ALL = "for_all_scripts.csv"
RESULTS_SCRIPTS_ALWAYS_PASSING = "for_scripts_always_passing.csv"
RESULTS_SCRIPTS_ALWAYS_FAILING = "for_scripts_always_failing.csv"
RESULTS_SCRIPTS_INCONSISTENTLY_FAILING = "for_scripts_inconsistently_failing.csv"
JENKINS_USER_ID = ENV["JENKINS_USER_ID"]
JENKINS_PASSWORD = ENV["JENKINS_PASSWORD"]

if JENKINS_USER_ID.nil? || JENKINS_PASSWORD.nil?
  puts(
    '
  Make sure to create a file named ".env" with content:

  JENKINS_USER_ID="first.last"
  JENKINS_PASSWORD="*******"

  The file is ignored by git (as seen in .gitignore)
  ')
  exit
end
