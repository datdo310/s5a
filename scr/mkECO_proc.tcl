proc chk_ECO_size {{COMMAND_FILE}} {
	set DRC [READ_LISTFILE $COMMAND_FILE]
	set OUTFILE [open "${COMMAND_FILE}.result" "w"]
	set OUTFILE2 [open "${COMMAND_FILE}.renew" "w"]
	
	set pitch 0.15
	set hight 7.0
	set k     [expr 7.0 * 0.15 * 0.15]
	
	set nu 0
	set total 0.0
	foreach tmp $DRC {
		set INST    [lindex $tmp 1]
		set REF_NEW [lindex $tmp 2]
		set ORG     [get_attribute [get_cells $INST] area]
		set PITCH_ORG [expr $ORG / $k]
		set NEW     [get_attribute [get_lib_cells */$REF_NEW] area]
		set PITCH_NEW [expr $NEW / $k]
		set DIFF    [expr $PITCH_NEW - $PITCH_ORG]
	
		puts $OUTFILE  [format "%2.0f (%15s) %s" $DIFF $REF_NEW $INST]
		puts $OUTFILE2 "$DIFF size_cell \{$INST\} \{$REF_NEW\}"
		set total [expr $total + $DIFF]
		incr nu
	}
	close $OUTFILE
	close $OUTFILE2
	
	puts "total : ($nu) +$total"
	sh sort -n +0 ${COMMAND_FILE}.result | awk \'{print \$1}\'|uniq -c
}

proc REPEATER_SKEWED_FANOUT { {HEADER ECOXX_SKEWEDFANOUT} {OUT_COMMAND cmdXX.SKEWED_REPEATER} {MAX_FANOUT 16} {INV_CELL TMHINVX40} {DIVIDE_RATIO 0.334} } {

    ## Get skewed pins from reports
    if {[catch "glob ls ./Report/skewed.*" skewedfiles]} {
        puts "  # Error:        No constraint file for atribute '$CODE'."
        nop
        nop
        continue
    }
    foreach file $skewedfiles {
        puts "  $file"
        set FILE_EX [file extension $file]
        if {$FILE_EX == ".bz2"} {
            set fid  [open "|bzip2 -dc $file"]
        } elseif {$FILE_EX == ".gz"} {
            set fid  [open "|gzip -dc $file"]
        } else {
            set fid  [open $file]
        }
        while {[gets $fid str]>=0} {
            #puts [subst $str]
            if {[regexp "^#" $str]} { continue }
            lappend all_pins [lindex $str 0]
        }
        close $fid
    }
    set all_pins [lsort -dictionary -ascii -unique $all_pins]

    set all_drv {}
    foreach pin $all_pins {
        #puts "$pin"
        set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]
    }
    set ofid [open $OUT_COMMAND "w"]
    set num 1
    foreach_in_collection pin $all_drv {
        #puts "[get_object_name $pin]"
        set fanout_num [sizeof_collection [remove_from_collection [all_connected -l [all_connected [get_pins $pin]]] [get_pins $pin]]]
        if {$fanout_num > $MAX_FANOUT} {
            set pnum [format "%05d" $num]
            puts            $ofid "# [get_object_name $pin] fanout $fanout_num"
            puts -nonewline $ofid "add_buffer_on_route -inverter_pair -repeater_distance_length_ratio ${DIVIDE_RATIO} -no_legalize -no_eco_route "
            puts -nonewline $ofid "-net_prefix  n_${HEADER}_${pnum} -cell_prefix i_${HEADER}_${pnum} "
            puts            $ofid "\[get_nets -of \[get_pins [get_object_name $pin]\]\] ${INV_CELL}"
            puts $ofid ""
            incr num
        }

    }
    close $ofid

}


