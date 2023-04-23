#!/bin/sh
#\
exec tclsh "$0" ${1+"$@"}

####################################################################
# File    : mkHOLD_path.tcl
# Version : v0r0
# Author  : S.Abe @RenesasCorp.
# COMMENT : New
####################################################################

#####################
# Error processing  #
#####################
proc ERROR_MESSAGE {{argv0}} {
        puts "
                useage : $argv0 <timing_report>\n
        "
        exit
}
if {$argc<1 || $argc>2} { ERROR_MESSAGE $argv0 }

set LIST_CLK {}

set bar "+============================================================================================+"
set REPORT_FILE [lindex $argv 0]
set fid [open $REPORT_FILE]
set inREP 0
set SAME_ST_LIST {}
while {[gets $fid str]>=0} {
	if {[regexp "^----" $str] > 0} {continue}
	switch $inREP {
	0 {
		switch -regexp $str {
			"Startpoint:" {
				set START [lindex $str 1]
			}
			"Endpoint:" {
				set END [lindex $str 1]
			}
			"Path Group:" {
				set GROUP [lindex $str 2]
			}
			"Point" {
				set inREP 1
				if {[regexp "Trans" $str] > 0} {
					set FlagTran true
				} else {
					set FlagTran false
				}
			}
			default {}
		}
	}
	1 {
		if {[regexp {clock [0-9a-zA-Z_']* \(} $str] > 0} {
			set ST_CLK  [lindex $str 1]
			if {$FlagTran == "true"} {
				set ST_TIME [lindex $str 5]
			} else {
				set ST_TIME [lindex $str 4]
			}
			set inREP 2
		}
	}
	2 {
		if {[regexp {clock [0-9a-zA-Z_']* \(} $str] > 0} {
			if {[regexp "source latency" $str] > 0} {
				set ST_LATENCY [lindex $str 5]
			} else {
				set ED_CLK  [lindex $str 1]
				if {$FlagTran == "true"} {
					set ED_TIME [lindex $str 5]
				} else {
					set ED_TIME [lindex $str 4]
				}
				set inREP 3
			}
		} elseif {[regexp "${START}/" [lindex $str 0]] > 0} {
			if {[regexp {/[T]?CLK[AB]?} [lindex $str 0]] > 0} {
				set START [lindex $str 0]
				if {$FlagTran == "true"} {
					set Latency_ST [lindex $str 6]
				} else {
					set Latency_ST [lindex $str 5]
				}
			}
		} elseif {[regexp "data arrival time" $str] > 0} {
			set END $MONI
		}
	}
	3 {
		if {[regexp "source latency" $str] > 0} {
			set ED_LATENCY [lindex $str 5]
		}
		if {[regexp "time borrowed from endpoint" $str] > 0} {
			set ED_CLK  ${ED_CLK}_latch
			set ED_TIME [expr [lindex $str 4] + $ED_TIME]
			set inREP 3
		} elseif {[regexp "clock reconvergence pessimism" $str] > 0} {
			set CRPR    [lindex $str 3]
			set Latency_ED [lindex $str 4]
		} elseif {[regexp "slack" $str] > 0} {
			set SLACK [lindex $str 2]
			if {$SLACK == "increase"} {set SLACK 0.0}

			set SKEW [expr $Latency_ED - $Latency_ST]
			set Latency_ED [expr $Latency_ED - $CRPR]
			set PERI  [expr $ED_TIME - $ST_TIME]
			if {$PERI == 0.0} {
				set PERI $ED_TIME
				if {$SLACK >= 0} {
					set RATIO 1
				} else {
					if {$ED_TIME == 0} {
						set RATIO 1
						set PERI  1
					} else {
						set RATIO [expr ($SLACK + $ED_TIME) / $ED_TIME]
					}
				}
			} else {
				set ARRL  [expr $PERI - $SLACK]
				set RATIO [expr $ARRL / $PERI]
			}
			if {[info exists WST_RATIO(${ST_CLK}@${ED_CLK})]} {
				if {$RATIO > $WST_RATIO(${ST_CLK}@${ED_CLK})} {
					set WST_RATIO(${ST_CLK}@${ED_CLK}) $RATIO
				}
			} else {
				set WST_RATIO(${ST_CLK}@${ED_CLK}) $RATIO
				lappend LIST_CLK ${ST_CLK}@${ED_CLK}
			}
			set inREP 0
			set FlagTran false
			lappend DB_LIST(${ST_CLK}@${ED_CLK}) [list $SKEW $SLACK $CRPR ${ST_CLK}@${ED_CLK} $Latency_ST $Latency_ED $ST_TIME $ED_TIME $START $END]
			#lappend DB_LIST(${ST_CLK}@${ED_CLK}) [list $SKEW $SLACK $PERI ${ST_CLK}@${ED_CLK} $ST_TIME $ED_TIME $START $END]

			lappend SAME_ST_LIST $START
		}
	}
	}
	set MONI [lindex $str 0]
}
close $fid

# Analyze same start point
foreach tmp $SAME_ST_LIST {
	if {[info exists SAME_NUM($tmp)]} {
		incr SAME_NUM($tmp)
	} else {
		set SAME_NUM($tmp) 1
		lappend list_same_st $tmp
	}
}
set RESULT_SAME_ST {}
foreach tmp $list_same_st {
	if {$SAME_NUM($tmp) > 1} {
		lappend RESULT_SAME_ST "$SAME_NUM($tmp) $tmp"
	}
}
if {[llength $RESULT_SAME_ST]>0} {
	puts $bar
	puts "@ You should check following same start points."
	puts $bar
	foreach disp [lsort -index 0 -integer -decreasing $RESULT_SAME_ST] {
		puts "@ $disp"
	}
	puts $bar
}
puts {}
puts [format "%20s %6s" "" "Ckock Latency" ]
puts [format "%5s %7s %6s %6s %6s %6s %6s %20s %20s %s %s" \
	SKEW SLACK CRPR T(ST) T(ED) E(ST) E(ED) ST_CLK ED_CLK START END]
puts $bar
foreach clk $LIST_CLK {
	regsub "(.*)@.*" $clk {\1} DISP_CLK_st
	regsub ".*@(.*)" $clk {\1} DISP_CLK_ed
	foreach disp [lsort -index 0 -real -decreasing $DB_LIST($clk)] {
	set SKEW   [lindex $disp 0]
	set SLACK   [lindex $disp 1]
	set CRPR    [lindex $disp 2]
	#set PERI    [lindex $disp 2]
	set CLK     [lindex $disp 3]
	set Latency_ST [lindex $disp 4]
	set Latency_ED [lindex $disp 5]

	set ST_TIME [lindex $disp 6]
	set ED_TIME [lindex $disp 7]
	set START   [lindex $disp 8]
	set END     [lindex $disp 9]

	if {$DISP_CLK_st == $DISP_CLK_ed} {
		puts [format "%5.3f %7.3f %6.3f %6.3f %6.3f %6.2f %6.2f %41s %s %s" \
			$SKEW $SLACK $CRPR $Latency_ST $Latency_ED $ST_TIME $ED_TIME $DISP_CLK_ed $START $END]
	} else {
		puts [format "%5.3f %7.3f %6.3f %6.3f %6.3f %6.2f %6.2f %20s %20s %s %s" \
			$SKEW $SLACK $CRPR $Latency_ST $Latency_ED $ST_TIME $ED_TIME $DISP_CLK_st $DISP_CLK_ed $START $END]
	}
	}
	puts $bar
	unset DISP_CLK_st
	unset DISP_CLK_ed
}
####################################################################
#                              END                                 #
####################################################################
