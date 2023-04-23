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
#          : v0r28 2020/10/28   Add CCE
#          : v0r30 2021/02/19   Pass eco_strict_pin_name_equivalence and timing_save_pin_arrival_and_required to slave
#          : v0r31 2021/03/03   Add setting of core-based license for PT2016.12 and PT2017.12 version.
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
set timing_save_pin_arrival_and_required true;  # PTECO recommended
set eco_strict_pin_name_equivalence true;	# avoid to pin swap
set_app_var timing_include_available_borrow_in_slack true	;# WA to avoid optmize setup, but we cannot use SignOff STA
set_app_var multi_scenario_license_mode core ;# core-based license (available after PT2016.12, ignore error if you use before it)

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
SET_INIT_VAR LOAD_MODEL              SPEF;
SET_INIT_VAR CLOCK_MODE              PROP;
SET_INIT_VAR USE_DB                  false;  # Changed true->false (TAT is same)
SET_INIT_VAR LIB_MODE                CCS;
SET_INIT_VAR PTECO_SIZE		     true; 
SET_INIT_VAR PTECO_SIZE_VTH	     true; 
SET_INIT_VAR PTECO_FIX_DRC           false; 
SET_INIT_VAR PTECO_FIX_LEAK          false; 
SET_INIT_VAR PTECO_LEAK_DOWNSIZE     false;
SET_INIT_VAR PTECO_LEAK_POWER_ATTR   false;
SET_INIT_VAR PTECO_LEAK_DOWN_SEQ     false;
SET_INIT_VAR PTECO_FIX_SETUP         true; 
SET_INIT_VAR PTECO_FIX_SETUP_SEQ     false; # ADD variable for SETUP-FIX(SEQ)
SET_INIT_VAR PTECO_FIX_HOLD          true; 
SET_INIT_VAR PTECO_FIX_HOLD_CCE      false; 
SET_INIT_VAR PTECO_ITER_NUM          30;    #PrimeTime default 30
SET_INIT_VAR PTECO_SIZE_LIMIT_RATIO  0;     #PrimeTime-ECO Resizing cells ratio

SET_INIT_VAR PTECO_SETUP_MARGIN      0.005; 
SET_INIT_VAR PTECO_HOLD_MARGIN       0.001; 
SET_INIT_VAR PTECO_CURRENT_LIB       false;
SET_INIT_VAR PTECO_HOLD_LOAD_ONLY    true;
SET_INIT_VAR PTECO_PREFIX            PTECO;
SET_INIT_VAR PTECO_SPLIT_ECOCARD     false;
SET_INIT_VAR CANCEL_CONST_AC         true;
SET_INIT_VAR ENABLE_RESTORE          false;
SET_INIT_VAR ENABLE_HF_ZERO          false;
SET_INIT_VAR ENABLE_XT               false;
SET_INIT_VAR MAXTRANCAP_FREQ_RELAX   0.000;
SET_INIT_VAR PTECO_MIN_HOSTS         2;		# Currently not work.


source ./design.cfg
READ_PTECO_INFO_FROM_DESIGN_CFG

SET_INIT_VAR pteco_slave_procs	[llength $pteco_param_table];

# << DEFINE Check Parameter in this environment >>
#set CHECK_PARAMETER {CONDITIONS STA_MODES}

#====================================================================#
# Define Files
#====================================================================#
set FILE_DONT_USE       ./PTECO/DONT_USE.ptsc
set FILE_DONT_TOUCH     ./PTECO/DONT_TOUCH.ptsc
set FILE_DONT_TOUCH_HM  ./PTECO/DONT_TOUCH_HM.ptsc
set FILE_FALSE_OPPOSITE ./PTECO/FALSE_OPPOSITE.ptsc
set FILE_SIZE_GROUP	./PTECO/SIZE_GROUP.ptsc
set FILE_POWER_ATTR     ./PTECO/POWER_ATTR.ptsc
ERROR_FILE   FILE_DONT_USE
ERROR_FILE   FILE_DONT_TOUCH