proc REPEATER_XTALK_FANOUT { {HEADER ECOXX_XTALKREPEATER} {OUT_COMMAND cmdXX.XTALK_REPEATER} {MAX_CAP 0.10} {INV_CELL TMHINVX40} {DIVIDE_RATIO 0.334} } {

    ## Get Xtalk pins from reports
    if {[catch "glob ls ./result.xtalk/??_DD*_*.csv" xtalksumfiles]} {
        puts "  # Error:        No constraint file for atribute '$CODE'."
        nop
        nop
        continue
    }
    set all_pins {}
    foreach file $xtalksumfiles {
        puts "  $file"
        set FILE_EX [file extension $file]
        if {$FILE_EX == ".bz2"} {
            set fid  [open "|bzip2 -dc $file"]
        } elseif {$FILE_EX == ".gz"} {
            set fid  [open "|gzip -dc $file"]
        } else {
            set fid  [open $file]
        }
        set mflg 0
        while {[gets $fid str]>=0} {
            #puts [subst $str]
            if {[regexp "^#" $str]} { continue }
            if {[regexp "^Num," $str]} {
                set mflg 1;
            } elseif {[regexp "^$" $str] } {
                set mflg 0;
            } elseif {$mflg == 1} {
                regsub -all {,} $str { } str
                lappend all_pins [lindex $str 1]
            }
        }
        close $fid
    }
    set all_pins [lsort -dictionary -ascii -unique $all_pins]

    set all_drv {}
    foreach pin $all_pins {
        #puts "$pin"
        set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]

    }
    set ofid [open $OUT_COMMAND "w"]
    set num 1
    foreach_in_collection pin $all_drv {
        #puts "[get_object_name $pin]"
        set capacitance [get_attribute [get_pins $pin] effective_capacitance_max]
        set drvcell	[get_attribute [get_cells -of [get_pins $pin] ] ref_name]
        if {$capacitance > $MAX_CAP} {
            set pnum [format "%05d" $num]
            puts $ofid "# [get_object_name $pin] cap:$capacitance driver:$drvcell"
            puts -nonewline $ofid "add_buffer_on_route -inverter_pair -repeater_distance_length_ratio ${DIVIDE_RATIO} -no_legalize -no_eco_route"
            puts -nonewline $ofid " -net_prefix  n_${HEADER}_${pnum} -cell_prefix i_${HEADER}_${pnum} "
            puts            $ofid " \[get_nets \-of \[get_pins [get_object_name $pin]\]\] ${INV_CELL}"
            puts $ofid ""
            incr num
        } else {
            puts $ofid "# Out_Of_Target [get_object_name $pin] cap:$capacitance driver:$drvcell"
        }
    }
    close $ofid

}

proc UPSIZE_TRAN     { {MAXSIZE 80} {OUT_COMMAND cmdXX.TRAN_UPSIZE} {UPSIZE_STEP 10} }  {
    ## Get maxtran pins from reports
    if {[catch "glob ls ./result.const/??_tran_*.csv ./result.const/??_cap_*.csv" transumfiles]} {
        puts "  # Error:        No constraint file for atribute '$CODE'."
        nop
        nop
        continue
    }
    set all_pins {}
    foreach file $transumfiles {
        if {![string match "*_clkpin_*" $file] && ![string match "*_lowdrv_*" $file]} {
            puts "  $file"
            set FILE_EX [file extension $file]
            if {$FILE_EX == ".bz2"} {
                set fid  [open "|bzip2 -dc $file"]
            } elseif {$FILE_EX == ".gz"} {
                set fid  [open "|gzip -dc $file"]
            } else {
                set fid  [open $file]
            }
            set mflg 0
            while {[gets $fid str]>=0} {
                #puts [subst $str]
                if {[regexp "^#" $str]} { continue }
                if {[regexp "^TOTAL" $str]} { continue }
                if {[regexp "^Num," $str]} {
                    set mflg 1;
                } elseif {[regexp "^$" $str] } {
                    set mflg 0;
                } elseif {$mflg == 1 && [regexp ",VIO," $str]} {
                    regsub -all {,} $str { } str
                    lappend all_pins [lindex $str 1]
                }
            }
            close $fid
        }
    }
    set all_pins [lsort -dictionary -ascii -unique $all_pins]

    set all_drv {}
    foreach pin $all_pins {
        #puts "$pin"
        set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]
    }
    set ofid [open $OUT_COMMAND "w"]
    set num 1
    foreach_in_collection pin $all_drv {
        #puts "[get_object_name $pin]"
        set net_name [get_net -of_objects [get_pins $pin]]
        set capacitance_wire [get_attribute [get_net $net_name] wire_capacitance_max]
        set capacitance_eff  [get_attribute -q [get_pins $pin] effective_capacitance_max]
        if {$capacitance_wire > $capacitance_eff} {
            set capacitance $capacitance_wire
        } else {
            set capacitance $capacitance_eff
        }
        set drvcell     [get_attribute [get_cells -of [get_pins $pin] ] ref_name]
        set newcell     [UPSIZE_CELL $drvcell $MAXSIZE $UPSIZE_STEP]
        set inst        [get_object_name [get_cells -of [get_pins $pin]]]
        if {![string match $drvcell $newcell]} {
            puts $ofid "size_cell $inst $newcell ;# $drvcell";
        } else {
            puts $ofid "# Out_Of_Target inst cap:$capacitance driver:$drvcell"
        }
    }
    close $ofid
}

