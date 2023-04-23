

if {[info exist PTECO_FIX_DRC]} {
    puts "* Information: Skip Reset maxcap constraints"
} else {
    puts "* Information: Reset maxcap constraints"
    set timing_override_max_capacitance_transition_lib_constraint true
    set timing_drc_optimization_for_unconstrained_datapath false
    set_max_capacitance 999 [get_pins * -hier]
    set_max_capacitance 999 [get_clocks *] -clock_path -rise -fall
    set_max_capacitance 999 [get_clocks *] -data_path  -rise -fall
}


proc set_maxcap_half_cycle { args } {
set results(-freq_margin)  "0"
set results(-include)      "*"
set results(-exclude)      ""
set results(-timing_check) "on"

parse_proc_arguments -args $args results

set my_freq_margin    $results(-freq_margin)
set my_include        $results(-include)
set my_exclude        $results(-exclude)
set my_check          $results(-timing_check)


set include_filter ""
if { $my_include != "*"} {
  foreach tmp $my_include {
    if { $include_filter == "" } {
      set include_filter "full_name=~${tmp}/*"
    } else {
      set include_filter "$include_filter || full_name=~${tmp}/*"
    }
  }
}
set exclude_filter ""
if { $my_exclude != ""} {
  foreach tmp $my_exclude {
    if { $exclude_filter == "" } {
      set exclude_filter "full_name!~${tmp}/*"
    } else {
      set exclude_filter "$exclude_filter && full_name!~${tmp}/*"
    }
  }
}

if { $include_filter != "" && $exclude_filter != ""} {
  set all_filter "(${include_filter}) && (${exclude_filter})"
} elseif { $include_filter != "" && $exclude_filter == "" } {
  set all_filter "(${include_filter})"
} elseif { $include_filter == "" && $exclude_filter != "" } {
  set all_filter "(${exclude_filter})"
} else {
  set all_filter "full_name=~*"
}


set clock_list ""
foreach_in_collection clk_tmp [get_clock * -filter "period < 5"] {
  set clk_obj [get_attribute $clk_tmp full_name]
  set clk_period [get_attribute $clk_tmp period]
  set clk_period2 [expr $clk_period * ( 1 + $my_freq_margin )]

  set half_cap [expr $clk_period2 * 0.095 * 2 * 0.5 / 1.25 ]

  puts "$clk_obj $clk_period $clk_period2 $half_cap"
  set clock_list "$clock_list $clk_obj"

  ### fall to ###
  set fall_to_path [get_timing_paths -fall_to [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]

  if { $fall_to_path != ""} {
    foreach_in_collection fi_tmp [get_pins -quiet [all_fanin -to [get_pins -quiet [get_attribute $fall_to_path endpoint] ] -flat] -filter "pin_direction==out && $all_filter && is_clock_pin==false"] {
      set pin_obj [get_attribute $fi_tmp full_name]
      set org_mt [get_attribute [get_pins $pin_obj] max_capacitance ]
      if { $half_cap < $org_mt } {
        if { $my_check == "on" } {
          set check_tm [get_timing_paths -rise_from [get_clocks * ] -through [get_pins $pin_obj] -fall_to [get_clocks $clk_obj] ]
          if { [sizeof_collection $check_tm] > 0 } {
            set_max_capacitance $half_cap [get_pins $pin_obj]
            puts "FALL_TO :  $pin_obj $half_cap"
          }
        } else {
          set_max_capacitance $half_cap [get_pins $pin_obj]
          puts "FALL_TO :  $pin_obj $half_cap"
        }
      }
    }
  }

  ### fall from ###
  set fall_from_path [get_timing_paths -fall_from [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]

  if { $fall_from_path != ""} {

    foreach_in_collection fo_tmp [get_pins -quiet [all_fanout -from [get_pins -quiet -of [get_cells -quiet -of [get_attribute $fall_from_path startpoint]] -filter "pin_direction==out" ] -flat ] -filter "pin_direction==out && $all_filter && is_clock_pin==false"] {
      set pin_obj [get_attribute $fo_tmp full_name]
      set org_mt [get_attribute [get_pins $pin_obj] max_capacitance ]
      if { $half_cap < $org_mt } {
        if { $my_check == "on" } {
          set check_tm [get_timing_paths -fall_from [get_clocks $clk_obj ] -through [get_pins $pin_obj] -rise_to [get_clocks *] ]
          if { [sizeof_collection $check_tm] > 0 } {
            set_max_capacitance $half_cap [get_pins $pin_obj]
            puts "FALL_FROM : $pin_obj $half_cap"
          }
        } else {
          set_max_capacitance $half_cap [get_pins $pin_obj]
          puts "FALL_FROM : $pin_obj $half_cap"
        }
      }
    }
  }

  set f_edge [lindex [lindex [get_attribute $clk_tmp waveform] 0 ] 0 ]
  if { $f_edge != 0} {
    puts "[get_attribute $clk_tmp full_name] [lindex [lindex [get_attribute $clk_tmp waveform] 0 ] 0]"
    set inv_to_ff [get_timing_paths -to [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]
    if { $inv_to_ff != ""} {
      foreach_in_collection fi_tmp [get_pins -quiet [all_fanin -to [get_pins -quiet [get_attribute $inv_to_ff endpoint] ] -flat] -filter "pin_direction==out && $all_filter && is_clock_pin==false"] {
        set pin_obj [get_attribute $fi_tmp full_name]
        set org_mt [get_attribute [get_pins $pin_obj] max_capacitance ]
        if { $half_cap < $org_mt } {
          if { $my_check == "on" } {
            set check_tm [get_timing_paths -from [get_clocks -filter "full_name!=${clk_obj}" ] -through [get_pins $pin_obj] -to [get_clocks $clk_obj] ]
            if { [sizeof_collection $check_tm] > 0 } {
              set_max_capacitance $half_cap [get_pins $pin_obj]
              puts "TO UNDER : $pin_obj $half_cap"
            }
          } else {
            sizeof_collection $half_cap [get_pins $pin_obj]
            puts "TO UNDER : $pin_obj $half_cap"
          }
        }
      }
    }

    set inv_from_ff [get_timing_paths -from [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]
    if { $inv_from_ff != ""} {
      foreach_in_collection fo_tmp [get_pins -quiet [all_fanout -from [get_pins -quiet -of [get_cells -quiet -of [get_attribute $inv_from_ff startpoint]] -filter "pin_direction==out" ] -flat ] -filter "pin_direction==in && $all_filter && is_clock_pin==false"] {
        set pin_obj [get_attribute $fo_tmp full_name]
        set org_mt [get_attribute [get_pins $pin_obj] max_capacitance ]
        if { $half_cap < $org_mt } {
          if { $my_check == "on" } {
            set check_tm [get_timing_paths -from [get_clocks ${clk_obj} ] -through [get_pins $pin_obj] -to [get_clocks -filter "full_name!=${clk_obj}" ] ]
            if { [sizeof_collection $check_tm] > 0 } {
              set_max_capacitance $half_cap [get_pins $pin_obj]
              puts "FROM : $pin_obj $half_cap"
            }
          } else {
            set_max_capacitance $half_cap [get_pins $pin_obj]
            puts "FROM : $pin_obj $half_cap"
          }
        }
      }
    }
  }
}

}

define_proc_attributes set_maxcap_half_cycle \
  -info "Set Max Capacitance of Half Cycle Path" \
  -define_args \
  {
    {-freq_margin    "specify freq margin"          "margin"          string  optional }
    {-include        "specify include inst"         "instance_list"   string  optional }
    {-exclude        "specify exclude inst"         "instance_list"   string  optional }
    {-timing_check   "specify timing check flag"    "on/off"          string  optional }
}

