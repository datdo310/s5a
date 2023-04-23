proc CHECK_HIER { {LEVEL " "} {FLAG 1} } {
    if {$FLAG=="1"} {
        echo "# The hierarchy report of design name \"[get_object_name [current_design]]\" [get_attri [get_design *] area]."
    }
    redirect /dev/null {set CELLS [sort_collection [get_cells * -filter "@is_hierarchical==true"] full_name]}

    foreach_in_collection tmp $CELLS {
        set REF_NAME [get_attribute $tmp ref_name]
        set CEL_NAME [get_attribute $tmp base_name]
        set AREA [get_attribute $tmp area]
        echo "${LEVEL}+ $CEL_NAME ( $REF_NAME )	$AREA"
        #echo "${LEVEL}+ $CEL_NAME ( $REF_NAME )"
        current_instance $CEL_NAME
        set LEVEL "${LEVEL}	"
        CHECK_HIER $LEVEL 0
        redirect /dev/null {current_instance ..}
        regsub {	} $LEVEL {} LEVEL
    }
}

proc REPORT_DIRECT_CONNECTED_FF { {CHECK_PIN {*/DATA */SIN} } } {
    echo "#\n# CheckStart: DirectConnection FF output -> FF $CHECK_PIN\n#"
    set tmp_DATA_PINS          [get_pins $CHECK_PIN -h]
    #set tmp_DATA_PINS          [get_pins {*/DATA */SIN} -h]
    set ALL_REGISTERS_DATA     [all_registers -data_pins]
    set tmp_DFF_without_DATA   [remove_from_collection $ALL_REGISTERS_DATA $tmp_DATA_PINS]
    set ALL_REGISTER_DATA_PINS [remove_from_collection $ALL_REGISTERS_DATA $tmp_DFF_without_DATA]
    redirect /dev/null {set POWER_NETS             [get_nets [list *VDD* *VSS* *Logic0* *Logic1*]]}
	
    set num 0
    echo "#number DriveFF pin (ref) -> Net -> SinkFF pin (ref)"
    foreach_in_collection FF_DATA_PIN $ALL_REGISTER_DATA_PINS {
        #puts "# [get_object_name $FF_DATA_PIN]"
        set DATA_NET       [remove_from_collection [get_nets -quiet -of $FF_DATA_PIN] $POWER_NETS]
        if {[sizeof_collection $DATA_NET]==0} {continue}
        redirect /dev/null {set DRIVE_PIN_NAME [get_object_name [get_pins -leaf -of $DATA_NET -filter "@pin_direction==out"]]}
        if {$DRIVE_PIN_NAME == ""} {
            echo "* Error: DrivePin does not exist. ? -> [get_object_name $DATA_NET] -> [get_object_name $FF_DATA_PIN]"
            continue
        }

        regsub {.*/} $DRIVE_PIN_NAME {} LIB_PIN_NAME
        regsub {\[} $LIB_PIN_NAME {\\[} tmp_LIB_PIN_NAME
        regsub {\]} $tmp_LIB_PIN_NAME {\\]} tmp_LIB_PIN_NAME
        regsub "/$tmp_LIB_PIN_NAME$" $DRIVE_PIN_NAME {} DRIVE_CELL_NAME

        set DRIVE_CELL_REF [get_attribute [get_cells $DRIVE_CELL_NAME] ref_name]

        if {[regexp "ADDF" $DRIVE_CELL_REF]} {continue}

        if {[regexp DFF $DRIVE_CELL_REF] || [regexp DLAT $DRIVE_CELL_REF] || [regexp {\w+DF\w+D\d+BWP\w+} $DRIVE_CELL_REF] || [regexp {L[NH]\w+D\d+BWP\w+} $DRIVE_CELL_REF] } {
            set num [expr $num + 1]
            set Net_NAME [get_object_name $DATA_NET]

            set DriveFF_NAME [get_object_name $FF_DATA_PIN]
            regsub {.*/} $DriveFF_NAME {} SINK_LIB_PIN_NAME
            regsub "/$SINK_LIB_PIN_NAME$" $DriveFF_NAME {} SINK_CELL_NAME
            set SINK_CELL_REF [get_attribute [get_cells $SINK_CELL_NAME] ref_name]

            if {[regexp "SO" $LIB_PIN_NAME]} {continue}
            if {[regexp "DFF" $DRIVE_CELL_REF] && [regexp "HOLD" $DRIVE_CELL_REF]} {continue}
            if {[regexp "DFF" $DRIVE_CELL_REF] && [regexp "ZGX" $DRIVE_CELL_REF]} {continue}
            if {[regexp "DFF" $DRIVE_CELL_REF] && [regexp "ZFX" $DRIVE_CELL_REF]} {continue}
            echo "$num $DRIVE_CELL_NAME $LIB_PIN_NAME ($DRIVE_CELL_REF) -> $Net_NAME -> $SINK_CELL_NAME $SINK_LIB_PIN_NAME ($SINK_CELL_REF)"
        }
    }
}

proc REPORT_DIRECT_CONNECTED_FF_SOSI { {CHECK_PIN {*/SIN */SI} } } {
    echo "#\n# CheckStart: DirectConnection FF/Q -> FF/DATA\n#"
    set tmp_DATA_PINS          [get_pins $CHECK_PIN -h]
    #set tmp_DATA_PINS          [get_pins {*/DATA */SIN} -h]
    set ALL_REGISTERS_DATA     [all_registers -data_pins]
    set tmp_DFF_without_DATA   [remove_from_collection $ALL_REGISTERS_DATA $tmp_DATA_PINS]
    set ALL_REGISTER_DATA_PINS [remove_from_collection $ALL_REGISTERS_DATA $tmp_DFF_without_DATA]
    redirect /dev/null {set POWER_NETS             [get_nets [list VDD* VSS* *Logic0* *Logic1*]]}

    set num 0
    echo "#number DriveFF pin (ref) -> Net -> SinkFF pin (ref)"
    foreach_in_collection FF_DATA_PIN $ALL_REGISTER_DATA_PINS {
        #puts "# [get_object_name $FF_DATA_PIN]"
        set DATA_NET       [remove_from_collection [get_nets -of $FF_DATA_PIN] $POWER_NETS]
        if {[sizeof_collection $DATA_NET]==0} {continue}
        redirect /dev/null {set DRIVE_PIN_NAME [get_object_name [get_pins -leaf -of $DATA_NET -filter "@pin_direction==out"]]}
        if {$DRIVE_PIN_NAME == ""} {
            echo "# Error: DrivePin does not exist. ? -> [get_object_name $DATA_NET] -> [get_object_name $FF_DATA_PIN]"
            continue
        }

        regsub {.*/} $DRIVE_PIN_NAME {} LIB_PIN_NAME
        regsub {\[} $LIB_PIN_NAME {\\[} tmp_LIB_PIN_NAME
        regsub {\]} $tmp_LIB_PIN_NAME {\\]} tmp_LIB_PIN_NAME
        regsub "/$tmp_LIB_PIN_NAME$" $DRIVE_PIN_NAME {} DRIVE_CELL_NAME

        set DRIVE_CELL_REF [get_attribute [get_cells $DRIVE_CELL_NAME] ref_name]
        if {[regexp "ADDF" $DRIVE_CELL_REF]} {continue}
 
        if {[regexp "SO" $LIB_PIN_NAME] || [regexp "SOB" $LIB_PIN_NAME]} {
            set num [expr $num + 1]
            set Net_NAME [get_object_name $DATA_NET]
 
            set DriveFF_NAME [get_object_name $FF_DATA_PIN]
            regsub {.*/} $DriveFF_NAME {} SINK_LIB_PIN_NAME
            regsub "/$SINK_LIB_PIN_NAME$" $DriveFF_NAME {} SINK_CELL_NAME
            set SINK_CELL_REF [get_attribute [get_cells $SINK_CELL_NAME] ref_name]
   
            if {[regexp "DFFB" $DRIVE_CELL_REF]} {continue}
            echo "$num $DRIVE_CELL_NAME $LIB_PIN_NAME ($DRIVE_CELL_REF) -> $Net_NAME -> $SINK_CELL_NAME $SINK_LIB_PIN_NAME ($SINK_CELL_REF)"
        }
    }
}

#puts "# Define: CHECK_CLOCK_PIN2 <List or Collection Variable of pin-name>"
proc CHECK_CLOCK_PIN2 { {PIN_COLL} } {
    set CHECK_PINS [get_pins $PIN_COLL]
    foreach_in_collection tmp_PIN $CHECK_PINS {
        set tmp_PIN_NAME [get_object_name $tmp_PIN]
        echo "# $tmp_PIN_NAME"
        set TIMING_PATH [get_timing_path -from [get_pins $tmp_PIN]]

        foreach_in_collection tmp $TIMING_PATH {
            #START-POINST
            set START_CLOCK [get_object_name [get_attribute $tmp startpoint_clock]]
            set START_POINT  [get_attribute [get_attribute $tmp startpoint] lib_pin_name]

            #END-POINST
            set END_CLOCK [get_object_name [get_attribute $tmp endpoint_clock]]
            set END_POINT  [get_attribute [get_attribute $tmp endpoint] lib_pin_name]

            echo "+ $START_CLOCK : $tmp_PIN_NAME $START_POINT -> $END_CLOCK $END_POINT"
        }
    }
}


#puts "# Define: CHECK_CLOCK_PIN <instance-list-File>"
proc CHECK_CLOCK_PIN { {FILE_NAME} } {
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

    foreach tmp $CHECK_LIST {
        set CLOCK_PINS [get_pins $tmp/* -filter "@is_clock_pin==true"]
        foreach_in_collection tmp_pin $CLOCK_PINS {
            #echo "[get_object_name $tmp_pin]"
            CHECK_CLOCK_PIN2 $tmp_pin
        }
    }
}

#puts "# Define: GET_INST_ALL_PIN <instance-list>"
proc GET_INST_ALL_PIN { {INST_LIST} } {
    foreach INST $INST_LIST {
        set tmp_INST [get_pins $INST/*]
        foreach_in_collection tmpPIN $tmp_INST {
            set DIRECTION [get_attribute $tmpPIN pin_direction]
            set tmp_INST_NAME [get_object_name $tmpPIN]
            echo [format "%5s %s" $DIRECTION $tmp_INST_NAME]
        }
    }
}

#puts "# Define: GET_INST_ADD_PWR_AREA <instance-list>"
proc GET_INST_ADD_PWR_AREA { {INST_LIST} } {
    set TGT_INST {}
    foreach INST $INST_LIST {
        lappend TGT_INST "*/$INST"
    }
    set tmp_INSTS [get_cells $TGT_INST]

    foreach_in_collection tmp_INST $tmp_INSTS {
        set REF_NAME  [get_attribute $tmp_INST ref_name]
        set INST_NAME [get_object_name $tmp_INST]
        set tmp_PINS  [get_pins $INST_NAME/*]

        foreach_in_collection tmpPIN $tmp_PINS {
            set DIRECTION [get_attribute $tmpPIN pin_direction]
            set tmp_NAME  [get_object_name $tmpPIN]
            regsub {.*/} $tmp_NAME {} LIB_PIN

            echo [format "%-15s %-10s %-5s %s" $REF_NAME $LIB_PIN $DIRECTION $INST_NAME]
        }
    }
}

