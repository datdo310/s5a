##########################################################
# add_maxcap_of_hv.tcl
# v0r0:	From E1M-S orignal
# v0r1: 2017/10/05 Y.Oda Support for RV28F
##########################################################
if {![info exists PROCESS]} {
	puts "Error: add_maxcap_of_hv.tcl cannot read \$PROCESS, so that cannot add MaxCap constraint for VCC area"
} elseif {[string match "RV40F" $PROCESS] } {
	puts "*Information: add_maxcap_of_hv.tcl select RV40F MaxCap for HV@80MHz"
} elseif {[string match "RV28F" $PROCESS] } {
	puts "*Information: add_maxcap_of_hv.tcl select RV28F MaxCap for HV@80MHz"
} else {
	puts "Error: add_maxcap_of_hv.tcl cannot Use \$PROCESS: $PROCESS, so that cannot add MaxCap constraint for VCC area"
}

foreach_in_collection pin_tmp [get_pins -hierarchical -filter "pin_direction!=in && is_hierarchical==false"] {

set v_max [get_attribute [get_pins $pin_tmp] power_rail_voltage_max]
set c_flag [get_attribute -quiet [get_pins $pin_tmp] clocks]

if {[string match "RV40F" $PROCESS] } {
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
} elseif {[string match "RV28F" $PROCESS] } {
	if { $v_max == 4.5 } {
		if { $c_flag == "" } {
			set_max_capacitance 0.3943 [get_pins $pin_tmp]
		} else {
			set_max_capacitance 0.1971 [get_pins $pin_tmp]
		}
	} elseif { $v_max == 3.0 } {
		if { $c_flag == "" } {
			set_max_capacitance 0.5974 [get_pins $pin_tmp]
		} else {
			set_max_capacitance 0.2987 [get_pins $pin_tmp]
		}
	}
}

}
