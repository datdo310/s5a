##############################################
# PrimeTime ECO Main script for MCU product
# 
# Name     : pteco_main.mcu.tcl
# Version  : v0r0  2014/02/03   Y.Oda
#          : v0r1  2014/03/26   Y.Oda
#          : v0r5  2014/04/25   Y.Oda
#          : v0r6  2014/06/11   Y.Oda
#          : v0r7  2014/11/12   Y.Oda(FB from FCC2)
#          : v0r8  2015/03/11   Y.Oda
#          : v0r9  2015/10/30   Y.Oda
#          : v0r10 2015/12/03   add MAXTRANCAP_FREQ_RELAX
#          : v0r11 2016/02/24   support Ideal mode
#          : v0r12 2016/06/13   PTECO_SIZE_VTH_ONLY -> PTECO_SIZE/PTECO_SIZE_VTH
#          : v0r14 2016/07/25   support PT2014.12/reject PT2015.12
#          : v0r15 2016/08/24   add "exit" for batch jobs/report_timing -in -> -input
#          : v0r16 2017/01/24   Add "start_host -min_host 2;" for using EWS effective
#          : v0r17 2017/04/11   support PT2015.12
#          : v0r18 2017/06/26   Add ENABLE_HF_ZERO
#          : v0r19 2017/11/21   Add ENABLE_XT
#          : v0r20 2018/01/30   MAXTRANCAP_FREQ_RELAX is changed to 0
#          : v0r21 2018/03/07   PT2016.12 and apply eco_strict_pin_name_equivalence = true
#          : v0r22 2018/04/30   Change PT2015.12 support version
#          : v0r23 2018/09/05   remove chkprime.pl for each reports
#          : v0r24 2019/06/05   Change slave jobs to AL_Ptime/set timeout 86400 to wait jobs.
#          : v0r25 2019/08/19   apply 9001516371_WA.tbc to analyze max_tran/cap correctly
#          : v0r26 2019/09/12   apply timing_include_available_borrow_in_slack=true for calculate D-LATCH slack
#          : v0r27 2020/03/12   support PT2017.12
#          : v0r27a 2020/04/30  set tcl_precision (6)
#          : v0r28 2020/07/22   Change fix_eco_leakage to fix_eco_power, tcl_precision 6 to 12
#          : v0r29 2020/10/28   Add CCE
#          : v0r30 2021/02/19   Pass eco_strict_pin_name_equivalence and timing_save_pin_arrival_and_required to slave
#          : v0r31 2021/03/03   Add setting of core-based license for PT2016.12 and PT2017.12 version.
#          : v0r32 2021/07/12   Change to remote execute for read POWER_ATTR.ptsc
#          : v0r33 2021/07/21   Enable selecting CPUs/MEM each hosts      
#          : v0r34 2021/07/30   Add function and enable get report after pteco
#          : v0r35 2021/09/24   Adupt using PhysicalAware PTECO
#                
# Comment  : Timing-ECO by PrimeTimeECO
#            For session start added
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

set ENABLE_READ_SDC         true;
set CANCEL_TRANnCAP_REPORT  true;
set CANCEL_REPORT_TIMING    true;
set CANCEL_CONST_REPORT     true;
set CANCEL_UPDATE_TIMING    true;
set CANCEL_AC_REPORT        true;
set REPORT_LESSER_THAN_ONLY true;

## PTECO variable
set_app_var timing_save_pin_arrival_and_required true;     # PTECO recommended
set_app_var eco_strict_pin_name_equivalence true;          # avoid to pin swap
set_app_var timing_include_available_borrow_in_slack true; # WA to avoid optmize setup, but we cannot use SignOff STA
set_app_var multi_scenario_license_mode core;              # core-based license (available after PT2016.12, ignore error if you use before it)

#  << set_clock_sense command works same as older version. >>
if {[regexp $PT_VER201206 $sh_product_version]} {
} elseif {[regexp $PT_VER201306 $sh_product_version]} {
} elseif {[regexp $PT_VER201312 $sh_product_version]} {
} elseif {[regexp $PT_VER201406 $sh_product_version]} {
} elseif {[regexp $PT_VER201412 $sh_product_version]} {
} elseif {[regexp $PT_VER201512 $sh_product_version]} {
} elseif {[regexp $PT_VER201612 $sh_product_version]} {
    source /common/appl/Synopsys/primetime/2016.12-sp3-1/9001516371_WA.tbc  ;# W/A for MaxTran with jump clock
} elseif {[regexp $PT_VER201712 $sh_product_version]} {
    source /common/appl/Synopsys/primetime/2017.12-sp3-5-VAL20191205/star_9001516371_fix.tbc        ;# W/A for MaxTran with jump clock
} else {
    puts "* Error: you must use PT version project approved."
    exit
}



