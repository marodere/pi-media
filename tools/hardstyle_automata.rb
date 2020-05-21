eval_file "~/Music/0n1y/akai.rb"

use_akai_channel 2
use_sched_ahead_time 0.5

base = "~/Music/Shock force/Shock Force - Hardstyle Loops vol 1/Hardstyle Loops/"

define :norm do |value|
  return (value - 64) / 64.0
end

define :get_sample_index do |cc_no|
  key = "samp_" + cc_no.to_s
  sample_index = get[key]
  if (sample_index == nil) || (akai_cc_pressed? (cc_no + 4)) then
    sample_index = rand_i(101)
    set key, sample_index
  end
  return sample_index
end

define :play_sample_pack do |samples, cc_no|
  on_program_match = lambda{|cb| lambda {|v| if akai_program == cc_no then cb.call v end }}
  
  with_fx :eq do |eq|
    akai_bind :handle, 1, on_program_match.(lambda {|v| control eq, low: (norm v)})
    akai_bind :handle, 2, on_program_match.(lambda {|v| control eq, mid: (norm v)})
    akai_bind :handle, 3, on_program_match.(lambda {|v| control eq, high: (norm v)})
    with_fx :lpf, cutoff: 130 do |lpf|
      with_fx :hpf, cutoff: 0 do |hpf|
        akai_bind :handle, 4, on_program_match.(
          lambda {|v|
            control lpf, cutoff: [v * 2 + 2, 130].min
            control hpf, cutoff: [(v - 64) * 2, 0].max
        })
        
        s = nil
        me = "voice_" + cc_no.to_s
        live_loop me do
          sync_bpm :main
          s = samples, (get_sample_index cc_no)
          sample s, on: (akai_cc_pressed? cc_no), beat_stretch: 16
        end
      end
    end
  end
end

voices = [
  [base + "Kick loops", 1],
  [base + "Bassline Loops", 2],
  [base + "Percussion Loops", 3],
  [base + "Lead and Synth Loops", 4]
]

voices.each do |v|
  play_sample_pack v[0], v[1]
end

live_loop :main do
  use_bpm (akai_cc_handle 8) + 120
  sleep 16
end