
foreach_in_collection pin_tmp [get_pins -hierarchical -filter "pin_direction!=in && is_hierarchical==false"] {

set v_max [get_attribute [get_pins $pin_tmp] power_rail_voltage_max]
set c_flag [get_attribute -quiet [get_pins $pin_tmp] clocks]

if { $v_max == 4.5 } {
  if { $c_flag == "" } {
    set_max_capacitance 0.7200 [get_pins $pin_tmp]
  } else {
    set_max_capacitance 0.3600 [get_pins $pin_tmp]
  }
} elseif { $v_max == 3.0 } {
  if { $c_flag == "" } {
    set_max_capacitance 1.0909 [get_pins $pin_tmp]
  } else {
    set_max_capacitance 0.5454 [get_pins $pin_tmp]
  }
}

}