# << Reading common procedure >>
source ./scr/common_proc.tcl
source ./scr/r_tcl.proc.tcl

READ_PATH_INFO
#-----------------------------------------------------
# for Uninitialized variables
#-----------------------------------------------------
SET_INIT_VAR LOAD_MODEL                   SPEF;
SET_INIT_VAR CLOCK_MODE                   PROP;
SET_INIT_VAR USE_DB                       false;  # Changed true->false (TAT is same)
SET_INIT_VAR LIB_MODE                     CCS;
SET_INIT_VAR PTECO_SIZE_LIMIT_RATIO       0;     #PrimeTime-ECO Resizing cells ratio
SET_INIT_VAR PTECO_ITER_NUM               30;    #PrimeTime default 30
SET_INIT_VAR PTECO_CURRENT_LIB            false;
SET_INIT_VAR PTECO_PREFIX                 PTECO;
SET_INIT_VAR PTECO_SPLIT_ECOCARD          false;
SET_INIT_VAR CANCEL_CONST_AC              true;
SET_INIT_VAR ENABLE_RESTORE               false;
SET_INIT_VAR ENABLE_HF_ZERO               false;
SET_INIT_VAR ENABLE_XT                    false;
SET_INIT_VAR MAXTRANCAP_FREQ_RELAX        0.000;
SET_INIT_VAR PTECO_MIN_HOSTS              2;        # Currently not work.
SET_INIT_VAR PTECO_PHYSICAL_AWARE         false;
# Initialize var for pteco leak
SET_INIT_VAR PTECO_FIX_LEAK               false; 
SET_INIT_VAR PTECO_LEAK_DOWNSIZE          false;
SET_INIT_VAR PTECO_LEAK_POWER_ATTR        false;
SET_INIT_VAR PTECO_LEAK_DOWN_SEQ          false;
SET_INIT_VAR PTECO_LEAK_REMOVE_BUFFER     false;
SET_INIT_VAR PTECO_LEAK_VTH_SWAP          false;
SET_INIT_VAR PTECO_FIX_LEAK_SETUP_MARGIN  0.000; 
SET_INIT_VAR PTECO_FIX_LEAK_HOLD_MARGIN   0.030; 
SET_INIT_VAR PTECO_MAKE_SUMMARY_LEAK      false; # Run chkprime.pl after eco
# Initialize var for pteco drc
SET_INIT_VAR PTECO_FIX_DRC                false; 
SET_INIT_VAR PTECO_FIX_DRC_SIZE_ONLY      false;
SET_INIT_VAR PTECO_FIX_DRC_VTH_ONLY       false;
SET_INIT_VAR PTECO_MAKE_SUMMARY_DRC       false; # Run chkprime.pl after eco
# Initialize var for pteco setup
SET_INIT_VAR PTECO_FIX_SETUP              false;
SET_INIT_VAR PTECO_FIX_SETUP_SIZE_ONLY    false;
SET_INIT_VAR PTECO_FIX_SETUP_VTH_ONLY     false;
SET_INIT_VAR PTECO_FIX_SETUP_SEQ          false; # ADD variable for SETUP-FIX(SEQ)
SET_INIT_VAR PTECO_FIX_SETUP_SETUP_MARGIN 0.005;
SET_INIT_VAR PTECO_FIX_SETUP_HOLD_MARGIN  -100;
SET_INIT_VAR PTECO_MAKE_SUMMARY_SETUP     false; # Run chkprime.pl after eco
# Initialize var for pteco hold
SET_INIT_VAR PTECO_FIX_HOLD               false;
SET_INIT_VAR PTECO_HOLD_LOAD_ONLY         true;
SET_INIT_VAR PTECO_FIX_HOLD_SETUP_MARGIN  0.000;
SET_INIT_VAR PTECO_FIX_HOLD_HOLD_MARGIN   0.000;
SET_INIT_VAR PTECO_MAKE_SUMMARY_HOLD      false; # Run chkprime.pl after eco
# Initialize var for pteco hold cce
SET_INIT_VAR PTECO_FIX_HOLD_CCE           false; 
SET_INIT_VAR PTECO_MAKE_SUMMARY_HOLD_CCE  false; # Run chkprime.pl after eco


source ./design.cfg
#READ_PTECO_INFO_FROM_DESIGN_CFG

SET_INIT_VAR pteco_slave_procs    [llength $pteco_param_table];

if {$PTECO_PHYSICAL_AWARE == "true"} {
    set_app_var read_parasitics_load_locations true
    set_app_var eco_insert_buffer_search_distance_in_site_rows 20
}

# << DEFINE Check Parameter in this environment >>
#set CHECK_PARAMETER {CONDITIONS STA_MODES}

