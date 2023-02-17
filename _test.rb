require_relative '../Lib/Labeler/options'
require 'sonosite-hudson-remote-api'
require 'sonosite-model'
require 'logger'

MAX_SCANHEAD_SLOTS = 3 # Assuming a TTC

def regenerate_labels(product, ip)
  new_labels = []
  # Call Ruby model and get current hardware list
  begin
    ss = SonoSiteSystemModel.new(product, ip)
  rescue RsiConnectException
    abort "Could not connect with IP address #{ip} - is it powered?"
  end

  # Go to Imaging
  ss.ui.navigator.set_view 'Imaging'

  # Check for secure mode
  new_labels << 'SECURE_MODE' if ss.ui.control_panel.buttons.names.include?('LoginMenuButton')

  # Get current hardware list.
  devicename = ss.device.assemblies['Program']['Name']

  # Scanhead keys.
  nscanheads = ss.ultrasound.scanheads.size
  if nscanheads == 0
    new_labels << "none"
  else
    # Look for scanheads on all slots, regardless of scanheads.size
    MAX_SCANHEAD_SLOTS.times do |slot|
      begin
        puts "Attempting to select slot: #{slot}"
        ss.ultrasound.scanheads.set_selected_scanhead(slot)
        selected = ss.ultrasound.scanheads.selected_scanhead
        puts("Actual selected_scanhead: #{selected}")
        puts "Attempting to get name from slot: #{slot}"
        # Will raise exception if no scanhead at slot
        sh_name = ss.ultrasound.scanheads.at_index(slot).name
        # ... no exception raised, thus we have a scanhead at slot
        puts "On Slot[#{slot}]: '#{sh_name}'"
        if devicename == "ST" && slot == 1
          print("Unexpected scanhead found on slot 1 given device type is 'ST'")
        end
        new_labels << sh_name
        # Some scanheads have had their names changed. So far this has been the addition of
        # lowercase letters at the end, so strip them off to create a 'basename' for
        # backwards compatibility.
        sh_basename = sh_name.gsub(/[a-z]+$/, '')
        new_labels << sh_basename if sh_basename != sh_name
      rescue RuntimeError
        # No scanhead at slot, continue to next slot
      end
    end
    new_labels << "NUM_SH_#{nscanheads}"
  end

  # Simulator or hardware?
  # On some early M2 builds, device.simulator? returned true even on hardware.
  # So as a precaution we also look at the IP address.
  if !ss.device.simulator? || ((product =~ /Porte|M2/i) && (ip != "192.168.0.2"))
    new_labels << "Hardware"
  else
    new_labels << "Simulator"
  end

  # Peripherals: Biopsy, ECG, and thumb drives
  #   USBS simple case: any/none
  #   Biopsy (Note: P21 bracket with hall sensor is the only one detectible by the M2)
  #   ECG
  visit_usb_page = false    # Assume only thumb drive or other simple cases
  num_usbs = 0
  peripherals = ss.device.peripherals
  peripherals.each do |name, properties|
    # Non-USB Devices
    if name.match(/biopsy/i)
      new_labels << "BIOPSY" if properties["Connected"].to_s.match(/true/i)
    elsif name.match(/ecg/i)
      new_labels << "ECG" if properties["Connected"].to_s.match(/true/i)
    else
      # Winnow down to USB Devices only
      next unless properties.keys.include?("Is_A")
      next if properties["Is_A"] != "USB_DEVICE"
      type = properties['Type']
      capacity = properties['Capacity'].to_i
      if (type == 8) || (capacity > 0)
        new_labels << "USBS" unless new_labels.include?("USBS")
        num_usbs += 1
      else
        # We have some other kind of USB device attached to the system
        # We will need to navigate to the USB Devices setup page to get the information we need.
        visit_usb_page = true
      end
    end
  end
  new_labels << "NUM_USBS_#{num_usbs}"

  if visit_usb_page
    # new_labels += find_other_usb_devices(ss)
  end
  labelstring = new_labels.join(" ") + " #{product.upcase}"
  puts "\nNew labels: #{labelstring}"
  labelstring
end

puts regenerate_labels("PHX", "10.192.144.183") # On my cube
# puts regenerate_labels("ST", "10.192.151.32") # An ST on the CTL
# puts regenerate_labels("ST", "10.192.151.64") # An ST on the CTL
# puts regenerate_labels("ST", "localhost") # Which for now is simulating an ST