#################################################################
# chkPTCresult.tcl
# Ver   : Date       : Author   : Description
# v0r0  : ????/??/?? : Y.Oda    : first release
# v0r01 : 2021/12/07 : T.Manaka : Adjust PTC format
#
#################################################################
##------------------------------------------------------
## Confirm NoCLOCK Sequential cells by case/tie setting
##------------------------------------------------------
proc chkGCACaseClk { pin_name } {
    set inspin      [get_pins -q $pin_name]
    set inspin_obj  [get_object_name  $inspin]
    set insname     [get_cells -q -of $pin_name]
    set insname_obj [get_object_name $insname]
    set inscell     [get_attribute $insname ref_name]
    set CaseClkPin  [chkGCACaseClkV $inspin]

    if { $CaseClkPin != "Empty" } {
        puts "// $inspin_obj,Clk_Constant ,$CaseClkPin,$inscell"
        set CLKPinSIM [ChangeHierPT2SIM $inspin_obj]
        set Value     [chkGCACaseClkV2R $CaseClkPin]
        puts "force `CHIP_TOP.$CLKPinSIM = 1'b$Value"
        puts ""
    } elseif {[string match "T*HGTD*" $inscell] || [string match "CKLNPQD*BWP7T40P140*" $inscell] || [string match "CKLHQD*BWP7T40P140*" $inscell] || [string match "CKLNQD*BWP7T40P140*" $inscell]} {
        if { [string match "T*HGTD*" $inscell] } {
            set CENPin  [get_object_name [get_pins $insname_obj/CEN]]
            set SMCPin  [get_object_name [get_pins $insname_obj/SMC]]
        } elseif {[string match "CKLNPQD*BWP7T40P140*" $inscell] || [string match "CKLHQD*BWP7T40P140*" $inscell] || [string match "CKLNQD*BWP7T40P140*" $inscell]} {
            set CENPin  [get_object_name [get_pins $insname_obj/E]]
            set SMCPin  [get_object_name [get_pins $insname_obj/TE]]
        }
        set CaseCENPin  [chkGCACaseClkV $CENPin]
        set CaseSMCPin  [chkGCACaseClkV $SMCPin]
        set CaseCENPinR [chkGCACaseClkV2R $CaseCENPin]
        set CaseSMCPinR [chkGCACaseClkV2R $CaseSMCPin]
        if { $CaseCENPinR == 1 || $CaseSMCPinR == 1 } {
            if { $CaseCENPinR == 1 } {
                puts "//$inspin_obj,EnAlwaysOpen ,$CaseCENPin"
                #puts "$CaseCENPinR: $CENPin"
                set CENPinSIM [ChangeHierPT2SIM $CENPin]
                puts "force `CHIP_TOP.$CENPinSIM = 1'b$CaseCENPinR"
                puts ""
            } else {
                puts "//$inspin_obj,EnAlwaysOpen ,$CaseSMCPin"
                #puts "$CaseSMCPinR: $SMCPin"
                set SMCPinSIM [ChangeHierPT2SIM $SMCPin]
                puts "force `CHIP_TOP.$SMCPinSIM = 1'b$CaseSMCPinR"
                puts ""
            }
        } elseif { $CaseCENPinR == 0 && $CaseSMCPinR == 0 } {
            puts "//$inspin_obj,EnAlwaysClose,CEN:${CaseCENPin}&&SMC:${CaseSMCPin}"
            #puts "$CaseCENPinR: $CENPin"
            #puts "$CaseSMCPinR: $SMCPin"
            #set CLKPinSIM [ChangeHierPT2SIM $inspin_obj]
            #puts "force `CHIP_TOP.$CLKPinSIM = 1'b0"
            set CENPinSIM [ChangeHierPT2SIM $CENPin]
            set SMCPinSIM [ChangeHierPT2SIM $SMCPin]
            puts "force `CHIP_TOP.$CENPinSIM = 1'b$CaseCENPinR"
            puts "force `CHIP_TOP.$SMCPinSIM = 1'b$CaseSMCPinR"
            puts ""
        } else {
            puts "//Cannot find attribute $inspin_obj"
            set CLKPinSIM [ChangeHierPT2SIM $inspin_obj]
            puts "force `CHIP_TOP.$CLKPinSIM = 1'b0"
            puts ""
        }
    } else {
        puts "//Cannot find attribute $inspin_obj"
        set CLKPinSIM [ChangeHierPT2SIM $inspin_obj]
        puts "force `CHIP_TOP.$CLKPinSIM = 1'b0"
        puts ""
    }
}

