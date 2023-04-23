
suppress_message UITE-416

if { !([info exists SYNC_FF_LIST]  && ($SYNC_FF_LIST  ne "")) } { puts "Error: Variable \"SYNC_FF_LIST\" is required."  ; set flg 1 ; }
if { !([info exists OUT_INFO_FILE] && ($OUT_INFO_FILE ne "")) } { puts "Error: Variable \"OUT_INFO_FILE\" is required." ; set flg 1 ; }
if { !([info exists OUT_SIZE_TCL]  && ($OUT_SIZE_TCL  ne "")) } { puts "Error: Variable \"OUT_SIZE_TCL\" is required."  ; set flg 1 ; }
if { [info exists flg] && $flg } { unset flg ; return ; }

#### update for RV28FT(7T) on 2020/11/27 ####
#### 29/07/2021 : RVC/Hung Pham update for more correct in U2B6

###
set fi [open $SYNC_FF_LIST  r]
set fo [open $OUT_INFO_FILE w]
set fs [open $OUT_SIZE_TCL  w]

set n [string length [lindex [exec wc -l $SYNC_FF_LIST] 0]]

if { [info exists OUT_ANNO] && ($OUT_ANNO ne "") } {
    set anno_flg 1
    echo -n "" > $OUT_ANNO

    if { [info exists HALF_LIST] && ($HALF_LIST ne "") } {
        set tri_flg 1
        set ft [open $HALF_LIST r]
        if { [info exists anno_half_list] } { unset anno_half_list }
        while { [gets $ft line] >= 0 } {
            if { $line ne "" } { lappend anno_half_list [lindex $line 0] }
        }
        unset line
        close $ft
    } else { set tri_flg 0 }
} else { set anno_flg 0 }

set date [date]

if { [file type $SYNC_FF_LIST] eq "link" } {
    set tmp_file [file readlink $SYNC_FF_LIST]
    if { [regexp {^/} $tmp_file] } {
        set file $tmp_file
    } else {
        set file [file dirname $SYNC_FF_LIST]/$tmp_file
    }
} else {
    set file $SYNC_FF_LIST
}

puts $fo "# Created at $date"
puts $fo "# SyncFF List: $SYNC_FF_LIST ([clock format [file mtime $file]])"

puts $fs "# Created at $date"
puts $fs "# SyncFF List: $SYNC_FF_LIST ([clock format [file mtime $file]])"

if { ![info exists SESSION] }                                         { set SESSION  "" }
if { [info exists ENABLE_READ_SDC] && ($ENABLE_READ_SDC eq "false") } { set FILE_SDC "" }

puts $fo "#     Session: $SESSION"
puts $fo "#     Netlist: $NET_SRC"
puts $fo "#         SDC: $FILE_SDC\n"
puts $fs "#     Session: $SESSION"
puts $fs "#     Netlist: $NET_SRC"
puts $fs "#         SDC: $FILE_SDC\n"

puts $fo "No,FF,org_slack,org_ref,new_ref,slack(w/Meta),fastest clk,period,all clocks,comment"

unset file
if { [info exists tmp_file] } { unset tmp_file }

### metas time

proc getMetasTime { cell } {
    switch -glob $cell {
        SDFSYNCNQD*BWP7T40P140HVT   { set d  3.00 }
        SDFSYNCNQD*BWP7T40P140      { set d  1.60 }
        SDFSYNCNQD*BWP7T40P140ULVT  { set d  0.90 }
        SDFSYNQD*BWP7T40P140HVT     { set d  3.30 }
        SDFSYNQD*BWP7T40P140        { set d  1.80 }
        SDFSYNQD*BWP7T40P140ULVT    { set d  0.90 }
        SDFSYNSNQD*BWP7T40P140HVT   { set d  2.60 }
        SDFSYNSNQD*BWP7T40P140      { set d  1.30 }
        SDFSYNSNQD*BWP7T40P140ULVT  { set d  0.80 }
        *DF*D*BWP7T40P140HVT        { set d 36.00 }
        *DF*D*BWP7T40P140           { set d 34.10 }
        *DF*D*BWP7T40P140ULVT       { set d  9.30 }
        T5CDFF*           { set d  8.70 }
        T5CSDFF*          { set d  8.70 }
        default           { set d "---" }
    }
    return $d
}