#puts "# Define: SET_POWER_COND"
#puts "# --> DesignCompiler"
## set VDD & VSS value
proc SET_POWER_COND {} {
    set VDD_LIST [get_nets VDD*]
    foreach_in_collection tmp $VDD_LIST {
        set NAME_ [get_object_name $tmp]
        set NAME ${NAME_}_LOGIC_ONE
        create_cell $NAME -logic 1
        connect_net $tmp [get_pin $NAME/*]
    }
	
    set VSS_LIST [get_nets VSS*]
    foreach_in_collection tmp $VSS_LIST {
        set NAME_ [get_object_name $tmp]
        set NAME ${NAME_}_LOGIC_ZERO
        create_cell $NAME -logic 0
        connect_net $tmp [get_pin $NAME/*]
    }
}

#puts "# Define: CHECK_W_PTE060 <collection>"
# Filter the warning PTE-060 by pin/port endpoint.
proc CHECK_W_PTE060 { {LIST_WPTE060} } {
    set COL_PTE060 [get_pins $LIST_WPTE060]

    echo "## Attention! If you face no-matched pin name error, you must check above them!"

    set LIST_CLK {}
    set LIST_MIX {}
    set LIST_PORT {}
    set LIST_DATA {}

    foreach_in_collection tmp $COL_PTE060 {
        redirect /dev/null {
            set PINNAME [get_object_name $tmp]
            set PORT    [get_port [all_fanout -from $tmp -end -flat]]
            set CLKDATA [get_pin  [all_fanout -from $tmp -end -flat] \
                -filter "@lib_pin_name=~*CLK* || @lib_pin_name=~*CK* || @lib_pin_name=~*GT*"]
        }

        if { [sizeof_collection $PORT] > 0 && [sizeof_collection $CLKDATA] > 0} {
            #echo "# Endpoints are CLOCK & PORT."
            lappend LIST_MIX $PINNAME
        } elseif { [sizeof_collection $PORT] > 0 } {
            #echo "# Endpoints are PORT."
            lappend LIST_PORT $PINNAME
        } elseif { [sizeof_collection $CLKDATA] > 0 } {
            #echo "# Endpoints are CLOCK."
            lappend LIST_CLK $PINNAME
        } else {
            #echo "# Endpoints are not Clock."
            lappend LIST_DATA $PINNAME
        }
    } 
    ###########
    # Display #
    ###########

    # Case CLK Only: Must be checked by designner.
    for {set i 0} {$i < [llength $LIST_CLK]} {incr i} {
        echo "CLK: [lindex $LIST_CLK $i]"
    }

    # Case Mixed : Must be checked by designner.
    for {set i 0} {$i < [llength $LIST_MIX]} {incr i} {
        echo "MIX: [lindex $LIST_MIX $i]"
    }

    # Case PORT only : Check port attribute is Clock or not first
    for {set i 0} {$i < [llength $LIST_PORT]} {incr i} {
        echo "PRT: [lindex $LIST_PORT $i]"
    }

    # Case Other : No need to check them.
    for {set i 0} {$i < [llength $LIST_DATA]} {incr i} {
        echo "DAT: [lindex $LIST_DATA $i]"
    }
} 

#puts "# Define: SET_CASE_ANALYSIS_FOR_UIODLATCH"
# Create the command of set_case_analysis which stopped on the DATA-Pin of UIO-Latch.
# Besides, inform error on following case:
#   1.case-value is not propageted to power-cut signal
#   2.case-value is wrong
proc SET_CASE_ANALYSIS_FOR_UIODLATCH {} {
    set UIO [get_cells -h * -filter "@ref_name=~*UIODLAT*"]
    if {[sizeof_collection $UIO]==0} {
        echo "# There isn't any UIOLATCH in your design."
        return -1
    }
    set GTB1 {}
    set GTBX {}
    set GTB0_DAT {}
    global MODE

    if {[info exists MODE]} {
        echo "# This constraints created on $MODE"
    }
    echo "#-------------------------------------------------------------------------"
    echo "# Add constraints : GTB is tied 0 and DATA has fixed value."
    echo "#-------------------------------------------------------------------------"

    set num 0
    foreach_in_collection uio $UIO {
        set DAT [get_pins -of $uio -filter "@lib_pin_name==DATA"]
        set GTB [get_pins -of $uio -filter "@lib_pin_name==GTB"]
        set OUT [get_object_name [get_pins -of $uio -filter "@lib_pin_name==Q"]]
        set GTB_name [get_object_name $GTB]
        redirect /dev/null {
            set CASE_DAT [get_attribute $DAT case_value]
            set CASE_GTB [get_attribute $GTB case_value]
        }
        if {$CASE_GTB == 1} {
            lappend GTB1 $GTB_name
        } elseif { $CASE_GTB == 0 } {
            if { $CASE_DAT != ""} {
                echo "set_case_analysis $CASE_DAT $OUT"
                incr num
            } else {
                lappend GTB0_DAT $OUT
            }
        } else {
            lappend GTBX $GTB_name
        }
    }
    echo "# Total $num constraint can be added"

    ###########
    # Display #
    ###########
    # Error (GTB=X) --------------------------
    echo ""
    echo "#-------------------------------------------------------------------------"
    echo "# Error: GTB must be 0, but X found.: Total [llength $GTBX]"
    echo "#-------------------------------------------------------------------------"
    foreach tmp [lsort -ascii $GTBX] {
        echo "# Error-GTB-X: $tmp"
    }

    # Error (GTB=1) --------------------------
    echo ""
    echo "#-------------------------------------------------------------------------"
    echo "# Error: GTB must be 0, but 1 found.: Total [llength $GTB1]"
    echo "#-------------------------------------------------------------------------"
    foreach tmp [lsort -ascii $GTB1] {
        echo "# Error-GTB-1: $tmp"
    }

    # GTB=0 ----------------------------------
    echo ""
    echo "#-------------------------------------------------------------------------"
    echo "# Information:"
    echo "# The followings can through inout DATA to Q.(GTB=0) Total [llength $GTB0_DAT]"
    echo "#-------------------------------------------------------------------------"
    foreach tmp [lsort -ascii $GTB0_DAT] {
        echo "# $tmp"
    }
}

#puts "# Define: SET_DELAY_ZERO <collection>"
# Set 0 to the input -> output delay for the cells in given collection.
proc SET_DELAY_ZERO { {COL_CELL} } {
    foreach_in_collection tmp [get_cells $COL_CELL] {
        set_annotated_delay -cell -load_delay cell 0 \
            -from [get_pins -of $tmp -filter "@pin_direction==in"] \
            -to   [get_pins -of $tmp -filter "@pin_direction==out"] \
    }
}

#puts "# Define: REMOVE_DELAY_ZERO <collection>"
# Remove 0 delay by "SET_DELAY_ZERO".
proc REMOVE_DELAY_ZERO { {COL_CELL} } {
    foreach_in_collection tmp [get_cells $COL_CELL] {
        remove_annotated_delay \
            -from [get_pins -of $tmp -filter "@pin_direction==in"] \
            -to   [get_pins -of $tmp -filter "@pin_direction==out"] \
    }
}

#puts "# Define: GET_MEMCELL_COLLECTION"
proc GET_MEMCELL_COLLECTION { {LIBRARY_NAME "dk*"} } {
	global REF_MEM
	global NUMBER_REFS
	set LIB_NAMES [get_object_name [get_libs $LIBRARY_NAME]]
	foreach LIB_NAME $LIB_NAMES {
		set REF_MEM  [add_to_collection $REF_MEM [get_lib_cells ${LIB_NAME}/*] -unique]
		echo "* Info: There are $NUMBER_REFS cells in $LIB_NAME library."
	}
	set NUMBER_REFS [sizeof_collection $REF_MEM]
	echo "* Info: There are $NUMBER_REFS cells in library '$LIB_NAMES'."
}
#puts "# Define: GET_CHIP_COLLECTION"
proc GET_CHIP_COLLECTION {} {
	global ALL_INST
	global REF_MEM
	global NUMBER_REFS
	redirect /dev/null {set REMOVE_INST [get_cells -h * -filter {is_combinational==TRUE || ref_name=~*DFF*}] }
	redirect /dev/null {set ALL_INST [remove_from_collection [get_cells -h *] $REMOVE_INST]}
	set num 1
	set COL_INST {}
	foreach_in_collection A_MEM_REF $REF_MEM {
		set A_MEM_REF    [get_attribute $A_MEM_REF base_name]
		redirect /dev/null {set INST [filter_collection $ALL_INST ref_name=="$A_MEM_REF"]}
		if {[sizeof_collection $INST] == 0} {
			echo "* info: $A_MEM_REF is not used in this design."
			continue
		}
		set COL_INST [add_to_collection $COL_INST $INST -unique]
		set NUMBER_CELLS [sizeof_collection $INST]
		echo [format "#(%3d/%3d) %s : total %3d in this design." $num $NUMBER_REFS $A_MEM_REF $NUMBER_CELLS]
		set num [expr $num + 1]
	}
	return $COL_INST
}
#puts "# Define: GET_MEMPIN_COLLECTION"
# Get the collection by pin-name
proc GET_MEMPIN_COLLECTION { {PINNAME} {MEM_INST_COL} } { 
	set TARGET_PINS [eval "get_pins -of \$MEM_INST_COL -filter {lib_pin_name =~\"${PINNAME}\"}"]
	return $TARGET_PINS
}
#Example
# pt_shell> set REF_MEM     {}
# pt_shell> set ALL_INST    {}
# pt_shell> set NUMBER_REFS {}
# pt_shell> GET_MEMCELL_COLLECTION "dk*"
# pt_shell> set MEM_INST_COL [GET_CHIP_COLLECTION]
# pt_shell> set MEM_SI_PINS  [GET_MEMPIN_COLLECTION "SI" $MEM_INST_COL]
# pt_shell> set MEM_RS_PINS  [GET_MEMPIN_COLLECTION "RS" $MEM_INST_COL]

proc TIE_PSWCDN { {TARGET_NET} } {
	#redirect /dev/null { set TGT_LATTHR [get_nets {sy_pswcdn* cl_vs_ab_p}] }
	redirect /dev/null { set TGT_LATTHR [get_nets $TARGET_NET] }

	if {[sizeof_collection $TGT_LATTHR] > 0} {
		set TGT_LATTHR_PINS [get_pins -l -of $TGT_LATTHR -filter "direction == out"]
		puts "* Information : The followings are targets of Latch-Through."
		puts "* << Net name >> -------------------------------------------"
		COL2DISP $TGT_LATTHR
		puts "* << Pin name >> -------------------------------------------"
		COL2DISP $TGT_LATTHR_PINS
		puts "* ----------------------------------------------------------"
		set_case_analysis 0 $TGT_LATTHR_PINS
	} else {
		puts "* Warning     : No Latch-Through target is in your design."
	}
}

proc DELETE_DELAY_FOR_DETOUR { {DETOUR_LIST} } {
	set TARGET_NETS  [get_nets         $DETOUR_LIST]
	set TARGET_CELL  [get_cells -of [get_pins  -l -of $TARGET_NETS -filter "@pin_direction==out"]]

	# << Set cell_delay to defined value >>
	remove_annotated_delay $TARGET_CELL
}

proc SET_LOAD0_FOR_DETOUR { {DETOUR_LIST} } {
	set TARGET_NETS     [get_nets         $DETOUR_LIST]

	# << Set net load zero >>
	set_load -subtract_pin_load 0 $TARGET_NETS
}
proc SET_DELAY_FOR_DETOUR { {DETOUR_LIST} {VALUE 0.4} } {
	set TARGET_NETS     [get_nets         $DETOUR_LIST]
	set DRIVE_OUT_PINS  [get_pins  -l -of $TARGET_NETS  -filter "@pin_direction==out"]

	# << Set cell_delay to defined value >>
	set_annotated_delay -cell -increment -load_delay cell $VALUE -to $DRIVE_OUT_PINS
}

proc SET_DELAY_WITH_ZERO_LOAD { {DETOUR_LIST} {VALUE 0.4} } {
	# << Setting LOAD zero to target nets >>
	SET_LOAD0_FOR_DETOUR $DETOUR_LIST

	# << Auto incremental update_timing and to know changing >>
	report_timing -tran -in -nets -nosplit -sig 3

	# << Seting 0 load delay + additional fixed delay value to driving cell >>
	SET_DELAY_FOR_DETOUR $DETOUR_LIST $VALUE
}

proc GET_NETS_FROM_LIST_FILE { {DETOUR_NETS} } {
	set fid [open $DETOUR_NETS]
	set string "set DETOUR {"
	set num 0
	while {[gets $fid str]>=0} {
		if {[regexp "^#" $str]} {continue}
		regsub {^\\} $str {} tmp
		redirect /dev/null {set tmp [get_object_name [get_nets $tmp]]}
		if {$tmp != ""} {set str $tmp}
		if {$num == 0} {
			set string "set DETOUR \[GET_NETS \{$str";incr num
		} else {
			set string "$string $str"
		}
	}
	close $fid
	eval "$string}]"
	return $DETOUR
}

proc GET_CHANGE_LIST { {INSTANCES} {REPLACE_FROM} {REPLACE_TO} } {
	set CHANGE_LIST ""
	foreach_in_collection INST ${INSTANCES} {
		set INST_NAME [ get_object_name ${INST} ]
		set LIB_CELL  [ get_object_name [ get_lib_cells -of_objects ${INST} ]  ]
		set LIB_NAME  [ lindex [ split ${LIB_CELL} "/"] 0 ]
		set REF_NAME  [ lindex [ split ${LIB_CELL} "/"] 1 ]
		regsub ${REPLACE_FROM} ${LIB_NAME} ${REPLACE_TO} LIB_TMP
		regsub {VIRTUAL_} ${LIB_TMP} {} LIB_CHANGED
		regsub ${REPLACE_FROM} ${REF_NAME} ${REPLACE_TO} REF_CHANGED
		lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  $${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
		#lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  ${LIB_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
	}
	return ${CHANGE_LIST}
}

proc CHNGE_VTH_TO_ML {} {
	global STBY_AREA

	puts "* Information : Changing CellVth : WaitArea=Mvth, Others=Lvth."
	puts "*               Making Collections...\n"
	set CELL_ALL [get_cells * -h]
	puts "*               ...Hvth"
	set HVTH_INST [filter_collection $CELL_ALL "ref_name=~TH*"]
	puts "*               ...Mvth"
	set MVTH_INST [filter_collection $CELL_ALL "ref_name=~TM*"]

	# << Making collection of WaitArea >>
	set ALL_WAIT {}
	foreach STBY ${STBY_AREA} {
		puts "*               ...all of '${STBY}'"
		redirect /dev/null {
			set WAIT [filter_collection $CELL_ALL -regexp "full_name =~ \[_/\]?${STBY}\[_/\].*"]
			set WAIT [add_to_collection $WAIT [filter_collection $CELL_ALL -regexp "full_name =~ .*\[_/\]?${STBY}\[_/\].*"]]
			set NUM_CELLS [sizeof_collection $WAIT]
		}
		if {$NUM_CELLS == 0} {
			puts "* Error : Naming Unmatched. Please check name '${STBY}'."
			continue
		} else {
			puts "*                      ...'${NUM_CELLS}' cells are detected."
			set ALL_WAIT [add_to_collection $ALL_WAIT $WAIT]
		}
		
	}

	puts "*               ...without WaitArea.."
	set HVTH_OTHER [remove_from_collection $HVTH_INST $ALL_WAIT]
	set MVTH_OTHER [remove_from_collection $MVTH_INST $ALL_WAIT]
	set TO_LVTH_TARGET [add_to_collection $HVTH_OTHER $MVTH_OTHER]

	puts "*               ...WaitArea.."
	set HVTH_WAIT  [remove_from_collection $HVTH_INST $HVTH_OTHER]

	# << Hvth => Mvth >> for WaitArea
	puts "*               Making ChangeList for WaitArea...\n"
	set CHANGE_LIST ""
	foreach_in_collection INST $HVTH_WAIT {
		set INST_NAME [get_object_name $INST]
		set REF_NAME  [get_attribute $INST ref_name]
		regsub "TH(\[567CDME\])" $REF_NAME {TM\1}  REF_CHANGED
		lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
	}
	puts "*               Writing './LOAD/TO_MVTH.tcl'...\n"
	WRITE_FILE ./LOAD/TO_MVTH.tcl $CHANGE_LIST


	# << *vth => Lvth >> for Others
	set NUM_TO_LVTH [sizeof_collection $TO_LVTH_TARGET]
	puts "*               Making ChangeList for Others(${NUM_TO_LVTH})... \n"
	set CHANGE_LIST ""
	foreach_in_collection INST $TO_LVTH_TARGET {
		set INST_NAME [get_object_name $INST]
		set REF_NAME  [get_attribute $INST ref_name]
		regsub "TH(\[567CDME\])" $REF_NAME    {TL\1}  REF_CHANGED
		regsub "TM(\[567CDME\])" $REF_CHANGED {TL\1}  REF_CHANGED
		if {[regexp "^TL5B" $REF_CHANGED] && ![regexp "^TL5BUF" $REF_CHANGED]} {continue}
		lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
	}
	puts "*               Writing './LOAD/TO_LVTH.tcl'...\n"
	WRITE_FILE ./LOAD/TO_LVTH.tcl $CHANGE_LIST
}

proc IS_CLOCK_CELL { {INST} } {
	redirect /dev/null {
		set CHECK [get_attribute [get_pins -of [get_cells $INST] -filter pin_direction=="in"] clocks]
	}
	if {[sizeof_collection $CHECK] > 0} {
		return 1
	} else {
		return 0
	}
}
proc IS_LIB_CELL { {LIB_CELL} } {
	redirect /dev/null { set check [get_lib_cells $LIB_CELL] }
	if {$check == ""} {
		return 0
	} else {
		return 1
	}
}
proc CHNGE_VTH_TO_ML2 {} {
	global STBY_AREA

	puts "* Information : Changing CellVth : WaitArea=Mvth, Others=Lvth."
	puts "*               Making Collections...\n"
	set CELL_ALL [get_cells * -h]
	puts "*               ...Hvth"
	set HVTH_INST [filter_collection $CELL_ALL "ref_name=~TH*"]
	puts "*               ...Mvth"
	set MVTH_INST [filter_collection $CELL_ALL "ref_name=~TM*"]

	# << Making collection of WaitArea >>
	set ALL_WAIT {}
	foreach STBY ${STBY_AREA} {
		puts "*               ...all of '${STBY}'"
		redirect /dev/null {
			set WAIT [filter_collection $CELL_ALL -regexp "full_name =~ \[_/\]?${STBY}\[_/\].*"]
			set WAIT [add_to_collection $WAIT [filter_collection $CELL_ALL -regexp "full_name =~ .*\[_/\]?${STBY}\[_/\].*"]]
			set NUM_CELLS [sizeof_collection $WAIT]
		}
		if {$NUM_CELLS == 0} {
			puts "* Error : Naming Unmatched. Please check name '${STBY}'."
			continue
		} else {
			puts "*                      ...'${NUM_CELLS}' cells are detected."
			set ALL_WAIT [add_to_collection $ALL_WAIT $WAIT]
		}
	}

	puts "*               ...without WaitArea.."
	set HVTH_OTHER [remove_from_collection $HVTH_INST $ALL_WAIT]
	set MVTH_OTHER [remove_from_collection $MVTH_INST $ALL_WAIT]
	set TO_LVTH_TARGET [add_to_collection $HVTH_OTHER $MVTH_OTHER]

	puts "*               ...WaitArea.."
	set HVTH_WAIT  [remove_from_collection $HVTH_INST $HVTH_OTHER]

	# << Hvth => Mvth >> for WaitArea
	puts "*               Making ChangeList for WaitArea...\n"
	set CHANGE_LIST_M ""
	foreach_in_collection INST $HVTH_WAIT {
		set INST_NAME [get_object_name $INST]
		set REF_NAME  [get_attribute $INST ref_name]
		regsub "^THH"     $REF_NAME    "TMM" REF_CHANGED
		regsub "^TH"      $REF_CHANGED "TM"  REF_CHANGED
		lappend CHANGE_LIST_M [concat "${INST_NAME},\$${REF_CHANGED}/${REF_CHANGED}" ]
	}

	# << *vth => Lvth >> for Others
	set NUM_TO_LVTH [sizeof_collection $TO_LVTH_TARGET]
	puts "*               Making ChangeList for Others(${NUM_TO_LVTH})... \n"
	set CHANGE_LIST_L ""
	foreach_in_collection INST $TO_LVTH_TARGET {
		set INST_NAME [get_object_name $INST]
		set REF_NAME  [get_attribute $INST ref_name]
		regsub "^THH"     $REF_NAME    "TLL" REF_CHANGED
		regsub "^TH"      $REF_CHANGED "TL"  REF_CHANGED
		regsub "^TMM"     $REF_CHANGED "TLL" REF_CHANGED
		regsub "^TM"      $REF_CHANGED "TL"  REF_CHANGED
		if {[regexp "^TL5B" $REF_CHANGED]} {continue}
		lappend CHANGE_LIST_L [concat "${INST_NAME},\$${REF_CHANGED}/${REF_CHANGED}" ]
	}

	#<< Write File >>
	puts "*               Writing './LOAD/TO_MVTH.tcl'...\n"
	set fid  [ open "./LOAD/TO_MVTH.tcl" w ]
	puts $fid "set CHANGE_LIST_M \{"
	puts $fid [ join $CHANGE_LIST_M \n ]
	puts $fid "\}"
	puts $fid {
foreach source $CHANGE_LIST_M {
	set str [split $source ","]
	set REF [subst [lindex $str 1]]
	if {[regexp "DFF" $REF]==0 && [regexp "DLAT" $REF]==0 && [IS_CLOCK_CELL [lindex $str 0]]} {continue}
	if {[IS_LIB_CELL $REF]} {
		regsub "," $str { } str
		eval [subst "size_cell $str"]
	}
}
	}
	close $fid

	
	puts "*               Writing './LOAD/TO_LVTH.tcl'...\n"
	set fid  [ open "./LOAD/TO_LVTH.tcl" w ]
	puts $fid "set CHANGE_LIST_L \{"
	puts $fid [ join $CHANGE_LIST_L \n ]
	puts $fid "\}"
	puts $fid {
foreach source $CHANGE_LIST_L {
	set str [split $source ","]
	set REF [subst [lindex $str 1]]
	if {[regexp "DFF" $REF]==0 && [regexp "DLAT" $REF]==0 && [IS_CLOCK_CELL [lindex $str 0]]} {continue}
	if {[IS_LIB_CELL $REF]} {
		regsub "," $str { } str
		eval [subst "size_cell $str"]
	}
}
	}
	close $fid
}

#usage: EXTRACT_OUTPIN_FROM_REP input_report_file
#attention: Only for RC05LP-6pitch. If other technology, please change egrep statement in proc.
#           You must run this in not integrated-DFT but LBIST mode.
proc CHECK_MPI_from_rep { args } {
    set INFILE [open [lindex $args 0] r]
    set OUTFILE [open [lindex $args 1] w]

    while { [gets $INFILE line] > -1 } {
        #if { [get_pins $line]=="" } { continue }
        #if { [regexp "\/CLK" $line] } { continue }
        #if { [regexp "\/Q" $line] } { continue }
        if { [get_attribute [get_pins $line] pin_direction]!="out" } { continue }
        set mpi_value [get_attribute -q [get_pins $line] case_value]
        if { $mpi_value == 0 || $mpi_value == 1 } {
            puts $OUTFILE $line
        }
    }
    close $INFILE; close $OUTFILE
}

proc EXTRACT_OUTPIN_FROM_REP { rep_file } {
    #check report file
    if { ![file exist $rep_file] } { puts "Error: $rep_file does not exist!!"; return 0 } 

    #extract outpins from report file (only for RC05LP-6pitch)
    sh egrep '\\\(TH5*|\\\(TM5*|\\\(TL5*|\\\(THH5*|\\\(TMM5*|\\\(THC*|\\\(TMC*|\\\(TLC*' $rep_file | awk \'{print \$1 }\' | sort -u > tmp1

    #check case setting for the outpins
    set out_file ./Report/add_MPI_false_from_rep_[clock format [clock seconds] -format {%Y%m%d%H%M%S}].list
    CHECK_MPI_from_rep tmp1 tmp2

    #sort
    sh sort -u tmp2 > $out_file
    file delete tmp1 tmp2
}

proc SET_LIBNAME_OF_REF {} {
    set LIB_LIST [COL2LIST [get_libs]]
    foreach lib $LIB_LIST {
        foreach libcell [COL2LIST [get_lib_cells $lib/*]] {
            set REF [lindex [split $libcell "/"] 1]
            eval "set ::$REF $lib"
        }
    }
}

proc CHECK_MAX_CAP { {REF_NAME} } {
	global [subst ${REF_NAME}]
	set LIB_NAME  [subst "$$REF_NAME"]
	set LIB_OPIN  [lindex [COL2LIST [get_lib_pins ${LIB_NAME}/$REF_NAME/* -filter "pin_direction==out"]] 0]
	return [get_attribute [get_lib_pins $LIB_OPIN] max_capacitance]
}

proc CHECK_PITCH { {REF_NAME} } {
    global [subst ${REF_NAME}]
    if {[info exists ::GRID_UNIT]} {
        set GRID_UNIT $::GRID_UNIT
    } else {
        set GRID_UNIT 0.14
    }
    if {[info exists ::HIGHT]} {
        set HIGHT $::HIGHT
    } else {
        set HIGHT 6
    }
    set LIB_NAME  [subst "$$REF_NAME"]
    set AREA  [get_attribute [get_lib_cells ${LIB_NAME}/$REF_NAME] area]
    return [expr $AREA / ( ($GRID_UNIT * $HIGHT) * $GRID_UNIT )]
}

proc CHECK_VTH { {REF_NAME} } {
	if {[regexp "^TUL" $REF_NAME]} {
		return "5"
	} elseif {[regexp "^TS" $REF_NAME]} {
		return "4"
	} elseif {[regexp "^TL" $REF_NAME]} {
		return "3"
	} elseif {[regexp "^TM" $REF_NAME]} {
		return "2"
	} elseif {[regexp "^TH" $REF_NAME]} {
		return "1"
	} else {
		return -1
	}
}

proc REMAKE_TIMING_ECO_COMMAND { {FILE} {ADDNAME ""} } {
    puts ""
    puts "* Start remaking ECO command based on this design."
    # << making library dic >>
    SET_LIBNAME_OF_REF
    if {$ADDNAME == ""} {
        set ADD ""
    } else {
        set ADD ".$ADDNAME"
    }
	
    set LIST_INST {}
    puts "* reading original command..."
    set fid [open $FILE]
    while { [gets $fid str] >= 0 } {
        if {$str == ""} {continue}
            # new design information
            set INST      [lindex $str 1]
            redirect /dev/null {set CHECK_INST [get_cells $INST]}
            if {$CHECK_INST == ""} {continue}
            set TARGET    [lindex $str 2]
            set T_REF     [lindex [split ${TARGET} "/"] 1]
            if {$T_REF == ""} {set T_REF $TARGET}
            #if {$T_REF == ""} {puts "Error : $INST"}
            set T_VTH     [CHECK_VTH     $T_REF]
            set T_AREA    [CHECK_PITCH   $T_REF]
            set T_CAP     [CHECK_MAX_CAP $T_REF]

            # Collection original design information
            set O_REF     [get_attribute [get_cells $INST] ref_name]
            set O_VTH     [CHECK_VTH     $O_REF]
            set O_AREA    [CHECK_PITCH   $O_REF]
            set O_CAP     [CHECK_MAX_CAP $O_REF]
            set OREF($INST) $O_REF

            # Judge change or keep compared to original
            if {$T_REF == $O_REF} {continue}
            if {[info exists TARGET_REF($INST)]} {
                # Collection latest target information
                set CT_REF    $TARGET_REF($INST)
                set CT_VTH    [CHECK_VTH     $CT_REF]
                set CT_AREA   [CHECK_PITCH   $CT_REF]
                set CT_CAP    [CHECK_MAX_CAP $CT_REF]
                if {$T_REF == $CT_REF} {continue}

                if {$T_VTH > $CT_VTH} {
                    if {$T_VTH == 5} {
                        regsub "TH(\[567CDME\])" $CT_REF {TUL\1}  CT_REF
                        regsub "TS(\[567CDME\])" $CT_REF {TUL\1}  CT_REF
                    } elseif {$T_VTH == 4} {
                        regsub "TH(\[567CDME\])" $CT_REF {TS\1}  CT_REF
                    } elseif {$T_VTH == 3} {
                        regsub "TH(\[567CDME\])" $CT_REF {TL\1}  CT_REF
                        regsub "TM(\[567CDME\])" $CT_REF {TL\1}  CT_REF
                    } elseif {$T_VTH == 2} {
                        #regsub {^THH}   $CT_REF {TMM} CT_REF
                        #regsub {^TH}    $CT_REF {TM}  CT_REF
                        regsub "TH(\[567CDME\])" $CT_REF {TM\1}  CT_REF
                    }
                } else {
                    if {$T_VTH == 5} {
                        regsub "TH(\[567CDME\])" $CT_REF {TUL\1}  CT_REF
                        regsub "TS(\[567CDME\])" $CT_REF {TUL\1}  CT_REF
                    } elseif {$T_VTH == 4} {
                        regsub "TH(\[567CDME\])" $CT_REF {TS\1}  CT_REF
                    } elseif {$T_VTH == 3} {
                        #regsub {^THH}   $T_REF {TLL} T_REF
                        #regsub {^TMM}   $T_REF {TLL} T_REF
                        #regsub {^T[HM]} $T_REF {TL}  T_REF
                        regsub "TH(\[567CDME\])" $T_REF {TL\1}  T_REF
                        regsub "TM(\[567CDME\])" $T_REF {TL\1}  T_REF
                    } else {
                        #regsub {^THH}   $T_REF {TMM} T_REF
                        #regsub {^TH}    $T_REF {TM}  T_REF
                        regsub "TH(\[567CDME\])" $T_REF {TM\1}  T_REF
                    }
                }
                set T_CAP     [CHECK_MAX_CAP $T_REF]
                set CT_CAP    [CHECK_MAX_CAP $CT_REF]

                set T_AREA    [CHECK_PITCH   $T_REF]
                set CT_AREA   [CHECK_PITCH   $CT_REF]

                if {$T_CAP > $CT_CAP} {
                    set REF $T_REF
                } else {
                    if {$T_CAP == $CT_CAP} {
                        if {$T_AREA >= $CT_AREA} {
                            set REF $T_REF
                        } else {
                            set REF $CT_REF
                        }
                    } else {
                        set REF $CT_REF
                    }
                }

                if {$REF == $O_REF} {continue}
            } else {
            set CT_REF   $O_REF
            if {$T_VTH > $O_VTH} {
                if {$T_VTH == 3} {
                    #regsub {^THH}   $O_REF {TLL} CT_REF
                    #regsub {^TMM}   $O_REF {TLL} CT_REF
                    #regsub {^T[HM]} $O_REF {TL}  CT_REF
                    regsub "TH(\[567CDME\])" $O_REF  {TL\1}  CT_REF
                    regsub "TM(\[567CDME\])" $CT_REF {TL\1}  CT_REF
                } else {
                    #regsub {^THH}   $O_REF {TMM} CT_REF
                    #regsub {^TH}    $O_REF {TM}  CT_REF
                    regsub "TH(\[567CDME\])" $O_REF {TM\1} CT_REF
                }
                set CT_CAP    [CHECK_MAX_CAP $CT_REF]
            } else {
                if {$O_VTH == 3} {
                    #regsub {^THH}   $T_REF {TLL} T_REF
                    #regsub {^TMM}   $T_REF {TLL} T_REF
                    #regsub {^T[HM]} $T_REF {TL}  T_REF
                    regsub "TH(\[567CDME\])" $T_REF {TL\1}  T_REF
                    regsub "TM(\[567CDME\])" $T_REF {TL\1}  T_REF
                } else {
                    #regsub {^THH}   $T_REF {TMM} T_REF
                    #regsub {^TH}    $T_REF {TM}  T_REF
                    regsub "TH(\[567CDME\])" $T_REF {TM\1}  T_REF
                }
                set CT_CAP    [CHECK_MAX_CAP $O_REF]
            }
            set T_CAP     [CHECK_MAX_CAP $T_REF]

            if {$T_CAP > $CT_CAP} {
                set REF $T_REF
            } else {
                if {$T_CAP == $CT_CAP} {
                    if {$T_AREA >= $O_AREA} {
                        set REF $T_REF
                    } else {
                        set REF $CT_REF
                    }	
                } else {
                    set REF $CT_REF
                }
            }
            if {$REF == $O_REF} {continue}
            lappend LIST_INST $INST
        }

        # Over write target ref
        set TARGET_REF($INST) $REF
    }
    close $fid
    puts "* finished..."
    puts "* Creating new command..."
    echo "" > ${FILE}${ADD}.remake_mix.tcl
    echo "" > ${FILE}${ADD}.remake_mix.dcs
    echo "" > ${FILE}${ADD}.remake_mix.cmd

    # Check param existance
    if {[info exists ::CANCEL_CELL_TYPE_CHECK]} {
        puts "* Information : Cell type check function is disabled."
        set CANCEL_CELL_TYPE_CHECK "YES"
    } else {
        puts "* Information : Cell type check function is enabled."
        set CANCEL_CELL_TYPE_CHECK "NO"
    }

    foreach inst $LIST_INST {
        set REF $TARGET_REF($inst)
        global [subst ${REF}]
        set LIB [subst "$$REF"]
        set T_AREA    [CHECK_PITCH $REF]
        set O_AREA    [CHECK_PITCH $OREF($inst)]
        set DIF_AREA  [expr $T_AREA - $O_AREA]
        if {$DIF_AREA < 0} {
            set DIF_AREA "@D $DIF_AREA"
        } elseif {$DIF_AREA > 0} {
            set DIF_AREA "@U $DIF_AREA"
        } else {
            set DIF_AREA "@S $DIF_AREA"
        }

        # Check
        if {$CANCEL_CELL_TYPE_CHECK == "NO"} { 
            if {![eval "size_cell $inst $REF ;# $OREF($inst) $DIF_AREA"]} {
                echo "* Information : (Skip) Cell Type is mismatched."
                echo "                $inst"
                echo "           NG   $OREF($inst) -> $REF"
                continue
            }
        }
        #echo "size_cell $inst \$::${REF}/$REF ;# $OREF($inst) $DIF_AREA"   >> ${FILE}${ADD}.remake_mix.tcl
        echo "size_cell $inst $REF ;# $OREF($inst) $DIF_AREA"   >> ${FILE}${ADD}.remake_mix.tcl
        #echo "change_link $inst \$::${REF}/$REF ;# $OREF($inst) $DIF_AREA" >> ${FILE}${ADD}.remake_mix.dcs
        echo "change_link $inst $REF ;# $OREF($inst) $DIF_AREA" >> ${FILE}${ADD}.remake_mix.dcs
        echo "+R $OREF($inst) $REF $inst ;# $DIF_AREA"                 >> ${FILE}${ADD}.remake_mix.cmd
    }
    puts "* finished..."
    puts "* Thank you."
    puts ""
}

proc REMAKE_TIMING_ECO_COMMAND_DOPING { {FILE} {ADDNAME ""} } {
    puts ""
    puts "* Start remaking ECO command based on this design."
    # << making library dic >>
    SET_LIBNAME_OF_REF
    if {$ADDNAME == ""} {
        set ADD ""
    } else {
        set ADD ".$ADDNAME"
    }
	
    set LIST_INST {}
    puts "* reading original command..."
    set fid [open $FILE]
    while { [gets $fid str] >= 0 } {
        set REF ""
        if {$str == ""} {continue}
        # new design information
        set INST      [lindex $str 1]
        redirect /dev/null {set CHECK_INST [get_cells $INST]}
        if {$CHECK_INST == ""} {continue}
        set TARGET    [lindex $str 2]
        set T_REF     [lindex [split ${TARGET} "/"] 1]
        if {$T_REF == ""} {puts "Error : $INST"}
        set T_VTH     [CHECK_VTH     $T_REF]
        set T_AREA    [CHECK_PITCH   $T_REF]

        # Collection original design information
        set O_REF     [get_attribute [get_cells $INST] ref_name]
        set O_VTH     [CHECK_VTH     $O_REF]
        set O_AREA    [CHECK_PITCH   $O_REF]
        set OREF($INST) $O_REF

        # Judge change or keep compared to original
        if {$T_REF == $O_REF} {continue}
        if {[info exists TARGET_REF($INST)]} {
            # Collection latest target information
            set CT_REF    $TARGET_REF($INST)
            set CT_VTH    [CHECK_VTH     $CT_REF]
            set CT_AREA   [CHECK_PITCH   $CT_REF]
            if {$T_REF == $CT_REF} {continue}

            if {$T_VTH > $CT_VTH} {
                if {$T_VTH == 3} {
                    #regsub {^THH}   $O_REF {TLL} REF
                    #regsub {^TMM}   $O_REF {TLL} REF
                    #regsub {^T[HM]} $O_REF {TL}  REF
                    regsub "TH(\[567CDME\])" $O_REF {TL\1}  REF
                    regsub "TM(\[567CDME\])" $O_REF {TL\1}  REF
                } else {
                    #regsub {^THH}   $O_REF {TMM} REF
                    #regsub {^TH}    $O_REF {TM}  REF
                    regsub "TH(\[567CDME\])" $O_REF {TM\1}  REF
                }
            } else {
                set REF $O_REF
            }
            if {$REF == $O_REF} {continue}
        } else {
            if {$T_VTH > $O_VTH} {
                if {$T_VTH == 3} {
                    #regsub {^THH}   $O_REF {TLL} REF
                    #regsub {^TMM}   $O_REF {TLL} REF
                    #regsub {^T[HM]} $O_REF {TL}  REF
                    regsub "TH(\[567CDME\])" $O_REF {TL\1}  REF
                    regsub "TM(\[567CDME\])" $O_REF {TL\1}  REF
                } else {
                    #regsub {^THH}   $O_REF {TMM} REF
                    #regsub {^TH}    $O_REF {TM}  REF
                    regsub "TH(\[567CDME\])" $O_REF {TM\1}  REF
                }
            } else {
                set REF $O_REF
            }
            if {$REF == $O_REF} {
                continue
            } else {
                lappend LIST_INST $INST
            }
        }
        if {$REF == ""} {continue}

        # Over write target ref
        set TARGET_REF($INST) $REF
    }
    close $fid
    puts "* finished..."
    puts "* Creating new command..."
    echo "" > ${FILE}${ADD}.remake_mix.tcl
    echo "" > ${FILE}${ADD}.remake_mix.dcs
    echo "" > ${FILE}${ADD}.remake_mix.cmd

    # Check param existance
    if {[info exists ::CANCEL_CELL_TYPE_CHECK]} {
        puts "* Information : Cell type check function is disabled."
        set CANCEL_CELL_TYPE_CHECK "YES"
    } else {
        puts "* Information : Cell type check function is enabled."
        set CANCEL_CELL_TYPE_CHECK "NO"
    }

    foreach inst $LIST_INST {
        set REF $TARGET_REF($inst)
        global [subst ${REF}]
        set LIB [subst "$$REF"]
        set T_AREA    [CHECK_PITCH $REF]
        set O_AREA    [CHECK_PITCH $OREF($inst)]
        set DIF_AREA  [expr $T_AREA - $O_AREA]
        if {$DIF_AREA < 0} {
            set DIF_AREA "@D $DIF_AREA"
        } elseif {$DIF_AREA > 0} {
            set DIF_AREA "@U $DIF_AREA"
        } else {
            set DIF_AREA "@S $DIF_AREA"
        }

        # Check
        if {$CANCEL_CELL_TYPE_CHECK == "NO"} { 
            if {![eval "size_cell $inst \$::${REF}/$REF ;# $OREF($inst) $DIF_AREA"]} {
                echo "* Information : (Skip) Cell Type is mismatched."
                echo "                $inst"
                echo "           NG   $OREF($inst) -> $REF"
                continue
            }
        }
        #echo "size_cell $inst \$::${REF}/$REF ;# $OREF($inst) $DIF_AREA"   >> ${FILE}${ADD}.remake_mix.tcl
        #echo "change_link $inst \$::${REF}/$REF ;# $OREF($inst) $DIF_AREA" >> ${FILE}${ADD}.remake_mix.dcs
        echo "size_cell $inst $REF ;# $OREF($inst) $DIF_AREA"   >> ${FILE}${ADD}.remake_mix.tcl
        echo "change_link $inst $REF ;# $OREF($inst) $DIF_AREA" >> ${FILE}${ADD}.remake_mix.dcs
        echo "+R $OREF($inst) $REF $inst ;# $DIF_AREA"                 >> ${FILE}${ADD}.remake_mix.cmd
    }
    puts "* finished..."
    puts "* Thank you."
    puts ""
}


proc CHECK_ECO { {ECO_FILE} {OPTION "default"} } {
    set fid [open "${ECO_FILE}" r]
    set num   0
    set FLAG  0
    set FLAG1 0
    set FLAG2 0
    set FLAG3 0
    while {[gets $fid str]>=0} {
        set NG 0
        set ErrMessage1 {}
        set ErrMessage2 {}
        set ErrMessage3 {}
        set CMD  [lindex $str 0]
        if {$str == "^$"} { continue }
        if {$CMD == "+C"} { continue }
        set PRE  [lindex $str 1]
        set POST [lindex $str 2]
        set INST [lindex $str 3]

        set num  [expr $num + 1]

        # CHECK
        set INST_REAL [get_cells $INST]
        set REF_REAL  [get_attribute $INST_REAL ref_name]

        if {[sizeof_collection $INST_REAL] == 0} {
            set ErrMessage1 "Error(Instance is missing)    line(${num}) : $INST"
            set FLAG1 [expr $FLAG1 + 1]
            set NG 1
        } 
        if {$REF_REAL != $PRE} {
            set ErrMessage2 "Error(Current ref = ECO-pre)  line(${num}) : $INST"
            set FLAG2 [expr $FLAG2 + 1]
            set NG 1
        }
        if {$REF_REAL == $POST} {
            set ErrMessage3 "Error(Current ref = ECO-post) line(${num}) : $INST"
            set FLAG3 [expr $FLAG3 + 1]
            set NG 1
        }
        if {$NG == "0"} {
            if {$OPTION == "-force"} {puts $str }
        } else {
            set FLAG [expr $FLAG + 1]
            if {$OPTION == "default"} {
                if {$ErrMessage1 != ""} {puts $ErrMessage1}
                if {$ErrMessage2 != ""} {puts $ErrMessage2}
                if {$ErrMessage3 != ""} {puts $ErrMessage3}
            }
        }
    }
    close $fid
    if {$FLAG >= "1"} {
        puts {}
        puts "================================================================="
        puts " << Check Result Summary >>"
        puts " File: '${ECO_FILE}'"
        puts "-----------------------------------------------------------------"
        puts [format "%12d Error : Instance name mismatched" ${FLAG1}]
        puts [format "%12d Error : Current cell type is wrong." ${FLAG2}]
        puts [format "%12d Error : Current cell type is equal to ECO-target." ${FLAG3}]
        puts "-----------------------------------------------------------------"
        puts " Total '${FLAG}/${num}' errors are in ECO command file."
        puts "================================================================="
        puts {}
        return -1
    } else {
        puts ""
        puts " Result($ECO_FILE) : SUCCEEDED"
        puts "If you want to make ECO files for (Layout,PrimeTime,DesignCompiler), use 'mkECO' command."
        puts "Thank you."; puts {}
        return 1
    }
}

proc mkECO { {ECO_FILE} } {
    set result [CHECK_ECO $ECO_FILE]
    if {$result == "-1"} { return -1 }

    set OUTFILE_CMD "${ECO_FILE}.cmd"
    set OUTFILE_TCL "${ECO_FILE}.tcl"
    set OUTFILE_DCS "${ECO_FILE}.dcs"

    set fid_cmd [open "${OUTFILE_CMD}" w]
    set fid_tcl [open "${OUTFILE_TCL}" w]
    set fid_dcs [open "${OUTFILE_DCS}" w]

    set num  0
    set FLAG 0
    set fid [open "${ECO_FILE}" r]
    while {[gets $fid str]>=0} {
        set num [expr $num + 1]
        set CMD  [lindex $str 0]
        set PRE  [lindex $str 1]
        set POST [lindex $str 2]
        set INST [lindex $str 3]

        # CHECK
        set INST_REAL [get_cells $INST]
        set REF_REAL  [get_attribute $INST_REAL ref_name]

        set string.cmd "$CMD $REF_REAL $POST $INST"
        set string.tcl "size_cell $INST $$POST/$POST ;# $REF_REAL"
        set string.dcs "change_link $INST $$POST/$POST ;# $REF_REAL"

        puts $fid_cmd ${string.cmd}
        puts $fid_tcl ${string.tcl}
        puts $fid_dcs ${string.dcs}
    }
    close $fid
    close $fid_cmd
    close $fid_tcl
    close $fid_dcs
    puts ""
    puts "Thank you."; puts {}
}

proc mkPROHIBITED_DOPING {} {

	set RESTRICT_CELLS {
		TH5INVXC
		TH5INVZHXB
		TH5INVZLXB
		TH5INVCLXB
		TL5INVXC
		TL5INVZHXB
		TL5INVZLXB
		TL5INVCLXB
	}
	# << For General Module >>
	set POST(TH5INVXC)   TM5INVXC
	set POST(TH5INVZHXB) TM5INVZHXB
	set POST(TH5INVZLXB) TM5INVZLXB
	set POST(TH5INVCLXB) TM5INVCLXB
	set POST(TL5INVXC)   TM5INVXC
	set POST(TL5INVZHXB) TM5INVZHXB
	set POST(TL5INVZLXB) TM5INVZLXB
	set POST(TL5INVCLXB) TM5INVCLXB
		
	set ALL_INST [get_cells * -h]
	set TARGET_INST {}
	foreach ref $RESTRICT_CELLS {
		set TARGET [filter_collection $ALL_INST ref_name==$ref]
		set TARGET_INST [add_to_collection $TARGET_INST $TARGET]
	}
	
	echo "" > COMMAND.DOPING_PROHIBITED.tcl
	echo "" > COMMAND.DOPING_PROHIBITED.dcs
	echo "" > COMMAND.DOPING_PROHIBITED.cmd
	foreach_in_collection inst $TARGET_INST {
		set NAME [get_object_name $inst]
		set REF  [get_attribute $inst ref_name]
		set TGT  $POST($REF)
		if {$TGT == "KEEP"} {continue}
		echo [format "size_cell %s $%s/%s ;# %s" $NAME $TGT $TGT $REF]   >> COMMAND.DOPING_PROHIBITED.tcl
		echo [format "change_link %s $%s/%s ;# %s" $NAME $TGT $TGT $REF] >> COMMAND.DOPING_PROHIBITED.dcs
		echo [format "+R %s %s %s" $REF $TGT $NAME]                      >> COMMAND.DOPING_PROHIBITED.cmd
	}
}
proc mkPROHIBITED_ECO { {ENABLE_SIZEUP "NO"} } {

	set RESTRICT_CELLS {
		TH5INVXC
		TH5INVZHXB
		TH5INVZLXB
		TH5INVCLXB
		TM5INVXC
		TL5INVXC
		TL5INVZHXB
		TL5INVZLXB
		TL5INVCLXB
	}
	if {$ENABLE_SIZEUP == "YES"} {
		# << For General Module >>
		set POST1(TH5INVXC)   TL5INVXD ;# +0p
		set POST1(TH5INVZHXB) TM5INVXD ;# +0p
		set POST1(TH5INVZLXB) TM5INVXD ;# +0p
		set POST1(TH5INVCLXB) TM5INVXD ;# +0p
		set POST1(TM5INVXC)   TL5INVXD ;# +1p
		set POST1(TL5INVXC)   TL5INVXD ;# +1p
		set POST1(TL5INVZHXB) TL5INVXD ;# +1p
		set POST1(TL5INVZLXB) TL5INVXD ;# +1p
		set POST1(TL5INVCLXB) TL5INVXD ;# +1p
		
		# << For Physical Compiled Module >>
		set POST2(TH5INVXC)   TM5INVXC ;# +0p
		set POST2(TH5INVZHXB) TM5INVXC ;# +0p
		set POST2(TH5INVZLXB) TM5INVXC ;# +0p
		set POST2(TH5INVCLXB) TM5INVXC ;# +0p
		set POST2(TM5INVXC)   KEEP     ;# +0p
		set POST2(TL5INVXC)   TM5INVXC ;# +0p
		set POST2(TL5INVZHXB) TM5INVXC ;# +0p
		set POST2(TL5INVZLXB) TM5INVXC ;# +0p
		set POST2(TL5INVCLXB) TM5INVXC ;# +0p
		
		# << For WaitArea Module >>
		set POST3(TH5INVXC)   TH5INVXD   ;# +1p
		set POST3(TH5INVZHXB) TH5INVZHXH ;# +1p
		set POST3(TH5INVZLXB) TH5INVZLXH ;# +1p
		set POST3(TH5INVCLXB) TH5INVCLXH ;# +1p
		set POST3(TM5INVXC)   TM5INVXD   ;# +1p
		set POST3(TL5INVXC)   TM5INVXE   ;# +1p
		set POST3(TL5INVZHXB) TM5INVZHXH ;# +1p
		set POST3(TL5INVZLXB) TM5INVZLXC ;# +1p (max_cap doun 0.043 -> 0.039)
		set POST3(TL5INVCLXB) TM5INVCLXH ;# +1p
	} else {
		# << For General Module >>
		set POST1(TH5INVXC)   TL5INVXA ;# +0p
		set POST1(TH5INVZHXB) TM5INVXA ;# +0p
		set POST1(TH5INVZLXB) TM5INVXA ;# +0p
		set POST1(TH5INVCLXB) TM5INVXC ;# +0p
		set POST1(TM5INVXC)   KEEP
		set POST1(TL5INVXC)   TM5INVXC ;# +0p
		set POST1(TL5INVZHXB) TM5INVXC ;# +0p
		set POST1(TL5INVZLXB) TM5INVXC ;# +0p
		set POST1(TL5INVCLXB) TM5INVXC ;# +0p
		
		# << For Physical Compiled Module >>
		set POST2(TH5INVXC)   TM5INVXC ;# +0p
		set POST2(TH5INVZHXB) TM5INVXC ;# +0p
		set POST2(TH5INVZLXB) TM5INVXC ;# +0p
		set POST2(TH5INVCLXB) TM5INVXC ;# +0p
		set POST2(TM5INVXC)   KEEP
		set POST2(TL5INVXC)   TM5INVXC ;# +0p
		set POST2(TL5INVZHXB) TM5INVXC ;# +0p
		set POST2(TL5INVZLXB) TM5INVXC ;# +0p
		set POST2(TL5INVCLXB) TM5INVXC ;# +0p
		
		# << For WaitArea Module >>
		set POST3(TH5INVXC)   TM5INVXC ;# +0p
		set POST3(TH5INVZHXB) TM5INVXC ;# +0p
		set POST3(TH5INVZLXB) TM5INVXC ;# +0p
		set POST3(TH5INVCLXB) TM5INVXC ;# +0p
		set POST3(TM5INVXC)   KEEP
		set POST3(TL5INVXC)   TM5INVXC ;# +0p
		set POST3(TL5INVZHXB) TM5INVXC ;# +0p
		set POST3(TL5INVZLXB) TM5INVXC ;# +0p (max_cap doun 0.043 -> 0.039)
		set POST3(TL5INVCLXB) TM5INVXC ;# +0p
	}
	
	
	# << Special Area>>
	set WAIT {PVC5 PVBA4 PVBW3 PVBG3}
	set PhyC {SGX apatop0 E100}
	
	set ALL_INST [get_cells * -h]
	set TARGET_INST {}
	foreach ref $RESTRICT_CELLS {
		set TARGET [filter_collection $ALL_INST ref_name==$ref]
		set TARGET_INST [add_to_collection $TARGET_INST $TARGET]
	}
	
	
	echo "" > COMMAND.PROHIBITED.tcl
	foreach_in_collection inst $TARGET_INST {
		set NAME [get_object_name $inst]
		set REF  [get_attribute $inst ref_name]
	
		if {[regexp_list $WAIT $NAME]} {
			set TGT  $POST3($REF)
	
		} elseif {[regexp_list $PhyC $NAME]} {
			set TGT  $POST2($REF)
	
		} else {
			set TGT  $POST1($REF)
		}
		if {$TGT == "KEEP"} {continue}
		#echo [format "size_cell %s $%s/%s ;# %s" $NAME $TGT $TGT $REF] >> COMMAND.PROHIBITED.tcl
		echo [format "size_cell %s %s ;# %s" $NAME $TGT $REF] >> COMMAND.PROHIBITED.tcl
		echo [format "+R %s %s ;# %s" $REF $TGT $NAME]        >> COMMAND.PROHIBITED.cmd
	}
}
proc CHECK_PROHIBIT {} {
	global PROHIBIT_REF_ALL
	set PROHIBIT_REF_LIST $PROHIBIT_REF_ALL
	puts ""
	puts "* Information: Start check pohibited cell existance."
	puts "* Information: Collecting information of instance on whole chip."
	set ALL_INST [get_cells * -h]
	foreach ref $PROHIBIT_REF_LIST {
		puts ""
		echo "# Library cell name : '$ref'"
		set TARGET {}
		set TARGET [filter_collection $ALL_INST ref_name==$ref]
	
		foreach_in_collection inst $TARGET {
			set NAME [get_object_name $inst]
			#set REF  [get_attribute $inst ref_name]
			echo [format "%20s %s" $ref $NAME]
		}
	}
}

proc mkMETA_ECO { {LIST_FILE} {VTH "LVTH"} } {
    if {$VTH == "LVTH"} {
        set CHK "^TL"
    } elseif {$VTH == "MVTH"} {
        set CHK "^T\[ML\]"
    } else {
        puts "# Error : you must give 'MVTH or LVTH' key."
        return 0
    }

    set numError 0
    set numOK    0
    set numNG    0
    set numTotal 0

    set fid [open $LIST_FILE]
    echo "" > ./COMMAND.META.${VTH}.tcl
    echo "" > ./COMMAND.META.${VTH}.cmd
    while { [gets $fid str] >= 0 } {
        if {$str == ""} { continue }
        if {[regexp {^#} $str]} { continue }
        incr numTotal
        if {[regexp {CAN'T FIND instance} $str]} {
            continue
        }
        set inst [lindex $str 0]

        redirect /dev/null {set INST [get_cells $inst]}
        if {$INST == ""} {
            puts "# Error : '$inst' mismatch"
            echo "# Error : '$inst' mismatch"  >> ./COMMAND.META.${VTH}.tcl
            echo "+C Error : '$inst' mismatch" >> ./COMMAND.META.${VTH}.cmd
            incr numError
            continue
            #return 0
        }
        set REF  [get_attribute $INST ref_name]

        if {[regexp $CHK $REF]} {
            echo [format "  OK : %-25s %s" $REF $inst]
            incr numOK
        } else {
            echo [format "# NG : %-25s %s" $REF $inst]
            incr numNG

            if {$VTH == "LVTH"} {
                regsub "^THH" $REF {TLL} TGT
                regsub "^TH"  $TGT {TL}  TGT
                regsub "^TMM" $TGT {TLL} TGT
                regsub "^TM"  $TGT {TL}  TGT
            } else {
                regsub "^THH" $REF {TMM} TGT
                regsub "^TH"  $TGT {TM}  TGT
            }
            #echo [format "size_cell %s %s%s/%s ;# %s" $inst "$" $TGT $TGT $REF] >> ./COMMAND.META.${VTH}.tcl
            echo [format "size_cell %s %s ;# %s" $inst $TGT $REF] >> ./COMMAND.META.${VTH}.tcl
            echo [format "+R %s %s %s" $REF $TGT $inst]           >> ./COMMAND.META.${VTH}.cmd
        }
    }
    echo ""
    echo "----------------------------------"
    echo [format " %6s %6s %6s %6s" OK NG Error Total]
    echo [format " %6d %6d %6d %6d" $numOK $numNG $numError $numTotal]
    echo "----------------------------------"
    close $fid
}

# << Start of line for mk45 >>
proc get_met_domain {} {
    set REP [get_timing_path -slack_less 0.00001]
    foreach_in_collection rep $REP {
        lappend return_path_group [get_attribute [get_attribute $rep path_group] full_name]	
    }
    set return_path_group [remove_from_collection [get_path_group *] [get_path_group $return_path_group]]
    return $return_path_group
}

proc get_violated_domain {} {
    set REP [get_timing_path -slack_less 0.00001]
    foreach_in_collection rep $REP {
        lappend return_path_group [get_attribute [get_attribute $rep path_group] full_name]	
    }
    return $return_path_group
}

proc find_ref { {REF_NAME} } {
    global [subst ${REF_NAME}]
    set LIB [subst $$REF_NAME]
    regsub {X[A-Z0-9][A-Z0-9]?[A-Z0-9]?$} $REF_NAME {X*} REF
    set LIB_PIN [get_lib_pins $LIB/$REF/* -filter pin_direction==out]
    set LIST [COL2LIST [sort_collection $LIB_PIN {full_name max_capacitance}]]
    set O_AREA [get_attri [get_lib_cells $LIB/$REF_NAME] area]
    set O_PITCH [expr $O_AREA / (0.14 * 0.14 * 6)]
    set O_CAP   [get_attri [get_lib_pins $LIB/$REF/* -filter pin_direction==out] max_capacitance]

    puts "-------------------------------------------------------------------"
    puts "DeltaPitch (LibPitch) MaxCap   LibCellName"
    puts "-------------------------------------------------------------------"
    foreach tmp $LIST {
        set REF [get_object_name [get_lib_cells -of $tmp]]
        set CAP [get_attri [get_lib_pins $tmp] max_capacitance]
        set AREA [get_attri [get_lib_cells $REF] area]
        set PITCH [expr $AREA / (0.14 * 0.14 * 6)]
        puts [format "  %5.1f (%5.1f) %10.3f  %s" [expr $PITCH - $O_PITCH] $PITCH  $CAP   $REF]
    }
    puts "-------------------------------------------------------------------"
}

proc get_mk45_target {} {
    set REP [get_timing_path -slack_less 0.00001]
    if {[sizeof_collection $REP] == 0} {
        puts "* Information : There is nothing timing-path to show."
        puts "                Please check the situation of path-group by command 'get_path_group'."
        return ""
    }
    foreach_in_collection rep $REP {
        # << information >>
        set SLACK [get_attribute $rep slack]
        set CLK_ST [get_object_name [get_attribute $rep startpoint_clock]]
        set CLK_ED [get_object_name [get_attribute $rep endpoint_clock]]
        set GROUP [get_attribute [get_attribute $rep path_group] full_name]
        set PERI_ST    [get_attribute $rep startpoint_clock_open_edge_value]
        set PERI_ED    [get_attribute $rep endpoint_clock_close_edge_value]
        set SPEC       [expr $PERI_ED - $PERI_ST]
        set A_ARRIVAL  [expr $PERI_ED - $PERI_ST -$SLACK]
        set RATIO      [expr $A_ARRIVAL / $SPEC]

        # << making databae >>
        set DOMAIN ${CLK_ST}@${CLK_ED}
        if {[info exists DB_RATIO($DOMAIN)]} {
            incr DB_NUM($DOMAIN)
            if {$DB_RATIO($DOMAIN) < $RATIO} {
                set DB_RATIO($DOMAIN) $RATIO
            }
            if {$DB_WNS($DOMAIN) > $SLACK} {
                set DB_WNS($DOMAIN) $SLACK
            }
            set DB_TNS($DOMAIN) [expr $DB_TNS($DOMAIN) + $SLACK]
        } else {
            set DB_NUM($DOMAIN) 1
            set DB_RATIO($DOMAIN) $RATIO
            set DB_WNS($DOMAIN) $SLACK
            set DB_TNS($DOMAIN) $SLACK
            lappend list_domain $DOMAIN
        }
    }
    if {[info exists ::gr_LIMIT_RATIO]} {
        puts ""; puts "* LIMIT_RATIO : $::gr_LIMIT_RATIO"
    }
    set result ""
    foreach domain $list_domain {
        set ST [lindex [split $domain "@"] 0]
        set ED [lindex [split $domain "@"] 1]
        set string [format "%5.3f %5.3f %6.1f %3d -from %30s -to %30s" \
            $DB_RATIO($domain) $DB_WNS($domain) $DB_TNS($domain) $DB_NUM($domain) $ST $ED]

        if {[info exists ::gr_LIMIT_RATIO]} {
            if {$DB_RATIO($domain) < $::gr_LIMIT_RATIO} {continue}
        }
        lappend result $string
    }
    set return_value {}
    foreach tmp [lsort -index 0 -decreasing $result] {
        set ratio [lindex $tmp 0]
        set group [lindex $tmp 7]
        #puts "$ratio	$group"
        lappend return_value $group
    }
    return $return_value
}

proc get_slack { {MAX 1} } {
    #set REP [get_timing_path -slack_less 0.00001 -max $MAX -group [get_path_groups *]]
    set REP {}
    foreach_in_collection group [get_path_groups *] {
        set REP [add_to_collection $REP [get_timing_path -gr $group -slack_less 0.00001 -max $MAX]]
    }
    puts "Done get_path_group"
    if {[sizeof_collection $REP] == 0} {
        puts "* Information : There is nothing timing-path to show."
        puts "                Please check the situation of path-group by command 'get_path_group'."
        return 0
    }
    foreach_in_collection rep $REP {
        set path_endpoint [get_attribute $rep endpoint]
        puts "[get_object_name $path_endpoint]"
        # << information >>
        set IS_ST_LATCH [get_attribute $rep startpoint_is_level_sensitive]
        set IS_ED_LATCH [get_attribute $rep endpoint_is_level_sensitive]
        #if {$IS_ST_LATCH == "true"} {puts "# Start is latch"}
        #if {$IS_ED_LATCH == "true"} {puts "# End is latch"}
        set SLACK [get_attribute $rep slack]
        set CLK_ST [get_object_name [get_attribute -q $rep startpoint_clock]]
        set CLK_ED [get_object_name [get_attribute -q $rep endpoint_clock]]
        set GROUP [get_attribute [get_attribute $rep path_group] full_name]
        set PERI_ST    [get_attribute -quiet $rep startpoint_clock_open_edge_value]
        set PERI_ED    [get_attribute -quiet $rep endpoint_clock_close_edge_value]
        if {[info exist PERI_ST] && [info exist PERI_ED] && $PERI_ST !="" && $PERI_ED != ""} {
            set SPEC       [expr $PERI_ED - $PERI_ST]
            set A_ARRIVAL  [expr $PERI_ED - $PERI_ST -$SLACK]
            # Case latch time borrow or lent
            set TIME_BORROW [get_attribute $rep time_borrowed_from_endpoint]
            set TIME_LENT   [get_attribute $rep time_lent_to_startpoint]
            #puts "# A_ARRIVAL=$A_ARRIVAL SPEC=$SPEC Borrow=$TIME_BORROW Lent=$TIME_LENT IS_ST_LATCH($IS_ST_LATCH) IS_ED_LATCH($IS_ED_LATCH) CLK_ST($CLK_ST:$PERI_ST) CLK_ED($CLK_ED:$PERI_ED)"
        } else {
            set START_LATENCY    [get_attribute -quiet $rep startpoint_clock_latency]
            set REQUIRED_TIME    [get_attribute -quiet $rep required]
            set SETUP_TIME       [get_attribute -quiet $rep endpoint_setup_time_value]
            set RECOV_TIME       [get_attribute -quiet $rep endpoint_recovery_time_value]
            set UNCERTAINTY      [get_attribute -quiet $rep clock_uncertainty]
            if {![info exist START_LATENCY] || $START_LATENCY == ""} {
                set START_LATENCY 0
            }
            if {![info exist SETUP_TIME] || $SETUP_TIME == "" } {
                set SETUP_TIME 0
            }
            if {![info exist RECOV_TIME] || $RECOV_TIME == "" } {
                set RECOV_TIME 0
            }
            if {![info exist UNCERTAINTY] || $UNCERTAINTY == "" } {
                set UNCERTAINTY 0
            }
            set CYCLE_TIME       [expr $REQUIRED_TIME - $START_LATENCY - $UNCERTAINTY + $SETUP_TIME + $RECOV_TIME]
            set A_ARRIVAL   [expr $CYCLE_TIME -$SLACK]
        }

        if {$SPEC == 0} {
            set SPEC $PERI_ED
            if {$SLACK >= 0} {
                set RATIO 1
            } else {
                if {$PERI_ED == 0} {
                    set RATIO 1
                    set SPEC  1
                } else {
                    set RATIO [expr ($SLACK + $PERI_ED) / $PERI_ED]
                }
            }
        }

        set RATIO      [expr $A_ARRIVAL / $SPEC]

        # << making databae >>
        set DOMAIN ${CLK_ST}@${CLK_ED}
        if {[info exists DB_RATIO($DOMAIN)]} {
            incr DB_NUM($DOMAIN)
            if {$DB_RATIO($DOMAIN) < $RATIO} {
                set DB_RATIO($DOMAIN) $RATIO
            }
            if {$DB_WNS($DOMAIN) > $SLACK} {
                set DB_WNS($DOMAIN) $SLACK
            }
            set DB_TNS($DOMAIN) [expr $DB_TNS($DOMAIN) + $SLACK]
        } else {
            set DB_NUM($DOMAIN) 1
            set DB_RATIO($DOMAIN) $RATIO
            set DB_WNS($DOMAIN) $SLACK
            set DB_TNS($DOMAIN) $SLACK
            lappend list_domain $DOMAIN
        }
    }
    if {[info exists ::gr_LIMIT_RATIO]} {
        puts ""; puts "* LIMIT_RATIO : $::gr_LIMIT_RATIO"
    }
    puts "------------------------------------------------------------------------------------------------"
    puts [format "%5s %5s %6s  %3s -from %30s -to %30s" RATIO WNS TNS Num StartClock EndClock]
    puts "------------------------------------------------------------------------------------------------"

    # << For convenience >>
    redirect /dev/null {
        #set MUSK [COL2LIST [get_clocks {*ZCLK* *RamStrobe*}]]
        set MUSK [COL2LIST [get_clocks {}]]
        set ABE  [COL2LIST [get_clocks {}]]
        set UNE  [COL2LIST [get_clocks {*ZB3CLK* *DDRCLK* *ZB3D2CLK* *DDRCLK400* *ZB3CLK200* *ZSCLK* *SCLK* }]]
        set NAKA [COL2LIST [get_clocks {*M1CLK* *FSIA_ckgo_sdi_bck* *SPUCLK* *DT0CLK8B* *HPCLK* *ISPBCLK* *CPCLK*}]]
    }
    set result ""
    foreach domain $list_domain {
        set ST [lindex [split $domain "@"] 0]
        set ED [lindex [split $domain "@"] 1]
        if {[lsearch -inline $MUSK $ED] >= 0} {continue}
        set string [format "%5.3f %5.3f %6.1f %3d -from %30s -to %30s" \
            $DB_RATIO($domain) $DB_WNS($domain) $DB_TNS($domain) $DB_NUM($domain) $ST $ED]

        # << If you want to make a charge clear >>
        #if {[lsearch -inline $ABE  $ED] >= 0} {set string "$string ;Abe"}
        #if {[lsearch -inline $UNE  $ED] >= 0} {set string "$string ;Shitaune"}
        #if {[lsearch -inline $KOJI $ED] >= 0} {set string "$string ;Kojima"}
        #if {[lsearch -inline $NAKA $ED] >= 0} {set string "$string ;Nakagawa"}

        if {[info exists ::gr_LIMIT_RATIO]} {
            if {$DB_RATIO($domain) < $::gr_LIMIT_RATIO} {continue}
        }
        lappend result $string
    }
    foreach tmp [lsort -real -index 0 -decreasing $result] {
        puts $tmp
    }
    puts "------------------------------------------------------------------------------------------------"
}

proc DISP_REP { {REP} } {
	foreach_in_collection rep $REP {
		set FF_LIB_SETUP [get_attribute $rep endpoint_setup_time_value]
		foreach_in_collection point [get_attribute $rep points] {
			set TRAN {}
			set ARRIVAL_TIME {}
			set OBJECT       [get_attribute $point  object]
			set NAME         [get_attribute $OBJECT full_name]
			redirect /dev/null { set INST [get_cells -of $OBJECT] }
			set TRAN         [get_attribute $point  transition]
			set ARRIVAL_TIME [get_attribute $point  arrival]
			echo [format "%6.4f %6.4f %s" $TRAN $ARRIVAL_TIME $NAME]
		}
			echo [format "%6.4f %6.4f %s LibrarySetupTime" $TRAN $FF_LIB_SETUP $NAME]
	}
}

proc regexp_list { {list} {string} } {
    foreach tmp $list {
        if {[regexp $tmp $string] != 0} { return 1 }
    }
    return 0
}

proc ADD_ORIGINAL_AREA { {HIGHT 6} {GRID_UNIT 0.14} } {
    echo "* adding original cell area..."
    suppress_message {UIAT-4}
    set area_ratio [expr ($HIGHT * $GRID_UNIT) * $GRID_UNIT]
    define_user_attribute -class cell -type float o_area
    #define_user_attribute -class pin  -type float o_maxcap
    foreach_in_collection inst [get_cells * -h] {
        set o_area [get_attribute $inst area]
        set pitch  [expr $o_area / $area_ratio]
        redirect /dev/null {set_user_attribute $inst o_area $pitch}
    }
}
# << End of line for mk45 >>

proc SET_CASE_ANALYSIS_FOR_SENGEN { {TARGET_SENBR "SENBR"} } {
	set TARGET_SENBR [get_nets -q $TARGET_SENBR]
	if {[sizeof_collection $TARGET_SENBR] == 0} {
		return "# Error : There is no 'SENBR' net in this design."
	}
	set_case_analysis 0 [get_pins -of [get_nets $TARGET_SENBR ] -filter "direction == out"]
	set QEM_cell [ get_cell -h * -filter "@ref_name=~*DFFQEM*"]
	set kotei ""

	echo "#=========================================="
	echo "# set_case_analysis constraints for SENGEN"
	echo "#=========================================="
	echo ""
	redirect /dev/null {
		foreach_in_collection TARGET $QEM_cell {
			set local [get_object_name $TARGET]
			set val_sem [get_attri -q [get_pins  $local/SEM]  case_value]
			set val_dat [get_attri -q [get_pins  $local/DATA] case_value]
			if { $val_sem == 0 && $val_dat == 0} {
				set kotei [add_to_collection $kotei [get_cell $local]]
			}
		}
	}
	foreach_in_collection TARGET $kotei {
		set local [get_object_name $TARGET]
		echo "set_case_analysis 0 \[get_pins $local/Q \]"
	}
}

# << MPI check >>
proc CHECK_MPI { PIN_NAME } {

define_user_attribute -q -class pin -type string ACBIST_WARNING

  set ::HT_MPI_wo_CASE   {}
  set ::OTHER_PIN_wo_CASE   {}
  set ::OTHER_PIN_WITH_CASE {}
  set ::HT_MPI_WITH_CASE {}

  set PIN [ get_pins -q  ${PIN_NAME} ]
  foreach_in_collection tmp ${PIN} {
   FIND_MPI ${tmp}
  }

  echo "###################################################"
  echo "# ERROR:                                          #"
  echo "#  HT-MPI Cells without Case-Propagating          #"
  echo "#  Confirm Designers whether they need ECO or not #"
  echo "###################################################"
  if { [sizeof_collection ${::HT_MPI_wo_CASE}] > 0 } {
    foreach_in_collection tmp ${::HT_MPI_wo_CASE} {
       echo "[get_attribute [get_pins $tmp] ACBIST_WARNING]  [get_object_name ${tmp}]  ;# No case-value  ([get_attribute [get_cells -of $tmp] ref_name])"
    }
  } else {
    echo "No pins matched."
  }
  echo "###########################################"
  echo "# WARNING:                                #"
  echo "#  Non HT-MPI Cells with Case-Propagating #"
  echo "#  Check the Timing constraints for them  #"
  echo "###########################################"
  if { [sizeof_collection ${::OTHER_PIN_WITH_CASE}] > 0 } {
    foreach_in_collection tmp ${::OTHER_PIN_WITH_CASE} {
       echo "[get_attribute [get_pins $tmp] ACBIST_WARNING]  [get_object_name ${tmp}]  ;# Case: [get_attribute [get_pins $tmp] case_value]  ([get_attribute [get_cells -of $tmp] ref_name])"
    }
  } else {
    echo "No pins matched."
  }
  echo "#######################################"
  echo "# Information(1):                     #"
  echo "#  HT-MPI Cells with Case-Propagating #"
  echo "#######################################"
  if { [sizeof_collection ${::HT_MPI_WITH_CASE}] > 0 } {
    foreach_in_collection tmp ${::HT_MPI_WITH_CASE} {
       echo "[get_attribute [get_pins $tmp] ACBIST_WARNING]  [get_object_name ${tmp}]  ;# Case: [get_attribute [get_pins $tmp] case_value]  ([get_attribute [get_cells -of $tmp] ref_name])"
    }
  } else {
    echo "No pins matched."
  }
  echo "##############################################"
  echo "# Information(2):                            #"
  echo "#  Non HT-MPI Cells without Case-Propagating #"
  echo "##############################################"
  if { [sizeof_collection ${::OTHER_PIN_wo_CASE}] > 0 } {
    foreach_in_collection tmp ${::OTHER_PIN_wo_CASE} {
       echo "[get_attribute [get_pins $tmp] ACBIST_WARNING]  [get_object_name ${tmp}]  ;# No case-value  ([get_attribute [get_cells -of $tmp] ref_name])"
    }
  } else {
    echo "No pins matched."
  }
}

proc FIND_MPI { PIN_NAME } {

  set START_CASE_VALUE [ get_attribute [ get_pins ${PIN_NAME} ] case_value ]
  set CONNECTED_NET [ get_nets -of ${PIN_NAME} ]
  set INPUT_PINS    [ get_pins -l -of ${CONNECTED_NET} -filter "direction==in" ]
  foreach_in_collection tmp ${INPUT_PINS} {
      set FOUND_CELL [ get_cells -of $tmp ]
      set REF_NAME   [ get_attribute [ get_cells ${FOUND_CELL} ] ref_name ]
      redirect /dev/null { set OUTPUT_PIN [ get_pins -of  [ get_cells ${FOUND_CELL} ] -filter "direction==out" -l ] }
      redirect /dev/null { set OUT_CASE_VALUE [ get_attribute [ get_pins ${OUTPUT_PIN} ] case_value ]}
      if  { ( [lsearch ${REF_NAME} "*INV*"] > -1 ) || ( [lsearch ${REF_NAME} "*BUF*"] > -1 ) } {
          FIND_MPI ${OUTPUT_PIN}
      } else {
          if { ($OUT_CASE_VALUE == 0) || ($OUT_CASE_VALUE == 1) } {
             if { [string first HT_MPI [get_object_name ${OUTPUT_PIN}]] > -1 } {
                set ::HT_MPI_WITH_CASE [add_to_collection ${OUTPUT_PIN} ${::HT_MPI_WITH_CASE}]
		set_user_attribute -q ${OUTPUT_PIN} ACBIST_WARNING "\[Info(1)\]"
             } else {
                set ::OTHER_PIN_WITH_CASE [add_to_collection ${OUTPUT_PIN} ${::OTHER_PIN_WITH_CASE}]
		set_user_attribute -q ${OUTPUT_PIN} ACBIST_WARNING "\[Warning\]"
             } 
          } else {
             if { [string first HT_MPI [get_object_name ${OUTPUT_PIN}]] > -1 } {
                set ::HT_MPI_wo_CASE [add_to_collection ${OUTPUT_PIN} ${::HT_MPI_wo_CASE}]
		set_user_attribute -q ${OUTPUT_PIN} ACBIST_WARNING "\[Error\]"
             } else {
                set ::OTHER_PIN_wo_CASE [add_to_collection ${OUTPUT_PIN} ${::OTHER_PIN_wo_CASE}]
		set_user_attribute -q ${OUTPUT_PIN} ACBIST_WARNING "\[Info(2)\]"
             }
          }
      }
  }
}


#usage: EXTRACT_OUTPIN_WITH_CASE
#       You must run this in not integrated-DFT but LBIST-AC mode.
proc SET_CASE_OF_ACSCAN_TO_FALSE {} {
	#extract all tied outpins
	redirect /dev/null {
		set tied_pins [filter_collection [get_pins * -hier -filter "pin_direction==out"] "case_value==0 or case_value==1"]
	}
	#print
	echo "set MPI_PIN_LIST2 {"
	foreach_in_collection var $tied_pins {
		echo [get_object $var]
	}
	echo "}"
	echo "set_false_path -through \[get_pins \$MPI_PIN_LIST2 \] -to \[get_clocks { LB_*_AC* }\]"
}

### GET_FALSE_MPI_PIN.tcl
### v0r0   2009.09.02  new
### written by K.Kojima/LSI Design Dept./Renesas Technology Corp.
###
### Syntax: GET_FALSE_MPI_PIN -output file_name [-debug] patterns
###          *Patterns={pin_list or port_list or net_list}
###
### Example: pt_shell> source GET_FALSE_MPI_PIN.tcl
###          pt_shell> GET_FALSE_MPI_PIN [get_nets Z997ACBIST1001] -output LOG/false_mpi_pin.list
###          pt_shell> source -echo LOG/false_mpi_pin.list
###          pt_shell> set_false_path -through $MPI_FALSE_LIST -to [get_clocks *_AC*]
###
### Notice: In this script it is processed with Renesas library naming rule.
###         If applying for other technology, don't use this script as is. 
###


proc GET_FALSE_MPI_PIN { args } {
  #initialize
  set MPI_FALSE_LIST ""

  # decode argument
  parse_proc_arguments -args $args results
  set target $results(patterns)
  set ofile      [info exists results(-output) ]
  set debug      [info exists results(-debug) ]
  if {$debug==1} { echo ">>> Start from $target" }

  #existence check
  redirect /dev/null { set exist_test1 [get_pins  $target]}
  redirect /dev/null { set exist_test2 [get_ports $target]}
  redirect /dev/null { set exist_test3 [get_nets  $target]}
  if {$exist_test1=="" && $exist_test2=="" && $exist_test3==""} {
    echo "<<< Error >>> $target is not existing!"
    return -code error
  }

  #open output file
  if { $ofile==1 } {
     set iop_out [open $results(-output) w]
  } else {
    set iop_out stdout
  }

  #when fanout=0, skip
  if {[sizeof_collection [filter_collection [all_fanout -from $target -flat -level 1 -trace_arcs enabled] "pin_direction==in"]]<1} { return -code break }

  #collection cells
  set lev1_pin_list [filter_collection [all_fanout -from $target -flat -trace_arcs enabled] "pin_direction==in"]

  #main
  foreach_in_collection pin $lev1_pin_list {
    #get info
    set arrival_pin_name [get_attribute $pin lib_pin_name]
    set inst [get_cells -of $pin]
    set lib_cell_name [get_attribute $inst ref_name]
    set lev1_out_pin [get_pins -of $inst -filter "pin_direction==out"]
    set in_case_val [get_attribute -q [get_pins $pin] case_value]
    set out_case_val [get_attribute -q [get_pins $lev1_out_pin] case_value]

    #for debug
    if {$debug==1} {
      echo "**************"
      echo "Arrival Pin Name == [get_object_name $pin]"
      echo "Cell Name        == $lib_cell_name"
      #<>if {[get_object $inst]=="PVBG2/BBGMTOP/BBGMSAIC_pvbg2/HT_MPI_AND_saic_pvbg2_saic_div32_inst_div32_wrapper_inst_div32_BGH12CLK_r_REG123_S1_QB_319"} { echo "KKKKKKKK" };#only for G4-ES2
    }

    #skip the sequential cells
    if {[get_attribute $inst is_combinational]!="true"} { continue }

    #skip when the case value is not propagated to the arrival pin
    if {$in_case_val==""} { continue }

    #when out pin is open without net, skip
    if {[get_nets -q -of $lev1_out_pin]==""} {
      if {$debug==1} {
        echo "--- Info --- Skipped processing because next target net is not connected to any pins."
        echo "             The driven pin is [get_object $lev1_out_pin]."
      }
      continue
    }

    #when out pin is tied to 0 or 1, add to false list and call proc recursively
    if {$out_case_val==0 || $out_case_val==1} {
      #if not buf/inv, add to false list
      if {[regexp "(BUF|INV)" $lib_cell_name]} {
        #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST $lev1_out_pin -unique]
        puts $iop_out "[get_object $lev1_out_pin]"
      }
      #go to next stage
      #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [GET_FALSE_MPI_PIN [get_nets -q -of $lev1_out_pin]] -unique]
    } else {
    #when out pin is NOT tied, add both tied and disabled input pins to false list
      #(1)add tied pin to false list
      #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins $pin] -unique]
      puts $iop_out [get_object [get_pins $pin]]

      #(2)add disabled pins of complex gate to false list
      #MUX2, MUXI2
      if {[regexp "(MUX2|MUXI2)" $lib_cell_name] && $arrival_pin_name=="S0"} {
        if {$in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==D1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==D1"]]
        } elseif {$in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==D0"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==D0"]]
        }
      #MUX3, MUX4, MUXI3, MUXI4, ADDF, ADDH, XOR3, XNOR3
        #skip these cells because there are no disabled pins in this case.
      #AN211, AN211Z*, AN21
      #AO211, AO21, AO21RZ*, AO21Z*
      #OA2BB11, OA2BB11Z*
      #ON2BB11, ON2BB11Z*
      } elseif {[regexp "(AN21|AO21|OA2BB11|ON2BB11)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
        }
      #AN22BB, AN22BBZ*
      #AO22BB, AO22BBZ*
      } elseif {[regexp "(AN22BB|AO22BB)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
        } elseif {($arrival_pin_name=="B0" || $arrival_pin_name=="B1") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B1"]]
        }
      #AN22BB, AN22BBZ*, AN22, AN22Z*
      #AO22BB, AO22BBZ*, AO22, AO22Z*
      } elseif {[regexp "(AN22|AO22)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
        } elseif {($arrival_pin_name=="B0" || $arrival_pin_name=="B1") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B1"]]
        }
      #AN2BB11, AN2BB11Z*
      #AO2BB11, AO2BB11Z*
      #OA211, OA211Z*, OA21RZ*, OA21, OA21Z*
      #ON211, ON211Z*, ON21, ON21Z*
      } elseif {[regexp "(AN2BB11|AO2BB11|OA21|ON21)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
        }
      #AN2BB1V, AN2BB1VZ*
      #AO2BB1V, AO2BB1VZ*
      } elseif {[regexp "(AN2BB1V|AO2BB1V)" $lib_cell_name]} {
        if {($arrival_pin_name=="B0" || $arrival_pin_name=="B1") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B1"]]
        }
      #OA2BB1V, OA2BB1VZ*
      #ON2BB1V, ON2BB1VZ*
      } elseif {[regexp "(OA2BB1V|ON2BB1V)" $lib_cell_name]} {
        if {($arrival_pin_name=="B0" || $arrival_pin_name=="B1") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B1"]]
        }
      #AN31, AN31Z*
      #AO31, AO31Z*
      } elseif {[regexp "(AN31|AO31)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1" || $arrival_pin_name=="A2") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A2"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A2"]]
        }
      #OA31, OA31Z*
      #ON31, ON31Z*
      } elseif {[regexp "(OA31|ON31)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1" || $arrival_pin_name=="A2") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A2"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A2"]]
        }
      #OA22BB, OA22BBZ*
      #ON22BB, ON22BBZ*
      } elseif {[regexp "(OA22BB|ON22BB)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
        } elseif {($arrival_pin_name=="B0" || $arrival_pin_name=="B1") && $in_case_val==0} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B1"]]
        }
      #OA22BB, OA22BBZ*, OA22, OA22Z*
      #ON22BB, ON22BBZ*, ON22, ON22Z*
      } elseif {[regexp "(OA22|ON22)" $lib_cell_name]} {
        if {($arrival_pin_name=="A0" || $arrival_pin_name=="A1") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==A1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==A1"]]
        } elseif {($arrival_pin_name=="B0" || $arrival_pin_name=="B1") && $in_case_val==1} {
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B0"] -unique]
          #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of $inst -filter "lib_pin_name==B1"] -unique]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B0"]]
          puts $iop_out [get_object [get_pins -of $inst -filter "lib_pin_name==B1"]]
        }
      }
    }
  }

  #add target itself to false list
  if {$exist_test1!="" && $exist_test2!=""} {
    #pin or port
    #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST $target -unique]
    puts $iop_out [get_object [get_pins -of [get_nets $target] -filter "pin_direction==out"]]
  } else {
    #net
    #<>set MPI_FALSE_LIST [add_to_collection $MPI_FALSE_LIST [get_pins -of [get_nets $target] -filter "pin_direction==out"] -unique]
    puts $iop_out [get_object [get_pins -of [get_nets $target] -filter "pin_direction==out"]]
  }

  #output
  if { $debug==1 } { echo ">>> Now outputing..."; date }
  if { $ofile==1 } {
  #<>  foreach_in_collection pp $MPI_FALSE_LIST { puts $iop_out [get_object $pp] }
    close $iop_out
  }

  #sort
  if { $ofile==1 } {
    sh sort -u $results(-output) > ${results(-output)}.sort_uniq 
    echo "set MPI_FALSE_LIST \{" > ${results(-output)}.sort_uniq_list
    sh cat ${results(-output)}.sort_uniq >> ${results(-output)}.sort_uniq_list
    echo "\}" >> ${results(-output)}.sort_uniq_list
    echo "set_false_path -through \$MPI_FALSE_LIST -to \[get_clocks \{ LB_*_AC* \}\]" >> ${results(-output)}.sort_uniq_list
    sh rm -f $results(-output) ${results(-output)}.sort_uniq
    sh mv ${results(-output)}.sort_uniq_list $results(-output)
  }

  #<>return $MPI_FALSE_LIST
  return
}

define_proc_attributes GET_FALSE_MPI_PIN \
   -info "collect all pins that are possible to set as false_path with AC clocks in integrated DFT mode.\
           1)trace from specified point \
           2)pick up output pins with case value and disabled input pins without case value" \
   -define_args {
      {-output  "indicate output file name." "file_name" string  optional}
      {-debug   "indicate debug mode."       ""          boolean optional}
      {patterns "specify patterns."          "patterns"  string  required}
   }
#eof

proc list_or { args } {
	set return_value ""
	foreach arg $args {
		set return_value [concat $return_value $arg]
	}
	return [lsort -uniq $return_value]
}

proc and { {list_A} {list_B} } {
	set and_list ""
	if {[llength $list_A] > [llength $list_B]} {
		set list_C $list_A
		set list_A $list_B
		set list_B $list_C
		unset list_C
	}
	foreach tmpA $list_A {
		if {[lsearch $list_B $tmpA] != -1} {
			lappend and_list $tmpA
		}
	}
	return $and_list
}

proc list_and { args } {
	set num 0
	foreach arg $args {
		if {$num == 0} {
			set return_value $arg
			incr num; continue
		} else {
			set return_value [and $return_value $arg]
		}
		incr num
	}
	return $return_value
}

proc REMOVE_HOLD_BUF { {TIMING_REPORT} } {
	puts ""
	if {$TIMING_REPORT == ""} {
		puts "* Error: 'REMOVE_HOLD_BUF' must need timing_report."
		puts "  Usage:  REMOVE_HOLD_BUF <timing_report>"
		puts ""
		return 0
	}
	puts "* Start 'REMOVE_HOLD_BUF'"
	puts "* Making list file from timing_report '$TIMING_REPORT'"
	sh grep "hold_min" $TIMING_REPORT | grep -v " (net)" | awk '{print \$1}' | sort | uniq > list.removeHold
	set LIST [READ_LISTFILE ./list.removeHold]
	set TARGET [get_cells -of [get_pins -q $LIST]]
	set num [sizeof_collection $TARGET]
	if {$num == 0} {
		puts "* There is no-target cell in this report."
		puts ""
		return
	}

	puts "* Setting Zero delay to '$num' target cells now..."
	SET_DELAY_ZERO [COL2LIST $TARGET]

	puts "* Redirecting target cells to 'release.removed_hold_buffers' now."
	foreach tmp [COL2LIST $TARGET] {
		echo "$tmp" >> release.removed_hold_buffers
	}
	puts "* Finished 'REMOVE_HOLD_BUF'"
	puts ""
}

#puts "MAKING_ECO_FG_LIB <POWER_LIST>"
proc MAKING_ECO_FG_LIB {POWER_LIST} {
	set ofid [open ECO_FG_LIB.dcs w]
	puts "ECO from MAKING_ECO_FG_LIB proc include clock cell"
	puts "Please ask BE team to remove clock cell in ECO_FG_LIB.dcs"
	set TFML5 [get_lib_cell CLN40ATFM5_Pss_V1p04_T125/*]
	append_to_collection TFML5 [get_lib_cell CLN40ATFL5_Pss_V1p04_T125/*]

	foreach_in_collection LIB $TFML5 {
		set LIB_NAME [get_attribute [get_lib_cell $LIB] full_name]
		set REF_LIB_TFML5 [lindex [split $LIB_NAME /] 1]
		regsub TFM5 $REF_LIB_TFML5 TM5 REF_LIB_TML5_tmp
		regsub TFL5 $REF_LIB_TML5_tmp TL5 REF_LIB_TML5
		puts "$REF_LIB_TML5"
		set CELL_TML5_LIST [get_cell -h * -filter "ref_name == $REF_LIB_TML5"]
		if {$CELL_TML5_LIST != ""} {
			foreach_in_collection CELL_TML5 $CELL_TML5_LIST {
				set CELL_NAME [get_attribute [get_cell $CELL_TML5] full_name]
				set FLAG [regexp_list $POWER_LIST $CELL_NAME ] 
				if {$FLAG == "1"} {
					puts $ofid "change_link $CELL_NAME $LIB_NAME"
				}
			}
		}
	}
	close $ofid
}

proc GET_LIST_NET { {REPORT_FILE} {OUT_FILE} } {
    set FILE_EXT [file extension $REPORT_FILE]
    if       {$FILE_EXT == ".gz"} {
        set fid [open "|gzip  -dc $REPORT_FILE" r]
    } elseif {$FILE_EXT == ".bz2"} {
        set fid [open "|bzip2 -dc $REPORT_FILE" r]
    } else {
        set fid [open $REPORT_FILE r]
        set FILE_EXT "NORMAL"
    }
    puts "* Information : Open file '${REPORT_FILE}' as format '${FILE_EXT}'"
    while {[gets $fid str]>=0} {
        if {[regexp "\\\(net\\\)" $str]} { lappend LIST_NET [lindex $str 0]}
    }
    close $fid

    puts "* Information : proceeding sort & uniq all nets wait for a while..."
    set OUT_fid [open "$OUT_FILE" w]
    set net [lsort -dictionary -unique $LIST_NET]
    puts $OUT_fid [join $net \n]
    close $OUT_fid
}

proc GET_AGGRESSORS { {LIST_NET} {OUT_FILE} } {
    puts "* Information : Reading file '${LIST_NET}'..."
    set fid [open ${LIST_NET} r]
    while {[gets $fid str]>=0} {
        lappend list_net $str
    }
    close $fid

    # << Get effective_aggressors information >>
    puts "* Information : Collect 'number_of_effective_aggressors' attribute..."
    redirect /dev/null {set checknet [get_nets $list_net]}
    set OUT_fid [open "$OUT_FILE" w]
    foreach_in_collection tmp $checknet {
        puts $OUT_fid "[get_object_name $tmp],[get_attribute $tmp number_of_effective_aggressors]"

        if {! [info exists ::BUS_CONSIDER]} {continue}
        set AGGN [get_attribute [get_nets -q $tmp] effective_aggressors]
        if {[llength $AGGN] > 0} {
            foreach AGGname $AGGN {
                if {[regsub {([A-Za-z0-9_\/]*)([\[_])([0-9]*)([_\]])(.*)} $AGGname {\1} AGGbus] > 0} {
                    puts $OUT_fid "#    $AGGbus"
                }
            }
        }
    }
    close $OUT_fid
}

proc GET_NET_TIMING { {TARGET_NET ""} {ENABLE_FILTER "NO"} {LIMIT_RATIO 1.0} {TYPE "ratio"}} {
    if {$TARGET_NET == "-h" || $TARGET_NET == ""} {
        puts ""
        puts "Usage: get_net_timing \"net-name\" <ENABLE_FILTER> <LIMIT_RATIO> <TYPE>"
        puts "       Option: <ENABLE_FILTER> : NO(default), YES(skip CAP < 0.05 && RES < 0.5)"
        puts "               <LIMIT_RATIO>   : 1.0(default), skip(RATIO < LIMIT_RATIO)"
        puts "               <TYPE>          : sort order. ratio(default), freq"
        puts ""
        puts "Output Format:"
        puts "       Ratio Slack (Spec) Capacitance Resistance Netname"
        puts ""
        return
    }
    set NET [get_nets $TARGET_NET]
    if {[sizeof_collection $NET] == 0} {
        puts [format "%5s %5s %5s %s" "-" "-" "-" $TARGET_NET]
        return 0
    }
    set CAP [get_attribute $NET wire_capacitance_max]
    set RES [get_attribute $NET net_resistance_max]
    if {$CAP < 0.05 && $RES < 0.5 && $ENABLE_FILTER == "YES"} {return}

    set REP [get_timing_path -unique_pins -thr $NET]
    if {[sizeof_collection $REP] == 0} {
        #puts "* Information : There is nothing timing-path to show."
        #puts "                Please check the situation of path-group by command 'get_path_group'."
        puts [format "%5.3f %5.3f %6.5f %6.5f %s" 0.00 0.00 $CAP $RES $TARGET_NET]
        return 0
    }
    set dispSPEC 99999999
    set dispRATIO 99999999
    foreach_in_collection rep $REP {
        # << information >>
        if {[sizeof_collection [get_attribute -quiet $rep endpoint_clock]] == 0 \
            || [get_attribute -quiet $rep startpoint_clock_open_edge_value] == ""} {
            puts [format "%5.3f %5.3f %6.5f %6.5f %s" 0.00 0.00 $CAP $RES $TARGET_NET]
            continue
        }
        set IS_ST_LATCH [get_attribute $rep startpoint_is_level_sensitive]
        set IS_ED_LATCH [get_attribute $rep endpoint_is_level_sensitive]
        set SLACK       [get_attribute $rep slack]
        set CLK_ST      [get_object_name [get_attribute $rep startpoint_clock]]
        set CLK_ED      [get_object_name [get_attribute $rep endpoint_clock]]
        set GROUP       [get_attribute [get_attribute $rep path_group] full_name]
        set PERI_ST     [get_attribute $rep startpoint_clock_open_edge_value]
        set PERI_ED     [get_attribute $rep endpoint_clock_close_edge_value]
        set SPEC        [expr $PERI_ED - $PERI_ST]
        set A_ARRIVAL   [expr $PERI_ED - $PERI_ST -$SLACK]
        unset -nocomplain RATIO

        # Case latch time borrow or lent
        set TIME_BORROW [get_attribute $rep time_borrowed_from_endpoint]
        set TIME_LENT   [get_attribute $rep time_lent_to_startpoint]
        if {$SPEC == 0} {
            set SPEC $PERI_ED
            if {$SLACK >= 0} {
                set RATIO 1
            } else {
                if {$PERI_ED == 0} {
                    set RATIO 1
                    set SPEC  1
                } else {
                    set RATIO [expr ($SLACK + $PERI_ED) / $PERI_ED]
                }
            }
        } else {
            set RATIO      [expr $A_ARRIVAL / $SPEC]
        }
        #puts "$CLK_ST->$CLK_ED : $RATIO ($SLACK)"

        #puts "# [format "%5.3f %5.3f (%5.3f) %6.5f %6.5f %s" $RATIO $SLACK $SPEC $CAP $RES $TARGET_NET]"
        if {($dispSPEC > $SPEC && $TYPE == "freq") || ($dispRATIO > $RATIO && $TYPE == "ratio") } {
            set dispRATIO $RATIO
            set dispSLACK $SLACK
            set dispCAP   $CAP
            set dispRES   $RES
            set dispSPEC  $SPEC
        } else {
        }
    }
    #set CAP [get_attribute $NET wire_capacitance_max]
    #set RES [get_attribute $NET net_resistance_max]
	
    # DISPLAY
    if {[info exists dispRATIO] && [info exists dispSLACK] && $dispRATIO > $LIMIT_RATIO} {
        puts [format "%5.3f %5.3f (%5.3f) %6.5f %6.5f %s" $dispRATIO $dispSLACK $dispSPEC $dispCAP $dispRES $TARGET_NET]
    }
}

proc GET_NET_TIMING_FROM_LIST {{LIST} {ENABLE_FILTER "NO"} {LIMIT_RATIO 1.0} {TYPE "ratio"}} {
    set LIST_NET [READ_LISTFILE $LIST]
    foreach net $LIST_NET {
        GET_NET_TIMING $net $ENABLE_FILTER $LIMIT_RATIO $TYPE
    }
}

proc CHECK_LS_TYPE {} {
    # << Collect LevelShifter Cell instances >>
    set LS_CELLS [get_cells -h * -filter ref_name=~"ZBDDM*"]
    set LS_PIN_OUT [get_pins -of $LS_CELLS -filter pin_direction=="out"]
	
    # << Check >>
    foreach_in_collection ls_pin $LS_PIN_OUT {
        set NAME_LS  [get_object_name $ls_pin]
        set NAME_REF [get_attribute [get_cells -of $ls_pin] ref_name]
        redirect /dev/null {set CLK_NAME [get_attribute $ls_pin clocks]}
        if {[sizeof_collection $CLK_NAME] > 0} {
            set JUDGE CLK
            set NAME_CLK {}
            foreach_in_collection clk $CLK_NAME {
                set CLK  [get_object_name $clk]
                set FREQ "[expr round(1/ [get_attribute [get_clocks $CLK] period] * 1000)]MHz"
                lappend NAME_CLK ${CLK}($FREQ)
            }
            set num 0
            if {[llength $NAME_CLK] > 1} {
                set DISP_CLK {}
                foreach tmp $NAME_CLK {
                    if {$num == 0} {
                        set DISP_CLK $tmp
                        incr num
                        continue
                    }
                    set DISP_CLK "${DISP_CLK},${tmp}"
                    incr num
                }
                set NAME_CLK $DISP_CLK
            }
        } else {
            set JUDGE DATA
            set NAME_CLK "-"
        }
        puts [format "%5s %8s %10s %s" $JUDGE $NAME_CLK $NAME_REF $NAME_LS]
    }
}

proc GET_UP_INST { { INST } {CUT 2} } {
	set tmp [split $INST "/"]
	set max [llength $tmp]
	set num 0
	set return_value ""
	foreach cat $tmp {
		set return_value "${return_value}$cat"
		if {$num == [expr $max - $CUT -1]} {break}
		set return_value "${return_value}/"
		incr num
	}
	return $return_value
}

proc mkMETA_ECO_T28 { {LIST_FILE} {VTH "LVTH"} {TYPE "SP"} } {
    puts {}
    puts "########################################"
    puts "Constraint: $LIST_FILE"
    puts "VTH       : $VTH"
    puts "TYPE      : $TYPE"
    puts "########################################"
    switch $VTH {
        ULVTH {
            set CHK_VTH "^T\[D\]?UL"
        }
        LVTH {
            set CHK_VTH "^T\[D\]?L|^T\[D\]?UL"
        }
        SVTH {
            set CHK_VTH "^T\[D\]?S|^T\[D\]?L|^T\[D\]?UL"
        }
        HVTH {
            set CHK_VTH "^T\[D\]?H|^T\[D\]?S|^T\[D\]?L|^T\[D\]?UL"
        }
        UHVTH {
            set CHK_VTH "^T\[D\]?UH|^T\[D\]?H|^T\[D\]?S|^T\[D\]?L|^T\[D\]?UL"
        }
        default {
            puts "# Error : you must give 'VTH' key."
            puts {
                VTH  : [ ULVTH LVTH SVTH MVTH HVTH UHVTH ]
            }
            return 0
        }
    }

    #<<TYPE>>
    switch $TYPE {
        SP {
            set KEY "ASN"
        }
        NRM {
            set KEY "normal"
        }
        default {
            puts "# Error : you must give 'TYPE' key."
            puts {
                TYPE : [ SP NRM ]
            }
            return 0
        }
    }

    set numError 0
    set numOK    0
    set numNG    0
    set numTotal 0

    set fid [open $LIST_FILE]
    set fid_dcs [open ./COMMAND.META.${VTH}.${TYPE}.dcs "w"]
    set fid_tcl [open ./COMMAND.META.${VTH}.${TYPE}.tcl "w"]
    set fid_cmd [open ./COMMAND.META.${VTH}.${TYPE}.cmd "w"]

    while { [gets $fid str] >= 0 } {
        redirect /dev/null {current_instance}
        if {$str == ""} { continue }
        if {[regexp {^#} $str]} { continue }
        incr numTotal
        if {[regexp {CAN'T FIND instance} $str]} {
            continue
        }
        set inst [lindex $str 0]

        redirect /dev/null {set INST [get_cells $inst]}
        if {$INST == ""} {
            puts "# Error : '$inst' mismatch"
            puts $fid_dcs "# Error : '$inst' mismatch"
            puts $fid_tcl "# Error : '$inst' mismatch"
            puts $fid_cmd "+C Error : '$inst' mismatch"
            incr numError
            continue
            #return 0
        }
        set REF  [get_attribute $INST ref_name]

        set JUDGE OK
        #<<VTH>>
        if {[regexp $CHK_VTH $REF]} {
            set TGT $REF
        } else {
            switch $VTH {
                ULVTH {
                    regsub "^TUH" $REF {TUL} TGT
                    regsub "^TH"  $TGT {TUL} TGT
                    regsub "^TS"  $TGT {TUL} TGT
regsub "^TL"  $TGT {TUL} TGT
                }
                LVTH {
                    regsub "^TUH" $REF {TL} TGT
                    regsub "^TH"  $TGT {TL} TGT
                    regsub "^TS"  $TGT {TL} TGT
                }
                SVTH {
                    regsub "^TUH" $REF {TS} TGT
                    regsub "^TH"  $TGT {TS} TGT
                }
                HVTH {
                    regsub "^TUH" $REF {TH} TGT
                }
                default {
                    puts [format "# NG?? : %-25s %s" $REF $inst]
                }
            }
            set JUDGE NG
        }

        #<<TYPE>>
        set SPECIAL NO
        if {$TYPE == "SP" && $SPECIAL == "NO"} {
            #<<special care>> SPECIAL(YES): redundant terminal will be tied low.
            switch -regexp $TGT {
                QDFFQBRZC1X {
                    regsub "QDFFQBRZC1X.*" $TGT QKDFFAQBRZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QDFFQBSBZC1X {
                    regsub "QDFFQBSBZC1X.*" $TGT QKDFFAQBSBZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QDFFQBRZC1X {
                    regsub "QDFFQBRZC1X.*" $TGT QKDFFAQBRZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QDFFQBSBZC1X {
                    regsub "QDFFQBSBZC1X.*" $TGT QKDFFAQBSBZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QDFFQBRZC1X {
                    regsub "QDFFQBRZC1X.*" $TGT QKDFFAQBRZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QDFFQBSBZC1X {
                    regsub "QDFFQBSBZC1X.*" $TGT QKDFFAQBSBZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QDFFQBX {
                    regsub "QDFFQBX.*" $TGT QDFFQBZASNX10 TGT
                    set SPECIAL NO; set JUDGE NG
                }
                QDFFQRX {
                    regsub "QDFFQRX.*" $TGT QKDFFAQRZC1ASNX10 TGT
                    set SPECIAL YES; set JUDGE NG
                }
                QKDFFAQX {
                    regsub "QKDFFAQX.*" $TGT QKDFFAQZC1ASNX10 TGT
                    set SPECIAL NO; set JUDGE NG
                }
                default {
                    if {[regexp $KEY $REF]} {
                        #puts "OK"
                    } else {
                        #regsub "Z.*C1X" $TGT {ZC1ASNX} TGT
                        regsub "X5" $TGT {X10} TGT
                        regsub "X8" $TGT {X10} TGT
                        regsub "QDFFQBZC1X"   $TGT {QDFFQBZASNX} TGT
                        regsub "QDFFQX"       $TGT {QDFFQZASNX}  TGT
                        regsub "Z.*C1X"       $TGT {ZC1ASNX}     TGT
                        regsub "AQRX"         $TGT {AQRZC1ASNX}  TGT
                        regsub "AQBX"         $TGT {AQBZC1ASNX}  TGT
                        regsub "AQSBX"        $TGT {AQSBZC1ASNX} TGT
                        regsub "AQX"          $TGT {AQZC1ASNX}   TGT
                        regsub "AAQZ.*C1X"    $TGT {AQZC1ASNX}   TGT
                        regsub "Z.*C1.*HOLDX" $TGT {ZC1ASNX}     TGT
                        set JUDGE NG
                    }
                    set SPECIAL NO
                }
            }
        }

        if {$JUDGE == "NG"} {
            puts [format "# NG : %-25s %s" $REF $inst]
            incr numNG
            if {$SPECIAL == "YES"} {
                puts $fid_dcs [format "change_link %s %s -force ;# %s" $inst [get_object_name [get_lib_cells */$TGT]] $REF] 
                #<<get target hirrarchy>>
                set LIST   [split $inst /]
                set LENGTH [llength $LIST]
                set CINST  [join [lrange $LIST 0 end-1] / ]
                set LINST  [lindex $LIST end ]
                set CDSGN  [get_attribute $CINST ref_name]

                # Logic0/**logic_0** ==> *Logic0* ==> target-pin
                puts $fid_dcs [format "current_instance %s " $CINST ]
                puts $fid_dcs "create_cell Logic0 -logic 0"
                puts $fid_dcs [format "connect_net \[get_nets -of \[get_pins {Logic0/**logic_0**}\]\] \[get_pins %s/SIN\]" $LINST]
                puts $fid_dcs [format "connect_net \[get_nets -of \[get_pins {Logic0/**logic_0**}\]\] \[get_pins %s/SMC\]" $LINST]
                puts $fid_dcs "current_instance"
            } else {
                puts $fid_dcs [format "change_link %s %s ;# %s" $inst [get_object_name [get_lib_cells */$TGT]] $REF] 
                puts $fid_tcl [format "size_cell %s %s ;# %s" $inst $TGT $REF]
            }

            #puts $fid_tcl [format "size_cell %s %s ;# %s" $inst $TGT $REF]
            #puts $fid_cmd [format "+R %s %s %s" $REF $TGT $inst]
        } else {
            puts [format "  OK : %-25s %s" $REF $inst]
            incr numOK
        }
        unset REF
        unset TGT
    }
    close $fid
    close $fid_dcs
    close $fid_tcl
    close $fid_cmd
    puts ""
    puts "----------------------------------"
    puts [format " %6s %6s %6s %6s" OK NG Error Total]
    puts [format " %6d %6d %6d %6d" $numOK $numNG $numError $numTotal]
    puts "----------------------------------"
    puts "Thank you"
    puts ""
}

