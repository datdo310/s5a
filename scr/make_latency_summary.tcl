source ./scr/common_proc.tcl

set MODE      ${CONDITION}_${STA_MODE}_${DELAY}
set OPT_FLAG  ""
if {[info exists DFT_MODE] && $DFT_MODE != "INTEG" && $DFT_MODE != "SDC"} {
      set OPT_FLAG "_${DFT_MODE}${OPT_FLAG}"
}
set MODE      ${CONDITION}_${STA_MODE}_${DELAY}${OPT_FLAG}

READ_PATH_INFO

check_resource START
set START_TIME2 [clock seconds]
if {[file exists ./LOAD/save.${LOAD_MODEL}.${MODE}]} {
	puts "Information: Reading Session"
	restore_session ./LOAD/save.${LOAD_MODEL}.${MODE}
} else {
	puts "Information: Reading Session"
	exit
}
check_resource Read_Session
set START_TIME $START_TIME2
source -echo ./design.cfg

if {[string match "DFT" $STA_MODE]} {
	set CUT_MODE	$DFT_MODE
	set NOCHK_CLK	${APPLY_DIR}/except/DFT_${CUT_MODE}/nochk_latency_clk_${CUT_MODE}.list
} else {
	set CUT_MODE	$STA_MODE
	set NOCHK_CLK	${APPLY_DIR}/except/SYS/nochk_latency_clk_${CUT_MODE}.list
}




set REP_DIR	./Report/LATENCY/${CUT_MODE}_${DELAY}_${CONDITION}
DIR_CHECK $REP_DIR


set_timing_derate -early 1.0
set_timing_derate -late  1.0
update_timing -full

##---------------------------------------##
## Get Latency Report for each condition ##
##---------------------------------------##
set fo [open ${REP_DIR}/chk_clk.list w]

set VIRTUAL_CLK [filter_collection [all_clocks] "is_generated==false && undefined(sources)"]
set CLK_LISTS [sort_collection -dictionary [all_clocks] full_name]

set fi [open ${REP_DIR}/all_clk.list w]
puts $fi "[regsub -all -- " " [get_object_name $CLK_LISTS] "\n"]"
close $fi

set CLK_LISTS [remove_from_collection $CLK_LISTS $VIRTUAL_CLK]

if { [file exists ${NOCHK_CLK}] } {
	puts "Information: ${NOCHK_CLK} is found. read this file to exclude clock latency check"
	set fi [open ${NOCHK_CLK} r]
	while {![eof $fi]} {
		set delclk [read -nonewline $fi]
	}
	set CLK_LISTS [remove_from_collection $CLK_LISTS [get_clocks -quiet $delclk]]
	close $fi
} else {
	puts "Information: ${NOCHK_CLK} is not found"
}

foreach_in_collection tmpclk $CLK_LISTS {
	set clk [get_object_name $tmpclk]
	report_clock_timing -clock $clk -type latency -nworst 1000000000 -nosplit > ${REP_DIR}/latency_${clk}.rep
	puts $fo "$clk"
}

#set cmd "perl -ni -e {print ; print \"$tmp_file\" if \$. == 3} histogram.csh.mod"
#eval exec $cmd


close $fo
##------------------------------------------##
## End of Latency Report for each condition ##
##------------------------------------------##

sh bin/latency_histogram.pl ${REP_DIR} 0 0.2 ; # step = 0.200ns 

report_clock_timing -type latency -nosplit          > ${REP_DIR}/latency_all_summary.rep
report_clock_timing -type latency -nosplit -verbose > ${REP_DIR}/latency_all_summary_verbose.rep

exit


