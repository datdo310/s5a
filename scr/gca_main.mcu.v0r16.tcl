##############################################
# Main script for MCU product
# Common STA environment
# Name     : gca_main.mcu.tcl
# Version  : v0r0  2014/01/14   Y.Oda           Branch from "V2.gca_main.v0r08.tcl"
#            v0r1  2014/02/07   Y.Oda
#            v0r3  2014/07/17   Y.Oda
#            v0r4  2014/11/11   Y.Oda           AC constraints loading(SETUP/HOLD)
#            v0r5  2014/12/03   Y.Oda           clock_sense_compatibility.tbc was deleted.
#            v0r6  2014/02/04   Y.Oda           DFT AC LATENCY added/write force for sim
#            v0r7  2014/02/19   Y.Oda           Fixed Syntax error (DFT AC LATENCY)
#            v0r8  2016/07/14   Y.Oda           support PT2015.12-SP3
#            v0r9  2016/07/25   Y.Oda           Reject PT2015.12-SP3/support PT2014.12-SP3
#            v0r10 2016/08/24   Y.Oda           add "exit" for batch jobs
#            v0r11 2016/12/16   Y.Oda           remove MPI constraints, add SDC_MASK constraints
#            v0r12 2017/02/02   Y.Oda           CANCEL_TENTATIVE variable is added
#            v0r13 2017/04/11   Y.Oda           support PT2015.12-SP3
#            v0r14 2018/06/12   A.Yoshida       support PTC_2016.12-sp3-3-t-20180209
#            v0r15 2019/01/11   Y.Oda           add ENABLE_AOCVM variable for CU constraints
#            v0r16 2019/01/29   Y.Oda           add FORCE_SETTING ptsc and integrate CU
# Comment  : GCA check main script
##############################################
set GCA_VER201212 H-2012.12-SP2
set GCA_VER201306 H-2013.06-SP1
set GCA_VER201312 I-2013.12-SP1
set GCA_VER201412 J-2014.12-SP3-1
set GCA_VER201512 K-2015.12-SP3
set GCA_VER201612 M-2016.12-SP3


# <<Common alias >>
history keep    500
alias   h       history
alias   rt      "report_timing -sig 3 -nospl -net"

# << Prameter >>
#------------------------------------------------------------------
#   path
# m i
# u n
# s f                         : Valid
# t o   Param-name            : Definition
#------------------------------------------------------------------
# *     CONDITION             #  P  T  V   ; setup hold
#                             :<<NORMAL>>--------------------------
#                             : MIN_LT     ;        * 
#                             : MIN_HT     ;        *
#                             : MAX_LT     ;   *    *
#                             : MAX_HT     ;   *    *
#------------------------------------------------------------------
# *     STA_MODE              : SYSTEM/DFT/INIT
#------------------------------------------------------------------
# *     DFT_MODE              : INTEG/SCAN/MBIST/FBIST
#------------------------------------------------------------------
# *     LOAD_MODEL            : NO_LOAD
#------------------------------------------------------------------
# *     IDEAL_CLOCK           : false
#------------------------------------------------------------------
# *     DELAY                 : SETUP/HOLD
#------------------------------------------------------------------
# *     LIB_MODE              : CCS
#       USE_DB                : false
#------------------------------------------------------------------

# << To control STA flow >>
#------------------------------------------------------------------
#       RESTORE              : When true and exist session data, JOB re-start from the point loading const.
#	KEEP_SUB_DESIGNS     : When reading netlist, PT keeps sub mdules.
#------------------------------------------------------------------
# << DEFINE Check Parameter in this environment >>
set CHECK_PARAMETER {CONDITION STA_MODE DELAY LOAD_MODEL USE_DB CLOCK_MODE}

#  << set_clock_sense command works same as older version. >>
if {[regexp $GCA_VER201212 $sh_product_version]} {
} elseif {[regexp $GCA_VER201306 $sh_product_version]} {
} elseif {[regexp $GCA_VER201312 $sh_product_version]} {
} elseif {[regexp $GCA_VER201412 $sh_product_version]} {
} elseif {[regexp $GCA_VER201512 $sh_product_version]} {
} elseif {[regexp $GCA_VER201612 $sh_product_version]} {
} else {
	puts "* Error: you must use PT version project approved."
	exit
}



# << Reading common procedure >>
source ./scr/common_proc.tcl
source ./scr/r_tcl.proc.tcl

