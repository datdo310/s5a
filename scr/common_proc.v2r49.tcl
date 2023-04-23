#################################################################
# common_proc.tcl
#
# Ver   : Date       : Description
# v2r00 : 2014/01/10 : Branch from v1r61 for MCU
# v2r01 : 2014/01/24 :
# v2r04 : 2014/07/17 : 
# v2r05 : 2014/11/11 : CHK_HIGHFREQ_DONTUSE_PATH (adjusted for max_delay)
# v2r06 : 2014/12/02 : mkEdtChainMask_2_1stSIN is added
# v2r07 : 2014/12/29 : slack_less 0->0.00001(PrimeTime2013.xx Bug)
# v2r08 : 2015/01/17 : proc chkClockAsData* are updated.
# v2r09 : 2015/01/23 : chkMEM changed target jk1308759_* -> jk*
# v2r10 : 2015/04/24 : GET_BIGDELAY_NET is added
# v2r11 : 2015/05/30 : CHK_SKEWED_MARGIN is added
# v2r13 : 2015/08/24 : bkTrace* was updated
# v2r14 : 2015/09/01 : chkClkReconvPin is updated
# v2r15 : 2015/09/21 : SKEWED_REP2PATH is added
#                    : DELTA_*2REP are added
# v2r16 : 2015/12/01 : DELTA_*2REP are changed to clock_expanded
# v2r17 : 2016/01/12 : CHK_SKEWED_MARGIN is updated for Bug
# v2r18 : 2016/01/21 : GET_CLOCK_CELLS is added to make clock list
# v2r19 : 2016/03/22 : CALC_STD_AREA is added to analyze VTH ratio
# v2r20 : 2016/07/01 : REPEATER_XTALK_FANOUT/REPEATER_SKEWED_FANOUT are added
# v2r21 : 2016/07/25 : chkGCLKPathAll(r4) is supported
# v2r22 : 2016/07/27 : CHK_KEEP_DONTTOUCH is supported
# v2r23 : 2016/09/12 : get_slack supports max_delay constraints
# v2r24 : 2017/01/06 : Update CHK_CLKVT for reducing TAT
# v2r25 : 2017/02/22 : Add COMP_VAR proc to compare variables
# v2r26 : 2017/03/09 : ADD SET_ASYNC_TRAN for RV28F Transition check
# v2r27 : 2017/04/17 : CLKVT support master -> generate line.
# v2r28 : 2017/05/15 : SDC Mask Procecure
# v2r29 : 2017/05/25 : change MK_HF_CMD (set_load -> set_ideal_network)
# v2r30 : 2017/06/06 : change CHECK_VTH/CHECK_PITCH (support RV28F)
# v2r31 : 2017/10/19 : CALC_STD_AREA support RV28F
# v2r32 : 2017/12/19 : MERGE_SDCMASK_PTSC changed for Naming rule
# v2r33 : 2018/01/30 : REPEATER_TRAN_FANOUT is added
# v2r34 : 2018/03/06 : Add UPSIZE_TRAN, Update: REPEATER_TRAN_FANOUT
# v2r35 : 2018/03/09 : chkClockAsDataAll support create_clocks too
# v2r36 : 2018/03/20 : MERGE_SDCMASK_PTSC add file name in comment
# v2r37 : 2018/08/09 : Add DONTTOUCH_CLOCK/MKDOWNSIZETCL to make downsize
# v2r38 : 2018/09/10 : Update GET_STARTEND_CYCLE to get no_path report
#                    : MERGE_SDCMASK_PTSC to add header
# v2r39 : 2019/10/8  : Update CHK_SKEWED_MARGIN to ADD (SPE pins)
# v2r40 : 2020/08/24 : CALC_STD_AREA support RV28FT
# v2r41 : 2020/09/01 : REPORT_DIRECT_CONNECTED_FF CHK_HIGHFREQ_DONTUSE
#                    : UPSIZE_CELL DOWNSIZECELL support RV28FT
# v2r43 : 2021/07/12 : CALC_STD_AREA support MF3
# v2r44 : 2021/07/21 : Add READ_OCV_INFO_FROM_DESIGN_CFG_CLOCK_DATA from Rcar-STAenv
#                    : Add READ_SPECIAL_OCV_CLOCK_DATA from Rcar-STAenv
# v2r45 : 2021/11/29 : change MK_HF_CMD use existance report
#                    : Delete dc_shell/ML netlist procs
# v2r46 : 2021/12/22 : Delete unused procs
# v2r47 : 2022/02/01 : globRecursive was added
# v2r48 : 2022/02/14 : Take back several deleted procs at v2r46
# v2r49 : 2022/03/02 : Add no_clock proc
#                    : Add FILE_OPEN, summarize hold timing procs
#################################################################

