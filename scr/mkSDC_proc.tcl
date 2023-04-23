proc TRACE_TPI_FF { {TRACE_ROOT_LIST "tt_tr"} } {
    set ROOT [get_pins -of [get_nets $TRACE_ROOT_LIST] -filter pin_direction=="out"]
    set TPI_FF {}
    foreach_in_collection TT_TR $ROOT {
        set TPI_FF [add_to_collection $TPI_FF [all_fanout -from $TT_TR -endpoints_only -flat]]
    }
    set TPI_FF [sort_collection $TPI_FF full_name]
    foreach tmp [COL2LIST $TPI_FF] {
        echo $tmp
    }
}

proc CHECK_GCLK {} {
    suppress_message {ATTR-3}
    foreach_in_collection CLK_CG [get_generated_clocks] {
        puts {}
        set PIN_CG     [get_attribute $CLK_CG sources]
        set INST_CG    [get_cells -of [get_pins $PIN_CG]]
	
        redirect /dev/null {
            set MASTER_CLK [COL2LIST [get_attribute $CLK_CG master_clock]]
            set IN_CLK     [COL2LIST [get_attribute [get_pins -of $INST_CG -filter "(is_clock_used_as_clock==true || is_clock_pin==true) && pin_direction==in"] clocks]]
            if {[llength $IN_CLK] == 0} {
                set IN_CLK_TRACED [remove_from_collection [all_fanin -to $PIN_CG -startpoint] $PIN_CG]
                set IN_CLK        [COL2LIST [get_attribute [filter_collection $IN_CLK_TRACED "(is_clock_used_as_clock==true || is_clock_pin==true) && pin_direction==in"] clocks]]
            }
            set IN_CLK        [lsort -dictionary -unique $IN_CLK]
        }

        #set IN_CLK     [COL2LIST [get_attribute [get_pins -of $INST_CG -filter pin_direction=="in"] clocks]]
        set NAME_CG    [get_object_name $CLK_CG]
        set NAME_PIN_CG    [get_object_name $PIN_CG]
	
        if {[lsearch $IN_CLK $MASTER_CLK] == "-1"} {
            puts "# NG : $MASTER_CLK => $NAME_CG ($NAME_PIN_CG)"

            if {[llength $MASTER_CLK]=="0"} {
                puts "       Error: No master clock"
            }
            foreach tmp $IN_CLK {
                puts "       $tmp"
            }
        } else {
            puts "  OK : $MASTER_CLK => $NAME_CG ($NAME_PIN_CG)" 
            foreach tmp $IN_CLK {
                if {$MASTER_CLK == $tmp} {
                    puts "     * $tmp"
                } else {
                    puts "       $tmp"
                }
            }
        }
        set NAME_CG {}
        set IN_CLK {}
        set NAME_PIN_CG {}
    }
    unsuppress_message {ATTR-3}
}

