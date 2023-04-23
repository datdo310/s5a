proc CHK_CU { { LOG_DIR "./LOG" } { RESULT_DIR "CU_RESULT" } { EXPECTED_FILE "./CU_expect.list" } { SETUP_DEF_CU 0.300 } { base_cycle 1.240 } { base_jitter 0.100 } } {
    if {![file exists $EXPECTED_FILE]} {
        puts "Error: $EXPECTED_FILE was not found."
        return 
    }
    set STA_MODE $::STA_MODE
    if {$STA_MODE == "SYSTEM"} {
        set CU_MODE $STA_MODE
    } elseif {$STA_MODE == "DFT"} {
        set DFT_MODE $::DFT_MODE
        set CU_MODE $DFT_MODE
    }
    DIR_CHECK $RESULT_DIR

    if {$::ENABLE_AOCVM == "true"} {
        set FILES_A [glob ls ${LOG_DIR}/CU_AOCVM_${::MODE}${::SUFFIX}${::OPT_FLAG}.log*]
    } else {
        set FILES_A [glob ls ${LOG_DIR}/CU_${::MODE}${::SUFFIX}${::OPT_FLAG}.log*]
    }

    ## Check CU value from CU LOG
    foreach FILE_A $FILES_A {
        # reject condition
        if {[regexp "XTALK" $FILE_A ] || [regexp "SMVA" $FILE_A] || [regexp "5P" $FILE_A] || [regexp "5Z" $FILE_A] || [regexp "MP" $FILE_A]} {
            puts "          Skip $FILE_A"
        } else {
            if {[regexp "SETUP" $FILE_A]} {
                set TYPE SETUP
            } elseif {[regexp "HOLD" $FILE_A]} {
                set TYPE HOLD
            } else {
                set TYPE UNKWN
            }
            ## Define CONDITION
            regsub "$LOG_DIR/CU_" $FILE_A {} COND
            regsub "_SYSTEM.*"    $COND   {} COND
            regsub "_DFT.*"       $COND   {} COND
            regsub "XTALK_"       $COND   {} COND
            regsub "SMVA_"        $COND   {} COND


            ## Define Output File
            set FILE_O ${CU_MODE}_${COND}_${TYPE}.csv

            ## Check CU value from CU LOG
            puts "Reading $FILE_A"
            set FILE_EX_A [file extension $FILE_A]
            if {$FILE_EX_A == ".bz2"} {
                set fid_a  [open "|bzip2 -dc $FILE_A"]
            } elseif {$FILE_EX_A == ".gz"} {
                set fid_a  [open "|gzip -dc $FILE_A"]
            } else {
                set fid_a  [open $FILE_A]
            }
            set status 0
            set fid_o  [ open "$RESULT_DIR/$FILE_O" w ]
            puts $fid_o "LaunchCLK,CaptureCLK,LaunchPeriod,CapturePeriod,SetupCU,HoldCU,ExpSetupCU,ExpHoldCU,AutoSetupJudge,AutoHoldJudge,SetupPathExist,HoldPathExist,SetupJudge,HoldJudge,SetupComments,HoldComments"
            while {[gets $fid_a str]>=0} {
                if { $status == 2 && [regexp "^$" $str] } {
                    set status 0
                }
                if { $status == 2 } {
                    set st_clk      [lindex $str 0]
                    set ed_clk      [lindex $str 1]
                    set hold_CU     [lindex $str 2]
                    set setup_CU    [lindex $str 3]
                    set st_period   [CHK_CU_PERIOD $st_clk]
                    set ed_period   [CHK_CU_PERIOD $ed_clk]
                    set target_period [GET_MAX_VALUE $st_period $ed_period]
                    #set exp_setup_CU [CHK_CU_EXPECT_SETUP $target_period $EXPECTED_FILE $SETUP_DEF_CU]      ;# Get CU from Period Calculation
                    set exp_setup_CU [CHK_CU_EXPECT_SETUP $target_period $base_cycle $base_jitter $SETUP_DEF_CU]      ;# Get CU from Period Calculation
                    set exp_hold_CU [CHK_CU_EXPECT_HOLD $COND $EXPECTED_FILE]

                    ## Margin calculate from clock name matching
                    set exp_setup_CU [expr $exp_setup_CU + [CHK_CU_MARGIN $st_clk $ed_clk SETUP $EXPECTED_FILE]]
                    set exp_hold_CU  [expr $exp_hold_CU  + [CHK_CU_MARGIN $st_clk $ed_clk HOLD  $EXPECTED_FILE]]

                    ## RESET CU
                    set exp_setup_CU [CHK_CU_RESET_CU $st_clk $ed_clk $exp_setup_CU SETUP $EXPECTED_FILE]
                    set exp_hold_CU  [CHK_CU_RESET_CU $st_clk $ed_clk $exp_hold_CU  HOLD  $EXPECTED_FILE]

                    ## Judge between expectation and log
                    set SETUP_JUDGE [CHK_CU_JUDGE $exp_setup_CU $setup_CU]
                    set HOLD_JUDGE  [CHK_CU_JUDGE $exp_hold_CU  $hold_CU]

                    ## Check timing path existance
                    if {$SETUP_JUDGE == "NG"} {
                        set setup_path_exist [CHK_CU_INTER_CLOCK SETUP $st_clk $ed_clk]
                    } else {
                        set setup_path_exist ""
                    }
                    if {$HOLD_JUDGE == "NG"} {
                        set hold_path_exist  [CHK_CU_INTER_CLOCK HOLD  $st_clk $ed_clk]
                    } else {
                        set hold_path_exist ""
                    }

                    ## Print results
                    puts $fid_o [format "%s,%s,%.3f,%.3f,%.3f,%.3f,%.3f,%.3f,%s,%s,%s,%s" $st_clk $ed_clk $st_period $ed_period $setup_CU $hold_CU $exp_setup_CU $exp_hold_CU $SETUP_JUDGE $HOLD_JUDGE $setup_path_exist $hold_path_exist]
                }
                if {[regexp "^(\ )*Object(\ )*Object(\ )*Uncertainty(\ )*Uncertainty" $str] } {
                    set status 1
                } elseif { $status == 1 && [regexp "^\-\-\-\-\-\-\-" $str] } {
                    set status 2
                }
            }
            close $fid_a
            puts $fid_o ""
            close $fid_o
        }
    }
}
proc CHK_CU_JUDGE { {EXP} {ACT} {OK_DIFF 0.001} } {
    if {[expr $EXP - $ACT] < $OK_DIFF && [expr $ACT - $EXP] < $OK_DIFF} {
        return "OK"
    } else {
        return "NG"
    }
}
proc CHK_CU_PERIOD { {CLOCK} } {
    regsub {\(r\)} $CLOCK {} CLOCK
    regsub {\(f\)} $CLOCK {} CLOCK
    set clock_period [get_attribute [get_clocks $CLOCK] period]
    return $clock_period
}