#------------------------------------------------------------------
# For Constraint Control
SET_INIT_VAR CANCEL_CLOCK             false ;# true: Cancel common clock constraints.
SET_INIT_VAR CANCEL_CASE              false ;# true: Cancel common set_case_analysis command
SET_INIT_VAR CANCEL_CONST             false ;# true: Cancel timing exceptions of top-level and modules
SET_INIT_VAR CANCEL_CONST_AC          false ;# true: Cancel timing exceptions for AC-timing(I/O-open-path)
SET_INIT_VAR CANCEL_CU                false ;# true: Cancel clock uncertainty
SET_INIT_VAR CANCEL_UPDATE_TIMING     false ;# true: Cancel update_timing -full
SET_INIT_VAR CANCEL_TIE_POWER_NET     true ;# true: Cancel set_case for power nets
SET_INIT_VAR CANCEL_SENGEN            false ;# true: Cancel reading SENGEN constraint
SET_INIT_VAR CANCEL_TENTATIVE         false ;# true: Cancel reading TENTAITVE constraint
SET_INIT_VAR CANCEL_FORCE_SETTING     false ;# true: Cancel reading FORCE_SETTING constraint

# RC annotation
SET_INIT_VAR ENABLE_IO_LOAD           true  ;# false: Cancel IO_LOAD annotation.

# For save_session
SET_INIT_VAR ENABLE_RESTORE           false ;# true: session data base restart.
SET_INIT_VAR RESTORE                  false ;# true: When exist session data, JOB re-start from the point loading const.
SET_INIT_VAR ENABLE_SS                false ;# true: Create session.
SET_INIT_VAR KEEP_SUB_DESIGNS         false ;# true: PT keeps sub mdules.

# SDC
SET_INIT_VAR ENABLE_READ_SDC          false ;# true: Reads constraints from SDC file.

# Error Check
SET_INIT_VAR ENABLE_ERROR_FILE        true ;# false: Cancel file existance check

# Add used variable by ptsc 
SET_INIT_VAR ENABLE_AOCVM             false ;# GCA doesn't use this variable but CU ptsc uses this variable


READ_PATH_INFO

check_resource START
set START_TIME [clock seconds]

# << Common flow setting >>
#------------------------------------------------------------------
# << Initial Setting >>
#------------------------------------------------------------------
# added 2011/12/08	for GCA
set_app_var sh_continue_on_error true



if {[info exists OPT_FLAG]} {
	regsub -all {/} $OPT_FLAG {_} OPT_FLAG
	set OPT_FLAG "_${OPT_FLAG}"
} else {
	set OPT_FLAG ""
}
set MODE    ${CONDITION}_${STA_MODE}_${DELAY}


source -echo ./design.cfg
source -echo ${APPLY_DIR}/ALL/instance_name.ptsc

# Common constraints
set FILE_OPEN_TRAN          ${APPLY_DIR}/System/Common/COM_OpenTran.ptsc