#====================================================================#
# Define Files
#====================================================================#
set FILE_DONT_USE         ./PTECO/DONT_USE.ptsc
set FILE_DONT_TOUCH       ./PTECO/DONT_TOUCH.ptsc
set FILE_DONT_TOUCH_HM    ./PTECO/DONT_TOUCH_HM.ptsc
set FILE_FALSE_OPPOSITE   ./PTECO/FALSE_OPPOSITE.ptsc
set FILE_SIZE_GROUP       ./PTECO/SIZE_GROUP.ptsc
set FILE_POWER_ATTR       ./PTECO/POWER_ATTR.ptsc
set FILE_RMBUF_DONT_TOUCH ./PTECO/RMBUF_DONT_TOUCH.ptsc
set FILE_PHYSICAL_INFO    ./PTECO/set_physical_library.tcl
ERROR_FILE   FILE_DONT_USE
ERROR_FILE   FILE_DONT_TOUCH

#====================================================================#
# Make Work Directory
#====================================================================#

set workdir dmsa_work
file delete -force ${workdir}

set multi_scenario_working_directory ${workdir}
set multi_scenario_merged_error_log  ${workdir}/error_log.txt

#set currentDir [getenv {currentDir}]

#====================================================================#
# Set Host Options
#====================================================================#
set_app_var eco_enable_more_scenarios_than_hosts    true
set_app_var eco_report_unfixed_reason_max_endpoints 1000 ;# ADD variable at v0r8
set_app_var eco_alternative_area_ratio_threshold    $PTECO_SIZE_LIMIT_RATIO

set master_cores [lindex [getenv LSB_MCPU_HOSTS] 1]
set_host_options -max_cores [lindex [getenv LSB_MCPU_HOSTS] 1]
foreach table $pteco_param_table {
    set CONDITION  [lindex $table 0];
    set DELAY      [lindex $table 1];
    set VDD_CORE   [lindex $table 2];
    set STA_MODE   [lindex $table 3];
    set DFT_MODE   [lindex $table 4];
    set ADD_CONST  [lindex $table 5];
    set SLV_CORES  [lindex $table 6];
    set SLV_MEM    [lindex $table 7];

    if {$STA_MODE == "DFT"} {
        set PTECO_MODE $DFT_MODE
    } else {
        set PTECO_MODE $STA_MODE
    }

    if {$SLV_CORES > 1} {
        set_host_options \
            -num_processes 1 \
            -max_cores ${SLV_CORES} \
            -name ${PTECO_MODE}_${CONDITION}_${DELAY} \
            -submit_command "bs -m \"sv\" -os \"REDHATE6 REDHATE7\" -B -M ${SLV_MEM} -n ${SLV_CORES} -B -J pt_slave_${PTECO_MODE}_${CONDITION}_${DELAY} -tool pt_slave" \
            -terminate_command "/common/lsf/bin/bkill"
    } else {
        set_host_options \
            -num_processes 1 \
            -max_cores ${SLV_CORES} \
            -name ${PTECO_MODE}_${CONDITION}_${DELAY} \
            -submit_command "bs -m \"sv\" -os \"REDHATE6 REDHATE7\" -B -M ${SLV_MEM} -B -J pt_slave_${PTECO_MODE}_${CONDITION}_${DELAY} -tool pt_slave" \
            -terminate_command "/common/lsf/bin/bkill"
    }
}

report_host_usage
#start_hosts -min_host $PTECO_MIN_HOSTS;
start_hosts -timeout 86400;

check_resource START_get_host