if { [info exist PTECO_SIZE_VTH_ONLY] } {
	puts "Error: PTECO_SIZE_VTH_ONLY variable is obsolute\n";
	puts "       Change PTECO_SIZE_VTH_ONLY -> PTECO_SIZE_VTH(VTH change), PTECO_SIZE(Size change)\n"
	exit
}

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
 
if {$pteco_slave_cores > 1} {
 set_host_options -max_core $pteco_slave_cores -num_processes $pteco_slave_procs \
   -submit_command "bs -os RHEL6 -M [expr $pteco_slave_mem * 1000] -q AL_Ptime -n $pteco_slave_cores -B" \
   -terminate_command "/common/lsf/bin/bkill"
} else {
 set_host_options -num_processes $pteco_slave_procs \
   -submit_command "bs -os RHEL6 -M [expr $pteco_slave_mem * 1000] -q AL_Ptime -B" \
   -terminate_command "/common/lsf/bin/bkill"
}


report_host_usage
#start_hosts -min_host $PTECO_MIN_HOSTS;
start_hosts -timeout 86400;


#====================================================================#
# Create Scenarios
#====================================================================#
foreach item $pteco_param_list {
    set elm        [split $item ","]
    set CONDITION  [lindex $elm 0];
    set DELAY      [lindex $elm 1];
    set VDD_CORE   [lindex $elm 2];
    set STA_MODE   [lindex $elm 3];
    set DFT_MODE   [lindex $elm 4];
    set ADD_CONST  [lindex $elm 5];

    set MODE      ${CONDITION}_${STA_MODE}_${DELAY}

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
                #restore_session ./LOAD/save.${LOAD_MODEL}.${MODE}
                set RESTORE true
        } else {
                puts "* Information : Session Data has not been ready. Changed to read data from Netlist/Spef/const"
                set RESTORE false
        }
    }

	create_scenario \
		-name scenario_${PTECO_MODE}_${CONDITION}_${DELAY} \
		-specific_data { ./scr/pteco_initial.tcl ./scr/main.mcu.tcl ./scr/pteco_drc_const.tcl } \
		-specific_variables {  STA_MODE DFT_MODE DELAY CONDITION VDD_CORE \
		  ADD_CONST \
		  LOAD_MODEL CLOCK_MODE USE_DB ENABLE_READ_SDC ENABLE_HF_ZERO \
		  CANCEL_UPDATE_TIMING CANCEL_REPORT_TIMING CANCEL_CONST_REPORT CANCEL_AC_REPORT CANCEL_CONST_AC \
		  CANCEL_TRANnCAP_REPORT REPORT_LESSER_THAN_ONLY ENABLE_RESTORE \
		  PTECO_FIX_DRC PTECO_FIX_LEAK PTECO_SIZE_LIMIT_RATIO PTECO_SPLIT_ECOCARD \
		  FILE_DONT_USE FILE_DONT_TOUCH FILE_DONT_TOUCH_HM FILE_SIZE_GROUP FILE_POWER_ATTR PTECO_SIZE_VTH PTECO_SIZE \
		  FILE_TENTATIVE FILE_FALSE_OPPOSITE APPLY_DIR REPORT_DIR MAXTRANCAP_FREQ_RELAX ENABLE_XT \
		  timing_include_available_borrow_in_slack eco_strict_pin_name_equivalence timing_save_pin_arrival_and_required \
		}

}


date
cputime
mem

current_session -all