proc UPSIZE_CELL { {CELLNAME} {MAXSIZE 80} {UPSIZE_STEP 10} } {
    if {[string match "RV40F" $::PROCESS] || [string match "RV28F" $::PROCESS]} {
        if {[regexp {^THH} $CELLNAME] || [regexp {^TMH} $CELLNAME] || [regexp {^TSH} $CELLNAME]
            || [regexp {^TWH} $CELLNAME] || [regexp {^TLH} $CELLNAME] || [regexp {^TULH} $CELLNAME]} {
            regsub -all ".*X" $CELLNAME "" CELLDRV
            if {[string match  "0*" $CELLDRV]} {
                set NEWDRV 10
            } elseif {$CELLDRV <= $MAXSIZE } {
                set NEWDRV [expr $CELLDRV + $UPSIZE_STEP]
            } else {
                return $CELLNAME
            }
            for {set NEWDRV $NEWDRV } {$NEWDRV <= $MAXSIZE} { set NEWDRV [expr $NEWDRV + $UPSIZE_STEP] } {
                regsub "X${CELLDRV}" $CELLNAME "X$NEWDRV" NEWCELL
                if {[get_lib_cells -q */${NEWCELL}] != ""} {
                    return $NEWCELL
                }
            }
            return $CELLNAME
        } elseif { [regexp {P140HVT$} $CELLNAME] || [regexp {P140$} $CELLNAME] || [regexp {P140ULVT$} $CELLNAME] } {
            set MAXSIZE [expr $MAXSIZE / 10]
            set UPSIZE_STEP [expr $UPSIZE_STEP / 10]
            regexp {\w+D(\d+)BWP\w+} $CELLNAME match CELLDRV
            if {[string match "0*" $CELLDRV]} {
                set NEWDRV 1
            } elseif {$CELLDRV <= $MAXSIZE} {
                set NEWDRV [expr $CELLDRV + $UPSIZE_STEP]
            } else {
                return $CELLNAME
            }
            for {set NEWDRV $NEWDRV } {$NEWDRV <= $MAXSIZE} { set NEWDRV [expr $NEWDRV + $UPSIZE_STEP] } {
                regsub {D\d+BWP} $CELLNAME "D${NEWDRV}BWP" NEWCELL
                if {[get_lib_cells -q */${NEWCELL}] != ""} {
                    return $NEWCELL
                }
            }
            return $CELLNAME
        } else {
            puts "* Warning: \$CELLNAME is not standard cell($CELLNAME)."
        }
    } else {
        puts "* Error: \$PROCESS is not set or supported(RV40F/RV28F)."
    }
}