proc check_aocv_coeff [] {
    redirect aocv_cell_list { report_aocvm -coefficient }
    redirect lib_cell_list {
        foreach_in_collection libs1 [ get_libs ] {
            set libs2 [ get_object_name $libs1 ]
            foreach_in_collection cells1 [ get_lib_cells $libs2/* ] {
                set cells2 [ get_object_name $cells1 ]
                echo "$cells2"
            }
        }
    }
    sh ./bin/check_aocv_coeff.scr lib_cell_list aocv_cell_list > No_set_aocv_cell_list
    sh /bin/rm lib_cell_list aocv_cell_list
}

proc SET_TARGET_LIBNAME_OF_REF { {TARGET_LIB ""} } {
    set LIB_LIST [COL2LIST [get_libs ${TARGET_LIB}] ]
    foreach lib $LIB_LIST {
        foreach libcell [COL2LIST [get_lib_cells $lib/*]] {
            set REF [lindex [split $libcell "/"] 1]
            eval "set ::$REF $lib"
        }
    }
}

proc get_slack_hold { {MAX 1} {NWORST 1} } {
	puts {}
	puts "* Information : Getting timing information... Please wait for a while.."
	set REP [get_timing_path -slack_less 0.1 -max $MAX -delay min]
	if {[sizeof_collection $REP] == 0} {
		puts "* Information : There is nothing timing-path to show."
		puts "                Please check the situation of path-group by command 'get_path_group'."
		return 0
	}
	puts "* Information : Analyzing timing ... Please wait for a while.."
	set TNS 0.0
	foreach_in_collection rep $REP {
		# << information >>
		set SLACK       [get_attribute $rep slack]
		set CLK_ST      [get_object_name [get_attribute $rep startpoint_clock]]
		set CLK_ED      [get_object_name [get_attribute $rep endpoint_clock]]
		set GROUP       [get_attribute   [get_attribute $rep path_group] full_name]

		if {$SLACK < 0} {
			set N_SLACK $SLACK
		} else {
			set N_SLACK 0.0
		}
		# << making databae >>
		set DOMAIN ${CLK_ST}@${CLK_ED}

		if {[info exists DB_WNS($DOMAIN)]} {
			incr DB_NUM($DOMAIN)
			if {$DB_WNS($DOMAIN) > $SLACK} {
				set DB_WNS($DOMAIN) $SLACK
			}
			set DB_TNS($DOMAIN) [expr $DB_TNS($DOMAIN) + $N_SLACK]
		} else {
			set DB_NUM($DOMAIN) 1
			set DB_WNS($DOMAIN) $SLACK
			set DB_TNS($DOMAIN) $N_SLACK
			lappend list_domain $DOMAIN
		}
		set TNS [expr $TNS + $N_SLACK]
	}
	global MODE
	puts {}
	puts "------------------------------------------------------------------------------------------------"
	puts " << $MODE >>"
	puts "    TNS = [format "%8.1f ns" $TNS]  (nworst/max_path : $NWORST / $MAX)"
	puts "------------------------------------------------------------------------------------------------"
	puts [format "%7s %8s  %5s -from %30s -to %30s" WNS TNS Num StartClock EndClock]
	puts "------------------------------------------------------------------------------------------------"

	# << For convenience >>
	redirect /dev/null {
		#set MUSK [COL2LIST [get_clocks {*ZCLK* *RamStrobe*}]]
		set MUSK [COL2LIST [get_clocks {}]]
		set ABE  [COL2LIST [get_clocks {}]]
		set UNE  [COL2LIST [get_clocks {*ZB3CLK* *DDRCLK* *ZB3D2CLK* *DDRCLK400* *ZB3CLK200* *ZSCLK* *SCLK* }]]
		set NAKA [COL2LIST [get_clocks {*M1CLK* *FSIA_ckgo_sdi_bck* *SPUCLK* *DT0CLK8B* *HPCLK* *ISPBCLK* *CPCLK*}]]
	}
	set result ""
	foreach domain $list_domain {
		set ST [lindex [split $domain "@"] 0]
		set ED [lindex [split $domain "@"] 1]
		if {[lsearch -inline $MUSK $ED] >= 0} {continue}
			set string [format "%7.3f %8.3f %5d -from %30s -to %30s" \
				$DB_WNS($domain) $DB_TNS($domain) $DB_NUM($domain) $ST $ED]

		# << If you want to make a charge clear >>
		#if {[lsearch -inline $ABE  $ED] >= 0} {set string "$string ;Abe"}
		#if {[lsearch -inline $UNE  $ED] >= 0} {set string "$string ;Shitaune"}
		#if {[lsearch -inline $KOJI $ED] >= 0} {set string "$string ;Kojima"}
		#if {[lsearch -inline $NAKA $ED] >= 0} {set string "$string ;Nakagawa"}

		lappend result $string
	}
	foreach tmp [lsort -real -index 0 -increasing $result] {
		puts $tmp
	}
	puts "------------------------------------------------------------------------------------------------"
}

proc GET_ALL_FANOUT_FF { {TRACE_TARGET} } {
	set return_value {}

	set TRACE_TARGET_org $TRACE_TARGET
	set TRACE_TARGET [get_pins -q $TRACE_TARGET]
	if {[sizeof_collection $TRACE_TARGET]==0} {
		set TRACE_TARGET [get_pins -leaf -q -of [get_nets $TRACE_TARGET_org]]
	}
	set INST   [get_cells -q -of $TRACE_TARGET]
	if {[get_attribute $INST is_sequential]=="true"} {
		return $TRACE_TARGET
	}
	set OUTPIN   [get_pins -leaf -of $INST -filter pin_direction=="out"]
	set NEXT_NET [get_nets -q -of $OUTPIN]
	set NEXT_IN  [get_pins -leaf -q -of $NEXT_NET -filter pin_direction=="in"]

	# << Trace Next >>
	foreach_in_collection in_pin $NEXT_IN {
		set return_value [add_to_collection $return_value [GET_ALL_FANOUT_FF $in_pin]]
	}
	return $return_value
}

proc TRACE_COMBI { {TRACE_TARGET "MASKVIT"} } {
        set return_value {}

        set TRACE_TARGET_org $TRACE_TARGET
        set TRACE_TARGET [get_pins -q $TRACE_TARGET]
        if {[sizeof_collection $TRACE_TARGET]==0} {
                set TRACE_TARGET [get_pins -leaf -q -of [get_nets $TRACE_TARGET_org]]
        }
        set INST   [get_cells -q -of $TRACE_TARGET]
        set REF    [get_attribute $INST ref_name]
        if {[regexp "(BUF|INV|UIO)" $REF]!=1} {
                return $TRACE_TARGET
        }
        set OUTPIN   [get_pins -leaf -of $INST -filter pin_direction=="out"]
        set NEXT_NET [get_nets -q -of $OUTPIN]
        set NEXT_IN  [get_pins -leaf -q -of $NEXT_NET -filter pin_direction=="in"]

        # << Trace Next >>
        foreach_in_collection in_pin $NEXT_IN {
                set return_value [add_to_collection $return_value [TRACE_COMBI $in_pin]]
        }
        return [add_to_collection -unique $return_value ""]
}

proc TRACE_COMBI_MULTI { {TRACE_TARGET "MASKVIT"} {SKIPKEY "BUF|INV|UIO"}} {
        set return_value {}

        set TRACE_TARGET_org $TRACE_TARGET
        set TRACE_TARGET [get_pins -q $TRACE_TARGET]
        if {[sizeof_collection $TRACE_TARGET]==0} {
                set TRACE_TARGET [get_pins -leaf -q -of [get_nets $TRACE_TARGET_org]]
        }
        set INST   [get_cells -q -of $TRACE_TARGET]
        set REF    [get_attribute $INST ref_name]
        if {[regexp "($SKIPKEY)" $REF]!=1} {
                return $TRACE_TARGET
        }
        set OUTPIN   [get_pins -leaf -of $INST -filter pin_direction=="out"]
        set NEXT_NET [get_nets -q -of $OUTPIN]
        set NEXT_IN  [get_pins -leaf -q -of $NEXT_NET -filter pin_direction=="in"]

        # << Trace Next >>
        foreach_in_collection in_pin $NEXT_IN {
                set return_value [add_to_collection $return_value [TRACE_COMBI_MULTI $in_pin $SKIPKEY]]
        }
        return [add_to_collection -unique $return_value ""]
}

proc TRACE_COMBI_MULTI_SENGEN { {TRACE_TARGET "MASKVIT"} {SKIPKEY "BUF|INV|UIO|DFFQEMX"}} {
        set return_value {}

        set TRACE_TARGET_org $TRACE_TARGET
        set TRACE_TARGET [get_pins -q $TRACE_TARGET]

#puts "** [get_attribute [get_cells -of $TRACE_TARGET] ref_name] [get_object_name $TRACE_TARGET]"

        if {[sizeof_collection $TRACE_TARGET]==0} {
                set TRACE_TARGET [get_pins -leaf -q -of [get_nets $TRACE_TARGET_org]]
        }
        set INST   [get_cells -q -of $TRACE_TARGET]
        set REF    [get_attribute $INST ref_name]
        if {[regexp "($SKIPKEY)" $REF]!=1} {
                return $TRACE_TARGET
        }
        set OUTPIN   [get_pins -leaf -of $INST -filter pin_direction=="out"]
        set NEXT_NET [get_nets -q -of $OUTPIN]
        set NEXT_IN  [get_pins -leaf -q -of $NEXT_NET -filter pin_direction=="in"]

        # << Trace Next >>
        foreach_in_collection in_pin $NEXT_IN {
                set return_value [add_to_collection $return_value [TRACE_COMBI_MULTI_SENGEN $in_pin $SKIPKEY]]
        }
        return [add_to_collection -unique $return_value ""]
}

proc mkCONST_SENGENCLK_MAIN {{SENGEN}} {
	#set CLK1 [get_attribute -quiet [get_pins -quiet -of [get_cells $SENGEN] -filter is_clock_pin==true] clocks]
	set CLK2 [get_attribute -quiet [get_pins -quiet -of [get_cells -quiet -of [all_fanout -from [get_pins -quiet -of $SENGEN -filter lib_pin_name==Q] -flat -endpoints_only]] -filter is_clock_pin==true] clocks]
	#return  [lsort -uniq [COL2LIST [add_to_collection $CLK1 $CLK2]]]
	return  [lsort -uniq [COL2LIST $CLK2]]
}


proc mkCONST_SENGENCLK {{outFILENAME "./CONST/SENGEN_false_const.ptsc"}} {
	puts "* Information : Making collection of all sengen"
	set ALL_SENGEN [get_cells -h -filter ref_name=~T*DFFQEMX*]
	set NUM_SENGEN [sizeof_collection $ALL_SENGEN]
	puts "* Information : Total '$NUM_SENGEN' sengens are detected."

	set NON_TARGET [list LBTT LBTT_MB LBTC LBTT_DVFS LBTT_DVFS_MB LBTC_DVFS]

	set nu 0
	set fid [open $outFILENAME "a+"]
	puts $fid "# [get_object_name [current_design]]"
	puts $fid "# [pwd]"
	puts $fid "# Start: [date]"

	foreach_in_collection SENGEN $ALL_SENGEN {
		incr nu
		set NAME_SENGEN "[get_object_name $SENGEN]/Q"
		puts [format "%4d %s" $nu $NAME_SENGEN]

		set CLOCKS [mkCONST_SENGENCLK_MAIN $SENGEN]
		set LIST_CLOCK  [REMOVE_FROM_LIST $CLOCKS $NON_TARGET]

		foreach CLOCK $LIST_CLOCK {
		switch -regexp $CLOCK {
		^MB_* {
			if {[llength $CLOCK]==0} {
				puts $fid "### set_false_path -through \[get_pins {$NAME_SENGEN}\] -to \[get_clocks {$CLOCK}\]"
			} else {
				puts $fid "set_false_path -through \[get_pins {$NAME_SENGEN}\] -to \[get_clocks {$CLOCK}\]"
			}
		}
		default {
			if {[llength $CLOCK]==0} {
				puts $fid "### set_false_path -rise_through \[get_pins {$NAME_SENGEN}\] -to \[get_clocks {$CLOCK}\]"
			} else {
				puts $fid "set_false_path -rise_through \[get_pins {$NAME_SENGEN}\] -to \[get_clocks {$CLOCK}\]"
			}
		}
		}
		}
	}
	puts $fid "# End  : [date]"
	close $fid
}

proc mkCONST_SENGORCLK_MAIN {{SENGOR}} {
	set PIN [get_pins -quiet -of $SENGOR -filter lib_pin_name==Y]
	if {[sizeof_collection $PIN]==0} {return}
	set FOUT [all_fanout -from [get_pins -quiet -of $SENGOR -filter lib_pin_name==Y] -flat -endpoints_only]
	if {[sizeof_collection $FOUT]==0} {return}
	set CLK [get_attribute -quiet [get_pins -quiet -of [get_cells -quiet -of $FOUT] -filter is_clock_pin==true] clocks]
	return  [lsort -uniq [COL2LIST $CLK]]
}
proc mkCONST_SENGORCLK {{outFILENAME "./CONST/SENGOR_false_const.ptsc"}} {
	puts "* Information : Making collection of all sengen"
	set ALL_SENGEN [get_cells -h -filter ref_name=~T*DFFQEMX*]
	set NUM_SENGEN [sizeof_collection $ALL_SENGEN]
	puts "* Information : Total '$NUM_SENGEN' sengens are detected."

	set NON_TARGET [list LBTT LBTT_MB LBTC LBTT_DVFS LBTT_DVFS_MB LBTC_DVFS]

	set nu 0
	set fid [open $outFILENAME "a+"]
	puts $fid "# [get_object_name [current_design]]"
	puts $fid "# [pwd]"
	puts $fid "# Start: [date]"

	foreach_in_collection SENGEN $ALL_SENGEN {
		set NAME_SENGEN "[get_object_name $SENGEN]/Q"
		set tmpSENGOR   [get_cells -of [TRACE_COMBI_MULTI_SENGEN [get_pins $NAME_SENGEN]] -filter ref_name=~*OR*]
		foreach_in_collection SENGOR $tmpSENGOR {
			incr nu
			set NAME_SENGOR "[get_object_name $SENGOR]/Y"
			puts [format "%4d %s" $nu $NAME_SENGOR]

			set CLOCKS [mkCONST_SENGORCLK_MAIN $SENGOR]
			set CLOCK  [REMOVE_FROM_LIST $CLOCKS $NON_TARGET]
			if {[llength $CLOCK]==0} {
				puts $fid "### set_false_path -through \[get_pins {$NAME_SENGOR}\] -to \[get_clocks {$CLOCK}\]"
			} else {
				puts $fid "set_false_path -through \[get_pins {$NAME_SENGOR}\] -to \[get_clocks {$CLOCK}\]"
			}
		}
	}
	puts $fid "# End  : [date]"
	close $fid
}


proc CHK_NOCLK {{CLOCK}} {
	if {[llength $CLOCK]==0} {
		return "##No_CLK##"
	} else {
		return  $CLOCK
	}
}
proc CHK_CLKGR {{ST_CLK} {ED_CLK}} {
	if {$ST_CLK==[lsort -uniq [concat $ST_CLK $ED_CLK]]} {
		return "OK"
	} else {
		if {$ED_CLK=="##No_CLK##"} {
			return "OK: no_clock"
		}
		set strings "NG..check source clocks"
		set MASTER_ST_CLK [get_attribute [get_clocks $ST_CLK] master_clock]
		foreach st_clk [COL2LIST $MASTER_ST_CLK] {
			set strings "$strings\n	ST_CLK: $st_clk"
		}

		set MASTER_ED_CLK [get_attribute [get_clocks $ED_CLK] master_clock]
		foreach ed_clk [COL2LIST $MASTER_ED_CLK] {
			set strings "$strings\n	ED_CLK: $ed_clk"
		}

		return "$strings"
	}
}
proc CHECK_SENGENCLK {} {
	puts "* Information : Making collection of all sengen"
	set ALL_SENGEN [get_cells -h -filter ref_name=~T*DFFQEMX*]
	set NUM_SENGEN [sizeof_collection $ALL_SENGEN]
	puts "* Information : Total '$NUM_SENGEN' sengens are detected."

	set NON_TARGET [list LBTT LBTT_MB LBTC LBTT_DVFS LBTT_DVFS_MB LBTC_DVFS]

	set nu 0
	set fid [open "./log.CHECK_SENGENCLK" "a+"]
	puts $fid "# [get_object_name [current_design]]"
	puts $fid "# [pwd]"
	puts $fid "# Start: [date]"

	foreach_in_collection SENGEN $ALL_SENGEN {
		
		puts $fid ""
		incr nu
		set NAME_SENGEN "[get_object_name $SENGEN]/Q"
		
		# SENGEN
		set tmpCLK_SENGEN      [COL2LIST [get_attribute -quiet [get_pins -quiet -of [get_cells $SENGEN] -filter is_clock_pin==true] clocks]]
		set CLK_SENGEN         [REMOVE_FROM_LIST $tmpCLK_SENGEN $NON_TARGET]

		set tmpCLK_SENGEN_LEAF [mkCONST_SENGENCLK_MAIN $SENGEN]
		set CLK_SENGEN_LEAF    [REMOVE_FROM_LIST $tmpCLK_SENGEN_LEAF $NON_TARGET]

		set dispCLK_SENGEN      [CHK_NOCLK $CLK_SENGEN]
		set dispCLK_SENGEN_LEAF [CHK_NOCLK $CLK_SENGEN_LEAF]

		puts $fid [format "* %4d %s" $nu $NAME_SENGEN]
		puts $fid [format " %4s %s" { ST:} $dispCLK_SENGEN]
		puts $fid [format " %4s %s" { ED:} $dispCLK_SENGEN_LEAF]
		puts $fid [format " %s" [CHK_CLKGR $dispCLK_SENGEN $dispCLK_SENGEN_LEAF]]


		# SENGOR
		set tmpSENGOR   [get_cells -of [TRACE_COMBI_MULTI_SENGEN [get_pins $NAME_SENGEN]] -filter ref_name=~*OR*]

		set nuor 0
		set CLK_SENGOR_LEAF {}
		foreach_in_collection SENGOR $tmpSENGOR {
			incr nuor
			set NAME_SENGOR "[get_object_name $SENGOR]/Y"
			puts $fid [format " %4d %s" $nuor $NAME_SENGOR]

			set tmpCLK_SENGOR_LEAF [mkCONST_SENGORCLK_MAIN $SENGOR]
			set CLK_SENGOR_LEAF    [REMOVE_FROM_LIST $tmpCLK_SENGOR_LEAF $NON_TARGET]

			set dispCLK_SENGOR_LEAF [CHK_NOCLK $CLK_SENGOR_LEAF]
			puts $fid [format " %4s %s" { ED:} $dispCLK_SENGOR_LEAF]

			puts $fid [format " %s" [CHK_CLKGR $dispCLK_SENGEN $dispCLK_SENGOR_LEAF]]
		}

	}
	puts $fid "# End  : [date]"
	close $fid
}

proc GET_CLKPIN_wCLK {{CLKPIN} {CLK}} {
	set PIN [get_pins $CLKPIN]
	set return_value {}
	foreach_in_collection pin $PIN {
		set CLKS [filter_collection [get_attribute $PIN clocks] full_name==$CLK]
		if {[sizeof_collection $CLKS]==1} {
			set return_value [add_to_collection $return_value $pin]
		}
	}
	return $return_value
}
proc DEBG_SENG_CLK {{SENGEN} {CLK}} {
	set outSENG   [get_pins $SENGEN]
	set leaf_smcs [all_fanout -from $outSENG -flat -endpoints_only]
	set NON_TARGET [list LBTT LBTT_MB LBTC LBTT_DVFS LBTT_DVFS_MB LBTC_DVFS]

	foreach_in_collection leaf_smc $leaf_smcs {
		set name_smc [get_object_name $leaf_smc]
		set leaf_clk [get_pins -of [get_cells -of $leaf_smc] -filter is_clock_pin==true]
		set LEAF     [COL2LIST [GET_CLKPIN_wCLK $leaf_clk $CLK]]
	
		if {[llength $LEAF]==0} {continue}
		puts "\n* NG-clock:  $CLK (NG-clock)"
		puts "* Check-Pin: $name_smc"
		foreach tmp $LEAF {puts "  $tmp [REMOVE_FROM_LIST [COL2LIST [get_attribute [get_pins $tmp] clocks]] $NON_TARGET]"}
	}

}

