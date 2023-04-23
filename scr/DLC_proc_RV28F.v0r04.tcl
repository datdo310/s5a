############################################################
# DLC_proc_RV28F.tcl
#
# v0r04: 2019/01/10 Change Initial Transition 9999.999->99999.99
# v0r05: 2020/08/19 Remove min_period and half cycle section
#                   Add RV28F TSMC
############################################################
############################################################
# set constraint factors
############################################################
# time scale factor
set Tunit [get_attribute [current_design] time_unit_in_second]
set Tfactor [expr 1.0e-9/$Tunit]
# capacitance scale factor
set Cunit [get_attribute [current_design] capacitance_unit_in_farad]
set Cfactor [expr 1.0e-12/$Cunit]
#=================================================================#
# get_min_period.tcl
#
# COPYRIGHT (C) 2014 RENESAS ELECTRONICS CORP. ALL RIGHTS RESERVED
#=================================================================#

global DLCLT_ReducedPeriod

proc get_min_period {
    pin
    direction
    path_flag
} {
    if { $path_flag == "true" } {
        set clk [get_attribute -quiet $pin clocks]
        set period [get_min_period_from_clk_object $clk]

    } else {
        set period [get_min_period_from_arrival_window $pin $direction]
    }

    return $period
}

proc get_min_period_from_arrival_window {
    pin
    direction
} {
    set clklist [get_clock_list_from_arrival_window $pin $direction]

    if { $clklist != "" } {
        set period [get_min_period_from_namelist $clklist]
    } else {
        set period 1.0e10
    }

    return $period
}

proc get_clock_list_from_arrival_window {
    pin
    direction
} {
    if { $direction == "in" } {
        set arrival_window [get_attribute -quiet $pin arrival_window]
    } else {
        set arrival_window [get_attribute -quiet \
                        [get_pins -quiet -of [get_nets -quiet -of $pin] \
                        -filter "direction==in*"] arrival_window]
        if { $arrival_window == "" } {
            set arrival_window [get_attribute -quiet \
                        [get_pins -quiet -leaf -of [get_cells -quiet -of $pin] \
                        -filter "direction=~in*"] arrival_window]
        }
    }

    if { [llength $arrival_window] == 1 } {
        set namelist ""
        set line_no_bracket [lindex $arrival_window 0]
        if { $line_no_bracket == "" } {
            return ""
        }
        foreach clk_window $line_no_bracket {
            append namelist " [lindex $clk_window 0]"
        }
        return [lsort -unique $namelist]
    } elseif { [llength $arrival_window] > 1 } {
        set namelist ""
        foreach aw $arrival_window {
            set line_no_bracket [lindex $aw 0]
            if { $line_no_bracket == "" } { continue }
            foreach clk_window $line_no_bracket {
                append namelist " [lindex $clk_window 0]"
            }
        }
        return [lsort -unique $namelist]
    } else {
        return ""
    }

    return ""
}