# << Common flow setting >>
switch -regexp -- ${STA_MODE} {
        ^(SYSTEM) {
                set FILE_SDC                $SDC(${STA_MODE},${CLOCK_MODE})
                set FILE_SYS_loop_disable   ${APPLY_DIR}/System/Common/SYS_loop_disable.ptsc
                set FILE_SYS_mode_setting   ${APPLY_DIR}/System/Common/SYS_mode_setting.ptsc
                set FILE_SYS_ATOM           ${APPLY_DIR}/System/Common/SYS_ATOM.ptsc ;# "Cut_thr_reg_TGN.ptsc"
                set FILE_SYS_SENGEN         ${APPLY_DIR}/System/Common/SYS_SENGEN.ptsc
                set FILE_SYS_CLK            ${APPLY_DIR}/System/Common/SYS_clk.ptsc
                set FILE_SYS_CLK_FALSE      ${APPLY_DIR}/System/Common/SYS_clk_false.ptsc
                set FILE_SYS_CU             ${APPLY_DIR}/System/Common/SYS_clk_CU_setting.ptsc ;
                set FILE_SYS_CLKGATING      ${APPLY_DIR}/System/Common/SYS_clk_gating_check.ptsc
                set FILE_SYS_XT_ADD         ${APPLY_DIR}/System/Common/SYS_Xtalk_additional.ptsc
                set FILE_SYS_ADD            ${APPLY_DIR}/System/Common/SYS_additional.ptsc
                set FILE_SYS_CONST_chip     ${APPLY_DIR}/System/module/SYS_chip_const.ptsc
                set FILE_SYS_CONST_module   ${APPLY_DIR}/System/module/SYS_module_const.ptsc
		set FILE_SYS_FORCE_SETTING  ${APPLY_DIR}/System/Common/SYS_FORCE_SETTING.ptsc; # Force Setting(set_annotated_transition)
                set FILE_SYS_AC_IN          ${APPLY_DIR}/System/AC/SYS_AC_IN_${DELAY}_${CLOCK_MODE}.ptsc ;# System/AC/Inopen_AC_USER_${CLOCK_MODE}.tcl_max/min
                set FILE_SYS_AC_OUT         ${APPLY_DIR}/System/AC/SYS_AC_OUT_${DELAY}_${CLOCK_MODE}.ptsc ;# System/AC/Outopen_AC_USER_${CLOCK_MODE}.tcl_max/min
                set FILE_SYS_AC_IN_FALSE    ${APPLY_DIR}/System/AC/SYS_AC_IN_false.ptsc  ;# Const_USER_false_InAC.tcl
                set FILE_SYS_AC_OUT_FALSE   ${APPLY_DIR}/System/AC/SYS_AC_OUT_false.ptsc ;# Const_USER_false_OutAC.tcl
                set FILE_SYS_AC_CLK_LATENCY ${APPLY_DIR}/System/Common/SYS_AC_CLK_LATENCY_${CLOCK_MODE}_${CONDITION}.ptsc

                set FILE_SYS_IO_LOAD        ${APPLY_DIR}/System/AC/SYS_LOAD_${DELAY}.ptsc
                set FILE_SYS_IO_DRV         ${APPLY_DIR}/System/AC/SYS_IODRV.ptsc
                set FILE_SYS_REP_AC         ${APPLY_DIR}/System/AC/SYS_REP.tcl
                set FILE_MAXTRAN_FILTER     ${APPLY_DIR}/except/SYS/MAXTRAN.filter
                set FILE_MAXCAP_FILTER      ${APPLY_DIR}/except/SYS/MAXCAP.filter
                set FILE_REACHCLK_PIN       ${APPLY_DIR}/except/SYS/CLKPIN.clockreach

                set FILE_SYS_TENTATIVE      ${APPLY_DIR}/System/Common/SYS_TENTATIVE.ptsc; # tentative const(rm in case of signoff)
        }
        ^(DFT) {
                set FILE_SDC                $SDC(${DFT_MODE},${CLOCK_MODE})
                set FILE_DFT_LOOP_CUT       ${APPLY_DIR}/DFT/Common/${DFT_MODE}_loop_disable.ptsc
                set FILE_DFT_CLK            ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clk.ptsc
                set FILE_DFT_CLK_FALSE      ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clk_false.ptsc
                set FILE_DFT_CU             ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clk_CU_setting.ptsc
                set FILE_DFT_CLKGATING      ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clock_gating_check.ptsc
                set FILE_DFT_MODE           ${APPLY_DIR}/DFT/Common/${DFT_MODE}_mode_setting.ptsc
                set FILE_DFT_CONST          ${APPLY_DIR}/DFT/Common/${DFT_MODE}_const.ptsc
                set FILE_DFT_ATOM           ${APPLY_DIR}/DFT/Common/${DFT_MODE}_ATOM.ptsc
                set FILE_DFT_SENGEN         ${APPLY_DIR}/DFT/Common/${DFT_MODE}_SENGEN.ptsc
                set FILE_DFT_XT_ADD         ${APPLY_DIR}/DFT/Common/${DFT_MODE}_Xtalk_additional.ptsc
                set FILE_DFT_nonSCAN        ${APPLY_DIR}/DFT/Common/${DFT_MODE}_const_DFT_nonScanFF.ptsc
		set FILE_DFT_FORCE_SETTING  ${APPLY_DIR}/DFT/Common/${DFT_MODE}_FORCE_SETTING.ptsc; # Force Setting(set_annotated_transition)
		set FILE_DFT_SDCMASK        ${APPLY_DIR}/DFT_mask_info/PTSC/SCAN_SDCMASK.ptsc
                set FILE_DFT_AC_IN          ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_${DELAY}_${CLOCK_MODE}.ptsc ;
                set FILE_DFT_AC_OUT         ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_${DELAY}_${CLOCK_MODE}.ptsc ;
		set FILE_DFT_AC_CLK_LATENCY ${APPLY_DIR}/DFT/Common/${DFT_MODE}_AC_CLK_LATENCY_${CLOCK_MODE}_${CONDITION}.ptsc

                set FILE_DFT_IO_LOAD        ${APPLY_DIR}/DFT/AC/${DFT_MODE}_LOAD_${DELAY}.ptsc
                set FILE_DFT_IO_DRV         ${APPLY_DIR}/DFT/AC/${DFT_MODE}_IODRV.ptsc
                set FILE_DFT_REP_AC         ${APPLY_DIR}/DFT/AC/${DFT_MODE}_REP.tcl
                set FILE_MAXTRAN_FILTER     ${APPLY_DIR}/except/DFT_${DFT_MODE}/MAXTRAN.filter
                set FILE_MAXCAP_FILTER      ${APPLY_DIR}/except/DFT_${DFT_MODE}/MAXCAP.filter
                set FILE_REACHCLK_PIN       ${APPLY_DIR}/except/DFT_${DFT_MODE}/CLKPIN.clockreach

                set FILE_DFT_TENTATIVE      ${APPLY_DIR}/DFT/Common/${DFT_MODE}_TENTATIVE.ptsc; # tentative const(rm in case of signoff)
        }
        default {
        }
}




