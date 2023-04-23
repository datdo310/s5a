##############################################
# Main script for Renesas MCU Products
# Common STA environment Generation V3
# Renesas Electronics Corporation. All rights reserved.
# Strict confidential
#
# Name     : main.mcu.tcl
#
# Version  : mcu.v0r0  2014/01/15 Branch from "V2.main.v8r0.tcl"
#          : mcu.v0r05 2014/01/21 feedback from E1L24 PROP STA
#          : mcu.v0r06 2014/01/24 Revise Bigskew,WriteSDF(forSim)
#          : mcu.v0r07 2014/01/31 remove PAD delay
#          : mcu.v0r08 2014/02/03 separate DFT AC constraints
#          : mcu.v0r09 2014/02/14 maxtrancap, DeltaDelayRatio
#          : mcu.v0r09 2014/02/14 maxtrancap, DeltaDelayRatio
#          : mcu.v0r10 2014/02/21 File locations have changed
#          : mcu.v0r12 2014/03/20 VDD/GND case was removed
#          : mcu.v0r13 2014/04/03 PT_ECO_FILE added
#          : mcu.v1r00 2014/05/08 SMVA supported
#          : mcu.v1r01 2014/05/08 ENABLE_ANNOTATED_CHECK added
#          : mcu.v1r02 2014/06/19 SIMSDF_ANNO_ZERO_FILE is modified
#          : mcu.v1r03 2014/07/13 min_period added
#          : mcu.v1r04 2014/07/17 HighFreq dont_use added
#          : mcu.v1r05 2014/07/26 AOCVM CU report file name was same to OCV.
#          : mcu.v1r06 2014/11/23 Feedback from FCC2 and applying for PrimeTime2013
#          : mcu.v1r07 2014/12/03 clock_sense_compatibility.tbc was deleted.
#          : mcu.v1r08 2015/03/13 PrimeTime2014.06-SP1 is supported for SMVA
#          : mcu.v1r09 2015/04/24 Critical Pins jobs are updated
#          : mcu.v1r10 2015/05/26 Variables are changed for SignOff
#          : mcu.v1r11 2015/07/10 Lumped check is added
#          : mcu.v1r12 2015/09/08 handle Block SPEF(as trial)
#                                 HighVoltage Tran/Cap
#          : mcu.v1r13 2015/09/22 Get Detail report(Skewed,Delta)
#          : mcu.v1r14 2015/11/06 add maxtran/cap for HV option(-period_value)
#          : mcu.v1r15 2015/11/25 Remove set resistance after update_timing -full
#          : mcu.v1r16 2015/12/10 modify AOCVM path_group bug
#          : mcu.v1r17 2016/01/21 To get clock pin list
#          : mcu.v1r18 2016/05/12 Feedback D1M-E(Change Order block spef/save_session)
#          : mcu.v1r19 2016/07/11 Support PT201512, lowdrive@320MHz/HighFreqDontUse
#          : mcu.v1r20 2016/07/14 Change AOCVM session name
#          : mcu.v1r21 2016/07/21 support PT2014.12
#          : mcu.v1r22 2016/08/11 AOCVM GBA margin up 0 -> 300ps
#          : mcu.v1r23 2016/08/31 add "exit" for batch jobs
#          : mcu.v1r24 2016/09/14 Transition separate
#          : mcu.v1r25 2016/12/28 remove MPI constraints, add SDC_MASK constraints
#          : mcu.v1r26 2017/01/06 ENABLE_GCLKPATH variable is added.
#          : mcu.v1r27 2017/02/02 CANCEL_TENTATIVE variable is added.
#          : mcu.v1r28 2017/02/20 Add COMP_VAR command to compare variables
#          : mcu.v1r29 2017/03/13 Handle RV28F condition
#          : mcu.v1r30 2017/04/10 support PT2015.12-sp3
#          : mcu.v1r31 2017/06/01 add annotate report for Kobetsu
#          : mcu.v1r32 2017/07/26 remove_option "read_parastics -complete_with zero"
#                                 Add variables IGNORE_TRAN_CLKS
#          : mcu.v1r33 2017/08/30 Change VCC MaxCap relax constraints for RV28F
#          : mcu.v1r34 2017/10/08 ADD REMOVE_DESIGN is supported
#          : mcu.v1r35 2017/10/13 ADD ENABLE_REMOVE_DESIGN variable
#          : mcu.v1r36 2017/11/27 Add Write Delta SDF
#          : mcu.v1r37 2018/01/18 remove XtalkDelta Max report(not use)
#          : mcu.v1r38 2018/03/09 support PT2016.12/significant digit 4->3
#          : mcu.v1r39 2018/04/12 support advanced waveform propagation for RV28F
#          : mcu.v1r40 2018/04/30 Change PT2015.12 support version
#          : mcu.v1r41 2018/05/11 Change AWP tbc for PT2015.12-SP3-1
#          : mcu.v1r42 2018/06/05 Change COMP_VAR Variables
#          : mcu.v1r43 2018/07/02 ccst_wfp_awp.tbc setting is removed from RV28F library.
#          : mcu.v1r44 2018/08/09 -include_hierarchical_pins option is added for PT2014.06-SP1 -
#          : mcu.v1r45 2019/01/29 Add ForceSetting ptsc for annotate_transition/integrate CU
#          : mcu.v1r46 2019/02/05 change Async Transition initial value 999->99999.999
#          : mcu.v1r47 2019/06/10 change make_chkprime.csh -> make_chkprime.pl
#          : mcu.v1r48 2019/08/19 apply 9001516371_WA.tbc to analyze max_tran/cap correctly
#          : mcu.v1r49 2020/03/08 support PT201712
#          : mcu.v1r50 2020/04/03 timing_crpr_threshold_ps change 1 -> 2 for TAT/MEM
#          : mcu.v1r51 2020/07/15 Change SMVA process(batch: exit, debug: continue with SMVA analysis)
#          : mcu.v1r52 2020/09/03 Add variable MAXFANOUT_THRESHOLD and tcl_precision(12)/(6:write_SDC)
#          : mcu.v1r53 2020/09/17 Change SET_INIT_VAR MAXTRANCAP_FREQ_RELAX value from 0.092 to 0.000
#          : mcu.v1r54 2020/10/16 support MF3 signoff
#          : mcu.v1r55 2020/11/11 Add make clock latency hisgtram procedure.
#          : mcu.v1r56 2021/02/19 Add pin name equivalent setting
#          : mcu.v1r57 2021/07/12 change NUM_SLACK 0.1ps -> -0.01ps
#                                 Move parasitic_load_location variable setting to before read SPEF
#          : mcu.v1r58 2021/07/21 Add save pin for HOLD
#                                 Adjust OCV read for separate setting clock and data
#                                 Change DD_MIN criteria 0.1ps -> -0.01ps
#                                 Create report from report_timing_derate
#                                 Change message of write_sdf avoid shmsta status error
#                                 Change set_timing_derate 1.000 -> reset_timing_derate
#
##############################################
set PT_VER201206 G-2012.06-SP3-1
set PT_VER201306 H-2013.06-SP1
set PT_VER201312 I-2013.12-SP1
set PT_VER201406 J-2014.06-SP1
set PT_VER201412 J-2014.12-SP3-1
set PT_VER201512 K-2015.12-SP3-1
set PT_VER201612 M-2016.12-SP3-1
set PT_VER201712 N-2017.12-SP3-5-VAL-20191205

set tcl_precision 12

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
# *     STA_MODE              : mkVTH_CMD/mkHF/mkSDF/SYSTEM/DFT/INIT
#------------------------------------------------------------------
# *     DFT_MODE              : INTEG/SCAN/MBIST/FBIST
#------------------------------------------------------------------
# *     LOAD_MODEL            : WLM/SPEF/SDF/NO_LOAD
#------------------------------------------------------------------
# *     CLOCK_MODE            : PROP/IDEAL
#------------------------------------------------------------------
# *     DELAY                 : SETUP/HOLD/NONE
#------------------------------------------------------------------
# *     LIB_MODE              : NLDM/CCS
#       DEBUG_JOB             : Start Interactive mode
#       EXT                   : Source the extra-script at the end.
#       MOD_NAME              : Nickname of module for EXT.
#       USE_DB                : true/false
#------------------------------------------------------------------

# << To control STA flow >> Default setting
#
#------------------------------------------------------------------

#  << Check approval PrimeTime version >>
if {[regexp $PT_VER201206 $sh_product_version]} {
} elseif {[regexp $PT_VER201306 $sh_product_version]} {
} elseif {[regexp $PT_VER201312 $sh_product_version]} {
} elseif {[regexp $PT_VER201406 $sh_product_version]} {
} elseif {[regexp $PT_VER201412 $sh_product_version]} {
} elseif {[regexp $PT_VER201512 $sh_product_version]} {
  if {[info exists ENABLE_SMVA]} {
	if {$ENABLE_SMVA == "true"} {
		puts "* Error: SMVA with PT2015.12-SP3 isn't approved."
		exit
	}
  }
} elseif {[regexp $PT_VER201612 $sh_product_version]} {
	source /common/appl/Synopsys/primetime/2016.12-sp3-1/9001516371_WA.tbc  ;# W/A for MaxTran with jump clock

} elseif {[regexp $PT_VER201712 $sh_product_version]} {
	source /common/appl/Synopsys/primetime/2017.12-sp3-5-VAL20191205/star_9001516371_fix.tbc	;# W/A for MaxTran with jump clock
} else {
	puts "* Error: you must use PT version project approved."
	exit
}

# << DEFINE Check Parameter in this environment >>
set CHECK_PARAMETER {CONDITION STA_MODE DELAY LOAD_MODEL USE_DB CLOCK_MODE}


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
SET_INIT_VAR CANCEL_TIE_POWER_NET     true  ;# true: Cancel set_case for power nets
SET_INIT_VAR CANCEL_SENGEN            false ;# true: Cancel reading SENGEN constraint
SET_INIT_VAR CANCEL_TENTATIVE         false ;# true: Cancel reading TENTAITVE constraint
SET_INIT_VAR CANCEL_FORCE_SETTING     false ;# true: Cancel reading FORCE_SETTING constraint

# For ML netlist
SET_INIT_VAR ENABLE_ML                false ;# true: Enable ML netlist mode for Timing Check
SET_INIT_VAR ENABLE_MK_CLK_LIST       false ;# true: Create clock pin list file for mkVTHCMD
SET_INIT_VAR ENABLE_MK_VTH_CMD        false ;# true: Create size_cell commands for timing estimation with Lower Vths.
SET_INIT_VAR ENABLE_TRAN_ML           false ;# true: Enable ML netlist mode for Check Transition time.

# For REMOVE_DESIGN
SET_INIT_VAR ENABLE_REMOVE_DESIGN     false ;# true: Available to use remove_design

# RC annotation
SET_INIT_VAR ENABLE_IO_LOAD           true  ;# false: Cancel IO_LOAD annotation.
SET_INIT_VAR ENABLE_HF_ZERO           false ;# true: Treat high fanout nets(>50) zero RC.
SET_INIT_VAR ENABLE_ANNOTATED_CHECK   false ;# true: Get annotated report that all circuit net are applied from SPEF file.

# For Timing ECO tools
SET_INIT_VAR ENABLE_ATTRIBUTE_MK40F   false ;# true: execute 'SET_LIBNAME_OF_REF' and 'ADD_ORIGINAL_AREA' for mk40F

SET_INIT_VAR ENABLE_SAVE_PIN	     false ;# true: Criate negative slack pins information for mk40F/STF40F.
SET_INIT_VAR PIN_SLACK                0.1   ;# limit value of 'GET_CRITICAL_PINS' slack value. (default 0.1)
SET_INIT_VAR PT_ECO_FILE              NONE  ;# Apply ECO commands when defined files in "PT_ECO_FILE" parameter.

# CRITICAL PINS / BIGDELAY for SETUP
SET_INIT_VAR CRITICAL_SETUP_SLACK     3.0;   # we can get pins information under this slack value.
SET_INIT_VAR CRITICAL_HOLD_SLACK      3.0;   # we can get pins information under this slack value.
SET_INIT_VAR BIGDELAY_SETUP_SLACK    -0.1;   # we can get bigdelay net infomation net_delay > BIGDELAY_NET_DELAY
SET_INIT_VAR BIGDELAY_NET_DELAY       0.5;   #   and slack < BIGDELAY_SETUP_SLACK

# For save_session
SET_INIT_VAR ENABLE_RESTORE           false ;# true: session data base restart.
SET_INIT_VAR RESTORE                  false ;# true: When exist session data, JOB re-start from the point loading const.
SET_INIT_VAR ENABLE_SS                false ;# true: Create session.
SET_INIT_VAR ENABLE_SS_SIMPLE         false ;# true: Create session with Netlist and LOAD only. use with 'RESTORE' command.
SET_INIT_VAR KEEP_SUB_DESIGNS         false ;# true: PT keeps sub mdules.

# For Xtalk
SET_INIT_VAR ENABLE_XT                false ;# true: PT-SI mode activate
SET_INIT_VAR ENABLE_XT_PESSIMISTIC    false ;# true: Create Xtalk Delay Timing Report without pessimistic.
SET_INIT_VAR ENABLE_XT_DD_ANALYSIS    false ;# Cancel analizing xtalk delta delay
SET_INIT_VAR ENABLE_XT_NOISE_REPORT   false ;# true: Get SI-noise report (Noise/double_switching/check_noise)
SET_INIT_VAR XT_DD_MAX_RATIO          0.050 ;# If the DELTA RATIO is bigger than XT_DD_MAX_RATIO, Detail paths are reported
SET_INIT_VAR XT_DD_MAX_DELTA          0.400 ;# If the DELTA is bigger than XT_DD_MAX_DELTA, Detail paths are reported.
SET_INIT_VAR XT_DD_MIN_DELTA         -0.060 ;# Hold xtalk delta check is violated, if the DELTA is smaller than XT_DD_MIN_DELTA
SET_INIT_VAR XT_DD_MIN_SLACK        -0.00001;# Hold xtalk delta check is done , if the slack < XT_DD_MIN_SLACK
SET_INIT_VAR ENABLE_WRITE_DD_SDF      false ;# true: write Delta SDF
SET_INIT_VAR DELTA_PATH_LIMIT	        500 ;# Number of Detail path report

# SDC
SET_INIT_VAR ENABLE_WRITE_SDC         false ;# true: Create SDC.
SET_INIT_VAR ENABLE_READ_SDC          false ;# true: Reads constraints from SDC file.
SET_INIT_VAR SDC_VERSION              2.0   ;#

