#
# History:
# Version  Date       Author     Description
# v1.0     2005/11/25 K.Nakayama    Original
# v2.0     2012/08/08 K.Nakayama    Renewal
#          take measurures to "assign"
# v2.1     2012/10/02 K.Nakayama    added "global synopsys_program_name"
# v2.2     2012/10/16 K.Nakayama    commnet out echo for debug
#                                   get_pin's option add -quiet by port name
# v2.3     2012/05/14 K.Nakayama    add proc "r_get_lowerpin","r_check_pin"
# v3.0     2012/05/27 K.Nakayama    Renewal 
# v4.0     2012/06/21 K.Nakayama    change priority leaf_pin_lower_input,leaf_pin_upper_output
# v5.0     2012/12/10 K.Nakayama    add options "-driver|-receiver|-lower|upper"
#                                   Change the processing of 1'b1/1'b0
# v5.1     2013/01/06 K.Nakayama    fix bug "multi port assign"
# v5.2     2013/06/23 K.Nakayama    add GCA support
# v5.2.1   2018/06/12 A.Yoshida     add PTC support
# ---------------------------------------------------------------------
# (C) Copyright 2012 Renesas Electronics Corp. All rights reserved.
# ---------------------------------------------------------------------


proc r_get_cellpin { target_pin_string {alter_target_pin_string 0}} {

  global synopsys_program_name
  if { ( $synopsys_program_name == "pt_shell" ) || ( $synopsys_program_name == "gca_shell" ) || ( $synopsys_program_name == "ptc_shell" ) } {
  } else {
    return $target_pin_string
  }
  if {$alter_target_pin_string == 0} {
    set alter_target_pin_string $target_pin_string
    set target_pin_string ""
  } elseif {$target_pin_string != "-driver" && $target_pin_string != "-receiver" && $target_pin_string != "-lower" && $target_pin_string != "-upper"} {
      echo "Error (r_get_cellpin) : usage  r_get_cellpin \[-driver|-receiver|-lower|upper\] pins"
      return
  }

  set return_primitive_pin {}
  set all_traget_port [get_port -quiet $alter_target_pin_string]
  set all_traget_pin  [get_pin  -quiet $alter_target_pin_string]
  if { [sizeof_collection $all_traget_port] == 0 && [sizeof_collection $all_traget_pin] == 0} {
    echo "Error (r_get_cellpin) : " $alter_target_pin_string " can not be found !!"
    return $return_primitive_pin
  }

  set target_pin_net {}
  foreach each_pin_string $alter_target_pin_string {
    set traget_port [get_port -quiet $each_pin_string]
    set traget_pin  [get_pin  -quiet $each_pin_string]
    set traget_pin_leaf  [get_pin  -quiet $each_pin_string -filter "is_hierarchical == false"]
    set traget_pin_hier  [get_pin  -quiet $each_pin_string -filter "is_hierarchical == true"]
    if { [sizeof_collection $traget_port] == 0 && [sizeof_collection $traget_pin] == 0} {
      echo "Error (r_get_cellpin) : The pin " $each_pin_string " can not be found !!"
    }
    if { [sizeof_collection $traget_port] != 0} {
      set return_primitive_pin [add_to_collection $return_primitive_pin $traget_port]
    }
    if { [sizeof_collection $traget_pin_leaf] != 0} {
      set return_primitive_pin [add_to_collection $return_primitive_pin $traget_pin_leaf]
    }
    foreach_in_collection each_traget_pin_hier $traget_pin_hier {
      if { [sizeof_collection [get_net -quiet [get_attribute $each_traget_pin_hier full_name]]] != 0} {
        set target_pin_net [add_to_collection $target_pin_net $each_traget_pin_hier]
      } else {
        echo "Error (r_get_cellpin) : The net " $each_pin_string " can not be found !!"
      }
    }
  }

  foreach_in_collection each_target_net $target_pin_net {
    set each_target_pin [get_pin -quiet [get_attribute $each_target_net full_name]]

    set leaf_pin     [get_pin -quiet -of [get_nets -of $each_target_net -boundary_type both] -leaf]
    set leaf_output  [filter_collection $leaf_pin "pin_direction == out || pin_direction == inout"]
    set _flag_pin_logic_1 [sizeof_collection [filter_collection $leaf_output "full_name =~ */Logic1/output"]]
    set _flag_pin_logic_0 [sizeof_collection [filter_collection $leaf_output "full_name =~ */Logic0/output"]]
    set _flag_net_logic_1 [sizeof_collection [get_nets -quiet -of $leaf_output -filter "base_name == *Logic1*"]]
    set _flag_net_logic_0 [sizeof_collection [get_nets -quiet -of $leaf_output -filter "base_name == *Logic0*"]]
    set leaf_input   [filter_collection $leaf_pin "pin_direction == in  || pin_direction == inout"]
    set leaf_port    [get_port -quiet -of [get_net -of $each_target_net -segments -boundary_type both]]
    set leaf_inport  [filter_collection $leaf_port "direction == in || direction == inout"]
    set leaf_outport [filter_collection $leaf_port "direction == out || direction == inout"]
    if { [sizeof_collection $leaf_input] == 0 && [sizeof_collection $leaf_outport] == 0} {
      echo "Warning (r_get_cellpin) : A reciever of " [get_attribute $each_target_pin full_name] " can not be found !!"
    }
    if { [sizeof_collection $leaf_output] == 0 && [sizeof_collection $leaf_inport] == 0} {
      echo "Error (r_get_cellpin) : A driver of " [get_attribute $each_target_pin full_name] " can not be found !!"
    } elseif { $_flag_net_logic_0 != 0 || $_flag_pin_logic_0 != 0} {
      echo "Error (r_get_cellpin) :" [get_attribute $each_target_pin full_name] " is connected *Logic0* !!"
    } elseif { $_flag_net_logic_1 != 0 || $_flag_pin_logic_1 != 0} {
      echo "Error (r_get_cellpin) :" [get_attribute $each_target_pin full_name] " is connected *Logic1* !!"
    } else {
      set net_upper [get_net -quiet -of $each_target_pin -boundary_type upper]
      set net_lower [get_net -quiet -of $each_target_pin -boundary_type lower]

      set i 1
      while {$i > 0} {
        set pin_lower [remove_from_collection [get_pin -quiet -of $net_lower] $each_target_pin]
        set port_lower [get_port -quiet -of $net_lower]
        set net_lower_new [get_net -quiet -of $pin_lower -boundary_type both]
        if {[compare_collections $net_lower $net_lower_new] ==0} {
          set i 0
        } else {
          set net_lower $net_lower_new
        }
      }
      set i 1
      while {$i > 0} {
        set pin_upper [remove_from_collection [get_pin -quiet -of $net_upper] $each_target_pin]
        set port_upper [get_port -quiet -of $net_upper]
        set net_upper_new [get_net -quiet -of $pin_upper -boundary_type both]
        if {[compare_collections $net_upper $net_upper_new] ==0} {
          set i 0
        } else {
          set net_upper $net_upper_new
        }
      }

      set leaf_pin_upper  [filter_collection $pin_upper  "is_hierarchical == false"]
      set leaf_pin_lower  [filter_collection $pin_lower  "is_hierarchical == false"]

      set leaf_pin_lower_input  [filter_collection $leaf_pin_lower "pin_direction == in  || pin_direction == inout"]
      set leaf_pin_lower_output [filter_collection $leaf_pin_lower "pin_direction == out || pin_direction == inout"]
      set leaf_pin_upper_input  [filter_collection $leaf_pin_upper "pin_direction == in  || pin_direction == inout"]
      set leaf_pin_upper_output [filter_collection $leaf_pin_upper "pin_direction == out || pin_direction == inout"]
      set port_lower_input  [filter_collection $port_lower "direction == in  || direction == inout"]
      set port_lower_output [filter_collection $port_lower "direction == out || direction == inout"]
      set port_upper_input  [filter_collection $port_upper "direction == in  || direction == inout"]
      set port_upper_output [filter_collection $port_upper "direction == out || direction == inout"]

      set size_lower_input  [expr [sizeof_collection $leaf_pin_lower_input] + [sizeof_collection $port_lower_output]]
      set size_lower_output [expr [sizeof_collection $leaf_pin_lower_output] + [sizeof_collection $port_lower_input]]
      set size_upper_input  [expr [sizeof_collection $leaf_pin_upper_input] + [sizeof_collection $port_upper_output]]
      set size_upper_output [expr [sizeof_collection $leaf_pin_upper_output] + [sizeof_collection $port_upper_input]]
      set flag_error 0

      if {$target_pin_string == "-driver"} {
        if {$size_lower_output != 0 && $size_lower_input == 0} {
          #echo "leaf_pin_lower_output"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_lower_output]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_lower_input]
        } elseif {$size_upper_output != 0 && $size_upper_input == 0} {
          #echo "leaf_pin_upper_output"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_upper_output]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_upper_input]
        } else {
          set flag_error 1
        }
      } elseif {$target_pin_string == "-receiver"} {
        if {$size_lower_input != 0 && $size_lower_output == 0} {
          #echo "leaf_pin_lower_input"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_lower_input]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_lower_output]
        } elseif {$size_upper_input != 0 && $size_upper_output == 0} {
          #echo "leaf_pin_upper_input"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_upper_input]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_upper_output]
        } else {
          set flag_error 1
        }
      } elseif {$target_pin_string == "-upper"} {
        if {$size_upper_output != 0 && $size_upper_input == 0} {
          #echo "leaf_pin_upper_output"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_upper_output]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_upper_input]
        } elseif {$size_upper_input != 0 && $size_upper_output == 0} {
          #echo "leaf_pin_upper_input"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_upper_input]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_upper_output]
        } else {
          set flag_error 1
        }
      } elseif {$target_pin_string == "-lower"} {
        if {$size_lower_output != 0 && $size_lower_input == 0} {
          #echo "leaf_pin_lower_output"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_lower_output]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_lower_input]
        } elseif {$size_lower_input != 0 && $size_lower_output == 0} {
          #echo "leaf_pin_lower_input"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_lower_input]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_lower_output]
        } else {
          set flag_error 1
        }
      } else {
        if {$size_lower_output != 0 && $size_lower_input == 0} {
          #echo "leaf_pin_lower_output"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_lower_output]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_lower_input]
        } elseif {$size_lower_input != 0 && $size_lower_output == 0} {
          #echo "leaf_pin_lower_input"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_lower_input]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_lower_output]
        } elseif {$size_upper_output != 0 && $size_upper_input == 0} {
          #echo "leaf_pin_upper_output"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_upper_output]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_upper_input]
        } elseif {$size_upper_input != 0 && $size_upper_output == 0} {
          #echo "leaf_pin_upper_input"
          set return_primitive_pin [add_to_collection $return_primitive_pin $leaf_pin_upper_input]
          set return_primitive_pin [add_to_collection $return_primitive_pin $port_upper_output]
        } else {
          set flag_error 1
        }
      }
      if {$flag_error == 1} {
        echo "Error (r_get_cellpin " $target_pin_string ") : The pin " [get_attribute $each_target_pin full_name] " can not be moved !!"
        if {$size_lower_output != 0} { echo "  Lower side output : Num = " $size_lower_output ": " [get_attribute $leaf_pin_lower_output full_name] }
        if {$size_lower_input  != 0} { echo "  Lower side input  : Num = " $size_lower_input  ": " [get_attribute $leaf_pin_lower_input  full_name] }
        if {$size_upper_output != 0} { echo "  Upper side output : Num = " $size_upper_output ": " [get_attribute $leaf_pin_upper_output full_name] }
        if {$size_upper_input  != 0} { echo "  Upper side input  : Num = " $size_upper_input  ": " [get_attribute $leaf_pin_upper_input  full_name] }
      }
    }
  }
  return $return_primitive_pin


}