if {[info exists DEBUG_JOB]} {
        #set CANCEL_REPORT_TIMING true
        #set CANCEL_CONST_REPORT  true
}

###################################################################
# << Error Check >>
###################################################################
# << File existence check >>
if {$ENABLE_ERROR_FILE == "true"} {
        ## mode common constraints ##
        ERROR_FILE FILE_OPEN_TRAN
        ## timing constraints
        if {$ENABLE_READ_SDC == "true"} {
                ERROR_FILE FILE_SDC
        }
        ## each mode setting
        if {$STA_MODE == "SYSTEM"} {
                ERROR_FILE FILE_SYS_loop_disable
                ERROR_FILE FILE_SYS_mode_setting
                ERROR_FILE FILE_SYS_ATOM
                ERROR_FILE FILE_SYS_SENGEN
                ERROR_FILE FILE_SYS_CLK
                ERROR_FILE FILE_SYS_CU
                ERROR_FILE FILE_SYS_CLK_FALSE
                ERROR_FILE FILE_SYS_CLKGATING
		ERROR_FILE FILE_SYS_ADD
                ERROR_FILE FILE_SYS_CONST_chip
                ERROR_FILE FILE_SYS_CONST_module
                ERROR_FILE FILE_SYS_IO_LOAD
                ERROR_FILE FILE_SYS_IO_DRV
		ERROR_FILE FILE_SYS_FORCE_SETTING
                ERROR_FILE FILE_SYS_AC_CLK_LATENCY
                if {$CANCEL_CONST_AC == "false"} {
                        ERROR_FILE FILE_SYS_AC_IN
                        ERROR_FILE FILE_SYS_AC_OUT
                        ERROR_FILE FILE_SYS_AC_IN_FALSE
                        ERROR_FILE FILE_SYS_AC_OUT_FALSE
			# ERROR_FILE FILE_SYS_REP_AC
                }
        } elseif {$STA_MODE == "DFT"} {
                ERROR_FILE FILE_DFT_LOOP_CUT
                ERROR_FILE FILE_DFT_CLK
                ERROR_FILE FILE_DFT_CU
                ERROR_FILE FILE_DFT_MODE
                ERROR_FILE FILE_DFT_CLK_FALSE
                ERROR_FILE FILE_DFT_CONST
                ERROR_FILE FILE_DFT_ATOM
                ERROR_FILE FILE_DFT_CLKGATING
                ERROR_FILE FILE_DFT_SENGEN
		if {$DFT_MODE != "MBIST" } {
			ERROR_FILE FILE_DFT_nonSCAN
		}
		if {$DFT_MODE != "MBIST" && $DFT_MODE != "FBIST"} {
			ERROR_FILE FILE_DFT_SDCMASK
		}
                ERROR_FILE FILE_DFT_IO_LOAD
                ERROR_FILE FILE_DFT_IO_DRV
		ERROR_FILE FILE_DFT_FORCE_SETTING
		ERROR_FILE FILE_DFT_AC_CLK_LATENCY
                if {$CANCEL_CONST_AC == "false"} {
                        ERROR_FILE FILE_DFT_AC_IN
                        ERROR_FILE FILE_DFT_AC_OUT
			#  ERROR_FILE FILE_DFT_REP_AC
                }
        }
} else {
        puts "* Information : Canceled ERROR_FILE check-flow."
}

# << Rule check: parameters >>
foreach tmp $CHECK_PARAMETER {
        if {[eval "info exist $tmp"] != 1} { ERROR $tmp }
}

if {[info exists OPT_FLAG]} {
        regsub -all {/} $OPT_FLAG {_} OPT_FLAG
        set OPT_FLAG "_${OPT_FLAG}"
} else {
        set OPT_FLAG ""
}
if {[info exists DFT_MODE] && $DFT_MODE != "INTEG" && $DFT_MODE != "SDC"} {
      set OPT_FLAG "_${DFT_MODE}${OPT_FLAG}"
}
set MODE      ${CONDITION}_${STA_MODE}_${DELAY}${OPT_FLAG}

###################################################################
# Initial Setting for Synopsys env parameters (EDA recommended)
###################################################################

