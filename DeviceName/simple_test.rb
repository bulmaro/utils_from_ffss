# frozen_string_literal: true
require 'sonosite-model'

def sname
  ss = SonoSiteSystemModel.new("PHX", ARGV[0])

  puts "Device name (straight): #{ss.device.name}"

  devicename = '--DIDNT GET IT--'
  begin
    devicename = ss.device.assemblies['Program']['Name']
    puts "Got it via long name"
  rescue NoMethodError => e
    devicename = ss.device.name
  end
  return devicename
end

puts "Device name (long): #{sname}"
