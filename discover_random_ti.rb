require 'pathname'

root_name = Dir.pwd + "/"

Dir.glob("**/*.ti") do |ti_file| # note one extra “*”
  ti_file_info = Pathname.new(ti_file)
  ti_name = File.expand_path ti_file
  ti_dir = ti_file_info.dirname

  Dir.chdir(ti_dir) do
    File.readlines(ti_name).each do |ti_line|
      if ti_line.strip.start_with? 'declare_test_class_require_path'
        require_paths = ti_line.scan(/["']([^"']*)["']/)
        require_paths.each do |require_path|
          require_file = require_path[0]
          random_references = []
          if File.exists? require_file
            line_number = 0
            File.readlines(require_file).each do |ruby_file_line|
              # Check if it contains a call to random function
              if !(ruby_file_line.strip.start_with?('#')) && (ruby_file_line =~ /\b(bytes|seed|new_seed|rand|Random\.new|srand|sample|raw_seed)\b/)
                random_references << [line_number, ruby_file_line]
              end
              line_number += 1
            end
          else
            # puts "File '#{require_path[0]}' does not exist."
          end

          # List the random references (if any)
          if !random_references.empty?
            puts "test: #{ti_name.sub(root_name, '')}"
            puts "\tscript: #{File.expand_path(require_file).sub(root_name, '')}"
            random_references.each do |random_reference|
              puts "\t\tline #{random_reference[0]}: #{random_reference[1]}"
            end
          end
        end
      end
    end
  end
end
