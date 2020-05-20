# usage:
# metronome 4, 4

define :metronome do |x, y|
  live_loop :metronome do
    sample :elec_tick, amp: 1.5
    sleep x.to_f/y
    (x-1).times do
      sample :elec_tick, rate: 1.5
      sleep x.to_f/y
    end
  end
end