proc CHK_CU_RESET_CU { { LAUNCH_CLK } { CAPTURE_CLK } {ORG_CU 0} { TYPE SETUP } { EXPECT_FILE ./CU_expect.list } } {
    set fid_r  [open $EXPECT_FILE]
    while { [gets $fid_r str] >= 0 } {
        if { [regexp "^#" $str] || [regexp "^$" $str] } {
        } elseif { [regexp "^RESET\," $str] } {
            regsub -all {,} $str { } str2
            set RESET_TYPE    [lindex $str2 1]      ;# SETUP/HOLD
            set RESET_LAUNCH  [lindex $str2 2]      ;# LAUNCH CLOCK
            set RESET_CAPTURE [lindex $str2 3]      ;# CAPTURE CLOCK
            set RESET_CU      [lindex $str2 4]      ;# CU VALUE
            #puts "ACT:$PERIOD,EXP:$EXP_PERIOD,EXP_CU:$EXP_CU"
            if { [string match $RESET_LAUNCH $LAUNCH_CLK] && [string match $RESET_CAPTURE $CAPTURE_CLK] && [string match $RESET_TYPE $TYPE] } {
                close $fid_r
                return $RESET_CU
            }
        }
    }
    close $fid_r
    return $ORG_CU
}

proc CHK_CU_MARGIN { { LAUNCH_CLK } { CAPTURE_CLK } { TYPE SETUP } { EXPECT_FILE ./CU_expect.list } } {
    set fid_r  [open $EXPECT_FILE]
    set RETURN_MARGIN_CU 0
    while { [gets $fid_r str] >= 0 } {
        if { [regexp "^#" $str] || [regexp "^$" $str] } {
        } elseif { [regexp "^MARGIN\," $str] } {
            regsub -all {,} $str { } str2
            set MARGIN_TYPE    [lindex $str2 1]     ;# SETUP/HOLD
            set MARGIN_LAUNCH  [lindex $str2 2]     ;# LAUNCH CLOCK
            set MARGIN_CAPTURE [lindex $str2 3]     ;# CAPTURE CLOCK
            set MARGIN_CU      [lindex $str2 4]     ;# MARGIN VALUE
            #puts "ACT:$PERIOD,EXP:$EXP_PERIOD,EXP_CU:$EXP_CU"
            if { [string match $MARGIN_LAUNCH $LAUNCH_CLK] && [string match $MARGIN_CAPTURE $CAPTURE_CLK] && [string match $MARGIN_TYPE $TYPE] } {
                set RETURN_MARGIN_CU [expr $RETURN_MARGIN_CU + $MARGIN_CU]
            }
        }
    }
    close $fid_r
    return $RETURN_MARGIN_CU
}