# Default Values
# (1) NOT applied AOCV / NOT applied crosstalk analysis
set_app_var case_analysis_propagate_through_icg         true   ;# (option) ;#default false (EDA recommended : true)
set_app_var case_analysis_sequential_propagation        never  ;# (option) ;#default never (EDA recommended : never)
set_app_var report_default_significant_digits           3      ;# (option) ;#default 2     (EDA recommended : 3)
set_app_var svr_keep_unconnected_nets                   true   ;# (must)   ;#default true
set_app_var timing_all_clocks_propagated                true   ;# (must)   ;#default false
set_app_var timing_disable_internal_inout_cell_paths    true   ;# (option) ;#default true  (EDA recommended : false) ##MCU true###
set_app_var timing_enable_preset_clear_arcs             false  ;# (option) ;#default false (EDA recommended : true) ##MCU false##
set_app_var timing_input_port_default_clock             false  ;# (option) ;#default false (EDA recommended : false)
set_app_var timing_gclock_source_network_num_master_registers 1 ;# (option) (EDA recommended : 10,000,000) (E1MS=1)
#set_app_var extract_model_with_ccs_timing		false	;# (option) (EDA recommended false from PT2015.12-SP3)
#set_app_var link_keep_cells_with_pg_only_connection	true	;# (option) (EDA recommended true from PT2015.12-SP3)
#set_app_var link_keep_unconnected_cells			true	;# (option) (EDA recommended true from PT2015.12-SP3)



# Common setting (OCV = AOCVM)
set_app_var  timing_clock_gating_propagate_enable           true
set_app_var  timing_disable_clock_gating_checks             false
set_app_var  timing_disable_recovery_removal_checks         false
set          timing_dynamic_loop_breaking                   false
puts "Information(PTEnv): Variable(timing_dynamic_loop_breaking) is abolished from PT2015.12, Error message must be printed."


# << Always check "UITE-461" >>
if {[regexp {2011.} $sh_product_version] != 1} {
	set timing_edge_specific_source_latency                  true
}


# << Display Mode Information >>
puts "
################################
# $MODE${OPT_FLAG}
# --Information--
#   Condition    : ${CONDITION}
#   STA_MODE     : ${STA_MODE}
#   LibMode      : ${LIB_MODE}
#   LoadModel    : NO_LOAD
################################
"

#------------------------------------------------------------------
# << Read Design >>
#------------------------------------------------------------------
check_resource Read_design
		puts "* Information : Reading Gate level netlist..."
		read_verilog ./Gate/${NET}

		#Remove Design
		if {[info exists REMOVE_DESIGN]} {
			puts "* Information : Removing designs based on user definition."
			foreach tmp ${REMOVE_DESIGN} {
				remove_design $tmp
			}
		}
	
		#Read Verilog
		if {[info exists READ_VERILOG]} {
			puts "* Information : Reading designs based on user definition."
			foreach tmp ${READ_VERILOG} {
				read_verilog $tmp
			}
		}
puts "* Information : Netlist has read successfully."


#------------------------------------------------------------------
# << Linking with Libraries >>
#------------------------------------------------------------------
# << Setup Priority Link Library Information >>
source -echo ./${CONDITION}.${LIB_MODE}.cfg

# << Linking >>
check_resource link_design1
current_design ${TOP}
if {![info exists RESTORE]} {
	if {[info exists KEEP_SUB_DESIGNS] || [info exists ENABLE_DVFS]} {
		puts "* Information : linking with '-keep_sub_designs' options."
		link_design -keep_sub_designs
	} else {
		puts "* Information : linking. Unused sub-designs will be removed."
		link_design
	}
} else {
	puts "* Information : linking process has been skipped by 'RESTORE' direction."
}

# << Display Using Libraries >>
list_libraries

#------------------------------------------------------------------
# << Applying Tied constraints for PowerNets >>
#------------------------------------------------------------------
puts "* Information : Checking Power atribute nets"
if {$CANCEL_TIE_POWER_NET == "false"} {
	puts "* Information : Power atribute nets will be tied with 'set_case_analysis' command."
	redirect /dev/null {
		set GND_NETS [get_nets VSS*]
		set PWR_NETS [get_nets VDD*]
	}
	if {[sizeof_collection $GND_NETS] > 0 } {
		puts "* <<GND nets group>>"
		COL2DISP $GND_NETS
		set_case_analysis 0 [get_pins -of [get_nets VSS*] ]
	}
	if {[sizeof_collection $PWR_NETS] > 0 } {
		puts "* <<PWR nets group>>"
		COL2DISP $PWR_NETS
		set_case_analysis 1 [get_pins -of [get_nets VDD*] ]
	}
} else {
	puts "* Information : Power attribute nets are still floating."
}

