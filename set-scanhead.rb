require 'optparse'
require 'scanheadSetter/scanhead_setter'

begin
  # scanhead_setter = SonoSiteSystemScanheadSetter::ScanheadSetter.new(ARGV[0], "10.192.151.31", ARGV[1].split(","))
  # scanhead_setter = SonoSiteSystemScanheadSetter::ScanheadSetter.new(ARGV[0], "localhost", ARGV[1].split(","))
  scanhead_setter = SonoSiteSystemScanheadSetter::ScanheadSetter.new(ARGV[0], "10.192.144.183", ARGV[1].split(","))
  scanhead_setter.set_scanhead
rescue => e
  puts e.to_s
  exit SonoSiteSystemScanheadSetter::EXIT_FAILURE_SCRIPT
ensure
  scanhead_setter.finalize if scanhead_setter
end
exit SonoSiteSystemScanheadSetter::EXIT_NORMAL
