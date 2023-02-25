require 'fileutils'
require_relative 'global_settings'
require_relative 'utilities'

def retrieve_script_list(matrix_list)
  all_scripts = []

  Dir.chdir(TEST_SCRIPTS_ROOT) do
    matrix_list.each do |matrix|
      matrix_scripts = []
      matrix_file_name = "./" + matrix["matrix_file_name"].gsub(/\*\*/,'')
      print "Retrieving test scripts from '#{File.basename(matrix_file_name)}'"

      matrix_file_content = File.read(matrix_file_name)

      # Define the regular expression to match a class definition that inherits from the named class
      class_regex = /class\s+(\w+)\s+<\s+#{Regexp.escape('SonoSiteTestMatrix::Matrix')}/m

      # Find all matches of the regular expression in the source file
      class_matches = matrix_file_content.scan(class_regex)

      # Loop through the matches and extract the lines of the specified method from each class
      class_matches.each do |class_match|
        class_name = class_match[0]
        method_regex = /def\s+initialize\s*\n(.*?)\nend/m
        method_match = matrix_file_content.match(/class\s+#{Regexp.escape(class_name)}.*?\nend/m)
        if method_match
          method_content = method_match[0]
          method_content = method_content.gsub("@ti_files", "$ti_files")
          method_lines = method_content.scan(method_regex).flatten[0].split("\n")
          ti_references = method_lines.select { |line| line =~ /\$ti_files/}
          eval(ti_references.join(";"))
          matrix_scripts = $ti_files.map { |full_path| {"owner" => matrix["owner"], "job_name" => matrix["job_name"], "script_name" => File.basename(full_path)} }
        end
      end

      puts " found #{matrix_scripts.length} scripts"
      all_scripts += matrix_scripts
    end
  end

  all_scripts
end

def matrix_list_to_script_list(matrix_list_file_name, script_list_file_name)
  if ! Dir.exists? TEST_SCRIPTS_ROOT
    puts "Error: 'test_scripts' directory is set to '#{TEST_SCRIPTS_ROOT}' but does not exist"
    puts "Update the value of constant TEST_SCRIPTS_ROOT in file 'global_settings.rb'"
    exit 1
  end
  matrix_list = read_csv_file(matrix_list_file_name)
  script_list = retrieve_script_list(matrix_list)
  write_csv_file(script_list_file_name, script_list)
end

if __FILE__ == $0
  matrix_list_to_script_list( MATRIX_LIST, SCRIPT_LIST)
end