###################################################################
# External load capacity & setting driveability
###################################################################
#<< Set IO_LOAD_CONST_FILE >>
if {$ENABLE_IO_LOAD == "true" && $ENABLE_READ_SDC == "false"} {
        if {$STA_MODE == "DFT"} {
               set FILE_IO_LOAD $FILE_DFT_IO_LOAD
               set FILE_IO_DRV  $FILE_DFT_IO_DRV
        } else {
               set FILE_IO_LOAD $FILE_SYS_IO_LOAD
               set FILE_IO_DRV  $FILE_SYS_IO_DRV
        }
        puts "* Information : Applying I/O load/drive condition '${FILE_IO_LOAD}' '${FILE_IO_DRV}'."
        source -echo ${FILE_IO_LOAD}
        source -echo ${FILE_IO_DRV}
} else {
        puts "* Information : Skipped applying I/O driveability. "
}



###################################################################
# << Read Constraints >>
###################################################################
check_resource Read_Constraints

switch -regexp -- ${STA_MODE} {

        ^(INIT) {
                puts "* Information : Selected 'INIT' mode."
                set CANCEL_CLOCK "true"
                set CANCEL_CU    "true"
        }

        ^(SYSTEM) {
                # already read constraints in SDC mode.
                if {$ENABLE_READ_SDC == "true"} {
                        puts "* Information : Selected '${STA_MODE}' SDC mode."
                        puts "                Reading '${FILE_SDC}'"
                        source -echo ${FILE_SDC}
                        #break
                } else {
                        puts "* Information : Selected '${STA_MODE}' original constraints mode."
                        puts "* Information : Selected 'SYSTEM' mode."
                        # << loop cut >>
                        check_resource Loop_cut
                        puts "* Information : reading $FILE_SYS_loop_disable"
                        source -echo -verbose $FILE_SYS_loop_disable
                        source -echo -verbose $FILE_OPEN_TRAN

                        # << Clock definition >>
                        check_resource Load_constraints
                        if {$CANCEL_CLOCK == "true"} {
                                puts "* Information : No clock constraint has been applied."
                                set CANCEL_CU "true"
                        } else {
                                puts "* Information : reading $FILE_SYS_CLK"
                                source -echo -verbose $FILE_SYS_CLK
                                puts "* Information : reading $FILE_SYS_CLK_FALSE"
                                source -echo -verbose $FILE_SYS_CLK_FALSE
                        }

                        # << Constraints for TGN in ATOM >>
                        puts "* Information : reading $FILE_SYS_ATOM"
                        
                        source -echo -verbose $FILE_SYS_ATOM

                        # << AC setting >>
                        if {$CANCEL_CONST_AC == "true"} {
                                puts "* Information : No Input/Output constraint has been applied."
                        } else {
                                # << Reading constraints of AC-false >> 
                                # << Reading case_value of pinmulti-AC >>
                                puts "* Information : Reading AC input false settings"
                                source -echo -verbose $FILE_SYS_AC_IN_FALSE
                                puts "* Information : Reading AC output false settings"
                                source -echo -verbose $FILE_SYS_AC_OUT_FALSE
                        }

                        # << mode_setting >>
                        puts "* Information : reading $FILE_SYS_mode_setting"
                        if {$CANCEL_CASE == "true"} {
                                puts "* Information : No set_case_analysis constraint has been applied."
                        } else {
                                puts "* Information : Applying set_case_analysis constraints for mode setting."
                                source -echo -verbose $FILE_SYS_mode_setting
                        }

                        # << Reading case_value of SENGEN >>
                        if {$CANCEL_SENGEN == "true"} {
                                puts "* Information : Cancel applying constraints of 'SENGEN'."
                        } else {
                                puts "* Information : reading ${FILE_SYS_SENGEN}"
                                source -echo -verbose $FILE_SYS_SENGEN
                        }

                        # << Timing exceptions >>
                        if {$CANCEL_CONST == "true"} {
                                puts "* Information : No constraint for timing exception has been applied."
                                puts "* Information : No clock gating check constraints are applied."
                        } else {
                                source -echo -verbose $FILE_SYS_ADD
                                # << Reading chip/module constraints>>
                                puts "* Information : Applying timing except constraints (multi/false)."
                                source -echo -verbose $FILE_SYS_CONST_chip
                                source -echo -verbose $FILE_SYS_CONST_module
                                # << Reading clock gating check >>
                                puts "* Information : Reading clock gating check constraints."
                                source -echo -verbose $FILE_SYS_CLKGATING
                        }
                }

                ## below files are not included in SDC constraints.(TCL/SDC mode read below)
                if {$CANCEL_CLOCK == "false" || $ENABLE_READ_SDC == "true"} {
                        # << Reading clock latency of AC-timing >>
                        puts "* Information : reading $FILE_SYS_AC_CLK_LATENCY"
                        source -echo -verbose $FILE_SYS_AC_CLK_LATENCY
                        if {$CANCEL_CU == "true"} {
                                puts "* Information : Canceled $FILE_SYS_CU reading by CANCEL_CU"
                        } else {
                                puts "* Information : reading $FILE_SYS_CU"
                                source -echo -verbose $FILE_SYS_CU
                        }
                }
                # << AC setting >>
		if {$CANCEL_CONST_AC == "true"} {
			puts "* Information : No Input/Output constraint has been applied."
		} else {
			# << Reading constraints of AC-timing >>
			puts "* Information : Reading AC input settings for SETUP/HOLD."
			source -echo -verbose ${APPLY_DIR}/System/AC/SYS_AC_IN_SETUP_${CLOCK_MODE}.ptsc
			source -echo -verbose ${APPLY_DIR}/System/AC/SYS_AC_IN_HOLD_${CLOCK_MODE}.ptsc
			puts "* Information : Reading AC output settings for SETUP/HOLD."
			source -echo -verbose ${APPLY_DIR}/System/AC/SYS_AC_OUT_SETUP_${CLOCK_MODE}.ptsc
			source -echo -verbose ${APPLY_DIR}/System/AC/SYS_AC_OUT_HOLD_${CLOCK_MODE}.ptsc
		}
		# << force setting >>
		if {$CANCEL_FORCE_SETTING == "true"} {
			puts "Information: Cancel to apply force_setting constraints by \$CANCEL_FORCE_SETTING"
		} else {
			source -echo -verbose $FILE_SYS_FORCE_SETTING
			puts "Information : End of force_setting constraints ${FILE_SYS_FORCE_SETTING}."
		}
                # << tentative constraints>>
                if {[file exists $FILE_SYS_TENTATIVE]} {
			if {$CANCEL_TENTATIVE == "true"} {
				puts "Information: Cancel to apply Tentative constraints by \$CANCEL_TENTATIVE"
			} else {
                        	puts "ERROR : Reading Tentative constraints ${FILE_SYS_TENTATIVE}."
                        	source -echo -verbose $FILE_SYS_TENTATIVE
				puts "Information : End of Tentative constraints ${FILE_SYS_TENTATIVE}."
			}
                }
        }

        ^(DFT) {
                puts "* Information : Selected 'DFT' mode."
                #<SDC mode>----------------------------------------------------------
                if {$ENABLE_READ_SDC == "true"} {
                        puts "* Information : Selected '${STA_MODE}/${DFT_MODE}' SDC mode."
                        puts "                Reading '${FILE_SDC}'"
                        source -echo ${FILE_SDC}
                        #break
                } else {
                        puts "* Information : Selected '${STA_MODE}/${DFT_MODE}' original constraints mode."

                        #<Constraint mode>----------------------------------------------------
                        # << loop cut >>
                        check_resource Loop_cut
                        puts "* Information : reading $FILE_DFT_LOOP_CUT"
                        source -echo -verbose ${FILE_DFT_LOOP_CUT}
			source -echo -verbose $FILE_OPEN_TRAN

                        # << Clock definition >>
                        check_resource Clock_setting
                        if {$CANCEL_CLOCK == "true"} {
                                puts "* Information : No clock constraint has been applied."
                                set CANCEL_CU        "true"
                                set CANCEL_CLK_FALSE "true"
                        } else {
                                puts "* Information : Applying clock constraints."
                                source -echo -verbose ${FILE_DFT_CLK}
                                puts "* Information : Applying clock false constraints."
                                source -echo -verbose ${FILE_DFT_CLK_FALSE}
                                # << Timing exceptions >>
                                if {$CANCEL_CONST == "true"} {
                                        puts "* Information : No timing except constraint has been applied."
                                } else {
                                        puts "* Information : Applying timing except constraints."
                                        source -echo -verbose $FILE_DFT_MODE
                                        source -echo -verbose $FILE_DFT_CONST ;# Including AC constraints
                                        source -echo -verbose $FILE_DFT_ATOM
                                        source -echo -verbose $FILE_DFT_CLKGATING
                                        source -echo -verbose $FILE_DFT_SENGEN
					if {$DFT_MODE == "MBIST" || $DFT_MODE == "FBIST"} {
						puts "* Information: Cancel reading SDC_MASK constraints"
					} else {
						puts "* Information: Applying reading SDC_MASK constraints"
						source -echo -verbose $FILE_DFT_SDCMASK
					}

					if {$DFT_MODE == "MBIST"} {
						puts "* Information : Cancel reading nonSCAN constraints"
					} else {
						puts "* Information : Applying reading nonSCAN constraints"
						source -echo -verbose $FILE_DFT_nonSCAN
					}
                                }
                        }
                }
                ## below files are not included in SDC constraints.(TCL/SDC mode read below)
                if { $CANCEL_CLOCK == "false" || $ENABLE_READ_SDC == "true" } {
			# << Reading clock latency of AC-timing >>
			puts "* Information : reading $FILE_DFT_AC_CLK_LATENCY"
			source -echo -verbose $FILE_DFT_AC_CLK_LATENCY
                        if {$CANCEL_CU == "true"} {
                                puts "* Information : Canceled $FILE_DFT_CU reading by CANCEL_CU"
                        } else {
                                puts "* Information : reading $FILE_DFT_CU"
                                source -echo -verbose $FILE_DFT_CU
                        }
                }
		# << AC setting >>
		if {$CANCEL_CONST_AC == "true"} {
			puts "* Information : No Input/Output constraint has been applied."
		} else {
			# << Reading constraints of AC-timing >>
			puts "* Information : Reading AC input settings for SETUP/HOLD."
			source -echo -verbose ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_SETUP_${CLOCK_MODE}.ptsc
			source -echo -verbose ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_HOLD_${CLOCK_MODE}.ptsc
			puts "* Information : Reading AC output settings for SETUP/HOLD."
			source -echo -verbose ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_SETUP_${CLOCK_MODE}.ptsc
			source -echo -verbose ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_HOLD_${CLOCK_MODE}.ptsc
		}
		# << force setting >>
		if {$CANCEL_FORCE_SETTING == "true"} {
			puts "Information: Cancel to apply force_setting constraints by \$CANCEL_FORCE_SETTING"
		} else {
			source -echo -verbose $FILE_DFT_FORCE_SETTING
			puts "Information : End of force_setting constraints ${FILE_DFT_FORCE_SETTING}."
		}

                # << tentative constraints>>
                if {[file exists $FILE_DFT_TENTATIVE]} {
			if {$CANCEL_TENTATIVE == "true"} {
				puts "Information: Cancel to apply Tentative constraints by \$CANCEL_TENTATIVE"
			} else {
                        	puts "ERROR : Reading Tentative constraints ${FILE_DFT_TENTATIVE}."
                        	source -echo -verbose $FILE_DFT_TENTATIVE
				puts "Information : End of Tentative constraints ${FILE_DFT_TENTATIVE}."
			}
                }
        }

        default {
                puts "ERROR: STA_MODE is not defined!"
                exit
        }  
}