# Accuracy Check
SET_INIT_VAR ENABLE_ACCURACY          false ;# true: Get reports for accuracy-check
SET_INIT_VAR ENABLE_MESSAGE_UNLIMIT   false ;# true: Set sh_message_limit to 1,500,000
SET_INIT_VAR ENABLE_REPORT_NOCLK      false ;# true: Get no-clock and unconstrained endpoint report.
SET_INIT_VAR ENABLE_REPORT_LOOPS      false ;# true: Get loop report.
SET_INIT_VAR ENABLE_CLK_CROSSING      false ;# true: Get clock_crossing report.
SET_INIT_VAR ENABLE_GCLKPATH          $ENABLE_REPORT_NOCLK ;# true: Get GCLKPATH
SET_INIT_VAR ENABLE_LATENCY_HISTGRAM  $ENABLE_REPORT_NOCLK ;# true: Get clock latency histgram.
SET_INIT_VAR LATENCY_HISTGRAM_MIN     0.000 ;# Minimum value of latency histgram.
SET_INIT_VAR LATENCY_HISTGRAM_STEP    0.200 ;# Step value of latency histgram.
SET_INIT_VAR LATENCY_HISTGRAM_MAX    12.000 ;# Max value of latency histgram.

# Report
SET_INIT_VAR CANCEL_REPORT_TIMING     false ;# true: Cancel report_timing command
SET_INIT_VAR CANCEL_CONST_REPORT      false ;# true: Cancel 'constraints' 'min_pulse' report
SET_INIT_VAR CANCEL_TRANnCAP_REPORT   false ;# true: Cancel 'max_transition/max_capacitance' report
SET_INIT_VAR CANCEL_ML_TIMING_REPORT  false ;# true: Cancel ML_TIMING_REPORT
SET_INIT_VAR CANCEL_AC_REPORT         false ;# true: Cancel AC detail report.
SET_INIT_VAR ENABLE_REPORT_SUMMARY    true  ;# false: Cancel make summary of timing report.
SET_INIT_VAR REPORT_LESSER_THAN_ONLY  false ;# Make timing report with -lesser_than only.
SET_INIT_VAR ENABLE_REPORT_EXCEPTIONS false ;# true: Get report_exceptions execution.
SET_INIT_VAR ENABLE_REPORT_CLK_TMG    false ;# true: Get report_exceptions execution.
SET_INIT_VAR ENABLE_OCV               true  ;# true:Get report with OCV or AOCV
SET_INIT_VAR ENABLE_AOCVM             false ;# Enable design flow with AOCVM method

# SMVA mode
SET_INIT_VAR ENABLE_SMVA              false ;# Enable design flow with SMVA method

# BigSkew
SET_INIT_VAR ENABLE_BIGSKEW           false ;# true: getting bigskew reports
SET_INIT_VAR BSKEW_SLACK_MARGIN       0.075 ;# slack value for getting bigskew reports.
SET_INIT_VAR BSKEW_NWORST             5     ;# 
SET_INIT_VAR BSKEW_REPDIR             ./BigSkew     ;# Bigskew report dire

# Skewed_Load
SET_INIT_VAR ENABLE_SKEWED            false ;# true: getting skewed load SMC report
SET_INIT_VAR SKEWED_TRAN_RATIO        0.625 ;# required_slack = (actual_tran - $SKEWED_TRAN_OFFSET) * $SKEWED_TRAN_RATIO
SET_INIT_VAR SKEWED_TRAN_OFFSET	      0.400
SET_INIT_VAR SKEWED_PATH_LIMIT        200   ;# Get Detail Path report limit number

# MaxTran/Cap
SET_INIT_VAR MAXTRANCAP_FREQ_RELAX    0.000;# If MaxTran/Cap Frequency has margin(ex:NBTI) set relax value. (example:0.078@RV40F2)
SET_INIT_VAR MAXCAP_DEFAULT           1.52; # Maxcap default value 1.52pF@100MHz
SET_INIT_VAR IGNORE_TRAN_CLKS         NULL ;# ignored clocks for MaxTran/MaxCap Frequency/LowDrive/HalfCycle report
SET_INIT_VAR SKIP_TRAN_LIB            false;# true: skip to get library max transition report
SET_INIT_VAR SKIP_TRAN_FREQ           false;# true: skip to get frequency max transition report
SET_INIT_VAR SKIP_TRAN_CLKPIN         false;# true: skip to get clkpin max transition report
SET_INIT_VAR SKIP_TRAN_LOWDRV         false;# true: skip to get low drive max transition report
SET_INIT_VAR SKIP_TRAN_HALFCYCLE      false;# true: skip to get half cycle max transition report
SET_INIT_VAR SKIP_CAP_LIB             false;# true: skip to get library max capacitance report
SET_INIT_VAR SKIP_CAP_FREQ            false;# true: skip to get frequency max capacitance report


# Simulation SDF
SET_INIT_VAR ENABLE_WRITE_SIMSDF      false ;# true: write_SDF for simulation.

# Error Check
SET_INIT_VAR ENABLE_ERROR_FILE        true ;# false: Cancel file existance check

# Minpulse margin
SET_INIT_VAR MIN_PULSE_MARGIN         0.000 ;# Minipulse end point spec margin for CU(After PT2013.12, don't need)
SET_INIT_VAR MIN_PULSE_THRESHOLD      0.2;   # Minipulse for through pin constraints.

# HighFREQDONTUSE
SET_INIT_VAR HIGHFREQ_DONT_USE_PERIOD 2.800 ;# Target period of HighFreqDontuse check

# MAX_FANOUT_VALUE                       ;# ADD mcu.v1r50a
SET_INIT_VAR MAXFANOUT_THRESHOLD      50 ;# MAX_FANOUT 50 ADD mcu.v1r50a

if {[regexp $PT_VER201206 $sh_product_version] || [regexp $PT_VER201306 $sh_product_version]} {
   if {$MIN_PULSE_MARGIN == 0} {
	puts "Error: PrimeTime($sh_product_version) cannot verify minpulse with clock_uncertainty."
	puts "       Please check SignOff condition for correct setting";
	exit
   }
}


# for transition report
source ./scr/modify_maxtran_rep.proc
source ./scr/modify_maxtran_rep_hm.proc
source ./scr/relax_max_tran_hv.proc

# for capacitance report
source ./scr/modify_maxcap_rep.proc
source ./scr/modify_maxcap_rep_hm.proc
source ./scr/relax_max_cap_hv.proc

READ_PATH_INFO

# << Setup Design Information >>
source -echo ./design.cfg
source -echo ${APPLY_DIR}/ALL/instance_name.ptsc

# Common constraints
set FILE_OPEN_TRAN          ${APPLY_DIR}/System/Common/COM_OpenTran.ptsc

###################################################################
# << Process Variables >>
###################################################################
if {[info exists PROCESS]} {
	puts "* Information: PROCESS = $PROCESS ."
	if {[string match "RV40F" $PROCESS] } {
		SET_INIT_VAR BSKEW_LIMIT_SKEW         0.44  ;# Skew value for getting bigskew reports.
		SET_INIT_VAR SKIP_TRAN_ASYNC          true  ;# true: skip to get async set/reset max transition report
		SET_INIT_VAR MAXTRAN_ASYNC_CONST      0.80  ;# MaxTran for RV28F
	} elseif { [string match "RV28F" $PROCESS] } {
		SET_INIT_VAR BSKEW_LIMIT_SKEW         0.39  ;# Skew value for getting bigskew reports.
		SET_INIT_VAR SKIP_TRAN_ASYNC          false ;# true: skip to get async set/reset max transition report
		SET_INIT_VAR MAXTRAN_ASYNC_CONST      0.80  ;# MaxTran for RV28F
		## Advanced Waveform propagation for sophisticated than 28nm
		set_app_var delay_calc_waveform_analysis_mode full_design
	} elseif { [string match "MF3" $PROCESS] } {
		SET_INIT_VAR BSKEW_LIMIT_SKEW         0.44  ;# Skew value for getting bigskew reports.
		SET_INIT_VAR SKIP_TRAN_ASYNC          true  ;# true: skip to get async set/reset max transition report
		SET_INIT_VAR MAXTRAN_ASYNC_CONST      0.80  ;# MaxTran for RV28F
	} else {
		puts "* Error:  \$PROCESS $PROCESS is not supported"
		puts "          Define \[RV40F/RV28F\] in pathinfo.cfg."
		exit
	}
} else {
	puts "* Error: You must define \$PROCESS (RV40F/RV28F) in pathinfo.cfg."
	exit
}
###################################################################


check_resource START
set START_TIME [clock seconds]

# << Set log-file sufix for 'go_debug/*' jobs >>
if {[info exists DEBUG_JOB]} {
	set SUFFIX "_#$env(LS_JOBPID)"
} else {
	set SUFFIX ""
}
if {[info exists MOD_NAME]} {
	set SUFFIX ${SUFFIX}_${MOD_NAME}
}

# << Common flow setting >>
switch -regexp -- ${STA_MODE} {
	^(mkVTH_CMD) {
		if {![info exists STBY_AREA]} {
			puts "* Error : You must define paramater 'STBY_AREA' in 'pathinfo.cfg'."
			exit
		} else {
			set ENABLE_MK_VTH_CMD true
		}
	}

	^(INIT) {
		puts "* Information : Initial setup mode is starting."
		set ENABLE_XT              false
		set ENABLE_ACCURACY        false
		set ENABLE_IO_LOAD         false
		set CANCEL_CLOCK           true
		set CANCEL_CASE            true
		set CANCEL_CONST           true
		set CANCEL_CU              true
		set CANCEL_UPDATE_TIMING   true
		set CANCEL_REPORT_TIMING   true
		set CANCEL_CONST_REPORT    true
		set CANCEL_TRANnCAP_REPORT true
		set ENABLE_ERROR_FILE      false
		set ENABLE_MK_VTH_CMD      false
		set ENABLE_OCV             false
		set ENABLE_AOCVM           false
		set KEEP_SUB_DESIGNS       true
		set DELAY                  NONE
	}

	^(mkSDF) {
		if {[file exists "./LOAD/SDF_KEY_${CONDITION}"]} {
			puts "* Error : 'SDF_KEY_${CONDITION}' exists already in './LOAD' directry."
			puts "         If you want to make SDF with same condition again, please delete key first."
			puts "         And then re-start this job again."
			puts "         Thank you."
			exit
	        } elseif {[file exists "./LOAD/SDF_KEY_${LOAD_MODEL}.${MODE}${NWORD}"]} {
			puts "* Error : 'SDF_KEY_${LOAD_MODEL}.${MODE}${NWORD}' exists already in './LOAD' directry."
			puts "         If you want to make SDF with same condition again, please delete key first."
			puts "         And then re-start this job again."
			puts "         Thank you."
			exit
		} else {
			puts "* Information : No 'SDF_KEY_${CONDITION}' exists. It will be created after making SDF."
		}
		if {$LOAD_MODEL != "SPEF"} {
			puts "* Error : You must define 'LOAD_MODEL' = SPEF."
			exit
		}

		unset -nocomplain EXT ENABLE_SAVE_PIN CANCEL_CLOCK CANCEL_UPDATE_TIMING
		set ENABLE_OCV             false
		set ENABLE_WRITE_SDC       false
		set ENABLE_ACCURACY        false
		set CLOCK_MODE             PROP
		set ENABLE_XT              false
		set CANCEL_REPORT_TIMING   true
		set CANCEL_CU              true
		set ENABLE_ATTRIBUTE_MK40F false
		set CANCEL_UPDATE_TIMING   false
	}
	^(SYSTEM) {
		set FILE_SDC                $SDC(${STA_MODE},${CLOCK_MODE})
		set FILE_SYS_loop_disable   ${APPLY_DIR}/System/Common/SYS_loop_disable.ptsc
		set FILE_SYS_mode_setting   ${APPLY_DIR}/System/Common/SYS_mode_setting.ptsc
		set FILE_SYS_ATOM           ${APPLY_DIR}/System/Common/SYS_ATOM.ptsc ;# "Cut_thr_reg_TGN.ptsc"
		set FILE_SYS_SENGEN         ${APPLY_DIR}/System/Common/SYS_SENGEN.ptsc
		set FILE_SYS_CLK            ${APPLY_DIR}/System/Common/SYS_clk.ptsc
		set FILE_SYS_CLK_FALSE      ${APPLY_DIR}/System/Common/SYS_clk_false.ptsc
                #if {$ENABLE_AOCVM == "true"} {
		#      set FILE_SYS_CU       ${APPLY_DIR}/System/Common/SYS_clk_CU_setting_${CONDITION}_AOCV.ptsc ;
                #} else {
		#      set FILE_SYS_CU       ${APPLY_DIR}/System/Common/SYS_clk_CU_setting_${CONDITION}.ptsc ;
                #}
		set FILE_SYS_CU		    ${APPLY_DIR}/System/Common/SYS_clk_CU_setting.ptsc ;
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
                #if {$ENABLE_AOCVM == "true"} {
		#     set FILE_DFT_CU        ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clk_CU_setting_${CONDITION}_AOCV.ptsc
                #} else {
		#     set FILE_DFT_CU        ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clk_CU_setting_${CONDITION}.ptsc
                #}
		set FILE_DFT_CU		    ${APPLY_DIR}/DFT/Common/${DFT_MODE}_clk_CU_setting.ptsc
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
	set CANCEL_REPORT_TIMING true
        set CANCEL_CONST_REPORT  true
}

###################################################################
# << Error Check >>
###################################################################
# << File existence check >>
if {$ENABLE_ERROR_FILE == "true"} {
        ## mode common constraints ##
        if {$ENABLE_HF_ZERO == "true"} {
	        ERROR_FILE HF_FILE
        }
	ERROR_FILE FILE_OPEN_TRAN
        ## timing constraints
	if {$ENABLE_READ_SDC == "true"} {
		ERROR_FILE FILE_SDC
	}
        if {$ENABLE_SMVA == "true"} {
	        ERROR_FILE SMVA_UPF
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
	                ERROR_FILE FILE_SYS_REP_AC
                }
	        if {$ENABLE_XT == "true"} {
		        ERROR_FILE FILE_SYS_XT_ADD
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
	                ERROR_FILE FILE_DFT_REP_AC
                }
	        if {$ENABLE_XT == "true"} {
		        ERROR_FILE FILE_DFT_XT_ADD
	        }
        }
} else {
	puts "* Information : Canceled ERROR_FILE check-flow."
}