#====================================================================#
# Create Scenarios
#====================================================================#
foreach table $pteco_param_table {
    set CONDITION  [lindex $table 0];
    set DELAY      [lindex $table 1];
    set VDD_CORE   [lindex $table 2];
    set STA_MODE   [lindex $table 3];
    set DFT_MODE   [lindex $table 4];
    set ADD_CONST  [lindex $table 5];
    set SLV_CORES  [lindex $table 6];
    set SLV_MEM    [lindex $table 7];

    if {$STA_MODE == "SYSTEM"} {
        set MODE      ${CONDITION}_${STA_MODE}_${DELAY}
    } else {
        set MODE      ${CONDITION}_${STA_MODE}_${DELAY}_${DFT_MODE}
    }

    ## Additional constraints
    if {$STA_MODE == "SYSTEM"} {
        set FILE_TENTATIVE      ${APPLY_DIR}/System/Common/SYS_TENTATIVE.ptsc
    } else {
        set FILE_TENTATIVE      ${APPLY_DIR}/DFT/Common/${DFT_MODE}_TENTATIVE.ptsc
    }

    if {$STA_MODE == "DFT"} {
        set PTECO_MODE $DFT_MODE
    } else {
        set PTECO_MODE $STA_MODE
    }

    ## confirm sesssion
    set RESTORE false
    if {$ENABLE_RESTORE == "true"} {
        if {[file exist "./LOAD/SESSION_KEY_${LOAD_MODEL}.${MODE}"] && [file exist "./LOAD/save.${LOAD_MODEL}.${MODE}"]} {
            puts "* Information : Session Data has been ready. ./LOAD/save.${LOAD_MODEL}.${MODE}"
            puts "* Information : Restore Session (save session data are netlist and spef/sdf and constraints)."
            set SESSION ./LOAD/save.${LOAD_MODEL}.${MODE}
            set RESTORE true
        } else {
            puts "* Information : Session Data has not been ready. Changed to read data from Netlist/Spef/const"
            set RESTORE false
        }
    }

    if {$RESTORE == "true"} {
        create_scenario \
            -name scenario_${PTECO_MODE}_${CONDITION}_${DELAY} \
            -affinity ${PTECO_MODE}_${CONDITION}_${DELAY} \
            -image ${SESSION} \
            -specific_data { ./scr/pteco_initial.tcl ./scr/pteco_drc_const.tcl } \
            -specific_variables { \
                STA_MODE DFT_MODE DELAY CONDITION VDD_CORE ADD_CONST \
                LOAD_MODEL CLOCK_MODE USE_DB ENABLE_READ_SDC ENABLE_HF_ZERO \
                CANCEL_UPDATE_TIMING CANCEL_REPORT_TIMING CANCEL_CONST_REPORT CANCEL_AC_REPORT CANCEL_CONST_AC \
                CANCEL_TRANnCAP_REPORT REPORT_LESSER_THAN_ONLY ENABLE_RESTORE \
                PTECO_FIX_DRC PTECO_FIX_LEAK PTECO_SIZE_LIMIT_RATIO \
                FILE_DONT_USE FILE_DONT_TOUCH FILE_DONT_TOUCH_HM FILE_SIZE_GROUP FILE_POWER_ATTR FILE_RMBUF_DONT_TOUCH FILE_PHYSICAL_INFO \
                FILE_TENTATIVE FILE_FALSE_OPPOSITE APPLY_DIR REPORT_DIR MAXTRANCAP_FREQ_RELAX ENABLE_XT \
                timing_include_available_borrow_in_slack eco_strict_pin_name_equivalence timing_save_pin_arrival_and_required \
                PTECO_PHYSICAL_AWARE read_parasitics_load_locations eco_insert_buffer_search_distance_in_site_rows \
            }
    } else {
        create_scenario \
            -name scenario_${PTECO_MODE}_${CONDITION}_${DELAY} \
            -affinity ${PTECO_MODE}_${CONDITION}_${DELAY} \
            -specific_data { ./scr/pteco_initial.tcl ./scr/main.mcu.tcl ./scr/pteco_drc_const.tcl } \
            -specific_variables {  STA_MODE DFT_MODE DELAY CONDITION VDD_CORE \
                ADD_CONST \
                LOAD_MODEL CLOCK_MODE USE_DB ENABLE_READ_SDC ENABLE_HF_ZERO \
                CANCEL_UPDATE_TIMING CANCEL_REPORT_TIMING CANCEL_CONST_REPORT CANCEL_AC_REPORT CANCEL_CONST_AC \
                CANCEL_TRANnCAP_REPORT REPORT_LESSER_THAN_ONLY ENABLE_RESTORE \
                PTECO_FIX_DRC PTECO_FIX_LEAK PTECO_SIZE_LIMIT_RATIO \
                FILE_DONT_USE FILE_DONT_TOUCH FILE_DONT_TOUCH_HM FILE_SIZE_GROUP FILE_POWER_ATTR FILE_RMBUF_DONT_TOUCH FILE_PHYSICAL_INFO \
                FILE_TENTATIVE FILE_FALSE_OPPOSITE APPLY_DIR REPORT_DIR MAXTRANCAP_FREQ_RELAX ENABLE_XT \
                timing_include_available_borrow_in_slack eco_strict_pin_name_equivalence timing_save_pin_arrival_and_required \
                PTECO_PHYSICAL_AWARE read_parasitics_load_locations eco_insert_buffer_search_distance_in_site_rows \
            }
    }
}
check_resource END_get_host
current_session -all

