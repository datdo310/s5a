###############################################
#  WRITE_SDC.tcl  
#  Reject Logic0/output Logic1/output from SDC
#  version:   v0p9  added for MCU const files
#             v0p91 Delete AC for STA SDC
#             v1p00 Read SYS_ATOM.ptsc
#             v1p01 Read module/*.tcl
#             v1p02 handle without module/*.tcl
#             v1p03 add WRITE CU
#             v1p04 clock_gating_check from ptsc to write_script
#             v1p05 add variable to CU setting
#             v1p06 add significant_digits
###############################################
proc SDC_ITEM_REJECT_LOGIC_CASE { {SDC} } {
    set INPUT  [open $SDC]
    while {! [eof ${INPUT}]} {
        set LINE [gets ${INPUT}]
        #puts "#(Original) $LINE"
        regsub {^ *} ${LINE} {} TMP_LINE
        set LIST_LINE [split [regsub -all { +} ${TMP_LINE} { }]]
        #set INDEX [lsearch -regexp ${LIST_LINE} {.*\/?Logic[01]\/output.*}]
        set INDEX [lsearch -regexp ${LIST_LINE} {^\{?([^\{]*\/L|L)ogic[01]\/output[\}\]]*$}]

        if {${INDEX} > -1} {
            while {${INDEX} > -1} {
                set TARGET [lindex ${LIST_LINE} ${INDEX}]
                #regsub {[^\{]*\/?Logic[01]\/output} ${TARGET} "" TMP_LINE
                regsub {([^\{]*\/L|L)ogic[01]\/output} ${TARGET} "" TMP_LINE
                set NEW_LIST [lreplace ${LIST_LINE} ${INDEX} ${INDEX} ${TMP_LINE}]  
                set LIST_LINE ${NEW_LIST}
                #set INDEX [lsearch -regexp ${LIST_LINE} {.*\/?Logic[01]\/output.*}]
                set INDEX [lsearch -regexp ${LIST_LINE} {^\{?([^\{]*\/L|L)ogic[01]\/output[\}\]]*$}]
            }
            set NEW_LINE [join ${LIST_LINE}]
            if {[regexp {\{ *\}} $NEW_LINE] > 0} {
                set LINE [concat "#Empty-list made by rejecting Logic0/output,Logic1/output had disabled : " ${NEW_LINE}]
            } elseif {[regexp {\[ *get[^ ]+s +\]} $NEW_LINE] > 0} {
                set LINE [concat "#Command with empty-target made by rejecting Logic0/output,Logic1/output had disabled : " ${NEW_LINE}]
            } else {
                set LINE ${NEW_LINE}
            }
        }
        echo ${LINE}
    }
}

#Extract constraint with variable replacing(Not using from 2017/0525)
proc SDC_COMMAND_EXTRACTION { {CONST} {COMMAND} } {
    set INPUT  [open $CONST]

    set VAL_COUNT 0
    set VAL_LIST  ""
    set PUT_LINE false
    set LINE_BEFORE ""

    while {! [eof ${INPUT}]} {
        set LINE [gets ${INPUT}]
        #Extract variable at "set" line
        if {[regexp {^ *set +} ${LINE}] > 0} {
            regsub {^ *} ${LINE} {} TMP_LINE
            set LIST_LINE [split [regsub -all { +} ${TMP_LINE} { }]]
            regsub -all {\"} [lindex ${LIST_LINE} 2] {} TMP_LINE
            set PARAM [lindex ${LIST_LINE} 1]
            if {[llength $LIST_LINE] == 3} {
                #puts "$LIST_LINE"
                set VALUE [subst ${TMP_LINE}]
                set VALIABLE_([lindex ${LIST_LINE} 1]) ${VALUE}
                #puts "set $PARAM $VALUE"
                set $PARAM $VALUE
                #puts "fin"
                incr VAL_COUNT
                lappend VAL_LIST $PARAM
            } else {
                #puts "$LIST_LINE"
                #set VALIABLE_([lindex ${LIST_LINE} 1]) {}
                set $PARAM {Error_Cannot_Get_Variable}
            }
        } else {
            #Not "set" line
            #Judge to show line or not
            if { [regexp {^ *#} ${LINE}] == 1 } {
                set PUT_LINE false
            } elseif { [regexp ${COMMAND} ${LINE}] == 1 } {
                set PUT_LINE true
            } elseif { [regexp {\\$} ${LINE_BEFORE}] == 1 } {
                #No Processing
            } else {
                set PUT_LINE false
            }

            if {${PUT_LINE}} {
                #Replace variable
                if {[llength ${VAL_LIST}] > 0} {
                    foreach VAL ${VAL_LIST} {
                        if { [regexp {\$} ${LINE}] == 1 } {
                            if { [regexp {\$\{.*\}} ${LINE}] == 1 } {
                                regsub "\\\${$VAL}" ${LINE} $VALIABLE_($VAL) NEWLINE
                                #regsub "\\\${$VAL}" ${LINE} [subst $[subst ::$VAL]] NEWLINE
                            } else {
                                regsub "\\\$$VAL" ${LINE} $VALIABLE_($VAL) NEWLINE
                            }
                            set LINE    ${NEWLINE}
                        }
                        #puts "#set $VAL $VALIABLE_($VAL)"
                    }
                }
                echo "${LINE}"
            }
            set LINE_BEFORE ${LINE}
        }
    }
    close ${INPUT}
}

## Get Command from "write_script" result into OUTFILE(append write)
proc WRITE_SCR_EXTRACTION { {COMMAND} {OUT_FILE} } {
    global MODE
    global CLOCK_MODE
    global DFT_MODE
    if {[info exist DFT_MODE]} {
        set SDC_MODE "${MODE}_${DFT_MODE}"
    } else {
        set SDC_MODE ${MODE}
    }
    set TEMP_SCR LOG/temporary_scr_${SDC_MODE}_${CLOCK_MODE}.write_scr
    write_script -format ptsh  -nosplit -output $TEMP_SCR
    set fid  [open $TEMP_SCR]
    set OUT  [open $OUT_FILE "a"]
    while {[gets $fid str]>=0} {
        if {[string match  "${COMMAND}*" $str] } {
            puts $OUT "$str"
        }
    }
    close $fid
    close $OUT
    sh rm -rf $TEMP_SCR
}

proc WRITE_SDC {{SDC} {VERSION 2.0} {STA_METHOD CIS} {DIGITS 4}} {

    global MODE
    global STA_MODE
    global CLOCK_MODE
    global APPLY_DIR
    global CONDITION

    global DFT_MODE
    if {[info exist DFT_MODE]} {
        set SDC_MODE "${MODE}_${DFT_MODE}"
    } else {
        set SDC_MODE ${MODE}
    }

    set START_TIME [date]
    if {${STA_MODE}=="SYSTEM" || $STA_METHOD=="MCU"} {
        puts "Canceling AC-Related constraints..."
        remove_input_delay  [all_inputs]
        remove_output_delay [all_outputs]
        remove_capacitance  [add_to_collection [all_inputs] [all_outputs]]
        #puts "update_timing..."
        #update_timing
    }

    puts "Start writing SDC..."
    write_sdc -version ${VERSION} -nosplit -significant_digits 4 LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc

    if {$STA_METHOD=="MCU"} {
        set cu_out [open LOG/${SDC_MODE}_CU_${CLOCK_MODE}.sdc.org "w"]
        set fid    [open LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc]
        while {[gets $fid str]>=0} {
            if {[string match  "set_clock_uncertainty*" $str] } {
                puts $cu_out "$str"
            }
        }
        close $fid
        close $cu_out
        sh ./bin/add_PnR_margin_ToCU.pl LOG/${SDC_MODE}_CU_${CLOCK_MODE}.sdc.org LOG/${SDC_MODE}_CU_${CLOCK_MODE}.sdc
        sh \
            grep -v '^set_load' LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc | \
            grep -v '^set_clock_uncertainty' | \
            grep -v '^set_clock_latency' \
            > LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc.mod
        sh mv LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc.mod LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
    }

    switch -regexp -- ${STA_MODE} {
        ^(SYSTEM) {
            if {$STA_METHOD=="MCU"} {
                set FILE_ACIN_SETUP  ${APPLY_DIR}/System/AC/SYS_AC_IN_SETUP_${CLOCK_MODE}.ptsc
                set FILE_ACOUT_SETUP ${APPLY_DIR}/System/AC/SYS_AC_OUT_SETUP_${CLOCK_MODE}.ptsc
                set FILE_ACIN_HOLD   ${APPLY_DIR}/System/AC/SYS_AC_IN_HOLD_${CLOCK_MODE}.ptsc
                set FILE_ACOUT_HOLD  ${APPLY_DIR}/System/AC/SYS_AC_OUT_HOLD_${CLOCK_MODE}.ptsc
                set FILE_MAXLOAD     ${APPLY_DIR}/System/AC/SYS_LOAD_SETUP.ptsc
                set FILE_MINLOAD     ${APPLY_DIR}/System/AC/SYS_LOAD_HOLD.ptsc
            }
        }

        ^(DFT) {
            if {$STA_METHOD=="MCU"} {
                set FILE_ACIN_SETUP  ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_SETUP_${CLOCK_MODE}.ptsc
                set FILE_ACOUT_SETUP ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_SETUP_${CLOCK_MODE}.ptsc
                set FILE_ACIN_HOLD   ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_HOLD_${CLOCK_MODE}.ptsc
                set FILE_ACOUT_HOLD  ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_HOLD_${CLOCK_MODE}.ptsc
                set FILE_MAXLOAD     ${APPLY_DIR}/DFT/AC/${DFT_MODE}_LOAD_SETUP.ptsc
                set FILE_MINLOAD     ${APPLY_DIR}/DFT/AC/${DFT_MODE}_LOAD_HOLD.ptsc
            }
        }
    }

    if {${STA_MODE}=="SYSTEM"} {
        puts "Picking-Up set_disable_clock_gating_check constraints from module constraints."
        echo "#set_disable_clock_gating_check" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
        WRITE_SCR_EXTRACTION set_disable_clock_gating_check LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
    } else {
        puts "Picking-Up set_disable_clock_gating_check constraints from module constraints for DFT."
        echo "#set_disable_clock_gating_check" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
        WRITE_SCR_EXTRACTION set_disable_clock_gating_check LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
    }
    puts "Rejecting no-required/invalid descriptions."

    SDC_ITEM_REJECT_LOGIC_CASE LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc > LOG/temporary_sdc_wo_LogicCase_${SDC_MODE}_${CLOCK_MODE}.sdc

    sh \
        grep -v 'sdc_version' LOG/temporary_sdc_wo_LogicCase_${SDC_MODE}_${CLOCK_MODE}.sdc | \
        grep -v 'set_operating_conditions' | \
        grep -v 'set_units' | \
        grep -v 'set_wire_load_mode' | \
        grep -v 'set_max_area' | \
        grep -v 'set_max_leakage_power' | \
        grep -v 'set_clock_uncertainty -hold' | \
        grep -v 'set_timing_derate' | \
        grep -v 'set_wire_load_selection_group' > ${SDC}

    if {${STA_MODE}=="SYSTEM" || ${STA_METHOD} == "MCU" } {
        echo "#AC Related" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
        APPEND_FILE ${FILE_MAXLOAD}     ${SDC}
        APPEND_FILE ${FILE_MINLOAD}     ${SDC}
        if {$CLOCK_MODE == "PROP"} {
            sh cp ${SDC} ${SDC}.woAC
            sh gzip -9f ${SDC}.woAC
        }
        APPEND_FILE ${FILE_ACIN_SETUP}  ${SDC}
        APPEND_FILE ${FILE_ACOUT_SETUP} ${SDC}
        APPEND_FILE ${FILE_ACIN_HOLD}   ${SDC}
        APPEND_FILE ${FILE_ACOUT_HOLD}  ${SDC}
    }

    sh gzip -9f ${SDC}
    sh rm -rf LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
    set END_TIME [date]

    puts "START      : ${START_TIME}"
    puts "WRITE_END  : ${END_TIME}"
    puts "CHECK_END  : [date]"
}