proc REPEATER_TRAN_FANOUT { {HEADER ECOXX_TRANREPEATER} {OUT_COMMAND cmdXX.TRAN_REPEATER} {MAX_CAP 0.16} {INV_CELL THHINVZHX40} {DIVIDE_RATIO 0.334} } {

    ## Get maxtran pins from reports
    if {[catch "glob ls ./result.const/??_tran_*.csv ./result.const/??_cap_*.csv" transumfiles]} {
        puts "  # Error:        No constraint file for atribute '$CODE'."
        nop
        nop
        continue
    }
    set all_pins {}
    foreach file $transumfiles {
        if {![string match "*_clkpin_*" $file] && ![string match "*_lowdrv_*" $file]} {
            puts "  $file"
            set FILE_EX [file extension $file]
            if {$FILE_EX == ".bz2"} {
                set fid  [open "|bzip2 -dc $file"]
            } elseif {$FILE_EX == ".gz"} {
                set fid  [open "|gzip -dc $file"]
            } else {
                set fid  [open $file]
            }
            set mflg 0
            while {[gets $fid str]>=0} {
                #puts [subst $str]
                if {[regexp "^#" $str]} { continue }
                if {[regexp "^TOTAL" $str]} { continue }
                if {[regexp "^Num," $str]} {
                    set mflg 1;
                } elseif {[regexp "^$" $str] } {
                    set mflg 0;
                } elseif {$mflg == 1 && [regexp ",VIO," $str]} {
                    regsub -all {,} $str { } str
                    lappend all_pins [lindex $str 1]
                }
            }
            close $fid
        }
    }
    set all_pins [lsort -dictionary -ascii -unique $all_pins]

    set all_drv {}
    foreach pin $all_pins {
        #puts "$pin"
        set all_drv [add_to_collection $all_drv [get_pins  [all_connected -l [all_connected [get_pins $pin]]] -filter "direction==out"] -unique]

    }
    set ofid [open $OUT_COMMAND "w"]
    set num 1
    foreach_in_collection pin $all_drv {
        #puts "[get_object_name $pin]"
        set net_name [get_net -of_objects [get_pins $pin]]
        set capacitance_wire [get_attribute [get_net $net_name] wire_capacitance_max]
        set capacitance_eff  [get_attribute -q [get_pins $pin] effective_capacitance_max]
        if {$capacitance_wire > $capacitance_eff} {
            set capacitance $capacitance_wire
        } else {
            set capacitance $capacitance_eff
        }
        set drvcell     [get_attribute [get_cells -of [get_pins $pin] ] ref_name]
        if {$capacitance > $MAX_CAP} {
            set pnum [format "%05d" $num]
            puts $ofid "# [get_object_name $pin] cap:$capacitance driver:$drvcell"
            puts -nonewline $ofid "add_buffer_on_route -inverter_pair -repeater_distance_length_ratio ${DIVIDE_RATIO} -no_legalize -no_eco_route"
            puts -nonewline $ofid " -net_prefix  n_${HEADER}_${pnum} -cell_prefix i_${HEADER}_${pnum} "
            puts            $ofid " \[get_nets \-of \[get_pins [get_object_name $pin]\]\] ${INV_CELL}"
            puts $ofid ""
            incr num
        } else {
            puts $ofid "# Out_Of_Target [get_object_name $pin] cap:$capacitance driver:$drvcell"
        }
    }
    close $ofid

}

