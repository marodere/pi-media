use_bpm 120

use_sched_ahead_time 10

define :beat_detector do |in_sample, onset|
  t_len = sample_duration in_sample
  t_len_minutes = t_len / current_bpm
  st = onset.map {|x| x[:start]}
  detected = (60..129).map {|bpm|
    t_len_beats = t_len_minutes * bpm
    eps = 1.0 / t_len_beats / 32
    {
      :bpm => bpm,
      :best_match => (0..(st.length / 10).floor).map {|start_beat| {
          :start_from => start_beat,
          :match => (0..t_len_beats).map {|beat|
            expect = st[start_beat] + beat / t_len_beats - (eps / 2)
            nearest = st.bsearch {|x| x >= expect}
            (nearest != nil and (expect - nearest).abs <= eps) ? 1 : 0
          }.sum
        }
      }.max_by{|x| x[:match]}
    }
  }.max_by{|x| x[:best_match][:match]}
  return {
    :bpm => detected[:bpm],
    :start => st[detected[:best_match][:start_from]]
  }
end

define :get_bpm do |in_sample|
  onset = nil
  sample in_sample, onset: lambda{|c| onset = c; c[0]}, on: 0
  return beat_detector in_sample, onset
end
