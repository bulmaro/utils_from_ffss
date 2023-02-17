# import this line to benefit from methods here
# require 'C:\Users\bulmaro.herrera\work\utils\debug_log.rb'

def log_line(msg, call_stack_depth = 4)
  call_stack = caller_locations

  time_stamp = "#{Time.now.strftime("%H:%M:%S.%L")}"

  last_caller = call_stack[0]
  file_info = "#{File.basename(last_caller.path)}@#{last_caller.lineno}"

  # TODO: Enhance to include class name. So far, in Ruby 2.4.4, the base_label does NOT include it.
  recent_called_methods = call_stack.take(call_stack_depth).reverse.map {|frame| "(#{frame.base_label})" }.join('->')

  return "#{time_stamp} #{file_info}: #{recent_called_methods} - #{msg}"
end

if $0 == __FILE__
  # Test log_line
  class A
    def Ac
      puts log_line("Here")
      return "A"
    end
  end
  class B
    def Bc
      a = A.new
      return "B" + a.Ac
    end
  end

  b = B.new
  b.Bc
end


