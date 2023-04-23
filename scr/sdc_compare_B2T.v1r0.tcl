##############################################
# Compare SDC (TOP2TOP/1design 2sdc)
# Common STA environment
# Name     : sdc_compare_B2T.tcl
# Version  : v1r0  2017/12/11   Y.Oda
# Comment  : GCA for comparing SDC
##############################################
set GCA_VER201212 H-2012.12-SP2
set GCA_VER201306 H-2013.06-SP1
set GCA_VER201312 I-2013.12-SP1
set GCA_VER201412 J-2014.12-SP3-1
set GCA_VER201512 K-2015.12-SP3


# <<Common alias >>
history keep    500
alias   h       history
alias   rt      "report_timing -sig 3 -nospl -net"

#  << set_clock_sense command works same as older version. >>
if {[regexp $GCA_VER201312 $sh_product_version]} {
} elseif {[regexp $GCA_VER201412 $sh_product_version]} {
} elseif {[regexp $GCA_VER201512 $sh_product_version]} {
} else {
	puts "* Error: you must use PT version project approved."
	exit
}



# << Reading common procedure >>
source ./scr/common_proc.tcl
source ./scr/r_tcl.proc.tcl

READ_PATH_INFO

check_resource START
set START_TIME [clock seconds]

#------------------------------------------------------------------
# << Initial Setting >>
#------------------------------------------------------------------
# added 2011/12/08      for GCA
set_app_var sh_continue_on_error true
source -echo ./design.cfg
source -echo ./sdc_compare.cfg

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
#set_app_var extract_model_with_ccs_timing              false   ;# (option) (EDA recommended false from PT2015.12-SP3)
#set_app_var link_keep_cells_with_pg_only_connection    true    ;# (option) (EDA recommended true from PT2015.12-SP3)
#set_app_var link_keep_unconnected_cells                        true    ;# (option) (EDA recommended true from PT2015.12-SP3)



# Common setting (OCV = AOCVM)
set_app_var  timing_clock_gating_propagate_enable           true
set_app_var  timing_disable_clock_gating_checks             false
set_app_var  timing_disable_recovery_removal_checks         false
set          timing_dynamic_loop_breaking                   false
puts "Information(PTEnv): Variable(timing_dynamic_loop_breaking) is abolished from PT2015.12, Error message must be printed."

SET_INIT_VAR COMPARE_RESULT_DIR			Report_SDCCOMPARE

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



###################################################################
# << Read TOP SDC >>
###################################################################
for { set i 0 } { $i< [llength $TOP_SDC] } { incr i } {
	set SDC_GOLDEN [subst [lindex $TOP_SDC $i]];
	if {[file exists $SDC_GOLDEN]} {
		puts "*Information: Reading $SDC_GOLDEN"
		source -echo $SDC_GOLDEN
	} else {
		puts "*Error : Not Found $SDC_GOLDEN"
	}
}

###################################################################
# << Read Block SDC and compare SDC>>
###################################################################
foreach BLOCK_ITEM $BLOCK_ITEMS {
	# << Read Block SDC >>
	if { [llength $BLOCK_ITEM] < 3} {
		puts "Error: define \{ Block_name CLOCK_MAP SDC1 \[SDC2 SDC3 ...\] \}"
	}
	set BLOCK_NAME	[lindex $BLOCK_ITEM 0]
	set CLOCK_MAP	[subst [lindex $BLOCK_ITEM 1]]
	check_resource Start_${BLOCK_NAME}
	current_design $BLOCK_NAME
	link_design -add $BLOCK_NAME
	for { set i 2 } { $i< [llength $BLOCK_ITEM] } { incr i } {
		set SDC_REF [subst [lindex $BLOCK_ITEM $i]];
		if {[file exists $SDC_REF]} {
			puts "*Information: Reading $SDC_REF"
			source -echo $SDC_REF
		} else {
			puts "*Error : Not Found $SDC_REF"
		}
	}
	if {[file exists $CLOCK_MAP]} {
		source -echo -verbose $CLOCK_MAP
	} else {
		puts "*Error : Not Found $CLOCK_MAP"
	}


	# << COMPARE SDC >>
	DIR_CHECK ${COMPARE_RESULT_DIR}/${BLOCK_NAME}
	report_constraint_analysis -include { violations }    -style full    -rule_types block2top -output ${COMPARE_RESULT_DIR}/${BLOCK_NAME}/constraint_vio.rep_type_full
	report_constraint_analysis -include { violations }    -style summary -rule_types block2top -output ${COMPARE_RESULT_DIR}/${BLOCK_NAME}/constraint_vio.rep_type_summary
	report_constraint_analysis -include { rule_info }                    -rule_types block2top -output ${COMPARE_RESULT_DIR}/${BLOCK_NAME}/gca_report_info
	report_constraint_analysis -include { user_messages } -style full    -format standard                   -output ${COMPARE_RESULT_DIR}/${BLOCK_NAME}/user_message_vio.rep
	report_constraint_analysis -include { violations }    -style full    -format csv  -rule_types block2top -output ${COMPARE_RESULT_DIR}/${BLOCK_NAME}/constraint_vio.rep_type_full.csv
	report_constraint_analysis -include { violations }    -style summary -format csv  -rule_types block2top -output ${COMPARE_RESULT_DIR}/${BLOCK_NAME}/constraint_vio.rep_type_summary.csv
	check_resource END_${BLOCK_NAME}

}



if {![info exists DEBUG_JOB]} {
        puts "Information: Exit GCA by batch job"
        exit
}

