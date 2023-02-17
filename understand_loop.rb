num_scanheads = ARGV[0].to_i # @model.ultrasound.scanheads.size
# Remember where we started.  Beware, may be -1 if no scanheads attached
saved_scanhead_index = ARGV[1].to_i # @model.ultrasound.scanheads.selected_scanhead

[num_scanheads, 1].max.times do |i|              # do at least one time
  new_index = (saved_scanhead_index + i) % num_scanheads
  puts("new_index: #{new_index}")
  if new_index == saved_scanhead_index # match
    puts("matched at new_index: #{new_index}")
    return true
  end
end