#====================================================================#
# set_dont_touch & dont_use
#====================================================================#
remote_execute {

    set_app_var eco_alternative_area_ratio_threshold       $PTECO_SIZE_LIMIT_RATIO;# ADD variable unlimited at v0r9

    puts "* Information: Reset eco_changes"
    write_changes -reset
    puts "* Information: Reading $FILE_FALSE_OPPOSITE"
    source -echo -verbose $FILE_FALSE_OPPOSITE
    puts "* Information: Reading $FILE_SIZE_GROUP"
    source -echo -verbose $FILE_SIZE_GROUP
    puts "* Information: Reading $FILE_DONT_TOUCH"
    source -echo -verbose $FILE_DONT_TOUCH
    puts "* Information: Reading $FILE_DONT_USE"
    source -echo -verbose $FILE_DONT_USE
    puts "* Information: Dont_touch Setting net and cells connected HM"
    source -echo -verbose $FILE_DONT_TOUCH_HM
    SET_PROHIBIT_HM_PINS
    puts "* Information: end of donttouch for HM"
    if {$PTECO_PHYSICAL_AWARE == "true"} {
        puts "* Information: Reading $FILE_PHYSICAL_INFO"
        source -echo -verbose $FILE_PHYSICAL_INFO
    }
    ## Additional constraints
    if {$ADD_CONST != "NONE"} {
        puts "Reading $ADD_CONST."
        source -echo $ADD_CONST
    }
    if {$CANCEL_CONST_AC == "true"} {
        if {$DELAY == "SETUP"} {
            set_false_path -from [all_inputs]
            set_false_path -to   [all_outputs]
        } else {
            set_false_path -hold -from [all_inputs]
            set_false_path -hold -to   [all_outputs]
        }
    }
}

#====================================================================#
# STA Before ECO / attach const, and getting reports
#====================================================================#
check_resource START_get_preeco_report
remote_execute {
    if {$DELAY == "SETUP"} {
        redirect -file 00_preeco.all_vio_max.txt.gz -compress {
            report_timing -nosplit -net -input -cap -tran -delay max -max_path 100000 -slack_lesser 0.00001
        }
    } else {
        redirect -file 00_preeco.all_vio_min.txt.gz -compress {
            report_timing -nosplit -net -input -cap -tran -delay min -max_path 100000 -slack_lesser 0.00001
        }
    }
}
#if {[catch "glob ls dmsa_work/scenario_*/00_preeco.all_vio_m??.txt.gz" files] == 0} {
#    foreach file $files {
#        regsub {.txt.gz} $file {.sum} sum
#        sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
#    }
#}
check_resource END_get_preeco_report
sh touch ECO_START

#====================================================================#
# leak optimize
#====================================================================#
#set PTECO_ITER_NUM 2; # default 30
if {$PTECO_ITER_NUM < 30} {
    set PTECO_ITER_OPT "-max_iteration $PTECO_ITER_NUM"
} else {
    set PTECO_ITER_OPT ""
}
if {$PTECO_CURRENT_LIB == "true"} {
    set PTECO_LIB_OPT "-current_library"
} else {
    set PTECO_LIB_OPT ""
}

if {$PTECO_FIX_LEAK == "true" && $sh_product_version != "G-2012.06-SP3-1"} {
    check_resource START_pteco_fix_leak
    set eco_net_name_prefix      "n_${PTECO_PREFIX}leak_"
    set eco_instance_name_prefix "u_${PTECO_PREFIX}leak_"
    remote_execute {
        report_cell_usage -pattern $PTECO_LEAK_PRIORITY   > preleak.Vth.ratio.rpt
        report_power                                      > preleak.power.rpt
        set eco_alternative_cell_attribute_restrictions { rv28f_nolimit_grp rv28ft_nolimit_grp }    ;# nolimit_grp/same_vth_grp/same_size_grp
    }

    set PTECO_LEAK_OPT "$PTECO_ITER_OPT $PTECO_LIB_OPT"
    set PTECO_LEAK_OPT "$PTECO_LEAK_OPT -setup_margin $PTECO_FIX_LEAK_SETUP_MARGIN"

    if {$PTECO_LEAK_DOWNSIZE == "true"} {
        puts "* Information: PTECO LEAK by DownSizing Start!"
        if {$PTECO_LEAK_POWER_ATTR == "true"} {
            puts "* Information: PTECO LEAK power_attribute is enabled."
            remote_execute {
                source -echo -verbose $FILE_POWER_ATTR
            }
            set PTECO_LEAK_OPT "-power_attribute pwr_attr $PTECO_LEAK_OPT"
        }
        puts "* Information: PTECO LEAK by DownSizing combinational cells Start!"
        eval "fix_eco_power -methods size_cell -cell_type combinational $PTECO_LEAK_OPT -verbose"
        if {$PTECO_LEAK_DOWN_SEQ == "true"} {
            puts "* Information: PTECO LEAK by DownSizing sequential cells Start!"
            eval "fix_eco_power -methods size_cell -cell_type sequential $PTECO_LEAK_OPT -verbose"
        }
    }

    if {$PTECO_LEAK_REMOVE_BUFFER == "true"} {
        # Reset option for remove buffer
        set PTECO_LEAK_OPT "$PTECO_ITER_OPT $PTECO_LIB_OPT -hold_margin $PTECO_FIX_LEAK_HOLD_MARGIN"
        puts "* Information: PTECO LEAK by RemoveBuffer Start!"
        remote_execute {
            source -echo -verbose $FILE_RMBUF_DONT_TOUCH
        }
        eval "fix_eco_power -methods remove_buffer $PTECO_LEAK_OPT"
    }

    if {$PTECO_LEAK_VTH_SWAP == "true"} {
        puts "* Information: PTECO LEAK by VthSwap Start!"
        eval "fix_eco_power -pattern_priority {$PTECO_LEAK_PRIORITY} $PTECO_LEAK_OPT -verbose"
    }
    remote_execute {
        report_cell_usage -pattern $PTECO_LEAK_PRIORITY   > 01_postleak.Vth.ratio.rpt
        report_power                                      > 01_postleak.power.rpt
        report_constraint -max_transition -all -nosplit > 01_report_constraint_postleak.rpt
        report_constraint                               > 01_report_constraint_postleak.txt
        report_global_timing                            > 01_report_global_timing_postleak.rpt
    }
    if {$PTECO_SPLIT_ECOCARD == "true"} {
        remote_execute {
            write_changes -format icctcl -output 01_eco_leak.tcl
            write_changes -format ptsh   -output 01_pt_eco_leak.tcl
            write_changes -reset
        }
    }
    if {$PTECO_MAKE_SUMMARY_LEAK == "true"} {
        puts "* Information: Report summary after PTECO LEAK start."
        remote_execute {
            if {$DELAY == "SETUP"} {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
                #mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
            } else {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #sh ./bin/go.mk_pathrep4_2  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep*
            }
        }
    } else {
        puts "* Information: Skip report summary after PTECO LEAK."
    }
    check_resource END_pteco_fix_leak
}