#====================================================================#
# set_dont_touch & dont_use
#====================================================================#
remote_execute {

   set_app_var eco_alternative_area_ratio_threshold       $PTECO_SIZE_LIMIT_RATIO;# ADD variable unlimited at v0r9

   puts "* Information : Reset eco_changes"
   write_changes -reset
   puts "* Information : Reading $FILE_FALSE_OPPOSITE"
   source -echo -verbose $FILE_FALSE_OPPOSITE
   puts "* Information : Reading $FILE_SIZE_GROUP"
   source -echo -verbose $FILE_SIZE_GROUP
   puts "* Information : Reading $FILE_DONT_TOUCH"
   source -echo -verbose $FILE_DONT_TOUCH
   puts "* Information : Reading $FILE_DONT_USE"
   source -echo -verbose $FILE_DONT_USE
   puts "* Information : Dont_touch Setting net and cells connected HM"
   source -echo -verbose $FILE_DONT_TOUCH_HM
   SET_PROHIBIT_HM_PINS
   puts "* Information : end of donttouch for HM"
   ## Additional constraints
    if {$ADD_CONST != ""} {
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
date
cputime
mem

#====================================================================#
# STA Before ECO / attach const, and getting reports
#====================================================================#
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
#	foreach file $files {
#		regsub {.txt.gz} $file {.sum} sum
#		sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
#	}
#}
date
cputime
mem

sh touch ECO_START

#====================================================================#
# leak optimize
#====================================================================#
#set PTECO_ITER_NUM 2; # default 30
if { $PTECO_ITER_NUM < 30 } {
    set PTECO_ITER_OPT "-max_iteration $PTECO_ITER_NUM"
} else {
    set PTECO_ITER_OPT ""
}
if { $PTECO_CURRENT_LIB == "true" } {
    set PTECO_LIB_OPT "-current_library"
} else {
    set PTECO_LIB_OPT ""
}

if { $PTECO_FIX_LEAK == "true" && $sh_product_version != "G-2012.06-SP3-1"} {
    set eco_net_name_prefix      "n_${PTECO_PREFIX}leak_"
    set eco_instance_name_prefix "u_${PTECO_PREFIX}leak_"
    remote_execute {
        report_cell_usage -pattern $PTECO_LEAK_PRIORITY   > preleak.Vth.ratio.rpt
        report_power                                      > preleak.power.rpt
        set eco_alternative_cell_attribute_restrictions { nolimit_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
    }

    set PTECO_LEAK_OPT "$PTECO_ITER_OPT"
    set PTECO_LEAK_OPT "$PTECO_LEAK_OPT -setup_margin $PTECO_SETUP_MARGIN"

    if { $PTECO_LEAK_DOWNSIZE == "true" } {
        puts "Information: PTECO LEAK by DownSizing Start!"
        if { $PTECO_LEAK_POWER_ATTR == "true" } {
            puts "Information: PTECO LEAK power_attribute is enabled."
            source -echo -verbose $FILE_POWER_ATTR
            set PTECO_LEAK_OPT "-power_attribute pwr_attr $PTECO_LEAK_OPT"
        }
        puts "Information: PTECO LEAK by DownSizing combinational cells Start!"
        eval "fix_eco_power -cell_type combinational $PTECO_LEAK_OPT -verbose"
        if { $PTECO_LEAK_DOWN_SEQ == "true" } {
            puts "Information: PTECO LEAK by DownSizing sequential cells Start!"
            eval "fix_eco_power -cell_type sequential $PTECO_LEAK_OPT -verbose"
        }
    }

    puts "Information: PTECO LEAK by VthSwap Start!"
    eval "fix_eco_power -pattern_priority {$PTECO_LEAK_PRIORITY} $PTECO_LEAK_OPT -verbose"

    remote_execute {
        report_cell_usage -pattern $PTECO_LEAK_PRIORITY   > postleak.Vth.ratio.rpt
        report_power                                      > postleak.power.rpt

        if {$PTECO_SPLIT_ECOCARD == "true"} {
            write_changes -format icctcl -output 01_eco_leak.tcl
            write_changes -format ptsh   -output 01_pt_eco_leak.tcl
            write_changes -reset
        }

        report_constraint -max_transition -all -nosplit > 01_report_constraint_postleak.rpt
        report_constraint                               > 01_report_constraint_postleak.txt
        report_global_timing                            > 01_report_global_timing_postleak.rpt
        if {$DELAY == "SETUP"} {
            redirect -file 01_postleak.all_vio_max.txt.gz -compress {
                report_timing -nosplit -net -input -cap -tran -delay max -max_path 100000 -slack_lesser 0.00001 -sig 3
            }
        } else {
            redirect -file 01_postleak.all_vio_min.txt.gz -compress {
                report_timing -nosplit -net -input -cap -tran -delay min -max_path 100000 -slack_lesser 0.00001 -sig 3
            }
        }
    }
  #if {[catch "glob ls dmsa_work/scenario_*/01_postleak.all_vio_m??.txt.gz" files] == 0} {
  #	foreach file $files {
  #		regsub {.txt.gz} $file {.sum} sum
  #		sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
  #	}
  #}
}


#====================================================================#
# DRC Fixing
#====================================================================#
if { $PTECO_FIX_DRC == "true" } {
   report_constraint -max_transition -all -nosplit > 02_report_constraint_preeco.rpt
   set eco_net_name_prefix      "n_${PTECO_PREFIX}drc_"
   set eco_instance_name_prefix "u_${PTECO_PREFIX}drc_"

   if {$PTECO_SIZE == "true"} {
	puts "Information: FIX DRC by Sizing without changing VTH Start!"
   	remote_execute {
     		set eco_alternative_cell_attribute_restrictions { same_vth_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
   	if { [info exist pteco_drc_bufferList] } {
		eval "fix_eco_drc -type max_transition -verbose -methods { size_cell insert_buffer } \
                     -buffer_list $pteco_drc_bufferList $PTECO_ITER_OPT $PTECO_LIB_OPT"
	} else {
		eval "fix_eco_drc -type max_transition -verbose -methods { size_cell } $PTECO_ITER_OPT $PTECO_LIB_OPT"
	}
	puts "Information: FIX DRC by Sizing without changing VTH End!"
   }
   if {$PTECO_SIZE_VTH == "true"} {
	puts "Information: FIX DRC by without changing Different size Start!"
   	remote_execute {
     		set eco_alternative_cell_attribute_restrictions { same_size_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
   	if { [info exist pteco_drc_bufferList] } {
		eval "fix_eco_drc -type max_transition -verbose -methods { size_cell insert_buffer } \
                     -buffer_list $pteco_drc_bufferList $PTECO_ITER_OPT $PTECO_LIB_OPT"
	} else {
		eval "fix_eco_drc -type max_transition -verbose -methods { size_cell } $PTECO_ITER_OPT $PTECO_LIB_OPT"
	}
	puts "Information: FIX DRC by Sizing without changing Different size End!"
   }

   remote_execute {
	report_constraint -max_transition -all -nosplit > 02_report_constraint_postdrc.rpt
	report_constraint                               > 02_report_constraint_postdrc.txt
	report_global_timing                            > 02_report_global_timing_postdrc.rpt
	if {$PTECO_SPLIT_ECOCARD == "true"} {
		write_changes -format icctcl -output 02_eco_drc.tcl
		write_changes -format ptsh   -output 02_pt_eco_drc.tcl
		write_changes -reset
	}

	if {$DELAY == "SETUP"} {
		redirect -file 02_postdrc.all_vio_max.txt.gz -compress {
			report_timing -nosplit -net -input -cap -tran -delay max -max_path 100000 -slack_lesser 0.00001 -sig 3
		}
	} else {
		redirect -file 02_postdrc.all_vio_min.txt.gz -compress {
			report_timing -nosplit -net -input -cap -tran -delay min -max_path 100000 -slack_lesser 0.00001 -sig 3
		}
	}
  }
  #if {[catch "glob ls dmsa_work/scenario_*/02_postdrc.all_vio_m??.txt.gz" files] == 0} {
  #	foreach file $files {
  #		regsub {.txt.gz} $file {.sum} sum
  #		sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
  #	}
  #}
}

#====================================================================#
# Setup Fixing
#====================================================================#
if { $PTECO_FIX_SETUP == "true" } {
   set eco_net_name_prefix      "n_${PTECO_PREFIX}setup_"
   set eco_instance_name_prefix "u_${PTECO_PREFIX}setup_"

   set PTECO_SETUP_OPT "-methods size_cell $PTECO_ITER_OPT $PTECO_LIB_OPT"
   set PTECO_SETUP_OPT "$PTECO_SETUP_OPT -slack_lesser_than $PTECO_SETUP_MARGIN"
   set PTECO_SETUP_OPT "$PTECO_SETUP_OPT -setup_margin      $PTECO_SETUP_MARGIN"
   set PTECO_SETUP_OPT "$PTECO_SETUP_OPT -hold_margin       -100"

   if {$PTECO_SIZE == "true"} {
	puts "Information: PTECO SETUP by Sizing without changing VTH Start!"
	puts "*            SETUP_OPTION:$PTECO_SETUP_OPT"
   	remote_execute {
     		set eco_alternative_cell_attribute_restrictions { same_vth_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
	eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT"
	puts "Information: PTECO SETUP by Sizing without changing VTH End!"
   	#if { $PTECO_FIX_SETUP_SEQ == "true" } {
	#	puts "* Information: PTECO SETUP for Sequential-cell is starting."
	#	puts "*              SETUP_OPTION: $PTECO_SETUP_OPT"
	#	eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT -cell_type sequential"
   	#}
   }
   if {$PTECO_SIZE_VTH == "true"} {
	puts "Information: Sizing without changing Different size Start!"
   	remote_execute {
     		set eco_alternative_cell_attribute_restrictions { same_size_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
	eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT"
	puts "Information: Sizing without changing Different size End!"
   	if { $PTECO_FIX_SETUP_SEQ == "true" } {
		puts "* Information: PTECO SETUP for Sequential-cell is starting."
		puts "*              SETUP_OPTION: $PTECO_SETUP_OPT"
		eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT -cell_type sequential"
   	}
   }
   if {$PTECO_SIZE == "false" && $PTECO_SIZE_VTH == "false"} {
	puts "Information: Up/DownSizing and VTH in same time Start!"
   	remote_execute {
     		set eco_alternative_cell_attribute_restrictions { nolimit_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
	eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT"
   	if { $PTECO_FIX_SETUP_SEQ == "true" } {
		puts "* Information: PTECO SETUP for Sequential-cell is starting."
		puts "*              SETUP_OPTION: $PTECO_SETUP_OPT"
		eval "fix_eco_timing -type setup -verbose $PTECO_SETUP_OPT -cell_type sequential"
   	}
   }


   remote_execute {
	if {$PTECO_SPLIT_ECOCARD == "true"} {
		write_changes -format icctcl -output 03_eco_setup.tcl
		write_changes -format ptsh   -output 03_pt_eco_setup.tcl
		write_changes -reset
	}
	if {$DELAY == "SETUP"} {
		redirect -file 03_postsetup.all_vio_max.txt.gz -compress {
			report_timing -nosplit -net -input -cap -tran -delay max -max_path 100000 -slack_lesser 0.00001 -sig 3
		}
	} else {
		redirect -file 03_postsetup.all_vio_min.txt.gz -compress {
			report_timing -nosplit -net -input -cap -tran -delay min -max_path 100000 -slack_lesser 0.00001 -sig 3
		}
	}
  }
  #if {[catch "glob ls dmsa_work/scenario_*/03_postsetup.all_vio_m??.txt.gz" files] == 0} {
  #	foreach file $files {
  #		regsub {.txt.gz} $file {.sum} sum
  #		sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
  #	}
  #}
}


#====================================================================#
# Hold Fixing
#====================================================================#
if { $PTECO_FIX_HOLD == "true" } {
   	remote_execute {
		set eco_alternative_cell_attribute_restrictions { same_vth_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
	if {$PTECO_HOLD_LOAD_ONLY == "true"} {
		set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins}"
	} else {
		set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins insert_buffer_at_driver_pins}"
	}
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT $PTECO_ITER_OPT"
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -slack_lesser_than $PTECO_HOLD_MARGIN"
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -setup_margin      $PTECO_SETUP_MARGIN"
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -hold_margin       $PTECO_HOLD_MARGIN"

	set eco_net_name_prefix      "n_${PTECO_PREFIX}hold_"
	set eco_instance_name_prefix "u_${PTECO_PREFIX}hold_"

	puts "* Information: PTECO HOLD is starting."
	puts "*              HOLD_OPTION:$PTECO_HOLD_OPT"
	eval "fix_eco_timing -type hold -buffer_list {$pteco_bufferList} -verbose $PTECO_HOLD_OPT"


	remote_execute {
		if {$PTECO_SPLIT_ECOCARD == "true"} {
			write_changes -format icctcl -output 04_eco_hold.tcl
			write_changes -format ptsh   -output 04_pt_eco_hold.tcl
			write_changes -reset
		}
		if {$DELAY == "SETUP"} {
			redirect -file 04_posthold.all_vio_max.txt.gz -compress {
				report_timing -nosplit -net -input -cap -tran -delay max -max_path 100000 -slack_lesser 0.00001 -sig 3
			}
		} else {
			redirect -file 04_posthold.all_vio_min.txt.gz -compress {
				report_timing -nosplit -net -input -cap -tran -delay min -max_path 100000 -slack_lesser 0.00001 -sig 3
			}
		}
	}
	#if {[catch "glob ls dmsa_work/scenario_*/04_posthold.all_vio_m??.txt.gz" files] == 0} {
	#	foreach file $files {
	#		regsub {.txt.gz} $file {.sum} sum
	#		sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
	#	}
	#}
   date
   cputime
   mem
}
#====================================================================#
# Hold Fixing by CCE
#====================================================================#
if { $PTECO_FIX_HOLD_CCE == "true" } {
   	remote_execute {
		set eco_alternative_cell_attribute_restrictions { same_vth_grp }	;# nolimit_grp/same_vth_grp/same_size_grp
	}
	if {$PTECO_HOLD_LOAD_ONLY == "true"} {
		set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins}"
	} else {
		set PTECO_HOLD_OPT "-method {insert_buffer_at_load_pins insert_buffer_at_driver_pins}"
	}
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT $PTECO_ITER_OPT"
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -slack_lesser_than $PTECO_HOLD_MARGIN"
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -setup_margin      $PTECO_SETUP_MARGIN"
	set PTECO_HOLD_OPT "$PTECO_HOLD_OPT -hold_margin       $PTECO_HOLD_MARGIN"

	set eco_net_name_prefix      "n_${PTECO_PREFIX}hold_cce_"
	set eco_instance_name_prefix "u_${PTECO_PREFIX}hold_cce_"

	puts "* Information: PTECO HOLD CCE is starting."
	puts "*              HOLD_OPTION:$PTECO_HOLD_OPT"
	eval "fix_eco_hold_timing -buffer_list {$pteco_bufferList} -verbose $PTECO_HOLD_OPT"


	remote_execute {
		if {$PTECO_SPLIT_ECOCARD == "true"} {
			write_changes -format icctcl -output 05_eco_holdcce.tcl
			write_changes -format ptsh   -output 05_pt_eco_holdcce.tcl
			write_changes -reset
		}
		if {$DELAY == "SETUP"} {
			redirect -file 05_posthold.all_vio_max.txt.gz -compress {
				report_timing -nosplit -net -input -cap -tran -delay max -max_path 100000 -slack_lesser 0.00001 -sig 3
			}
		} else {
			redirect -file 05_posthold.all_vio_min.txt.gz -compress {
				report_timing -nosplit -net -input -cap -tran -delay min -max_path 100000 -slack_lesser 0.00001 -sig 3
			}
		}
	}
	#if {[catch "glob ls dmsa_work/scenario_*/04_posthold.all_vio_m??.txt.gz" files] == 0} {
	#	foreach file $files {
	#		regsub {.txt.gz} $file {.sum} sum
	#		sh bs -os RHEL5 -M 2000 -B -q AL_Other ./bin/chkprime.pl $file -out $sum
	#	}
	#}
   date
   cputime
   mem
}


#====================================================================#
# Write ECO File After Fixing
#====================================================================#


if {$PTECO_SPLIT_ECOCARD == "false"} {
    remote_execute {
        write_changes -format icctcl	-output eco_dmsa.tcl
        write_changes -format ptsh	-output pt_eco_dmsa.tcl
    }
}

sh touch ECO_END

if {![info exists DEBUG_JOB]} {
        puts "Information: Exit PrimeTime by batch job"
        exit
}