proc CHK_KEEP_DONTTOUCH { {keep_dir null} {dont_dir null} } {
    if {[regexp "null" $keep_dir] || [regexp "null" $dont_dir]} {
        puts {Error: CHK_KEEP_DONTTOUCH $KEEP_LIST_DIRECTORY $DONT_TOUCH_DIRECTORY}
    } elseif {![file exists $keep_dir] || ![file exists $dont_dir]} {
        if {![file exists $keep_dir]} {
            puts "Error: Cannot find $keep_dir as \$KEEP_LIST_DIRECTORY"
        }
        if {![file exists $dont_dir]} {
            puts "Error: Cannot find $dont_dir as \$DONT_TOUCH_DIRECTORY"
        }
    } else {
        set out_dir  keep_log
        set cwd      [pwd]
        set overview 00_OVERVIEW.list

        DIR_CHECK $out_dir
        set OK_LOGS {}
        set NG_LOGS {}

        foreach cell_file [glob ${keep_dir}/*.list ${dont_dir}/*_dont_touch_cell.list] {
            puts "Information(cell_check): $cell_file"

            set  ng_flg  0;
            set  base_name [regsub {.*/} $cell_file {}];
            set  rfp [open $cell_file "r"]
            redirect ${out_dir}/${base_name}.log {
                puts "# Check $cell_file"
                while {[gets $rfp str]>=0} {
                    if {[regexp "^ *\#" $str] || [regexp "^ *$" $str]} {
                        continue
                    }
                    if {[regexp {\*} $str ]} {
                        puts "NG(\*): $str"
                        set ng_flg 1
                    }
                    set  hit_cells [get_cells -q $str]
                    if {[sizeof_collection $hit_cells] == 0} {
                        puts "NG(NoCell): $str"
                        set ng_flg 1
                    } else {
                        foreach_in_collection hit_cell $hit_cells {
                            if {[get_attribute $hit_cell is_hierarchical] == "true"} {
                                puts "OK(hier): [get_object_name $hit_cell]"
                            } else {
                                puts "OK(inst): [get_object_name $hit_cell]"
                            }
                        }
                    }
                }
            }
            close $rfp
            if {$ng_flg>0} {
                lappend NG_LOGS ${cwd}/${out_dir}/${base_name}.log
            } else {
                lappend OK_LOGS ${cwd}/${out_dir}/${base_name}.log
            }
        }

        foreach net_file [glob ${dont_dir}/*dont_touch_net.list ${dont_dir}/*dont_touch_net_seg.list] {
            puts "Information(net_check): $net_file"

            set  ng_flg  0;
            set  base_name [regsub {.*/} $net_file {}];
            set  rfp [open $net_file "r"]
            redirect ${out_dir}/${base_name}.log {
                puts "# Check $net_file"
                while {[gets $rfp str]>=0} {
                    if {[regexp "^ *\#" $str] || [regexp "^ *$" $str]} {
                        continue
                    }
                    if {[regexp {\*} $str ]} {
                        puts "NG(\*): $str"
                        set  ng_flg  1;
                    }
                    set  hit_nets [get_nets -q $str]
                    if {[sizeof_collection $hit_nets] == 0} {
                        puts "NG(NoNet): $str"
                        set  ng_flg  1;
                    } else {
                        foreach_in_collection hit_net $hit_nets {
                            puts "OK(inst): [get_object_name $hit_net]"
                        }
                    }
                }
            }
            close $rfp
            if {$ng_flg>0} {
                lappend NG_LOGS ${cwd}/${out_dir}/${base_name}.log
            } else {
                lappend OK_LOGS ${cwd}/${out_dir}/${base_name}.log
            }
        }

        foreach network_file [glob ${dont_dir}/*_from_network.list] {
            puts "Information(network_check): $network_file"

            set  ng_flg  0;
            set  base_name [regsub {.*/} $network_file {}];
            set  rfp [open $network_file "r"]
            redirect ${out_dir}/${base_name}.log {
                puts "# Check $network_file"
                while {[gets $rfp str]>=0} {
                    if {[regexp "^ *\#" $str] || [regexp "^ *$" $str]} {
                        continue
                    }
                    if {[regexp {\*} $str ]} {
                        puts "NG(\*): $str"
                        set  ng_flg  1;
                    }
                    set  hit_pins [get_pins -q $str]
                    if {[sizeof_collection $hit_pins] == 0} {
                        puts "NG(NoNetwork): $str"
                        set  ng_flg  1;
                    } else {
                        foreach_in_collection hit_pin $hit_pins {
                            if {[get_attribute $hit_pin is_hierarchical] == "true"} {
                                puts "OK(hierpin): [get_object_name $hit_pin]"
                            } else {
                                puts "OK(instpin): [get_object_name $hit_pin]"
                            }
                        }
                    }
                }
            }
            close $rfp
            if {$ng_flg>0} {
                lappend NG_LOGS ${cwd}/${out_dir}/${base_name}.log
            } else {
                lappend OK_LOGS ${cwd}/${out_dir}/${base_name}.log
            }
        }

        redirect ${out_dir}/${overview} {
            foreach NG_LOG $NG_LOGS {
                puts "NG: $NG_LOG"
            }
            puts ""
            foreach OK_LOG $OK_LOGS {
                puts "OK: $OK_LOG"
            }
        }
    }
}
proc MKDOWNSIZETCL { { INST_FILE } { OUT_TCL } {MAX_DRV 80} {MIN_DRV 40} {MAX_CAP 0.005} { INFO_DIR ./Info_Critical_Pins }  } {
    set fid  [open $INST_FILE]
    set ofid [open $OUT_TCL "w"]
    set DRV_STEP 10;	# Step for decrease drivability
    DONTTOUCH_CLOCK $INFO_DIR
    while {[gets $fid str]>=0} {
        if {[regexp "^#" $str]}	{ continue }
        set inst [get_cells -q $str -filter "is_combinational==true"]
        if {$inst == ""}	{ continue }
        if {[get_attribute -q $inst dont_touch] == "true"}	{ continue }
        set DRVCELL [get_attribute $inst ref_name ]
        regsub -all ".*X" $DRVCELL {} DRV
        set outpin [get_pins -of $inst -filter "direction==out"]
        set net_name [get_object_name [all_connected $outpin]]

        set capacitance_wire [get_attribute [get_net $net_name] wire_capacitance_max]
        set capacitance_eff  [get_attribute -q [get_pins $outpin] effective_capacitance_max]
        if {$capacitance_wire > $capacitance_eff} {
            set capacitance $capacitance_wire
        } else {
            set capacitance $capacitance_eff
        }
        if {$capacitance < $MAX_CAP} {
            set NEWCELL [DOWNSIZECELL $DRVCELL $MAX_DRV $MIN_DRV $DRV_STEP]
            if {$NEWCELL != "0"} {
                puts $ofid "size_cell [get_object_name $inst] $NEWCELL	;# $DRVCELL Cap:$capacitance"
            }
        }
    }
    close $fid
    close $ofid
}