#====================================================================#
# DRC Fixing
#====================================================================#
if {$PTECO_FIX_DRC == "true"} {
    check_resource START_pteco_fix_drc
    set eco_net_name_prefix      "n_${PTECO_PREFIX}drc_"
    set eco_instance_name_prefix "u_${PTECO_PREFIX}drc_"

    remote_execute {
        report_constraint -max_transition -all -nosplit > 02_report_constraint_preeco.rpt
    }

    set PTECO_DRC_OPT "$PTECO_ITER_OPT $PTECO_LIB_OPT"
    if {$PTECO_PHYSICAL_AWARE == "true" && [info exist pteco_drc_bufferList]} {
        set PTECO_DRC_OPT "$PTECO_DRC_OPT -methods {size_cell insert_buffer} -buffer_list $pteco_drc_bufferList"
    } else {
        set PTECO_DRC_OPT "$PTECO_DRC_OPT -methods {size_cell}"
    }
    if {$PTECO_FIX_DRC_SIZE_ONLY == "true"} {
        puts "* Information: FIX DRC by without changing VTH."
        remote_execute {
            set eco_alternative_cell_attribute_restrictions { rv28f_same_vth_grp rv28ft_same_vth_grp }    ;# nolimit_grp/same_vth_grp/same_size_grp
        }
    } elseif {$PTECO_FIX_DRC_VTH_ONLY == "true"} {
        puts "* Information: FIX DRC by without changing Different drive-ability."
        remote_execute {
            set eco_alternative_cell_attribute_restrictions { rv28f_same_size_grp rv28ft_same_size_grp }    ;# nolimit_grp/same_vth_grp/same_size_grp
        }
    } else {
        puts "* Information: FIX DRC by without sizing restriction."
        remote_execute {
            set eco_alternative_cell_attribute_restrictions { rv28f_nolimit_grp rv28ft_nolimit_grp }    ;# nolimit_grp/same_vth_grp/same_size_grp
        }
    }
    if {$PTECO_PHYSICAL_AWARE == "true" && [info exist pteco_drc_bufferList]} {
        puts "* Information: FIX DRC with Physical Aware mode open_site Start."
        eval "fix_eco_drc -type max_transition -verbose $PTECO_DRC_OPT -physical_mode open_site"
    } else {
        puts "* Information: FIX DRC without Physical Aware mode Start."
        eval "fix_eco_drc -type max_transition -verbose $PTECO_DRC_OPT"
    }
    remote_execute {
        report_constraint -max_transition -all -nosplit > 02_report_constraint_postdrc.rpt
        report_constraint                               > 02_report_constraint_postdrc.txt
        report_global_timing                            > 02_report_global_timing_postdrc.rpt
    }
    if {$PTECO_SPLIT_ECOCARD == "true"} {
        remote_execute {
            write_changes -format icctcl -output 02_eco_drc.tcl
            write_changes -format ptsh   -output 02_pt_eco_drc.tcl
            write_changes -reset
        }
    }
    if {$PTECO_MAKE_SUMMARY_DRC == "true"} {
        puts "* Information: Report summary after PTECO DRC start."
        remote_execute {
            if {$DELAY == "SETUP"} {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
                #mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
            } else {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #sh ./bin/go.mk_pathrep4_2  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
            }
        }
    } else {
        puts "* Information: Skip report summary after PTECO DRC."
    }
    check_resource END_pteco_fix_drc
}

