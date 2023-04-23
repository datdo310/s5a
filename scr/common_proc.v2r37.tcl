#############################################
# common_proc.tcl
#
# Version : v2r00 2014/01/10
#     Modified :  Branch from v1r61 for MCU
#         : v2r01 2014/01/24
#         : v2r04 2014/07/17 
#         : v2r05 2014/11/11 CHK_HIGHFREQ_DONTUSE_PATH (adjusted for max_delay)
#         : v2r06 2014/12/02 mkEdtChainMask_2_1stSIN is added
#         : v2r07 2014/12/29 slack_less 0->0.00001(PrimeTime2013.xx Bug)
#         : v2r08 2015/01/17 proc chkClockAsData* are updated.
#         : v2r09 2015/01/23 chkMEM changed target jk1308759_* -> jk*
#         : v2r10 2015/04/24 GET_BIGDELAY_NET is added
#         : v2r11 2015/05/30 CHK_SKEWED_MARGIN is added
#         : v2r13 2015/08/24 bkTrace* was updated
#         : v2r14 2015/09/01 chkClkReconvPin is updated
#         : v2r15 2015/09/21 SKEWED_REP2PATH is added
#                            DELTA_*2REP are added
#         : v2r16 2015/12/01 DELTA_*2REP are changed to clock_expanded
#         : v2r17 2016/01/12 CHK_SKEWED_MARGIN is updated for Bug
#         : v2r18 2016/01/21 GET_CLOCK_CELLS is added to make clock list
#         : v2r19 2016/03/22 CALC_STD_AREA is added to analyze VTH ratio
#         : v2r20 2016/07/01 REPEATER_XTALK_FANOUT/REPEATER_SKEWED_FANOUT are added
#         : v2r21 2016/07/25 chkGCLKPathAll(r4) is supported
#         : v2r22 2016/07/27 CHK_KEEP_DONTTOUCH is supported
#         : v2r23 2016/09/12 get_slack supports max_delay constraints
#         : v2r24 2017/01/06 Update CHK_CLKVT for reducing TAT
#         : v2r25 2017/02/22 Add COMP_VAR proc to compare variables
#         : v2r26 2017/03/09 ADD SET_ASYNC_TRAN for RV28F Transition check
#         : v2r27 2017/04/17 CLKVT support master -> generate line.
#         : v2r28 2017/05/15 SDC Mask Procecure
#         : v2r29 2017/05/25 change MK_HF_CMD (set_load -> set_ideal_network)
#         : v2r30 2017/06/06 change CHECK_VTH/CHECK_PITCH (support RV28F)
#         : v2r31 2017/10/19 CALC_STD_AREA support RV28F
#         : v2r32 2017/12/19 MERGE_SDCMASK_PTSC changed for Naming rule
#         : v2r33 2018/01/30 REPEATER_TRAN_FANOUT is added
#         : v2r34 2018/03/06 Add UPSIZE_TRAN, Update: REPEATER_TRAN_FANOUT
#         : v2r35 2018/03/09 chkClockAsDataAll support create_clocks too
#         : v2r36 2018/03/20 MERGE_SDCMASK_PTSC add file name in comment
#         : v2r37 2018/08/09 Add DONTTOUCH_CLOCK/MKDOWNSIZETCL to make downsize
#############################################

#puts "# Define: COL2LIST <collection>"
proc COL2LIST { {COLLECTION} } {
	set RETURN_VALUE {}
	if {[sizeof_collection $COLLECTION] == 0} {return {}}
	foreach_in_collection tmp $COLLECTION {
		#set COL_NAME [get_object_name $tmp]
		#if {[info exists RETURN_VALUE]} {
		#		set RETURN_VALUE [concat $RETURN_VALUE $COL_NAME]
		#} else {
		#		set RETURN_VALUE $COL_NAME
		#}
		lappend RETURN_VALUE [get_object_name $tmp]
	}
	return $RETURN_VALUE
}

