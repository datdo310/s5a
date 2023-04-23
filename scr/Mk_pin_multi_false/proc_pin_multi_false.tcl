################################################################################
# Proc : mk_inputAC_false
#   Make input ac false script for SOC product.
################################################################################
proc mk_inputAC_false { pad_inst patten_file output_file } {

  # Make port name list
    set all_port_coll [get_ports *]
    foreach_in_collection coll $all_port_coll {
	lappend all_port_list [get_object_name $coll]
    }

  # Make padlogic output pin list that connected to internal module
    set pad_out_coll [get_pins ${pad_inst}/* -filter "direction==out"]
    foreach_in_collection coll $pad_out_coll {
	set pad_o_pin [get_object_name $coll]
	set net_name [get_object_name [get_nets -of $coll]]
	if {$net_name == ""} {continue}
	if {[lsearch $all_port_list $net_name]!=-1} {continue}

	set connect_inst($pad_o_pin) ""
	set connect_pin_col [get_pin -of $net_name -filter "direction==in"]
	foreach_in_collection pin_col $connect_pin_col {
	    set pin_name [get_object_name $pin_col]
	    regsub {\/.*} $pin_name "" conn_inst
	    regsub {gpio.*} $conn_inst "gpio*" conn_inst
	    lappend connect_inst($pad_o_pin) $conn_inst
	}
    }

    if {[catch {open $patten_file r} PAT]} {
	puts "Error : Can not open pattern file ($patten_file)"
	return
    }
    if {[catch {open $output_file w} OUT]} {
	puts "Error : Can not create false const file ($output_file)"
	return
    }

    puts $OUT "#########################################################################################"
    puts $OUT "#   False setting of Input multiple AC"
    puts $OUT "#      Made by mk_inputAC_false : [date]"
    puts $OUT "#########################################################################################"

    set head {#set_false_path -from [get_clock }
    set middle1 {] -through [get_ports }
    set middle2 {] -through [r_get_cellpin }
    set tail {]}
    while {[gets $PAT line]>=0} {
	regsub { *$} $line "" line
	set port_name [lindex $line 0]
	puts "Searching input false of port : $port_name"
	puts $OUT "\#"
	puts $OUT "\# Target port : $port_name"
	puts $OUT "\#"
	if {[llength $line] == 1 } {
	    puts $OUT ""
	    continue
	}
	set path_pad_out {}
    #
    # Search pad pins and connected instance that in logic from ports.
    #
	foreach_in_collection pin_coll [filter_collection [all_fanout -from $port_name] "pin_direction==out"] {
	    set pad_pin [get_object_name $pin_coll]
	    if {[regexp "^${pad_inst}/" $pad_pin]==0} {continue}
	    set other_pad_pins [remove_from_collection $pad_out_coll $pin_coll]
	    set path_col [get_timing_path -from [get_ports $port_name] -through [get_pins $pad_pin] -exclude $other_pad_pins]
	    if {[sizeof_collection $path_col]>0} { lappend path_pad_out $pad_pin }
	}
    #
    # Make false setting to unnecessary timing path that through of pad pins
    #
	foreach path [lrange $line 1 end] {
	    set clock [lindex $path 0]
	    set true_inst [lrange $path 1 end]
	    foreach pad_pin $path_pad_out {
		set false 1
		foreach inst $connect_inst($pad_pin) {
		    if {[lsearch $true_inst $inst]!=-1} { set false 0 }
	        }
		if { $false == 1 } {
		    puts $OUT "$head$clock$middle1$port_name$middle2$pad_pin$tail"
		}
	    }
	}
	puts $OUT ""
    }
    close $OUT

}

################################################################################
# Proc : mk_output_false
#   Make output ac false script for SOC product.
################################################################################
proc mk_outputAC_false { pad_inst patten_file output_file } {

  # Make port name list
    set all_port_coll [get_ports *]
    foreach_in_collection coll $all_port_coll {
	lappend all_port_list [get_object_name $coll]
    }

  # Make padlogic output pin list that connected to internal module
    set pad_in_coll [get_pins ${pad_inst}/* -filter "direction==in"]
    foreach_in_collection coll $pad_in_coll {
	set pad_i_pin [get_object_name $coll]
	set net_name [get_object_name [get_nets -of $coll]]
	if {$net_name == ""} {continue}
	if {[lsearch $all_port_list $net_name]!=-1} {continue}

	lappend pad_out_list $pad_i_pin
	set connect_inst($pad_i_pin) ""
	set connect_pin_col [get_pin -of $net_name -filter "direction==out"]
	foreach_in_collection pin_col $connect_pin_col {
	    set pin_name [get_object_name $pin_col]
	    regsub {\/.*} $pin_name "" conn_inst
	    regsub {gpio.*} $conn_inst "gpio*" conn_inst
	    lappend connect_inst($pad_i_pin) $conn_inst
	}
    }

    if {[catch {open $patten_file r} PAT]} {
	puts "Error : Can not open pattern file ($patten_file)"
	return
    }
    if {[catch {open $output_file w} OUT]} {
	puts "Error : Can not create false const file ($output_file)"
	return
    }

    puts $OUT "#########################################################################################"
    puts $OUT "#   False setting of Output multiple AC"
    puts $OUT "#      Made by mk_outputAC_false : [date]"
    puts $OUT "#########################################################################################"

    set head {#set_false_path -through [r_get_cellpin }
    set middle1 {] -through [get_ports }
    set middle2 {] -to [get_clocks }
    set tail {]}
    while {[gets $PAT line]>=0} {
	regsub { *$} $line "" line
	set port_name [lindex $line 0]
	puts "Searching output false of port : $port_name"
	puts $OUT "\#"
	puts $OUT "\# Target port : $port_name"
	puts $OUT "\#"
	if {[llength $line] == 1 } {
	    puts $OUT ""
	    continue
	}
	set path_pad_in {}
    #
    # Search pad pins that include timng path of target ports
    #
	foreach_in_collection pin_coll [filter_collection [all_fanin -to $port_name] "pin_direction==in"] {
	    set pad_pin [get_object_name $pin_coll]
	    if {[regexp "^${pad_inst}/" $pad_pin]==0} {continue}
	    set other_pad_pins [remove_from_collection $pad_in_coll $pin_coll]
	    set path_col [get_timing_path -through [get_pins $pad_pin] -to [get_ports $port_name] -exclude $other_pad_pins]
	    if {[sizeof_collection $path_col]>0} { lappend path_pad_in $pad_pin }
	}
    #
    # Make false setting to unnecessary timing path that through pad pins.
    #
	foreach path [lrange $line 1 end] {
	    set clock [lindex $path 0]
	    set true_inst [lrange $path 1 end]
	    foreach pad_pin $path_pad_in {
		set false 1
		foreach inst $connect_inst($pad_pin) {
		    if {[lsearch $true_inst $inst]!=-1} { set false 0 }
	        }
		if { $false == 1 } {
		    puts $OUT "$head$pad_pin$middle1$port_name$middle2$clock$tail"
		}
	    }
	}
	puts $OUT ""
    }
    close $OUT

}

# $Id: r_tcl.pt,v 1.3modify1 2005/12/26 08:06:34 nakayaka Exp $
# History:
# Version  Date       Author     Description
# v0.0     2005/11/25 K.Nakayama    Original
#   new proc "r_get_cellpin","r_get_top_net"
#    "r_get_up_inst" is sub proc of "r_get_top_net"
# ---------------------------------------------------------------------
# (C) Copyright 2005 Renesas Technology Corp. All rights reserved.
# -HC -----------------------------------------------------------------


proc r_get_top_net {target_pin} {
  set net [get_nets -q -of_objects $target_pin]
  set i 1
  while {$i > 0} {
    set i 0
    set net_name [get_attribute $net full_name]
    foreach_in_collection net2 [get_nets -q -of_objects $net_name] {
      if {$net_name != [get_attribute $net2 full_name]} {
        set net $net2
        incr i
      }
    }
  }
  return [get_attribute $net full_name]
}
proc r_get_up_inst {target_pin len} {
  set cell [get_cell -quiet -of_objects $target_pin]
  set len_full [string length [get_attribute $cell full_name]]
  set len_base [string length [get_attribute $cell base_name]]
  set string_end [expr $len_full - $len_base -2 ]
  while {[expr $string_end+2] > $len} {
    set cell [get_cell [string range [get_attribute $cell full_name] 0 $string_end] ]
    set len_full [string length [get_attribute $cell full_name]]
    set len_base [string length [get_attribute $cell base_name]]
    set string_end [expr $len_full - $len_base -2]
  }
  return [get_attribute $cell full_name]
}

proc r_get_cellpin { target_pin_string } {
  set target_pin {} 
  foreach each_pin_string $target_pin_string {
    set target_pin_add [get_net -quiet "$each_pin_string $each_pin_string[*]"]
    set target_pin [add_to_collection $target_pin $target_pin_add]
  }
  set c_i [list [current_instance .]]
  current_instance >> /dev/null
  set return_primitive_pin {}
  if { [sizeof_collection $target_pin] != 0 } {
    foreach_in_collection each_target_net $target_pin {
      set each_target_pin [get_pin -quiet [get_attribute $each_target_net full_name]]
      set each_target_port [get_port -quiet [get_attribute $each_target_net full_name]]
      if { [sizeof_collection $each_target_pin] != 0 } {
        set pin_int_input {}
        set pin_int_output {}
        set pin_ext_input {}
        set pin_ext_output {}
        set target_pin_name [get_attribute $each_target_pin full_name]
        set connect_pin [get_pin -l -of $target_pin_name]
        foreach_in_collection each_connect_pin $connect_pin {
          set target_inst [get_cell -of $each_target_pin]
          set target_inst_name [get_attribute $target_inst full_name]
          set len_target_inst [string length $target_inst_name]
          set inst_connect_pin [r_get_up_inst $each_connect_pin $len_target_inst]
          if {$inst_connect_pin == $target_inst_name} {
            set flag_int_ext "in"
          } else {
            set flag_int_ext "out"
          }
          # echo $inst_connect_pin $target_inst_name
          if {$flag_int_ext == "in"} {
            if {[get_attribute $each_connect_pin direction]=="in"} {
              set pin_int_input [add_to_collection $pin_int_input $each_connect_pin]
              # echo [get_attribute $each_connect_pin full_name] "AAA"
            }
            if {[get_attribute $each_connect_pin direction]=="out"} {
              set pin_int_output [add_to_collection $pin_int_output $each_connect_pin]
              # echo [get_attribute $each_connect_pin full_name] "AA2"
            }
            if {[get_attribute $each_connect_pin direction]=="inout"} {
              set pin_int_input [add_to_collection $pin_int_input $each_connect_pin]
              set pin_int_output [add_to_collection $pin_int_output $each_connect_pin]
              # echo [get_attribute $each_connect_pin full_name] "AA3"
            }
          } else {
            if {[get_attribute $each_connect_pin direction]=="in"} {
              set pin_ext_input [add_to_collection $pin_ext_input $each_connect_pin]
              # echo [get_attribute $each_connect_pin full_name] "AA4"
            }
            if {[get_attribute $each_connect_pin direction]=="out"} {
              set pin_ext_output [add_to_collection $pin_ext_output $each_connect_pin]
              # echo [get_attribute $each_connect_pin full_name] "AA5"
            }
            if {[get_attribute $each_connect_pin direction]=="inout"} {
              set pin_ext_input [add_to_collection $pin_ext_input $each_connect_pin]
              set pin_ext_output [add_to_collection $pin_ext_output $each_connect_pin]
              # echo [get_attribute $each_connect_pin full_name] "AA6"
            }
          }
        }
        foreach_in_collection each_connect_port [get_port -q [r_get_top_net $each_target_pin]] {
          if {[get_attribute $each_connect_port direction]=="out"} {
            set pin_ext_input [add_to_collection $pin_ext_input $each_connect_port]
          }
          if {[get_attribute $each_connect_port direction]=="in"} {
            set pin_ext_output [add_to_collection $pin_ext_output $each_connect_port]
          }
          if {[get_attribute $each_connect_port direction]=="inout"} {
            set pin_ext_input [add_to_collection $pin_ext_input $each_connect_port]
            set pin_ext_output [add_to_collection $pin_ext_output $each_connect_port]
          }
        }
        if {[sizeof_collection $pin_int_input] == 0} {
          set return_primitive_pin [add_to_collection $return_primitive_pin $pin_int_output]
        } elseif {[sizeof_collection $pin_ext_input] == 0} {
          set return_primitive_pin [add_to_collection $return_primitive_pin $pin_ext_output]
        } elseif {[sizeof_collection $pin_int_output] == 0} {
          set return_primitive_pin [add_to_collection $return_primitive_pin $pin_int_input]
        } elseif {[sizeof_collection $pin_ext_output] == 0} {
          set return_primitive_pin [add_to_collection $return_primitive_pin $pin_ext_input]
        } else {
          echo "Error: Not move target_pin"
        }
        # echo [sizeof_collection $pin_int_input] [sizeof_collection $pin_int_output]
        # echo [sizeof_collection $pin_ext_input] [sizeof_collection $pin_ext_output]
      } elseif { [sizeof_collection $each_target_port] != 0 } {
        set return_primitive_pin [add_to_collection $return_primitive_pin $each_target_port]
      } else {
        echo "Error : Dont set net!!  r_get_cellpin(" $target_pin_string ")"
      }
    }
  } else {
      echo "Error :  Nothing matched!!  r_get_cellpin(" $target_pin_string ")"
  }
  if {$c_i != "{}"} {
    current_instance $c_i
  }
  return $return_primitive_pin
}

