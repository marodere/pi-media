#
# simple MIDI input framework
# originally created for using with Akai LPD8 controller
#

# const
__akai_log_prefix = "[akai] "

# hardware configuration
__akai_channels = (1..4)
__akai_device = "/midi:lpd8_midi_1:1:"

__akai_programs = (1..8)
__akai_cc_pads = (1..8)
__akai_cc_handles = (11..18)
__akai_note_pads = (36..43)

#
# initialization
#

use_real_time

if get[:__akai_initialized] == nil then
  __akai_channels.each do |channel_no|
    key_prefix = "__akai_state_ch" + channel_no.to_s
    set (key_prefix + "_program"), 1
    
    set (key_prefix + "_cc"), map(
      __akai_cc_pads.map do |cc_no| [cc_no, 0] end +
      __akai_cc_handles.map do |cc_no| [cc_no, 0] end
    )
    
    set (key_prefix + "_note"),
      map(__akai_note_pads.map do |note_no| [note_no, nil] end)
  end
  
  set :__akai_initialized, true
  puts __akai_log_prefix + "initialization completed"
end

__akai_channels.each do |channel_no|
  ch = channel_no.to_s()
  th_prefix = "__akai_event_ch_" + ch
  key_prefix = "__akai_state_ch" + channel_no.to_s
  
  in_thread(name: th_prefix + "_program_change") do
    loop do
      x = sync __akai_device + ch + "/program_change"
      set (key_prefix + "_program"), x[0]
    end
  end
  
  in_thread(name: th_prefix + "_control_change") do
    loop do
      cc_no, value = sync __akai_device + ch + "/control_change"
      set (key_prefix + "_cc"),
        get[key_prefix + "_cc"].merge({cc_no => value})
    end
  end
  
  in_thread(name: th_prefix + "_note_on") do
    loop do
      note_no, value = sync __akai_device + ch + "/note_on"
      set (key_prefix + "_note"),
        get[key_prefix + "_note"].merge({note_no => value})
    end
  end
  
  in_thread(name: th_prefix + "_note_off") do
    loop do
      note_no, _ = sync __akai_device + ch + "/note_off"
      set (key_prefix + "_note"),
        get[key_prefix + "_note"].merge({note_no => nil})
    end
  end
end

set :__akai_channel, __akai_channels.first()

puts __akai_log_prefix + "started!"

#
# private
#

define :__akai_validate_channel do |channel_no|
  assert (__akai_channels.include? channel_no), __akai_log_prefix + " ERROR: no such channel!"
end

define :__akai_channel do |channel_no|
  if channel_no != nil
    __akai_validate_channel channel_no
    return channel_no.to_s
  end
  return get[:__akai_channel].to_s
end

#
# public
#

# channel

define :use_akai_channel do |channel_no|
  __akai_validate_channel channel_no
  set :__akai_channel, channel_no
end

define :with_akai_channel do |channel_no, &block|
  outer_channel = get[:__akai_channel]
  use_akai_channel channel_no
  block.call
  set :__akai_channel, outer_channel
end

# program

define :akai_program do |channel_no=nil|
  ch = __akai_channel channel_no
  return get["__akai_state_ch" + ch + "_program"]
end

# cc pads

define :akai_cc_pad do |pad_no, channel_no=nil|
  assert (__akai_cc_pads.include? pad_no), __akai_log_prefix + "ERROR: no such pad!"
  value = get["__akai_state_ch" + (__akai_channel channel_no) + "_cc"][pad_no]
  return value > 0 ? value : nil
end

define :akai_cc_pressed? do |pad_no, channel_no=nil|
  return (akai_cc_pad pad_no, channel_no) != nil
end

# cc handles

define :akai_cc_handle do |handle_no, channel_no=nil|
  h = __akai_cc_handles.first + handle_no - 1
  assert (__akai_cc_handles.include? h), __akai_log_prefix + "ERROR: no such handle!"
  return get["__akai_state_ch" + (__akai_channel channel_no) + "_cc"][h]
end

# note pads

define :akai_note do |note_no, channel_no=nil|
  n = __akai_note_pads.first + note_no - 1
  assert (__akai_note_pads.include? n), __akai_log_prefix + "ERROR: no such note!"
  return get["__akai_state_ch" + (__akai_channel channel_no) + "_note"][n]
end

define :akai_note_pressed? do |note_no, channel_no=nil|
  return (akai_note note_no, channel_no) != nil
end

# events TBD
