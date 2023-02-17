require 'sonosite-model'

product = "PHX"
ip = "10.192.144.183"
ss = SonoSiteSystemModel.new(product, ip)

n = ss.ui.control_panel.buttons.names

puts n