proc CHK_CU_INTER_CLOCK { { TYPE SETUP } { LAUNCH_CLK } { CAPTURE_CLK } } {
    if {$TYPE == "SETUP"} {
        set delay "max"
    } else {
        set delay "min"
    }
    if {[regexp {\(r\)} $LAUNCH_CLK]} {
        set from "-rise_from"
    } elseif {[regexp {\(f\)} $LAUNCH_CLK]} {
        set from "-fall_from"
    } else {
        set from "-from"
    }
    if {[regexp {\(r\)} $CAPTURE_CLK]} {
        set to "-rise_to"
    } elseif {[regexp {\(f\)} $CAPTURE_CLK]} {
        set to "-fall_to"
    } else {
        set to "-to"
    }
    regsub {\(r\)} $LAUNCH_CLK {} LAUNCH_CLK
    regsub {\(f\)} $LAUNCH_CLK {} LAUNCH_CLK
    regsub {\(r\)} $CAPTURE_CLK {} CAPTURE_CLK
    regsub {\(f\)} $CAPTURE_CLK {} CAPTURE_CLK
    if {[sizeof_collection [get_timing_paths -delay_type $delay $from [get_clocks $LAUNCH_CLK] $to [get_clocks $CAPTURE_CLK]]] > 0} {
        set inter_clock "TRUE"
    } else {
        set inter_clock "FALSE or NoPath"
    }
    return $inter_clock
}

#proc CHK_CU_EXPECT_SETUP { { PERIOD } { EXPECT_FILE ./CU_expect.list } { DEF_CU } } {
#    set fid_r  [open $EXPECT_FILE]
#    while { [gets $fid_r str] >= 0 } {
#        if { [regexp "^#" $str] || [regexp "^$" $str] } {
#        } elseif { [regexp "^SETUP\," $str] } {
#            regsub -all {,} $str { } str2
#            set EXP_PERIOD [lindex $str2 1]
#            set EXP_CU [lindex $str2 2]
#            #puts "ACT:$PERIOD,EXP:$EXP_PERIOD,EXP_CU:$EXP_CU"
#            if { $EXP_PERIOD == $PERIOD } {
#                set EXP_CU [lindex $str2 2]
#                close $fid_r
#                return $EXP_CU
#            }
#        }
#    }
#    close $fid_r
#    return $DEF_CU
#        
#}

proc CHK_CU_EXPECT_SETUP { {PERIOD 1.240} {base_cycle 1.240} {base_jitter 0.100} {MAX_CU 0.300} } {
    set jitter_cu [expr $base_jitter * sqrt($PERIOD/$base_cycle)]
    set cu_value_setup [expr ceil( [expr ( $jitter_cu ) * 1000] ) / 1000]
    if { $cu_value_setup > $MAX_CU } {
        set cu_value_setup $MAX_CU
    }
    return $cu_value_setup
}

proc CHK_CU_EXPECT_HOLD { { CONDITION } { EXPECT_FILE ./CU_expect.list } } {
    set fid_r  [open $EXPECT_FILE]
    while { [gets $fid_r str] >= 0 } {
        if { [regexp "^#" $str] || [regexp "^$" $str] } {
        } elseif { [regexp "^HOLD\," $str] } {
            regsub -all {,} $str { } str2
            set EXP_COND [lindex $str2 1]
            set EXP_CU   [lindex $str2 2]
            #puts "ACT:$PERIOD,EXP:$EXP_PERIOD,EXP_CU:$EXP_CU"
            if { [string match $EXP_COND $CONDITION] } {
                set EXP_CU [lindex $str2 2]
                close $fid_r
                return $EXP_CU
            }
        }
    }
    close $fid_r
    return 1000
}