################################################################################
# Proc : mk_inputAC_false
#   Make input ac false script for SOC product.
################################################################################
proc mk_inputAC_false { pad_inst patten_file output_file } {
    # Make port name list
    set all_port_coll [get_ports *]
    foreach_in_collection coll $all_port_coll {
        lappend all_port_list [get_object_name $coll]
    }

    # Make padlogic output pin list that connected to internal module
    set pad_out_coll [get_pins ${pad_inst}/* -filter "direction==out"]
    foreach_in_collection coll $pad_out_coll {
        set pad_o_pin [get_object_name $coll]
        set net_name [get_object_name [get_nets -of $coll]]
        if {$net_name == ""} {continue}
        if {[lsearch $all_port_list $net_name]!=-1} {continue}

        set connect_inst($pad_o_pin) ""
        set connect_pin_col [get_pin -of $net_name -filter "direction==in"]
        foreach_in_collection pin_col $connect_pin_col {
            set pin_name [get_object_name $pin_col]
            regsub {\/.*} $pin_name "" conn_inst
            regsub {gpio.*} $conn_inst "gpio*" conn_inst
            lappend connect_inst($pad_o_pin) $conn_inst
        }
    }

    if {[catch {open $patten_file r} PAT]} {
        puts "Error : Can not open pattern file ($patten_file)"
        return
    }
    if {[catch {open $output_file w} OUT]} {
        puts "Error : Can not create false const file ($output_file)"
        return
    }

    puts $OUT "#########################################################################################"
    puts $OUT "#   False setting of Input multiple AC"
    puts $OUT "#      Made by mk_inputAC_false : [date]"
    puts $OUT "#########################################################################################"

    set head {set_false_path -from [get_clock }
    set middle1 {] -through [get_ports }
    set middle2 {] -through [get_pins -l -of [get_nets }
    set tail {] -filter "direction==out"]}
    while {[gets $PAT line]>=0} {
        regsub { *$} $line "" line
        set port_name [lindex $line 0]
        puts "Searching input false of port : $port_name"
        puts $OUT "\#"
        puts $OUT "\# Target port : $port_name"
        puts $OUT "\#"
        if {[llength $line] == 1 } {
            puts $OUT ""
            continue
        }
        set path_pad_out {}
        #
        # Search pad pins and connected instance that in logic from ports.
        #
        foreach_in_collection pin_coll [filter_collection [all_fanout -from $port_name] "pin_direction==out"] {
            set pad_pin [get_object_name $pin_coll]
            if {[regexp "^${pad_inst}/" $pad_pin]==0} {continue}
            set other_pad_pins [remove_from_collection $pad_out_coll $pin_coll]
            set path_col [get_timing_path -from [get_ports $port_name] -through [get_pins $pad_pin] -exclude $other_pad_pins]
            if {[sizeof_collection $path_col]>0} { lappend path_pad_out $pad_pin }
        }
        #
        # Make false setting to unnecessary timing path that through of pad pins
        #
        foreach path [lrange $line 1 end] {
            set clock [lindex $path 0]
            set true_inst [lrange $path 1 end]
            foreach pad_pin $path_pad_out {
                set false 1
                foreach inst $connect_inst($pad_pin) {
                    if {[lsearch $true_inst $inst]!=-1} { set false 0 }
                }
                if { $false == 1 } {
                    puts $OUT "$head$clock$middle1$port_name$middle2$pad_pin$tail"
                }
            }
        }
        puts $OUT ""
    }
    close $OUT
}

################################################################################
# Proc : mk_output_false
#   Make output ac false script for SOC product.
################################################################################
proc mk_outputAC_false { pad_inst patten_file output_file } {
    # Make port name list
    set all_port_coll [get_ports *]
    foreach_in_collection coll $all_port_coll {
        lappend all_port_list [get_object_name $coll]
    }

    # Make padlogic output pin list that connected to internal module
    set pad_in_coll [get_pins ${pad_inst}/* -filter "direction==in"]
    foreach_in_collection coll $pad_in_coll {
        set pad_i_pin [get_object_name $coll]
        set net_name [get_object_name [get_nets -of $coll]]
        if {$net_name == ""} {continue}
        if {[lsearch $all_port_list $net_name]!=-1} {continue}

        lappend pad_out_list $pad_i_pin
        set connect_inst($pad_i_pin) ""
        set connect_pin_col [get_pin -of $net_name -filter "direction==out"]
        foreach_in_collection pin_col $connect_pin_col {
            set pin_name [get_object_name $pin_col]
            regsub {\/.*} $pin_name "" conn_inst
            regsub {gpio.*} $conn_inst "gpio*" conn_inst
            lappend connect_inst($pad_i_pin) $conn_inst
        }
    }

    if {[catch {open $patten_file r} PAT]} {
        puts "Error : Can not open pattern file ($patten_file)"
        return
    }
    if {[catch {open $output_file w} OUT]} {
        puts "Error : Can not create false const file ($output_file)"
        return
    }

    puts $OUT "#########################################################################################"
    puts $OUT "#   False setting of Output multiple AC"
    puts $OUT "#      Made by mk_outputAC_false : [date]"
    puts $OUT "#########################################################################################"

    set head {set_false_path -through [get_pins -l -of [get_nets }
    set middle1 {] -filter "direction==in"] -through [get_ports }
    set middle2 {] -to [get_clocks }
    set tail {]}
    while {[gets $PAT line]>=0} {
        regsub { *$} $line "" line
        set port_name [lindex $line 0]
        puts "Searching output false of port : $port_name"
        puts $OUT "\#"
        puts $OUT "\# Target port : $port_name"
        puts $OUT "\#"
        if {[llength $line] == 1 } {
            puts $OUT ""
            continue
        }
        set path_pad_in {}
        #
        # Search pad pins that include timng path of target ports
        #
        foreach_in_collection pin_coll [filter_collection [all_fanin -to $port_name] "pin_direction==in"] {
            set pad_pin [get_object_name $pin_coll]
            if {[regexp "^${pad_inst}/" $pad_pin]==0} {continue}
            set other_pad_pins [remove_from_collection $pad_in_coll $pin_coll]
            set path_col [get_timing_path -through [get_pins $pad_pin] -to [get_ports $port_name] -exclude $other_pad_pins]
            if {[sizeof_collection $path_col]>0} { lappend path_pad_in $pad_pin }
        }
        #
        # Make false setting to unnecessary timing path that through pad pins.
        #
        foreach path [lrange $line 1 end] {
            set clock [lindex $path 0]
            set true_inst [lrange $path 1 end]
            foreach pad_pin $path_pad_in {
                set false 1
                foreach inst $connect_inst($pad_pin) {
                    if {[lsearch $true_inst $inst]!=-1} { set false 0 }
                }
                if { $false == 1 } {
                    puts $OUT "$head$pad_pin$middle1$port_name$middle2$clock$tail"
                }
            }
        }
        puts $OUT ""
    }
    close $OUT

}

proc chkMACRO_type {{PIN_COLLECTION}} {
    set pins  [get_pins $PIN_COLLECTION]
    set cells [get_cells -of $pins]
    set refs  [get_attribute $cells ref_name]
    COUNT_REF $refs
}

proc COUNT_REF {{LIST_TGT}} {
    set TYPE_LIST {}
    foreach tmp $LIST_TGT {
        if {[lsearch $TYPE_LIST $tmp] == -1} {
            lappend TYPE_LIST $tmp
            set num($tmp) 1
        } else {
            incr num($tmp)
        }
    }
    foreach tmp $TYPE_LIST {
        puts [format "%7d %s" $num($tmp) $tmp]
    }
}

proc mkMPI_const {{ROOT "TEST_TOP/ACBISTDFTP"} {outfile "SCAN_MPI.ptsc"}} {
	set chkValue  1
	set ROOT      [get_pins $ROOT]
	set MPI_cells [get_cells -h HT_MPI_*]
	set MPI_cntrl [get_pins -o $MPI_cells -filter lib_pin_name=="A"]
	set_case_analysis $chkValue [get_pins $ROOT]

	set fid  [ open $outfile w ]
	puts $fid "#########################################"
	puts $fid "## SCAN_MPI.ptsc [date]"
	puts $fid "## Total MPI     [sizeof_collection $MPI_cells]"
	puts $fid "#########################################"
	set nu 1
	foreach_in_collection chkPIN $MPI_cntrl {
		set chk [get_attribute $chkPIN case_value]
		if {$chk == $chkValue} {
			set outpin [get_object_name [get_pins -of [get_cells -of $chkPIN] -filter pin_direction==out]]
			puts "* OK($nu) : $outpin"
			puts $fid "set_false_path -from \[get_clocks LB_AC1_*\] -thr $outpin"
		} else {
			# NG
			puts "# Error($nu): $chk(Not $chkValue) [get_object_name $chkPIN]"
			puts $$fid "# Error: $chk(Not $chkValue) [get_object_name $chkPIN]"
		}
		set outpin ""
		set chk ""
		incr nu
	}	
	close $fid
}


proc chkCLK {} {
set clocks [get_clocks]
foreach_in_collection tmp $clocks {
	set peri [get_attribute $tmp period]
	set MHZ  [expr 1 / $peri * 1000]
	set name [get_object_name $tmp]
	puts [format "%6.2f %s" $MHZ $name]
}
}
proc chkMEM_CLK {{LIBNAME {jk*_* Amcip*}}} {
	set REFS [get_attribute [get_lib_cells -of [get_libs $LIBNAME]] base_name]
	
	foreach ref $REFS {
		puts "* $ref"
		set CELLS [get_cells -q -h * -filter ref_name==$ref]

		foreach_in_collection cell $CELLS {
			set PINclk [get_pins -of $cell -filter is_clock_pin==true]
			foreach_in_collection pin $PINclk {
				set CLKSTA [get_object_name [get_attribute $pin clocks]]
				puts "	([get_attribute $pin lib_pin_name]) \{$CLKSTA\} [get_object_name $cell]"
			}
		}
	}
}
proc chkMBISTclkSTOP {} {
	set CGG_GTD [get_cells sys_top/sysvdd/cggtop/gck*/gck]	
	foreach_in_collection tmp $CGG_GTD {
		set GTDoutnet [get_object_name [get_nets -of [get_pins -of $tmp -filter lib_pin_name=="GCLK"]]]
		set clkName   [get_object_name [get_nets -of [get_pins $GTDoutnet]]]
		set inCLK     [get_object_name [get_pins -of $tmp -filter lib_pin_name=="CLK"]]
		#puts "* $inCLK ;# $clkName"
		if {[regexp {_mbist} $clkName]} {
			puts "# active clock ;# $inCLK ;# $clkName"
		} else {
			puts "set_clock_sense -stop_propagation \[get_pins $inCLK\] ;# $clkName"
		}
	}
}
proc chkFieldMBISTclkSTOP {} {
	set CGG_GTD [get_cells sys_top/sysvdd/cggtop/gck*/gck]	
	foreach_in_collection tmp $CGG_GTD {
		set GTDoutnet [get_object_name [get_nets -of [get_pins -of $tmp -filter lib_pin_name=="GCLK"]]]
		set clkName   [get_object_name [get_nets -of [get_pins $GTDoutnet]]]
		set inCLK     [get_object_name [get_pins -of $tmp -filter lib_pin_name=="CLK"]]
		#puts "* $inCLK ;# $clkName"
		if {[regexp {_mbist} $clkName]} {
			puts "# active clock ;# $inCLK ;# $clkName"
		} else {
			puts "set_clock_sense -stop_propagation -clock \[get_clocks FB_M_*\] \[get_pins $inCLK\] ;# $clkName"
		}
	}
}

