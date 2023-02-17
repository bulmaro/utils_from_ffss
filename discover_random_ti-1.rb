require 'pathname'

Dir.glob("**/*.ti") do |ti_file| # note one extra “*”
  ti_file_info = Pathname.new(ti_file)
  ti_name = ti_file_info.basename
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
              if ruby_file_line =~ /\b(rand|srand|sample|Random)\b/
                random_references << [line_number, ruby_file_line]
              end
              line_number += 1
            end
          else
            # puts "File '#{require_path[0]}' does not exist."
          end

          # List the random references (if any)
          if !random_references.empty?
            puts "#{ti_file}"
            puts "\t#{File.expand_path(require_file)}"
            random_references.each do |random_reference|
              puts "\t\t#{random_reference[0]}: #{random_reference[1]}"
            end
          end
        end
      end
    end
  end
end
