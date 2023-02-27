require_relative 'global_settings'
require 'fileutils'

def create_all_results_file_timestamped
  filename_with_ext = File.basename(RESULTS_ALL)
  filename_without_ext = File.basename(filename_with_ext, '.*')
  ext = File.extname(filename_with_ext)
  now_timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  filename_timestamped = "#{filename_without_ext}_#{now_timestamp}#{ext}"
  Dir.chdir(RESULTS_FILE_LOCATION) do
    puts "Making a copy of '#{filename_with_ext}' named '#{filename_timestamped}'"
    FileUtils.cp(filename_with_ext, filename_timestamped)
  end
end