if {$synopsys_program_name == "dc_shell"} {
#puts "# Define: CHECK_HIER	#dc_shell version"
proc CHECK_HIER { {LEVEL " "} {FLAG 1} } {
	if {$FLAG=="1"} {echo "# The hierarchy report of design name \"[get_object_name [current_design]]\"."}
	redirect /dev/null {set CELLS [sort_collection [get_cells * -filter "@is_hierarchical==true"] full_name]}
	#if {[sizeof_collection $CELLS]==0} { echo "\n Information: There is no hierarchical module."}
	foreach_in_collection tmp $CELLS {
		set REF_NAME [get_attribute $tmp ref_name]
		set CEL_NAME [get_object_name $tmp]
		echo "${LEVEL}+ $CEL_NAME ( $REF_NAME )"
		
		redirect /dev/null {current_design $REF_NAME}
		set LEVEL "${LEVEL}	"
		CHECK_HIER $LEVEL 0
		regsub {	} $LEVEL {} LEVEL
	}
}

} elseif {$synopsys_program_name == "pt_shell"} {

#puts "# Define: CHECK_HIER	#pt_shell version"
proc CHECK_HIER { {LEVEL " "} {FLAG 1} } {
	if {$FLAG=="1"} {echo "# The hierarchy report of design name \"[get_object_name [current_design]]\" [get_attri [get_design *] area]."}
	#if {$FLAG=="1"} {echo "# The hierarchy report of design name \"[get_object_name [current_design]]\"."}
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

}

#puts "# Define: REPORT_DIRECT_CONNECTED_FF"
proc REPORT_DIRECT_CONNECTED_FF { {CHECK_PIN {*/DATA */SIN} } } {
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
	
		if {[regexp DFF $DRIVE_CELL_REF] || [regexp DLAT $DRIVE_CELL_REF]} {
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

#puts "# Define: REPORT_DIRECT_CONNECTED_FF_SOSI"
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

#puts "# Define: MAKE_MVTH_DICTIONARY"
proc MAKE_MVTH_DICTIONARY {} {
	set TOP_MODULE_NAME [get_object_name [current_design]]
	set ALL_MVTH_CELLS [get_cells * -filter "@ref_name=~TC7*"]
	set REPORT_NAME "$TOP_MODULE_NAME.MVTH.dic"
	
	echo "# MVTH CELL INSTANCE DICTIONARY \"$TOP_MODULE_NAME\"" > $REPORT_NAME
	foreach_in_collection MVTH_CELL $ALL_MVTH_CELLS {
		set MVTH_CELL_NAME [get_object_name $MVTH_CELL]
		set MVTH_REF_NAME  [get_attribute $MVTH_CELL ref_name]
	
		echo "$MVTH_REF_NAME $MVTH_CELL_NAME" >> $REPORT_NAME
	}
}

#puts "# Define: GET_DRIVE_PIN <net_name>"
proc GET_DRIVE_PIN { {NET_NAME} } {
	set RETURN_VALUE [get_pins -leaf -of [get_nets TOP_NET] -filter "@pin_direction==out"]
	return $RETURN_VALUE
}

#puts "# Define: GET_SINK_PIN <net_name>"
proc GET_SINK_PIN { {NET_NAME} } {
	set RETURN_VALUE [get_pins -leaf -of [get_nets TOP_NET] -filter "@pin_direction==in"]
	return $RETURN_VALUE
}


#puts "# Define: GET_NETS {name}"
#puts "#         Please use it, when you acquire the irregular netr-name containing a backslash."
proc GET_NETS { {name} } {
	regsub -all {\\} $name {\\\\\\\\} target_name
	return [get_nets $target_name]
}

#puts "# Define: CHECK_DSPF_ERROR <LIST Variable of net(signal)name>"
proc CHECK_DSPF_ERROR { {TARGET_NET_LIST} } {
#source check_net.list
	foreach tmp $TARGET_NET_LIST {
		set check_string "GET_NETS \{$tmp\}"
		redirect /dev/null {set NET_COLL [eval $check_string]}
		if {[sizeof_collection $NET_COLL]==0} {
			echo "#Error: NOT-FOUND $tmp"
		} else {
			#echo " OK   : $tmp"
			redirect /dev/null {set CHECK_FLOAT [get_pins -leaf -of $NET_COLL -filter "@pin_direction==in"]}
			if {[sizeof_collection $CHECK_FLOAT]==0} {
				echo " Info.: FLOAT     $tmp"
			} else {
				set FOUT [sizeof_collection $CHECK_FLOAT]
				echo " Info.: CONNECT   $tmp ($FOUT)"
			}
		}
	}
}


#puts "# Define: CHECK_CLOCK_GROUP <List or Collection Variable of cell-instance-name>"
#proc CHECK_CLOCK_GROUP { {INST_COLL} } {
#	set tmp_INST_COLL [get_cells $INST_COLL]
#
#	#pin_loop
#	foreach_in_collection tmp_INST $tmp_INST_COLL {
#		set INST_NAME [get_object_name $tmp_INST]
#		echo "# $INST_NAME"
#		set TIMING_PATH [get_timing_path -to [get_pins $INST_NAME/* -filter "@is_data_pin==true||@pin_direction==in"]]
#
#		#timing_path_loop
#		foreach_in_collection tmp $TIMING_PATH {
#			set PATH_GROUP [get_object_name [get_attribute $tmp endpoint_clock]]
#			set END_POINT  [get_attribute [get_attribute $tmp endpoint] lib_pin_name]
#
#			echo "+ $PATH_GROUP : $INST_NAME $END_POINT"
#		}
#	}
#}

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

####
#puts "# Define: GET_INFO <LibraryPinName>"
proc GET_INFO { {CUSTOM_MEM_PINS} } {
	foreach PIN $CUSTOM_MEM_PINS {
		set tmp_PINS [get_pins */$PIN]
		foreach_in_collection tmp_TGT $tmp_PINS {
			set PIN [get_object_name $tmp_TGT]
			echo "$PIN"
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

#/ssv/prj664/X-chip/users/okada/STA/m51030/memlist2
#puts "# Define: READ_LISTFILE <instance-list-File>"
proc READ_LISTFILE { {FILE_NAME} } {
	set fid [open $FILE_NAME]
	set CHECK_LIST {}
	while {[gets $fid str]>=0} {
		if {[regexp {^#} $str]} {continue}
		#if {[info exists CHECK_LIST]} {
			#set CHECK_LIST [concat $CHECK_LIST $str]
			lappend CHECK_LIST $str
		#} else {
		#	set CHECK_LIST $str
		#}
	}
	close $fid
	return $CHECK_LIST
}

#puts "# Define: COL2DISP <collection>"
proc COL2DISP { {COLLECTION} } {
	if {[sizeof_collection $COLLECTION] == 0} {return {}}
	foreach_in_collection tmp $COLLECTION {
		echo "[get_object_name $tmp]"
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

#puts "# Define: DIR_CHECK"
proc DIR_CHECK { {DIR_NAME} } {
        if {[file exists $DIR_NAME] && [file isdirectory $DIR_NAME]} {
                puts "* $DIR_NAME was found."
        } else {
                puts "* $DIR_NAME was not found. creating now."
                file mkdir $DIR_NAME
                if {[file exists $DIR_NAME]&&[file isdirectory $DIR_NAME]} {
                        puts "... OK"
                } else {
                        puts "Error\!\! Could not create $DIR_NAME. Exit."
                }
        }
}

#puts {  check_resource <string>}
proc check_resource {comment} {
	set memory_ [mem]
	set date_   [date]
	set host_   [info hostname]
	echo "---< check resources >------------------------------------------------------"
	echo " DATE: ${date_} *MEM: ${memory_} KB *HOST: ${host_} *${comment}"
	echo "----------------------------------------------------------------------------"
}
#Before 2003.02.05
if [ catch { set command_log_file $command_log_file } ] {
	set tool_name "pt_shell"
} else {
	set tool_name "dc_shell"
}
echo $tool_name

proc find_loadpin { net_name } {
  set pin_col {}
  foreach_in_collection tmp1 [ find net $net_name ] {
    set tmp2 [ filter_collection [ all_connected $tmp1 ] "pin_direction==in || pin_direction==inout" ]
    set pin_col [ add_to_collection $pin_col $tmp2 -unique ]
  }
  echo loadpin($net_name) : [get_object_name $pin_col]
  return $pin_col
}

proc find_drivepin { net_name } {
  set pin_col {}
  foreach_in_collection tmp1 [ find net $net_name ] {
    set tmp2 [ filter_collection [ all_connected $tmp1 ] "pin_direction==out || pin_direction==inout" ]
    set pin_col [ add_to_collection $pin_col $tmp2 -unique ]
  }
  echo drivepin($net_name) : [get_object_name $pin_col]
  return $pin_col
}

proc find_outputpin { pin_name } {
	set pin_col {}
	foreach_in_collection tmp1 [ find pin $pin_name] {
		set tmp2 [ filter_collection $tmp1 "pin_direction==out || pin_direction==inout" ]
		set pin_col [ add_to_collection $pin_col $tmp2 -unique ]
	}
	return $pin_col
}

proc find_inputpin { pin_name } {
	set pin_col {}
	foreach_in_collection tmp1 [ find pin $pin_name] {
		set tmp2 [ filter_collection $tmp1 "pin_direction==in || pin_direction==inout" ]
		set pin_col [ add_to_collection $pin_col $tmp2 -unique ]
	}
	return $pin_col
}
proc find_inputport { port_name } {
	set port_col {}
	foreach_in_collection tmp1 [ find port $port_name] {
		set tmp2 [ filter_collection $tmp1 "port_direction==in || port_direction==inout" ]
		set port_col [ add_to_collection $port_col $tmp2 -unique ]
	}
	return $port_col
}
proc find_outputport { port_name } {
	set port_col {}
	foreach_in_collection tmp1 [ find port $port_name] {
		set tmp2 [ filter_collection $tmp1 "port_direction==out || port_direction==inout" ]
		set port_col [ add_to_collection $port_col $tmp2 -unique ]
	}
	return $port_col
}
proc find_inoutport { port_name } {
	set port_col {}
	foreach_in_collection tmp1 [ find port $port_name] {
		set tmp2 [ filter_collection $tmp1 "port_direction==inout" ]
		set port_col [ add_to_collection $port_col $tmp2 -unique ]
	}
	return $port_col
}

#puts "# Define: MK_HF_CMD <collection>"
proc MK_HF_CMD { {HF_FILE "./LOAD/hi_fanout_set_load.tcl"} {HF_NUMBER 50} } {
	echo "#############################"
	echo "# Set HighFanout nets ideal #"
	echo "#############################"
	echo "# START"
	set_max_fanout $HF_NUMBER [current_design]
	redirect tmpHF {report_constraint -all_violators -max_fanout -nosplit}
	redirect /dev/null {
	set HF_LIST [sh grep "VIOLATED" tmpHF | awk '{print \$1}']
	set HF_NETS [get_nets -of [get_pins $HF_LIST]]
	set HF_NETS_LIST [COL2LIST $HF_NETS]
	}
	redirect $HF_FILE {
		echo "# DIR  : [sh pwd]"
		echo "# DATE : [date]"
		echo "# Athor: [sh whoami]"
		echo "set HF_NETS \[get_nets  \{"
		[foreach tmp $HF_NETS_LIST { echo $tmp }]
		echo "\}]"
		echo "set_ideal_network -no_propagate \$HF_NETS"
	}
	echo "# END"
	echo "#############################"
}
proc SOURCE { {FILENAME} } {
        echo "########################################"
        echo "# Start loading ${FILENAME}"
        echo "########################################"
        puts "Loading ${FILENAME}"
        source -echo ${FILENAME}
        echo "########################################"
        echo "# Finish loading ${FILENAME}"
        echo "########################################\n"
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


proc READ_PATH_INFO {} {
	set chk [file exists "./pathinfo.cfg"]
	if {$chk==0} {
		puts " --># Error: 'pathinfo.cfg' is not found!"
		exit
	} else {
		set fid [open pathinfo.cfg]
		set LINE {}
		while {[gets $fid str]>=0} {
			lappend LINE $str
			if {[regexp {(\\ *)$} $str]==0} {
				if { ([regexp {^( *#)} $str]==0) && ([llength [join ${LINE}]]>0) } { 
					regsub -all {\\} $LINE {} LINE_wo_BS
					scan ${LINE_wo_BS} "%s %s %s" SET NAME VALUE

					if {[info exist ::[join $NAME]]} {
						puts "<Ignored> $NAME is already declared as $$NAME."
					} else {
						eval [join ${LINE_wo_BS}]
						puts [subst [join ${LINE_wo_BS}]]

						regsub $NAME $LINE_wo_BS "::$NAME" LINE_wo_BS
						eval [join ${LINE_wo_BS}]
					}
				}
				set LINE {}
			}
		}
		close $fid
	}
}
proc TOTAL_RUN_TIME {} {
	global START_TIME
	global TOP
	global MODE
	set END_TIME           [clock seconds]
	set PASSED_TIME        [expr ${END_TIME} - ${START_TIME} ]
	set START_TIME_FORMAT  [clock format ${START_TIME} ]
	set END_TIME_FORMAT    [clock format ${END_TIME} ]
	set PASSED_TIME_FORMAT [concat [expr  ${PASSED_TIME}/3600]:[ clock format ${PASSED_TIME} -format {%M:%S} ]]
	set string [concat ${TOP} ${MODE} ${PASSED_TIME_FORMAT} \[Start\] ${START_TIME_FORMAT} \[End\] ${END_TIME_FORMAT} \[MEM\] [mem]]
	redirect -append ./LOG/EXEC_TIME.${MODE}.log { puts $string }
	puts $string
}

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

proc WRITE_FILE { {FILE_NAME} {LIST} } {
	set fid  [ open $FILE_NAME w ]
	set LINE [ join $LIST \n ]
	puts $fid $LINE
	close $fid
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


proc mkFreq_path { {TimingReport} } {
set LIST_CLK {}
set bar "+============================================================================================+"
set REPORT_FILE $TimingReport
set fid [open $REPORT_FILE]
set inREP 0
while {[gets $fid str]>=0} {
	if {[regexp "^----" $str] > 0} {continue}
	switch $inREP {
	0 {
		switch -regexp $str {
			"Startpoint:" {
				set START [lindex $str 1]
			}
			"Endpoint:" {
				set END [lindex $str 1]
			}
			"Path Group:" {
				set GROUP [lindex $str 2]
			}
			"Point" {
				if {[regexp "Trans" $str] > 0} {
					set FlagTran true
				} else {
					set FlagTran false
				}
				set inREP 1
			}
			default {}
		}
	}
	1 {
		if {[regexp {clock [0-9a-zA-Z_'/]* \(} $str] > 0} {
			set ST_CLK  [lindex $str 1]
			if {$FlagTran == "true"} {
				set ST_TIME [lindex $str 5]
			} else {
				set ST_TIME [lindex $str 4]
			}
			set inREP 2
		}
	}
	2 {
		if {[regexp {clock [0-9a-zA-Z_'/]* \(} $str] > 0} {
			if {[regexp "source latency" $str] > 0} {
				set ST_LATENCY [lindex $str 5]
			} else {
				set ED_CLK  [lindex $str 1]
				if {$FlagTran == "true"} {
					set ED_TIME [lindex $str 5]
				} else {
					set ED_TIME [lindex $str 4]
				}
				set inREP 3
			}
		} elseif {[regexp "data arrival time" $str] > 0} {
			set END $MONI
		}
	}
	3 {
		if {[regexp "source latency" $str] > 0} {
			set ED_LATENCY [lindex $str 5]
		}
		if {[regexp "time borrowed from endpoint" $str] > 0} {
			set ED_CLK  ${ED_CLK}_latch
			set ED_TIME [expr [lindex $str 4] + $ED_TIME]
			set inREP 3
		} elseif {[regexp "slack" $str] > 0} {
			set SLACK [lindex $str [expr [llength $str] - 1] ]
			set PERI  [expr $ED_TIME - $ST_TIME]
			if {$PERI == 0.0} {
				set PERI $ED_TIME
				if {$SLACK >= 0} {
					set RATIO 1
				} else {
					if {$ED_TIME == 0} {
						set RATIO 1
						set PERI  1
					} else {
						set RATIO [expr ($SLACK + $ED_TIME) / $ED_TIME]
					}
				}
			} else {
				set ARRL  [expr $PERI - $SLACK]
				set RATIO [expr $ARRL / $PERI]
			}
			if {[info exists WST_RATIO(${ST_CLK}@${ED_CLK})]} {
				if {$RATIO > $WST_RATIO(${ST_CLK}@${ED_CLK})} {
					set WST_RATIO(${ST_CLK}@${ED_CLK}) $RATIO
				}
			} else {
				set WST_RATIO(${ST_CLK}@${ED_CLK}) $RATIO
				lappend LIST_CLK ${ST_CLK}@${ED_CLK}
			}
			set inREP 0
			set FlagTran false
			lappend DB_LIST(${ST_CLK}@${ED_CLK}) [list $RATIO $SLACK $PERI ${ST_CLK}@${ED_CLK} $ST_TIME $ED_TIME $START $END]
		}
	}
	}
	set MONI [lindex $str 0]
}
close $fid

puts $bar
puts [format "%5s %7s %5s (%5s / %5s ) %20s %20s %s %s" \
	RATIO SLACK PERI ST ED  ST_CLK ED_CLK START END]
puts $bar
foreach clk $LIST_CLK {
	regsub "(.*)@.*" $clk {\1} DISP_CLK_st
	regsub ".*@(.*)" $clk {\1} DISP_CLK_ed
	foreach disp [lsort -index 0 -real -decreasing $DB_LIST($clk)] {
	set RATIO   [lindex $disp 0]
	set SLACK   [lindex $disp 1]
	set PERI    [lindex $disp 2]
	set CLK     [lindex $disp 3]
	set ST_TIME [lindex $disp 4]
	set ED_TIME [lindex $disp 5]
	set START   [lindex $disp 6]
	set END     [lindex $disp 7]

	if {$DISP_CLK_st == $DISP_CLK_ed} {
		puts [format "%5.3f %7.3f %5.2f ( %5.2f / %5.2f ) %41s %s %s" \
			$RATIO $SLACK $PERI $ST_TIME $ED_TIME $DISP_CLK_ed $START $END]
	} else {
		puts [format "%5.3f %7.3f %5.2f ( %5.2f / %5.2f ) %20s %20s %s %s" \
			$RATIO $SLACK $PERI $ST_TIME $ED_TIME $DISP_CLK_st $DISP_CLK_ed $START $END]
	}
	}
	puts $bar
	unset DISP_CLK_st
	unset DISP_CLK_ed
}
}

proc mkFreq_sum { {TimingReport} } {
set LIST_CLK {}
set result   {}
set bar "+============================================================================================+"
set REPORT_FILE $TimingReport
set fid [open $REPORT_FILE]
set inREP 0
while {[gets $fid str]>=0} {
	if {[regexp "^----" $str] > 0} {continue}
	if {$inREP == 0 && [regexp "Point" $str] > 0} {
		set inREP 1
		if {[regexp "Trans" $str] > 0} {
			set FlagTran true
		} else {
			set FlagTran false
		}
	} elseif {$inREP == 1 && [regexp {clock [0-9a-zA-Z_'/]* \(} $str] > 0} {
		set ST_CLK  [lindex $str 1]
		if {$FlagTran == "true"} {
			set ST_TIME [lindex $str 5]
		} else {
			set ST_TIME [lindex $str 4]
		}
		set inREP 2
	} elseif {$inREP == 2 && [regexp {clock [0-9a-zA-Z_'/]* \(} $str] > 0} {
		if {[regexp "source latency" $str] > 0} {
			set ST_LATENCY [lindex $str 5]
		} else {
			set ED_CLK  [lindex $str 1]
			if {$FlagTran == "true"} {
				set ED_TIME [lindex $str 5]
			} else {
				set ED_TIME [lindex $str 4]
			}
			set inREP 3
		}
	} elseif {$inREP == 3 && [regexp "source latency" $str] > 0} {
		set ED_LATENCY [lindex $str 5]
	} elseif {$inREP == 3 && [regexp "time borrowed from endpoint" $str] > 0} {
		set ED_CLK  ${ED_CLK}_latch
		#set ED_TIME [lindex $str 4]
		set ED_TIME [expr [lindex $str 4] + $ED_TIME]
		set inREP 3
	} elseif {$inREP == 3 && [regexp "slack" $str] > 0} {
		set SLACK [lindex $str [expr [llength $str] - 1] ]
		set PERI  [expr $ED_TIME - $ST_TIME]
#puts "#ST_TIME($ST_TIME) ED_TIME($ED_TIME) PERI($PERI)"
		if {$PERI == 0.0} {
			#set PERI $ED_TIME
			if {$SLACK >= 0} {
				set RATIO 1
			} else {
				if {$ED_TIME == 0} {
					set RATIO 1
					#set PERI  1
				} else {
					set RATIO [expr ($SLACK + $ED_TIME) / $ED_TIME]
				}
			}
		} else {
			set ARRL  [expr $PERI - $SLACK]
			set RATIO [expr $ARRL / $PERI]
		}
		if {[info exists WST_RATIO(${ST_CLK}@${ED_CLK})]} {
			if {$RATIO > $WST_RATIO(${ST_CLK}@${ED_CLK})} {
				set WST_RATIO(${ST_CLK}@${ED_CLK}) $RATIO
				set WST_PERI(${ST_CLK}@${ED_CLK})  $PERI
			}
		} else {
			set WST_RATIO(${ST_CLK}@${ED_CLK}) $RATIO
			set WST_PERI(${ST_CLK}@${ED_CLK})  $PERI
			set TNS(${ST_CLK}@${ED_CLK}) 0
			set NUM(${ST_CLK}@${ED_CLK}) 0
			set T_NUM(${ST_CLK}@${ED_CLK}) 0
			lappend LIST_CLK ${ST_CLK}@${ED_CLK}
		}
		incr T_NUM(${ST_CLK}@${ED_CLK})
		if {$SLACK < 0} {
			incr NUM(${ST_CLK}@${ED_CLK})
			set TNS(${ST_CLK}@${ED_CLK}) [expr $TNS(${ST_CLK}@${ED_CLK}) + $SLACK]
		}
		set inREP 0
		set FlagTran false
	}
}
close $fid

puts $bar
puts [format "%9s %8s %8s %10s %5s / %5s %30s" "   Freq." ratio "  Period" TNS #VIO #TOTAL CLOCK]
puts $bar
foreach clk $LIST_CLK {
	#if {$WST_RATIO($clk) >= 0.0} {continue}
	set check [expr $WST_RATIO($clk) * $WST_PERI($clk)]
	if {$check == 0} {
		set WST_FREQ 0
	} else {
		set WST_FREQ [expr (1 / ( $WST_RATIO($clk) * $WST_PERI($clk) )) * 1000]
	}
	regsub "(.*)@.*" $clk {\1} DISP_CLK_st
	regsub ".*@(.*)" $clk {\1} DISP_CLK_ed
	if {$DISP_CLK_st == $DISP_CLK_ed} {
		lappend result [format "%9.2f %8.3f %8.3f %10.1f %5d / %5d %30s" \
			$WST_FREQ $WST_RATIO($clk) $WST_PERI($clk) $TNS($clk) $NUM($clk) $T_NUM($clk) $DISP_CLK_st]
	} else {
		lappend result [format "%9.2f %8.3f %8.3f %10.1f %5d / %5d %30s -> %s" \
			$WST_FREQ $WST_RATIO($clk) $WST_PERI($clk) $TNS($clk) $NUM($clk) $T_NUM($clk) $DISP_CLK_st $DISP_CLK_ed]
	}
}
foreach tmp [lsort -index 1 -real -decreasing $result] {puts $tmp}
puts $bar

}

proc mkMod_sum { {PathReport} } {
	# << File read & check >>
	proc READ_LISTFILE { {FILE_NAME} } {
		set chk [file exists $FILE_NAME]
		if {$chk==0} {
			puts " --># ERROR # not found $FILE_NAME"
			return -1
		}
		
	        set fid [open $FILE_NAME]
	        set CHECK_LIST {}
	        while {[gets $fid str]>=0} {
	                if {[regexp {^#} $str]} {continue}
	                lappend CHECK_LIST $str
	        }
	        close $fid
	        return $CHECK_LIST
	}

	# Comment <*.path items>
	#      OLD            NEW
	#                     Diff     Same (clock)
	# (0) Ratio           <-       <-
	# (1) Slack           <-       <-
	# (2) Rate            Peri     <-
	# (3) StartCLK(Edge)  (        <-
	# (4) EndCLK(Edge)    ST       <-
	# (5) StartInstance   /        <-
	# (6) EndInstance     ED       <-
	# (7)                 )        <-
	# (8)                 ST_CLK   ED_CLK
	# (9)                 ED_CLK   ST_INST
	#(10)                 ST_INST  ED_INST
	#(11)                 ED_INST
	
	set bar "+===============================================================================================+"
	set SRC            [READ_LISTFILE $PathReport]
	set CLK_CROUP_LIST {}
	
	#sort by slack-ratio
	set SRC_mod {}
	foreach tmp $SRC {
		if {[regexp {^#}	$tmp]}	{continue}
		if {[regexp {^\+}	$tmp]}	{continue}
		if {[regexp {^RATIO}	$tmp]}	{continue}
		if {[regexp {^$}	$tmp]}	{continue}
		lappend SRC_mod	$tmp
	}
	set SRC_sort [lsort -real -decreasing -index 0 $SRC_mod]
	set MOD_GROUP_LIST      {}
	set CLK_CROUP_LIST      {}
	set STRLEN(INST_ST)	0
	set STRLEN(INST_ED)	0
	
	foreach tmp $SRC_sort {
		set LENGTH  [llength $tmp]
		switch $LENGTH {
			11 {
				# << Clock is same >>
				set RATIO       [lindex $tmp  0]
				set SLACK       [lindex $tmp  1]
				set PERI        [lindex $tmp  2]
				set CLK_NAME_ST [lindex $tmp  8]
				set CLK_EDGE_ST [lindex $tmp  4]
				set CLK_NAME_ED [lindex $tmp  8]
				set CLK_EDGE_ED [lindex $tmp  6]
				set INST_ST     [lindex $tmp  9]
				set INST_ED     [lindex $tmp 10]
				set CLK_ST      "${CLK_NAME_ST}(${CLK_EDGE_ST})"
				set CLK_ED      "${CLK_NAME_ST}(${CLK_EDGE_ED})"
			}
			12 {
				# << Clock is different >>
				set RATIO       [lindex $tmp  0]
				set SLACK       [lindex $tmp  1]
				set PERI        [lindex $tmp  2]
				set CLK_NAME_ST [lindex $tmp  8]
				set CLK_EDGE_ST [lindex $tmp  4]
				set CLK_NAME_ED [lindex $tmp  9]
				set CLK_EDGE_ED [lindex $tmp  6]
				set INST_ST     [lindex $tmp 10]
				set INST_ED     [lindex $tmp 11]
				set CLK_ST      "${CLK_NAME_ST}(${CLK_EDGE_ST})"
				set CLK_ED      "${CLK_NAME_ED}(${CLK_EDGE_ED})"
			}
			default {
				puts "#Error: $tmp"
				#exit;
			}
		}
		# << Module Name Start Instance >>
		set list_INST_ST [split $INST_ST "/"]
		set ST_MOD [lindex $list_INST_ST [lsearch -regexp $list_INST_ST {([0-9a-zA-Z_]*_pv[0-9a-z_]*)}]]
		#regsub {.*/([0-9a-zA-Z_]*_pv[0-9a-z_]*)/.*} $INST_ST {\1} ST_MOD
		#regsub {([0-9a-zA-Z_]*_pv[0-9a-z_]*)/.*}    $ST_MOD  {\1} ST_MOD
		if {[string length $ST_MOD] < 1} {
			set ST_MOD [lindex $list_INST_ST 0]
		}
	
		# << Module Name End Instance >>
		set list_INST_ED [split $INST_ED "/"]
		set ED_MOD [lindex $list_INST_ED [lsearch -regexp $list_INST_ED {([0-9a-zA-Z_]*_pv[0-9a-z_]*)}]]
		#regsub {.*/([0-9a-zA-Z_]*_pv[0-9a-z_]*)/.*} $INST_ED {\1} ED_MOD
		#regsub {([0-9a-zA-Z_]*_pv[0-9a-z_]*)/.*}    $ED_MOD  {\1} ED_MOD
		if {[string length $ED_MOD] < 1} {
			set ED_MOD [lindex $list_INST_ED 0]
		}
	
		# << check string length >>
		set tmpSTRLEN(INST_ST) [string length $ST_MOD]
		set tmpSTRLEN(INST_ED) [string length $ED_MOD]
		if {$tmpSTRLEN(INST_ST) > $STRLEN(INST_ST)} {set STRLEN(INST_ST) $tmpSTRLEN(INST_ST)}
		if {$tmpSTRLEN(INST_ED) > $STRLEN(INST_ED)} {set STRLEN(INST_ED) $tmpSTRLEN(INST_ED)}
	
	
		set CLK_CROUP ${CLK_ST}_${CLK_ED}
		set MOD_GROUP ${ST_MOD},${ED_MOD}
		if {[lsearch $CLK_CROUP_LIST $CLK_CROUP]==-1} {
			lappend CLK_CROUP_LIST $CLK_CROUP
		}
		if {[lsearch $MOD_GROUP_LIST $MOD_GROUP]== -1} {
			lappend MOD_GROUP_LIST $MOD_GROUP
		}
		if {![info exists TNS($CLK_CROUP)]} {
			set TNS($CLK_CROUP) {}
		}
		if {![info exists TNS($MOD_GROUP)]} {
			set TNS($MOD_GROUP) {}
		}

	
		# make TNS info.
		if {$SLACK > 0} {
			set SLACK 0.0
		}
		set TNS($CLK_CROUP) [expr $TNS($CLK_CROUP) + $SLACK]
		set TNS($MOD_GROUP) [expr $TNS($MOD_GROUP) + $SLACK]
		lappend INFO($MOD_GROUP) $tmp
	}
	
	# DISPLAY RESULT
	puts $bar
	eval "puts \[format \"%${STRLEN(INST_ST)}s %${STRLEN(INST_ED)}s %7s %7s %8s %6s (%s/%s)\" START END RATIO WNS TNS PERI ST_CLK END_CLK]"
	
	puts $bar
	foreach tmp $MOD_GROUP_LIST {
		set SRC_sort  [lsort -real -decreasing -index 0 $INFO($tmp)]
		set WORST     [lindex $INFO($tmp) 0]
		set LENGTH    [llength $WORST]
		switch $LENGTH {
			11 {
				# << Clock is same >>
				set RATIO       [lindex $WORST  0]
				set SLACK       [lindex $WORST  1]
				set PERI        [lindex $WORST  2]
				set CLK_NAME_ST [lindex $WORST  8]
				set CLK_EDGE_ST [lindex $WORST  4]
				set CLK_NAME_ED [lindex $WORST  8]
				set CLK_EDGE_ED [lindex $WORST  6]
				set INST_ST     [lindex $WORST  9]
				set INST_ED     [lindex $WORST 10]
				set CLK_ST      "${CLK_NAME_ST}(${CLK_EDGE_ST})"
				set CLK_ED      "${CLK_NAME_ST}(${CLK_EDGE_ED})"
			}
			12 {
				# << Clock is different >>
				set RATIO       [lindex $WORST  0]
				set SLACK       [lindex $WORST  1]
				set PERI        [lindex $WORST  2]
				set CLK_NAME_ST [lindex $WORST  8]
				set CLK_EDGE_ST [lindex $WORST  4]
				set CLK_NAME_ED [lindex $WORST  9]
				set CLK_EDGE_ED [lindex $WORST  6]
				set INST_ST     [lindex $WORST 10]
				set INST_ED     [lindex $WORST 11]
				set CLK_ST      "${CLK_NAME_ST}(${CLK_EDGE_ST})"
				set CLK_ED      "${CLK_NAME_ED}(${CLK_EDGE_ED})"
			}
			default {
				puts "#Error: $tmp"
				#exit;
			}
		}
		set TNS_      $TNS($tmp)
		set ST_MOD    [lindex [split $tmp ","] 0]
		set ED_MOD    [lindex [split $tmp ","] 1]
		eval "puts \[format \"%${STRLEN(INST_ST)}s %${STRLEN(INST_ED)}s %7.3f %7.3f %10.2f %6.2f (%30s/%-30s)\" \$ST_MOD \$ED_MOD \$RATIO \$SLACK \$TNS_ \$PERI \$CLK_ST \$CLK_ED]"
	}
	puts $bar
}

proc TRACE_TPI_FF { {TRACE_ROOT_LIST "tt_tr"} } {
	set ROOT [get_pins -of [get_nets $TRACE_ROOT_LIST] -filter pin_direction=="out"]
	set TPI_FF {}
	foreach_in_collection TT_TR $ROOT {
		set TPI_FF [add_to_collection $TPI_FF [all_fanout -from $TT_TR -endpoints_only -flat]]
	}
	set TPI_FF [sort_collection $TPI_FF full_name]
	foreach tmp [COL2LIST $TPI_FF] {
		echo $tmp
	}
}

proc CHECK_GCLK {} {
	suppress_message {ATTR-3}
	foreach_in_collection CLK_CG [get_generated_clocks] {
		puts {}
		set PIN_CG     [get_attribute $CLK_CG sources]
		set INST_CG    [get_cells -of [get_pins $PIN_CG]]
	
		redirect /dev/null {
			set MASTER_CLK [COL2LIST [get_attribute $CLK_CG master_clock]]
			set IN_CLK     [COL2LIST [get_attribute [get_pins -of $INST_CG -filter "(is_clock_used_as_clock==true || is_clock_pin==true) && pin_direction==in"] clocks]]
			if {[llength $IN_CLK] == 0} {
				set IN_CLK_TRACED [remove_from_collection [all_fanin -to $PIN_CG -startpoint] $PIN_CG]
				set IN_CLK        [COL2LIST [get_attribute [filter_collection $IN_CLK_TRACED "(is_clock_used_as_clock==true || is_clock_pin==true) && pin_direction==in"] clocks]]
			}
			set IN_CLK        [lsort -dictionary -unique $IN_CLK]
		}

		#set IN_CLK     [COL2LIST [get_attribute [get_pins -of $INST_CG -filter pin_direction=="in"] clocks]]
		set NAME_CG    [get_object_name $CLK_CG]
	
		set NAME_PIN_CG    [get_object_name $PIN_CG]
	
		if {[lsearch $IN_CLK $MASTER_CLK] == "-1"} {
			puts "# NG : $MASTER_CLK => $NAME_CG ($NAME_PIN_CG)"

				if {[llength $MASTER_CLK]=="0"} {
					puts "       Error: No master clock"
				}
				foreach tmp $IN_CLK {
					puts "       $tmp"
				}
		} else {
			puts "  OK : $MASTER_CLK => $NAME_CG ($NAME_PIN_CG)" 
				foreach tmp $IN_CLK {
					if {$MASTER_CLK == $tmp} {
						puts "     * $tmp"
					} else {
						puts "       $tmp"
					}
				}
		}
		set NAME_CG {}
		set IN_CLK {}
		set NAME_PIN_CG {}
	}
	unsuppress_message {ATTR-3}
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

proc CHNGE_VTH_TO_ML_WO_CLK { {WO_CLK_CELL_LIST_SYS} {WO_CLK_CELL_LIST_DFT} } {
	global STBY_AREA
	global MODE

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

	#### With out clock cells ####
	set CLOCK_CELL_INST	[ get_cells [ concat [ READ_LISTFILE ${WO_CLK_CELL_LIST_SYS} ] [ READ_LISTFILE ${WO_CLK_CELL_LIST_DFT} ]]]

	puts "*               ...without clock cells.."
	set HVTH_WAIT_WO_CLK		[remove_from_collection $HVTH_WAIT $CLOCK_CELL_INST]
	set TO_LVTH_TARGET_WO_CLK	[remove_from_collection $TO_LVTH_TARGET $CLOCK_CELL_INST]

	# << Hvth => Mvth >> for WaitArea
	puts "*               Making ChangeList for WaitArea...\n"
	set CHANGE_LIST ""
	foreach_in_collection INST $HVTH_WAIT_WO_CLK {
		set INST_NAME [get_object_name $INST]
		set REF_NAME  [get_attribute $INST ref_name]
		regsub "TH(\[567CDME\])" $REF_NAME {TM\1}  REF_CHANGED
		lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
	}
	puts "*               Writing './LOAD/TO_MVTH_WO_CLK.tcl'...\n"
	WRITE_FILE ./LOAD/TO_MVTH_WO_CLK.tcl $CHANGE_LIST


	# << *vth => Lvth >> for Others
	set NUM_TO_LVTH [sizeof_collection $TO_LVTH_TARGET_WO_CLK]
	puts "*               Making ChangeList for Others(${NUM_TO_LVTH})... \n"
	set CHANGE_LIST ""
	foreach_in_collection INST $TO_LVTH_TARGET_WO_CLK {
		set INST_NAME [get_object_name $INST]
		set REF_NAME  [get_attribute $INST ref_name]
		regsub "TH(\[567CDME\])" $REF_NAME    {TL\1}  REF_CHANGED
		regsub "TM(\[567CDME\])" $REF_CHANGED {TL\1}  REF_CHANGED
		if {[regexp "^TL5B" $REF_CHANGED] && ![regexp "^TL5BUF" $REF_CHANGED]} {continue}
		lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
	}
	puts "*               Writing './LOAD/TO_LVTH_WO_CLK.tcl'...\n"
	WRITE_FILE ./LOAD/TO_LVTH_WO_CLK.tcl $CHANGE_LIST

	echo "KEY: TO_MVTH_WO_CLK.tcl & TO_LVTH_WO_CLK.tcl has been ready." > ./LOAD/KEY_TO_CHG_VTH_WO_CLK
}


proc MAKE_CLOCK_CELL_LISTFILE {} {
	global STA_MODE
	set CLOCK_CELL_PINS     [get_pins -of [get_cells -h * ] -filter "pin_direction==out"]
	foreach_in_collection tmp [get_pins $CLOCK_CELL_PINS] {
		set CLOCK_CELL_INST     [get_cells -of $tmp]
		set CLOCK_ATTR	[get_attr -q [get_pins $tmp ] clocks]
		if { $CLOCK_ATTR != "" } {
			set INST_tmp    [get_object_name $CLOCK_CELL_INST]
			puts "$INST_tmp" 
		}
	}	>> ./LOAD/WO_CLK_CELL.${STA_MODE}.list
	#echo "KEY: WO_CLK_CELL.${STA_MODE} has been ready." > ./LOAD/KEY_WO_CLK_CELL.${STA_MODE}
}

proc WAIT_KEY { {KEY_FILE} } {
	puts "* Information : Waiting for file '${KEY_FILE}' now..."
	while { [file exists $KEY_FILE] != 1 } {
		exec sleep 60
	}
	exec sleep 150
	puts "* Information : '${KEY_FILE}' has been created"
	#check_error -reset
	return 1
}
proc WRITE_LIST2FILE { {LIST} {FILENAME} } {
	set fid [open $FILENAME "w"]
	foreach tmp $LIST {
		puts $fid $tmp
	}
	close $fid
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

# T.Igarash 2011.1.31
# A.Kato    2011.5.19
proc READ_OCV_INFO_FROM_DESIGN_CFG {} {
	if {![info exists ::ocv_param_table]} {
		puts "* Error : OCV parameter table \"ocv_param_table\" not defined in design.info file."
	exit
	}

	puts ""
	set max_len 0
	foreach list $::ocv_param_table {
		if {[llength $list] != 8} {
			puts "* Error : lack of item(s)."
			puts "       at : $list"
			exit
		}

		# check list item value
		foreach item [lrange $list 0 1] {
			if {![regexp {^\w+$} $item]} {
				puts "* Error : Key word error. \"$item\" in \"$list\""
				exit
			}
		}
		foreach item [lrange $list 2 7] {
			if {![regexp {^(\d.)?\d+$} $item]} {
				puts "* Error : Not a value. \"$item\" in \"$list\""
				exit
			}
		}

		set ary_cond_delay "[lindex $list 0],[lindex $list 1]"
		set derate_cell_early       [lindex $list 2]
		set derate_cell_late        [lindex $list 3]
		set derate_net_early        [lindex $list 4]
		set derate_net_late         [lindex $list 5]
		set derate_cell_early_oside [lindex $list 6]
		set derate_cell_late_oside  [lindex $list 7]

		set ::ocv_param_list($ary_cond_delay) [list \
			      $derate_cell_early $derate_cell_late \
			      $derate_net_early  $derate_net_late \
			      $derate_cell_early_oside $derate_cell_late_oside \
			      ]

		if {$max_len < [string length [lindex $list 0]]} {
			set max_len [string length [lindex $list 0]]
		}
	}
	if {![info exists ::ocv_param_list]} {
		puts "* Error : Cannot read OCV parameter(s)."
		exit
	}


	# output OCV parameters
	puts "* Information : OCV Parameter Settings."
	puts "CONDITION   (SETUP/HOLD)  cell(early/late) net(early/late) outside(early/late)"
	foreach item [lsort [array names ::ocv_param_list]] {
		set elm [split $item ","]
		puts -nonewline [format "%-${max_len}s" [lindex $elm 0]]
		puts -nonewline [format {  %-8s} [lindex $elm 1]]
		puts [join [concat $::ocv_param_list($item)] "    "]
	}
	puts ""
	return 0
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

proc CHNGE_VTH_TO_H {} {
        global STBY_AREA

        puts "* Information : Changing CellVth : WaitArea=No Change, Others=Hvth."
        puts "*               Making Collections...\n"
        set CELL_ALL [get_cells * -h]
        puts "*               ...Hvth"
        set UHVTH_INST [filter_collection $CELL_ALL "ref_name=~TUH*"]

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
        set UHVTH_OTHER [remove_from_collection $UHVTH_INST $ALL_WAIT]
        set TO_HVTH_TARGET ${UHVTH_OTHER}

        #puts "*               ...WaitArea.."
        #set UHVTH_WAIT  [remove_from_collection $UHVTH_INST $UHVTH_OTHER]

        # << Hvth => Mvth >> for WaitArea
        #puts "*               Making ChangeList for WaitArea...\n"
        #set CHANGE_LIST ""
        #foreach_in_collection INST $UHVTH_WAIT {
        #       set INST_NAME [get_object_name $INST]
        #       set REF_NAME  [get_attribute $INST ref_name]
        #       regsub "TUH(\[QFT\])" $REF_NAME {TH\1}  REF_CHANGED
        #       lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
        #}
        #puts "*               Writing './LOAD/TO_HVTH.tcl'...\n"
        #WRITE_FILE ./LOAD/TO_HVTH.tcl $CHANGE_LIST


        # << UHVth => HVth >> for Others
        set NUM_TO_HVTH [sizeof_collection $TO_HVTH_TARGET]
        puts "*               Making ChangeList for Others(${NUM_TO_HVTH})... \n"
        set CHANGE_LIST ""
        foreach_in_collection INST $TO_HVTH_TARGET {
                set INST_NAME [get_object_name $INST]
                set REF_NAME  [get_attribute $INST ref_name]
                regsub "TUH(\[QFT\])" $REF_NAME    {TH\1}  REF_CHANGED
                lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
        }
        puts "*               Writing './LOAD/TO_HVTH.tcl'...\n"

        set fid  [ open "./LOAD/TO_HVTH.tcl" w ]
        foreach LINE ${CHANGE_LIST} {
           puts $fid $LINE
        }
        close $fid

}

proc CHNGE_VTH_TO_H_WO_CLK { {WO_CLK_CELL_LIST_SYS} {WO_CLK_CELL_LIST_DFT} } {
        global STBY_AREA
        global MODE

        puts "* Information : Changing CellVth : WaitArea=No Change, Others=Hvth."
        puts "*               Making Collections...\n"
        set CELL_ALL [get_cells * -h]
        puts "*               ...UHvth"
        set UHVTH_INST [filter_collection $CELL_ALL "ref_name=~TUH*"]

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
        set UHVTH_OTHER [remove_from_collection $UHVTH_INST $ALL_WAIT]
        set TO_HVTH_TARGET ${UHVTH_OTHER}

        puts "*               ...WaitArea.."
        set UHVTH_WAIT  [remove_from_collection $UHVTH_INST $UHVTH_OTHER]

        #### With out clock cells ####
        set CLOCK_CELL_INST     [ get_cells [ concat [ READ_LISTFILE ${WO_CLK_CELL_LIST_SYS} ] [ READ_LISTFILE ${WO_CLK_CELL_LIST_DFT} ]]]

        puts "*               ...without clock cells.."
        set UHVTH_WAIT_WO_CLK           [remove_from_collection $UHVTH_WAIT $CLOCK_CELL_INST]
        set TO_HVTH_TARGET_WO_CLK       [remove_from_collection $TO_HVTH_TARGET $CLOCK_CELL_INST]

        # << Hvth => Mvth >> for WaitArea
        #puts "*               Making ChangeList for WaitArea...\n"
        #set CHANGE_LIST ""
        #foreach_in_collection INST $UHVTH_WAIT_WO_CLK {
        #       set INST_NAME [get_object_name $INST]
        #       set REF_NAME  [get_attribute $INST ref_name]
        #        regsub "TUH(\[QFT\])" $REF_NAME    {TH\1}  REF_CHANGED
        #       lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
        #}
        #puts "*               Writing './LOAD/TO_MVTH_WO_CLK.tcl'...\n"
        #WRITE_FILE ./LOAD/TO_HVTH_WO_CLK.tcl $CHANGE_LIST


        # << HUVth => Hvth >> for Others
        set NUM_TO_HVTH [sizeof_collection $TO_HVTH_TARGET_WO_CLK]
        puts "*               Making ChangeList for Others(${NUM_TO_LVTH})... \n"
        set CHANGE_LIST ""
        foreach_in_collection INST $TO_HVTH_TARGET_WO_CLK {
                set INST_NAME [get_object_name $INST]
                set REF_NAME  [get_attribute $INST ref_name]
                regsub "TUH(\[QFT\])" $REF_NAME    {TH\1}  REF_CHANGED
                lappend CHANGE_LIST [concat "size_cell  ${INST_NAME}  \$${REF_CHANGED}/${REF_CHANGED}  ;# ${REF_NAME}" ]
        }
        puts "*               Writing './LOAD/TO_HVTH_WO_CLK.tcl'...\n"
        set fid  [ open "./LOAD/TO_HVTH.tcl" w ]
        foreach LINE ${CHANGE_LIST} {
           puts $fid $LINE
        }
        close $fid
        echo "KEY: TO_HVTH_WO_CLK.tcl has been ready." > ./LOAD/KEY_TO_CHG_VTH_WO_CLK
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



proc GET_CLOCK_CELLS { {CLOCK_INST_FILE CLOCK_INST_FILE.txt} } {
        set fid_o [open "|gzip -c > ${CLOCK_INST_FILE}.gz" w]
	### Search clock pin from attribute
	set all_clockpins_obj [get_clock_network_objects -type pin]
	set all_clockpins_obj [get_pins $all_clockpins_obj -filter "is_hierarchical==false"]
	set all_clockpins_obj [get_pins $all_clockpins_obj -filter "direction==out"]
	set all_clockpins_obj [get_pins $all_clockpins_obj -filter "is_clock_pin==true||is_clock_used_as_clock==true||is_clock_gating_pin==true"]


	### Search clock pin from clock_timing report
	set TMPCLKPINS {}
	foreach_in_collection target_clock [get_clocks [all_clocks] -filter "is_generated==true"] {
	  redirect -variable CLOCK_REPORT {report_clock_timing -type latency -clock [get_clocks $target_clock] -verbose -nosplit}
	  set repflg 0
	  for {set i 0} {$i < [llength $CLOCK_REPORT]} {incr i} {
	   set str [lindex $CLOCK_REPORT $i]
	   if {[string match  "-----*" $str] } {
		set repflg 1
	   }
	   if {$repflg == 0 || ! [string match "(*" $str] } {
		continue;
	   }
	   set before_string  [lindex $CLOCK_REPORT $i-1]
	   set before_string2 [lindex $CLOCK_REPORT $i-2]
	   if {[string match "(*" $before_string] || [string match "clock" $before_string2] } {
			continue;
	   }
	   set clockpin_obj [get_pins -q $before_string]
	   if {$clockpin_obj == ""} {
			# Reject Port
			continue;
	   }
	   if {[get_attribute -q $clockpin_obj is_clock_used_as_clock] != "true" && [get_attribute $clockpin_obj is_hierarchical] == "false"} {
		set TMPCLKPINS [add_to_collection $TMPCLKPINS $clockpin_obj -unique]
		#puts "[get_object_name $target_clock] [get_object_name $clockpin_obj]"
	   }
	  }
	}
	### End of Search clock pin from clock_timing report
	set all_clockpins_obj [add_to_collection $all_clockpins_obj $TMPCLKPINS -unique]
	
        set CLOCK_CELLS [get_object_name [get_cells -of $all_clockpins_obj]]
        foreach CLOCK_CELL $CLOCK_CELLS {
                set ref_name [get_attribute [get_cells $CLOCK_CELL] ref_name]
                puts $fid_o "$CLOCK_CELL $ref_name"
        }
        close $fid_o;
}



proc GET_CRITICAL_PINS { {pin_collection} {DELAY "SETUP"} {SLACK 0.1} {OUT_FILE "./setup.pin"} } {
	set ::timing_save_pin_arrival_and_slack true
	set fid [open $OUT_FILE "w"]
	if {$DELAY == "HOLD"} {
		set critical_pins [filter_collection $pin_collection "min_rise_slack < $SLACK || min_fall_slack < $SLACK"]
	} else {
		set critical_pins [filter_collection $pin_collection "max_rise_slack < $SLACK || max_fall_slack < $SLACK"]
	}
	foreach_in_collection pin $critical_pins {
		puts $fid [get_object_name $pin]
	}
	close $fid
	return $critical_pins
}



proc GET_CRITICAL_DETAIL_PINS { {pin_collection}  {OUT_FILE "./SETUP_SLACK.list"} {DELAY "SETUP"} {SLACK 0.8} } {
    set ::timing_save_pin_arrival_and_slack true
    set OUTFILE [open "|gzip -c > ${OUT_FILE}.gz" w]
    puts $OUTFILE "##PIN_NAME rise_slack fall_slack rise_tran fall_tran cell_name"
    if {$DELAY == "SETUP"} {
	set critical_pins [filter_collection $pin_collection "max_rise_slack < $SLACK || max_fall_slack < $SLACK"]
    } else {
	set critical_pins [filter_collection $pin_collection "min_rise_slack < $SLACK || min_fall_slack < $SLACK"]
    }

    foreach_in_collection pin $critical_pins {
	if {[get_attribute $pin is_hierarchical] == "true"} { continue }
	if { $DELAY == "SETUP" } {
		set fall_slack [get_attribute -quiet $pin max_fall_slack]
		set rise_slack [get_attribute -quiet $pin max_rise_slack]
	} else {
		set fall_slack [get_attribute -quiet $pin min_fall_slack]
		set rise_slack [get_attribute -quiet $pin min_rise_slack]
	}
	set fall_tran [get_attribute -quiet $pin actual_fall_transition_max]
	set rise_tran [get_attribute -quiet $pin actual_rise_transition_max]
	set cell_name [get_attribute [get_cells -of $pin] ref_name]

	puts $OUTFILE "[get_object_name $pin] $rise_slack $fall_slack $rise_tran $fall_tran $cell_name"
    }
    close $OUTFILE
}


proc GET_SETUP_CRITICAL_BADTRAN_PINS { {pin_collection} {tran_threshold 0.4} {OUT_FILE "./setup_big_tran.info"} } {
	set fid [open $OUT_FILE "w"]
	set ::timing_save_pin_arrival_and_slack true
	set out_pins                 [filter_collection $pin_collection pin_direction=="out"]
	set big_transition_pins      [filter_collection $out_pins "actual_rise_transition_max > $tran_threshold || actual_fall_transition_max > $tran_threshold"]
	set return_value             {}
	foreach_in_collection pin $big_transition_pins {
		set name_pin         [get_object_name $pin]
		set value_tran_r     [get_attribute $pin actual_rise_transition_max]
		set value_tran_f     [get_attribute $pin actual_fall_transition_max]
		set value_tran       [expr {$value_tran_r > $value_tran_f ? $value_tran_r : $value_tran_f}]
		set value_slack_r    [get_attribute $pin max_rise_slack]
		set value_slack_f    [get_attribute $pin max_fall_slack]
		#puts "* ($value_slack_r/$value_slack_f) [get_object_name $pin]"
		if {$value_slack_r == "INFINITY"} {continue}
		if {$value_slack_f == "INFINITY"} {continue}
		set value_slack      [expr {$value_slack_r < $value_slack_f ? $value_slack_r : $value_slack_f}]
		set name_ref         [get_attribute [get_cells -of $pin] ref_name]
		#lappend return_value [list $value_tran $name_ref $name_pin]
		puts $fid [format "%6.3f %6.3f %20s %s" $value_tran $value_slack $name_ref $name_pin]
	}
	close $fid
	#return $return_value
}


proc GET_BIGDELAY_NET { {pin_collection} {OUT_FILE "./BIGDELAY_NET.list"} {DELAY 0.2} {SLACK -0.1} } {
    set ::timing_save_pin_arrival_and_slack true
    set critical_pins [filter_collection $pin_collection "max_rise_slack < $SLACK || max_fall_slack < $SLACK "]
    set critical_pins [filter_collection $critical_pins "direction == in"]

    set result {}
    foreach_in_collection pin $critical_pins {
        if {[get_attribute $pin is_hierarchical] == "true"} { continue }
        if {[get_attribute -q $pin is_clock_used_as_clock] == "true"} { continue }
        set fall_slack [GET_MIN_VALUE_LIST [get_attribute -quiet $pin max_fall_slack]]
        set rise_slack [GET_MIN_VALUE_LIST [get_attribute -quiet $pin max_rise_slack]]
        set fall_tran [GET_MAX_VALUE_LIST [get_attribute -quiet $pin actual_fall_transition_max]]
        set rise_tran [GET_MAX_VALUE_LIST [get_attribute -quiet $pin actual_rise_transition_max]]

	set rise_delay_list [get_attri [get_timing_arcs -to $pin]  delay_max_rise]
	set fall_delay_list [get_attri [get_timing_arcs -to $pin]  delay_max_fall]
        set rise_delay [lindex $rise_delay_list [expr [llength $rise_delay_list] -1]]
        set fall_delay [lindex $fall_delay_list [expr [llength $fall_delay_list] -1]]

        set _slack    [GET_MIN_VALUE $rise_slack $fall_slack]
        set net_delay [GET_MAX_VALUE $rise_delay $fall_delay]
        set tran_time [GET_MAX_VALUE $rise_tran $fall_tran]
        set fanout_num [sizeof_collection [get_pins [all_connected -l [all_connected $pin]] -filter "direction==in"]]

        if { $_slack > $SLACK }    {continue}
        if { $net_delay < $DELAY } {continue}

        set drive_pin [get_pins [all_connected -l [all_connected $pin]] -filter "direction==out"]
        set drive_cell [get_attribute [get_cells -of $drive_pin] ref_name]

        lappend result "[get_object_name $pin] $_slack $net_delay $tran_time $drive_cell [get_object_name $drive_pin] $fanout_num"
    }
    set OUTFILE [open "|gzip -c > ${OUT_FILE}.gz" w]
    puts $OUTFILE "##PIN_NAME slack net_delay tran drive_cell drive_pin fanout"
    foreach tmp [lsort -index 1 -decreasing $result] {
        puts $OUTFILE "$tmp"
    }
    close $OUTFILE
}
proc GET_MAX_VALUE_LIST {VALUE_LIST} {
	set i 0
	set MAX_VALUE -1000000.000
	set LENGTH [llength $VALUE_LIST]
	foreach VALUE $VALUE_LIST {	
		set VALUE_CURRENT [lindex $VALUE_LIST $i] 
		if {$VALUE_CURRENT > $MAX_VALUE} {
			set MAX_VALUE $VALUE_CURRENT
		}
		incr i
	}
	return $MAX_VALUE
}

proc GET_MIN_VALUE_LIST {VALUE_LIST} {
        set i 0
        set MIN_VALUE 1000000.000
        set LENGTH [llength $VALUE_LIST]
        foreach VALUE $VALUE_LIST {
                set VALUE_CURRENT [lindex $VALUE_LIST $i]
                if {$VALUE_CURRENT < $MIN_VALUE} {
                        set MIN_VALUE $VALUE_CURRENT
                }
                incr i
        }
        return $MIN_VALUE
}


proc GET_MAX_VALUE { {VALUE1} {VALUE2} } {
	if {$VALUE1 > $VALUE2} {
		return $VALUE1
	} else {
		return $VALUE2
	}
}

proc GET_MIN_VALUE { {VALUE1} {VALUE2} } {
	if {$VALUE1 > $VALUE2} {
		return $VALUE2
	} else {
		return $VALUE1
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


################################################################################
# Proc : READ_SPECIAL_OCV
#   read ocv value for special library.
################################################################################
proc READ_SPECIAL_OCV {} {
        if {![info exists ::special_ocv_param_table]} {
                puts "* Information : OCV parameter table for special cells \"special_ocv_param_table\" is not defined in design.info file."
		return
        }

        puts ""
        foreach list $::special_ocv_param_table {
                if {[llength $list] != 5} {
                        puts "* Error : lack of item(s). at \"$list\""
                        exit 1
                }

		# check STA condition
		if { ${::CONDITION} != [lindex $list 0] || ${::DELAY} != [lindex $list 1]} {continue}

                set cond_delay "[lindex $list 0],[lindex $list 1]"
                eval "set libs \$::[lindex $list 2]"
                set derate_cell_early       [lindex $list 3]
                set derate_cell_late        [lindex $list 4]

                if {![info exists ::special_ocv_param_list($cond_delay)]} {
                        set ::special_ocv_param_list($cond_delay) {}
                }
		foreach lib $libs {
                set ::special_ocv_param_list($cond_delay) [concat \
                                $::special_ocv_param_list($cond_delay) \
                              [list [list $lib $derate_cell_early $derate_cell_late]] \
                              ]
		}
        }
	# check ocv parameters
	if {![info exists ::special_ocv_param_list]} {
		puts "* Error : No OCV parameter found in special OCV table. Check table for \"${::CONDITION}\", \"${::DELAY}\" "
		exit 1
	}
        # << ouput ocv parameters >>
        puts "* Information : special ocv parameter settings."
        foreach item [lsort [array names ::special_ocv_param_list]] {
                set elm [split $item ","]
                foreach item2 $::special_ocv_param_list($item) {
                        puts "[lindex $elm 0]\t [lindex $elm 1]\t $item2"
                }
        }
        puts ""
        return 0

} ;# end proc

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

    set head {set_false_path -from [get_clock }
    set middle1 {] -through [get_ports }
    set middle2 {] -through [get_pins -l -of [get_nets }
    set tail {] -filter "direction==out"]}
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

    set head {set_false_path -through [get_pins -l -of [get_nets }
    set middle1 {] -filter "direction==in"] -through [get_ports }
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

proc LIST_OR {{LIST_A} {LIST_B}} {
	
	if {[llength $LIST_A] > [llength $LIST_B]} {
		set returnvalue $LIST_A
		foreach list_B $LIST_B {
			if {[lsearch $LIST_A $list_B]==-1} {
				lappend returnvalue $list_B
			}
		}
	} else {
		set returnvalue $LIST_B
		foreach list_A $LIST_A {
			if {[lsearch $LIST_B $list_A]==-1} {
				lappend returnvalue $list_A
			}
		}
	}
	return $returnvalue
}

proc LIST_AND {{LIST_A} {LIST_B}} {

	set returnvalue {}
	if {[llength $LIST_A] > [llength $LIST_B]} {
		foreach list_B $LIST_B {
			if {[lsearch $LIST_A $list_B]!=-1} {
				lappend returnvalue $list_B
			}
		}
	} else {
		foreach list_A $LIST_A {
			if {[lsearch $LIST_B $list_A]!=-1} {
				lappend returnvalue $list_A
			}
		}
	}
	return $returnvalue
}

proc REMOVE_FROM_LIST {{LIST_A} {LIST_B}} {
	
	set returnvalue {}
	foreach list_A $LIST_A {
		if {[lsearch $LIST_B $list_A]==-1} {
			lappend returnvalue $list_A
		}
	}
	return $returnvalue
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

proc ERROR_FILE { PARAMETER } {
        if {[eval "info exists ::$PARAMETER"]} {
                puts "* Information : PARAMETER '$${PARAMETER}' has been detected."
                set FILENAME [subst "\$::$PARAMETER"]
                #puts "* File_Name is $FILENAME"
                if {![file exists $FILENAME]} {
                        puts "* Error : '${FILENAME}' : No such file or directory"
                        exit
                } else {
                        puts "* Information : File '${FILENAME}' is ready."
                }
        } else {
                puts "* Information : PARAMETER '$${PARAMETER}' is not used in this job."
        }
}
proc ERROR { PARAMETER } {
        puts "* Error : You must define parameter '$PARAMETER' in 'go*'."
        if {$PARAMETER == "LOAD_MODEL"} {
                set ::LOAD_MODEL "NO_LOAD"
        } else {
                exit
        }
}
proc const {name value} {
  uplevel 1 [list set $name $value]
  uplevel 1 [list trace add variable $name write "error const ;#"]
  uplevel 1 [list trace add variable $name read "set $name [list $value] ;#"]
}

proc SET_INIT_VAR {{PARAM} {VALUE}} {
        if {[info exists ::$PARAM]} {
                set VALUE [subst $[subst ::$PARAM]]
                puts "'job_table.cfg' : ${PARAM}($VALUE)"
        } else {
                puts "set $PARAM $VALUE"
                eval "set ::$PARAM $VALUE"
        }
}


### 20140128: Create new ###
proc make_keep_list { {FILE_NAME} } {
	set LIST ""
        set fid [open $FILE_NAME]
        while {[gets $fid str]>=0} {
                        regsub -all {\ \{} $str { } str
                        regsub -all {\}\]} $str {} str
                if {[regexp {^#} $str]} {continue}
		for {set i 0} {$i < [llength $str]} {incr i} {
			set NAME [lindex $str $i]
			if {[regexp "\/" $NAME]} {
				#echo $NAME
				set N_CLK	[sizeof_collection [get_clock -q $NAME]]
				set N_PIN	[sizeof_collection [get_pins -q $NAME]]
				set N_CELL	[sizeof_collection [get_cells -q $NAME]]
				if {($N_CLK == 0) && ($N_PIN ==0) && ($N_CELL==0)} {
					echo "#Error: Can not find in design: $NAME"
					set NAME ""
				} elseif {$N_CLK == 1} {
					echo "#Skip: This is the clock name: $NAME"
					set NAME ""
				} elseif {$N_PIN == 1} {
					set NAME [get_object_name [get_cell -of $NAME]]
				} elseif {$N_CELL == 1} {
					# Do nothing
				} else {
					echo "#Error: Unknown"
				}
				lappend LIST $NAME
			}
        	}
	}
	set LIST [lsort -unique $LIST]
	COL2DISP [get_cells $LIST]
}

proc bkTraceWhyPropagate {{PIN}} {
	suppress_message {UIAT-4}
	define_user_attribute -class pin -type string is_already_trace
	unsuppress_message {UIAT-4}

	bkTraceWhyPropagate_main $PIN

	remove_user_attribute -q [get_pins * -h -filter is_already_trace==true] is_already_trace
}

proc bkTraceWhyPropagate_main {{PIN} {TAB {}} } {
	suppress_message {ATTR-3}
	set TAB "${TAB}    "
	#set DRVpin [get_pins -of [get_nets -of [get_pins $PIN]] -filter {pin_direction==out&&is_hierarchical==false}]
	set DRVnet [get_nets -of [get_pins $PIN]]
	set DRVpin [get_pins -of $DRVnet -leaf -filter {pin_direction==out&&is_hierarchical==false}]
	set Cvalue [get_attribute $DRVpin case_value]
	set Cconst [get_attribute $DRVpin constant_value]
	set nameDRVpin [get_object_name $DRVpin]
	if {$Cconst != ""} {
		set VALUE "T$Cconst"
	} elseif {$Cvalue != ""} {
		set VALUE "C$Cvalue"
	} else {
		set VALUE "--"
	}

	# check combinational
	if {[get_attribute [get_cells -of $DRVpin] is_combinational]==false} {
		puts "$TAB <= ($VALUE) $nameDRVpin <<STOP>>"
		return
	} else {
		puts "$TAB <= ($VALUE) $nameDRVpin"
	}
	set INpins [get_pins -of [get_cells -of $DRVpin] -filter pin_direction==in]
	foreach_in_collection pin $INpins {
		set Cvalue    [get_attribute $pin case_value]
		set Cconst    [get_attribute $pin constant_value]
		set nameINpin [get_object_name $pin]

		# Check Loop
		set chkPIN     [get_attribute -q [get_pins $pin] is_already_trace]
		if {$chkPIN==true} { puts "${TAB} $nameINpin    ### <<< loop >>>" ; return }

		if {$Cconst != ""} {
			set VALUE "T$Cconst"
		} elseif {$Cvalue != ""} {
			set VALUE "C$Cvalue"
		} else {
			set VALUE "--"
			puts "$TAB <= ($VALUE) $nameINpin"
			continue
		}
		puts "$TAB <= ($VALUE) $nameINpin"
		set_user_attribute -q $pin is_already_trace true
		bkTraceWhyPropagate_main $pin $TAB
	}
	unsuppress_message {ATTR-3}
}
proc bkTraceWhyNoPropagate {{PIN}} {
	suppress_message {UIAT-4}
	define_user_attribute -class pin -type string is_already_trace
	unsuppress_message {UIAT-4}

	bkTraceWhyNoPropagate_main $PIN

	remove_user_attribute -q [get_pins * -h -filter is_already_trace==true] is_already_trace
}
proc bkTraceWhyNoPropagate_main {{PIN} {TAB {}} } {
	suppress_message {ATTR-3}
	set TAB "${TAB}    "
	#set DRVpin [get_pins -of [get_nets -of [get_pins $PIN]] -filter {pin_direction==out&&is_hierarchical==false}]
	set DRVnet [get_nets -of [get_pins $PIN]]
	set DRVpin [get_pins -of $DRVnet -leaf -filter {pin_direction==out&&is_hierarchical==false}]
	set Cvalue [get_attribute $DRVpin case_value]
	set Cconst [get_attribute $DRVpin constant_value]
	set nameDRVpin [get_object_name $DRVpin]
	if {$Cconst != ""} {
		set VALUE "T$Cconst"
	} elseif {$Cvalue != ""} {
		set VALUE "C$Cvalue"
	} else {
		set VALUE "--"
	}

	# check combinational
	if {[get_attribute [get_cells -of $DRVpin] is_combinational]==false} {
		puts "$TAB <= ($VALUE) $nameDRVpin <<STOP>>"
		return
	} else {
		puts "$TAB <= ($VALUE) $nameDRVpin"
	}
	set INpins [get_pins -of [get_cells -of $DRVpin] -filter pin_direction==in]
	foreach_in_collection pin $INpins {
		set Cvalue    [get_attribute $pin case_value]
		set Cconst    [get_attribute $pin constant_value]
		set nameINpin [get_object_name $pin]
		if {$Cconst != ""} {
			set VALUE "T$Cconst"
		} elseif {$Cvalue != ""} {
			set VALUE "C$Cvalue"
		} else {
			set VALUE "--"
		}
		puts "$TAB    ($VALUE) $nameINpin"
		#bkTrace $pin $TAB
	}
puts {}
	foreach_in_collection pin $INpins {
		set Cvalue    [get_attribute $pin case_value]
		set Cconst    [get_attribute $pin constant_value]
		set nameINpin [get_object_name $pin]

		# Check Loop
		set chkPIN     [get_attribute -q [get_pins $pin] is_already_trace]
		if {$chkPIN==true} { puts "${TAB} $nameINpin    ### <<< loop >>>" ; return }

		if {$Cconst != ""} {
			set VALUE "T$Cconst"
			continue
		} elseif {$Cvalue != ""} {
			set VALUE "C$Cvalue"
			continue
		} else {
			set VALUE "--"
		}
		puts "$TAB <= ($VALUE) $nameINpin"
		set_user_attribute -q $pin is_already_trace true
		bkTraceWhyNoPropagate_main $pin $TAB
	}
	unsuppress_message {ATTR-3}
}


proc APPEND_FILE {{INF} {OUTF}} {
   global APPLY_DIR
   global APPEND_FILE_SOURCELIST
   if {![info exists APPEND_FILE_SOURCELIST] } {
   	set APPEND_FILE_SOURCELIST {}
   }

   set outf  [open $OUTF "a+"]
   
   if ([file exist $INF]) {
	set inf  [open $INF]
	while { [gets $inf str] >= 0} {
		if { [regexp "^ *source " $str] } {
			if {![regexp {^-} [lindex $str 1]]} {
				set newf [lindex $str 1]
			} elseif {![regexp {^-} [lindex $str 2]]} {
				set newf [lindex $str 2]
			} elseif {![regexp {^-} [lindex $str 3]]} {
				set newf [lindex $str 3]
			} else {
				set newf "Error_NOFile"
			}
			set newf [subst $newf]
			puts $outf "#$str"
			if { [lsearch $APPEND_FILE_SOURCELIST $newf] ==-1 } {
				puts $outf "## APPEND_FILE:begining of $newf"
				lappend APPEND_FILE_SOURCELIST $newf

				close $outf
				APPEND_FILE $newf $OUTF
   				set outf  [open $OUTF "a+"]
				puts $outf "## APPEND_FILE:end of $newf"
			} else {
				puts $outf "## APPEND_FILE:$newf is already added"
			}

		} else {
			puts $outf "$str"
		}
	}
	close $inf
	close $outf
   } else {
	puts "Error: No $INF"
   }
}


proc READ_PTECO_INFO_FROM_DESIGN_CFG {} {
        global pteco_param_list
        if {![info exists ::pteco_param_table]} {
                puts "* Error : PTECO parameter table \"pteco_param_table\" not defined in design.info file."
        exit
        }

        puts ""
        if {[info exists pteco_param_list]} {
                puts "* Information : PTECO pteco_param_list is reset."
                unset pteco_param_list
        }
        foreach list $::pteco_param_table {
                if {[llength $list] != 5 && [llength $list] != 6} {
                        puts "* Error : lack of item(s)."
                        puts "       at : $list"
                        exit
                }

                # check list item value
                foreach item [lrange $list 0 4] {
                        if {![regexp {^\w+$} $item]} {
                                puts "* Error : Key word error. \"$item\" in \"$list\""
                                exit
                        }
                }

                lappend pteco_param_list "[lindex $list 0],[lindex $list 1],[lindex $list 2],[lindex $list 3],[lindex $list 4],[lindex $list 5],"
        }
        if {![info exists pteco_param_list]} {
                puts "* Error : Cannot read PTECO parameter(s)."
        #        exit
        }


        # output PTECO parameters
        puts "* Information : PTECO Parameter Settings."
        puts "CONDITION  (SETUP/HOLD) VDD_CORE  STA_MODE  DFT_MODE ADD_CONST"
        foreach item $pteco_param_list {
                set elm [split $item ","]
                puts -nonewline [format { %-12s} [lindex $elm 0]]
                puts -nonewline [format { %-10s} [lindex $elm 1]]
                puts -nonewline [format { %-8s}  [lindex $elm 2]]
                puts -nonewline [format { %-10s} [lindex $elm 3]]
                puts -nonewline [format { %-8s}  [lindex $elm 4]]
                puts            [format { %-8s}  [lindex $elm 5]]
        }
        puts ""
        return 0
}


proc chkMACRO_type {{PIN_COLLECTION}} {
	set pins  [get_pins $PIN_COLLECTION]
	set cells [get_cells -of $pins]
	set refs  [get_attribute $cells ref_name]
	COUNT_REF $refs
}

proc COUNT_REF {{LIST_TGT}} {
	set TYPE_LIST {}
	foreach tmp $LIST_TGT {
		if {[lsearch $TYPE_LIST $tmp] == -1} {
			lappend TYPE_LIST $tmp
			set num($tmp) 1
		} else {
			incr num($tmp)
		}
	}
	foreach tmp $TYPE_LIST {
		puts [format "%7d %s" $num($tmp) $tmp]
	}
}


proc mkMPI_const {{ROOT "TEST_TOP/ACBISTDFTP"} {outfile "SCAN_MPI.ptsc"}} {
	set chkValue  1
	set ROOT      [get_pins $ROOT]
	set MPI_cells [get_cells -h HT_MPI_*]
	set MPI_cntrl [get_pins -o $MPI_cells -filter lib_pin_name=="A"]
	set_case_analysis $chkValue [get_pins $ROOT]

	set fid  [ open $outfile w ]
	puts $fid "#########################################"
	puts $fid "## SCAN_MPI.ptsc [date]"
	puts $fid "## Total MPI     [sizeof_collection $MPI_cells]"
	puts $fid "#########################################"
	set nu 1
	foreach_in_collection chkPIN $MPI_cntrl {
		set chk [get_attribute $chkPIN case_value]
		if {$chk == $chkValue} {
			set outpin [get_object_name [get_pins -of [get_cells -of $chkPIN] -filter pin_direction==out]]
			puts "* OK($nu) : $outpin"
			puts $fid "set_false_path -from \[get_clocks LB_AC1_*\] -thr $outpin"
		} else {
			# NG
			puts "# Error($nu): $chk(Not $chkValue) [get_object_name $chkPIN]"
			puts $$fid "# Error: $chk(Not $chkValue) [get_object_name $chkPIN]"
		}
		set outpin ""
		set chk ""
		incr nu
	}	
	close $fid
}


proc chkCLK {} {
set clocks [get_clocks]
foreach_in_collection tmp $clocks {
	set peri [get_attribute $tmp period]
	set MHZ  [expr 1 / $peri * 1000]
	set name [get_object_name $tmp]
	puts [format "%6.2f %s" $MHZ $name]
}
}
proc chkMEM_CLK {{LIBNAME {jk*_* Amcip*}}} {
	set REFS [get_attribute [get_lib_cells -of [get_libs $LIBNAME]] base_name]
	
	foreach ref $REFS {
		puts "* $ref"
		set CELLS [get_cells -q -h * -filter ref_name==$ref]

		foreach_in_collection cell $CELLS {
			set PINclk [get_pins -of $cell -filter is_clock_pin==true]
			foreach_in_collection pin $PINclk {
				set CLKSTA [get_object_name [get_attribute $pin clocks]]
				puts "	([get_attribute $pin lib_pin_name]) \{$CLKSTA\} [get_object_name $cell]"
			}
		}
	}
}
proc chkMBISTclkSTOP {} {
	set CGG_GTD [get_cells sys_top/sysvdd/cggtop/gck*/gck]	
	foreach_in_collection tmp $CGG_GTD {
		set GTDoutnet [get_object_name [get_nets -of [get_pins -of $tmp -filter lib_pin_name=="GCLK"]]]
		set clkName   [get_object_name [get_nets -of [get_pins $GTDoutnet]]]
		set inCLK     [get_object_name [get_pins -of $tmp -filter lib_pin_name=="CLK"]]
		#puts "* $inCLK ;# $clkName"
		if {[regexp {_mbist} $clkName]} {
			puts "# active clock ;# $inCLK ;# $clkName"
		} else {
			puts "set_clock_sense -stop_propagation \[get_pins $inCLK\] ;# $clkName"
		}
	}
}
proc chkFieldMBISTclkSTOP {} {
	set CGG_GTD [get_cells sys_top/sysvdd/cggtop/gck*/gck]	
	foreach_in_collection tmp $CGG_GTD {
		set GTDoutnet [get_object_name [get_nets -of [get_pins -of $tmp -filter lib_pin_name=="GCLK"]]]
		set clkName   [get_object_name [get_nets -of [get_pins $GTDoutnet]]]
		set inCLK     [get_object_name [get_pins -of $tmp -filter lib_pin_name=="CLK"]]
		#puts "* $inCLK ;# $clkName"
		if {[regexp {_mbist} $clkName]} {
			puts "# active clock ;# $inCLK ;# $clkName"
		} else {
			puts "set_clock_sense -stop_propagation -clock \[get_clocks FB_M_*\] \[get_pins $inCLK\] ;# $clkName"
		}
	}
}

proc readMEGMIcsv {{FILE "/design01/rh850d4_me/01_DFT/01_D4/v004_scaap/30_MBIST/02_MBIST/03_MEGMI.reGroup/CSV_fin_mod.csv"} {instWBST "MB_MINORI_WBIST"} {CHECK true}} {
# This is the format of MEGMI file.
# 0: No
# 1: memID
# 2: ApgGr
# 3: EncGr
# 4: RamGr
# 5: RepairGr1
# 6: RepairGr2
# 7: FuseRegGr
# 8: NMA1Gr
# 9: NMA2Gr
#10: FoutGr
#11: Instance
#12: Module
#13: Type
#14: Words
#15: Bits
#16: X_addr
#17: Y_addr
#18: X_size
#19: Y_size
#20: Repair
#21: Clk1
#22: Clk2
#23: MB_CLK
#24: Nma
#25: Rs
#26: Bwn
#27: Fbm
#28: Test
#29: Xaxis
#30: Yaxis
#31: Domain
#32: Cap
#33: Disturb
#34: Fav
#35: PwsTep
#36: PVname
#37: layername
#38: FoutBufPlace
#39: MemE
	set fid [open $FILE "r"]
	while {[gets $fid str]>=0} {
		if {[regexp {No} $str]} {continue}
		set INFO  [split $str ","]
		set NO        [lindex $INFO 0]
		set ApgGr     [lindex $INFO 2]
		set EncGr     [lindex $INFO 3]
		set RamGr     [lindex $INFO 4]
		set RepairGr1 [lindex $INFO 5]
		set RepairGr2 [lindex $INFO 6]
		set FuseRegGr [lindex $INFO 7]
		set Type      [lindex $INFO 13]
		set MB_CLK    [lindex $INFO 23]
		set Instance  [lindex $INFO 11] ;# MB_ApgGr2_MB_CLKH_apg 
		set tmpModule [lindex $INFO 12]
		if {$Type == "SP"} {set Type "spram"}
		if {$Type == "DP"} {set Type "dpram"}
		if {$Type == "ROM"} {set Type "rom"}
		set ENCTL [format "%04d" $EncGr]
		set BRIDG [format "%04d" $RamGr]
		set INST  [lindex [split $Instance "."] 0]
		regsub -all {\.} $Instance {/} RAM
		set tmpMACRO [get_cells -q ${RAM}/i*/i*]
		if {$tmpMACRO == ""} {
			set MACRO [get_object_name [get_cells -q ${RAM}/*/* -filter ref_name=~"Amc*"]]
		} else {
			set MACRO [get_object_name $tmpMACRO]
		}
		set Module "[string range $tmpModule 0 [expr [string length $tmpModule] - 2]]*"
		set instApg   [get_object_name [get_cells -h "MB_ApgGr${ApgGr}_${MB_CLK}_apg"]]
		set instEncGr [get_object_name [get_cells -h "MB_ApgGr${ApgGr}_${MB_CLK}_Enctrl${ENCTL}_enctrl_${Type}_vmc_pl"]]
		set instRamGr [get_object_name [get_cells -h "MB_ApgGr${ApgGr}_${MB_CLK}_Bridge${BRIDG}_*"]]
		set REF       [get_attribute [get_cells $MACRO] ref_name]
		puts {}
		puts "##############################################################################################"
		puts "# ($NO)"
		puts "# Apg  ([format "%3d" $ApgGr]): $instApg"
		puts "# EncGr([format "%3d" $EncGr]): $instEncGr"
		puts "# RamGr([format "%3d" $RamGr]): $instRamGr"
		puts "# macro     : ${MACRO} ($REF)"
		set pinCLOCKS [get_object_name [get_pins ${MACRO}/* -filter is_clock_pin==true]]
		foreach pin $pinCLOCKS {
			set CLOCKS    [get_object_name [get_attribute [get_pins $pin] clocks]]
			puts "# MB_CLK    : ${pinCLOCKS} ($CLOCKS)"
		}
		puts "##############################################################################################"

		if {$CHECK == "true"} {
		# REPORT #
		set clkWBT [get_clocks MB_DC_TT_TR]
		set st_WBT [get_pins -of [get_cells ${instWBST}/*/* -filter is_sequential==true] -filter pin_direction==out]
		set ed_WBT [get_pins -of [get_cells ${instWBST}/*/* -filter is_sequential==true] -filter is_data_pin==true]
		set st_Apg [get_pins -of [get_cells ${instApg}/*    -filter is_sequential==true] -filter pin_direction==out]
		set ed_Apg [get_pins -of [get_cells ${instApg}/*    -filter is_sequential==true] -filter is_data_pin==true]
		set st_Enc [get_pins -of [get_cells ${instEncGr}/*  -filter is_sequential==true] -filter pin_direction==out]
		set ed_Enc [get_pins -of [get_cells ${instEncGr}/*  -filter is_sequential==true] -filter is_data_pin==true]
		set st_Brg [get_pins -of [get_cells ${instRamGr}/*  -filter is_sequential==true] -filter pin_direction==out]
		set ed_Brg [get_pins -of [get_cells ${instRamGr}/*  -filter is_sequential==true] -filter is_data_pin==true]
		set st_RAM [get_pins -of [get_cells ${MACRO}        -filter is_sequential==true] -filter pin_direction==out]
		set ed_RAM [get_pins -of [get_cells ${MACRO}        -filter is_sequential==true] -filter is_data_pin==true]
		#------
		set timing_report_unconstrained_paths false
		# WBIST -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> Apg ($clk)"
		}
		# WBIST -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> EncGr ($clk)"
		}
		# WBIST -> RamGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> RamGr ($clk)"
		}
		# WBIST -> MACRO
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> MACRO ($clk)"
		}
		#------
		# Apg -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_Apg -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> WBIST ($clk)"
		}
		# Apg -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Apg -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> EncGr ($clk)"
		}
		# Apg -> RamGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Apg -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> RamGr ($clk)"
		}
		# Apg -> MACRO
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Apg -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> MACRO ($clk)"
		}

		#------
		# EncGr -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_Enc -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> WBIST ($clk)"
		}
		# EncGr -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Enc -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> Apg ($clk)"
		}
		# EncGr -> RamGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Enc -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> RamGr ($clk)"
		}
		# EncGr -> MACRO
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Enc -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> MACRO ($clk)"
		}

		#------
		# RamGr -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_Brg -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> WBIST ($clk)"
		}
		# RamGr -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Brg -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> Apg ($clk)"
		}
		# RamGr -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Brg -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> EncGr ($clk)"
		}
		# RamGr -> RAM(ROM)
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Brg -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> MACRO ($clk)"
		}

		#------
		# RAM(ROM) -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_RAM -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> WBIST ($clk)"
		}
		# RAM(ROM) -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_RAM -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> Apg ($clk)"
		}
		# RAM(ROM) -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_RAM -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> EncGr ($clk)"
		}
		# RAM(ROM) -> Brg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_RAM -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> RamGr ($clk)"
		}
		#------
		}

	}
	close $fid
}

proc chkMACROcase {{INST}} {
        suppress_message {ATTR-3}
	puts "-------------------------------------------"
	puts "T0: Tied 1'b0(Vss)"
	puts "T1: Tied 1'b1(Vdd/Vss)"
	puts "C0: Propagated case value '0'"
	puts "C1: Propagated case value '1'"
	puts "-------------------------------------------"
	puts [format " (%s) %-8s %s" case Direction MacroPIN]
	set MACROinst [get_cells $INST]
	set MACROpins [get_pins -of $MACROinst]
        foreach_in_collection pin $MACROpins {
		set Direction [get_attribute $pin pin_direction]
                set Cvalue    [get_attribute $pin case_value]
                set Cconst    [get_attribute $pin constant_value]
                set nameINpin [get_object_name $pin]
                if {$Cconst != ""} {
                        set VALUE "T$Cconst"
                } elseif {$Cvalue != ""} {
                        set VALUE "C$Cvalue"
                } else {
                        set VALUE "--"
                }
                puts [format "   (%s) %-8s %s" $VALUE $Direction $nameINpin]
        }
	puts "-------------------------------------------"
        unsuppress_message {ATTR-3}
}


## For checking clocks have reached, MBIST circuit and RAM.
proc CHK_REACHE_CLK { args }  {
    set FILE_A [lindex $args 0]
    set FILE_B [lindex $args 1]
    if {$FILE_A == "" || $FILE_B == ""} {
            puts "Usage: CHK_REACHE_CLK <PIN_LIST_FILE> <OUTPUT_REPORT>"
            return 0
    }
    
    set PIN_LIST {}
    if {[file isfile ${FILE_A}] == 0} {
            puts "Error : There is no '$FILE_A'... "
    } else {
            puts "* Information : Loading pin file '$FILE_B' for cheking clock_name..."
            set fid_a  [open "$FILE_A"]
            while {[gets $fid_a str]>=0} {
                    if {$str != ""} {
                            set tmpA [lindex [split $str ","] 0]
                            lappend PIN_LIST $tmpA
                    }
            }
            close $fid_a
    }
    
    puts "* Information : Analyzing clock_name..."
    set fid_b [open "$FILE_B" "w"]
    foreach A $PIN_LIST {
            set pin_name [get_pins $A -quiet]
            if {[llength $pin_name] == 0} {
                    puts "Error: $A is not found..."
                    puts $fid_b "$A,_NOPIN_"
                    continue;
            }
            set clock_name [get_attribute $pin_name clocks -quiet]
            if {[llength $clock_name] == 0} {
                puts $fid_b "$A,_NOCLK_"
            } else {
                puts $fid_b "$A,[get_object_name $clock_name]"
            }
    }
    close $fid_b
    
}






proc CHK_CLKVT { {args} } {
    set FILE_A [lindex $args 0]
    set FILE_B [lindex $args 1]

    if {$FILE_A == "" || $FILE_B == ""} {
            puts "Usage: CHK_CLKVT <CONFIG_FILE> <OUTPUT_REPORT>"
            puts "  --sample of CONFIG file---"
            puts "  SKIP_PIN,*/CLK,Comments(FF/CLK pin)"
            puts "  SKIP_PIN,*/GT,Comments(DLAT/CLK pin)"
            puts "  NG,*/THH*"
            puts "  NG,*/TLH*"
            return 0
    }

    set NG_CELL_LIST {}
    set SKIP_PIN_LIST {}
    if {[file isfile ${FILE_A}] == 0} {
            puts "Error : There is no '$FILE_A'... "
    } else {
            puts "* Information : Loading config file '$FILE_A' ..."
            set fid_a  [open "$FILE_A"]
            while {[gets $fid_a str]>=0} {
                    if {$str != ""} {
                            set tmpA [lindex [split $str ","] 0]
                            set tmpB [lindex [split $str ","] 1]
                            if {[string match "NG" $tmpA]} {
                                 lappend NG_CELL_LIST $tmpB
                            } elseif {[string match "SKIP_PIN" $tmpA]} {
                                 lappend SKIP_PIN_LIST $tmpB
                            }
                    }
            }
            close $fid_a
            puts "Skip_Pin: $SKIP_PIN_LIST"
            puts "NG_CELL:  $NG_CELL_LIST"
    }

    puts "* Information: Analyzing clock line cell.."

    set OUTFILE [open "|gzip -c >  ./${FILE_B}.gz" w]

    ### Search clock pin from attribute
    set all_clockpins_obj [get_clock_network_objects -type pin]
    set all_clockpins_obj [get_pins $all_clockpins_obj -filter "is_hierarchical==false"]
    set all_clockpins_obj [get_pins $all_clockpins_obj -filter "is_clock_pin==true||is_clock_used_as_clock==true||is_clock_gating_pin==true"]

    ### Search clock pin from clock_timing report
    set TMPCLKPINS {}
    foreach_in_collection target_clock [get_clocks [all_clocks] -filter "is_generated==true"] {
	redirect -variable CLOCK_REPORT {report_clock_timing -type latency -clock [get_clocks $target_clock] -verbose -nosplit}
	set repflg 0
	for {set i 0} {$i < [llength $CLOCK_REPORT]} {incr i} {
	   set str [lindex $CLOCK_REPORT $i]
	   if {[string match  "-----*" $str] } {
		set repflg 1
	   }
	   if {$repflg == 0 || ! [string match "(*" $str] } {
		continue;
	   }
	   set before_string  [lindex $CLOCK_REPORT $i-1]
	   set before_string2 [lindex $CLOCK_REPORT $i-2]
	   if {[string match "(*" $before_string] || [string match "clock" $before_string2] } {
			continue;
	   }
	   set clockpin_obj [get_pins -q $before_string]
	   if {$clockpin_obj == ""} {
			# Reject Port
			continue;
	   }
	   if {[get_attribute -q $clockpin_obj is_clock_used_as_clock] != "true" && [get_attribute $clockpin_obj is_hierarchical] == "false"} {
		set TMPCLKPINS [add_to_collection $TMPCLKPINS $clockpin_obj -unique]
		#puts "[get_object_name $target_clock] [get_object_name $clockpin_obj]"
	   }
	}
    }
    ### End of Search clock pin from clock_timing report
    set all_clockpins_obj [add_to_collection $all_clockpins_obj $TMPCLKPINS -unique]
    
    foreach SKIP_PIN $SKIP_PIN_LIST {
    	set all_clockpins_obj [get_pins $all_clockpins_obj -filter "full_name!~$SKIP_PIN"]
    }
    foreach_in_collection pin [get_pins $all_clockpins_obj  ] {

         set pin_name [get_object_name $pin]
         set inst     [get_object_name [get_cells -of_obj [get_object_name $pin]]]

         set libcells [get_object_name [get_lib_cells -of_object $inst]]

         foreach NG_CELL $NG_CELL_LIST {
            if {[string match $NG_CELL $libcells] == 1 } {
                 if {[get_attribute $pin clocks -quiet] == ""} {
                     puts $OUTFILE "NG:$pin_name $libcells"
                 } else {
                     set clocks   [get_object_name [get_attribute $pin clocks]]
                     puts $OUTFILE "NG:$pin_name $libcells  $clocks"
                 }
            } else {
                 #set clocks   [get_object_name [get_attribute $pin clocks]]
                 #puts $OUTFILE "OK:$pin_name $libcells  $clocks"
            }
         }
    }

    close $OUTFILE 


}


proc TraceClock {{END}} {
        suppress_message {UIAT-4}
	define_user_attribute -class pin -type string is_already_trace
        unsuppress_message {UIAT-4}

	suppress_message {ATTR-3}
	set END   [get_pins $END]
	set CLOCKS [get_attribute $END clocks]
	foreach_in_collection clk $CLOCKS {
		set name_clk [get_object_name $clk]
		puts "****************************************************"
		puts " [get_object_name $END] $name_clk"
		TraceClock_main2 $END {} [get_object_name [get_attribute $clk sources]]
		puts {}
	}
	unsuppress_message {ATTR-3}
	remove_user_attribute -q [get_pins * -h -filter is_already_trace==true] is_already_trace
}

proc TraceClock_main2 {{PIN} {TAB {}} {CLK_ROOT}} {
        suppress_message {ATTR-3}
	set SPC ${TAB}
	set TAB "${TAB}  "
        set DRVnet     [get_nets -of [get_pins $PIN]]
        set DRVpin     [get_pins -of $DRVnet -leaf -filter {pin_direction==out&&is_hierarchical==false}]
        set nameDRVpin [get_object_name $DRVpin]
        set AttCLK     [get_attribute $DRVpin clocks -q]

        if {[sizeof_collection $AttCLK] == 0} {
		puts "$TAB $nameDRVpin --"
		return
        } else {
		set nameAttCLK [get_object_name $AttCLK]
		if {$nameDRVpin == $CLK_ROOT} {
                	puts "# $SPC $nameDRVpin {$nameAttCLK}"
		} else {
                	puts "$TAB $nameDRVpin {$nameAttCLK}"
		}
        }

        set INpins [get_pins -of [get_cells -of $DRVpin] -filter pin_direction==in]

        foreach_in_collection pin $INpins {
                set nameINpin  [get_object_name $pin]
		set AttCLK     [get_attribute $pin clocks -q]

		# Check Loop
		set chkPIN     [get_attribute -q [get_pins $pin] is_already_trace]
		if {$chkPIN==true} { puts "${TAB} $nameINpin	### <<< loop >>>" ; return }

        	if {[sizeof_collection $AttCLK] == 0} {
			puts "$TAB $nameINpin --"
			continue
		} else {
			set nameAttCLK [get_object_name $AttCLK]
			if {$nameINpin == $CLK_ROOT} {
				puts "# $SPC $nameINpin {$nameAttCLK}"
			} else {
				puts "$TAB $nameINpin {$nameAttCLK}"
			}
		}

		set_user_attribute -q $pin is_already_trace true
		TraceClock_main2 $pin $TAB $CLK_ROOT
        unsuppress_message {ATTR-3}

        }
        unsuppress_message {ATTR-3}
}

proc TraceClock_main {{PIN} {TAB {}}} {
        suppress_message {ATTR-3}
	set TAB "${TAB}  "
        set DRVnet     [get_nets -of [get_pins $PIN]]
        set DRVpin     [get_pins -of $DRVnet -leaf -filter {pin_direction==out&&is_hierarchical==false}]
        set nameDRVpin [get_object_name $DRVpin]
        set AttCLK     [get_attribute $DRVpin clocks -q]

        if {[sizeof_collection $AttCLK] == 0} {
		puts "$TAB $nameDRVpin --"
		return
        } else {
		set nameAttCLK [get_object_name $AttCLK]
                puts "$TAB $nameDRVpin {$nameAttCLK}"
        }

        set INpins [get_pins -of [get_cells -of $DRVpin] -filter pin_direction==in]
        foreach_in_collection pin $INpins {
                set nameINpin  [get_object_name $pin]
		set AttCLK     [get_attribute $pin clocks -q]

        	if {[sizeof_collection $AttCLK] == 0} {
			puts "$TAB $nameINpin --"
			continue
		} else {
			set nameAttCLK [get_object_name $AttCLK]
			puts "$TAB $nameINpin {$nameAttCLK}"
		}

		TraceClock_main $pin $TAB
        }
}

proc getCCports {} {
	suppress_message {ATTR-3}
	set tmp_ports [get_ports [get_attribute [get_clocks *] sources] -q]
	set return_value ""
	foreach_in_collection port $tmp_ports {
		set attribute [get_attribute $port clocks -q]
		if {[sizeof_collection $attribute]==0} {continue}
		set chkclk [get_clocks $attribute -filter is_generated!=true -q]
		if {[sizeof_collection $chkclk] > 0} {
			set return_value [add_to_collection $return_value $port]
		}
	}
	unsuppress_message {ATTR-3}
	set return_value [get_ports [lsort -dictionary -unique [COL2LIST $return_value]]]
	return $return_value
}

proc chkClockAsDataAll {} {
	###set PINALL [get_pins -h -filter {is_clock_used_as_data==true&&pin_direction==in}]
	###set PINALL [get_attribute  [get_clocks -filter is_generated==true] sources]
	set PINALL [get_attribute  [get_clocks *] sources]
	foreach_in_collection pin $PINALL {
		puts "-----------------------------------"
		puts "> [get_object_name $pin]"
		chkClockAsData $pin
	}
	puts "-----------------------------------"
}
proc chkClockAsDataAC {} {
	###set PINALL [get_pins -h -filter {is_clock_used_as_data==true&&pin_direction==in}]
	#set PINALL [get_attribute  [get_clocks -filter is_generated==true] sources]
	set PINALL [getCCports]
	foreach_in_collection pin $PINALL {
		puts "-----------------------------------"
		puts "> [get_object_name $pin]"
		chkClockAsData $pin
	}
	puts "-----------------------------------"
}
proc chkClockAsData {{PIN} {TAB {}}} {
        if {![string match "*/*" [get_object_name $PIN]]} {
		set PIN [get_object_name [remove_from_collection [all_con -l [all_con [get_ports $PIN]]] [get_ports $PIN]]]
        }
	set TAB     "$TAB  "
	set cell    [get_cells -of [get_pins $PIN]]
	set OUTpins [get_pins -of $cell -filter pin_direction==out]

	foreach_in_collection OUTpin $OUTpins {
		set INnet  [get_nets -of $OUTpin -q]
                if {$INnet == ""} {
			puts "-->No connection"
			 continue
		}
		set INpins [get_pins -of $INnet -leaf -filter pin_direction==in -quiet]
                if {$INpins == ""} { continue }
		foreach_in_collection INpin $INpins {
			set opt_string ""
			set clock [get_attribute $INpin clocks -q]
			set name  [get_object_name $INpin]

			set IO_PAD [get_pins -of [get_cells -of $INpin] -filter "pin_direction!=in&&lib_pin_name==PAD" -q]
			if {[sizeof_collection $IO_PAD]!=0} {
				set netIOPAD [get_nets -of $IO_PAD -segments -top_net_of_hierarchical_group]
				set IOPAD [get_object_name [get_ports -of $netIOPAD]]
				set opt_string "PAD($IOPAD)"
			}

			if {[sizeof_collection $clock] > 0} {
				set name_clk "	{ [get_object_name $clock] }"
			} else {
				set name_clk "========"
			}

			set flg "[chkClockAsData_main $INpin][chkClockAsClock_main $INpin]"
			switch $flg {
			11 {
				# Both
				puts "==DATA== ==CLK== $TAB $name $name_clk $opt_string"
				chkClockAsData $INpin $TAB
			}
			10 {
				# Clock As DATA
				puts "==DATA== ======= $TAB $name $name_clk $opt_string"
			}
			01 {
				# Clock As Clock
				puts "======== ==CLK== $TAB $name $name_clk $opt_string"
			}
			default {
			}
				puts "======== ======= $TAB $name $name_clk $opt_string"
			}
		}
	}
}

proc chkClockAsData_main {{PIN}} {
	if {[get_attribute [get_pins $PIN] is_clock_used_as_data -q] == "true"} {
		return 1
	} else {
		return 0
	}
}
proc chkClockAsClock_main {{PIN}} {
	if {[get_attribute [get_pins $PIN] is_clock_used_as_clock -q] == "true"} {
		return 1
	} else {
		return 0
	}
}


proc chkClkReconvPin {} {
   set ::timing_report_unconstrained_paths true
   puts "#------Clock reconvergence check----"
   foreach_in_collection inst [get_clock_network_objects -type cell] {
	set tmp_pins [get_object_name [get_pins -of [get_cells $inst] -filter "direction==in" -quiet]]
        if {[get_pins $tmp_pins -filter "is_clock_used_as_clock==true" -quiet] == "" } { continue }
	set in_pins [get_object_name [get_pins $tmp_pins -filter "is_clock_used_as_clock==true" -quiet]]
        if {[llength $in_pins] >= 2} {
	   set cell_clocks [get_object_name [get_attribute [get_pins $in_pins] clocks]]
	   set clock_num   [llength $cell_clocks]
           set matched_clocks {}
           for {set i 0} {$i<$clock_num} {incr i} {
		set clock_a [lindex $cell_clocks $i]
                for { set j 0 } {$j<$clock_num} {incr j} {
		    if { $i == $j } {
		    } else {
		    	set clock_b [lindex $cell_clocks $j]
		    	if {[string match $clock_a $clock_b]} {
				lappend matched_clocks $clock_a
				#puts "Reconvergence clock: $clock_a $in_pins"
		    	}
		     }
           	}
           }
	   set matched_clocks [lsort -unique $matched_clocks]
           foreach matched_clock $matched_clocks {
		set matched_pins {}
		foreach in_pin $in_pins {
		    set pin_clocks [get_object_name [get_attri [get_pins $in_pin] clocks]]
		    foreach pin_clock $pin_clocks {
		    	if {[string match $pin_clock $matched_clock]} {
			   set edge [chkClkEdge $matched_clock $in_pin]
			   if {![info exists edge1] } {
				set edge1 $edge
			   } else {
				set edge2 $edge
				if {[string match $edge1 $edge2]} {
					set comp_edge "SameEdge"
				} else {
					set comp_edge "Inverted"
				}
			   }
			   if {[string match "f" $edge] } {
				set inv "inv"
			   } else {
				set inv "-"
			   }
			   lappend matched_pins $in_pin
			   lappend printString "	PIN:$in_pin $inv"
			}
		    }
		}
		puts "CLK:$matched_clock @$comp_edge"
		foreach str $printString {
			puts "$str"
		}
		puts ""
		unset printString
		unset edge1
		unset edge2
		#puts "$matched_clock $matched_pins"
	   }
        }
    }
}

proc chkClkEdge { {SRC_CLK} {PROP_PIN} } {
    set Clock_Path [get_timing_path -rise_from [get_attr [get_clocks $SRC_CLK] sources] -th [get_pins $PROP_PIN]]
    redirect -variable stringCMD { report_timing -nosplit -net $Clock_Path }
    set count -1
    foreach str $stringCMD {
	if {[string match $PROP_PIN $str]} {
		set count 4
	} elseif { $count == 0 } {
		set count [expr $count - 1]
		return $str
	} elseif { $count > 0 } {
		set count [expr $count - 1]
	}
    }
}

proc GET_MINPULSE_MARGIN { {FILE_A} {TARGET_SLACK 0.015} } {

   if {![file exists $FILE_A]} {
	puts "$FILE_A is not found."
   } else {

	set FILE_EX_A [file extension $FILE_A]

#<< File Open with Check File Extention >>-------------------------------------#
	if {$FILE_EX_A == ".bz2"} {
		set fid_a  [open "|bzip2 -dc $FILE_A"]
	} elseif {$FILE_EX_A == ".gz"} {
		set fid_a  [open "|gzip -dc $FILE_A"]
	} else {
		set fid_a  [open $FILE_A]
	}


#------------------------------------------------------------------------------#
	set pflg          0

	while {[gets $fid_a str]>=0} {
		if {[string match "*------*" $str]} {
			set pflg 1
		} elseif {$str == ""} {
			set pflg 0
		} elseif {$pflg ==1} {
			if {[lindex $str 4] <= $TARGET_SLACK} {
				set pin   [lindex $str 0]
				set width [lindex $str 5]
				set slack [lindex $str 4]
				puts "## -----------------------------------"
				puts "##   Slack:$slack $width Pin:$pin"
				puts "## -----------------------------------"
				report_min_pulse_width [get_pins $pin] -path_type full_clock_expanded
			}
		}
	}
	close $fid_a
	puts "GET_MINPULSE_MARGIN SLACK:$TARGET_SLACK REPORT:$FILE_A done"
   }
}

proc CHK_HIGHFREQ_DONTUSE_PATH { {COLLECTION} {TARGET_PERIOD} } {
  global HIGHFREQ_DONUSE_NG_CELL
  global HIGHFREQ_DONUSE_OUT_MESSEAGE
  if {[sizeof_collection $COLLECTION] == 0} {return {}}
  foreach_in_collection target_path $COLLECTION {
	set start_edge_value [get_attribute -quiet $target_path startpoint_clock_open_edge_value]
	set end_edge_value   [get_attribute -quiet $target_path endpoint_clock_open_edge_value]
	set slack_value      [get_attribute $target_path slack]
	if { $slack_value == "INFINITY" } {
		set path_cycle       0
	} elseif {[info exist start_edge_value] && [info exist end_edge_value] && $start_edge_value !="" && $end_edge_value != ""} {
		set path_cycle       [expr $end_edge_value - $start_edge_value]
	} else {
		set start_latency    [get_attribute -quiet $target_path startpoint_clock_latency]
		set required_time    [get_attribute -quiet $target_path required]
		set setup_time       [get_attribute -quiet $target_path endpoint_setup_time_value]
		set recov_time       [get_attribute -quiet $target_path endpoint_recovery_time_value]
		set uncertainty      [get_attribute -quiet $target_path clock_uncertainty]
		if {![info exist start_latency] || $start_latency == ""} {
			set start_latency 0
		}
		if {![info exist setup_time] || $setup_time == "" } {
			set setup_time 0
		}
		if {![info exist recov_time] || $recov_time == "" } {
			set recov_time 0
		}
		if {![info exist uncertainty] || $uncertainty == "" } {
			set uncertainty 0
		}
		set path_cycle       [expr $required_time - $start_latency - $uncertainty + $setup_time + $recov_time]
	}
	if {$slack_value == "INFINITY"} {
		#puts "Skip slack is Infinity"
	} elseif {$path_cycle > $TARGET_PERIOD} {
		#puts "Skip report/cycle: $path_cycle:start: $start_edge_value, end:$end_edge_value";
	} else {
		#puts "cycle:$path_cycle start: $start_edge_value, end:$end_edge_value";
		foreach_in_collection pin_name [get_pins [get_attribute [get_attribute $target_path points] object]] {
			set inst_name [get_object_name [get_cells -of $pin_name]]
			set cell_name [get_attribute [get_cells $inst_name] ref_name ]
			if {[string match $HIGHFREQ_DONUSE_NG_CELL $cell_name] == 1 } {
				#puts "$cell_name $inst_name"
				lappend HIGHFREQ_DONUSE_OUT_MESSEAGE "$cell_name $inst_name"
			}  
		}
	}
  }
	
}

proc CHK_HIGHFREQ_DONTUSE_OUTREP { { OUT_MESSEAGE } {OUT_REP "null"} } {
   set OUT_MESSEAGE [lsort -dictionary -ascii -unique $OUT_MESSEAGE]
   if {$OUT_REP != "null"} {
	set fid [open $OUT_REP "w"]
	foreach line $OUT_MESSEAGE {
		puts $fid "$line"
	}
	close $fid
   } else {
	foreach line $OUT_MESSEAGE {
		puts "$line"
	}
   }
}

proc CHK_HIGHFREQ_DONTUSE { { OUT_REP "null" } {TARGET_PERIOD 2.800} } {
	#################
	## Made by Y.oda 2014/07/17
	#################
	global HIGHFREQ_DONUSE_NG_CELL
	global HIGHFREQ_DONUSE_OUT_MESSEAGE

	set TARGET_PERIOD2 [expr $TARGET_PERIOD * 2]; # for halfcycle
	set OneCycleClks   [get_clocks [all_clocks] -filter period<=$TARGET_PERIOD]
	set HalfCycleClks  [remove_from_collection [get_clocks [all_clocks] -filter period<=$TARGET_PERIOD2] $OneCycleClks]
	set max_target  200000
	set HIGHFREQ_DONUSE_NG_CELL     THH*
	set HIGHFREQ_DONUSE_OUT_MESSEAGE ""

	## ------- over 320MHz clocks ----------------
	## to over 320MHz clocks
	set target_paths [get_timing_paths -to [get_clocks $OneCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
	if {[sizeof_collection $target_paths] == $max_target} {
		puts " Error(CHK_HIGHFREQ_DONTUSE): Over $max_target paths reported in 320MHz"
	}
	CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD

	## from over 320MHz clocks
	set target_paths [get_timing_paths -from [get_clocks $OneCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
	if {[sizeof_collection $target_paths] == $max_target} {
		puts " Error(CHK_HIGHFREQ_DONTUSE): Over $max_target paths reported in 320MHz"
	}
	CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD


	## ------- over 160MHz clocks halfcycle --------
	## over 160MHz clocks with halfcycle fall_to
	set target_paths [get_timing_paths -fall_to [get_clocks $HalfCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
	if {[sizeof_collection $target_paths] == $max_target} {
		puts " Error(CHK_HIGHFREQ_DONTUSE): Over $max_target paths reported in 160MHz (fall_to)"
	}
	CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD

	## over 160MHz clocks with halfcycle fall_from
	set target_paths [get_timing_paths -fall_from [get_clocks $HalfCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
	if {[sizeof_collection $target_paths] == $max_target} {
		puts " Error(CHK_HIGHFREQ_DONTUSE): Over $max_target paths reported in 160MHz (fall_from)"
	}
	CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD

	## ------- Print output report ----------------
	CHK_HIGHFREQ_DONTUSE_OUTREP $HIGHFREQ_DONUSE_OUT_MESSEAGE $OUT_REP
}

proc mkEdtChainMask_2_1stSIN {} {
	set SCAN_IN       [get_pins -h {*/SIN */SI */SIA */SIB */ADSCAN_IN[*] */SYFP_SCANIN*_G} -filter is_hierarchical==false]
	set SIN_LIB_PIN   [lsort -u [get_attribute $SCAN_IN lib_pin_name]]
	set EDT_MASK_REG  [get_pins -h edt_chain_mask_reg_*/Q*]
		
	proc filter_SIN_only {{PIN_COL} {SIN_LIB_PIN}} {
		set return_value {}
		foreach_in_collection pin $PIN_COL {
			set lib_pin_name [get_attribute $pin lib_pin_name]
			if {[lsearch $SIN_LIB_PIN $lib_pin_name] >= 0} {
				#return $pin
				set return_value [add_to_collection $return_value $pin]
			}
		}	
		return $return_value
	}
	set NumEDT_MASK_REG [sizeof_collection $EDT_MASK_REG]
	set tmp [date]
	set Y [lindex $tmp 4]
	set M [lindex $tmp 1]
	set D [lindex $tmp 2]
	set T [lindex $tmp 3]
	set date "${Y}/${M}/${D} $T"
	puts "######################################"
	puts "# Generated by mkEdtChainMask_2_1stSIN"
	puts "#  $date"
	puts "#  edt_chain_mask_reg_* -> 1stFF/chain"
	puts "#  Number of edt_chain_mask_reg : $NumEDT_MASK_REG"
	puts "######################################"
	set NumDummyChain  0
	set NumNormalChain 0
	set NumZeroFFChain 0
	set NumErrorChain  0
	set NormalChain_LIST {}
	set ZeroChain_LIST   {}
	set DummyChain_LIST  {}
	set ErrorChain_LIST  {}
	foreach_in_collection pin $EDT_MASK_REG {
		set st_clk        [get_pins -of [get_cells -of $pin] -filter is_clock_pin]
		set ALL_FOUT_LEAF [all_fanout -from $pin -flat -endpoints_only] 
		set SIN_COLL      [filter_SIN_only $ALL_FOUT_LEAF $SIN_LIB_PIN]
		set num_SIN_COLL  [sizeof_collection $SIN_COLL]
		set st_name       [get_object_name $st_clk]
		set st_name_q     [get_object_name $pin]
		set ed_name       [get_object_name $SIN_COLL]
		set string_N "set_false_path -from \[get_pins $st_name\] -to \[get_pins \{$ed_name\}\]"

		if {$num_SIN_COLL == 1} {
			incr NumNormalChain
			lappend NormalChain_LIST $string_N
		} elseif {$num_SIN_COLL == 2} {
			incr NumDummyChain
			lappend DummyChain_LIST $st_name_q
			set DummyChain($st_name_q) $string_N
		} elseif {$num_SIN_COLL == 0} {
			incr NumZeroFFChain
			lappend ZeroChain_LIST $st_name_q
		} else {
			incr NumErrorChain
			lappend ErrorChain_LIST $st_name_q
			set ErrorChain($st_name_q) $ed_name
		}
		#puts "set_false_path -from \[get_pins $st_name\] -to \[get_pins \{$ed_name\}\]"
	}
	if {$NumEDT_MASK_REG == [expr $NumNormalChain + $NumDummyChain]} {
		set result "OK"
	} else {
		set result "Error!"
	}
	if {$NumZeroFFChain > 0} {
		set NumZeroFFChain "Error! $NumZeroFFChain"
	} else {
		set NumZeroFFChain "$NumZeroFFChain ...OK"
	}
	if {$NumErrorChain  > 0} {
		set NumErrorChain  "Error! $NumErrorChain"
	} else {
		set NumErrorChain  "$NumErrorChain ...OK"
	}
	puts "# (E) 1 to 0    : $NumZeroFFChain"
	foreach tmp $ZeroChain_LIST  {puts "#Error: $tmp"}

	puts "# (E) 1 to many : $NumErrorChain"
	foreach tmp $ErrorChain_LIST {
		puts "#Error: $tmp"
		foreach tmp2 $ErrorChain($tmp) { puts "        -> $tmp2" }
	}

	puts "# (1) 1 to 1    : $NumNormalChain"
	puts "# (2) 1 to 2    : $NumDummyChain"
	puts {}
	puts "# Result        : $result"
	puts "######################################"
	puts "#<< Type: 1 to 1 >>"
	foreach tmp $NormalChain_LIST     {puts $tmp}
	puts "#<< Type: 1 to 2 >>"
	foreach tmp $DummyChain_LIST {puts $DummyChain($tmp)}
}


proc chk_ECO_size {{COMMAND_FILE}} {
	set DRC [READ_LISTFILE $COMMAND_FILE]
	set OUTFILE [open "${COMMAND_FILE}.result" "w"]
	set OUTFILE2 [open "${COMMAND_FILE}.renew" "w"]
	
	set pitch 0.15
	set hight 7.0
	set k     [expr 7.0 * 0.15 * 0.15]
	
	set nu 0
	set total 0.0
	foreach tmp $DRC {
		set INST    [lindex $tmp 1]
		set REF_NEW [lindex $tmp 2]
		set ORG     [get_attribute [get_cells $INST] area]
		set PITCH_ORG [expr $ORG / $k]
		set NEW     [get_attribute [get_lib_cells */$REF_NEW] area]
		set PITCH_NEW [expr $NEW / $k]
		set DIFF    [expr $PITCH_NEW - $PITCH_ORG]
	
		puts $OUTFILE  [format "%2.0f (%15s) %s" $DIFF $REF_NEW $INST]
		puts $OUTFILE2 "$DIFF size_cell \{$INST\} \{$REF_NEW\}"
		set total [expr $total + $DIFF]
		incr nu
	}
	close $OUTFILE
	close $OUTFILE2
	
	puts "total : ($nu) +$total"
	sh sort -n +0 ${COMMAND_FILE}.result | awk \'{print \$1}\'|uniq -c
}


proc CHK_SKEWED_MARGIN {
    outfile
    {min_max max}
    {DLCLT_DRV_SMC_MAXTRAN_SLACK_RATIO 0.625}
    {DLCLT_DRV_SMC_MAXTRAN_OFFSET      0.4}
    {DLCLT_DRV_SMC_MAXTRAN_NWORST      1}
    {DLCLT_DRV_SMC_MAXTRAN_MAX_PATHS   200000}
} {
    set DLCLT_DRV_SMC_MAXTRAN_PINS         "SE SMC"
    set DLCLT_DRV_SMC_MAXTRAN_REPORT_MODE  violated

    if { [catch {open $outfile "w"} out_fd] } {
        puts "Error(DLCLT): Cannot open SMC Maxtran report file. ($outfile)"
        return 1
    }
    suppress_message {UITE-416}

    puts -nonewline $out_fd "#
# SMC pin Maxtransition report
#   Date : [date]
#
#   Pin                        Timing        Actual Tran   Slack   Judge
#                              Slack         ((Tran-$DLCLT_DRV_SMC_MAXTRAN_OFFSET)*$DLCLT_DRV_SMC_MAXTRAN_SLACK_RATIO)
# --------------------------------------------------------------------------
"
    set print_lines ""

    foreach pinname $DLCLT_DRV_SMC_MAXTRAN_PINS {

	foreach_in_collection smc_pin [get_pins -hier */$pinname -quiet -filter "actual_fall_transition_max > $DLCLT_DRV_SMC_MAXTRAN_OFFSET"] {
        	if { $smc_pin == "" } { continue }
		set smc_tran  [get_attribute [get_pins $smc_pin] actual_fall_transition_max]
		#set max_slack [get_attribute -quiet $smc_pin max_fall_slack]
		#set min_slack [get_attribute -quiet $smc_pin min_fall_slack]
		if { $min_max == "max" } {
                	set ptype "setup"
			#set slack $max_slack
		} else {
                	set ptype "hold"
			#set slack $min_slack
		}
		set slacks [get_attribute [get_timing_path -delay $min_max -fall_to $smc_pin -group *] slack] 
		set slack  [GET_MIN_VALUE_LIST $slacks]

		if { $slack == "INFINITY" } { continue }; #y.mino 2015/09/13 No report unconstrained path


		# calculate constraint
		set chk_val [expr [expr $smc_tran - $DLCLT_DRV_SMC_MAXTRAN_OFFSET] * $DLCLT_DRV_SMC_MAXTRAN_SLACK_RATIO]

		# check
		if { $slack < $chk_val } {
			lappend print_lines  [format \
				{   %-27s %-13.3f %-13.3f %5.3f  (VIOLATED)} \
				[get_object_name $smc_pin] $slack $chk_val \
				[expr $slack - $chk_val]]
		} elseif { [string equal -nocase $DLCLT_DRV_SMC_MAXTRAN_REPORT_MODE "all"] } {
			lappend print_lines  [format \
				{   %-27s %-13.3f %-13.3f %5.3f  (MET)} \
				[get_object_name $smc_pin] $slack $chk_val \
				[expr $chk_val - $slack]]
            }
        }
    }
    unsuppress_message {UITE-416}
    set print_lines [lsort -dictionary -ascii -decreasing -index 3 $print_lines]
    foreach print_line $print_lines {
	puts $out_fd "$print_line"
    }
    # close report file
    close $out_fd

    return 0
}


proc SKEWED_REP2PATH { INFILE OUTFILE {min_max max} {LIMITTER 200} } {
   set INFILE_EX [file extension $INFILE]

   if {$INFILE_EX== ".bz2"} {
	set fid_a  [open "|bzip2 -dc $INFILE"]
   } elseif {$INFILE_EX == ".gz"} {
	set fid_a  [open "|gzip -dc $INFILE"]
   } else {
	set fid_a  [open $INFILE]
   }

   redirect $OUTFILE {
	puts "#---------------------------------------------------"
	puts "# SKEWED_REP2PATH $INFILE -> $OUTFILE"
	puts "# MIN_MAX $min_max,  LIMITTER:$LIMITTER"
	puts "#---------------------------------------------------"
	set num 0
   }
   while {[gets $fid_a str]>=0} {
	if {[string match "*(VIOLATED)*" $str]} {
		set pin_name  [lindex $str 0]
		set required  [lindex $str 2]
		set pin_slack [lindex $str 3]
		redirect -append $OUTFILE {
			puts "# Path $num: $pin_name Slack:$pin_slack Required_slack:$required"
			if {$num < $LIMITTER} {
				report_timing -fall_to $pin_name -delay $min_max -input -tran -cap -net -nosplit
				puts ""
			} elseif {$num == $LIMITTER} {
				puts "Error: number is over than $LIMITTER"
			}
		}
		incr num
	}
   }
   close $fid_a
}

proc DELTA_RATIO2REP { INFILE OUTFILE {MIN_DELTARATIO 0.050} {LIMITTER 50} } {
   set INFILE_EX [file extension $INFILE]

   if {$INFILE_EX== ".bz2"} {
	set fid_a  [open "|bzip2 -dc $INFILE"]
   } elseif {$INFILE_EX == ".gz"} {
	set fid_a  [open "|gzip -dc $INFILE"]
   } else {
	set fid_a  [open $INFILE]
   }

   redirect $OUTFILE {
	puts "#---------------------------------------------------"
	puts "# DELTA_RATIO2REP $INFILE -> $OUTFILE"
	puts "# MIN_DELTARATIO $MIN_DELTARATIO,  LIMITTER:$LIMITTER"
	puts "#---------------------------------------------------"
   }
   if {[info exists LIST_DELTA]} {
	unset LIST_DELTA
   }
   set LIST_DELTA {}
   ######################################
   ## Get Delta ratio Error list
   while {[gets $fid_a str]>=0} {
	if {![regexp "^  NO        CLK    RATIO" $str]} {
		set pin_name    [lindex $str 12]
		set clock_name  [lindex $str 1]
		set delta_ratio [lindex $str 3]

		regsub {^\(} $pin_name    {} pin_name
		regsub {\)$} $pin_name    {} pin_name

		if {$delta_ratio >= $MIN_DELTARATIO} {
			lappend LIST_DELTA "$delta_ratio $pin_name $clock_name"
		}
	}
   }
   close $fid_a
   ######################################
   ## Sort list and output report
   set LIST_DELTA [lsort -dictionary -decreasing -ascii -unique $LIST_DELTA]
   set num 0
   foreach str $LIST_DELTA {
	set delta_ratio [lindex $str 0]
	set pin_name    [lindex $str 1]
	set clock_name  [lindex $str 2]
	if {[regexp "^$" $str]} {
		continue
	}
	if {$num<$LIMITTER} {
	    redirect -append $OUTFILE {
		puts "##############################################################################################"
		puts "#[expr $num+1] Pin:$pin_name CLK:$clock_name DDRATIO:$delta_ratio"
		report_timing -delay max -net -input -cap -tran -nosplit -th $pin_name -delta -path_type full_clock_expanded -derate
	    }
	} else {
	    if { $num==$LIMITTER } {
		redirect -append $OUTFILE {
		    puts "Error: Overflow PathNumber LIMITTER:$LIMITTER"
		}
	    }
	    redirect -append $OUTFILE {
		puts "#[expr $num+1] Pin:$pin_name CLK:$clock_name DDRATIO:$delta_ratio"
	    }
	}
	incr num
   }
}

proc DELTA_MAXDELTA2REP { INFILE OUTFILE {MIN_DELTAMAX 0.400} {LIMITTER 50} } {
   set INFILE_EX [file extension $INFILE]

   if {$INFILE_EX== ".bz2"} {
	set fid_a  [open "|bzip2 -dc $INFILE"]
   } elseif {$INFILE_EX == ".gz"} {
	set fid_a  [open "|gzip -dc $INFILE"]
   } else {
	set fid_a  [open $INFILE]
   }

   redirect $OUTFILE {
	puts "#---------------------------------------------------"
	puts "# DELTA_MAXDELTA2REP $INFILE -> $OUTFILE"
	puts "# MIN_DELTAMAX $MIN_DELTAMAX,  LIMITTER:$LIMITTER"
	puts "#---------------------------------------------------"
   }
   if {[info exists LIST_DELTA]} {
	unset LIST_DELTA
   }
   set LIST_DELTA {}
   ######################################
   ## Get Delta ratio Error list
   while {[gets $fid_a str]>=0} {
	if {![regexp "^  NO        CLK    RATIO" $str]} {
		set pin_name    [lindex $str 12]
		set clock_name  [lindex $str 1]
		set delta_temp  [lindex $str 4]

		regsub {^\(} $delta_temp  {} delta_temp
		regsub {\)$} $delta_temp  {} delta_temp
		set delta       [lindex [ split ${delta_temp} "/"] 0]

		regsub {^\(} $pin_name    {} pin_name
		regsub {\)$} $pin_name    {} pin_name

		if {$delta >= $MIN_DELTAMAX} {
			lappend LIST_DELTA "$delta $pin_name $clock_name"
		}
	}
   }
   close $fid_a
   ######################################
   ## Sort list and output report
   set LIST_DELTA [lsort -dictionary -decreasing -ascii -unique $LIST_DELTA]
   set num 0
   foreach str $LIST_DELTA {
	set delta       [lindex $str 0]
	set pin_name    [lindex $str 1]
	set clock_name  [lindex $str 2]
	if {$num<$LIMITTER} {
	    redirect -append $OUTFILE {
		puts "##############################################################################################"
		puts "#[expr $num+1] Pin:$pin_name CLK:$clock_name DELTA:$delta"
		report_timing -delay max -net -input -cap -tran -nosplit -th $pin_name -delta -path_type full_clock_expanded -derate
	    }
	} else {
	    if { $num==$LIMITTER } {
		redirect -append $OUTFILE {
		    puts "Error: Overflow PathNumber LIMITTER:$LIMITTER"
		}
	    }
	    redirect -append $OUTFILE {
		puts "#[expr $num+1] Pin:$pin_name CLK:$clock_name DELTA:$delta"
	    }
	}
	incr num
   }
}

proc DELTA_MINDELTA2REP { INFILE OUTFILE {MAX_DELTAMIN -0.060} {LIMITTER 50} } {
   set INFILE_EX [file extension $INFILE]

   if {$INFILE_EX== ".bz2"} {
	set fid_a  [open "|bzip2 -dc $INFILE"]
   } elseif {$INFILE_EX == ".gz"} {
	set fid_a  [open "|gzip -dc $INFILE"]
   } else {
	set fid_a  [open $INFILE]
   }

   redirect $OUTFILE {
	puts "#---------------------------------------------------"
	puts "# DELTA_MINDELTA2REP $INFILE -> $OUTFILE"
	puts "# MAX_DELTAMIN $MAX_DELTAMIN,  LIMITTER:$LIMITTER"
	puts "#---------------------------------------------------"
   }
   if {[info exists LIST_DELTA]} {
	unset LIST_DELTA
   }
   set LIST_DELTA {}
   ######################################
   ## Get Delta ratio Error list
   while {[gets $fid_a str]>=0} {
	if {![regexp "^  NO :(DLT_DLYmin/SLACK)" $str] && ![regexp "^#" $str]} {
		set pin_name    [lindex $str 4]
		set delta_temp  [lindex $str 2]

		regsub {^\(} $delta_temp  {} delta_temp
		regsub {\)$} $delta_temp  {} delta_temp
		set delta       [lindex [ split ${delta_temp} "/"] 0]

		regsub {^\(} $pin_name    {} pin_name
		regsub {\)$} $pin_name    {} pin_name

		if {$delta <= $MAX_DELTAMIN} {
			lappend LIST_DELTA "$delta $pin_name"
		}
	}
   }
   close $fid_a
   ######################################
   ## Sort list and output report
   set LIST_DELTA [lsort -dictionary -decreasing -ascii -unique $LIST_DELTA]
   set num 0
   foreach str $LIST_DELTA {
	set delta       [lindex $str 0]
	set pin_name    [lindex $str 1]
	if {$num<$LIMITTER} {
	    redirect -append $OUTFILE {
		puts "##############################################################################################"
		puts "#[expr $num+1] Pin:$pin_name DELTA:$delta"
		report_timing -delay min -net -input -cap -tran -nosplit -th $pin_name -delta -path_type full_clock_expanded -derate
	    }
	} else {
	    if { $num==$LIMITTER } {
		redirect -append $OUTFILE {
		    puts "Error: Overflow PathNumber LIMITTER:$LIMITTER"
		}
	    }
	    redirect -append $OUTFILE {
		puts "#[expr $num+1] Pin:$pin_name DELTA:$delta"
	    }
	}
	incr num
   }
}


proc CALC_STD_AREA {} {
   if {[string match "RV40F" $::PROCESS]} {
	set Cell_Total [get_cells -h * -filter "is_hierarchical==false"]
	set Cell_H     [get_cells -h * -filter "ref_name=~THH*"]
	set Cell_M     [get_cells -h * -filter "ref_name=~TMH*"]
	set Cell_L     [get_cells -h * -filter "ref_name=~TLH*"]
	set Cell_Std   [add_to_collection [add_to_collection $Cell_H $Cell_M] $Cell_L]

	set area_H 0.0; foreach_in_collection cell $Cell_H { set area_H [expr $area_H + [get_attribute $cell area]] }
	set area_M 0.0; foreach_in_collection cell $Cell_M { set area_M [expr $area_M + [get_attribute $cell area]] }
	set area_L 0.0; foreach_in_collection cell $Cell_L { set area_L [expr $area_L + [get_attribute $cell area]] }
	set area_Total [expr $area_H + $area_M + $area_L ]

	set ratio_H [expr $area_H/$area_Total * 100]
	set ratio_M [expr $area_M/$area_Total * 100]
	set ratio_L [expr $area_L/$area_Total * 100]

	puts "-----------------------------------------------"
	puts "               Area  (Ratio)"
	puts [format {LVT     %.1f (%.2f%s)} $area_L $ratio_L "%"]
	puts [format {MVT     %.1f (%.2f%s)} $area_M $ratio_M "%"]
	puts [format {HVT     %.1f (%.2f%s)} $area_H $ratio_H "%"]
	puts [format {Total   %.1f --- Std Area(wo WVT)} $area_Total]
	puts "-----------------------------------------------"
   } elseif {[string match "RV28F" $::PROCESS]} {
	set Cell_Total [get_cells -h * -filter "is_hierarchical==false"]
	set Cell_H     [get_cells -h * -filter "ref_name=~THH*"]
	set Cell_M     [get_cells -h * -filter "ref_name=~TSH*"]
	set Cell_L     [get_cells -h * -filter "ref_name=~TULH*"]
	set Cell_Std   [add_to_collection [add_to_collection $Cell_H $Cell_M] $Cell_L]

	set area_H 0.0; foreach_in_collection cell $Cell_H { set area_H [expr $area_H + [get_attribute $cell area]] }
	set area_M 0.0; foreach_in_collection cell $Cell_M { set area_M [expr $area_M + [get_attribute $cell area]] }
	set area_L 0.0; foreach_in_collection cell $Cell_L { set area_L [expr $area_L + [get_attribute $cell area]] }
	set area_Total [expr $area_H + $area_M + $area_L ]

	set ratio_H [expr $area_H/$area_Total * 100]
	set ratio_M [expr $area_M/$area_Total * 100]
	set ratio_L [expr $area_L/$area_Total * 100]

	puts "-----------------------------------------------"
	puts "               Area  (Ratio)"
	puts [format {ULVT    %.1f (%.2f%s)} $area_L $ratio_L "%"]
	puts [format {SVT     %.1f (%.2f%s)} $area_M $ratio_M "%"]
	puts [format {HVT     %.1f (%.2f%s)} $area_H $ratio_H "%"]
	puts [format {Total   %.1f --- Std Area(wo WVT)} $area_Total]
	puts "-----------------------------------------------"
   } else {
	puts "Error(CALC_STD_AREA): PROCESS = $PROCESS is not supported."
   }
}


proc REPEATER_SKEWED_FANOUT { {HEADER ECOXX_SKEWEDFANOUT} {OUT_COMMAND cmdXX.SKEWED_REPEATER} {MAX_FANOUT 16} {INV_CELL TMHINVX40} {DIVIDE_RATIO 0.334} } {

	## Get skewed pins from reports
	if {[catch "glob ls ./Report/skewed.*" skewedfiles]} {
		puts "  # Error:        No constraint file for atribute '$CODE'."
		nop
		nop
		continue
	}
	foreach file $skewedfiles {
		puts "  $file"
		set FILE_EX [file extension $file]
		if {$FILE_EX == ".bz2"} {
			set fid  [open "|bzip2 -dc $file"]
		} elseif {$FILE_EX == ".gz"} {
			set fid  [open "|gzip -dc $file"]
		} else {
			set fid  [open $file]
		}
		while {[gets $fid str]>=0} {
			#puts [subst $str]
			if {[regexp "^#" $str]} { continue }
			lappend all_pins [lindex $str 0]
		}
		close $fid
	}
	set all_pins [lsort -dictionary -ascii -unique $all_pins]

	set all_drv {}
	foreach pin $all_pins {
		#puts "$pin"
		set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]

	}
	set ofid [open $OUT_COMMAND "w"]
	set num 1
	foreach_in_collection pin $all_drv {
		#puts "[get_object_name $pin]"
		set fanout_num [sizeof_collection [remove_from_collection [all_connected -l [all_connected [get_pins $pin]]] [get_pins $pin]]]
		if {$fanout_num > $MAX_FANOUT} {
			set pnum [format "%05d" $num]
			puts            $ofid "# [get_object_name $pin] fanout $fanout_num"
			puts -nonewline $ofid "add_buffer_on_route -inverter_pair -repeater_distance_length_ratio ${DIVIDE_RATIO} -no_legalize -no_eco_route "
			puts -nonewline $ofid "-net_prefix  n_${HEADER}_${pnum} -cell_prefix i_${HEADER}_${pnum} "
			puts            $ofid "\[get_nets -of \[get_pins [get_object_name $pin]\]\] ${INV_CELL}"
			puts $ofid ""
			incr num
		}

	}
	close $ofid

}


proc REPEATER_XTALK_FANOUT { {HEADER ECOXX_XTALKREPEATER} {OUT_COMMAND cmdXX.XTALK_REPEATER} {MAX_CAP 0.10} {INV_CELL TMHINVX40} {DIVIDE_RATIO 0.334} } {

	## Get Xtalk pins from reports
	if {[catch "glob ls ./result.xtalk/??_DD*_*.csv" xtalksumfiles]} {
		puts "  # Error:        No constraint file for atribute '$CODE'."
		nop
		nop
		continue
	}
	set all_pins {}
	foreach file $xtalksumfiles {
		puts "  $file"
		set FILE_EX [file extension $file]
		if {$FILE_EX == ".bz2"} {
			set fid  [open "|bzip2 -dc $file"]
		} elseif {$FILE_EX == ".gz"} {
			set fid  [open "|gzip -dc $file"]
		} else {
			set fid  [open $file]
		}
		set mflg 0
		while {[gets $fid str]>=0} {
			#puts [subst $str]
			if {[regexp "^#" $str]} { continue }
			if {[regexp "^Num," $str]} {
				set mflg 1;
			} elseif {[regexp "^$" $str] } {
				set mflg 0;
			} elseif {$mflg == 1} {
				regsub -all {,} $str { } str
				lappend all_pins [lindex $str 1]
			}
		}
		close $fid
	}
	set all_pins [lsort -dictionary -ascii -unique $all_pins]

	set all_drv {}
	foreach pin $all_pins {
		#puts "$pin"
		set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]

	}
	set ofid [open $OUT_COMMAND "w"]
	set num 1
	foreach_in_collection pin $all_drv {
		#puts "[get_object_name $pin]"
		set capacitance [get_attribute [get_pins $pin] effective_capacitance_max]
		set drvcell	[get_attribute [get_cells -of [get_pins $pin] ] ref_name]
		if {$capacitance > $MAX_CAP} {
			set pnum [format "%05d" $num]
			puts $ofid "# [get_object_name $pin] cap:$capacitance driver:$drvcell"
			puts -nonewline $ofid "add_buffer_on_route -inverter_pair -repeater_distance_length_ratio ${DIVIDE_RATIO} -no_legalize -no_eco_route"
			puts -nonewline $ofid " -net_prefix  n_${HEADER}_${pnum} -cell_prefix i_${HEADER}_${pnum} "
			puts            $ofid " \[get_nets \-of \[get_pins [get_object_name $pin]\]\] ${INV_CELL}"
			puts $ofid ""
			incr num
		} else {
			puts $ofid "# Out_Of_Target [get_object_name $pin] cap:$capacitance driver:$drvcell"
		}
	}
	close $ofid

}

proc UPSIZE_TRAN     { {MAXSIZE 80} {OUT_COMMAND cmdXX.TRAN_UPSIZE} {UPSIZE_STEP 10} }  {
        ## Get maxtran pins from reports
        if {[catch "glob ls ./result.const/??_tran_*.csv ./result.const/??_cap_*.csv" transumfiles]} {
                puts "  # Error:        No constraint file for atribute '$CODE'."
                nop
                nop
                continue
        }
        set all_pins {}
        foreach file $transumfiles {
            if {![string match "*_clkpin_*" $file] && ![string match "*_lowdrv_*" $file]} {
                puts "  $file"
                set FILE_EX [file extension $file]
                if {$FILE_EX == ".bz2"} {
                        set fid  [open "|bzip2 -dc $file"]
                } elseif {$FILE_EX == ".gz"} {
                        set fid  [open "|gzip -dc $file"]
                } else {
                        set fid  [open $file]
                }
                set mflg 0
                while {[gets $fid str]>=0} {
                        #puts [subst $str]
                        if {[regexp "^#" $str]} { continue }
                        if {[regexp "^TOTAL" $str]} { continue }
                        if {[regexp "^Num," $str]} {
                                set mflg 1;
                        } elseif {[regexp "^$" $str] } {
                                set mflg 0;
                        } elseif {$mflg == 1 && [regexp ",VIO," $str]} {
                                regsub -all {,} $str { } str
                                lappend all_pins [lindex $str 1]
                        }
                }
                close $fid
           }
        }
        set all_pins [lsort -dictionary -ascii -unique $all_pins]

        set all_drv {}
        foreach pin $all_pins {
                #puts "$pin"
                set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]
        }
        set ofid [open $OUT_COMMAND "w"]
        set num 1
        foreach_in_collection pin $all_drv {
                #puts "[get_object_name $pin]"
                set net_name [get_net -of_objects [get_pins $pin]]
                set capacitance_wire [get_attribute [get_net $net_name] wire_capacitance_max]
                set capacitance_eff  [get_attribute -q [get_pins $pin] effective_capacitance_max]
		if {$capacitance_wire > $capacitance_eff} {
                	set capacitance $capacitance_wire
		} else {
                	set capacitance $capacitance_eff
		}
                set drvcell     [get_attribute [get_cells -of [get_pins $pin] ] ref_name]
		set newcell     [UPSIZE_CELL $drvcell $MAXSIZE $UPSIZE_STEP]
		set inst        [get_object_name [get_cells -of [get_pins $pin]]]
		if {![string match $drvcell $newcell]} {
			puts $ofid "size_cell $inst $newcell ;# $drvcell";
                } else {
                        puts $ofid "# Out_Of_Target inst cap:$capacitance driver:$drvcell"
                }
        }
        close $ofid
}

proc UPSIZE_CELL { {CELLNAME} {MAXSIZE 80} {UPSIZE_STEP 10} } {
	regsub -all ".*X" $CELLNAME "" CELLDRV
	if {[string match  "0*" $CELLDRV]} {
		set NEWDRV 10
	} elseif {$CELLDRV <= $MAXSIZE } {
		set NEWDRV [expr $CELLDRV + $UPSIZE_STEP]
	} else {
		return $CELLNAME
	}
	for {set NEWDRV $NEWDRV } {$NEWDRV <= $MAXSIZE} { set NEWDRV [expr $NEWDRV + $UPSIZE_STEP] } {
		regsub "X${CELLDRV}" $CELLNAME "X$NEWDRV" NEWCELL
		if {[get_lib_cells -q */${NEWCELL}] != ""} {
			return $NEWCELL
		}
	}
	return $CELLNAME
}

proc REPEATER_TRAN_FANOUT { {HEADER ECOXX_TRANREPEATER} {OUT_COMMAND cmdXX.TRAN_REPEATER} {MAX_CAP 0.16} {INV_CELL THHINVZHX40} {DIVIDE_RATIO 0.334} } {

        ## Get maxtran pins from reports
        if {[catch "glob ls ./result.const/??_tran_*.csv ./result.const/??_cap_*.csv" transumfiles]} {
                puts "  # Error:        No constraint file for atribute '$CODE'."
                nop
                nop
                continue
        }
        set all_pins {}
        foreach file $transumfiles {
            if {![string match "*_clkpin_*" $file] && ![string match "*_lowdrv_*" $file]} {
                puts "  $file"
                set FILE_EX [file extension $file]
                if {$FILE_EX == ".bz2"} {
                        set fid  [open "|bzip2 -dc $file"]
                } elseif {$FILE_EX == ".gz"} {
                        set fid  [open "|gzip -dc $file"]
                } else {
                        set fid  [open $file]
                }
                set mflg 0
                while {[gets $fid str]>=0} {
                        #puts [subst $str]
                        if {[regexp "^#" $str]} { continue }
                        if {[regexp "^TOTAL" $str]} { continue }
                        if {[regexp "^Num," $str]} {
                                set mflg 1;
                        } elseif {[regexp "^$" $str] } {
                                set mflg 0;
                        } elseif {$mflg == 1 && [regexp ",VIO," $str]} {
                                regsub -all {,} $str { } str
                                lappend all_pins [lindex $str 1]
                        }
                }
                close $fid
           }
        }
        set all_pins [lsort -dictionary -ascii -unique $all_pins]

        set all_drv {}
        foreach pin $all_pins {
                #puts "$pin"
                set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]

        }
        set ofid [open $OUT_COMMAND "w"]
        set num 1
        foreach_in_collection pin $all_drv {
                #puts "[get_object_name $pin]"
                set net_name [get_net -of_objects [get_pins $pin]]
                set capacitance_wire [get_attribute [get_net $net_name] wire_capacitance_max]
                set capacitance_eff  [get_attribute -q [get_pins $pin] effective_capacitance_max]
		if {$capacitance_wire > $capacitance_eff} {
                	set capacitance $capacitance_wire
		} else {
                	set capacitance $capacitance_eff
		}
                set drvcell     [get_attribute [get_cells -of [get_pins $pin] ] ref_name]
                if {$capacitance > $MAX_CAP} {
                        set pnum [format "%05d" $num]
                        puts $ofid "# [get_object_name $pin] cap:$capacitance driver:$drvcell"
                        puts -nonewline $ofid "add_buffer_on_route -inverter_pair -repeater_distance_length_ratio ${DIVIDE_RATIO} -no_legalize -no_eco_route"
                        puts -nonewline $ofid " -net_prefix  n_${HEADER}_${pnum} -cell_prefix i_${HEADER}_${pnum} "
                        puts            $ofid " \[get_nets \-of \[get_pins [get_object_name $pin]\]\] ${INV_CELL}"
                        puts $ofid ""
                        incr num
                } else {
                        puts $ofid "# Out_Of_Target [get_object_name $pin] cap:$capacitance driver:$drvcell"
                }
        }
        close $ofid

}






proc CHK_KEEP_DONTTOUCH { {keep_dir null} {dont_dir null} } {
   if {[regexp "null" $keep_dir] || [regexp "null" $dont_dir]} {
	puts {Error: CHK_KEEP_DONTTOUCH $KEEP_LIST_DIRECTORY $DONT_TOUCH_DIRECTORY}
   } elseif {![file exists $keep_dir] || ![file exists $dont_dir]} {
	if {![file exists $keep_dir]} {
		puts "Error: Cannot find $keep_dir as \$KEEP_LIST_DIRECTORY"
	}
	if {![file exists $dont_dir]} {
		puts "Error: Cannot find $dont_dir as \$DONT_TOUCH_DIRECTORY"
	}
   } else {
	set out_dir  keep_log
	set cwd      [pwd]
	set overview 00_OVERVIEW.list

	DIR_CHECK $out_dir
	set OK_LOGS {}
	set NG_LOGS {}

	foreach cell_file [glob ${keep_dir}/*.list ${dont_dir}/*_dont_touch_cell.list] {
		puts "Information(cell_check): $cell_file"

		set  ng_flg  0;
		set  base_name [regsub {.*/} $cell_file {}];
		set  rfp [open $cell_file "r"]
		redirect ${out_dir}/${base_name}.log {
		  puts "# Check $cell_file"
		  while {[gets $rfp str]>=0} {
			if {[regexp "^ *\#" $str] || [regexp "^ *$" $str]} {
				continue
			}
			if {[regexp {\*} $str ]} {
				puts "NG(\*): $str"
				set ng_flg 1
			}
			set  hit_cells [get_cells -q $str]
			if {[sizeof_collection $hit_cells] == 0} {
				puts "NG(NoCell): $str"
				set ng_flg 1
			} else {
				foreach_in_collection hit_cell $hit_cells {
					if {[get_attribute $hit_cell is_hierarchical] == "true"} {
						puts "OK(hier): [get_object_name $hit_cell]"
					} else {
						puts "OK(inst): [get_object_name $hit_cell]"
					}
				}
			}
		  }
		}
		close $rfp
		if {$ng_flg>0} {
			lappend NG_LOGS ${cwd}/${out_dir}/${base_name}.log
		} else {
			lappend OK_LOGS ${cwd}/${out_dir}/${base_name}.log
		}
	}

	foreach net_file [glob ${dont_dir}/*dont_touch_net.list ${dont_dir}/*dont_touch_net_seg.list] {
		puts "Information(net_check): $net_file"
	
		set  ng_flg  0;
		set  base_name [regsub {.*/} $net_file {}];
		set  rfp [open $net_file "r"]
		redirect ${out_dir}/${base_name}.log {
	  	puts "# Check $net_file"
	  	while {[gets $rfp str]>=0} {
			if {[regexp "^ *\#" $str] || [regexp "^ *$" $str]} {
				continue
			}
			if {[regexp {\*} $str ]} {
				puts "NG(\*): $str"
				set  ng_flg  1;
			}
			set  hit_nets [get_nets -q $str]
			if {[sizeof_collection $hit_nets] == 0} {
				puts "NG(NoNet): $str"
				set  ng_flg  1;
			} else {
				foreach_in_collection hit_net $hit_nets {
					puts "OK(inst): [get_object_name $hit_net]"
				}
			}
		  }
		}
		close $rfp
		if {$ng_flg>0} {
			lappend NG_LOGS ${cwd}/${out_dir}/${base_name}.log
		} else {
			lappend OK_LOGS ${cwd}/${out_dir}/${base_name}.log
		}
	}

	foreach network_file [glob ${dont_dir}/*_from_network.list] {
		puts "Information(network_check): $network_file"

		set  ng_flg  0;
		set  base_name [regsub {.*/} $network_file {}];
		set  rfp [open $network_file "r"]
		redirect ${out_dir}/${base_name}.log {
		  puts "# Check $network_file"
		  while {[gets $rfp str]>=0} {
			if {[regexp "^ *\#" $str] || [regexp "^ *$" $str]} {
				continue
			}
			if {[regexp {\*} $str ]} {
				puts "NG(\*): $str"
				set  ng_flg  1;
			}
			set  hit_pins [get_pins -q $str]
			if {[sizeof_collection $hit_pins] == 0} {
				puts "NG(NoNetwork): $str"
				set  ng_flg  1;
			} else {
				foreach_in_collection hit_pin $hit_pins {
					if {[get_attribute $hit_pin is_hierarchical] == "true"} {
						puts "OK(hierpin): [get_object_name $hit_pin]"
					} else {
						puts "OK(instpin): [get_object_name $hit_pin]"
					}
				}
			}
		  }
		}
		close $rfp
		if {$ng_flg>0} {
			lappend NG_LOGS ${cwd}/${out_dir}/${base_name}.log
		} else {
			lappend OK_LOGS ${cwd}/${out_dir}/${base_name}.log
		}
	}

	redirect ${out_dir}/${overview} {
		foreach NG_LOG $NG_LOGS {
			puts "NG: $NG_LOG"
		}
		puts ""
		foreach OK_LOG $OK_LOGS {
			puts "OK: $OK_LOG"
		}
	}
   }
}
#################################################
## chkGCLKPathAll.r4.tcl 2016/07/15 Kenji.Asano
#################################################
proc chk_sync_clock {clk1 clk2} {
  if {[string match [get_root_clock $clk1] [get_root_clock $clk2]]} {
    return "sync"
  } else {
    return "async"
  }
}
proc get_root_clock {clk_name} {
  set clk [get_clocks $clk_name]
  if {[get_attribute $clk is_generated] == "true"} {
    set master [get_attribute [get_attribute $clk master_clock] full_name]
    return [get_root_clock $master]
  } else {
    return $clk_name
  }
}

proc chk_path_cycle {source endpoint startclk endclk delay} {
  set paths [get_timing_paths -delay $delay -from [get_clocks $startclk] -th $source -th $endpoint -to [get_clocks $endclk]] ;# very slow
  #set paths [get_timing_paths -delay $delay -from [get_clocks $startclk] -th $source -th $endpoint -group $endclk] ;# fast
  if {[sizeof_collection $paths] == 0} {
    return "---"
  } else {
    set start_period [get_attribute [get_attribute $paths startpoint_clock] period]
    set end_period   [get_attribute [get_attribute $paths endpoint_clock] period]
    set min_period   [expr ($start_period<$end_period)? $start_period: $end_period]
    set t_start_edge [get_attribute $paths startpoint_clock_open_edge_value]
    set t_end_edge   [get_attribute $paths endpoint_clock_close_edge_value]
    set path_cycle   [expr ($t_end_edge - $t_start_edge) / $min_period]
    return [format "%0.1f" $path_cycle]
  }
}

proc chkGCLKPathAll {{type "all"}} {
  if {[sizeof_collection [get_clocks -q -filter "is_generated==true"]]==0} {
    puts "No GCLK."
    return
  }

  set unconst_var [get_app_var timing_report_unconstrained_paths]
  set_app_var timing_report_unconstrained_paths "false"

  foreach_in_collection gclk [get_clocks -q -filter "is_generated==true"] {
    set sources       [get_attribute $gclk sources]
    set gclock_name   [get_attribute $gclk full_name]
    puts "#-----------------------------------"
    puts "# GCLK: [get_attribute $sources full_name] ([get_attribute $gclk full_name])"
    foreach_in_collection source $sources {
      set source_name [get_attribute $source full_name]
      if {$type=="all"} {
        if {[get_attribute $source object_class]=="port"} {
          set source_clocks [lsort -u [get_attribute [get_attribute [get_ports $sources] clocks] full_name]]
        } else {
          set source_clocks [lsort -u [get_attribute [get_attribute [get_pins -q -of [get_cells -of $source] -filter "defined(clocks) && is_clock_used_as_clock"] clocks] full_name]]
        }
      } else {
        set source_clocks $gclock_name
      }
      set gclk_fanout [all_fanout -from $source -flat -endpoint]
      set gclk_fanout_to_data [filter_collection $gclk_fanout "is_data_pin && !is_clock_pin"]
      if {[sizeof_collection $gclk_fanout] == 0} {
        puts "# No paths"
      } elseif {[sizeof_collection $gclk_fanout_to_data] == 0} {
        puts "# No ClockAsData paths"
      } else {
        puts "# Setup Hold : Startpoint (StartClock) -> Endpoint (EndClock)"
        foreach_in_collection pin $gclk_fanout_to_data {
          set endpoint [get_attribute $pin full_name]
          set endpoint_clocks [lsort -u [get_attribute [get_attribute [get_pins -q -of [get_cells -of $endpoint] -filter "defined(clocks) && is_clock_used_as_clock"] clocks] full_name]]

          foreach clk1 $source_clocks {
            foreach clk2 $endpoint_clocks {
              puts " [chk_path_cycle $source_name $endpoint $clk1 $clk2 "max"] [chk_path_cycle $source_name $endpoint $clk1 $clk2 "min"] : ${source_name} ($clk1) -> ${endpoint} ($clk2) [chk_sync_clock $clk1 $clk2]"
            }
          }
        }
      }
    }
    # End gclk foreach
  }
  set_app_var timing_report_unconstrained_paths $unconst_var > /dev/null
}

proc chkGCLKPathShort {} {
  chkGCLKPathAll "short"
}


proc COMP_VAR {in_file_list} {
   echo "### Compare Variables ..."
   echo "### expected file : [file normalize $in_file_list]"
   echo "### Result, Variable Name, Expected Value, Current Value"

   set err_flag 0
   set in_file [open "$in_file_list"]
   while {[gets ${in_file} in_line] != -1} {
      if {![regexp "^ *#" ${in_line}] && ![string match "" ${in_line}]} {
        set var_name [lindex ${in_line} 0]
	if { [info exists ::[join ${var_name}]] } {
         	set chk_value [get_app_var ${var_name}] 
	} else {
         	set chk_value "NotDefine"
	}
        set exp_value [lindex ${in_line} 1]
        set exp_value [lindex ${in_line} 1]
        if {[string compare -nocase ${exp_value} ${chk_value}]} {
           #echo "OK, ${var_name}, ${exp_value}, ${chk_value}"
            echo "NG, ${var_name}, ${exp_value}, ${chk_value}"
            set err_flag 1
        } else {
           #echo "NG, ${var_name}, ${exp_value}, ${chk_value}"
            echo "OK, ${var_name}, ${exp_value}, ${chk_value}"
        }
      }
   }
   close $in_file

   if {$err_flag eq "0"} {
      echo "###"
      echo "### (^o^) All variables are matched."
      echo "###"
   } else {
      echo "###"
      echo "### (*_*) There are mismatched variable!!!"
      echo "###"
   }
}

proc SET_ASYNC_TRAN { {ASYNC_MAXTRAN 0.8} {overwrite 0} } {
	set ALL_ASYNC_PINS		[get_pins -hier -filter "is_async_pin==true"]
	#set CONST_ALL_ASYNC_PINS	[get_pins $ALL_ASYNC_PIN -filter "constant_value == 0 || constant_value == 1"]
	#set FREE_ASYNC_PINS		[remove_from_collection $ALL_ASYNC_PIN $CONST_ALL_ASYNC_PIN]

	foreach_in_collection ASYNC_PIN $ALL_ASYNC_PINS {
           if { $overwrite == 1 } {
		set_max_transition $ASYNC_MAXTRAN $ASYNC_PIN
	   } else {
		set old_const [get_attribute -quiet $ASYNC_PIN max_transition]
		if { $old_const == "" } {
			set old_const 999.999
		}
		if { $ASYNC_MAXTRAN < $old_const } {
			set_max_transition $ASYNC_MAXTRAN $ASYNC_PIN
		}
	   }
	}

}

proc MERGE_SDCMASK_PTSC { {DIR 41_SDCMASK_RGETPIN} } {
    if {[catch "glob ls ${DIR}/*.tcl" files]} {
        puts "Error: Cannot find target tcl in $DIR"
        return
    }
    set ofile [format "%s.ptsc" $DIR]
    set out [open $ofile "w"]
    foreach file [lsort -ascii $files] {
	puts $out "# From $file"
        set fid  [open $file]
        while {[gets $fid str]>=0} {
            puts $out "$str"
        }
        close $fid
        puts  $out ""
    }
    close $out
}

proc CONV_GETPIN2RGETPIN { {INDIR 36_SDCMASK_PARTS} {OUTDIR 41_SDCMASK_RGETPIN} } {
    DIR_CHECK $OUTDIR
    if {[catch "glob ls ${INDIR}/*.tcl" files]} {
        puts "Error: Cannot find target tcl in $INDIR"
        return
    }
    foreach file [lsort -ascii $files] {
        regsub "$INDIR" $file "$OUTDIR" ofile
        puts "  $file -> $ofile"
        set fid  [open $file]
        set out [open $ofile "w"]
        while {[gets $fid str]>=0} {
            if {[string match "*get_pins *" $str] && ![string match "*get_cells *" $str]} {
                regsub ".*get_pins " $str              "" target_pins_str
                regsub {] \\}          $target_pins_str {} target_pins_str
                set   target_pins      [eval "get_pins $target_pins_str"]
                set   target_hier_pins [get_pins -q $target_pins -filter "is_hierarchical==true"]
                if {[sizeof_collection $target_hier_pins] != 0} {
                    regsub "get_pins" $str "r_get_cellpin" str
                }
                
            }
            puts $out "$str"
        }
        close $fid
        close $out
    }
}

proc GET_STARTEND_CYCLE { COLLECTION REPFILE STCLOCKFILE EDCLOCKFILE } {
   if {[info exists LINE]} {
	unset LINE
   }
   if {[info exists STCLKs]} {
	unset STCLKs
   }
   if {[info exists EDCLKs]} {
	unset EDCLKs
   }
   foreach_in_collection PATH $COLLECTION {
	set PERI_ST     [get_attribute -quiet $PATH startpoint_clock_open_edge_value]
	set PERI_ED     [get_attribute -quiet $PATH endpoint_clock_close_edge_value]
	set START_POINT [get_attribute $PATH startpoint]
	set START_NAME  [get_object_name $START_POINT]
	set END_POINT   [get_attribute $PATH endpoint]
	set END_NAME    [get_object_name $END_POINT]
    
	if {[info exist PERI_ST] && [info exist PERI_ED] && $PERI_ST !="" && $PERI_ED != ""} {
		set CYCLE_TIME  [expr $PERI_ED - $PERI_ST]
	} else {
		set START_LATENCY    [get_attribute -quiet $PATH startpoint_clock_latency]
		set REQUIRED_TIME    [get_attribute -quiet $PATH required]
		set SETUP_TIME       [get_attribute -quiet $PATH endpoint_setup_time_value]
		set RECOV_TIME       [get_attribute -quiet $PATH endpoint_recovery_time_value]
		set UNCERTAINTY      [get_attribute -quiet $PATH clock_uncertainty]
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
	}
	if { [get_attribute $PATH startpoint_clock] != "" } {
		lappend STCLKs [get_object_name [get_attribute $PATH startpoint_clock]]
	}
	if { [get_attribute $PATH endpoint_clock] != "" } {
		lappend EDCLKs [get_object_name [get_attribute $PATH endpoint_clock]]
	}
	lappend LINE "$START_NAME $END_NAME $CYCLE_TIME"
   }
   if {! [info exists LINE] } {
	return (0)
   }
   ### Output Start_End_Pair ####
   set fgz    [list | gzip > ${REPFILE}.gz ]
   set repfid [open $fgz "w"]
   puts $repfid "## Start Endpoint Cycle ##"
   foreach STR [lsort -ascii -unique $LINE] {
	puts $repfid "$STR"
   }
   puts $repfid "## End of report ##"
   close $repfid

   ### PickUp clock Start_End_Pair ####
   if { [info exists STCLKs] } {
   	set STCLKs [lsort -ascii -unique $STCLKs]
	set stclkfid  [ open $STCLOCKFILE w ]
	foreach CLK $STCLKs {
		set period [get_attribute [get_clocks $CLK] period]
		puts $stclkfid "$CLK $period"
	}
	close $stclkfid
   }
   if { [info exists EDCLKs] } {
   	set EDCLKs [lsort -ascii -unique $EDCLKs]
	set edclkfid  [ open $EDCLOCKFILE w ]
	foreach CLK $EDCLKs {
		set period [get_attribute [get_clocks $CLK] period]
		puts $edclkfid "$CLK $period"
	}
	close $edclkfid
   }
   return (1)
}

proc MKDOWNSIZETCL { { INST_FILE } { OUT_TCL } {MAX_DRV 80} {MIN_DRV 40} {MAX_CAP 0.005} { INFO_DIR ./Info_Critical_Pins }  } {
   set fid  [open $INST_FILE]
   set ofid [open $OUT_TCL "w"]
   set DRV_STEP 10;	# Step for decrease drivability
   DONTTOUCH_CLOCK $INFO_DIR
   while {[gets $fid str]>=0} {
	if {[regexp "^#" $str]}	{ continue }
	set inst [get_cells -q $str -filter "is_combinational==true"]
	if {$inst == ""}	{ continue }
	if {[get_attribute -q $inst dont_touch] == "true"}	{ continue }
	set DRVCELL [get_attribute $inst ref_name ]
	regsub -all ".*X" $DRVCELL {} DRV
	set outpin [get_pins -of $inst -filter "direction==out"]
	set net_name [get_object_name [all_connected $outpin]]

	set capacitance_wire [get_attribute [get_net $net_name] wire_capacitance_max]
	set capacitance_eff  [get_attribute -q [get_pins $outpin] effective_capacitance_max]
	if {$capacitance_wire > $capacitance_eff} {
		set capacitance $capacitance_wire
	} else {
		set capacitance $capacitance_eff
	}
	if {$capacitance < $MAX_CAP} {
		set NEWCELL [DOWNSIZECELL $DRVCELL $MAX_DRV $MIN_DRV $DRV_STEP]
		if {$NEWCELL != "0"} {
			puts $ofid "size_cell [get_object_name $inst] $NEWCELL	;# $DRVCELL Cap:$capacitance"
		}
	}
   }
   close $fid
   close $ofid
}

proc DOWNSIZECELL { {CELL} {MAX_DRV 80} {MIN_DRV 40} {DRV_STEP 10} } {
	regsub -all ".*X" $CELL {} DRV
	if { $DRV <= $MIN_DRV } {
		return 0
	} else {
		if {$DRV > $MAX_DRV} {
			set NEWDRV 80
		} else {
			set NEWDRV [expr $DRV - 10]
		}
	}
	regsub "$DRV" $CELL "$NEWDRV" NEWCELL
	set CELL_CHECK_FLG [get_lib_cells -q */$NEWCELL]
	while {$CELL_CHECK_FLG==""} {
		set NEWDRV [expr $NEWDRV - $DRV_STEP]
		regsub "$DRV" $CELL "$NEWDRV" NEWCELL
		set CELL_CHECK_FLG [get_lib_cells -q */$NEWCELL]
	}
	if {$NEWDRV >= $MIN_DRV} {
		return $NEWCELL
	} else {
		return 0
	}
	
}
proc DONTTOUCH_CLOCK { {DIR_INFO ../Info_Critical_Pins} } {
	puts "Information: Search clocklist to apply donttouch cells"
	if {[catch "glob ls ${DIR_INFO}/*.clocklist.gz" files]} {
		puts "  # Error:        No clocklist file for apply dont_touch"
		continue
	}
	foreach file $files {
		puts "  $file"
		set FILE_EX [file extension $file]
		if {$FILE_EX == ".bz2"} {
			set fid  [open "|bzip2 -dc $file"]
		} elseif {$FILE_EX == ".gz"} {
			set fid  [open "|gzip -dc $file"]
		} else {
			set fid  [open $file]
		}
		while {[gets $fid str]>=0} {
			#puts "[lindex $str 0]"
			set_dont_touch [get_cells [lindex $str 0]]
		}
		close $fid
	}
}


