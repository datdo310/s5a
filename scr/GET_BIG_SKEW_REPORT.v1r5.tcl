#################################################
# GET_BIG_SKEW_REPORT.tcl 
#
# Version : v1r5 2014/08/25
#a          (1) changed group option. Remove get_object_name
# Version : v1r4 2014/05/23
#           (1) changed SKEW calculation to abs($LATENCY_ED - $LATENCY_ST) + $CRPR]
# Version : v1r3 2014/02/19
# Comment : (1) Added PT version selection for get_timing_path option.
# Version : v1r2 2014/01/08
# Comment : (1) Added some comments.
# Version : v1r1.4 : Removed -group option. Added proc to recover UITE-502 warning.
# Version : v1r1.3 : Changed -group option. Made foreach loop in all groups.
# Version : v1r1.2 : Changed max_path 1,000,000 to 2,000,000. (maximum limit)
# Version : v1r1.1 : Added  -group option to get_timing_path

proc ENABLE_MPCORE {} {
	getenv LSB_MCPU_HOSTS
	set Host [lindex [getenv LSB_MCPU_HOSTS] 0]
	set Ncpu [lindex [getenv LSB_MCPU_HOSTS] 1]
	set_host_options -max_cores $Ncpu
	report_host_usage -verbose
	start_hosts
}
proc WRITE_BIGSKEW_REPORT { {CLOCK} {REP} {LIMIT_SKEW} {MODE} {DIR} {SLACK_MARGIN} {SLACK_MARGIN_L -999}} {
	suppress_message {CMD-041 CMD-018}
	regsub -all {/} $CLOCK {_} log_clock

	puts "* CLOCK $CLOCK , LIMIT_SKEW $LIMIT_SKEW , MODE $MODE , DIR $DIR , SLACK_MARGIN $SLACK_MARGIN , SLACK_MARGIN_L $SLACK_MARGIN_L"

	set BIGSKEW ""
	foreach_in_collection rep $REP {
		set SLACK      [get_attribute $rep slack]
		set LATENCY_ST [get_attribute $rep startpoint_clock_latency]
		set LATENCY_ED [get_attribute $rep endpoint_clock_latency]
		set CRPR       [get_attribute $rep common_path_pessimism]
		set CRPRabs    [expr abs($CRPR)]
		
		set SKEW       [expr abs($LATENCY_ED - $LATENCY_ST) + $CRPR]
		if {$SKEW >= $LIMIT_SKEW} {
			set END_PIN [get_object_name [get_attribute $rep endpoint]]
			echo [format "%30s slack: %5.3f skew(crpr): %5.3f(%5.3f) %s" $CLOCK $SLACK $SKEW $CRPRabs $END_PIN] >> $DIR/log.$MODE.$log_clock
			set BIGSKEW [add_to_collection $BIGSKEW $rep]
		}
	}
	# Write timing_report
	redirect -append $DIR/rep.bigskew.$MODE.$log_clock {report_timing $BIGSKEW -nosplit -input_pins -nets -derate -sig 4}
	unsuppress_message {CMD-041 CMD-018}
}

proc GET_BIG_SKEW_REPORT {{LIMIT_SKEW "0.3"} {SLACK_MARGIN "0.1"} {NWORST "1"} {DIR "./BigSkew"}} {
	suppress_message {CMD-041 CMD-018}
	global MODE
	set TMP_DIR "$DIR/$MODE"
	DIR_CHECK $DIR
	DIR_CHECK $TMP_DIR

	puts ""
	puts "------------------------------------------------------"
	puts "* Informaiton: LIMIT_SKEW   $LIMIT_SKEW"
	puts "*              SLACK_MARGIN $SLACK_MARGIN"
	puts "*              NWORST       $NWORST"
	puts "*              DIR          $DIR"
	puts "*              tmpDIR       $TMP_DIR"
	puts "------------------------------------------------------"
	puts ""



	# check argument
	if {![string is digit $NWORST]} {
		puts "* Error : argument 'NWORST' must be an integer. Not '$NWORST'"
		puts -nonewline "Usage : GET_BIG_SKEW_REPORT <"
		puts -nonewline [join [info args GET_BIG_SKEW_REPORT] "> <"]
		puts ">"
		return
	}

	set ALL_CLOCKS [get_clocks *]
	set NUM_CLOCKS [sizeof_collection $ALL_CLOCKS]
	set LIST_CLOCK [COL2LIST $ALL_CLOCKS]
	
	set TMG_OPT "-delay min -unique_pins -path full_clock_expanded -nworst $NWORST -max 2000000 -slack_less $SLACK_MARGIN"
	if {![regexp {2012.} ${::sh_product_version}]} {
		set TMG_OPT "${TMG_OPT} -group \[get_path_groups \*]"
	}

	set stringCMD "parallel_execute \{\n"
	foreach clock $LIST_CLOCK {
		puts "* $clock"
		regsub -all {/} $clock {_} log_clock
		set TMG_string "$TMG_OPT -to \[get_clocks $clock\]"
		redirect -variable stringCMD -append { echo "\{set TMG($clock) \[get_timing_path $TMG_string\];\
			WRITE_BIGSKEW_REPORT $clock \$TMG($clock) $LIMIT_SKEW $MODE $DIR $SLACK_MARGIN\
			\} $TMP_DIR/log.$log_clock" }
	}
	set stringCMD "$stringCMD\}"
	eval $stringCMD

	# check  UITE-502
	foreach f [glob -directory $TMP_DIR "log.*"] {
		recover502 $f $NWORST 1 $DIR
	}


	unsuppress_message {CMD-041 CMD-018}
}

