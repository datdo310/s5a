## v1r00: 2014/09/14 -:		1st from E1M-S
## v1r01: 2017/01/20 Y.Oda:	Add -slack_lesser_than inf
## v1r02: 2017/04/15 Y.Oda:	remove override variables and
#                           remove get_pins section of search fanin from fall_to/fanout from fall_from
#
#set timing_override_max_capacitance_transition_lib_constraint true
#set timing_drc_optimization_for_unconstrained_datapath false


if {[info exist PTECO_FIX_DRC]} {
    puts "* Information: Skip Reset maxtran constraints"
} else {
    puts "* Information: Reset maxtran constraints"
    set_max_transition 999 [get_pins * -hier]
    set_max_transition 999 [get_clocks *] -clock_path -rise -fall
    set_max_transition 999 [get_clocks *] -data_path  -rise -fall
}

proc set_maxtran_half_cycle { args } {
   set results(-freq_margin)  "0"
   set results(-include)      "*"
   set results(-exclude)      ""
   set override_maxcaptran [get_app_var timing_override_max_capacitance_transition_lib_constraint]
   set_app_var timing_override_max_capacitance_transition_lib_constraint false

   
   parse_proc_arguments -args $args results
   
   set my_freq_margin    $results(-freq_margin)
   set my_include        $results(-include)
   set my_exclude        $results(-exclude)
   
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
   foreach_in_collection clk_tmp [get_clock *] {
     set clk_obj [get_attribute $clk_tmp full_name]
     set clk_period [get_attribute $clk_tmp period]
     set clk_period2 [expr $clk_period /( 1 - $my_freq_margin )]
   
     set half_tran [expr $clk_period2 * 0.6 * 0.8 * 0.5]
     set half_tran_over [expr $clk_period2 * 0.4 * 0.8 * 0.5]
   
     if { $clk_period2 < 10 } {
       puts "$clk_obj $clk_period $clk_period2 $half_tran"
       set clock_list "$clock_list $clk_obj"
   
       ### fall to ###
       set fall_to_path [get_timing_paths -fall_to [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]
   
       if { $fall_to_path != ""} {
   
         if { [get_cells -quiet -of [get_attribute $fall_to_path endpoint]] != "" } {
            # Remove IO PAD
         foreach_in_collection fo_tmp [get_pins -quiet [all_fanout -from [get_pins -quiet -of [get_cells -quiet -of [get_attribute $fall_to_path endpoint]] -filter "pin_direction==out" ] -flat ] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fo_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
        }
        # Endif 
   
         foreach_in_collection fi_tmp [get_pins -quiet [all_fanin -to [get_attribute $fall_to_path endpoint]  -flat] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fi_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
   
       }
   
       ### fall from ###
       set fall_from_path [get_timing_paths -fall_from [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]
   
       if { $fall_from_path != ""} {
   
        if { [get_cells -quiet -of [get_attribute $fall_from_path startpoint]] != "" } {
         # Remove IO PAD
         foreach_in_collection fo_tmp [get_pins -quiet [all_fanout -from [get_pins -quiet -of [get_cells -quiet -of [get_attribute $fall_from_path startpoint]] -filter "pin_direction==out" ] -flat ] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fo_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
        }
        # End if
   
         foreach_in_collection fi_tmp [get_pins -quiet [all_fanin -to  [get_attribute $fall_from_path startpoint]  -flat] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fi_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
   
       }
   
     }
   
     set f_edge [lindex [lindex [get_attribute $clk_tmp waveform] 0 ] 0 ]
     if { $f_edge != 0 && $clk_period2 < 10} {
       puts "[get_attribute $clk_tmp full_name] [lindex [lindex [get_attribute $clk_tmp waveform] 0 ] 0]"
       set inv_to_ff [get_timing_paths -to [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]
       if { $inv_to_ff != ""} {
         foreach_in_collection fo_tmp [get_pins -quiet [all_fanout -from [get_pins -quiet -of [get_cells -quiet -of [get_attribute $inv_to_ff endpoint]] -filter "pin_direction==out" ] -flat ] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fo_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
         foreach_in_collection fi_tmp [get_pins -quiet [all_fanin -to [get_pins -quiet [get_attribute $inv_to_ff endpoint] ] -flat] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fi_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
   
       }
   
       set inv_from_ff [get_timing_paths -from [get_clocks $clk_obj ] -max_paths 10000 -slack_lesser_than inf]
       if { $inv_from_ff != ""} {
         foreach_in_collection fo_tmp [get_pins -quiet [all_fanout -from [get_pins -quiet -of [get_cells -quiet -of [get_attribute $inv_from_ff startpoint]] -filter "pin_direction==out" ] -flat ] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fo_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
         foreach_in_collection fi_tmp [get_pins -quiet [all_fanin -to [get_pins -quiet [get_attribute $inv_from_ff startpoint] ] -flat] -filter "pin_direction==in && $all_filter"] {
           set pin_obj [get_attribute $fi_tmp full_name]
           if { $clk_period2 < 6.25 } {
             puts "$pin_obj $clk_obj $half_tran_over"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran_over < $org_mt } {
               set_max_transition $half_tran_over [get_pins $pin_obj]
             }
           } else {
             puts "$pin_obj $clk_obj $half_tran"
             set org_mt [get_attribute [get_pins $pin_obj] max_transition ]
             if { $half_tran < $org_mt } {
               set_max_transition $half_tran [get_pins $pin_obj]
             }
           }
         }
   
       }
   
     }
   
   
   }
   set_app_var timing_override_max_capacitance_transition_lib_constraint $override_maxcaptran
}

define_proc_attributes set_maxtran_half_cycle \
  -info "Set Max Transition of Half Cycle Path" \
  -define_args \
  {
    {-freq_margin    "specify freq margin"       "margin"          string  optional }
    {-include        "specify include inst"      "instance_list"   string  optional }
    {-exclude        "specify exclude inst"      "instance_list"   string  optional }
}

