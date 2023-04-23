#############################################
# common_DFT_proc.tcl
# Version : v0r1 2010/07/01
# Modified by S.Abe@RenesasElectronics
# - note -
# (1) Add Proc : check_RebuildSE
#############################################

puts "# Define: SENG_SEARCH <seng-list-File>"
proc SENG_SEARCH  { {FILE_NAME} } {
        set fid [open $FILE_NAME]
        while {[gets $fid str]>=0} {
        if {[regexp {^#} $str]} {continue}
                if {[info exists CHECK_LIST]} {
                        set CHECK_LIST [concat $CHECK_LIST $str]
                } else {
                        set CHECK_LIST $str
                }
	}
        #echo $CHECK_LIST
	fconfigure stdout  -translation lf
	foreach tmp $CHECK_LIST {
#		puts -nonewline "$tmp " 
#		set PIN_LIST1 [ get_object_name [get_pins $tmp/Q ] ]
#		puts -nonewline "$PIN_LIST1"
		set PIN_LIST2_other [  get_object_name [get_pins -of [get_nets -of [get_pins $tmp ] -top -seg ]]]	
		set NET_LIST2 [  get_object_name [get_nets -of [get_pins $tmp ] -top -seg ]]
		set PIN_LIST2_other_size [ llength $PIN_LIST2_other ]
		if { $PIN_LIST2_other_size == 1 } {
			 puts "$tmp #### No Connect #####"
			continue
		}
		set PIN_LIST2 [  get_object_name [all_fanout -from  [ get_pins $tmp ]  -flat ]]
#		puts "$tmp $PIN_LIST2"
		set find_flg 0
		foreach tmp1 $PIN_LIST2 {
			set PIN_LIST3 [ get_object_name [ get_pins $tmp1 ] ]
			set CELL_LIST3 [ get_object_name [ get_cells -of [ get_pins $PIN_LIST3 ]]]
			set REF_NAME [  get_attribute [ get_cells  $CELL_LIST3 ] ref_name ]
			if { [ regexp "GTD" $REF_NAME ] && [ regexp "SMC" $PIN_LIST3 ] } {

				set PIN_LIST4 [ get_object_name [ get_pins $CELL_LIST3/CLK ] ]
				set PIN_LIST5 [  get_object_name [all_fanin -to  [ get_pins $PIN_LIST4 ] -flat ]]	
				set find_flg2 0
				foreach tmp2 $PIN_LIST5 {
					if { [ regexp "singcpg" $tmp2 ] && [ regexp "\/YB" $tmp2 ]  } {
						set find_flg2 1
						break
					}
				}
				if { $find_flg2 == 1 } {
					puts "$tmp $NET_LIST2 $CELL_LIST3 $REF_NAME $tmp2"
				} else {
					puts "$tmp $NET_LIST2 $CELL_LIST3 $REF_NAME ###CLK_NONE###"
				}
			}
		}
	}
}
puts "# Define: SKBR_SEARCH <skbr-list-File>"
proc SKBR_SEARCH  { {FILE_NAME} } {
        set fid [open $FILE_NAME]
        while {[gets $fid str]>=0} {
        if {[regexp {^#} $str]} {continue}
                if {[info exists CHECK_LIST]} {
                        set CHECK_LIST [concat $CHECK_LIST $str]
                } else {
                        set CHECK_LIST $str
                }
	}
        #echo $CHECK_LIST
	fconfigure stdout  -translation lf
	foreach tmp $CHECK_LIST {
#		puts -nonewline "$tmp " 
#		set PIN_LIST1 [ get_object_name [get_pins $tmp/Q ] ]
#		puts -nonewline "$PIN_LIST1"
		set PIN_LIST2_other [  get_object_name [get_pins -of [get_nets -of [get_pins $tmp ]]]]	
		set PIN_LIST2_other_size [ llength $PIN_LIST2_other ]
		if { $PIN_LIST2_other_size == 1 } {
			 puts "$tmp #### No Connect #####"
			continue
		}
		set PIN_LIST2 [  get_object_name [all_fanout -from  [ get_pins $tmp ]  -flat ]]	
#		puts "$tmp $PIN_LIST2"
		set find_flg 0
		foreach tmp1 $PIN_LIST2 {
			set PIN_LIST3 [ get_object_name [ get_pins $tmp1 ] ]
			set CELL_LIST3 [ get_object_name [ get_cells -of [ get_pins $PIN_LIST3 ]]]
			set REF_NAME [  get_attribute [ get_cells  $CELL_LIST3 ] ref_name ]
			if { [ regexp "DFFQEM" $REF_NAME ] && [ regexp "SEM" $PIN_LIST3 ] } {

				set PIN_LIST4 [ get_object_name [ get_pins $CELL_LIST3/CLK ] ]
				set PIN_LIST5 [  get_object_name [all_fanin -to  [ get_pins $PIN_LIST4 ] -flat ]]	
				set find_flg2 0
				foreach tmp2 $PIN_LIST5 {
					if { [ regexp "singcpg" $tmp2 ] && [ regexp "\/YB" $tmp2 ]  } {
						set find_flg2 1
						break
					}
				}
				if { $find_flg2 == 1 } {
					puts "$tmp $CELL_LIST3 $REF_NAME $tmp2"
				} else {
					puts "$tmp $CELL_LIST3 $REF_NAME ###CLK_NONE###"
				}
			}
		}
	}
}


proc check_RebuildSE { {SCAN_MODE "scan_mode"} } {
	set_case_analysis 1 [get_ports $SCAN_MODE]
	set GTD_ALL [get_cells -h * -filter ref_name=~"*GTD*"]
	set GTD_SMC [get_pins -of $GTD_ALL -filter lib_pin_name=="SMC"]
	set NUM_OK 0
	set NUM_NG 0
	set GTD_NG {}
	set NUM_ALL [sizeof_collection $GTD_SMC]
	foreach_in_collection pin $GTD_SMC {
		redirect /dev/null {set KEY [get_attribute $pin case_value]}
		if {$KEY == 1} {
			incr NUM_NG
			set GTD_NG [add_to_collection $GTD_NG $pin]
		} else {
			incr NUM_OK
		}
		
	}
	puts {}
	puts "-------------------------"
	puts [format "%4s %4s %4s" OK NG TOTAL]
	puts [format "%4d %4d %4d" $NUM_OK $NUM_NG $NUM_ALL]
	puts "-------------------------"
	set num 1
	foreach_in_collection pin $GTD_NG {
		set CHK_PIN [get_object_name $pin]
		regsub "/SMC" $CHK_PIN "/CEN" check_pin
		redirect /dev/null {set CHK_PORT [COL2LIST [get_ports [all_fanin -to $check_pin -flat -startpoints_only]]]}
		if {[llength $CHK_PORT] == 0} {
			redirect /dev/null {set TIED [get_attribute [get_pins $check_pin] case_value]}
			puts "#($num) Tied '$TIED' $check_pin"
		} else {
			puts "#($num) Drived by ports '$CHK_PORT' $check_pin"
		}
		incr num
		#if {[regexp "CGB/" $CHK_PIN]} {
		#	puts " OK $CHK_PIN"
		#} else {
		#	puts "#NG $CHK_PIN"
		#}
	}
}
proc CHECK_GTD_BUG {} {
	puts {}
	puts "* Information : Starting 'CHECK_GTD_BUG'. [date]"
	puts "* Information : Making collectioni..."
	set GTD_ALL        [get_cells * -h -filter ref_name=~"*GTD*"]
	set GTD_SMC        [get_pins -of $GTD_ALL -filter lib_pin_name=="SMC"]
	set GTD_SMC_TIED_H [filter_collection $GTD_SMC case_value=="1"]
	set GTD_SMC_TIED_L [filter_collection $GTD_SMC case_value=="0"]
	
	set GTD_CEN        [get_pins -of $GTD_ALL -filter lib_pin_name=="CEN"]
	set GTD_CEN_TIED_H [filter_collection $GTD_CEN case_value=="1"]
	set GTD_CEN_TIED_L [filter_collection $GTD_CEN case_value=="0"]

	
	# SENGEN
	puts "* Information : Tracing scan_enable cone from SENGEN cell '*DFFQEMX*/Q' out pins..."
	set SENG_ALL       [get_cells -filter ref_name=~"T*5DFFQEMX*"] ;# "Drive net "Z997SEN_*tgn*_T*_*G*"
	set SENG_OUT_ALL   [get_pins -of $SENG_ALL -filter pin_direction=="out"]
	set SENG_LEAF      [filter_collection [all_fanout -from $SENG_OUT_ALL -flat -endpoints_only] lib_pin_name=="SMC"]

	# SCAN_MODE
	#set SCAN_MODE_LEAF [filter_collection [all_fanout -from [get_pins -of [get_nets "scan_mode"] -filter pin_direction=="out"] -flat -endpoints_only] lib_pin_name=="SMC"]

	# Add user attribute
	puts "* Information : Set User attributes..."
	define_user_attribute -type boolean -class pin SENG
	#define_user_attribute -type boolean -class pin MODE
	set_user_attribute -class pin -quiet $SENG_LEAF      SENG true
	#set_user_attribute -class pin -quiet $SCAN_MODE_LEAF MODE true

	# Controled by SENG && CEN TIED 0
	puts "* Information : Check error structure which is SENGEN controled GTD and its CEN pin tied zero."
	set NG_PINS_L [filter_collection [get_pins -of [get_cells -of $GTD_CEN_TIED_L] -filter lib_pin_name=="SMC"] "SENG==true"]
	#set NG_PINS_H [filter_collection [get_pins -of [get_cells -of $GTD_CEN_TIED_H] -filter lib_pin_name=="SMC"] "SENG==true"]

	#set OK_PINS_L [filter_collection [get_pins -of [get_cells -of $GTD_CEN_TIED_L] -filter lib_pin_name=="SMC"] "MODE==true"]
	#set OK_PINS_H [filter_collection [get_pins -of [get_cells -of $GTD_CEN_TIED_H] -filter lib_pin_name=="SMC"] "MODE==true"]

	set NUM_ERROR [sizeof_collection $NG_PINS_L]
	puts {}
	if {$NUM_ERROR == 0} {
		puts " ** PASS **"
	} else {
		puts " ** FAILED **"
		puts "    There are '$NUM_ERROR' Error in your design. Following 'CEN' pin is tied to 'Logic0'"
		puts "    They should be controled by not 'scan_enable' attribute but 'scan_mode' attribute." 
		set num 1
		foreach_in_collection pin $NG_PINS_L {
			puts {}
			set pin_name     [get_object_name $pin]
			set pin_ref      [get_attribute [get_cells -of $pin] ref_name]
			set drv_net      [get_nets -of $pin]
			set drv_net_name [get_object_name $drv_net]
			set drv_pin_name [get_object_name [get_pins -of $drv_net -filter pin_direction=="out"]]
			set drv_pin_ref  [get_attribute [get_cells -of $drv_pin_name] ref_name]
			puts " # Error($num) : $pin_name ($pin_ref)"
			puts "                 Driven by $drv_pin_name"
			puts "                                ->(net) $drv_net_name"
			incr num
		}
		puts {}
	}
	puts "* Information : Finished 'CHECK_GTD_BUG'. [date]"
	puts "Thank you."
	puts {}
}

proc getFaultPins {{FAULT_FILE}} {
	set return_value ""
	set nu 0
        set FILE_EXT [file extension $FAULT_FILE]
        if       {$FILE_EXT == ".gz"} {
                set fid [open "|gzip  -dc $FAULT_FILE" r]
        } elseif {$FILE_EXT == ".bz2"} {
                set fid [open "|bzip2 -dc $FAULT_FILE" r]
        } else {
                set fid [open $FAULT_FILE r]
                set FILE_EXT "NORMAL"
        }
        puts "* Information : Open file '${FAULT_FILE}' as format '${FILE_EXT}'"
        while {[gets $fid str]>=0} {
		regsub "\{" $str "" str
		regsub "\}" $str "" str
		regsub -all "\"" $str "" str
		regsub -all "\;" $str "" str
		regsub -all "\," $str "" str
		set tmp [lindex $str 0]
		if {$tmp=="0"||$tmp=="1"} {
			set chk [lindex $str 1]
                	if {$chk == "UO.AAB"} {
				incr nu
				regsub "/" [lindex $str 2] "" pin
				lappend return_value $pin
			}
		} else {
			continue
		}
        }
        close $fid
	puts "* Total $nu number of undetected fault points are catched."
	return $return_value
}
proc sum {{list_int}} {
	set return_value 1
	foreach tmp $list_int {
		set return_value [expr $return_value + $tmp]
	}
	return $return_value
}

proc removeUndetectNumber {} {
	define_user_attribute -type int -class pin undetect
	remove_user_attribute [get_pins -h *] undetect -q
}
proc setUndetectNumber {{list_undetect}} {
	define_user_attribute -type int -class pin undetect
	set nu 0
	set nu_exist 0
	set return_value ""
	foreach tmp $list_undetect {
		incr nu
		set col_pin [get_pins $tmp -q]
		if {[sizeof_collection $col_pin] == 0} {continue}
		lappend return_value $tmp
		incr nu_exist
		set flg [get_attribute $col_pin undetect -quiet]
		if {$flg > 0} {
			set_user_attribute $col_pin undetect [expr $flg + 1] -quiet
		} else {
			set_user_attribute $col_pin undetect 1 -quiet
		}
	}
	puts "* $nu_exist / $nu are catched."
	return $return_value
}

proc minimizeUndetectTarget {{list_undetect}} {
	set return_value ""
	set col_undetect     [get_pins $list_undetect -q]
	set col_undetect_out [filter_collection $col_undetect pin_direction=="out"]
	set col_redun_in     [get_pins -of [get_nets -of $col_undetect_out] -leaf -filter pin_direction=="in" -q]
	set col_undetect     [remove_from_collection $col_undetect $col_redun_in]
	set list_undetect    [COL2LIST $col_undetect]
	foreach pin $list_undetect {
		set redundant_target [remove_from_collection [all_fanin -to $pin] [get_pins $pin]]
		set col_undetect [remove_from_collection $col_undetect $redundant_target]
	}
	set return_value [COL2LIST $col_undetect]
	return $return_value
}

proc chkUndetectNumber {{list_undetect}} {
	foreach pin $list_undetect {
		set num [sum [get_attribute  [all_fanin -to $pin] undetect]]
		puts "$num $pin"
	}
}


proc chkUndetectNumber_auto {{FAULT_FILE}} {
	suppress_message {UIAT-4 ATTR-3}
	removeUndetectNumber
	set list_undetect [getFaultPins $FAULT_FILE]
	set list_undetect [setUndetectNumber $list_undetect]
	set list_undetect [minimizeUndetectTarget $list_undetect]
	chkUndetectNumber $list_undetect
	unsuppress_message {UIAT-4 ATTR-3}
}