# recover Warning UITE-502
proc recover502 {{file} {NWORST} {DEPTH} {ROOT_DIR}} {


	# read log file to find UITE-502
	set flag 0
	set fid [open $file]
	puts "* Information : Checking UITE-502 $file"
	while {[gets $fid str] >= 0} {
		if {[regexp {(UITE-502)} $str]} {
			set flag 1
		}
		if {[regexp {\* CLOCK } $str]} {
			set step 0
			foreach item [split $str] {
				if {$item == "*" || $item == ","} {continue}
				if {$step == 0} {
					set aaaa $item
					set step 1
				} elseif {$step == 1} {
					set $aaaa $item
					set step 0
				}
			}
		}
	}
	close $fid
	if {$flag == 0} {return}
	puts "* Information : UITE-502 found."

        # calculate  report range and step
	if {$SLACK_MARGIN_L == -999} {
		set REP [get_timing_path -delay min -nworst 1 -max 1 -slack_lesser_than inf -to [get_clocks $CLOCK]]
		foreach_in_collection rep $REP {
			set SLACK_MARGIN_L [get_attribute $rep slack]
		}
	}
        set Ncpu [lindex [getenv LSB_MCPU_HOSTS] 1]
        if {$Ncpu < 2} {set Ncpu 2}
	set step [expr abs($SLACK_MARGIN - $SLACK_MARGIN_L) / $Ncpu]
	#puts "* Ncpu $Ncpu , SLACK $SLACK_MARGIN_L , SLACK_MARGIN $SLACK_MARGIN"

	set DIR     "${ROOT_DIR}_${DEPTH}"
	set TMP_DIR "${DIR}/$MODE"
	#file delete -force ${TMP_DIR}
	#file delete [glob -directory ${DIR} "*.${MODE}.${CLOCK}"
	DIR_CHECK ${DIR}
	DIR_CHECK ${TMP_DIR}
	incr DEPTH

	#
	set TMG_OPT "-delay min -unique_pins -path full_clock_expanded -nworst $NWORST -max 2000000 -group [get_object_name [get_path_groups *]]"

	set stringCMD "parallel_execute \{\n"
	for {set i 1} {$i <= $Ncpu} {incr i} {
		puts "* $i: $CLOCK"
		regsub -all {/} $CLOCK {_} log_clock
		set SLACK_MARGIN_GT [expr $SLACK_MARGIN - $step * ($i - 1)]
		if {$i < $Ncpu} {
			set SLACK_MARGIN_LT [expr $SLACK_MARGIN - $step * $i]
		} else {
			set SLACK_MARGIN_LT $SLACK_MARGIN_L
		}
		set slack_range "-slack_lesser ${SLACK_MARGIN_GT} -slack_greater ${SLACK_MARGIN_LT}"
		
		set TMG_string "$TMG_OPT $slack_range -to \[get_clocks $CLOCK\]"
		redirect -variable stringCMD -append { echo "\{set TMG($CLOCK) \[get_timing_path $TMG_string\];\
			WRITE_BIGSKEW_REPORT $CLOCK \$TMG($CLOCK) $LIMIT_SKEW $MODE ${DIR} $SLACK_MARGIN_GT $SLACK_MARGIN_LT\
			\} $TMP_DIR/log.${log_clock}_${SLACK_MARGIN_GT}_${SLACK_MARGIN_LT}" }
	}
	set stringCMD "$stringCMD\}"
	eval $stringCMD


	# check UITE-502 message.
	# It would be good to move this loop to the top of this proc.
	# and remove the same loop in the last of GET_BIG_SKEW_REPORT.
	foreach f [glob -directory $TMP_DIR "log.*"] {
		recover502 $f $NWORST $DEPTH ${ROOT_DIR}
	}

	# Merge the result files 
	# It would be good to add error recovery description.
	puts "* Information : Merging the results."
	set PID [pid]
	exec cat "${DIR}/rep.bigskew.${MODE}.${CLOCK}" >> "${ROOT_DIR}/rep.bigskew.${MODE}.${CLOCK}"
	exec cat "${DIR}/log.${MODE}.${CLOCK}"         >> "${ROOT_DIR}/log.${MODE}.${CLOCK}"
	exec cat "${ROOT_DIR}/log.${MODE}.${CLOCK}" | sort -u > "${ROOT_DIR}/log.${MODE}.${CLOCK}.${PID}"
	file delete "${ROOT_DIR}/log.${MODE}.${CLOCK}"
	file rename "${ROOT_DIR}/log.${MODE}.${CLOCK}.${PID}" "${ROOT_DIR}/log.${MODE}.${CLOCK}"
} ;# end proc