#====================================================================#
# Setup Fixing
#====================================================================#
if { $PTECO_FIX_SETUP == "true" } {
    check_resource START_pteco_fix_setup
    set eco_net_name_prefix      "n_${PTECO_PREFIX}setup_"
    set eco_instance_name_prefix "u_${PTECO_PREFIX}setup_"

    set PTECO_SETUP_OPT "$PTECO_ITER_OPT $PTECO_LIB_OPT"
    set PTECO_SETUP_OPT "$PTECO_SETUP_OPT -slack_lesser_than $PTECO_FIX_SETUP_SETUP_MARGIN"
    set PTECO_SETUP_OPT "$PTECO_SETUP_OPT -setup_margin      $PTECO_FIX_SETUP_SETUP_MARGIN"
    set PTECO_SETUP_OPT "$PTECO_SETUP_OPT -hold_margin       $PTECO_FIX_SETUP_HOLD_MARGIN"

    if {$PTECO_FIX_SETUP_SIZE_ONLY == "true"} {
        puts "* Information: FIX SETUP by without changing VTH."
        remote_execute {
            set eco_alternative_cell_attribute_restrictions { rv28f_same_vth_grp rv28ft_same_vth_grp}    ;# nolimit_grp/same_vth_grp/same_size_grp
        }
    } elseif {$PTECO_FIX_SETUP_VTH_ONLY == "true"} {
        puts "* Information: FIX SETUP by without changing Different drive-ability."
        remote_execute {
            set eco_alternative_cell_attribute_restrictions { rv28f_same_size_grp rv28ft_same_size_grp }    ;# nolimit_grp/same_vth_grp/same_size_grp
        }
    } else {
        puts "* Information: FIX SETUP by without sizing restriction."
        remote_execute {
            set eco_alternative_cell_attribute_restrictions { rv28f_nolimit_grp rv28ft_nolimit_grp }    ;# nolimit_grp/same_vth_grp/same_size_grp
        }
    }

    puts "* Information: SETUP_OPTION: $PTECO_SETUP_OPT"
    puts "* Information: FIX SETUP for combinational-cell start."
    if {$PTECO_PHYSICAL_AWARE == "true" && [info exist pteco_setup_bufferList]} {
        puts "* Information: FIX SETUP with Physical Aware mode open_site."
        eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT -methods {size_cell insert_buffer} -physical_mode open_site"
    } else {
        puts "* Information: FIX SETUP without Physical Aware."
        eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT"
    }
    if {$PTECO_FIX_SETUP_SEQ == "true"} {
        puts "* Information: FIX SETUP for Sequential-cell start."
        eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT -cell_type sequential"
    }
    if {$PTECO_SPLIT_ECOCARD == "true"} {
        remote_execute {
            write_changes -format icctcl -output 03_eco_setup.tcl
            write_changes -format ptsh   -output 03_pt_eco_setup.tcl
            write_changes -reset
        }
    }
    if {$PTECO_MAKE_SUMMARY_SETUP == "true"} {
        puts "* Information: Report summary after PTECO SETUP start."
        remote_execute {
            if {$DELAY == "SETUP"} {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
                #mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
            } else {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #sh ./bin/go.mk_pathrep4_2  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep*
            }
        }
    } else {
        puts "* Information: Skip report summary after PTECO SETUP."
    }
    check_resource END_pteco_fix_setup
}