proc define_user_attribute_clk_path_flag {
    clock_as_data
    clock_as_data_exclude_list
} {
    define_user_attribute -quiet -class {pin port} -type boolean \
                        dlclt_clk_path_flag

    set_user_attribute -quiet [get_pins * -hier] dlclt_clk_path_flag false
    set_user_attribute -quiet [get_ports *] dlclt_clk_path_flag false

    foreach_in_collection clk [get_clocks *] {
        set pins [get_attribute -quiet $clk clock_network_pins]
        set pins [add_to_collection -unique {} $pins]
        set_user_attribute -quiet $pins dlclt_clk_path_flag true
        if { [string equal -nocase $clock_as_data "data"] } {
            set CaD_pins [filter_collection $pins "is_clock_used_as_data==true"]
            set CaC_pins [filter_collection $pins "is_clock_used_as_clock==true"]
            set CaD_pins [remove_from_collection $CaD_pins $CaC_pins]
            set_user_attribute -quiet $CaD_pins dlclt_clk_path_flag false
            if { $clock_as_data_exclude_list != "" } {
                if { [catch {open $clock_as_data_exclude_list "r"} fd] } {
                    puts "Error(DLCLT): Cannot open file. $clock_as_data_exclude_list"
                    exit 1
                }
                while { [gets $fd line] >= 0 } {
                    if { [llength $line] == 0 } { continue }
                    set exclude [lindex $line 0]
                    if { [regexp {^#} $exclude] } { continue }
                    set exclude_pins [filter_collection $CaD_pins "full_name=~$exclude"]
                    if { $exclude_pins != "" } {
                        set_user_attribute -quiet $exclude_pins dlclt_clk_path_flag true
                    }
                }
                close $fd
            }
        }
    }
}

proc reduce_clock_margin {
    file
} {
    global DLCLT_ReducedPeriod

    foreach_in_collection clk [get_clocks -quiet *] {
        set clkname [get_object_name $clk]
        set period [get_attribute -quiet $clk period]
        if { $period == "" } {
            set DLCLT_ReducedPeriod($clkname) 1.0e10
        } else {
            set DLCLT_ReducedPeriod($clkname) $period
        }
    }

    if { $file != "" } {
        if { [catch {open $file r} fd] } {
            puts "Error(DLCLT): Cannot open file ($file)."
            exit 1
        }

        array unset Calculated
        while { [gets $fd line] >= 0 } {
            if { [llength $line] == 0 } { continue }
            if { [regexp {^#} [lindex $line 0]] } { continue }
            set clkname [lindex $line 0]
            set clklist [get_clocks -quiet $clkname]
            if { [sizeof_collection $clklist] == 0 } {
                puts "Warning(DLCLT): Clock $clkname does not exist."
                continue
            }
            set expression [lindex $line 1]
            foreach_in_collection clk $clklist {
                set clkname [get_object_name $clk]
                if { [info exists Calculated($clkname)] } {
                    puts "Warning(DLCLT): Expression for $clkname already set. Ignored it."
                    continue
                }
                set period [get_attribute -quiet $clk period]
                if { $period != "" } {
                    set DLCLT_ReducedPeriod($clkname) [expr $expression]
                }
                set Calculated($clkname) 1
            }
        }

        close $fd
    }
}

proc get_min_period_from_clk_object {
    objectlist
} {
    set namelist ""
    foreach_in_collection clk $objectlist {
        set clkname [get_object_name $clk]
        append namelist " $clkname"
    }

    return [get_min_period_from_namelist $namelist]
}

proc get_min_period_from_namelist {
    namelist
} {
    global DLCLT_ReducedPeriod

    set period_list "1.0e10"

    foreach clkname $namelist {
        append period_list " $DLCLT_ReducedPeriod($clkname)"
    }

    return [lindex [lsort -real -increasing $period_list] 0]
}

proc get_min_clock_and_period_from_namelist {
    namelist
    min_clock_In
    min_period_In
} {
    upvar $min_clock_In min_clock
    upvar $min_period_In min_period

    set min_clock ""
    set min_period 1.0e10

    global DLCLT_ReducedPeriod

    foreach clkname $namelist {
        if { $min_period > $DLCLT_ReducedPeriod($clkname) } {
            set min_clock $clkname
            set min_period $DLCLT_ReducedPeriod($clkname)
        }
    }

    return
}

proc get_min_clock_and_period {
    pin
    direction
    path_flag
    min_clock_In
    min_period_In
} {
    global DLCLT_ReducedPeriod
    upvar $min_clock_In min_clock
    upvar $min_period_In min_period

    set min_clock  "-"
    set min_period 1.0e10

    if { $path_flag == "true" } {
        get_min_clock_and_period_from_clk_object \
                [get_attribute -quiet $pin clocks] min_clock min_period

    } else {
        foreach clkname [get_clock_list_from_arrival_window $pin $direction] {
            if { $min_period > $DLCLT_ReducedPeriod($clkname) } {
                set min_clock  $clkname
                set min_period $DLCLT_ReducedPeriod($clkname)
            }
        }
    }

    return 0
}

proc get_min_clock_and_period_from_clk_object {
    clkobj
    min_clock_In
    min_period_In
} {
    global DLCLT_ReducedPeriod

    upvar $min_clock_In min_clock
    upvar $min_period_In min_period

    set min_period 1.0e10
    foreach_in_collection clk $clkobj {
        set clkname [get_object_name $clk]
        if { $min_period > $DLCLT_ReducedPeriod($clkname) } {
            set min_clock  $clkname
            set min_period $DLCLT_ReducedPeriod($clkname)
        }
    }
}

###################################################################
# Initialize section
###################################################################
if { ![info exists dlclt_call_initialize_get_min_period] } {
    # define period which reduced margin
    if { ![info exists DLCLT_PERIOD_MARGIN_FILE] } {
        set DLCLT_PERIOD_MARGIN_FILE ""
    }
    reduce_clock_margin $DLCLT_PERIOD_MARGIN_FILE

    # set clock as data flag
    if { ![info exists DLCLT_DRV_CLOCK_AS_DATA] } {
        set DLCLT_DRV_CLOCK_AS_DATA "clock"
    }
    # set clock as data exclude file
    if { ![info exists DLCLT_DRV_CLOCK_AS_DATA_EXCLUDE_LIST] } {
        set DLCLT_DRV_CLOCK_AS_DATA_EXCLUDE_LIST ""
    }
    # define user attribute dlclt_clk_path_flag
    define_user_attribute_clk_path_flag $DLCLT_DRV_CLOCK_AS_DATA \
                        $DLCLT_DRV_CLOCK_AS_DATA_EXCLUDE_LIST

    # set end flag
    set dlclt_call_initialize_get_min_period 1
}

#=================================================================#
# get_half_cycle_path_v2.tcl
#
# COPYRIGHT (C) 2014 RENESAS ELECTRONICS CORP. ALL RIGHTS RESERVED
#=================================================================#


#===============================================================#
# Define global variables
#===============================================================#
global DLCLT_MIN_EPS
if { [info exists DLCLT_HALF_CYCLE_MIN_EPS] } {
    set DLCLT_MIN_EPS $DLCLT_HALF_CYCLE_MIN_EPS
} else {
    set DLCLT_MIN_EPS 1.0e-5
}

if { ![info exists DLCLT_ENABLE_HALF_CYCLE_DIFFERENT_CLOCK] } {
    set DLCLT_ENABLE_HALF_CYCLE_DIFFERENT_CLOCK no
}
if { ![info exists DLCLT_ENABLE_HALF_CYCLE_CLOCK_HI_LO] } {
    set DLCLT_ENABLE_HALF_CYCLE_CLOCK_HI_LO no
}

if { ![info exists DLCLT_HALF_CYCLE_DIFFERENT_CLOCK_MARGIN] } {
    set DLCLT_HALF_CYCLE_DIFFERENT_CLOCK_MARGIN 0.1
}

if { ![info exists DLCLT_HALF_CYCLE_MAXTRAN_PERIOD_LIMIT] } {
    set DLCLT_HALF_CYCLE_MAXTRAN_PERIOD_LIMIT 0.0
}

#===============================================================#
# Define user attribute
#===============================================================#
define_user_attribute -quiet -class {pin port} -type string dlclt_half_clock


proc get_half_cycle_path_for_clock {
    clock
    filter
    nworst
    max_paths
} {
    global DLCLT_ENABLE_HALF_CYCLE_DIFFERENT_CLOCK
    global DLCLT_HALF_CYCLE_MAXTRAN_PERIOD_LIMIT
    global DLCLT_ENABLE_HALF_CYCLE_CLOCK_HI_LO
    global DLCLT_HalfCyclePath

    set to_period [get_attribute $clock period]
    if { $to_period > $DLCLT_HALF_CYCLE_MAXTRAN_PERIOD_LIMIT } {
        return
    }

    if { [string equal $DLCLT_ENABLE_HALF_CYCLE_DIFFERENT_CLOCK "no"] } {
        get_half_cycle_path_for_clock_v2 $clock $clock \
                        $::DLCLT_ENABLE_HALF_CYCLE_CLOCK_HI_LO
    } else {
        set half_cycle_path ""
        foreach_in_collection from_clock [get_clocks *] {
            get_half_cycle_path_for_clock_v2 $from_clock $clock \
                        $::DLCLT_ENABLE_HALF_CYCLE_CLOCK_HI_LO
        }
    }

    return
}

proc get_half_cycle_path_for_clock_v2 {
    from_clock
    to_clock
    enable_different_clock
} {
    global DLCLT_MIN_EPS

    if { [string equal -nocase $enable_different_clock "no"] } {
        set array_key "[get_object_name $clock],[get_object_name $clock],same"
        get_half_cycle_path_odd_clk $from_clock $to_clock

    } else {
        set from_period [get_attribute $from_clock period]
        set to_period [get_attribute $to_clock period]
        set key "[get_object_name $from_clock],[get_object_name $to_clock]"
        if { $from_period > $to_period } {
            set ratio [get_clock_ratio $to_period $from_period]
            if { $ratio < 0 } {
                get_half_cycle_path_alledge $from_clock $to_clock
            } elseif { [expr $ratio % 2] > 0 } {
                get_half_cycle_path_same_clk $from_clock $to_clock $key
            } else {
                get_half_cycle_path_from_lf_to_hf $from_clock $to_clock $key
            }
        } else {
            set ratio [get_clock_ratio $from_period $to_period]
            if { $ratio < 0 } {
                get_half_cycle_path_alledge $from_clock $to_clock
            } elseif { [expr $ratio % 2] > 0 } {
                get_half_cycle_path_same_clk $from_clock $to_clock $key
            } else {
                get_half_cycle_path_from_hf_to_lf $from_clock $to_clock $key
            }
        }
    }

    return
}

proc get_half_cycle_path_same_clk {
    from_clock
    to_clock
    key
} {
    global DLCLT_HalfCyclePath

    set from_clk_edge [judge_waveform_edge $from_clock]

    set to_clk_edge [judge_waveform_edge $to_clock]

    if { $from_clk_edge == "rise" && $to_clk_edge == "rise" } {
        get_half_cycle_path_odd_clk $from_clock $to_clock $key

    } elseif { $from_clk_edge == "rise" && $to_clk_edge == "fall" } {
        get_half_cycle_path_odd_clk_inv $from_clock $to_clock $key

    } elseif { $from_clk_edge == "fall" && $to_clk_edge == "rise" } {
        get_half_cycle_path_odd_clk_inv $from_clock $to_clock $key

    } elseif { $from_clk_edge == "fall" && $to_clk_edge == "fall" } {
        get_half_cycle_path_odd_clk $from_clock $to_clock $key
    }

    return
}

proc get_half_cycle_path_from_hf_to_lf {
    from_clock
    to_clock
    key
} {
    global DLCLT_HalfCyclePath

    set from_clk_edge [judge_waveform_edge $from_clock]

    set to_clk_edge [judge_waveform_edge $to_clock]

    if { $from_clk_edge == "rise" && $to_clk_edge == "rise" } {
        get_half_cycle_path_hf2lf_even_clk $from_clock $to_clock $key

    } elseif { $from_clk_edge == "rise" && $to_clk_edge == "fall" } {
        get_half_cycle_path_hf2lf_even_clk $from_clock $to_clock $key

    } elseif { $from_clk_edge == "fall" && $to_clk_edge == "rise" } {
        get_half_cycle_path_hf2lf_even_clk_inv $from_clock $to_clock $key

    } elseif { $from_clk_edge == "fall" && $to_clk_edge == "fall" } {
        get_half_cycle_path_hf2lf_even_clk_inv $from_clock $to_clock $key
    }

    return
}

proc get_half_cycle_path_from_lf_to_hf {
    from_clock
    to_clock
    key
} {
    global DLCLT_HalfCyclePath

    set from_clk_edge [judge_waveform_edge $from_clock]

    set to_clk_edge [judge_waveform_edge $to_clock]

    if { $from_clk_edge == "rise" && $to_clk_edge == "rise" } {
        get_half_cycle_path_lf2hf_even_clk $from_clock $to_clock $key

    } elseif { $from_clk_edge == "rise" && $to_clk_edge == "fall" } {
        get_half_cycle_path_lf2hf_even_clk_inv $from_clock $to_clock $key

    } elseif { $from_clk_edge == "fall" && $to_clk_edge == "rise" } {
        get_half_cycle_path_lf2hf_even_clk $from_clock $to_clock $key

    } elseif { $from_clk_edge == "fall" && $to_clk_edge == "fall" } {
        get_half_cycle_path_lf2hf_even_clk_inv $from_clock $to_clock $key
    }

    return
}

#=================================================================#
# get_half_cycle_path_common.tcl
#
# COPYRIGHT (C) 2014 RENESAS ELECTRONICS CORP. ALL RIGHTS RESERVED
#=================================================================#

proc get_half_cycle_path_start_end_pair {
    pair_file
    nworst
    max_paths
} {
    if { [catch {open $pair_file "r"} in_fd] } {
        puts "Error(DLCLT) : Cannot open file. $pair_file"
        return
    }

    set half_cycle_path ""
    while { [gets $in_fd line] >= 0 } {
        if { [llength $line] == 0 } { continue }
        if { [regexp {^#} [lindex $line 0]] } { continue }
        set start [get_pins -quiet [lindex $line 0]]
        if { $start == "" } {
            set start [get_ports -quiet [lindex $line 0]]
            if { $start == "" } {
                puts "Warning(DLCLT) : Start Pin or Port [lindex $line 0] is not found in design."
            }
        }
        set end [get_pins -quiet [lindex $line 1]]
        if { $end == "" } {
            set end [get_ports -quiet [lindex $line 1]]
            if { $end == "" } {
                puts "Warning(DLCLT) : End Pin or Port [lindex $line 1] is not found in design."
            }
        }
        if { $start == "" || $end == "" } { continue }
        set tp [get_timing_paths -from $start -to $end \
                -slack_lesser_than inf \
                -nworst $nworst -max_paths $max_paths -unique_pins]
        if { $tp == "" } {
            puts "Warning(DLCLT) : No timing path."
            puts "      From Pin : [lindex $line 0]"
            puts "      To Pin   : [lindex $line 1]"
            continue
        }
        set first_tp [index_collection $tp 0]
        if { [judge_half_cycle $first_tp] == 1 } {
            set half_cycle_path [add_to_collection -unique $half_cycle_path $tp]
        }
    }
    close $in_fd

    return $half_cycle_path
}

proc get_start_edge {
    tp
} {
    set edge_type [get_attribute $tp startpoint_clock_open_edge_type]
    set inv_flag [get_attribute $tp startpoint_clock_is_inverted]
    set clk_edge [judge_waveform_edge [get_attribute $tp startpoint_clock]]

    return [judge_edge_cond $edge_type $inv_flag $clk_edge]
}

proc get_end_edge {
    tp
} {
    set edge_type [get_attribute $tp endpoint_clock_close_edge_type]
    set inv_flag [get_attribute $tp endpoint_clock_is_inverted]
    set clk_edge [judge_waveform_edge [get_attribute $tp endpoint_clock]]

    return [judge_edge_cond $edge_type $inv_flag $clk_edge]
}

proc judge_edge_cond {
    cell_edge
    inv_flag
    clk_edge
} {
    if { $clk_edge == "rise" } {
        if { $cell_edge == "rise" } {
            if { $inv_flag == "false" } {
                return "rise"
            } else {
                return "fall"
            }
        } else {
            if { $inv_flag == "false" } {
                return "fall"
            } else {
                return "rise"
            }
        }
    } else {
        if { $cell_edge == "rise" } {
            if { $inv_flag == "false" } {
                return "fall"
            } else {
                return "rise"
            }
        } else {
            if { $inv_flag == "false" } {
                return "rise"
            } else {
                return "fall"
            }
        }
    }
}

proc make_half_cycle_check_filter {
    include_list
    exclude_list
    filter_In
} {
    upvar filter $filter_In
    set include_filter ""
    if { $include_list != "" } {
        if { [catch {open $include_list "r"} in_fd] } {
            puts "Error(DLCLT) : Cannot open file. $include_list"
            return 1
        }
        while { [gets $in_fd line] >= 0 } {
            if { [llength $line] == 0 } { continue }
            if { [regexp {^#} [lindex $line 0]] } { continue }
            regsub -all {^\s} $line {} line
            if { $include_filter == "" } {
                set include_filter "full_name=~${line}/*"
            } else {
                append include_filter "||full_name=~${line}/*"
            }
        }
        close $in_fd
    }
    set exclude_filter ""
    if { $exclude_list != "" } {
        if { [catch {open $exclude_list "r"} in_fd] } {
            puts "Error(DLCLT) : Cannot open file. $exclude_list"
            return 1
        }
        while { [gets $in_fd line] >= 0 } {
            if { [llength $line] == 0 } { continue }
            if { [regexp {^#} [lindex $line 0]] } { continue }
            if { $exclude_filter == "" } {
                set exclude_filter "full_name!~${line}/*"
            } else {
                append exclude_filter "&&full_name!~${line}/*"
            }
        }
        close $in_fd
    }
    if { $include_filter != "" && $exclude_filter != "" } {
        set filter "\"($include_filter)&&($exclude_filter)\""
    } elseif { $include_filter != "" } {
        set filter $include_filter
    } elseif { $exclude_filter != "" } {
        set filter $exclude_filter
    } else {
        set filter ""
    }
    return 0
}

proc judge_waveform_edge {
    clock
} {
    global DLCLT_MIN_EPS

    set period [get_attribute -quiet $clock period]
    set waveform [get_attribute -quiet $clock waveform]
    set rise_edge [lindex [lindex $waveform 0] 0]
    set fall_edge [lindex [lindex $waveform 0] 1]

    set nstart 0
    while { 1 } {
        set nperiod [expr $period * $nstart]
        set diff [expr $nperiod - $rise_edge]
        if { $diff > $DLCLT_MIN_EPS } {
            break
        }
        incr nstart
    }

    set diff [expr $nperiod - $fall_edge]
    if { $diff > $DLCLT_MIN_EPS } {
        return "rise"
    } else {
        return "fall"
    }
}

proc judge_half_cycle {
    tp
} {
    global DLCLT_MIN_EPS

    set enable_different_clock $::DLCLT_ENABLE_HALF_CYCLE_CLOCK_HI_LO

    set start_edge [get_start_edge $tp]
    set end_edge [get_end_edge $tp]
    if { [string equal $enable_different_clock "yes"] } {
        set from_clock [get_attribute -q $tp startpoint_clock]
        set to_clock [get_attribute -q $tp endpoint_clock]
        if { $from_clock == "" || $to_clock == "" } {
            return [judge_half_cycle_same_clk $start_edge $end_edge]
        } else {
            set from_period [get_attribute -q $from_clock period]
            if { $from_period == "" } { set from_period 1.0e10 }
            set to_period [get_attribute -q $to_clock period]
            if { $to_period == "" } { set to_period 1.0e10 }
            if { $from_period > $to_period } {
                set ratio [get_clock_ratio $to_period $from_period]
                if { [expr $ratio % 2] > 0 } {
                    return [judge_half_cycle_same_clk $start_edge $end_edge]
                } else {
                    return [judge_half_cycle_from_lf_to_hf $start_edge $end_edge]
                }
            } else {
                set ratio [get_clock_ratio $from_period $to_period]
                if { [expr $ratio % 2] > 0 } {
                    return [judge_half_cycle_same_clk $start_edge $end_edge]
                } else {
                    return [judge_half_cycle_from_hf_to_lf $start_edge $end_edge]
                }
            }
        }
    } else {
        return [judge_half_cycle_same_clk $start_edge $end_edge]
    }
}

proc judge_half_cycle_same_clk {
    start_edge
    end_edge
} {
    if { $start_edge != $end_edge } {
        return 1
    } else {
        return 0
    }
}

proc judge_half_cycle_from_lf_to_hf {
    start_edge
    end_edge
} {
    if { $start_edge == "rise" && $end_edge == "fall" } {
        return 1
    } elseif { $start_edge == "fall" && $end_edge == "fall" } {
        return 1
    } else {
        return 0
    }
}

proc judge_half_cycle_from_hf_to_lf {
    start_edge
    end_edge
} {
    if { $start_edge == "fall" && $end_edge == "rise" } {
        return 1
    } elseif { $start_edge == "fall" && $end_edge == "fall" } {
        return 1
    } else {
        return 0
    }
}

proc get_clock_ratio {
    clk1_period
    clk2_period
} {

    global DLCLT_HALF_CYCLE_DIFFERENT_CLOCK_MARGIN

    set div [expr $clk2_period / $clk1_period]

    set ratio [expr int($div)]
    set diff [expr $div - $ratio]
    if { $ratio > 10000 } {
        return 1
    } elseif { $diff <= $DLCLT_HALF_CYCLE_DIFFERENT_CLOCK_MARGIN } {
        return $ratio
    } elseif { $diff >= [expr 1.0 - $DLCLT_HALF_CYCLE_DIFFERENT_CLOCK_MARGIN] } {
        return [expr $ratio + 1]
    } else {
        return -1
    }
}

proc out_half_cycle_list {
    half_cycle_path_in
    outfile
} {
    upvar $half_cycle_path_in HC_Path
    if { [catch {open $outfile "w"} out_fd] } {
        puts "Error(DLCLT) : Cannot open file. $outfile"
        return
    }

    puts -nonwiline $out_fd "#
# Half Cycle Path Start and End pin list
#     Date : [clock format [clock seconds]]
#"

    if { [array exists HC_path] } {
        foreach key [array names HC_path] {
            foreach tp $HC_path($key) {
                set start [get_object_name [get_attribute $tp startpoint]]
                set end   [get_object_name [get_attribute $tp endpoint]]
                puts $out_fd "$start $end"
            }
        }
    } elseif { [info exists HC_path] } {
        foreach tp $HC_path($key) {
            set start [get_object_name [get_attribute $tp startpoint]]
            set end   [get_object_name [get_attribute $tp endpoint]]
            puts $out_fd "$start $end"
        }
    }

    close $out_fd
}

proc filter_half_cycle_pin {
    timing_path
    filter
} {
    set allpin [get_attribute [get_attribute $timing_path points] object]

    if { $filter != "" } {
        return [filter_collection $allpin $filter]
    } else {
        return $allpin
    }
}

proc get_half_cycle_path_odd_clk {
    from_clock
    to_clock
    array_key
} {
    global DLCLT_HalfCyclePath

    set DLCLT_HalfCyclePath($array_key,r2f) \
                [get_timing_paths -rise_from $from_clock \
                -fall_to $to_clock -slack_lesser_than inf \
                -max_paths 2000000 -nworst 2000000 -unique_pins]
    set DLCLT_HalfCyclePath($array_key,f2r) \
                [get_timing_paths -fall_from $from_clock \
                 -rise_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]

    return
}

proc get_half_cycle_path_odd_clk_inv {
    from_clock
    to_clock
    array_key
} {
    global DLCLT_HalfCyclePath

    set DLCLT_HalfCyclePath($array_key,r2r) \
                [get_timing_paths -rise_from $from_clock \
                 -rise_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]
    set DLCLT_HalfCyclePath($array_key,f2f) \
                [get_timing_paths -fall_from $from_clock \
                 -fall_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]

    return
}

proc get_half_cycle_path_hf2lf_even_clk {
    from_clock
    to_clock
    array_key
} {
    global DLCLT_HalfCyclePath

    set DLCLT_HalfCyclePath($array_key,f2r) \
                [get_timing_paths -fall_from $from_clock \
                 -rise_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]
    set DLCLT_HalfCyclePath($array_key,f2f) \
                [get_timing_paths -fall_from $from_clock \
                 -fall_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]

    return
}

proc get_half_cycle_path_hf2lf_even_clk_inv {
    from_clock
    to_clock
    array_key
} {
    global DLCLT_HalfCyclePath

    set DLCLT_HalfCyclePath($array_key,r2r) \
                [get_timing_paths -rise_from $from_clock \
                 -rise_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]
    set DLCLT_HalfCyclePath($array_key,r2f) \
                [get_timing_paths -rise_from $from_clock \
                 -fall_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]

    return
}

proc get_half_cycle_path_lf2hf_even_clk {
    from_clock
    to_clock
    array_key
} {
    global DLCLT_HalfCyclePath

    set DLCLT_HalfCyclePath($array_key,r2f) \
                [get_timing_paths -rise_from $from_clock \
                 -fall_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]
    set DLCLT_HalfCyclePath($array_key,f2f) \
                [get_timing_paths -fall_from $from_clock \
                 -fall_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]

    return
}

proc get_half_cycle_path_lf2hf_even_clk_inv {
    from_clock
    to_clock
    array_key
} {
    global DLCLT_HalfCyclePath

    set DLCLT_HalfCyclePath($array_key,r2r) \
                [get_timing_paths -rise_from $from_clock \
                 -rise_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]
    set DLCLT_HalfCyclePath($array_key,f2r) \
                [get_timing_paths -fall_from $from_clock \
                 -rise_to $to_clock -slack_lesser_than inf \
                 -max_paths 2000000 -nworst 2000000 -unique_pins]

    return
}

proc get_half_cycle_path_alledge {
    from_clock
    to_clock
} {
    global DLCLT_HALF_CYCLE_MAXTRAN_ASYNCHRONOUS
    global DLCLT_AsyncHalfCyclePath

    if { [string equal -nocase $DLCLT_HALF_CYCLE_MAXTRAN_ASYNCHRONOUS "no"] } {
        return
    } elseif { [string equal -nocase $DLCLT_HALF_CYCLE_MAXTRAN_ASYNCHRONOUS "half"] } {
        set to_wf_edge [judge_waveform_edge $to_clock]
        foreach_in_collection clk $from_clock {
            set warn_flag 0
            set key "[get_object_name $clk],[get_object_name $to_clock]"
            set from_wf_edge [judge_waveform_edge $clk]
            if { $to_wf_edge == $from_wf_edge } {
                get_half_cycle_path_odd_clk $clk $to_clock $key
                if { [sizeof_collection $DLCLT_HalfCyclePath($key,r2f)] > 0 || \
                        [sizeof_collection $DLCLT_HalfCyclePath($key,f2r)] > 0 } {
                    set warn_flag 1
                }
            } else {
                get_half_cycle_path_odd_clk_inv $clk $to_clock $key
                if { [sizeof_collection $DLCLT_HalfCyclePath($key,r2r)] > 0 || \
                        [sizeof_collection $DLCLT_HalfCyclePath($key,f2f)] > 0 } {
                    set warn_flag 1
                }
            }
            if { $warn_flag == 1 } {
                puts "Warning(DLCLT) : Asynchronous clocks path exists."
                puts "  Start : [get_object_name $clk]"
                puts "  End   : [get_object_name $to_clock]"
            }
        }
    } else {
        foreach_in_collection clk $from_clock {
            set key "[get_object_name $clk],[get_object_name $to_clock]"
            set DLCLT_AsyncHalfCyclePath($key) \
                        [get_timing_paths -from $clk -to $to_clock \
                        -slack_lesser_than inf \
                        -max_paths 2000000 -nworst 2000000]
            if { [sizeof_collection $DLCLT_AsyncHalfCyclePath($key)] > 0 } {
                puts "Warning(DLCLT) : Asynchronous clocks path exists."
                puts "  Start : [get_object_name $clk]"
                puts "  End   : [get_object_name $to_clock]"
            }
        }
    }

    return
}

############################################################
# Set MaxTransition for low drive cell procedures
#     Generated by make_DRV_script V03.01.00
############################################################
### Margin value
set DLCLT_MAXTRAN_LOWDRV_MARGIN 1.0
if { [expr abs($DLCLT_MAXTRAN_LOWDRV_MARGIN - 1.0)] > 0.000001 } {
    puts "Information(DLCLT): DLCLT_MAXTRAN_LOWDRV_MARGIN is not 1.0"
}

##----------------------------------------------------------
## Procedure : Check drive
##----------------------------------------------------------
### THH
proc RV28F_check_drive_limit_THH { drive } {
    if { $drive <= 20 } {
        return 1
    }
    return 0
}
### TSH
proc RV28F_check_drive_limit_TSH { drive } {
    if { $drive <= 15 } {
        return 1
    }
    return 0
}
### TULH
proc RV28F_check_drive_limit_TULH { drive } {
    if { $drive <= 8 } {
        return 1
    }
    return 0
}
### HVT
proc RV28FT_check_drive_limit_HVT { drive } {
    if { $drive <= 20 } {
        return 1
    }
    return 0
}

### SVT
proc RV28FT_check_drive_limit_SVT { drive } {
    if { $drive <= 15 } {
        return 1
    }
    return 0
}

### ULVT
proc RV28FT_check_drive_limit_ULVT { drive } {
    if { $drive <= 8 } {
        return 1
    }
    return 0
}
##----------------------------------------------------------
## Procedures : set MaxTransition of low drive cells
##----------------------------------------------------------
############################################################
# PROCEDURE       : RV28F_set_maxtran_lowdrv_Vall_Fto300MHz
# PROCEDURE       : RV28FT_set_maxtran_lowdrv_Vall_Fall
# TYPE            : lowdrv
# VOLTAGE RANGE   : 0.0[V] - inf[V]
# FREQUENCY RANGE : 0.0[Hz] - 300M[Hz]
# FREQUENCY RANGE : 0.0[Hz] - inf[Hz]
# MARGIN          : 1.0
#---------------------------------------
# VT        Drive     Constraint
#---------------------------------------
# THH       2.0       0.4       
# TSH       1.5       0.6       
# TULH      0.8       0.7       
# HVT       2.0       0.40      
# SVT       1.5       0.60      
# ULVT      0.8       0.70   
############################################################
set RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_THH_X20  [expr $Tfactor*0.4*$DLCLT_MAXTRAN_LOWDRV_MARGIN]
set RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TSH_X15  [expr $Tfactor*0.6*$DLCLT_MAXTRAN_LOWDRV_MARGIN]
set RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TULH_X08 [expr $Tfactor*0.7*$DLCLT_MAXTRAN_LOWDRV_MARGIN]
set RV28FT_MAXTRAN_LOWDRV_Vall_Fall_HVT_X20 [expr $Tfactor*0.40*$DLCLT_MAXTRAN_LOWDRV_MARGIN]
set RV28FT_MAXTRAN_LOWDRV_Vall_Fall_SVT_X15 [expr $Tfactor*0.60*$DLCLT_MAXTRAN_LOWDRV_MARGIN]
set RV28FT_MAXTRAN_LOWDRV_Vall_Fall_ULVT_X8 [expr $Tfactor*0.70*$DLCLT_MAXTRAN_LOWDRV_MARGIN]

proc RV28F_set_maxtran_lowdrv_Vall_Fto300MHz_THH { pin drive overwrite } {
    global DLCLT_SET_MAXTRAN_LOWDRV_FLAG
    if { $drive <= 20 } {
        if { $overwrite == 1 } {
            set_max_transition $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_THH_X20 $pin
            set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
        } else {
            set old_const [get_attribute -quiet $pin max_transition]
            if { $old_const == "" } {
                set old_const 999.999
            }
            if { $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_THH_X20 < $old_const } {
                set_max_transition $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_THH_X20 $pin
                set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
            }
        }
    }
}

proc RV28F_set_maxtran_lowdrv_Vall_Fto300MHz_TSH { pin drive overwrite } {
    global DLCLT_SET_MAXTRAN_LOWDRV_FLAG
    if { $drive <= 15 } {
        if { $overwrite == 1 } {
            set_max_transition $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TSH_X15 $pin
            set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
        } else {
            set old_const [get_attribute -quiet $pin max_transition]
            if { $old_const == "" } {
                set old_const 999.999
            }
            if { $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TSH_X15 < $old_const } {
                set_max_transition $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TSH_X15 $pin
                set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
            }
        }
    }
}


proc RV28F_set_maxtran_lowdrv_Vall_Fto300MHz_TULH { pin drive overwrite } {
    global DLCLT_SET_MAXTRAN_LOWDRV_FLAG
    if { $drive <= 8 } {
        if { $overwrite == 1 } {
            set_max_transition $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TULH_X08 $pin
            set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
        } else {
            set old_const [get_attribute -quiet $pin max_transition]
            if { $old_const == "" } {
                set old_const 999.999
            }
            if { $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TULH_X08 < $old_const } {
                set_max_transition $::RV28F_MAXTRAN_LOWDRV_Vall_Fto300MHz_TULH_X08 $pin
                set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
            }
        }
    }
}

## set_maxtran_lowdrv_Vall_Fall for HVT cells
proc RV28FT_set_maxtran_lowdrv_Vall_Fall_HVT { pin drive overwrite } {
    global DLCLT_SET_MAXTRAN_LOWDRV_FLAG
    if { $drive <= 20 } {
        if { $overwrite == 1 } {
            set_max_transition $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_HVT_X20 $pin
            set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
        } else {
            set old_const [get_attribute -quiet $pin max_transition]
            if { $old_const == "" } {
                set old_const 999.999
            }
            if { $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_HVT_X20 < $old_const } {
                set_max_transition $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_HVT_X20 $pin
                set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
            }
        }
    }
}

## set_maxtran_lowdrv_Vall_Fall for SVT cells
proc RV28FT_set_maxtran_lowdrv_Vall_Fall_SVT { pin drive overwrite } {
    global DLCLT_SET_MAXTRAN_LOWDRV_FLAG
    if { $drive <= 15 } {
        if { $overwrite == 1 } {
            set_max_transition $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_SVT_X15 $pin
            set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
        } else {
            set old_const [get_attribute -quiet $pin max_transition]
            if { $old_const == "" } {
                set old_const 999.999
            }
            if { $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_SVT_X15 < $old_const } {
                set_max_transition $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_SVT_X15 $pin
                set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
            }
        }
    }
}

## set_maxtran_lowdrv_Vall_Fall for ULVT cells
proc RV28FT_set_maxtran_lowdrv_Vall_Fall_ULVT { pin drive overwrite } {
    global DLCLT_SET_MAXTRAN_LOWDRV_FLAG
    if { $drive <= 8 } {
        if { $overwrite == 1 } {
            set_max_transition $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_ULVT_X8 $pin
            set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
        } else {
            set old_const [get_attribute -quiet $pin max_transition]
            if { $old_const == "" } {
                set old_const 999.999
            }
            if { $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_ULVT_X8 < $old_const } {
                set_max_transition $::RV28FT_MAXTRAN_LOWDRV_Vall_Fall_ULVT_X8 $pin
                set DLCLT_SET_MAXTRAN_LOWDRV_FLAG 1
            }
        }
    }
}