#<< Set ClockLatency When Ideal >>
set timing_ideal_clock_zero_default_transition false
if {[info exists CANCEL_CLOCK]} {
        puts "* Information : No clock latency has been applied."
} else {
        puts "* Information : Applying clock_latency."
        if {$CLOCK_MODE == "PROP"} {
                puts "* Information : Selected actual latency."
                set_propagated_clock [all_clocks]
        } else {
                puts "* Information : Selected Ideal latency."
                puts "* Information : No Additional constraints for ideal clock."
        }
}


# << Update Timing >>
check_resource Before_update_timing
update_timing -full
check_resource Before_report_timing

#<< Select naming word >>
set NWORD {}


if {![info exists DEBUG_JOB]} {
	puts "* Information : Check Constraints by GCA."
	source -echo -verbose ./scr/GCA_check_mcu.tcl

# << save_session >>
	if {[info exists ENABLE_SS]} {
		puts "* Information : Creating session data as ./LOAD/save.GCA.${LOAD_MODEL}.${MODE}${OPT_FLAG} now....."
		save_session ./LOAD/save.GCA.${LOAD_MODEL}.${MODE}${NWORD}${OPT_FLAG}
	} else {
		puts "* Information : Canceled writing SESSION data."
	}
}
# << checkGCA result.>>
	source scr/chkGCAresult.tcl
	set OUT_DIR GCA_FB
	if {[string match "DFT" $STA_MODE]} {
		set GCA_MODE $DFT_MODE
	} else {
		set GCA_MODE $STA_MODE
	}
	if {![file exists $OUT_DIR]} {
		puts "* Information: Creating $OUT_DIR"
		sh mkdir $OUT_DIR
        }
	redirect $OUT_DIR/${GCA_MODE}.result {
		chkGCAresult Report/result.GCA_check.vio_full.${LOAD_MODEL}.${MODE}${NWORD}.summary.csv
	}



# << Output total run time.>>
TOTAL_RUN_TIME
check_resource END
print_message_info

if {![info exists DEBUG_JOB]} {
        puts "Information: Exit GCA by batch job"
        exit
}