proc chkGCACaseClkV2R { Str } {
    regsub T $Str  {} Str2
    regsub C $Str2 {} Str3
    return $Str3
}

proc ChangeHierPT2SIM { Str } {
    regsub -all / $Str  . Str2
    return $Str2
}

proc chkGCACaseClkV { PIN_NAME } {
    set Cvalue [get_attribute -q [get_pins $PIN_NAME] case_value]
    set Cconst [get_attribute -q [get_pins $PIN_NAME] constant_value]
    if {$Cconst != ""} {
        set VALUE "T$Cconst"
    } elseif {$Cvalue != ""} {
        set VALUE "C$Cvalue"
        } else {
        set VALUE "Empty"
        }
    return $VALUE;
}


##------------------------------------------------------
## check GCA result
##------------------------------------------------------
proc chkGCAresult { {INFILE} } {
    global STA_MODE
    global DFT_MODE

    if {[string match "DFT" $STA_MODE]} {
        set GCA_MODE $DFT_MODE
    } else {
        set GCA_MODE $STA_MODE
    }

    set bar "+============================================================================================+"
    set GCA_REP $INFILE
    set OUT_DIR GCA_FB
    set fid [open $GCA_REP]
    puts "$bar"
    puts "// GCA report: $GCA_REP"
    puts "$bar"

    if {![file exists $OUT_DIR]} {
        sh mkdir $OUT_DIR
    }
    foreach SCR {"DES_0001" "DES_0002" "DES_0003"} {
        if {[file exists ${OUT_DIR}/${GCA_MODE}_${SCR}.txt]} {
            file delete ${OUT_DIR}/${GCA_MODE}_${SCR}.force.txt
        }
    }

    while {[gets $fid line]>=0} {
        #set str [split $line " "]
        set str [split $line ","]
 
        #regsub -all -expanded {\[([0-9]*)\]} $str {@\1@} str
        #regsub "," [lindex $str 4] {} RULE
        regsub " " [lindex $str 4] {} RULE
        if {$RULE == "" || $RULE == "Rule"} {continue}
        switch -- ${RULE} {
            {CAP_0001} {
                #Output/inout port 'PORT' has zero or incomplete capacitance values.
                regexp "'(.*?)'" $line match PORT
                #puts "@$PORT"
            }
            {CAS_0003} {
                #Pin/Port 'PIN' propagated value conflicts with a user case analysis value.
                regexp "'(.*?)'" $line match PIN
                puts "@CaseConflict $PIN"
            }
            {CLK_0004} {
                #Mismatch between generated clock definitions at 'PIN' and potential master clocks.
                regexp "'(.*?)'" $line match PIN
                #puts "@$PIN"
            }
            {CLK_0008} {
                #Generated clock 'CGclk' has paths from the source(s) of master clock 'CCclk' to generated clock source(s) with differing sequential depth.
                regexp "'(.*?)'.*?'(.*?)'" $line match CGclk CCclk
                #regsub -all "'" [lindex $str 9]  {} CGclk
                #regsub -all "'" [lindex $str 18] {} CCclk
                #puts "@$CGclk $CCclk"
            }
            {CLK_0021} {
                #Clock 'CLK' is not used in this scenario.
                regexp "'(.*?)'" $line match CLK
                #regsub -all "'" [lindex $str 8] {} CLK
                #puts "@$CLK"
            }
            {CLK_0024} {
                #Register Clock pin 'CLK' has 'num' clocks.
                regexp "'(.*?)'.*?'(.*?)'" match CLK NUM
                #regsub -all "'" [lindex $str 10] {} CLK
                #chkLackCLK $CLK
                #puts "@$CLK"
            }
            {CLK_0026} {
                #Clock 'CLK' is used as data.  One or more sources of the clock fans out to a register data pin or to a constrained primary output or inout port.
                regexp "'(.*?)'" $line match CLK
                #regsub -all "'" [lindex $str 8] {} CLK
                #puts "@clockAsData $CLK"
            }
            {CLK_0030} {
                #There is reconvergent logic in the network for clock 'CLK'.
                regexp "'(.*?)'" $line match CLK
                #regsub -all "'" [lindex $str 16] {} CLK
                #puts "@$CLK"
            }
            {CLK_0035} {
                #No clock-gating check inferred clock pin: 'PINclk' enable pin: 'PINenable'
                regexp "'(.*?)'.*?'(.*?)'" $line match PINclk PINenable
                #regsub -all "'" [lindex $str 17] {} PINclk
                #regsub -all "'" [lindex $str 20] {} PINenable
                puts "@NoClockGating $PINclk $PINenable"
            }
            {DES_0001} {
                #Register clock pin 'CLK' has no clock signal
                regexp "'(.*?)'" $line match CLK
                #regsub -all "'" [lindex $str 10] {} CLK
                puts "@NoClock $CLK"
                set CLKPinSIM [ChangeHierPT2SIM $CLK]
                redirect -append ${OUT_DIR}/${GCA_MODE}_DES_0001.force.txt {
                    puts "force `CHIP_TOP.$CLKPinSIM = 1'b0"
                }
            }
            {DES_0002} {
                #Register clock pin 'CLK' is disabled due to case values or disabled constraint arcs.
                regexp "'(.*?)'" $line match CLK
                #regsub -all "'" [lindex $str 10] {} CLK
                puts "@ConstraintDisable $CLK"
                redirect -append ${OUT_DIR}/${GCA_MODE}_DES_0002.force.txt {
                    chkGCACaseClk $CLK
                }
            }
            {DES_0003} {
                #The register clock pin 'pin' that is part of a generated clock source latency path does not receive a valid clock signal
                regexp "'(.*?)'" $line match CLK
                #regsub -all "'" [lindex $str 10] {} CLK
                #regsub -all "'" [lindex $str 7] {} MESSAGE
                #set POS_MES [split $MESSAGE " "]
                #regsub -all "'" [lindex $str 7] {} CLK
                #set CLK [lindex $POS_MES 5]
                puts "@NoClock $CLK"
                set CLKPinSIM [ChangeHierPT2SIM $CLK]
                redirect -append ${OUT_DIR}/${GCA_MODE}_DES_0003.force.txt {
                    puts "force `CHIP_TOP.$CLKPinSIM = 1'b0"
                }
            }
            {DRV_0001} {
                #Input/inout port 'PORT' has no input transition or driving cell or drive resistance specified.
                regexp "'(.*?)'" $line match PORT
                #regsub -all "'" [lindex $str 9] {} PORT
                #puts "@$PORT"
            }
            {EXC_0006} {
                #'false_path exception in sdc but it does not specify any valid paths.
            }
            {EXC_0014} {
                #multi/false constraint is fully overridden by other exceptions.
            }
            {EXC_0015} {
                #'multi/false_path exception is partially overridden by other exceptions.
            }
            {EXD_0003} {
                #Output/inout port 'xxx' has no clock-related output delay specified.
                regexp "'(.*?)'" $line match PIN
                #regsub -all "'" [lindex $str 9] {} PIN
                #puts "@$PIN"
            }
            {UDEF_ClockSetPointCheck} {
                #A Clock 'CLOCK' on 'MACRO' is not defined on a port or at the output pin of PLL/OSC(PLL_OSC_inst). Clock is not defined at a proper point.
                regexp "'(.*?)'.*?'(.*?)'" $line match CLOCK MACRO
                #regsub -all "'" [lindex $str 9] {} CLOCK
                #regsub -all "'" [lindex $str 11] {} MACRO
                puts "@MacroCLK $CLOCK $MACRO"
            }
            {UDEF_ComboPath_001} {
                #There are no timing constraints for the combinational path from port/pin ('TCK') to port/pin ('RDYZ').
                regexp "'(.*?)'.*?'(.*?)'" $line match PIN_A PIN_B
                #regsub -all "'" [lindex $str 18] {} PIN_A
                #regsub -all "'" [lindex $str 21] {} PIN_B
                #puts "@$PIN_A $PIN_B"
            }
            {UDEF_FixedMuxSetCaseAnalysis} {
                #All of MUX data signals are fixed by set_case_analysis command
                regexp "'(.*?)'" $line match PIN
                #regsub -all "'" [lindex $str 18] {} PIN
                #regsub -all {\).} $PIN {} PIN
                puts "@MUXinFixed $PIN"
            }
            {UDEF_GclockMultiDelayCalcPathCheck} {
                #Generated Clock 'CLK_A' has multiple paths to its master clock 'CLK_B'.
                regexp "'(.*?)'.*?'(.*?)'" $line match CLK_A CLK_B
                #regsub -all "'" [lindex $str 9] {} CLK_A
                #regsub -all "'" [lindex $str 23] {} CLK_B
                #puts "@CLKmultPath $CLK_A $CLK_B"
            }
            {UDEF_InputDelayCheck_0001} {
                #The input/inout port/pin ('XXX') is not set set_input_delay for the clocks (YYY). However, the others ('') are set.
                regexp "'(.*?)'.*?'(.*?)'" $line match XXX YYY
                #regsub -all "'" [lindex $str 10] {} XXX
                #regsub -all "'" [lindex $str 18] {} YYY
                #puts "@$XXX $YYY"
            }
            {UDEF_NoSetFromToFalsePath} {
                #Option '-to' is not specified by the command 'set_false_path'
            }
            {UDEF_NoSetFromToMultiPath} {
                #Option '-to' is not specified by the command 'set_multicycle_path
            }
            {UDEF_OutputDelayCheck_0001} {
                #The input/inout port/pin ('XXX') is not set set_output_delay for the clocks (YYY). However, the others ('') are set.
                regexp "'(.*?)'.*?'(.*?)'" $line match XXX YYY
                #regsub -all "'" [lindex $str 10] {} XXX
                #regsub -all "'" [lindex $str 18] {} YYY
                #puts "@$XXX $YYY"
            }
            {UDEF_ReportThPointException} {
                #The number ('num') of pins/ports are set by '-through' option instead of '-from' or '-to' option in the command,
            }
            {UDEF_SyncRstSetExceptionThrough} {
                #Asynchronous preset or clear pin of registers is specified on '-through' option by the command 'set_false_path -through option by the command.
            }
            {UDEF_VclkSrcLatencyCheck} {
                #Virtual Clock 'v_clk_TCK' in the SDC
            }
            default {
                puts "# $str"
            }
        }
    }
    close $fid
    puts "$bar"
}