#====================================================================#
# Hold Fixing
#====================================================================#
if {$PTECO_FIX_HOLD == "true"} {
    check_resource START_pteco_fix_hold
    set eco_net_name_prefix      "n_${PTECO_PREFIX}hold_"
    set eco_instance_name_prefix "u_${PTECO_PREFIX}hold_"

    if {$PTECO_HOLD_LOAD_ONLY == "true"} {
        set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins}"
    } else {
        set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins insert_buffer_at_driver_pins}"
    }
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT $PTECO_ITER_OPT"
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -slack_lesser_than $PTECO_FIX_HOLD_HOLD_MARGIN"
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -setup_margin      $PTECO_FIX_HOLD_SETUP_MARGIN"
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -hold_margin       $PTECO_FIX_HOLD_HOLD_MARGIN"
    if {$PTECO_PHYSICAL_AWARE == "false"} {
        puts "* Information: Non physical aware PTECO HOLD is starting."
        puts "* Information: HOLD_OPTION:$PTECO_HOLD_OPT"
        eval "fix_eco_timing -type hold -buffer_list {$pteco_bufferList} -verbose $PTECO_HOLD_OPT"

        if {$PTECO_SPLIT_ECOCARD == "true"} {
            remote_execute {
                write_changes -format icctcl -output 04_eco_hold.tcl
                write_changes -format ptsh   -output 04_pt_eco_hold.tcl
                write_changes -reset
            }
        }
    } else {
        puts "* Information: Open site Physical aware PTECO HOLD is starting."
        puts "* Information: HOLD_OPTION:$PTECO_HOLD_OPT -physical_mode open_site -buffer_list {$pteco_bufferList}"
        eval "fix_eco_timing -type hold -physical_mode open_site -buffer_list {$pteco_bufferList} -verbose $PTECO_HOLD_OPT"
        if {$PTECO_SPLIT_ECOCARD == "true"} {
            remote_execute {
                write_changes -format icctcl -output 04_eco_hold.open_site.tcl
                write_changes -format ptsh   -output 04_pt_eco_hold.open_site.tcl
                write_changes -reset
            }
        }

        puts "* Information: Occupied site Physical aware PTECO HOLD is starting."
        puts "* Information: HOLD_OPTION:$PTECO_HOLD_OPT -physical_mode occupied_site -buffer_list {$pteco_bufferList}"
        eval "fix_eco_timing -type hold -physical_mode occupied_site -buffer_list {$pteco_bufferList} -verbose $PTECO_HOLD_OPT"
        if {$PTECO_SPLIT_ECOCARD == "true"} {
            remote_execute {
                write_changes -format icctcl -output 04_eco_hold.occupied_site.tcl
                write_changes -format ptsh   -output 04_pt_eco_hold.occupied_site.tcl
                write_changes -reset
            }
        }
    }
    if {$PTECO_MAKE_SUMMARY_HOLD == "true"} {
        puts "* Information: Report summary after PTECO HOLD start."
        remote_execute {
            if {$DELAY == "SETUP"} {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
                #mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
            } else {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #sh ./bin/go.mk_pathrep4_2  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
            }
        }
    } else {
        puts "* Information: Skip report summary after PTECO HOLD."
    }
    check_resource END_pteco_fix_hold
}
#====================================================================#
# Hold Fixing by CCE
#====================================================================#
if {$PTECO_FIX_HOLD_CCE == "true"} {
    check_resource START_pteco_fix_hold_cce
    set eco_net_name_prefix      "n_${PTECO_PREFIX}hold_cce_"
    set eco_instance_name_prefix "u_${PTECO_PREFIX}hold_cce_"

    if {$PTECO_HOLD_LOAD_ONLY == "true"} {
        set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins}"
    } else {
        set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins insert_buffer_at_driver_pins}"
    }
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT $PTECO_ITER_OPT"
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -slack_lesser_than $PTECO_FIX_HOLD_HOLD_MARGIN"
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -setup_margin      $PTECO_FIX_HOLD_SETUP_MARGIN"
    set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -hold_margin       $PTECO_FIX_HOLD_HOLD_MARGIN"

    puts "* Information: PTECO HOLD CCE is starting."
    puts "* Information: HOLD_OPTION:$PTECO_HOLD_OPT"
    eval "fix_eco_hold_timing -buffer_list {$pteco_bufferList} -verbose $PTECO_HOLD_OPT"

    if {$PTECO_SPLIT_ECOCARD == "true"} {
        remote_execute {
            write_changes -format icctcl -output 05_eco_holdcce.tcl
            write_changes -format ptsh   -output 05_pt_eco_holdcce.tcl
            write_changes -reset
        }
    }
    if {$PTECO_MAKE_SUMMARY_HOLD_CCE == "true"} {
        puts "* Information: Report summary after PTECO HOLD CCE start."
        remote_execute {
            if {$DELAY == "SETUP"} {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #mkFreq_sum  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.sum
                #mkFreq_path ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep  > ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.path
            } else {
                redirect -file ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep.gz -compress {
                    eval "report_timing ${REPORT_OPT_SLACK}"
                }
                sh ./bin/make_chkprime.pl ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
                #sh ./bin/go.mk_pathrep4_2  ${REPORT_DIR}/timing_slack.${LOAD_MODEL}.${MODE}${NWORD}.rep
            }
        }
    } else {
        puts "* Information: Skip report summary after PTECO HOLD CCE."
    }
    check_resource END_pteco_fix_hold_cce
}


#====================================================================#
# Write ECO File After Fixing
#====================================================================#


if {$PTECO_SPLIT_ECOCARD == "false"} {
    remote_execute {
        write_changes -format icctcl    -output eco_dmsa.tcl
        write_changes -format ptsh    -output pt_eco_dmsa.tcl
    }
}

sh touch ECO_END

if {![info exists DEBUG_JOB]} {
    puts "Information: Exit PrimeTime by batch job"
    exit
}