proc writeAnno { inst cell file flg flgc } {
    set d [getMetasTime $cell]
    set i [get_object_name [get_pins -of [get_cells $inst] -filter "pin_direction==in && is_clock_pin==true"]]
#   set i [get_object_name [get_pins -of [get_cells $inst] -filter "lib_pin_name=~*CLK*"]]
    set o [get_object_name [get_pins -of [get_cells $inst] -filter "pin_direction==out"]]
    foreach x $o {
        if { !$flg } {
            if { $flgc } { echo -n "# " >> $file }
            echo "set_annotated_delay -max -from \[get_pins $i\] -to \[get_pins $x\] $d -cell -increment" >> $file
        } else {
            echo "# HALF set_annotated_delay -max -from \[get_pins $i\] -to \[get_pins $x\] $d -cell -increment" >> $file
            if { $flgc } { echo -n "# " >> $file }
            echo "set_annotated_delay -max -from \[get_pins $i\] -to \[get_pins $x\] [expr $d/2.0] -cell -increment ;# HALF" >> $file
        }
    }
}

# set ocv derating factor
set derate 1.056

# set TSH -> THH, TLUH -> TSH margin
set margin 0.150

###
set i 0
while { [gets $fi line] >= 0 } {
#    puts "$line"
    if { $line ne "" } {
        incr i
        set inst [lindex [regsub -- {get_cells} $line {}] 0]
#        puts "[format %05d $i] $inst" ;# debug
        set xx   [get_cells -quiet $inst]
        if { $xx eq "" } {
            puts $fo "[format %0${n}d $i],$inst,,,,,,,,Error: No cell objects matched"
        } else {
          set half_flg 0
          if { [info exists tri_flg] && $tri_flg } {
              if { [lsearch $anno_half_list $inst] != -1 } { set half_flg 1 }
          }

          # initial value
          set clk     ""
          set peri    ""
          set cfast   ""
          set newcell ""
          set msg     ""
          set mslack  infinity

          set pin    [get_pins -of $xx -filter "pin_direction==in && is_clock_pin==true"]
#         set pin    [get_pins -of $xx -filter "lib_pin_name =~ *CLK*"]
          set cell   [get_attribute $xx ref_name]
          set ocell $cell

          set tim    [get_timing_paths -from $pin]
          set slack  [get_attribute -quiet $tim slack]
          set tmpclk [get_attribute -quiet $pin clocks]

          if { $tmpclk ne "" } {
              set clk   [get_object_name [sort_collection $tmpclk period]]
              set cfast [lindex $clk 0]
              set peri  [get_attribute [get_clocks $cfast] period]
          }

          if { $slack == infinity || $slack eq "" } {
        # no_path/unconst_path
              if { [get_pins -quiet -of $xx -filter "is_clock_pin==true"] == "" } {
                  set c   [get_attribute $pin case_value]
                  set msg "Error: no_clock(case_value($c))"
              } else {
                  if { $tmpclk eq "" } {
                      set msg "Error: no_clock"
                  } else {
                      set msg "Error: unconstrained_path"
                  }
              }
              if { $anno_flg } { echo "# Error: There is no timing path from ${inst}." >> $OUT_ANNO }
              if { $slack eq "" } { set slack infinity }
          } else {
        # constrained_path
              set delay [expr [getMetasTime $cell] * $derate]

              if { [string match T5C* $cell] } {
                  # 5V cell
                  set mslack [expr $slack - $delay]
                  set newcell $cell
              } elseif { [string match *DF*D*BWP7T40P140* $cell] } {
                  # Non-MetasFF
                  if { ![string match {SDFSYN*} $cell] } {
                      if { [expr $slack - $delay] > 0 } {
                          set tmpmar 0
                          if { ![string match {*BWP7T40P140HVT} $cell] } {
                              if { [string match {*BWP7T40P140ULVT} $cell] } {
                                  set tmp  [string map {BWP7T40P140ULVT BWP7T40P140} $cell]
                                  set tmpd [expr ([getMetasTime $tmp] + $margin) * $derate]
                                  if { [expr $slack - $tmpd] > 0 } { set cell $tmp ; set tmpmar $margin }
                              }
                              if { [string match {*BWP7T40P140} $cell] } {
                                  set tmp  [string map {BWP7T40P140 BWP7T40P140HVT} $cell]
                                  set tmpd [expr ([getMetasTime $tmp] + $margin) * $derate]
                                  if { [expr $slack - $tmpd] > 0 } { set cell $tmp ; set tmpmar $margin }
                              }
                        }
                        set tmpd   [expr ([getMetasTime $cell] + $tmpmar) * $derate]
                        set mslack [expr $slack - $tmpd]
                        set newcell $cell
                    } else {
                        set tmp  [string map {BWP7T40P140HVT BWP7T40P140} $cell]
                        set tmpd [expr [getMetasTime $tmp] * $derate]
                        if { [expr $slack - $tmpd] > 0 } {
                            set newcell $tmp
                            set mslack  [expr $slack - $tmpd]
                        } else {
#                            set newcell [regsub -- {T(H|S|UL)HSDFFQ(R|SB)?(\w*)X\d+} $cell {THHSDFFQ\2ZMX10}]
                             set newcell [regsub -- {SDF(\w*)Q(\w*)D(\w*)} $cell {SDFSYN\1QD\3}]
			     echo "Cell [get_object_name $xx] TYPE  $cell :  Shoulde be change to META cell $newcell"
			     
                        }
                    }
                    set cell  $newcell
                    set delay [expr [getMetasTime $cell] * $derate]
                    set msg   "Info: Non-MetasType"
                }

                if { [expr $slack - $delay] > 0 } {
                    set tmpmar 0
                    if { ![string match {*BWP7T40P140HVT} $cell] } {
              if { [string match {*BWP7T40P140ULVT} $cell] } {
                set tmp  [string map {BWP7T40P140ULVT BWP7T40P140} $cell]
                set tmpd [expr ([getMetasTime $tmp] + $margin) * $derate]
                if { [expr $slack - $tmpd] > 0 } { set cell $tmp ; set tmpmar $margin }
              }
              if { [string match {*BWP7T40P140} $cell] } {
                set tmp  [string map {BWP7T40P140 BWP7T40P140HVT} $cell]
                set tmpd [expr ([getMetasTime $tmp] + $margin) * $derate]
                if { [expr $slack - $tmpd] > 0 } { set cell $tmp ; set tmpmar $margin }
              }
            }
            set tmpd   [expr ([getMetasTime $cell] + $tmpmar) * $derate]
            set mslack [expr $slack - $tmpd]
            set newcell $cell
          } else {
            set tmp  [string map {BWP7T40P140HVT BWP7T40P140} $cell]
            set tmpd [expr [getMetasTime $tmp] * $derate]
            if { [expr $slack - $tmpd] > 0 } {
              set newcell $tmp
              set mslack  [expr $slack - $tmpd]
            } else {
              if {![string match {*BWP7T40P140ULVT} $cell]} {
              set tmp  [string map {BWP7T40P140HVT BWP7T40P140ULVT BWP7T40P140 BWP7T40P140ULVT} $cell]
              set tmpd [expr [getMetasTime $tmp] * $derate]
	      } else {
	      set tmp $cell
	      set tmpd [expr [getMetasTime $tmp] * $derate]
	      }
              if { [expr $slack - $tmpd] > 0 } {
                set newcell $tmp
                set mslack  [expr $slack - $tmpd]
              } else {
                set newcell $tmp
                set mslack [expr $slack - $tmpd]
                if { $msg ne "" } {
                  set msg "$msg, Error: check period or timing path"
                } else {
                  set msg "Error: check period or timing path"
                }
              }
            }
          }
        } else {
          # Non-ScanFF 
          if { [getMetasTime $cell] ne "---" } {
            set tmpd [expr [getMetasTime $cell] * $derate]
            if { [expr $slack - $tmpd] > 0 } {
              set newcell $cell
              set mslack  [expr $slack - $tmpd]
            } else {
              set tmp  [string map {BWP7T40P140HVT BWP7T40P140} $cell]
              set tmpd [expr [getMetasTime $tmp] * $derate]
              if { [expr $slack - $tmpd] > 0 } {
                  set newcell $tmp
                  set mslack  [expr $slack - $tmpd]
              } else {
                set msg "Error: Check cell type"
              }
            }
          } else {
            # undefined metas-time
            set msg "Error: Undefined Metas-Time"
          }
        }
      }

      if { $ocell ne "" } { set cell $ocell }
      # output info
      if { $peri ne "" } { set xxx [format %.3f $peri] } else { set xxx $peri }

      if { $half_flg } {
        if { [string match {SDFSYN*} $newcell] } {
          if { [expr $slack - [getMetasTime $newcell] / 2.0] > 0 } { set hslk "MET" } else { set hslk "VIO" }
          set msg "$msg\(half_anno:$hslk\)"
          unset hslk
        }
      }

      puts $fo "[format %0${n}d $i],$inst,[format %.3f $slack],$cell,$newcell,[format %.3f $mslack],$cfast,$xxx,$clk,$msg"

      # output size_cell/annotate
      if { $newcell ne "" } {
        if { $newcell eq $cell } { puts -nonewline $fs "#" }
        puts $fs "size_cell $inst $newcell ;# $cell"
        if { $anno_flg } { [writeAnno $inst $newcell $OUT_ANNO $half_flg 0] }
      } elseif { [getMetasTime $cell] ne "---" } {
        if { $anno_flg } { [writeAnno $inst $cell $OUT_ANNO $half_flg 1] }
        puts $fs "#size_cell $inst $cell ;# $cell"
      }
    }
  }
}

close $fi
close $fo
close $fs

unsuppress_message UITE-416