proc chkAllFFClks {} {
    set ALLFFs [get_object_name [get_cells -hier -filter "is_sequential == true" ]]
    set ALLFFs [lsort -dictionary -ascii -unique $ALLFFs]
    if {[info exists STR_LIST]} {
        unset STR_LIST
    }
    if {[info exists CLK_LIST]} {
        unset CLK_LIST
    }
    foreach FF $ALLFFs {
        set FFobj  $FF
        set FFclkpins [get_pins -q [get_pins -of $FFobj] -filter "is_clock_pin==true"]
        foreach FFclkpin $FFclkpins {
            set clock_names [get_attribute -q $FFclkpin clocks]
            set FFclkpin_obj [get_object_name $FFclkpin]
            if {[sizeof_collection $clock_names] != 0} {
                set FFclks [mkCLKGroups [get_object_name $clock_names]]
                set FFclks [lsort -dictionary -ascii -unique $FFclks]
                set tmpstr " $FFclks $FFclkpin_obj"
                lappend STR_LIST $tmpstr 
                lappend CLK_LIST $FFclks 
            }
        }
    }
    set CLK_LIST [lsort -ascii -unique $CLK_LIST]
    puts "## CLK_LIST ##"
    foreach str $CLK_LIST {
        set clknum [lsearch $CLK_LIST $str]
        set clknum [format "%05d" $clknum]
        puts "$clknum  $str"
        regsub -all " $str " $STR_LIST "$clknum " STR_LIST
    }
    puts ""
    set STR_LIST [lsort -ascii -unique $STR_LIST]
    puts "## CELL_LIST ##"
    foreach str $STR_LIST {
        puts "$str"
    }
}
proc mkCLKGroups { {clknames} } {
    regsub -all { } $clknames @ clknames
    regsub      {^} $clknames @ clknames
    return $clknames
}