# << Rule check: EXTernal script execution >>
if {[info exists EXT]} {
	if {[info exists MOD_NAME]} {
		puts "* Information : Defined Module Nickname '$MOD_NAME'."
		if {$ENABLE_ERROR_FILE == "true"} {
			ERROR_FILE EXT
		}
	} else {
		ERROR MOD_NAME
	}
}
if {$ENABLE_READ_SDC == "true"} {
	puts "* Information : Select use SDC."
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
if {[info exists DFT_MODE] && $DFT_MODE != "INTEG" && $DFT_MODE != "SDC" && $DFT_MODE != "NONE"} {
      set OPT_FLAG "_${DFT_MODE}${OPT_FLAG}"
}
set MODE      ${CONDITION}_${STA_MODE}_${DELAY}${OPT_FLAG}


###################################################################
# Initial Setting for Synopsys env parameters (EDA recommended)
###################################################################

# Default Values
# (1) NOT applied AOCV / NOT applied crosstalk analysis
set_app_var auto_wire_load_selection                    false  		;# (must)   ;#default true
set_app_var case_analysis_propagate_through_icg         true   		;# (option) ;#default false (EDA recommended : true)
set_app_var case_analysis_sequential_propagation        never  		;# (option) ;#default never (EDA recommended : never)
set_app_var report_default_significant_digits           3      		;# (option) ;#default 2     (EDA recommended : 3)
set_app_var svr_keep_unconnected_nets                   true   		;# (must)   ;#default true
set_app_var timing_all_clocks_propagated                true   		;# (must)   ;#default false
set_app_var timing_remove_clock_reconvergence_pessimism true            ;# (must)   ;#default false
set_app_var timing_clock_reconvergence_pessimism        same_transition ;# (option) ;#default normal (EDA recommended : same_transition)
set_app_var timing_early_launch_at_borrowing_latches    false  		;# (must)   ;#default true  (EDA recommended : false)
set_app_var timing_crpr_threshold_ps                    2      		;# (option) ;#default 20    (EDA recommended : 1) #Before PT2012 change to 5
set_app_var timing_disable_internal_inout_cell_paths    true   		;# (option) ;#default true  (EDA recommended : false) ##MCU true###
set_app_var timing_enable_preset_clear_arcs             false  		;# (option) ;#default false (EDA recommended : true) ##MCU false##
set_app_var timing_input_port_default_clock             false  		;# (option) ;#default false (EDA recommended : false)
set_app_var timing_report_use_worst_parallel_cell_arc   true   		;# (option) ;#default false (EDA recommended : true)
set_app_var timing_use_zero_slew_for_annotated_arcs     auto   		;# (must)   ;#default auto
set_app_var timing_crpr_remove_clock_to_data_crp        false  		;# (option) ;#default false (EDA recommended : false) from 2012.06-SP3-1
set_app_var timing_gclock_source_network_num_master_registers 1 	;# (option) (EDA recommended : 10,000,000) (E1MS=1)
set         extract_model_with_ccs_timing		false		;# (option) (EDA recommended false from PT2015.12-SP3)
set         link_keep_cells_with_pg_only_connection	true		;# (option) (EDA recommended true from PT2015.12-SP3)
set         link_keep_unconnected_cells			true		;# (option) (EDA recommended true from PT2015.12-SP3)
set         timing_enable_max_capacitance_set_case_analysis true	;# (option) (EDA recommended true)
set	    timing_enable_max_transition_set_case_analysis  false	;# (option) (EDA recommended false from PT2017.12)
set         timing_point_arrival_attribute_compatibility true		;# (option) (EDA recommended true from PT2016.12-SP3-1)
set         timing_enable_max_cap_precedence		false		;# (option) (EDA recommended false from PT2017.12)
set         extract_model_short_syntax_compatibility    false		;# (option) (EDA recommended false from PT2016.12-SP3-1) 
set         sh_global_per_message_limit			0		;# (option) (EDA recommended 0 from PT2016.12-SP3)
set         timing_report_union_tns			true		;# (option) ;#default true (EDA recommended : true from PT2016.12-SP3-1)

if {[regexp {2012.} $sh_product_version]} {
  set_app_var timing_report_fast_mode                     false  ;# (must) i ;#default true  (But SoC/MCU false) # After PT2013, no variable
}

# Additional setting
set_app_var timing_reduce_parallel_cell_arcs false ;# Marge IOPATH conditio
set_app_var timing_override_max_capacitance_transition_lib_constraint true ;# Enabled max_capacitance/max_transition threshold less than library limitation.
set_app_var timing_drc_optimization_for_unconstrained_datapath false ;# Enabled Bug W/A about max_cap/tran analysis, abolished from PT201512
puts "Information(PTEnv): Variable(timing_drc_optimization_for_unconstrained_datapath) is abolished from PT2015.12, Error message must be printed."

# Common setting (OCV = AOCVM)
set_app_var  timing_allow_short_path_borrowing		    false
set_app_var  timing_clock_gating_propagate_enable	    true
set_app_var  timing_enable_auto_mux_clock_exclusivity	    false	;# (option) (EDA recommended false)
set_app_var  timing_include_uncertainty_for_pulse_checks    setup_hold	;# (option) (EDA recommended set_hold)
set_app_var  pba_exhaustive_endpoint_path_limit             25000	;# Default infinity (fromPT2017.12): EDA recommended 25000
set_app_var  pba_recalculate_full_path                      false	;# EDA Recommendation(SDF base) false
set_app_var  timing_disable_bus_contention_check	    false
set_app_var  timing_disable_clock_gating_checks		    false
set_app_var  timing_disable_recovery_removal_checks	    false
set          timing_dynamic_loop_breaking		    false	;# abolished from PT201512
puts "Information(PTEnv): Variable(timing_dynamic_loop_breaking) is abolished from PT2015.12, Error message must be printed."
set_app_var  rc_degrade_min_slew_when_rd_less_than_rnet	    false	;# (option) (EDA recommended false)
set_app_var  rc_driver_model_mode			    advanced	;# (option) (EDA recommended advanced)
set_app_var  rc_receiver_model_mode			    advanced	;# (option) (EDA recommended advanced)
set_app_var  report_capacitance_use_ccs_receiver_model	    true	;# (option) (EDA recommended advanced)
set          eco_strict_pin_name_equivalence                true        ;# keep pin nave equivalency for safe

# (2)     Applied AOCV / NOT applied crosstalk analysis
# (4)     Applied AOCV /     Applied crosstalk analysis

# << For Xtalk Analysis >>
# (3) NOT applied AOCV /     Applied crosstalk analysis
if {$LOAD_MODEL=="SPEF" && $ENABLE_XT == "true"} {
	puts "* Information : PrimeTime-SI mode."
	puts "* Information : Checking PT-SI iversion."

	puts "* Information : Applied NEW_METHOD mode"
	puts "                The formula of judgement threshold is (VDD * 0.375)."
	set si_enable_analysis                                   true
	set si_xtalk_delay_analysis_mode                         all_path_edges ;# [all_paths|all_path_edges] Before 'worst_path' (SoC)
	set si_ccs_small_bump_threshold_ratio                    0.3
	set si_ccs_use_gate_level_simulation                     true
	set si_xtalk_analysis_effort_level                       medium
	set si_xtalk_double_switching_mode                       clock_network ;# (must) (EDA recommended clock_network)
	set si_filter_accum_aggr_noise_peak_ratio                0.03	     ;# (option) (EDA recommended 0.03)
	set si_noise_update_status_level			 high	     ;# (option) (EDA recommended high)
	set si_filter_per_aggr_to_average_xcap_ratio             0.0         ;# Default ( For NLDM Library(Innored when CCS) )
	set si_filter_per_aggr_xcap                              0.0         ;# Default ( For NLDM Library(Innored when CCS) )
	set si_filter_total_aggr_xcap_to_gcap_ratio              0.0         ;# Default ( For NLDM Library(Innored when CCS) )
	set si_noise_effort_threshold_within_rails               0.2         ;# Default
	set si_noise_composite_aggr_mode                         statistical ;# (option) (EDA recommended statistical)
	set si_xtalk_composite_aggr_mode                         statistical ;# (option) (EDA recommended statistical)
	set si_xtalk_composite_aggr_quantile_high_pct		 99.73	     ;# (option) (EDA recommended 99.73)
	set si_noise_immunity_default_height_ratio 		 0.375	     ;# (option) (EDA recommended 0.375)
	set si_filter_per_aggr_noise_peak_ratio                  0.01        ;# (option) (EDA recommended 0.01)
	set si_xtalk_composite_aggr_noise_peak_ratio             0.01        ;# (option) (EDA recommended 0.01)
	set si_analysis_logical_correlation_mode                 true        ;# Default
	set si_xtalk_exit_on_max_iteration_count                 2           ;# Default


	set MODE "XTALK_${MODE}"
} elseif {$ENABLE_SMVA == "true"} {
	set MODE "SMVA_${MODE}"
}


## Updating variables
if {$CLOCK_MODE =="IDEAL"} {
	set_app_var timing_all_clocks_propagated                  false
}

##  for debugging
if {[info exists DEBUG_JOB]} {
	set_app_var timing_report_unconstrained_paths             true
}


# << Options for "report_timing" >>
set REPORT_OPT "-nets -nosplit"
if {![info exists NUM_NWORST]} { set NUM_NWORST   1 }
if {![info exists NUM_MAX]}    { set NUM_MAX      20000 }
if {![info exists NUM_SLACK]}  { set NUM_SLACK    -0.00001 }

if {![regexp {2012.} $sh_product_version]} {
  puts "*Information(PTEnv): -sort_by group added"
  set REPORT_OPT "$REPORT_OPT -sort_by group"
}
if {![regexp {2012.} $sh_product_version] && ![regexp {2013.} $sh_product_version]} {
	set REPORT_OPT "$REPORT_OPT -include_hierarchical_pins"
}

if {$DELAY == "HOLD"} {
	set REPORT_OPT "$REPORT_OPT -delay_type min -input -path full_clock_expanded -derate"
} else {
	set REPORT_OPT "$REPORT_OPT -delay_type max -input"
}
set REPORT_OPT_SLACK "$REPORT_OPT -slack_lesser_than ${NUM_SLACK} -max_paths ${NUM_MAX} -nworst ${NUM_NWORST}"
set REPORT_OPT       "$REPORT_OPT                                 -max_paths 300"

if {$ENABLE_XT == "true"} {
	set REPORT_OPT_SLACK "$REPORT_OPT_SLACK -significant_digits 3 -crosstalk_delta -trans -cap -uniq"
	set REPORT_OPT       "$REPORT_OPT       -significant_digits 3                  -trans"
	set ADD_FCLK         "true"
} else {
	set REPORT_OPT_SLACK "$REPORT_OPT_SLACK -significant_digits 3                  -trans -cap -uniq"
	set REPORT_OPT       "$REPORT_OPT       -significant_digits 3"
}
if {[info exists ADD_FCLK] && $DELAY != "HOLD"} {
	set REPORT_OPT_SLACK "$REPORT_OPT_SLACK -path full_clock_expanded"
}

if {$ENABLE_OCV == "true"} {
	set OPT_SS_KEY "_OCV"
} else {
	set OPT_SS_KEY ""
}

#<< Select naming word >>
set NWORD {}

# << Display Mode Information >>
puts "
################################
# $MODE
# --Information--
#   Condition    : ${CONDITION}
#   STA_MODE     : ${STA_MODE}
"
if {[info exists DFT_CLK_MODE]} {
        puts "#   DFT_CLCOK    : ${DFT_CLK_MODE}"
}
puts "
#   LibMode      : ${LIB_MODE}
#   LoadModel    : ${LOAD_MODEL}
#   ReportTiming : ${REPORT_OPT}
#   OPT_SS_KEY   : ${OPT_SS_KEY}
################################
"

###################################################################
# << Multi-core function >>
###################################################################
set multi_core_enable_analysis false
getenv LSB_MCPU_HOSTS
set Host [lindex [getenv LSB_MCPU_HOSTS] 0]
set Ncpu [lindex [getenv LSB_MCPU_HOSTS] 1]

puts "* Information : Enable MULTICORE with '$Ncpu' cpu on '$Host'."
set_host_options -max_cores $Ncpu
if {$Ncpu > 1} {
	set ENABLE_MULTICORE YES
	report_host_usage -verbose
}

###################################################################
# << Read Design >>
###################################################################
check_resource Read_design
if {$ENABLE_RESTORE == "true"} {
	if {[file exist	"./LOAD/SS_KEY_${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}"] && [file exist "./LOAD/save.${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}"]} {
		puts "* Information : Session Data has been ready."
		puts "* Information : Restore Session (save session data are netlist and spef/sdf)."
		restore_session ./LOAD/save.${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}
		set RESTORE true
	} else {
		puts "* Information : Session Data has not been ready. Changed to read netlist & LOAD data."
		set ENABLE_RESTORE false
	}
}
if {$ENABLE_RESTORE == "false"} {
	if {$USE_DB == "true"} {
		puts "* Information : Reading DB design..."
		read_ddc -netlist_only ./DB/${TOP}.ddc
	} else {
		puts "* Information : Reading Gate level netlist..."
		read_verilog ./Gate/${NET}

		#Read Verilog
		if {[info exists READ_VERILOG]} {
			puts "* Information : Reading designs based on user definition."
			foreach tmp ${READ_VERILOG} {
				read_verilog $tmp
			}
		}
		#Remove Design
		if {$ENABLE_REMOVE_DESIGN == "true" && [info exists REMOVE_DESIGN]} {
			puts "Error : Removing designs based on user definition(shmsta)."
			set REMOVE_DESIGNS [split $REMOVE_DESIGN ","]
			foreach tmp ${REMOVE_DESIGNS} {
				puts "* Information : Removing designs $tmp."
				remove_design $tmp
			}
		}

	}
	set RESTORE false
}
puts "* Information : Netlist has read successfully."


###################################################################
# << Linking with Libraries >>
###################################################################
# << Setup Priority Link Library Information >>
source -echo ./${CONDITION}.${LIB_MODE}.cfg

# << Linking >>
check_resource link_design1
current_design ${TOP}
if {$RESTORE == "true"} {
	puts "* Information : linking process has been skipped by 'RESTORE' direction."
} else {
	if {$KEEP_SUB_DESIGNS == "true"} {
		puts "* Information : linking with '-keep_sub_designs' options."
		link_design -keep_sub_designs
	} else {
		puts "* Information : linking. Unused sub-designs will be removed."
		link_design
	}
}

# << Display Using Libraries >>
if {$ENABLE_ACCURACY == "true"} {
	list_libraries -only_used
} else {
	puts "* Information : Canceled \"list_libraries -only_used\" report"
}


###################################################################
# << Making Command files to change Vth >>
###################################################################
if {$ENABLE_MK_VTH_CMD == "true"} {
	puts "* Information : Making size_cell commands as to './LOAD/TO_MVTH.tcl' & './LOAD/TO_LVTH.tcl'."
	if {[info exists STBY_AREA]} {
		if {$CLOCK_MODE == "PROP"} {
			puts "* Information : Making change Vth command without clock cells for Clock-propagated mode."
			WAIT_KEY ./LOAD/KEY_WO_CLK_CELL.SYSTEM
			WAIT_KEY ./LOAD/KEY_WO_CLK_CELL.DFT
			CHNGE_VTH_TO_ML_WO_CLK ./LOAD/WO_CLK_CELL.SYSTEM.list ./LOAD/WO_CLK_CELL.DFT.list

			puts "* Information : Finished making command and created a key file."
			echo "CHNGE_VTH_TO_ML_WO_CLK" > ./LOAD/KEY_TO_CHG_VTH_WO_CLK
		} else {
			puts "* Information : Making change Vth command for Clock-ideal mode."
			CHNGE_VTH_TO_ML
		}
		puts "* Information : Finished making size_cell commands."
		if {![info exists DEBUG_JOB]} {exit}
	} else {
		puts "* Error : You must define paramater 'STBY_AREA' in 'pathinfo.cfg'."
		exit
	}
} else {
	puts "* Information : size_cell command for timing estimation with Vth shift will be not created in this job."
}



#------------------------------------------------------------------
# << Applying Tied constraints for PowerNets >>
#------------------------------------------------------------------
puts "* Information : Checking Power attribute nets"
if {$CANCEL_TIE_POWER_NET == "false"} {
	puts "* Information : Power attribute nets will be tied with 'set_case_analysis' command."
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

#------------------------------------------------------------------
# << Making HighFanout collection >>
#------------------------------------------------------------------
if {$STA_MODE == "mkHF"} {
	puts "* Information : Setting max_fanout ${MAXFANOUT_THRESHOLD}."    ;# ADD mcu.v1r50a
	set_max_fanout ${MAXFANOUT_THRESHOLD} [current_design]              ;# ADD mcu.v1r50a
	redirect /dev/null { update_timing -full }                          ;# ADD mcu.v1r50a
	puts "* Information : Getting max_fanout report."
	redirect ./LOAD/rep.${MODE}_max_fanout_0 {
		report_constraint -all_violators -max_fanout -nosplit
	}
	puts "* Information : making set_load command from max_fanout report."
	MK_HF_CMD $HF_FILE ${MAXFANOUT_THRESHOLD}
	puts "* Information : HF-file '${HF_FILE}' has been created."
	echo "HF-File: $HF_FILE" > ./LOAD/HF_KEY

	# << Check netlist structure >>
	puts "* Information : Checking logic structure of Direct_Connected_FF"
	redirect ${REPORT_DIR}/rep.REPORT_DIRECT_CONNECTED_FF { REPORT_DIRECT_CONNECTED_FF }

	puts "* Information : Getting reference_report"
	redirect ${REPORT_DIR}/report_reference.rep           { report_reference }

	puts "* Information : Getting hierarchy report"
	redirect ${REPORT_DIR}/CHECK_HIER.rep                 { CHECK_HIER }

	if {![info exists DEBUG_JOB]} {exit}
}

#------------------------------------------------------------------
# << Analysis condition>>
#------------------------------------------------------------------
# << OCV SETTING >>
if {$DELAY == "NONE"} {
    puts "* Information: Due to \$DELAY is $DELAY, OCV settings are skipped."
} elseif {$STA_MODE == "mkSDF"} {
    #puts "* Information : set_operating_conditions for mkSDF"
    #eval "set_operating_conditions $mksdf_operating_conditions_($CONDITION)"
    if {$CLOCK_MODE == "PROP"} {
        set timing_ideal_clock_zero_default_transition false
    } else {
        set timing_ideal_clock_zero_default_transition true
    }
    puts "* Information: Due to \$STA_MODE is $STA_MODE, OCV settings are skipped."
    puts "* Information: \$CLOCK_MODE is $CLOCK_MODE."
    puts "* Information: 'timing_ideal_clock_zero_default_transition' $timing_ideal_clock_zero_default_transition"
} else {
    if {$ENABLE_OCV=="true"} {
        puts "* Information: Selected Layout LOAD with OCV"
        set OPT_SS_KEY "_OCV"
        if {[info exists ocv_param_table] && ![info exists ocv_param_table_clock_data]} {
            puts "* Information: ocv setting was found."
            READ_OCV_INFO_FROM_DESIGN_CFG
            if {[info exists ocv_param_list(${CONDITION},${DELAY})]} {
                set ocv_param $ocv_param_list(${CONDITION},${DELAY})
                set_timing_derate -cell_delay -early [lindex $ocv_param 0]
                set_timing_derate -cell_delay -late  [lindex $ocv_param 1]
                set_timing_derate -net_delay  -early [lindex $ocv_param 2]
                set_timing_derate -net_delay  -late  [lindex $ocv_param 3]
                #set OUTSIDE_LIB [get_lib_cells -quiet $[concat outside_characterize_lib]]
                #if {[sizeof ${OUTSIDE_LIB}] > 0} {
                #    set_timing_derate -cell_delay -early [lindex $ocv_param 4] [eval "get_lib_cells $[concat outside_characterize_lib]" ]
                #    set_timing_derate -cell_delay -late  [lindex $ocv_param 5] [eval "get_lib_cells $[concat outside_characterize_lib]" ]
                #} else {
                #    puts "Information: outside_characterize_lib is not defined."
                #}
            }
        } elseif {[info exists ocv_param_table_clock_data] && ![info exists ocv_param_table]} {
            puts "* Information: ocv clock and data setting was found."
            READ_OCV_INFO_FROM_DESIGN_CFG_CLOCK_DATA
            if {[info exists ocv_param_list_clock_data(${CONDITION},${DELAY})]} {
                set ocv_param $ocv_param_list_clock_data(${CONDITION},${DELAY})
                set_timing_derate -cell_delay -early -clock [lindex $ocv_param 0]
                set_timing_derate -cell_delay -early -data  [lindex $ocv_param 1]
                set_timing_derate -cell_delay -late  -clock [lindex $ocv_param 2]
                set_timing_derate -cell_delay -late  -data  [lindex $ocv_param 3]
                set_timing_derate -net_delay  -early -clock [lindex $ocv_param 4]
                set_timing_derate -net_delay  -early -data  [lindex $ocv_param 5]
                set_timing_derate -net_delay  -late  -clock [lindex $ocv_param 6]
                set_timing_derate -net_delay  -late  -data  [lindex $ocv_param 7]
                # set OUTSIDE_LIB [get_lib_cells -quiet $[concat outside_characterize_lib]]
                #if {[sizeof ${OUTSIDE_LIB}] > 0} {
                #    set_timing_derate -cell_delay -early -clock [lindex $ocv_param 8]  [eval "get_lib_cells $[concat outside_characterize_lib]" ]
                #    set_timing_derate -cell_delay -early -data  [lindex $ocv_param 9]  [eval "get_lib_cells $[concat outside_characterize_lib]" ]
                #    set_timing_derate -cell_delay -late  -clock [lindex $ocv_param 10] [eval "get_lib_cells $[concat outside_characterize_lib]" ]
                #    set_timing_derate -cell_delay -late  -data  [lindex $ocv_param 11] [eval "get_lib_cells $[concat outside_characterize_lib]" ]
                #} else {
                #    puts "Information: outside_characterize_lib is not defined."
                #}
            } else {
                puts "* Error: No OCV parameter was found for \"${CONDITION} ${DELAY}\"."
                exit
            }
        } else {
            puts "* Error: No (or two kind of) OCV parameter was found in design.cfg."
            exit
        }
        # << OCV setting for special library >>
        if {[info exists special_ocv_param_table] && ![info exists special_ocv_param_table_clock_data]} {
            puts "* Information: special ocv setting was found."
            READ_SPECIAL_OCV
            if {[info exists special_ocv_param_list(${CONDITION},${DELAY})]} {
                set ocv_param $special_ocv_param_list(${CONDITION},${DELAY})
                set lib [lindex $ocv_param 0]
                set_timing_derate -cell_delay -early [lindex $ocv_param 1] [eval "get_lib_cells ${lib}"]
                set_timing_derate -cell_delay -late  [lindex $ocv_param 2] [eval "get_lib_cells ${lib}"]
            }
        } elseif {[info exists special_ocv_param_table_clock_data] && ![info exists special_ocv_param_table]} {
            puts "* Information: Special ocv clock data setting was found."
            READ_SPECIAL_OCV_CLOCK_DATA
            if {[info exists special_ocv_param_list_clock_data(${CONDITION},${DELAY})]} {
                foreach ocv $special_ocv_param_list_clock_data(${CONDITION},${DELAY}) {
                    set lib [lindex $ocv 0]
                    set_timing_derate -cell_delay -early -clock [lindex $ocv 1] [eval "get_lib_cells ${lib}"]
                    set_timing_derate -cell_delay -early -data  [lindex $ocv 2] [eval "get_lib_cells ${lib}"]
                    set_timing_derate -cell_delay -late  -clock [lindex $ocv 3] [eval "get_lib_cells ${lib}"]
                    set_timing_derate -cell_delay -late  -data  [lindex $ocv 4] [eval "get_lib_cells ${lib}"]
                }
            } else {
                puts "* Information: No special OCV parameter was found for \"${CONDITION} ${DELAY}\"."
            }
        } else {
            puts "* Information: No (or two kind of) special OCV parameter was found in design.cfg."
        }
    } else {
        puts "* Information : Selected Layout LOAD without OCV"
        set OPT_SS_KEY ""
    }
}



###################################################################
# << Setting LOAD >>
###################################################################
check_resource Load-Settings
remove_wire_load_model
set_app_var auto_wire_load_selection    false
set_wire_load_mode              top

check_resource Set_the_load_model

if {$ENABLE_AOCVM == "true"} {
    if { [string match "MF3" $PROCESS] } {
        puts "Information: PrimeTime read location from Spef"
        set_app_var  read_parasitics_load_locations                 true ;# (must) EDA Recommendation: true     ;# ManatiiPF true
    } else {
        puts "Information: PrimeTime doesn't read location from Spef"
        set_app_var  read_parasitics_load_locations                 false ;# (must) EDA Recommendation: true
    }
}

if {$RESTORE == "true"} {
	puts "* Information : LOAD model setting process has been skipped by 'RESTORE' direction."
} else {
        if {$ENABLE_MESSAGE_UNLIMIT == "true"} {
                set_app_var sh_message_limit 1500000
                puts "* Information : Message limit changed to 1500000."
        }
	switch ${LOAD_MODEL} {
		SPEF {
		    suppress_message {PARA-045}
		    set SPEF [expr $[concat LOAD_SPEF_${CONDITION}]]
		    puts "######################################"
		    puts "# SPEF MODE                          #"
		    puts "######################################"
		    if { [file exists ./LOAD/${SPEF}] } {
			puts "./LOAD/${SPEF}"
		    } else {
			puts "* Error : There's no load-file ./LOAD/${SPEF}."
			exit
		    }
		    if {[info exists BLOCK_LOAD_${CONDITION}]} {
			puts "######################################"
			puts "# For BlockBase SPEF"
			puts "######################################"
			set BLOCK_SPEF [expr $[concat BLOCK_LOAD_${CONDITION}]]
			foreach MODULE_LOAD_PAIR ${BLOCK_SPEF} {
			   if {[llength ${MODULE_LOAD_PAIR}] > 1} {
				set MODULE   [lindex ${MODULE_LOAD_PAIR} 0]
				set MODULE_LOAD     [lindex ${MODULE_LOAD_PAIR} 1]
				set INSTANCE [get_cells -h * -filter "ref_name==$MODULE"]
				if {[sizeof_collection ${INSTANCE}] > 0} {
					foreach_in_collection INST ${INSTANCE} {
					   set INST_NAME [get_attribute ${INST} full_name]
					   puts "Read parasitics for ${MODULE} (instance ${INST_NAME})"
					   redirect -append #Info_Hier_Spef {
						puts "${MODULE} (instance ${INST_NAME}) $MODULE_LOAD"
					   }
		    			   if {$ENABLE_XT == "true"} {
					      redirect ./LOG/read_spef_XT.${MODE}${SUFFIX} {
						read_parasitics -keep_capacitive_coupling [subst ${MODULE_LOAD}] -path ${INST_NAME}
					      }       
					   } else {
					      redirect ./LOG/read_spef.${MODE}${SUFFIX} {
						read_parasitics [subst ${MODULE_LOAD}] -path ${INST_NAME}
					      }       
					   }
					}
				} else {
					puts "MODULE-LOAD pair not found."
				}
			    }
			}
		    } else {
		    	if {$ENABLE_XT == "true"} {
				redirect ./LOG/read_spef_XT.${MODE}${SUFFIX} {
					puts "Information: No Block base spefs are set."
				}
			} else {
				redirect ./LOG/read_spef.${MODE}${SUFFIX} {
					puts "Information: No Block base spefs are set."
				}
			}
		    }
		    if {$ENABLE_XT == "true"} {
			set parasitics_log_file ./LOG/log.read_spef_XT.${MODE}${SUFFIX}
			puts "######################################"
			puts "# keep capacitive_coupling (For Xtalk)"
			puts "######################################"
			puts "LogFile : ${parasitics_log_file}"
			redirect -append ./LOG/read_spef_XT.${MODE}${SUFFIX} { 
				read_parasitics -keep_capacitive_coupling ./LOAD/${SPEF}
			}

		    } else {
			set parasitics_log_file ./LOG/log.read_spef.${MODE}${SUFFIX}
			puts "#########################################"
			puts "# None capacitive_coupling (For Normal)"
			puts "#########################################"
			puts "LogFile : ${parasitics_log_file}"

			puts "LogFile : ./LOG/read_spef.${MODE}${SUFFIX}"
			redirect -append ./LOG/read_spef.${MODE}${SUFFIX} {
				read_parasitics ./LOAD/${SPEF}
			}
		    }
                    puts "* Information: Delete resistance between IO BUF and PAD"
                    set_resistance 0 [get_nets -of [get_port * -filter "direction == out || direction == inout" ]]
		}
		SDF  {
			puts "############"
			puts "# SDF MODE #"
			puts "############"
			set SDF "${TOP}_${CONDITION}.sdf.gz"
			puts "Load    : $SDF"
			puts "LogFile : ./LOG/read_sdf.${MODE}"
			if { [file exists ./LOAD/${SDF}] } {
				redirect ./LOG/read_sdf.${MODE} {
					read_sdf ./LOAD/$SDF -analysis_type on_chip_variation -min_type sdf_min -max_type sdf_max

				}
			} else {
				puts "* Error : There's no load-file ./LOAD/${SDF}."
				exit
			}
		}
		WLM  {
			puts "############"
			puts "# WLM MODE #"
			puts "############"
			set_app_var auto_wire_load_selection    true
			set_wire_load_mode              $wire_load_mode(WLM)
			set_wire_load_selection_group   $wire_load_selection_group -library $wire_load_lib_name
		}
		NO_LOAD {
			puts "######################"
			puts "# NO LOAD has Loaded #"
			puts "######################"
			set_app_var auto_wire_load_selection    true
			set_wire_load_selection_group "WireAreaForZero" -library $wire_load_lib_name
		}
		default {
			puts "Error: $LOAD_MODEL is not supported for \$LOAD_MODEL"
			exit -f 
		}
	}
}

# << Read PT ECO iformat command (doping & shotgunIPO & bypassHOLD) >>
if {$PT_ECO_FILE != "NONE"} {
	puts "* Information : Applying ECO command."
	current_design ${TOP}
	
	set num 0
	foreach tmp ${PT_ECO_FILE} {
		if {[file exists $tmp]} {
			#if {$num == 0} { link_design -keep_sub_designs }
			puts "* $tmp is detected."
			source -echo -verbose $tmp
			incr num
		} else {
			puts "* Error : '${tmp}' No such file or directory."
		}
	}
	if {$num == 0} { puts "* Information : No PT_ECO_FILE has been applied." }
}


###################################################################
#  Annotate Big HighFanout net zero load
###################################################################
if {$ENABLE_HF_ZERO == "true" } {
	check_resource Hi-Fanout_check
	puts "* Information : Applying HF commands."
	puts "* Information : Loading ${HF_FILE}"
	source -echo -verbose ${HF_FILE}
} else {
	puts "* Information : Canceled applying HF commands."
}


###################################################################
# << Setting AOCVM >>
###################################################################
check_resource AOCVM-Settings
if {$ENABLE_AOCVM == "true"} {
        if {$ENABLE_OCV == "false"} {
	     puts "* Information : chainging ENABLE_OCV false -> true for getting AOCVM report."
        }
	puts "* Information : Applying AOCVM setting."
	# Special setting AOCVM only
	set_app_var  timing_aocvm_ocv_precedence_compatibility	    false ;# (must) EDA recommenmded false
	set_app_var  timing_aocvm_analysis_mode                     {combined_launch_capture_depth delay_based_model}	;# (must) EDA recommended combined_launch_capture_depth delay_based_model
	set_app_var  timing_aocvm_infinite_single_leg_bounding_box  false ;# (must) EDA recommended false
	set_app_var  timing_aocvm_remove_edge_mismatch_crp          false ;# (option) EDA recommended false from 2012.06-SP3-1
	set_app_var  timing_aocvm_enhanced_delay_based_model        true  ;# (must) EDA recommended true
	set_app_var  timing_report_use_worst_parallel_cell_arc      true

        if {[regexp $PT_VER201206 $sh_product_version] || [regexp $PT_VER201306 $sh_product_version] 
		|| [regexp $PT_VER201312 $sh_product_version] || [regexp $PT_VER201406 $sh_product_version]
		|| [regexp $PT_VER201412 $sh_product_version] || [regexp $PT_VER201512 $sh_product_version]
		|| [regexp $PT_VER201612 $sh_product_version]} {
		set          pba_aocvm_only_mode                            true  ;# (must) EDA recommended true(cannot use it from PT2017, obslute)
	} else {
		set          pba_derate_only_mode			    true  ;# (must) EDA recommended true
	}


	switch $AOCVM_MODE {
		PBA {
			set timing_aocvm_enable_analysis		false	;# (must) EDA recommended false
			set NWORD        "${NWORD}_AOCVM_PBA"
		}
		GBA {
			set timing_aocvm_enable_analysis		true
			set NWORD        "${NWORD}_AOCVM_GBA"
		}
		default {
			set NWORD        "${NWORD}_AOCVM_unknown"
		}
	}

        foreach aocv_table   [glob ./${APPLY_DIR}/AOCVM/${CONDITION}/*.pt_table] {
                puts "* Information : Reading derate table for $aocv_table"
                read_aocvm ${aocv_table}
        }
        foreach aocv_command [glob ./${APPLY_DIR}/AOCVM/${CONDITION}/*.pt_command] {
                puts "* Information : Applying stage table for $aocv_command"
                source -echo -verbose ${aocv_command}
        }
	
} else {
	puts "* Information : Cancel Applying AOCVM setting."
}

###################################################################
#  Add attribute for mk45 & ML-netlist
###################################################################
if {$ENABLE_ATTRIBUTE_MK40F == "true"} {
	puts "* Information : Setting library name attribute to all cells."
	SET_LIBNAME_OF_REF
	puts "* Information : Setting original cell size attribute to all cells."
	ADD_ORIGINAL_AREA
} else {
	puts "* Information : Canceled to add cell attribute for mk40F."
}



###################################################################
# External load capacity & setting driveability
###################################################################
#<< Set IO_LOAD_CONST_FILE >>
if {$ENABLE_IO_LOAD == "true" && $ENABLE_READ_SDC == "false" } {
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
#  Save session data for restore_session
###################################################################
if {$ENABLE_SS_SIMPLE == "true"} {
	if {[file exist "./LOAD/save.${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}${OPT_FLAG}"]} {
		puts "* Information : Session './LOAD/save.${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}${OPT_FLAG}' data has been created."
	} else {
		puts "* Information : Save Session (netlist and spef/sdf)."
		save_session ./LOAD/save.${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}${OPT_FLAG}

		# << Output SDF_KEY to announce SDF file is finished >>
		puts "* Information : session data './save.${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}${OPT_FLAG}' was created."
		echo "session: ${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}${OPT_FLAG}" > ./LOAD/SS_KEY_${LOAD_MODEL}.${CONDITION}${OPT_SS_KEY}${OPT_FLAG}
	}
}



report_design
puts "timing_crpr_threshold_ps is ${timing_crpr_threshold_ps}"

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
			if {$CANCEL_CONST == "true"} {
				puts "* Information : No ATOM constraints has been applied."
			} else {
				puts "* Information : reading $FILE_SYS_ATOM"
				source -echo -verbose $FILE_SYS_ATOM
			}
			

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
                        if {$ENABLE_XT == "true"} {
				puts "* Information : Applying additional clock constraints for Xtalk."
				source -echo -verbose ${FILE_SYS_XT_ADD}
                        }
                }
		# << AC setting >>
		if {$CANCEL_CONST_AC == "true"} {
		        puts "* Information : No Input/Output constraint has been applied."
		} else {
		        # << Reading constraints of AC-timing >>
		        puts "* Information : Reading AC input settings for ${DELAY}."
		        source -echo -verbose $FILE_SYS_AC_IN
		        puts "* Information : Reading AC output settings for ${DELAY}."
		        source -echo -verbose $FILE_SYS_AC_OUT
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
				puts "Error : Reading Tentative constraints ${FILE_SYS_TENTATIVE}."
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
			}
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
                ## below files are not included in SDC constraints.(TCL/SDC mode read below)
                if {$CANCEL_CLOCK == "false" || $ENABLE_READ_SDC == "true"} {
			# << Reading clock latency of AC-timing >>
			puts "* Information : reading $FILE_DFT_AC_CLK_LATENCY"
                       	source -echo -verbose $FILE_DFT_AC_CLK_LATENCY
		        if {$CANCEL_CU == "true"} {
			        puts "* Information : Canceled $FILE_DFT_CU reading by CANCEL_CU"
		        } else {
			        puts "* Information : reading $FILE_DFT_CU"
			        source -echo -verbose $FILE_DFT_CU
		        }
		        if {$ENABLE_XT == "true"} {
			        puts "* Information : Applying additional clock constraints for Xtalk."
			        source -echo -verbose ${FILE_DFT_XT_ADD}
		        }
                }
		# << AC setting >>
		if {$CANCEL_CONST_AC == "true"} {
		                puts "* Information : No Input/Output constraint has been applied."
		} else {
		                # << Reading constraints of AC-timing >>
		                puts "* Information : Reading AC input settings for ${DELAY}."
		                source -echo -verbose $FILE_DFT_AC_IN
		                puts "* Information : Reading AC output settings for ${DELAY}."
		                source -echo -verbose $FILE_DFT_AC_OUT
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
				puts "Error : Reading Tentative constraints ${FILE_DFT_TENTATIVE}."
                        	source -echo -verbose $FILE_DFT_TENTATIVE
				puts "Information : End of Tentative constraints ${FILE_DFT_TENTATIVE}."
			}
                }
	}

	default {
		puts "Error: STA_MODE is not defined!"
		exit
	}  
}
## Common file
set FILE_CLKVT_CFG             ${APPLY_DIR}/ALL/clkvt_check.cfg

TOTAL_RUN_TIME

#<< Set ClockLatency When Ideal >>
set timing_ideal_clock_zero_default_transition false
if {$CANCEL_CLOCK == "true"} {
	puts "* Information : No clock latency has been applied."
} else {
	puts "* Information : Applying clock_latency."
	if {$CLOCK_MODE == "PROP"} {
		puts "* Information : Selected actual propagated latency."
		set_propagated_clock [all_clocks]
	} else {
		puts "* Information : Selected Ideal latency."
                puts "* Information : No Additional constraints for ideal clock."
                set timing_ideal_clock_zero_default_transition    true
                puts "* Information : 'timing_ideal_clock_zero_default_transition' $timing_ideal_clock_zero_default_transition"
	}
}

# << Information PT variable before getting reports >>
redirect ./LOG/var_${LOAD_MODEL}.${MODE}${NWORD}_initial${SUFFIX} { printvar }

# << Information CU getting reports >>
if {$CANCEL_CU == "true"} {
         puts "* Information : Canceled getting CU report by CANCEL_CU"
} else {
   if {$CANCEL_CLOCK == "true"} {
         puts "* Information : CANCEL_CLOCK is true -> change CANCEL_CU to true."
         set CANCEL_CU true
   } else {
         puts "* Information : getting CU report"
	if {$ENABLE_AOCVM == "true"} {
         	redirect LOG/CU_AOCVM_${MODE}${SUFFIX}${OPT_FLAG}.log { report_clock -skew -nosplit}
	} else {
         	redirect LOG/CU_${MODE}${SUFFIX}${OPT_FLAG}.log { report_clock -skew -nosplit}
	}
   }
}

#<< Set MinPluseThreshold >>
if {$CANCEL_CONST_REPORT == "true"} {
        puts "* Information : No minimum pulse width constraint has been applied."
} else {
	puts "* Information : setting minpulse constraints for clock line"
        check_resource "Set_mpw_constraint"
	set_min_pulse_width -high ${MIN_PULSE_THRESHOLD}
	set_min_pulse_width -low  ${MIN_PULSE_THRESHOLD}
}

# << remove clocks MaxTra/MaxCap >>
if { $IGNORE_TRAN_CLKS != "NULL"} {
	set IGNORE_CLOCKS [get_clocks -quiet ${IGNORE_TRAN_CLKS}]
	puts "Information: Remove clocks [get_object_name ${IGNORE_CLOCKS}] for MaxTran/MaxCap checking"
	remove_clock ${IGNORE_CLOCKS}
} else {
	puts "Information: IGNORE_TRAN_CLKS is NULL"
}

######################################################################################################################################
# << Check OCV >>
######################################################################################################################################
if {$ENABLE_OCV=="true"} {
    redirect ${REPORT_DIR}/ocv_timing_derate.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress -tee { report_timing_derate -nosplit }
}

######################################################################################################################################
# << Update Timing >>
######################################################################################################################################
if {$CANCEL_UPDATE_TIMING == true} { 
	puts "* Information : Canceled update_timing-full command"
        puts "* Information:  PAD net delay may be occurred"
} else {
	set timing_save_pin_arrival_and_slack $ENABLE_SAVE_PIN
	puts "* Information : Applying update_timing-full"
	if {[info exists ENABLE_MULTICORE] && [regexp $PT_VER201206 $sh_product_version]} { start_hosts }
	check_resource Before_update_timing
        if {$ENABLE_MESSAGE_UNLIMIT == "true"} {
		set sh_message_limit 1500000
		puts "* Information : Message limit changed to $sh_message_limit."
		puts "* Information : Running update_timing now."
		redirect LOG/update_timing_unlimit_message.${MODE}${SUFFIX}.log { update_timing -full }
		puts "* Information : Update_timing finished. Please refer to Log file.(./LOG/update_timing_unlimit_message.log) "
	} else {
		set_message_info -id RC-011 -limit 0
		update_timing -full
	}
	## Bug: incrrect crpr in case of V1R
        #puts "* Information: Delete resistance between IO BUF and PAD for W/A of pad net delay"
        #set_resistance 0 [get_nets -of [get_port * -filter "direction == out || direction == inout" ]]

	# << Annotated check >>
        if {$LOAD_MODEL == "SPEF" && $ENABLE_ANNOTATED_CHECK == "true" && ![info exists MOD_NAME]} {
		puts "* Information : Now on annotated checking..."
		set maxnet 1500000
		redirect ${REPORT_DIR}/rep.${LOAD_MODEL}.${MODE}${NWORD}_parasitics.log {
	        	report_annotated_parasitics
		}
		redirect ${REPORT_DIR}/rep.${LOAD_MODEL}.${MODE}${NWORD}_pin2pin_parasitics.log {
	        	report_annotated_parasitics -max_nets $maxnet -list_not_annotated -pin_to_pin_nets
		}
		sh tail -25 ${REPORT_DIR}/rep.${LOAD_MODEL}.${MODE}${NWORD}_pin2pin_parasitics.log > ${REPORT_DIR}/rep.not_annotated_${LOAD_MODEL}.${MODE}${NWORD}_parasitics.log
        	sh bin/annotated_check.pl \
	  	${REPORT_DIR}/rep.${LOAD_MODEL}.${MODE}${NWORD}_pin2pin_parasitics.log \
	  	./tmp.anno.${LOAD_MODEL}.${MODE}${NWORD}.tcl \
	  	${REPORT_DIR}/rep.not_annotated_${LOAD_MODEL}.${MODE}${NWORD}_parasitics.log

	        source ./tmp.anno.${LOAD_MODEL}.${MODE}${NWORD}.tcl
        	sh rm ./tmp.anno.${LOAD_MODEL}.${MODE}${NWORD}.tcl
	} elseif {$STA_MODE == "mkSDF"} {
		sh ./bin/report_annotated ${REPORT_DIR}/rep.${LOAD_MODEL}.${MODE}${NWORD}_parasitics.log > chk.${LOAD_MODEL}.${MODE}${NWORD}_check_net.list_wk
		sh sed -f ./bin/BACK.sed  chk.${LOAD_MODEL}.${MODE}${NWORD}_check_net.list_wk            > chk.${LOAD_MODEL}.${MODE}${NWORD}_check_net.list
		source -echo -verbose chk.${LOAD_MODEL}.${MODE}${NWORD}_check_net.list
		redirect ${REPORT_DIR}/chk.${LOAD_MODEL}.${MODE}${NWORD}_check_net.result { CHECK_DSPF_ERROR $TARGET_NET_LIST }
	}

	check_resource Before_report_timing
}

		
		

###################################################################
# << SMVA(Simultaneous Multi Voltage Analysis) >>
###################################################################
if {$ENABLE_SMVA == "true"} {
        echo "*Information : Running SMVA command. "

        #redirect ./LOG/load_upf_${MODE}.log { load_upf ${SMVA_UPF} }
        load_upf ${SMVA_UPF} 
	set_app_var timing_enable_cross_voltage_domain_analysis true

	source -echo -verbose ./apply/ALL/smva_guardband.tcl

        redirect ./LOG/update_timing_smva_on_${MODE}.rep { update_timing -full }
        check_timing -override unconnected_pg_pins > ./LOG/check_timing_smva.unconnected_pg_pins_${MODE}.vio

	# CHECK_VARIABLES 2017/02/20
	COMP_VAR ./scr/VariableCheck/exp_variable_smva.${PROCESS}.list > ./LOG/var_comp.${MODE}.SMVA
        source -echo -verbose ./apply/ALL/smva_timing_report.tcl
	if {$ENABLE_SS == "true"} {
		check_resource Before_save_session
		puts "* Information : Creating session data for SMVA as ./LOAD/save.${LOAD_MODEL}.${MODE}${NWORD} now....."
		save_session ./LOAD/save.${LOAD_MODEL}.${MODE}${NWORD}

		# << Output SESSION_KEY to announce session data output is finished >>
		puts "* Information : Session-data save.${LOAD_MODEL}.${MODE}${NWORD} was created."
		echo "" > ./LOAD/SESSION_KEY_${LOAD_MODEL}.${MODE}${NWORD}
		puts "* Information : ENABLE_SS is changed to false due to avoiding to overwrite session"
		set ENABLE_SS false
	} else {
		puts "* Information : Canceled writing Session file."
	}

	if {![info exists DEBUG_JOB]} {exit}

} else {
    echo "*Information : SMVA command was skipped. "
}

###################################################################
# << make SDF file with constraints >>
###################################################################
if {$STA_MODE == "mkSDF"} {
	puts "* Information : Selected 'mkSDF' mode for MCU product."

	# << Writing SDF file >>
	check_resource Before_write_sdf
	write_sdf \
		-version 3.0 \
		-include {SETUPHOLD RECREM} \
		-no_edge_merging {timing_checks cell_delays} \
		-significant_digits 4 \
		-compress gzip ./LOAD/${TOP}.${LOAD_MODEL}.${MODE}${NWORD}.sdf.gz
	#	-no_edge_merging {timing_checks}
	#	-exclude {checkpins} 
	#	-context verilog
	#	-input_port_nets -output_port_nets
	check_resource Finish_write_sdf
	
	# << Output SDF_KEY to announce SDF file is finished >>
	puts "* Information : SDF-file ${TOP}.${LOAD_MODEL}.${MODE}${NWORD}.sdf.gz was created."
	echo "SDF-File: ${TOP}.${LOAD_MODEL}.${MODE}${NWORD}.sdf.gz" > ./LOAD/SDF_KEY_${LOAD_MODEL}.${MODE}${NWORD}
	
	# << Annotated check >>
	puts "* Information : Now on annotated checking..."
	set maxnet 200000
	redirect ${REPORT_DIR}/rep.${MODE}_parasitics.log {
		report_annotated_parasitics -max_nets $maxnet -list_not_annotated
	}
	sh ./bin/report_annotated ${REPORT_DIR}/rep.${MODE}_parasitics.log > chk.${MODE}_check_net.list_wk
	sh sed -f ./bin/BACK.sed  chk.${MODE}_check_net.list_wk            > chk.${MODE}_check_net.list
	source -echo -verbose chk.${MODE}_check_net.list
	redirect ${REPORT_DIR}/chk.${MODE}_check_net.result { CHECK_DSPF_ERROR $TARGET_NET_LIST }

	report_design
	report_reference
	TOTAL_RUN_TIME
	redirect ./LOG/var_${MODE}${NWORD}_onexit${SUFFIX} { printvar }
	check_resource END

	if {![info exists DEBUG_JOB]} {exit}
}

# << Set Noise Error Threshold for Xtalk analisys >>
if {$ENABLE_XT == "true"} {
	puts "* Information : PrimeTime-SI mode."
	puts "* Information : start :update_noise."
	update_noise
}

#<< Make ML eco command without clock cells >>
if {$ENABLE_MK_CLK_LIST == "true"} {
	if {$CLOCK_MODE == "PROP"} {
		puts "* Information : start  : making clock cell listfile now..."
		MAKE_CLOCK_CELL_LISTFILE
		echo "KEY: WO_CLK_CELL.${STA_MODE} has been ready." > ./LOAD/KEY_WO_CLK_CELL.${STA_MODE}
		if {![info exists DEBUG_JOB]} {exit}
	} else {
		puts "* Information : cancel : making clock cells collection."
	}
}
###################################################################
# << save_session >>
###################################################################
if {$ENABLE_SS == "true"} {
	check_resource Before_save_session
	puts "* Information : Creating session data as ./LOAD/save.${LOAD_MODEL}.${MODE}${NWORD} now....."
	save_session ./LOAD/save.${LOAD_MODEL}.${MODE}${NWORD}

	# << Output SESSION_KEY to announce session data output is finished >>
	puts "* Information : Session-data save.${LOAD_MODEL}.${MODE}${NWORD} was created."
	echo "" > ./LOAD/SESSION_KEY_${LOAD_MODEL}.${MODE}${NWORD}
} else {
	puts "* Information : Canceled writing Session file."
}


###################################################################
# << Getting Timing Report >>
###################################################################
if {$CANCEL_REPORT_TIMING == "true"} {
	puts "* Information : No timing report has been gotten."
} else {
	puts "* Information : Timing report with '${LOAD_MODEL}'."
}


# << SETUP/HOLD Timing Report >> ----------------------------------------
# Normal Setup/HOLD (Not AOCVM)
if {$ENABLE_AOCVM == "false" && $ENABLE_SMVA == "false"&& $CANCEL_REPORT_TIMING == "false"} {
	#set NWORD        "${NWORD}_OCV"
	if {$REPORT_LESSER_THAN_ONLY == "true"} {
		redirect ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep {eval "report_timing ${REPORT_OPT_SLACK}"}
	} else {
		puts "* Information : parallel executing..."
		parallel_execute {
			{ eval "report_timing ${REPORT_OPT_SLACK}" } ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
			{ eval "report_timing ${REPORT_OPT}" }       ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.rep
		}
	}
	# CHECK_VARIABLES 2017/02/20
	COMP_VAR ./scr/VariableCheck/exp_variable_setuphold.${PROCESS}.list > ./LOG/var_comp.${MODE}.SETUPHOLD
	if {$ENABLE_REPORT_CLK_TMG == "true" && $DELAY == "HOLD"} {
		redirect ${REPORT_DIR}/clock.skew.${LOAD_MODEL}.${MODE}${NWORD}.rep       {report_clock_timing -hold -sig 3 -type skew}
		redirect ${REPORT_DIR}/clock.latency.${LOAD_MODEL}.${MODE}${NWORD}.rep    {report_clock_timing -hold -sig 3 -type latency}
		redirect ${REPORT_DIR}/clock.transition.${LOAD_MODEL}.${MODE}${NWORD}.rep {report_clock_timing -hold -sig 3 -type transition}
	}
}
# << End of SETUP/HOLD Timing Report >> ---------------------------------------
# << HOLD AOCVM Timing Report >> ----------------------------------------
# AOCVM HOLD
if {$DELAY == "HOLD" && $ENABLE_AOCVM == "true" && $CANCEL_REPORT_TIMING == "false"} {
	switch $AOCVM_MODE {
		PBA {
			puts "* Information : PBA mode."
			set AOCVM_SLACK  [expr ($NUM_SLACK  * 10.0) + 0.300]
			set AOCVM_MAX    [expr $NUM_MAX    * 1000]
			set AOCVM_NWORST [expr $NUM_NWORST * 3]

			#set PATH_GROUP [COL2LIST [get_attribute [get_timing_path -delay min -max 1 -nworst 1 -slack_less $AOCVM_SLACK] path_group]]
			set PATH_GROUP [COL2LIST [get_attribute [get_timing_path -group * -delay min -max 1 -nworst 1 -slack_less $AOCVM_SLACK] path_group]]

			set num 0
			set num_all [llength $PATH_GROUP]
			puts "* path groups are"
			foreach group $PATH_GROUP {
				incr num
				puts "* $num / $num_all : $group"
			}

			file delete ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
			redirect    ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep { puts "" }
			set num 0
			foreach group $PATH_GROUP {
				incr num
				puts "* $num / $num_all $group"
				check_resource $group
				puts " step1 : getting GBA_TP"
				set GBA_TP [get_timing_path -delay min -slack_lesser_than $AOCVM_SLACK -nworst $AOCVM_NWORST \
							-max_paths $AOCVM_MAX -path full_clock_expanded -uniq -group $group]

				puts " step2 : getting PBA_TP"
				set PBA_TP [get_timing_path -pba_mode path $GBA_TP]

				puts " step3 : report_timing"
				redirect -append ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep {
					report_timing [filter_collection $PBA_TP "slack < $NUM_SLACK"] -nets -nosplit -input \
							-path full_clock_expanded -derate -significant_digits 3 -trans -cap
				}
				# unset variables. PT cannot save these user defined collections to session data.
				unset GBA_TP PBA_TP
			}
		}
		GBA {
			puts "* Information : GBA mode."
			if {$REPORT_LESSER_THAN_ONLY == "true"} {
				redirect ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep {eval "report_timing -pba_mode exhaustive ${REPORT_OPT_SLACK}"}
			} else {
				puts "* Information : parallel executing..."
				parallel_execute {
					{ eval "report_timing -pba_mode exhaustive ${REPORT_OPT_SLACK}" } ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
					{ eval "report_timing -pba_mode exhaustive ${REPORT_OPT}" }       ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.rep
				}
			}
		}
		default {
			if {$REPORT_LESSER_THAN_ONLY == "true"} {
				redirect ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep {eval "report_timing ${REPORT_OPT_SLACK}"}
			} else {
				puts "* Information : parallel executing..."
				parallel_execute {
					{ eval "report_timing ${REPORT_OPT_SLACK}" } ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
					{ eval "report_timing ${REPORT_OPT}" }       ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.rep
				}
			}
		}
	}
	# CHECK_VARIABLES 2017/02/20
	COMP_VAR ./scr/VariableCheck/exp_variable_aocvm.${PROCESS}.list > ./LOG/var_comp.${MODE}.AOCVM
}
# << End of HOLD AOCVM Timing Report >> ----------------------------------------


###################################################################
# << Report Constraints >>
###################################################################

puts "* Information : Constraint report with '${LOAD_MODEL}'."
if {$CANCEL_CONST_REPORT == "true"} {
	puts "* Information : Cancel report_constraint"
} else {
	puts "* Information : getting constraint_report now.."
	parallel_execute {
		{report_min_pulse_width -path_type summary -nosplit} 
			${REPORT_DIR}/const.min_pulse_${LOAD_MODEL}.${MODE}${NWORD}.endpsum

		{report_min_pulse_width -all_violators -nosplit -derate -sig 3 -input -path_type full_clock_expanded} \
			${REPORT_DIR}/const.min_pulse_${LOAD_MODEL}.${MODE}${NWORD}_${MIN_PULSE_THRESHOLD}.rep

                {report_min_pulse_width -all_violators -nosplit -derate -sig 3 -input} \
			${REPORT_DIR}/const.min_pulse_${LOAD_MODEL}.${MODE}${NWORD}_${MIN_PULSE_THRESHOLD}.summary

                {report_constraint -all_violators -min_period -verbose -nosplit} \
			${REPORT_DIR}/const.min_period_${LOAD_MODEL}.${MODE}${NWORD}.rep

                {report_constraint      -all_violators -nosplit -significant_digits 3 -path_type slack_only -verbose \
			-max_capacitance -min_capacitance -min_pulse_width -min_period} \
			${REPORT_DIR}/const.${LOAD_MODEL}.${MODE}${NWORD}.rep

		{report_constraint -all_violators -max_fanout -nosplit } \
			${REPORT_DIR}/rep.${MODE}_max_fanout 

		{CALC_STD_AREA} \
			${REPORT_DIR}/rep.${MODE}_CALC_STD_AREA
	}
	# CHECK_VARIABLES 2017/02/20
	COMP_VAR ./scr/VariableCheck/exp_variable_setuphold.${PROCESS}.list > ./LOG/var_comp.${MODE}.minpulse

	puts "* Information : Minpulse report with margin ${MIN_PULSE_MARGIN}."
	redirect ${REPORT_DIR}/const.min_pulse_margin_${MIN_PULSE_MARGIN}_${LOAD_MODEL}.${MODE}${NWORD}.rep {
		GET_MINPULSE_MARGIN ${REPORT_DIR}/const.min_pulse_${LOAD_MODEL}.${MODE}${NWORD}.endpsum $MIN_PULSE_MARGIN 
	}
	sh rm ${REPORT_DIR}/const.min_pulse_${LOAD_MODEL}.${MODE}${NWORD}.endpsum
			
}

# << Report Transition and Capacitance >>
if {$CANCEL_TRANnCAP_REPORT == "true"} {
	puts "* Information : Canceled Transition/Capacitance report."
} else {
	# << ENABLE_TRAN_ML >>
	if {$ENABLE_TRAN_ML == "true"} {
		puts "* Information : Making 'ML' netlist..."
		set MODE "${MODE}_ML"
		#<< Applying 'size_cell' command >>
		redirect ./LOG/MLvth_${MODE}.log  {
			puts "* Information : Applying size_cell command to change HtoM."
			source ./LOAD/TO_MVTH.tcl
			puts "* Information : Applying size_cell command to change H/MtoL without WaitArea."
			source ./LOAD/TO_LVTH.tcl
		}
	} else {
		puts "* Information : Not 'ML' netlist."
	}
	set REP_TRANnCAP "${LOAD_MODEL}.${MODE}${NWORD}"


	#<< Transition Reports >>-----------------------------------------
	#(1) Library base report
     if {$SKIP_TRAN_LIB == "false"} {
	puts "* Information : Tran(1) Library base report"
        redirect ${REPORT_DIR}/maxtran_lib_${REP_TRANnCAP}.rep.org {
	   report_constraints -max_transition -all_violators -nosplit -significant_digits 3
        }

	# change format PrimeTime report -> summary
	modify_maxtran_rep \
		-input_file  ${REPORT_DIR}/maxtran_lib_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_lib_${REP_TRANnCAP}.rep
        sh gzip -9f ${REPORT_DIR}/maxtran_lib_${REP_TRANnCAP}.rep.org
     }
     if {$SKIP_TRAN_FREQ == "false"} {

	#(2) Frequency base report  (E1L24: report_const_maxtran.rpt_all)
	puts "* Information : Tran(2) Frequency base report"
	source ./scr/set_maxtran_freq.tcl	;# RV40F/RV28F frequency transition, MF3 constant maxtran
	set_maxtran_per_freq_CORE $core_clk $Tfactor $Cfactor $MAXTRANCAP_FREQ_RELAX $PROCESS
        redirect ${REPORT_DIR}/maxtran_freq_${REP_TRANnCAP}.rep.org {
	   report_constraints -max_transition -all_violators -nosplit -significant_digits 3
        }
	puts "* Information : Tran(2) High Voltage Frequency base report"
	if {[string match "RV40F" $PROCESS] || [string match "RV28F" $PROCESS] } {
	   relax_max_tran_hv \
		-relax_voltage {3.0 4.5} -freq_margin $MAXTRANCAP_FREQ_RELAX -data_tran 4.8 -clock_tran 2.4 \
		-input_file ${REPORT_DIR}/maxtran_freq_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_freq_${REP_TRANnCAP}.rep
           sh gzip -9f ${REPORT_DIR}/maxtran_freq_${REP_TRANnCAP}.rep.org
	} elseif { [string match "MF3" $PROCESS] } {
	   modify_maxtran_rep \
		-input_file  ${REPORT_DIR}/maxtran_freq_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_freq_${REP_TRANnCAP}.rep
	}

     }
     if {$SKIP_TRAN_CLKPIN == "false"} {
	#(3) set register's clock pin (E1L24: report_const_maxtran_${REP_TRANnCAP}_hvt.rpt_mod)
	puts "* Information : Tran(3) register's clock pin"
	source ./scr/set_maxtran_clkpin.tcl
        redirect ${REPORT_DIR}/maxtran_clkpin_${REP_TRANnCAP}.rep.org {
	   report_constraint -all_violators -max_transition -nosplit -significant_digits 3
        }
	modify_maxtran_rep \
		-input_file  ${REPORT_DIR}/maxtran_clkpin_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_clkpin_${REP_TRANnCAP}.rep
        sh gzip -9f ${REPORT_DIR}/maxtran_clkpin_${REP_TRANnCAP}.rep.org

     }
     if {$SKIP_TRAN_LOWDRV == "false"} {
	#(4) set lowdrive output pin Under/Over 160MHz
	if {[string match "RV40F" $PROCESS] } {
		puts "* Information : Tran(4) set lowdrive output pin for RV40F"
		source ./scr/DLC_proc_RV40F.tcl		;# From DelayCalc team(get_min_period.tcl, get_half_cycle_path_v2.tcl, dlclt_maxtran_lowdrv_proc.scr)
		source ./scr/set_maxtran_lowdrv_RV40F.tcl	;# Apply constraints
	} elseif { [string match "RV28F" $PROCESS] } {
		source ./scr/DLC_proc_RV28F.tcl		;# From DelayCalc team(get_min_period.tcl, get_half_cycle_path_v2.tcl, dlclt_maxtran_lowdrv_proc.scr)
		source ./scr/set_maxtran_lowdrv_RV28F.tcl	;# Apply constraints
	}
        redirect ${REPORT_DIR}/maxtran_lowdrv_${REP_TRANnCAP}.rep.org {
	   report_constraint -all_violators -max_transition -nosplit -significant_digits 3
        }
	modify_maxtran_rep \
		-input_file  ${REPORT_DIR}/maxtran_lowdrv_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_lowdrv_${REP_TRANnCAP}.rep

        sh gzip -9f ${REPORT_DIR}/maxtran_lowdrv_${REP_TRANnCAP}.rep.org

     }
     if {$SKIP_TRAN_HALFCYCLE == "false"} {
	#(5) half cycle path
        set         BACKUP_TIMING_REPORT_UNCONSTRAINED_PATHS      $timing_report_unconstrained_paths
        set_app_var timing_report_unconstrained_paths             false
	puts "* Information : Tran(5) half cycle path"
	source ./scr/set_maxtran_half_cycle.tcl
	set_maxtran_half_cycle -freq_margin $MAXTRANCAP_FREQ_RELAX
        set_app_var timing_report_unconstrained_paths $BACKUP_TIMING_REPORT_UNCONSTRAINED_PATHS
        redirect ${REPORT_DIR}/maxtran_halfcycle_${REP_TRANnCAP}.rep.org {
	   report_constraint -all_violators -max_transition -nosplit -significant_digits 3
        }
	modify_maxtran_rep \
		-input_file  ${REPORT_DIR}/maxtran_halfcycle_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_halfcycle_${REP_TRANnCAP}.rep

        # if many violation in the report, -> manual filter or option
	puts "* Information : Finished All Transition reports."
        sh gzip -9f ${REPORT_DIR}/maxtran_halfcycle_${REP_TRANnCAP}.rep.org

     }
     if {$SKIP_TRAN_ASYNC == "false"} {
	#(6) async pin transition
	puts "* Information : Tran(6) Async Pins Transtion"
	if {[info exist PTECO_FIX_DRC]} {
		puts "* Information: Skip Reset maxtran constraints"
		set OVERWRITE_MAXTRAN 0
	} else {
		puts "* Information: Reset maxtran constraints"
		set_max_transition 99999.999 [get_pins * -hier]
		set_max_transition 99999.999 [get_clocks *] -clock_path -rise -fall
		set_max_transition 99999.999 [get_clocks *] -data_path  -rise -fall
		set OVERWRITE_MAXTRAN 1
	}

	SET_ASYNC_TRAN $MAXTRAN_ASYNC_CONST $OVERWRITE_MAXTRAN	;# Overwrite Maxtran

        redirect ${REPORT_DIR}/maxtran_async_${REP_TRANnCAP}.rep.org {
	   report_constraint -all_violators -max_transition -nosplit -significant_digits 3
        }
	modify_maxtran_rep \
		-input_file  ${REPORT_DIR}/maxtran_async_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxtran_async_${REP_TRANnCAP}.rep
	sh gzip -9f ${REPORT_DIR}/maxtran_async_${REP_TRANnCAP}.rep.org

     }
	#<< Capacitance Reports >>-----------------------------------------
	#(1) Library base report
     if {$SKIP_CAP_LIB == "false"} {
	puts "* Information : Cap(1) Library base report"
        redirect ${REPORT_DIR}/maxcap_lib_${REP_TRANnCAP}.rep.org {
	    report_constraints -max_capacitance -all_violators -nosplit -significant_digits 3
        }

	# check for Hard Macro
	modify_maxcap_rep \
		-input_file  ${REPORT_DIR}/maxcap_lib_${REP_TRANnCAP}.rep.org \
		-output_file ${REPORT_DIR}/maxcap_lib_${REP_TRANnCAP}.rep
        sh gzip -9f ${REPORT_DIR}/maxcap_lib_${REP_TRANnCAP}.rep.org

	#(2) Frequency base report (E1L24: report_const_maxcap_${REP_TRANnCAP}.rpt_all)
     }
     if {$SKIP_CAP_FREQ == "false"} {
	puts "* Information : Cap(2) Frequency base report"
	puts "* Information : Reset maxcap constraints"
	set_max_capacitance $MAXCAP_DEFAULT [get_pins [get_pins -hier *] -filter "full_name!~*/Logic?/output&&full_name!~Logic?/output"]
	source ./scr/set_maxcap_freq.tcl
	set_maxcap_per_freq_CORE $core_clk $Tfactor $Cfactor $MAXTRANCAP_FREQ_RELAX $PROCESS
	source ./scr/add_maxcap_of_hv.tcl
        redirect ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep.org {
	   report_constraints -max_capacitance -all_violators -nosplit -significant_digits 3
        }
	if {[string match "RV40F" $PROCESS] } {
		puts "* Information : set hv maxcap for RV40F"
		relax_max_cap_hv \
			-freq_margin $MAXTRANCAP_FREQ_RELAX \
			-data_cap_3V 2.18 -clock_cap_3V 1.09 \
			-data_cap_5V 1.44 -clock_cap_5V 0.72 \
			-input_file ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep.org \
			-output_file ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep
	} elseif { [string match "RV28F" $PROCESS] } {
		puts "* Information : set hv maxcap for RV28F"
		relax_max_cap_hv \
			-freq_margin $MAXTRANCAP_FREQ_RELAX \
			-data_cap_3V 1.194 -clock_cap_3V 0.597 \
			-data_cap_5V 0.788 -clock_cap_5V 0.394 \
			-input_file ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep.org \
			-output_file ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep
	} elseif { [string match "MF3" $PROCESS] } {
		puts "* Information : MF3 doesn't need HV relaxation due to same MaxCap constraints to core voltage cell"
		modify_maxcap_rep \
			-input_file  ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep.org \
			-output_file ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep
	}
	
        sh gzip -9f ${REPORT_DIR}/maxcap_freq_${REP_TRANnCAP}.rep.org

     }
}

###################################################################
# << Summarize Timing Report >>
###################################################################
if {$ENABLE_REPORT_SUMMARY == "true" && $CANCEL_REPORT_TIMING == "false"} {
	if {$DELAY == "HOLD"} {
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
	        sh ./bin/go.mk_pathrep4_2  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
		if { $CLOCK_MODE == "PROP" } {
	        	sh ./bin/mkHOLD_path.tcl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path_sum
		}
	}
	if {$DELAY == "SETUP"} {
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
		mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
		mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
		if {$REPORT_LESSER_THAN_ONLY == "true"} {
			mkFreq_sum  ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.rep > ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.sum
		}
		mkMod_sum   ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path_sum
	}
} else {
	puts "* Information : Cancel make timing summary report."
}

###################################################################
# Timing Report : Xtalk Noise/double_switching/check_noise
###################################################################
if {$ENABLE_XT =="true" && $ENABLE_XT_NOISE_REPORT == "true"} {
	puts "* Information : PrimeTime-SI mode."
	puts "* Information : Getting Noise reports."
	redirect ${REPORT_DIR}/noise_low.${LOAD_MODEL}.${MODE}${NWORD}.rep {
		report_noise -nosplit -significant_digits 3 -all_violators -above -low  -slack_type height -nworst_pins 10000
	}
	redirect ${REPORT_DIR}/noise_high.${LOAD_MODEL}.${MODE}${NWORD}.rep {
		report_noise -nosplit -significant_digits 3 -all_violators -below -high -slack_type height -nworst_pins 10000
	}
	puts "* Information : Getting double_switching report."
	redirect ${REPORT_DIR}/double_switching.${LOAD_MODEL}.${MODE}${NWORD}.rep {
		report_si_double_switching -nosplit -clock_network -rise -fall
	}
	report_noise_parameters
	check_noise -include { noise_driver noise_immunity }
	puts "* Information : Getting check_noise result."
	redirect ${REPORT_DIR}/check_noise.${LOAD_MODEL}.${MODE}${NWORD}.rep {
		check_noise -include { noise_driver noise_immunity } -verbose -nosplit
	}
	# CHECK_VARIABLES 2017/02/20
	COMP_VAR ./scr/VariableCheck/exp_variable_xtalk.${PROCESS}.list > ./LOG/var_comp.${MODE}.XTALK
}

###################################################################
# Timing Report : For Lower VTH changed (Estimation Purpose)
###################################################################
if {$ENABLE_ML == "true"} {
	puts "* Information : MLvth Timing report with '${LOAD_MODEL}'."

	# << save_session Before Vth change >>
	if {$ENABLE_SS == "true"} {
		puts "* Information : Creating session data as ./LOAD/save.${LOAD_MODEL}.${MODE} now....."
		save_session ./LOAD/save.${LOAD_MODEL}.${MODE}${NWORD}
	} else {
		puts "* Information : Canceled writing SDC file."
	}

	set NWORD "${NWORD}_ML"
	#<< Applying 'size_cell' command >>
	redirect ./LOG/MLvth_${MODE}.log  {
		if {$CLOCK_MODE == "PROP"} {
			WAIT_KEY ./LOAD/KEY_TO_CHG_VTH_WO_CLK
			puts "* Information : Applying size_cell command to change HtoM without clock cells."
			source ./LOAD/TO_MVTH_WO_CLK.tcl
			puts "* Information : Applying size_cell command to change H/MtoL without WaitArea without clock cells."
			source ./LOAD/TO_LVTH_WO_CLK.tcl
		} else {
			puts "* Information : Applying size_cell command to change HtoM."
			source ./LOAD/TO_MVTH.tcl
			puts "* Information : Applying size_cell command to change H/MtoL without WaitArea."
			source ./LOAD/TO_LVTH.tcl
		}
	}
	#<< Getting ML Timing Report >>
	if {$CANCEL_ML_TIMING_REPORT == "true"} {
		puts "* Information : No timing report has been gotten."
	} else {
		puts "* Information : parallel executing..."
		parallel_execute {
			{ eval "report_timing ${REPORT_OPT_SLACK}" } ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
			{ eval "report_timing ${REPORT_OPT}" }       ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.rep
		}
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
		mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
		mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
		mkFreq_sum  ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.rep        > ${REPORT_DIR}/timing.${LOAD_MODEL}.${MODE}${NWORD}.sum
		mkMod_sum   ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path_sum
	}
} else {
	puts "* Information : No timing report has been gotten."
}

###################################################################
# << Executing User PT script >>
###################################################################
if {[info exists EXT] && [info exists MOD_NAME]} {
	check_resource Before_execute_user_script
	puts "* Information : Executing the additional script ${EXT}."
	redirect ${REPORT_AC_DIR}/log.${MOD_NAME}_${MODE} {
		source -echo -verbose ${EXT}
	}
        if {$LOAD_MODEL == "SPEF" && $ENABLE_ANNOTATED_CHECK == "true"} {
		puts "* Information : Now on annotated checking..."
		set maxnet 1500000
		redirect ${REPORT_DIR}/rep.${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}_pin2pin_parasitics.log {
	        	report_annotated_parasitics -max_nets $maxnet -list_not_annotated -pin_to_pin_nets
		}
		sh tail -25 ${REPORT_DIR}/rep.${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}_pin2pin_parasitics.log > ${REPORT_DIR}/rep.not_annotated_${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}_parasitics.log
        	sh bin/annotated_check.pl \
	  	${REPORT_DIR}/rep.${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}_pin2pin_parasitics.log \
	  	./tmp.anno.${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}.tcl \
	  	${REPORT_DIR}/rep.not_annotated_${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}_parasitics.log

	        source ./tmp.anno.${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}.tcl
        	sh rm ./tmp.anno.${LOAD_MODEL}.${MOD_NAME}_${MODE}${NWORD}.tcl
	}
	COMP_VAR ./scr/VariableCheck/exp_variable_setuphold.${PROCESS}.list > ./LOG/var_comp.KOBETSU_${MOD_NAME}_${MODE}
	check_resource After_execute_user_script
        puts "* Information: KOBETSU setting may change timing constraints so exit."
        exit
}

###################################################################
# Accuracy check
###################################################################
# << Get no-clock information >>
if {$ENABLE_REPORT_NOCLK == "true"} {
	# << CHECK NO-CLOCK >>
	puts "* Information : Getting no-clock information."
	set REP_CT_NOCLK "${REPORT_DIR}/check_timing_no_clock.${MODE}"
	set REP_CT_UNTST "${REPORT_DIR}/check_timing_unconst_endpoint.${MODE}"
	set REP_CT_LEVEL "${REPORT_DIR}/check_timing_level_check.${MODE}"
	set REP_RC_UNTST "${REPORT_DIR}/coverage.${MODE}"
	set REP_CLKVT    "${REPORT_DIR}/check_vt_clockline.${MODE}"
	set REP_REACHCLK "${REPORT_DIR}/check_reach_clock.${MODE}"
	set REP_HIGHFREQ_DONT_USE "${REPORT_DIR}/check_highfreq_dontuse.${MODE}"

	puts "* Information : parallel executing..."
	parallel_execute {
		{ CHK_HIGHFREQ_DONTUSE ${REP_HIGHFREQ_DONT_USE} 		${HIGHFREQ_DONT_USE_PERIOD}	}  /dev/null
		{ check_timing -verbose -over no_clock }			${REP_CT_NOCLK}
		{ check_timing -verbose -over unconstrained_endpoint }		${REP_CT_UNTST}
		{ report_analysis_coverage -status_details untested -nosplit }	${REP_RC_UNTST}
		{ check_timing -verbose -over signal_level }			${REP_CT_LEVEL}
	}
	sh ./bin/no_clock/chk_clkpins.csh ${REP_CT_NOCLK} ${REP_RC_UNTST}

        if {![file exists $FILE_CLKVT_CFG]} {
	        puts "Error(CHK_CLKVT) : $FILE_CLKVT_CFG is not found..."
        } else {
	        puts "* Information : Getting clock Vth..."
                CHK_CLKVT          $FILE_CLKVT_CFG     $REP_CLKVT
	        puts "* Information : done..."
        }
        if {[file exists $FILE_REACHCLK_PIN]} {
	         puts "* Information : Getting reach clock name ..."
                 CHK_REACHE_CLK  $FILE_REACHCLK_PIN $REP_REACHCLK
	         puts "* Information : done ..."
        }

} else {
	puts "* Information : Canceled no-clock checking."
}

if {$ENABLE_GCLKPATH == "true"} {
	set REP_CHK_GCLKPATH	"${REPORT_DIR}/check_GCLKPATH.${MODE}"
	redirect ${REP_CHK_GCLKPATH} {
		chkGCLKPathAll
	}
} else {
	puts "* Information : Canceled GCLKPATH checking."
}

# << CHECK LOOPS>>
if {$ENABLE_REPORT_LOOPS == "true"} {
	redirect ${REPORT_DIR}/rep.loops.${MODE} {check_timing -verbose -override_defaults {loops}}

} else {
	puts "* Information : Canceled no-clock checking."
}

# << Check Exceptions >>
if {$ENABLE_REPORT_EXCEPTIONS == "true"} {
	puts "* Information : Getting report_excecptions"
	redirect ${REPORT_DIR}/rep.ignored_exceptions.${MODE} {report_exceptions -ignored -nosplit}
} else {
	puts "* Information : Canceled report_excecptions"
}

# << Check clock_crossing >>
if {$ENABLE_CLK_CROSSING == "true"} {
	redirect ${REPORT_DIR}/${MODE}_clock_paths {check_timing -verbose -override_default {clock_crossing}}
} else {
	puts "* Information : Canceled clock_crossing check."
}

# << Make clock latency hisgtram >>
if {$ENABLE_LATENCY_HISTGRAM == "true"} {
    puts "* Information : Getting clock latency histgram."
    source ./scr/get_clock_latency_histgram.tcl
    if {$STA_MODE == "SYSTEM"} {
        set FILE_CLOCK_LIST ./apply/ALL/${STA_MODE}_latency_hisgram_target.list
    } elseif {$STA_MODE == "DFT"} {
        set FILE_CLOCK_LIST ./apply/ALL/${DFT_MODE}_latency_hisgram_target.list
    }
    if {[file exist $FILE_CLOCK_LIST]} {
        puts "* Information : Target clock list was found."
        set CLOCK_LIST ""
        set f [open $FILE_CLOCK_LIST r]
        while {[gets $f line] > 0} {
            lappend CLOCK_LIST $line
        }
        close $f
    } else {
        set CLOCK_LIST [COL2LIST [sort_collection [get_clocks -filter "defined(sources)"] -dictionary {full_name}]]
    }
    get_clock_latency_histgram $CLOCK_LIST $LATENCY_HISTGRAM_MIN $LATENCY_HISTGRAM_STEP $LATENCY_HISTGRAM_MAX
} else {
    puts "* Information : Canceled get clock latency histgram."
}

###################################################################
# << Analizing Xtalk Delta Delay >>
###################################################################
if {$ENABLE_XT == "true" && $ENABLE_XT_DD_ANALYSIS == "true"} {
	if {$DELAY == "SETUP"} {
		puts "* Information : Analizing Xtalk Delta Delay."
        	source ./bin/WRITE_DELTA_DELAY_MAX.tcl
        	#WRITE_DELTA_DELAY_MAX ${REPORT_DIR}/DELTA_DELAY_MAX_${MODE}.rep
        	#sh ./bin/calc_delta_delay.tcl ${REPORT_DIR}/DELTA_DELAY_MAX_${MODE}.rep.gz > ${REPORT_DIR}/result.DELTA_DELAY_MAX_${MODE}.rep
        	REPORT_XT_DD_RATIO    ${REPORT_DIR}/DELTA_DELAY_RATIO_${MODE}.rep

		# DELTA information -> get sample reports(Not All)
		DELTA_RATIO2REP       ${REPORT_DIR}/DELTA_DELAY_RATIO_${MODE}.rep.gz ${REPORT_DIR}/path.DELTA_RATIO_${MODE}.rep $XT_DD_MAX_RATIO $DELTA_PATH_LIMIT
		DELTA_MAXDELTA2REP    ${REPORT_DIR}/DELTA_DELAY_RATIO_${MODE}.rep.gz ${REPORT_DIR}/path.DELTA_MAX_${MODE}.rep   $XT_DD_MAX_DELTA $DELTA_PATH_LIMIT
	} else {
        	source ./bin/WRITE_DELTA_DELAY_MAX.tcl
		REPORT_XT_DD_MIN      ${REPORT_DIR}/DELTA_DELAY_MIN_${MODE}.rep ${XT_DD_MIN_DELTA} ${XT_DD_MIN_SLACK}

		# DELTA information -> get sample reports(Not All)
		DELTA_MINDELTA2REP    ${REPORT_DIR}/DELTA_DELAY_MIN_${MODE}.rep.gz ${REPORT_DIR}/path.DELTA_MIN_${MODE}.rep     $XT_DD_MIN_DELTA $DELTA_PATH_LIMIT
	}
        #sh sort +2 -n -r ${REPORT_DIR}/DELTA_DELAY_MAX_${MODE}.rep              > ${REPORT_DIR}/rep.big_delta_delay_${MODE}
        #sh gzip -9       ${REPORT_DIR}/DELTA_DTRAN_RATIOELAY_MAX_${MODE}.rep
} else {
	puts "* Information : Canceled analizing Xtalk Delta Delay."
}



###################################################################
# << Get Skewed report >>
###################################################################
if { $ENABLE_SKEWED == "true" } {
     if {$DELAY=="SETUP"} {
	set SKEWED_DELAY max
     } else {
	set SKEWED_DELAY min
     }
     puts "* Information : skewed report delay:$SKEWED_DELAY TRAN_RATIO:$SKEWED_TRAN_RATIO OFFSET:$SKEWED_TRAN_OFFSET"
     CHK_SKEWED_MARGIN ${REPORT_DIR}/skewed.${MODE}.rep ${SKEWED_DELAY} ${SKEWED_TRAN_RATIO} ${SKEWED_TRAN_OFFSET}
     SKEWED_REP2PATH ${REPORT_DIR}/skewed.${MODE}.rep ${REPORT_DIR}/skewed_path.${MODE}.rep ${SKEWED_DELAY} $SKEWED_PATH_LIMIT
}

###################################################################
# << Get BigSkew report >>
###################################################################
if { $ENABLE_BIGSKEW == "true" } {
     source ./scr/GET_BIG_SKEW_REPORT.tcl ;# after GET_BIG_SKEW_REPORT.v1r3.tcl
     puts "* Information : big skew parameters are LIMIT_SKEW: ${BSKEW_LIMIT_SKEW} SLACK_MARGIN: ${BSKEW_SLACK_MARGIN}"
     puts "* Information :                         NWORST: ${BSKEW_NWORST} DIR: ${BSKEW_REPDIR}"
     GET_BIG_SKEW_REPORT ${BSKEW_LIMIT_SKEW} ${BSKEW_SLACK_MARGIN} ${BSKEW_NWORST} ${BSKEW_REPDIR}
}

###################################################################
# << Get AC Setup/Hold report >>
###################################################################
if {$ENABLE_AOCVM == "false" && $ENABLE_XT == "false" && $CANCEL_AC_REPORT == "false"} {
        if {$CANCEL_CONST_AC == "true"} {
                puts "* Information : No Input/Output report has been applied."
        } else {
                puts "* Information : Getting Input/Output report."
                if {$STA_MODE == "DFT"} {
                    source -echo $FILE_DFT_REP_AC
                } elseif {$STA_MODE=="SYSTEM"} {
                    source -echo $FILE_SYS_REP_AC
                }
        }
}

###################################################################
# << Writing SDC >>
###################################################################
if {$ENABLE_WRITE_SDC == "true"} {
	set tcl_precision 6 ;# apply on 20/08/25 by A.Yoshida
	set sdc_write_unambiguous_names false
        puts "* Information: Delete resistance between IO BUF and PAD"
        set_resistance 0 [get_nets -of [get_port * -filter "direction == out || direction == inout" ]]
	puts "* Information : Writing SDC file."
	#transform_exceptions
	update_timing -full
        source scr/WRITE_SDC.tcl
        WRITE_SDC ${REPORT_DIR}/${MODE}_${CLOCK_MODE}.sdc ${SDC_VERSION} MCU
        puts "* Information: WRITE_SDC changes timing constraints so exit."
        exit
} else {
	puts "* Information : Canceled writing SDC file."
}


###################################################################
# << Create Xtalk Delay Timing Report without pessimistic >>
###################################################################
if {$ENABLE_XT == "true" && $ENABLE_XT_PESSIMISTIC == "true"} {
	puts "* Information : MCU and CIS don't use Xtalk PESSIMISTIC result."
	puts "* Information : Analizing aggressors."
	set BASE_FILE_NAME "${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}"
	GET_LIST_NET   ${BASE_FILE_NAME}.rep      ${BASE_FILE_NAME}.list_net
	GET_AGGRESSORS ${BASE_FILE_NAME}.list_net ${BASE_FILE_NAME}.list_agg
	if {[info exists BUS_CONSIDER]} {
		puts "* Information : Pessimism reduction with Bus consider."
		sh ./bin/go_Xtalk_pessimisim_reduction.TAT ${BASE_FILE_NAME}.rep ${BASE_FILE_NAME}.list_agg "BUS_CONSIDER"
	} else {
		puts "* Information : Pessimism reduction without Bus consider."
		sh ./bin/go_Xtalk_pessimisim_reduction.TAT ${BASE_FILE_NAME}.rep ${BASE_FILE_NAME}.list_agg
	}
}

###################################################################
# << Output timing information >>
###################################################################
if {$ENABLE_SAVE_PIN == "true"} {
    puts "* Information : Generating save_pin information for Timing-ECO work."
    check_resource Output_TimingInfo_START
    set PIN_ALL [get_pins -h *]
    DIR_CHECK Info_Critical_Pins
    set critical_pins [GET_CRITICAL_PINS $PIN_ALL $DELAY ${PIN_SLACK} "./Info_Critical_Pins/pin.${LOAD_MODEL}.${MODE}${NWORD}"]
    if {$DELAY == "SETUP"} {
        set PIN_ALL_INPUTS [get_pins $PIN_ALL -filter "direction==in"]
        GET_CRITICAL_DETAIL_PINS $PIN_ALL_INPUTS ./Info_Critical_Pins/${MODE}.slacklist SETUP $CRITICAL_SETUP_SLACK
        GET_BIGDELAY_NET         $PIN_ALL_INPUTS ./Info_Critical_Pins/${MODE}.bigdelayinputs.list $BIGDELAY_NET_DELAY $BIGDELAY_SETUP_SLACK
        GET_CLOCK_CELLS          Info_Critical_Pins/${MODE}.clocklist
    } elseif {$DELAY == "HOLD"} {
        set PIN_ALL_INPUTS [get_pins $PIN_ALL -filter "direction==in"]
        GET_CRITICAL_DETAIL_PINS $PIN_ALL_INPUTS ./Info_Critical_Pins/${MODE}.slacklist HOLD $CRITICAL_HOLD_SLACK
    }
    check_resource Output_TimingInfo_END
} else {
    puts "* Information : Cancel save_pin"
}

###################################################################
# << Output SDF for Simulation >>
###################################################################
if {$ENABLE_WRITE_SIMSDF == "true"} {
    puts "* Information: Delete resistance between IO BUF and PAD"
    set_resistance 0 [get_nets -of [get_port * -filter "direction == out || direction == inout" ]]

    puts "* Information : Generating SDF for Simulation."
    check_resource Ganerating_SDF_START

    #reset OCV
    reset_timing_derate

    ## For flash simulation, flash pins delay is changed to 0.
    if {[info exists SIMSDF_ANNO_ZERO_FILE]} {
        if {[file exists $SIMSDF_ANNO_ZERO_FILE]} {
            ERROR_FILE SIMSDF_ANNO_ZERO_FILE
        }
        puts "* Warning : changed delay partically 0 for Write Simulation SDF"
        source -echo -verbose $SIMSDF_ANNO_ZERO_FILE
    } else {
        puts "* Warning : Not changed delay, Flash may need changing annotation."
    }

    set_app_var timing_reduce_parallel_cell_arcs false
    update_timing -full
    write_sdf -version 3.0 \
              -include { SETUPHOLD RECREM } \
              -no_edge \
              -no_edge_merging { timing_checks cell_delays } \
              -significant_digits 4 \
              -no_internal_pins -context verilog \
              -compress gzip \
              ./LOAD/${TOP}.${MODE}.SIM.sdf.gz

    check_resource Ganerating_SDF_END
    puts "* Information: Derating values were overwritten for write_sdf. This session cannot continue to get timing report."
    print_message_info
    exit
} else {
    puts "* Information : Cancel WRITE_SIMSDF"
}

## Delta SDF
if {$ENABLE_XT == "true" && $ENABLE_WRITE_DD_SDF == "true"} {
	puts "* Information : WRITE_Delta SDF"
	write_sdf  -compress gzip -significant_digits 6 \
		-delta_net_delays_only ./LOAD/${TOP}.${MODE}.dsdf.gz
} elseif {$ENABLE_XT == "true"} {
	puts "* Information : Cancel WRITE_Delta SDF"
}


###################################################################
# << Output total run time.>>
###################################################################
TOTAL_RUN_TIME
redirect ./LOG/var_${LOAD_MODEL}.${MODE}${NWORD}_onexit${SUFFIX} { printvar }
check_resource END
print_message_info
if {[info exists DEBUG_JOB]} {
	puts "* Information : Output KEY file."
	if {[info exists LABEL]} {
		puts "                './LOAD/KEY_${LABEL}_${LOAD_MODEL}.${MODE}${NWORD}'"
		echo "KEY: ${TOP}_${LABEL}_${LOAD_MODEL}.${MODE}${NWORD} has been ready." > ./LOAD/KEY_${LABEL}_${LOAD_MODEL}.${MODE}${NWORD}
	} else {
		puts "                './LOAD/KEY_${LOAD_MODEL}.${MODE}${NWORD}'"
		echo "KEY: ${TOP}_${LOAD_MODEL}.${MODE}${NWORD} has been ready."          > ./LOAD/KEY_${LOAD_MODEL}.${MODE}${NWORD}
	}
} elseif {![info exists PTECO_FIX_DRC]} {
	puts "Information: Exit PrimeTime by batch job"
	exit
}

###################################################################
# END
###################################################################
