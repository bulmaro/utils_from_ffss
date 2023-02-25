require 'csv'
require_relative 'global_settings'

def read_csv_file(file_name)
  elements = []
  FileUtils.mkdir_p(DATA_FILE_LOCATION)
  Dir.chdir(DATA_FILE_LOCATION) do
    CSV.foreach(file_name, headers: true) do |element|
      elements << element.to_h
    end
  end
  elements
end

def write_csv_file(file_name, elements)
  FileUtils.mkdir_p(DATA_FILE_LOCATION)
  Dir.chdir(DATA_FILE_LOCATION) do
    CSV.open(file_name, 'w') do |csv|
      # Write the header row to the CSV file
      csv << elements.first.keys
      # Write each data row to the CSV file
      elements.each do |element|
        csv << element.values
      end
    end
  end
end