proc readMEGMIcsv {{FILE "/design01/rh850d4_me/01_DFT/01_D4/v004_scaap/30_MBIST/02_MBIST/03_MEGMI.reGroup/CSV_fin_mod.csv"} {instWBST "MB_MINORI_WBIST"} {CHECK true}} {
# This is the format of MEGMI file.
# 0: No
# 1: memID
# 2: ApgGr
# 3: EncGr
# 4: RamGr
# 5: RepairGr1
# 6: RepairGr2
# 7: FuseRegGr
# 8: NMA1Gr
# 9: NMA2Gr
#10: FoutGr
#11: Instance
#12: Module
#13: Type
#14: Words
#15: Bits
#16: X_addr
#17: Y_addr
#18: X_size
#19: Y_size
#20: Repair
#21: Clk1
#22: Clk2
#23: MB_CLK
#24: Nma
#25: Rs
#26: Bwn
#27: Fbm
#28: Test
#29: Xaxis
#30: Yaxis
#31: Domain
#32: Cap
#33: Disturb
#34: Fav
#35: PwsTep
#36: PVname
#37: layername
#38: FoutBufPlace
#39: MemE
	set fid [open $FILE "r"]
	while {[gets $fid str]>=0} {
		if {[regexp {No} $str]} {continue}
		set INFO  [split $str ","]
		set NO        [lindex $INFO 0]
		set ApgGr     [lindex $INFO 2]
		set EncGr     [lindex $INFO 3]
		set RamGr     [lindex $INFO 4]
		set RepairGr1 [lindex $INFO 5]
		set RepairGr2 [lindex $INFO 6]
		set FuseRegGr [lindex $INFO 7]
		set Type      [lindex $INFO 13]
		set MB_CLK    [lindex $INFO 23]
		set Instance  [lindex $INFO 11] ;# MB_ApgGr2_MB_CLKH_apg 
		set tmpModule [lindex $INFO 12]
		if {$Type == "SP"} {set Type "spram"}
		if {$Type == "DP"} {set Type "dpram"}
		if {$Type == "ROM"} {set Type "rom"}
		set ENCTL [format "%04d" $EncGr]
		set BRIDG [format "%04d" $RamGr]
		set INST  [lindex [split $Instance "."] 0]
		regsub -all {\.} $Instance {/} RAM
		set tmpMACRO [get_cells -q ${RAM}/i*/i*]
		if {$tmpMACRO == ""} {
			set MACRO [get_object_name [get_cells -q ${RAM}/*/* -filter ref_name=~"Amc*"]]
		} else {
			set MACRO [get_object_name $tmpMACRO]
		}
		set Module "[string range $tmpModule 0 [expr [string length $tmpModule] - 2]]*"
		set instApg   [get_object_name [get_cells -h "MB_ApgGr${ApgGr}_${MB_CLK}_apg"]]
		set instEncGr [get_object_name [get_cells -h "MB_ApgGr${ApgGr}_${MB_CLK}_Enctrl${ENCTL}_enctrl_${Type}_vmc_pl"]]
		set instRamGr [get_object_name [get_cells -h "MB_ApgGr${ApgGr}_${MB_CLK}_Bridge${BRIDG}_*"]]
		set REF       [get_attribute [get_cells $MACRO] ref_name]
		puts {}
		puts "##############################################################################################"
		puts "# ($NO)"
		puts "# Apg  ([format "%3d" $ApgGr]): $instApg"
		puts "# EncGr([format "%3d" $EncGr]): $instEncGr"
		puts "# RamGr([format "%3d" $RamGr]): $instRamGr"
		puts "# macro     : ${MACRO} ($REF)"
		set pinCLOCKS [get_object_name [get_pins ${MACRO}/* -filter is_clock_pin==true]]
		foreach pin $pinCLOCKS {
			set CLOCKS    [get_object_name [get_attribute [get_pins $pin] clocks]]
			puts "# MB_CLK    : ${pinCLOCKS} ($CLOCKS)"
		}
		puts "##############################################################################################"

		if {$CHECK == "true"} {
		# REPORT #
		set clkWBT [get_clocks MB_DC_TT_TR]
		set st_WBT [get_pins -of [get_cells ${instWBST}/*/* -filter is_sequential==true] -filter pin_direction==out]
		set ed_WBT [get_pins -of [get_cells ${instWBST}/*/* -filter is_sequential==true] -filter is_data_pin==true]
		set st_Apg [get_pins -of [get_cells ${instApg}/*    -filter is_sequential==true] -filter pin_direction==out]
		set ed_Apg [get_pins -of [get_cells ${instApg}/*    -filter is_sequential==true] -filter is_data_pin==true]
		set st_Enc [get_pins -of [get_cells ${instEncGr}/*  -filter is_sequential==true] -filter pin_direction==out]
		set ed_Enc [get_pins -of [get_cells ${instEncGr}/*  -filter is_sequential==true] -filter is_data_pin==true]
		set st_Brg [get_pins -of [get_cells ${instRamGr}/*  -filter is_sequential==true] -filter pin_direction==out]
		set ed_Brg [get_pins -of [get_cells ${instRamGr}/*  -filter is_sequential==true] -filter is_data_pin==true]
		set st_RAM [get_pins -of [get_cells ${MACRO}        -filter is_sequential==true] -filter pin_direction==out]
		set ed_RAM [get_pins -of [get_cells ${MACRO}        -filter is_sequential==true] -filter is_data_pin==true]
		#------
		set timing_report_unconstrained_paths false
		# WBIST -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> Apg ($clk)"
		}
		# WBIST -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> EncGr ($clk)"
		}
		# WBIST -> RamGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> RamGr ($clk)"
		}
		# WBIST -> MACRO
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clkWBT -to $clk -thr $st_WBT -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : WBIST -> MACRO ($clk)"
		}
		#------
		# Apg -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_Apg -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> WBIST ($clk)"
		}
		# Apg -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Apg -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> EncGr ($clk)"
		}
		# Apg -> RamGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Apg -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> RamGr ($clk)"
		}
		# Apg -> MACRO
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Apg -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : Apg -> MACRO ($clk)"
		}

		#------
		# EncGr -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_Enc -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> WBIST ($clk)"
		}
		# EncGr -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Enc -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> Apg ($clk)"
		}
		# EncGr -> RamGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Enc -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> RamGr ($clk)"
		}
		# EncGr -> MACRO
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Enc -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : EncGr -> MACRO ($clk)"
		}

		#------
		# RamGr -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_Brg -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> WBIST ($clk)"
		}
		# RamGr -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Brg -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> Apg ($clk)"
		}
		# RamGr -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Brg -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> EncGr ($clk)"
		}
		# RamGr -> RAM(ROM)
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_Brg -thr $ed_RAM]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : RamGr -> MACRO ($clk)"
		}

		#------
		# RAM(ROM) -> WBIST
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clkWBT -thr $st_RAM -thr $ed_WBT]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> WBIST ($clk)"
		}
		# RAM(ROM) -> Apg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_RAM -thr $ed_Apg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> Apg ($clk)"
		}
		# RAM(ROM) -> EncGr
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_RAM -thr $ed_Enc]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> EncGr ($clk)"
		}
		# RAM(ROM) -> Brg
		foreach clk $CLOCKS {
			set tmg [get_timing_path -from $clk -to $clk -thr $st_RAM -thr $ed_Brg]
			set JDG "NG"; if {[sizeof_collection $tmg] > 0} {set JDG "OK"} ; puts " $JDG : MACRO -> RamGr ($clk)"
		}
		#------
		}

	}
	close $fid
}

proc chkMACROcase {{INST}} {
    suppress_message {ATTR-3}
    puts "-------------------------------------------"
    puts "T0: Tied 1'b0(Vss)"
    puts "T1: Tied 1'b1(Vdd/Vss)"
    puts "C0: Propagated case value '0'"
    puts "C1: Propagated case value '1'"
    puts "-------------------------------------------"
    puts [format " (%s) %-8s %s" case Direction MacroPIN]
    set MACROinst [get_cells $INST]
    set MACROpins [get_pins -of $MACROinst]
    foreach_in_collection pin $MACROpins {
        set Direction [get_attribute $pin pin_direction]
        set Cvalue    [get_attribute $pin case_value]
        set Cconst    [get_attribute $pin constant_value]
        set nameINpin [get_object_name $pin]
        if {$Cconst != ""} {
            set VALUE "T$Cconst"
        } elseif {$Cvalue != ""} {
            set VALUE "C$Cvalue"
        } else {
            set VALUE "--"
        }
        puts [format "   (%s) %-8s %s" $VALUE $Direction $nameINpin]
    }
    puts "-------------------------------------------"
    unsuppress_message {ATTR-3}
}


## For checking clocks have reached, MBIST circuit and RAM.
proc CHK_REACHE_CLK { args }  {
    set FILE_A [lindex $args 0]
    set FILE_B [lindex $args 1]
    if {$FILE_A == "" || $FILE_B == ""} {
        puts "Usage: CHK_REACHE_CLK <PIN_LIST_FILE> <OUTPUT_REPORT>"
        return 0
    }
    
    set PIN_LIST {}
    if {[file isfile ${FILE_A}] == 0} {
        puts "Error : There is no '$FILE_A'... "
    } else {
        puts "* Information : Loading pin file '$FILE_B' for cheking clock_name..."
        set fid_a  [open "$FILE_A"]
        while {[gets $fid_a str]>=0} {
            if {$str != ""} {
                set tmpA [lindex [split $str ","] 0]
                lappend PIN_LIST $tmpA
            }
        }
        close $fid_a
    }

    puts "* Information : Analyzing clock_name..."
    set fid_b [open "$FILE_B" "w"]
    foreach A $PIN_LIST {
        set pin_name [get_pins $A -quiet]
        if {[llength $pin_name] == 0} {
            puts "Error: $A is not found..."
            puts $fid_b "$A,_NOPIN_"
            continue;
        }
        set clock_name [get_attribute $pin_name clocks -quiet]
        if {[llength $clock_name] == 0} {
            puts $fid_b "$A,_NOCLK_"
        } else {
            puts $fid_b "$A,[get_object_name $clock_name]"
        }
    }
    close $fid_b
}

proc mkEdtChainMask_2_1stSIN {} {
	set SCAN_IN       [get_pins -h {*/SIN */SI */SIA */SIB */ADSCAN_IN[*] */SYFP_SCANIN*_G} -filter is_hierarchical==false]
	set SIN_LIB_PIN   [lsort -u [get_attribute $SCAN_IN lib_pin_name]]
	set EDT_MASK_REG  [get_pins -h edt_chain_mask_reg_*/Q*]
		
	proc filter_SIN_only {{PIN_COL} {SIN_LIB_PIN}} {
		set return_value {}
		foreach_in_collection pin $PIN_COL {
			set lib_pin_name [get_attribute $pin lib_pin_name]
			if {[lsearch $SIN_LIB_PIN $lib_pin_name] >= 0} {
				#return $pin
				set return_value [add_to_collection $return_value $pin]
			}
		}	
		return $return_value
	}
	set NumEDT_MASK_REG [sizeof_collection $EDT_MASK_REG]
	set tmp [date]
	set Y [lindex $tmp 4]
	set M [lindex $tmp 1]
	set D [lindex $tmp 2]
	set T [lindex $tmp 3]
	set date "${Y}/${M}/${D} $T"
	puts "######################################"
	puts "# Generated by mkEdtChainMask_2_1stSIN"
	puts "#  $date"
	puts "#  edt_chain_mask_reg_* -> 1stFF/chain"
	puts "#  Number of edt_chain_mask_reg : $NumEDT_MASK_REG"
	puts "######################################"
	set NumDummyChain  0
	set NumNormalChain 0
	set NumZeroFFChain 0
	set NumErrorChain  0
	set NormalChain_LIST {}
	set ZeroChain_LIST   {}
	set DummyChain_LIST  {}
	set ErrorChain_LIST  {}
	foreach_in_collection pin $EDT_MASK_REG {
		set st_clk        [get_pins -of [get_cells -of $pin] -filter is_clock_pin]
		set ALL_FOUT_LEAF [all_fanout -from $pin -flat -endpoints_only] 
		set SIN_COLL      [filter_SIN_only $ALL_FOUT_LEAF $SIN_LIB_PIN]
		set num_SIN_COLL  [sizeof_collection $SIN_COLL]
		set st_name       [get_object_name $st_clk]
		set st_name_q     [get_object_name $pin]
		set ed_name       [get_object_name $SIN_COLL]
		set string_N "set_false_path -from \[get_pins $st_name\] -to \[get_pins \{$ed_name\}\]"

		if {$num_SIN_COLL == 1} {
			incr NumNormalChain
			lappend NormalChain_LIST $string_N
		} elseif {$num_SIN_COLL == 2} {
			incr NumDummyChain
			lappend DummyChain_LIST $st_name_q
			set DummyChain($st_name_q) $string_N
		} elseif {$num_SIN_COLL == 0} {
			incr NumZeroFFChain
			lappend ZeroChain_LIST $st_name_q
		} else {
			incr NumErrorChain
			lappend ErrorChain_LIST $st_name_q
			set ErrorChain($st_name_q) $ed_name
		}
		#puts "set_false_path -from \[get_pins $st_name\] -to \[get_pins \{$ed_name\}\]"
	}
	if {$NumEDT_MASK_REG == [expr $NumNormalChain + $NumDummyChain]} {
		set result "OK"
	} else {
		set result "Error!"
	}
	if {$NumZeroFFChain > 0} {
		set NumZeroFFChain "Error! $NumZeroFFChain"
	} else {
		set NumZeroFFChain "$NumZeroFFChain ...OK"
	}
	if {$NumErrorChain  > 0} {
		set NumErrorChain  "Error! $NumErrorChain"
	} else {
		set NumErrorChain  "$NumErrorChain ...OK"
	}
	puts "# (E) 1 to 0    : $NumZeroFFChain"
	foreach tmp $ZeroChain_LIST  {puts "#Error: $tmp"}

	puts "# (E) 1 to many : $NumErrorChain"
	foreach tmp $ErrorChain_LIST {
		puts "#Error: $tmp"
		foreach tmp2 $ErrorChain($tmp) { puts "        -> $tmp2" }
	}

	puts "# (1) 1 to 1    : $NumNormalChain"
	puts "# (2) 1 to 2    : $NumDummyChain"
	puts {}
	puts "# Result        : $result"
	puts "######################################"
	puts "#<< Type: 1 to 1 >>"
	foreach tmp $NormalChain_LIST     {puts $tmp}
	puts "#<< Type: 1 to 2 >>"
	foreach tmp $DummyChain_LIST {puts $DummyChain($tmp)}
}

