##############################################
# Main script of PrimeTime for 40/45nm process
# Common STA environment Generation V2
# Name     : get_summary_transition_rep.tcl
# Author   : N.Yada Renesas Electronics Corporation
# Version  :
#          : v0r3 2013/05/09
#                 Changed file name.
#                 get_summery_... -> get_summary_...
#          : v0r2 2012/11/26
#                 Changed Criteria.
#                 MAX 4 -> 2.4, SO 1.2 -> 2.4, ratio1 0.6 -> 0.4
#                 Suppofted hier-netlist like CIS.
#                 Added pinname, directio and clock/date to output file.
#          : v0r1 2010/03/19  modify criteria 0.4->0.6
#          : v0r0 2010/11/30
#                             ratio for over Fth and 0.5cyc
# Comment  : New
##############################################


proc analysis_tran_rep { rep rep_freq halfcyc out } {
	set f_0p4  [open $rep r]
	set f_clk  [open $rep_freq r]
	set f_half [open $halfcyc r]
	set wf [open $out w]

#-- set transition(10-90) constrain ---

	## fixed value [ns]
	 set RESET 0.8
	 set SO 2.4
	 set MAX 2.4

	## set cyc ratio
	 # frequency threshold [MHz]
	 set Fth 300
	 # ratio for over Fth and 0.5cyc
	 set ratio1 0.4
	 # ratio for less than Fth
	 set ratio2 0.6

#--------------------------------------

	# << Transition Report spec:0.4ns >>
	set vio_list [list]
	set NR 0
	while { ![eof $f_0p4] } {
		gets  $f_0p4 line_str
        	incr NR
		if { [llength $line_str] == 5} {
        		scan $line_str "%s %s %s %s %s" pin reqTran Tran slack flag
			if { $flag == "(VIOLATED)" } {
				if { [regexp {\/R?E?SETB?$} $pin] && [expr $Tran > $RESET]} {
					lappend vio_list [format "RESET %s %s %s" $pin $RESET $Tran]  
				} elseif { [regexp {\/SO$} $pin] && [expr $Tran > $SO]} {
					lappend vio_list [format "SO %s %s %s" $pin $SO $Tran]
if {$pin == "PVA3R_CORE/icbr_pva3r_core/vsplt0_tstall_flg_reg_9/SO"} {
	#puts "VIO_LIST1"
	#puts [format "SO %s %s %s" $pin $SO $Tran]
}
				} elseif { [expr $Tran > $MAX] } {
					lappend vio_list [format "MAX %s %s %s" $pin $MAX $Tran]
				}
			}
		}
	}

	# << Half-Cycle path >>
        while { [gets $f_half line] >= 0 } {
                set half_netname [lindex [removeSpace [split $line]] 0]
                set half_net [get_attribute -quiet [get_nets $half_netname] full_name]
                foreach_in_collection half_pin [get_pins -leaf -of $half_net] {
                        #set half_pinname [get_attribute $half_pin base_name]
                        #set half_instname [get_attribute $half_pin cell_name]
                        #set target [format "%s/%s" $half_instname $half_pinname]
			#set CHECK($target) "true"
			set CHECK([get_attri $half_pin full_name]) "true"
                }
	}


	# << Transition Report spec: frec-clock >>
        set NR 0
        while { ![eof $f_clk] } {
                gets  $f_clk line_str
                incr NR
                if { [llength $line_str] == 5} {
                        scan $line_str "%s %s %s %s %s" pin reqTran Tran slack flag
                        if { $flag == "(VIOLATED)" } {
				set cyc [expr $reqTran*10]
				set f [expr 1/($cyc/0.8)*1000]
				if { [info exist CHECK($pin)] } {
					set category HALF_FREQ
					set require [expr ($cyc/2)*$ratio1]
				} else {
					if { [expr $f >= $Fth] } {
						set category HI_FREQ
						set require [expr $cyc*$ratio1]
					} else {
						set category FREQ
						set require [expr $cyc*$ratio2]
					}
                        	}
				if { [expr $Tran > $require]} {
                                		lappend vio_list [format "%s %s %s %s" $category $pin $require $Tran]
if {$pin == "PVA3R_CORE/icbr_pva3r_core/vsplt0_tstall_flg_reg_9/SO"} {
	#puts "VIO_LIST2"
	#puts [format "%s %s %s %s" $category $pin $require $Tran]
}
                                }
			}
                }
        }

	# << Collect Violated netname >>
	set vio_net_pre [list]
	set vio_net [list]
        foreach i $vio_list {
		scan $i "%s %s %s %s" category pin require Tran
		set netname  [get_attribute -quiet [get_nets -quiet -of $pin] full_name]
		set netobj   [get_nets -quiet -of [get_pins -quiet -leaf -of $netname -filter "direction==out"]]
		if { [sizeof_collection $netobj] == 1 } { set netname [get_attribute -quiet $netobj full_name] }
		if { $netname != "" } {
			if {![info exists REQ($netname)]} {
				set REQ($netname) $require
				set ACT($netname) $Tran
				set PIN($netname) $pin
			}
			lappend vio_net_pre [format "%s %s" $category $netname]
if {$pin == "PVA3R_CORE/icbr_pva3r_core/vsplt0_tstall_flg_reg_9/SO"} {
	#puts "REQ_ACT: $require $Tran $category $netname"
}
		}
        }
	set vio_net [lsort -unique $vio_net_pre]

	# << Display >>
	foreach i $vio_net {
                scan $i "%s %s" category netname
		if { [info exist REQ($netname)] } {
			# Exception : FREQ attribute of test-signal
			if { [regexp {FREQ$} $category] && [regexp {Z997|ZQQ7} $netname] } {
			} else {
				set slack [expr $ACT($netname)-$REQ($netname)]
				set pindir [get_attribute [get_pins $PIN($netname)] direction]
				set netType "Clock"
				if { [get_attribute -quiet [get_pins $PIN($netname)] clocks] == ""} {set netType "DATA"}
				puts $wf [format "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" $category $slack $REQ($netname) $ACT($netname) $netname $PIN($netname) $pindir $netType]
			}
                }
        }

	close $wf
}

proc removeSpace { l } {
	set newl {}
	foreach obj $l {
        	if { ![string match $obj " "] } {
        		set newl [lappend newl $obj]
        	}
    	}
	return $newl
}