proc globRecursive {dir masks} {
    set result [list]
    foreach cur [lsort [glob -nocomplain -dir $dir *]] {
        if {[file isdirectory $cur]} {
            if {[file readable $cur]} {
                eval lappend result [globRecursive $cur $masks]
            }
        } else {
            foreach mask $masks {
                if {[string match $mask $cur]} {
                    lappend result $cur
                    break
                }
            }
        }
    }
    return $result
}

proc COL2LIST { {COLLECTION} } {
    set RETURN_VALUE {}
    if {[sizeof_collection $COLLECTION] == 0} {return {}}
    foreach_in_collection tmp $COLLECTION {
        lappend RETURN_VALUE [get_object_name $tmp]
    }
    return $RETURN_VALUE
}

#puts "# Define: READ_LISTFILE <instance-list-File>"
proc READ_LISTFILE { {FILE_NAME} } {
    if {![file exists $FILE_NAME]} {
        puts "* Error: $FILE_NAME was not found."
        return -1
    }
    set fid [open $FILE_NAME]
    set CHECK_LIST {}
    while {[gets $fid str]>=0} {
        if {[regexp {^#} $str]} {continue}
        if {![info exists CHECK_LIST]} {
            puts "* Warning: $str in $FILE_NAME was not found. Please confirm."
        }
        lappend CHECK_LIST $str
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

proc check_resource {comment} {
    set memory_ [mem]
    set date_   [date]
    set host_   [info hostname]
    echo "---< check resources >------------------------------------------------------"
    echo " DATE: ${date_} *MEM: ${memory_} KB *HOST: ${host_} *${comment}"
    echo "----------------------------------------------------------------------------"
}

proc MK_HF_CMD { {HF_FILE "./LOAD/hi_fanout_set_load.tcl"} {IN_REP} } {
    if {[info exist IN_REP] && ![file exist $IN_REP]} {
        echo "* Error: $IN_REP is not found."
        return
    }
    echo "* Information: Start making set_ideal_network for high fanout nets."
    redirect /dev/null {
        set HF_LIST [sh grep "VIOLATED" $IN_REP | awk '{print \$1}']
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
    echo "* Information: End making set_ideal_network for high fanout nets."
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

proc WRITE_FILE { {FILE_NAME} {LIST} } {
    set fid  [ open $FILE_NAME w ]
    set LINE [ join $LIST \n ]
    puts $fid $LINE
    close $fid
}

proc FILE_OPEN { {FILE} } {
    if {[file extension $FILE]==".gz"} {
        set FILE_EX ".gz"
    } elseif {[file extension $FILE]==".bz2"} {
        set FILE_EX ".bz2"
    } else {
        if {[file exist $FILE]} {
            set FILE_EX ""
            set open_file $FILE
        } elseif {[file exist "${FILE}.gz"]} {
            set FILE_EX ".gz"
            set open_file "${FILE}.gz"
        } elseif {[file exist "${FILE}.bz2"]} {
            set FILE_EX ".bz2"
            set open_file "${FILE}.bz2"
        }
    }
    if {[file exist $open_file]} {
        if {$FILE_EX==""} {
            return [open $open_file]
        } elseif {$FILE_EX==".gz"} {
            return [open "|gzip -dc $open_file"]
        } elseif {$FILE_EX==".bz2"} {
            return [open "|bzip2 -dc $open_file"]
        }
    } else {
        puts "* Error: $FILE cannot be found."
        return
    }
}

proc mkHOLD_slack { {TimingReport} } {
    puts "------------------------------------------------------------------------------------"
    puts "No    PathGroup                         WNS             TNS      VNE"
    puts "------------------------------------------------------------------------------------"
    set PATH_NO 0 ;# No
    set pre_path_group "xxx"
    set fid [FILE_OPEN $TimingReport]
    while {[gets $fid line] >= 0} {
        if {[regexp {Path Group: (\S+)} $line match path_group]} {
            if {$path_group != $pre_path_group} {
                lappend pg_list $path_group
                set TNS($path_group) 0
                set VNE($path_group) 0
            }
            set pre_path_group $path_group
            while {[gets $fid line] >= 0} {
                if {[regexp {slack \((?:VIOLATED.*|MET)\)\s+(\S+)} $line match slack]} {
                    lappend WNS($path_group) $slack
                    set TNS($path_group) [expr $TNS($path_group) + $slack]
                    incr VNE($path_group)
                    break
                }
            }
        }
    }
    close $fid
    foreach pg $pg_list {
        incr PATH_NO
        set wns [GET_MIN_VALUE_LIST $WNS($pg)]
        puts [format "%2d    %-30s    %5.3f ns    %9.3f ns    %d" $PATH_NO $pg $wns $TNS($pg) $VNE($pg)]
    }
    puts "------------------------------------------------------------------------------------"
}

proc mkHOLD_path { {TimingReport} } {
    puts "------------------------------------------------------------------------------------"
    puts "LaunchClock        CaptureClock        Startpoint        Endpoints     ClockDelay(Cap-Lau+CRPR)     Slack"
    puts "------------------------------------------------------------------------------------"

    set pre_path_group "xxx"
    set fid [FILE_OPEN $TimingReport]
    while {[gets $fid line] >= 0} {
        if {[regexp {Startpoint: (\S+)} $line match stpoint]} {
            set st_clock "xxx"
            set st_clock_delay "xxx"
            set ed_clock "xxx"
            set ed_clock_delay "xxx"
            set start_flg 0
            while {[gets $fid line] >= 0} {
                if {[regexp {Endpoint: (\S+)} $line match edpoint]} {
                } elseif {[regexp {Path Group: (\S+)} $line match path_group]} {
                    if {$pre_path_group != $path_group} {
                        puts "#################################################"
                        puts "####    $path_group"
                        puts "#################################################"
                        set pre_path_group $path_group
                    }
                } elseif {[regexp -- "----------" $line]} {
                    set start_flg 1
                } elseif {$start_flg==1 && $st_clock=="xxx" && [regexp {^\s*clock\s+(\S+)\s+\((:?rise|fall) edge\)} $line match st_clock]} {
                } elseif {$start_flg==1 && $st_clock_delay=="xxx" && [regexp "$stpoint" $line]} {
                    set elm [split [regsub -all {\s+} $line { }] " "]
                    set st_clock_delay [lindex $elm [expr [llength $elm] - 2]]
                } elseif {$start_flg==1 && ($st_clock!="xxx" && $ed_clock=="xxx") && [regexp {^\s*clock\s+(\S+)\s+\((?:rise|fall) edge\)} $line match ed_clock]} {
                } elseif {$start_flg==1 && ($st_clock_delay!="xxx" && $ed_clock_delay=="xxx") && [regexp "$edpoint" $line]} {
                    set elm [split [regsub -all {\s+} $line { }] " "]
                    set ed_clock_delay [lindex $elm [expr [llength $elm] - 2]]
                } elseif {$start_flg==1 && [regexp {^\s*clock reconvergence pessimism\s+(\S+)\s+\S+$} $line match crpr]} {
                } elseif {$start_flg==1 && [regexp {^\s*slack \((?:VIOLATED.*|MET)\)\s+(\S+)} $line match slack]} {
                    puts "$st_clock $ed_clock $stpoint $edpoint [expr $ed_clock_delay - $st_clock_delay + $crpr]($ed_clock_delay - $st_clock_delay + $crpr) $slack"
                    break
                }
            }
        }
    }
    close $fid
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

            #if {$DISP_CLK_st == $DISP_CLK_ed} {
                #puts [format "%5.3f %7.3f %5.2f ( %5.2f / %5.2f ) %41s %s %s" \
                    #$RATIO $SLACK $PERI $ST_TIME $ED_TIME $DISP_CLK_ed $START $END]
            #} else {
                #puts [format "%5.3f %7.3f %5.2f ( %5.2f / %5.2f ) %20s %20s %s %s" \
                    #$RATIO $SLACK $PERI $ST_TIME $ED_TIME $DISP_CLK_st $DISP_CLK_ed $START $END]
            #}
            puts [format "%5.3f %7.3f %5.2f ( %5.2f / %5.2f ) %20s %20s %s %s" \
                $RATIO $SLACK $PERI $ST_TIME $ED_TIME $DISP_CLK_st $DISP_CLK_ed $START $END]
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

    puts "$bar"
    puts [format "%9s %8s %8s %10s %5s / %5s %30s" "   Freq." ratio "  Period" TNS #VIO #TOTAL CLOCK]
    puts "$bar"
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
        lappend result [format "%9.2f %8.3f %8.3f %10.1f %5d / %5d %30s -> %s" \
            $WST_FREQ $WST_RATIO($clk) $WST_PERI($clk) $TNS($clk) $NUM($clk) $T_NUM($clk) $DISP_CLK_st $DISP_CLK_ed]
    }
    foreach tmp [lsort -index 1 -real -decreasing $result] {puts "$tmp"}
    puts "$bar"
}

proc mkMod_sum { {PathReport} } {
    set bar "+===============================================================================================+"
    set SRC [READ_LISTFILE $PathReport]
    set CLK_CROUP_LIST {}

    #sort by slack-ratio
    set SRC_mod {}
    foreach tmp $SRC {
        if {[regexp {^#} $tmp]} {continue}
        if {[regexp {^\+} $tmp]} {continue}
        if {[regexp {^RATIO} $tmp]} {continue}
        if {[regexp {^$} $tmp]} {continue}
        lappend SRC_mod $tmp
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
                puts "* Error: $tmp"
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
    puts "$bar"
    eval "puts \[format \"%${STRLEN(INST_ST)}s %${STRLEN(INST_ED)}s %7s %7s %8s %6s (%s/%s)\" START END RATIO WNS TNS PERI ST_CLK END_CLK]"
	
    puts "$bar"
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
                puts "* Error: $tmp"
                #exit;
            }
        }
        set TNS_      $TNS($tmp)
        set ST_MOD    [lindex [split $tmp ","] 0]
        set ED_MOD    [lindex [split $tmp ","] 1]
        eval "puts \[format \"%${STRLEN(INST_ST)}s %${STRLEN(INST_ED)}s %7.3f %7.3f %10.2f %6.2f (%30s/%-30s)\" \$ST_MOD \$ED_MOD \$RATIO \$SLACK \$TNS_ \$PERI \$CLK_ST \$CLK_ED]"
    }
    puts "$bar"
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
    if {[llength $VALUE_LIST] == 0} {
        return
    } elseif {[llength $VALUE_LIST] > 0} {
        foreach VALUE $VALUE_LIST { 
            if {![info exist MAX_VALUE]} {
                set MAX_VALUE $VALUE
            } elseif {$VALUE > $MAX_VALUE} {
                set MAX_VALUE $VALUE
            }
        }
        return $MAX_VALUE
    }
}

proc GET_MIN_VALUE_LIST {VALUE_LIST} {
    if {[llength $VALUE_LIST] == 0} {
        return
    } elseif {[llength $VALUE_LIST] > 0} {
        foreach VALUE $VALUE_LIST {
            if {![info exist MIN_VALUE]} {
                set MIN_VALUE $VALUE
            } elseif {$VALUE < $MIN_VALUE} {
                set MIN_VALUE $VALUE
            }
        }
        return $MIN_VALUE
    }
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

proc LIST_OR {{LIST_A} {LIST_B}} {
    set returnvalue $LIST_A
    foreach list_B $LIST_B {
        if {[lsearch $LIST_A $list_B]==-1} {
            lappend returnvalue $list_B
        }
    }
    return $returnvalue
}

proc LIST_AND {{LIST_A} {LIST_B}} {
    foreach list_B $LIST_B {
        if {[lsearch $LIST_A $list_B]!=-1} {
            lappend returnvalue $list_B
        }
    }
    return $returnvalue
}

proc REMOVE_FROM_LIST {{LIST_A} {LIST_B}} {
    foreach list_A $LIST_A {
        if {[lsearch $LIST_B $list_A]==-1} {
            lappend returnvalue $list_A
        }
    }
    return $returnvalue
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

# chkMACRO_type: Using by SYS_additional.ptsc, MBIST_const.ptsc
proc chkMACRO_type {{PIN_COLLECTION}} {
    set pins  [get_pins $PIN_COLLECTION]
    set cells [get_cells -of $pins]
    set refs  [get_attribute $cells ref_name]
    COUNT_REF $refs
}

# COUNT_REF: Using by chkMACRO_type procedure
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
        #exit
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

# procs for making SDC
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
    set PINALL [sort_collection -dictionary [get_attribute  [get_clocks *] sources] full_name]
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
        ##set PIN [get_object_name [remove_from_collection [all_con -l [all_con [get_ports $PIN]]] [get_ports $PIN]]]
        set PIN [get_object_name [remove_from_collection [all_fanout -flat -from [get_ports $PIN] -pin_levels 2] [get_ports $PIN]]]
    }
    set TAB     "$TAB  "
    set cells   [get_cells -of [get_pins $PIN]]

    set OUTpins ""
    foreach_in_collection cell $cells {
        if { [get_attribute [get_cells $cell] is_pad_cell] == "false" } {
            set OUTpins [add_to_collection -unique $OUTpins [get_pins -of $cell -filter pin_direction==out -quiet]]
        } else {
            set OUTpins [add_to_collection -unique $OUTpins [get_pins [all_fanout -flat -from [get_pins $PIN] -pin_levels 1] -filter pin_direction==out -quiet]]
        }
    }

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
                set name_clk "  { [get_object_name $clock] }"
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
    if {$::LOAD_MODEL != "NO_LOAD"} {
        puts "* Error: Please execute with NO_LOAD model."
        return
    }
    set ::timing_report_unconstrained_paths true
    puts "#------Clock reconvergence check----"
    foreach_in_collection inst [sort_collection -dictionary [get_clock_network_objects -type cell] full_name] {
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

proc ConfDRV { {str} } {
    set DRV0 [get_attribute [get_pins -of [get_cells -of [get_pins -of $str -leaf]] -filter lib_pin_name=~"DRVCTL0"] case_value]
    set DRV1 [get_attribute [get_pins -of [get_cells -of [get_pins -of $str -leaf]] -filter lib_pin_name=~"DRVCTL1"] case_value]
    if { $DRV0 == 1 && $DRV1 == 1 } {
        puts "Correct $str DRV0/1 == ${DRV0}/${DRV1}"
    } else {
        puts "NG      $str DRV0/1 == ${DRV0}/${DRV1}"
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
                puts "  ([get_attribute $pin lib_pin_name]) \{$CLKSTA\} [get_object_name $cell]"
            }
        }
    }
}

proc chkFieldMBISTclkSTOP {
    {
        CGG_GTD {
            SYS_TOP/SYSCTL/f_clock/isovdd_cggtop/clk*_gating/gck*/gck 
            SYS_TOP/SYSCTL/f_clock/isovdd_cggtop/cgg_cl*awo*_gating/gck*/gck
        }
    }
    { CGG_OUTPIN Q } { CGG_CLKPIN CP }
} {
    set CGG_GTD [get_cells $CGG_GTD]  
    foreach_in_collection tmp $CGG_GTD {
        set GTDoutnet [get_object_name [get_nets -of [get_pins -of $tmp -filter "lib_pin_name==$CGG_OUTPIN"]]]
        set clkName   [get_object_name [get_nets -of [get_pins $GTDoutnet]]]
        set inCLK     [get_object_name [get_pins -of $tmp -filter "lib_pin_name==$CGG_CLKPIN"]]
        #puts "* $inCLK ;# $clkName"
        if {[regexp {_mbist} $clkName]} {
            puts "# active clock ;# $inCLK ;# $clkName"
        } else {
            puts "set_clock_sense -stop_propagation -clock \[get_clocks FB_M_*\] \[get_pins $inCLK\] ;# $clkName"
        }
    }
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

proc chkMACROcase {{INST}} {
    suppress_message {ATTR-3}
    puts "-------------------------------------------"
    puts "T0: Tied 1'b0"
    puts "T1: Tied 1'b1"
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
};# End procs for making SDC

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
                foreach NG_CELL $HIGHFREQ_DONUSE_NG_CELL {
                    if {[string match $NG_CELL $cell_name] == 1 } {
                        #puts "$cell_name $inst_name"
                        lappend HIGHFREQ_DONUSE_OUT_MESSEAGE "$cell_name $inst_name"
                    }
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
    if {[string match "RV40F" $::PROCESS]} {
        set HIGHFREQ_DONUSE_NG_CELL     THH*
        set HIGHFREQ_DONUSE_OUT_MESSEAGE ""
    } elseif {[string match "RV28F" $::PROCESS]} {
        set HIGHFREQ_DONUSE_NG_CELL     {THH* *P140HVT}
        set HIGHFREQ_DONUSE_OUT_MESSEAGE ""
    } else {
        puts "* Error: \$PROCESS is not set or supported(RV40F/RV28F)."
    }

    ## ------- over 320MHz clocks ----------------
    ## to over 320MHz clocks
    set target_paths [get_timing_paths -to [get_clocks $OneCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
    if {[sizeof_collection $target_paths] == $max_target} {
        puts "* Error: $max_target or more paths reported in upper than [expr 1 / $TARGET_PERIOD * 1000]MHz."
    }
    CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD

    ## from over 320MHz clocks
    set target_paths [get_timing_paths -from [get_clocks $OneCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
    if {[sizeof_collection $target_paths] == $max_target} {
        puts "* Error: $max_target or more paths reported in upper than [expr 1 / $TARGET_PERIOD * 1000]MHz."
    }
    CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD


    ## ------- over 160MHz clocks halfcycle --------
    ## over 160MHz clocks with halfcycle fall_to
    set target_paths [get_timing_paths -fall_to [get_clocks $HalfCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
    if {[sizeof_collection $target_paths] == $max_target} {
        puts "* Error: $max_target or more paths reported in upper than [expr 1 / $TARGET_PERIOD2 * 1000]MHz(fall_to)."
    }
    CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD

    ## over 160MHz clocks with halfcycle fall_from
    set target_paths [get_timing_paths -fall_from [get_clocks $HalfCycleClks] -nworst $max_target -max_paths $max_target -slack_lesser_than $TARGET_PERIOD2]
    if {[sizeof_collection $target_paths] == $max_target} {
        puts "* Error: $max_target or more paths reported in upper than [expr 1 / $TARGET_PERIOD2 * 1000]MHz(fall_from)."
    }
    CHK_HIGHFREQ_DONTUSE_PATH $target_paths $TARGET_PERIOD

    ## ------- Print output report ----------------
    CHK_HIGHFREQ_DONTUSE_OUTREP $HIGHFREQ_DONUSE_OUT_MESSEAGE $OUT_REP
}

## output pin name from check_timing -over no_clock report
proc CHK_NO_CLOCK {INREP} {
    if {[file exist $INREP]} {
        set fid [FILE_OPEN $INREP]
        set flag 0
        while {[gets $fid line] >= 0} {
            if {[regexp {^-+$} $line]} {
                set flag 1
            } elseif {$flag == 1 && [regexp {^$} $line]} {
                set flag 0
            } elseif {$flag == 1 && ![regexp {^$} $line]} {
                puts "$line\tno_clock"
            }
        }
        close $fid
    } else {
        puts "* Error: $INREP is not found."
    }
}

## output pin name from report_analysis_coverage report
proc CHK_COVERAGE {INREP} {
    if {[file exist $INREP]} {
        set fid [FILE_OPEN $INREP]
        while {[gets $fid line] >= 0} {
            set elm [split $line " "]
            if {[regexp {(\S+)\((?:high|low)\)} [lindex $elm 0] match clkpin]} {
                if {[get_attribute [get_lib_pins -of [get_pins $clkpin]] is_clock_pin] == "true"} {
                    puts "$clkpin\t[lindex $elm 3]"
                }
            }
        }
        close $fid
    } else {
        puts "* Error: $INREP is not found."
    }
}

proc CHK_SKEWED_MARGIN {
    outfile
    {min_max max}
    {DLCLT_DRV_SMC_MAXTRAN_SLACK_RATIO 0.625}
    {DLCLT_DRV_SMC_MAXTRAN_OFFSET      0.4}
    {DLCLT_DRV_SMC_MAXTRAN_NWORST      1}
    {DLCLT_DRV_SMC_MAXTRAN_MAX_PATHS   200000}
} {
    set DLCLT_DRV_SMC_MAXTRAN_PINS         "SE TE SMC SPE SPEA SPEB"
    set DLCLT_DRV_SMC_MAXTRAN_REPORT_MODE  violated

    if { [catch {open $outfile "w"} out_fd] } {
        puts "Error(DLCLT): Cannot open SMC Maxtran report file. ($outfile)"
        return 1
    }
    suppress_message {UITE-416}

    puts $out_fd "#"
    puts $out_fd "# SMC pin Maxtransition report"
    puts $out_fd "#   Date : [date]"
    puts $out_fd "#"
    puts $out_fd "#   Pin                        Timing        Actual Tran   Slack   Judge"
    puts $out_fd "#                              Slack         ((Tran-$DLCLT_DRV_SMC_MAXTRAN_OFFSET)*$DLCLT_DRV_SMC_MAXTRAN_SLACK_RATIO)"
    puts $out_fd "# --------------------------------------------------------------------------"
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

            if { $slack == "" } { continue }; #y.mino 2015/09/13 No report unconstrained path
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
        if {[sizeof_collection [filter_collection -regexp [get_cells -quiet -hierarchical -filter "is_hierarchical==false"] {ref_name=~"TU?[LSWH]H.*X.*"}]] > 0} {
            set Cell8T_H     [get_cells -quiet -h * -filter "ref_name=~THH*"]
            set Cell8T_M     [get_cells -quiet -h * -filter "ref_name=~TSH*"]
            set Cell8T_L     [get_cells -quiet -h * -filter "ref_name=~TULH*"]
            set Cell8T_Std   [add_to_collection [add_to_collection $Cell8T_H $Cell8T_M] $Cell8T_L]

            set area8T_H 0.0; foreach_in_collection cell $Cell8T_H { set area8T_H [expr $area8T_H + [get_attribute $cell area]] }
            set area8T_M 0.0; foreach_in_collection cell $Cell8T_M { set area8T_M [expr $area8T_M + [get_attribute $cell area]] }
            set area8T_L 0.0; foreach_in_collection cell $Cell8T_L { set area8T_L [expr $area8T_L + [get_attribute $cell area]] }
            set area8T_Total [expr $area8T_H + $area8T_M + $area8T_L ]

            set ratio8T_H [expr $area8T_H/$area8T_Total * 100]
            set ratio8T_M [expr $area8T_M/$area8T_Total * 100]
            set ratio8T_L [expr $area8T_L/$area8T_Total * 100]
            puts "-----------------------------------------------"
            puts "               Area 8Track (Ratio)"
            puts [format {ULVT_8T    %.1f (%.2f%s)} $area8T_L $ratio8T_L "%"]
            puts [format {SVT_8T     %.1f (%.2f%s)} $area8T_M $ratio8T_M "%"]
            puts [format {HVT_8T     %.1f (%.2f%s)} $area8T_H $ratio8T_H "%"]
            puts [format {Total_8T   %.1f --- Std Area(wo WVT)} $area8T_Total]
            puts "-----------------------------------------------"
        }
        if {[sizeof_collection [get_cells -quiet -h * -filter "ref_name=~*BWP7T40P140*"]] > 0} {
            set Cell7T_H     [get_cells -quiet -h * -filter "ref_name=~*BWP7T40P140HVT"]
            set Cell7T_M     [get_cells -quiet -h * -filter "ref_name=~*BWP7T40P140"]
            set Cell7T_L     [get_cells -quiet -h * -filter "ref_name=~*BWP7T40P140ULVT"]
            set Cell7T_Std   [add_to_collection [add_to_collection $Cell7T_H $Cell7T_M] $Cell7T_L]

            set area7T_H 0.0; foreach_in_collection cell $Cell7T_H { set area7T_H [expr $area7T_H + [get_attribute $cell area]] }
            set area7T_M 0.0; foreach_in_collection cell $Cell7T_M { set area7T_M [expr $area7T_M + [get_attribute $cell area]] }
            set area7T_L 0.0; foreach_in_collection cell $Cell7T_L { set area7T_L [expr $area7T_L + [get_attribute $cell area]] }
            set area7T_Total [expr $area7T_H + $area7T_M + $area7T_L ]

            set ratio7T_H [expr $area7T_H/$area7T_Total * 100]
            set ratio7T_M [expr $area7T_M/$area7T_Total * 100]
            set ratio7T_L [expr $area7T_L/$area7T_Total * 100]
            puts "-----------------------------------------------"
            puts "               Area 7Track (Ratio)"
            puts [format {ULVT_7T    %.1f (%.2f%s)} $area7T_L $ratio7T_L "%"]
            puts [format {SVT_7T     %.1f (%.2f%s)} $area7T_M $ratio7T_M "%"]
            puts [format {HVT_7T     %.1f (%.2f%s)} $area7T_H $ratio7T_H "%"]
            puts [format {Total_7T   %.1f --- Std Area(wo WVT)} $area7T_Total]
            puts "-----------------------------------------------"
        }
        set Cell_Total [get_cells -quiet -h * -filter "is_hierarchical==false"]
        set Cell_H     [get_cells -quiet -h * -filter "ref_name=~THH*||ref_name=~*BWP7T40P140HVT"]
        set Cell_M     [get_cells -quiet -h * -filter "ref_name=~TSH*||ref_name=~*BWP7T40P140"]
        set Cell_L     [get_cells -quiet -h * -filter "ref_name=~TULH*||ref_name=~*BWP7T40P140ULVT"]
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
    } elseif {[string match "MF3" $::PROCESS]} {
        set Cell_Total [get_cells -h * -filter "is_hierarchical==false"]
        set Cell_M     [get_cells -h * -filter "ref_name=~TM6*"]
        set Cell_L     [get_cells -h * -filter "ref_name=~TL6*"]
        set Cell_Std   [add_to_collection $Cell_M $Cell_L]

        set area_M 0.0; foreach_in_collection cell $Cell_M { set area_M [expr $area_M + [get_attribute $cell area]] }
        set area_L 0.0; foreach_in_collection cell $Cell_L { set area_L [expr $area_L + [get_attribute $cell area]] }
        set area_Total [expr  $area_M + $area_L ]

        set ratio_M [expr $area_M/$area_Total * 100]
        set ratio_L [expr $area_L/$area_Total * 100]

        puts "-----------------------------------------------"
        puts "               Area  (Ratio)"
        puts [format {LVT     %.1f (%.2f%s)} $area_L $ratio_L "%"]
        puts [format {MVT     %.1f (%.2f%s)} $area_M $ratio_M "%"]
        puts [format {Total   %.1f --- Std Area(wo WVT)} $area_Total]
        puts "-----------------------------------------------"
    } else {
        puts "* Error: PROCESS = $PROCESS is not supported."
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

proc MERGE_SDCMASK_PTSC { {DIR 41_SDCMASK_RGETPIN} {HEADER ACx} } {
    if {[catch "glob ls ${DIR}/*.tcl" files]} {
        puts "Error: Cannot find target tcl in $DIR"
        return
    }
    set ofile [format "%s.ptsc" $DIR]

    # Attach Header for ptsc
    regsub {.*/} $DIR {} module
    regsub {^}   $module "${HEADER}_" newfile 
    regsub "${module}.ptsc" $ofile "${newfile}.ptsc" ofile

    # Write Constraints files
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
        lappend LINE "# No_path"
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
    return 1
}

proc READ_OCV_INFO_FROM_DESIGN_CFG_CLOCK_DATA {} {
    if {![info exists ::ocv_param_table_clock_data]} {
        puts "* Error : OCV parameter table \"ocv_param_table\" not defined in design.info file."
        exit
    }

    puts ""
    set max_len 0
    foreach list $::ocv_param_table_clock_data {
        if {[llength $list] != 14} {
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
        foreach item [lrange $list 2 13] {
            if {![regexp {^(\d.)?\d+$} $item]} {
                puts "* Error : Not a value. \"$item\" in \"$list\""
                exit
            }
        }

        set ary_cond_delay "[lindex $list 0],[lindex $list 1]"
        set derate_cell_early_clock       [lindex $list 2]
        set derate_cell_early_data        [lindex $list 3]
        set derate_cell_late_clock        [lindex $list 4]
        set derate_cell_late_data         [lindex $list 5]
        set derate_net_early_clock        [lindex $list 6]
        set derate_net_early_data         [lindex $list 7]
        set derate_net_late_clock         [lindex $list 8]
        set derate_net_late_data          [lindex $list 9]
        set derate_cell_early_oside_clock [lindex $list 10]
        set derate_cell_early_oside_data  [lindex $list 11]
        set derate_cell_late_oside_clock  [lindex $list 12]
        set derate_cell_late_oside_data   [lindex $list 13]

        set ::ocv_param_list_clock_data($ary_cond_delay) [list \
            $derate_cell_early_clock $derate_cell_early_data \
            $derate_cell_late_clock  $derate_cell_late_data \
            $derate_net_early_clock  $derate_net_early_data \
            $derate_net_late_clock   $derate_net_late_data \
            $derate_cell_early_oside_clock $derate_cell_early_oside_data \
            $derate_cell_late_oside_clock  $derate_cell_late_oside_data \
        ]

        if {$max_len < [string length [lindex $list 0]]} {
            set max_len [string length [lindex $list 0]]
        }
    }
    if {![info exists ::ocv_param_list_clock_data]} {
        puts "* Error : Cannot read OCV parameter(s)."
        exit
    }

    # output OCV parameters
    puts "* Information : OCV Parameter Settings."
    puts "CONDITION   (SETUP/HOLD)  cell(early/late) net(early/late) outside(early/late)"
    foreach item [lsort [array names ::ocv_param_list_clock_data]] {
        set elm [split $item ","]
        puts -nonewline [format "%-${max_len}s" [lindex $elm 0]]
        puts -nonewline [format {  %-8s} [lindex $elm 1]]
        puts [join [concat $::ocv_param_list_clock_data($item)] "    "]
    }
    puts ""
    return 0
}

################################################################################
# Proc : READ_SPECIAL_OCV_CLOCK_DATA
#   read ocv value for special library.
################################################################################
proc READ_SPECIAL_OCV_CLOCK_DATA {} {
    if {![info exists ::special_ocv_param_table_clock_data]} {
        puts "* Information : OCV parameter table for special cells \"special_ocv_param_table_clock_data\" is not defined in design.info file."
        return
    }

    puts ""
    foreach list $::special_ocv_param_table_clock_data {
        if {[llength $list] != 7} {
            puts "* Error : lack of item(s). at \"$list\""
            exit 1
        }

        # check STA condition
        if { ${::CONDITION} != [lindex $list 0] || ${::DELAY} != [lindex $list 1]} {continue}
        set cond_delay "[lindex $list 0],[lindex $list 1]"
        eval "set libs \$::[lindex $list 2]"
        set derate_cell_clock_early       [lindex $list 3]
        set derate_cell_data_early        [lindex $list 4]
        set derate_cell_clock_late        [lindex $list 5]
        set derate_cell_data_late         [lindex $list 6]
        if {![info exists ::special_ocv_param_list_clock_data($cond_delay)]} {
            set ::special_ocv_param_list_clock_data($cond_delay) {}
        }
        foreach lib $libs {
            set ::special_ocv_param_list_clock_data($cond_delay) [concat \
                $::special_ocv_param_list_clock_data($cond_delay) \
                [list [list $lib $derate_cell_clock_early $derate_cell_data_early $derate_cell_clock_late $derate_cell_data_late]] \
            ]
        }
    }
    # check ocv parameters
    if {![info exists ::special_ocv_param_list_clock_data]} {
        puts "* Error : No OCV parameter found in special OCV table. Check table for \"${::CONDITION}\", \"${::DELAY}\" "
        exit 1
    }
    # << ouput ocv parameters >>
    puts "* Information : special ocv parameter settings."
    foreach item [lsort [array names ::special_ocv_param_list_clock_data]] {
        set elm [split $item ","]
        foreach item2 $::special_ocv_param_list_clock_data($item) {
            puts "[lindex $elm 0]\t [lindex $elm 1]\t $item2"
        }
    }
    puts ""
    return 0
} ;# end proc