proc DOWNSIZECELL { {CELL} {MAX_DRV 80} {MIN_DRV 40} {DRV_STEP 10} } {
    if {[string match "RV40F" $::PROCESS] || [string match "RV28F" $::PROCESS]} {
        if {[regexp {^THH} $CELL] || [regexp {^TMH} $CELL] || [regexp {^TSH} $CELL]
            || [regexp {^TWH} $CELL] || [regexp {^TLH} $CELL] || [regexp {^TULH} $CELL]} {
            regsub -all ".*X" $CELL {} DRV
            if { $DRV <= $MIN_DRV } {
                return 0
            } else {
                if {$DRV > $MAX_DRV} {
                    set NEWDRV $MAX_DRV
                } else {
                    set NEWDRV [expr $DRV - $DRV_STEP]
                }
            }
            regsub "$DRV" $CELL "$NEWDRV" NEWCELL
            set CELL_CHECK_FLG [get_lib_cells -q */$NEWCELL]
            while {$CELL_CHECK_FLG==""} {
                set NEWDRV [expr $NEWDRV - $DRV_STEP]
                regsub "$DRV" $CELL "$NEWDRV" NEWCELL
                set CELL_CHECK_FLG [get_lib_cells -q */$NEWCELL]
            }
            if {$NEWDRV >= $MIN_DRV} {
                return $NEWCELL
            } else {
                return 0
            }
        } elseif {[regexp {P140HVT$} $CELL] || [regexp {P140$} $CELL] || [regexp {P140ULVT$} $CELL]} {
            set MAX_DRV [expr $MAX_DRV / 10]
            set MIN_DRV [expr $MIN_DRV / 10]
            set DRV_STEP [expr $DRV_STEP / 10]
            regexp {\w+D(\d+)BWP\w+} $CELL match DRV
            if { $DRV <= $MIN_DRV } {
                return 0
            } else {
                if {$DRV > $MAX_DRV} {
                    set NEWDRV $MAX_DRV
                } else {
                    set NEWDRV [expr $DRV - $DRV_STEP]
                }
            }
            regsub {D\d+BWP} $CELL "D${NEWDRV}BWP" NEWCELL
            set CELL_CHECK_FLG [get_lib_cells -q */$NEWCELL]
            while {$CELL_CHECK_FLG==""} {
                set NEWDRV [expr $NEWDRV - $DRV_STEP]
                regsub {D\d+BWP} $CELL "D${NEWDRV}BWP" NEWCELL
                set CELL_CHECK_FLG [get_lib_cells -q */$NEWCELL]
            }
            if {$NEWDRV >= $MIN_DRV} {
                return $NEWCELL
            } else {
                return 0
            }
        } else {
            puts "* Warning: \$CELLNAME is not standard cell($CELLNAME)."
        }
    } else {
        puts "* Error: \$PROCESS is not set or supported(RV40F/RV28F)."
    }
}
proc DONTTOUCH_CLOCK { {DIR_INFO ../Info_Critical_Pins} } {
    puts "Information: Search clocklist to apply donttouch cells"
    if {[catch "glob ls ${DIR_INFO}/*.clocklist.gz" files]} {
        puts "  # Error:        No clocklist file for apply dont_touch"
        continue
    }
    foreach file $files {
        puts "  $file"
        set FILE_EX [file extension $file]
        if {$FILE_EX == ".bz2"} {
            set fid  [open "|bzip2 -dc $file"]
        } elseif {$FILE_EX == ".gz"} {
            set fid  [open "|gzip -dc $file"]
        } else {
            set fid  [open $file]
        }
        while {[gets $fid str]>=0} {
            #puts "[lindex $str 0]"
            set_dont_touch [get_cells [lindex $str 0]]
        }
        close $fid
    }
}

