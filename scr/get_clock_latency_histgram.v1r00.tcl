###########################################################
## get_clock_latency_histgram.tcl
#  v1r00 : 2020/11/11 : New
#
###########################################################

proc get_clock_latency_histgram {{CLOCK_LIST} {min 0.000} {step 0.200} {max 12.000}} {
    global MODE
    global STA_MODE
    global DFT_MODE

    set REP_DIR Report/latency_histgram
    set TMP_DIR $REP_DIR/$MODE

    DIR_CHECK $REP_DIR
    DIR_CHECK $TMP_DIR

    set fo [open $TMP_DIR/first_column.dat w]
    puts $fo "name"
    puts $fo "Clock latency"
    puts $fo "    - $min"
    for {set i $min} {$i < $max} {set i [expr $i + $step]} {
        set j "[format %.3f-%.3f $i [expr $i + $step]]"
        puts $fo "$j"
    }
    puts $fo "$max - inf"
    close $fo

    foreach clk $CLOCK_LIST {
        set count($clk,$min) 0
        for {set i $min} {$i < $max} {set i [expr $i + $step]} {
            set j "[format %.3f-%.3f $i [expr $i + $step]]"
            set count($clk,$j) 0
        }
        set count($clk,$max-inf) 0
        redirect -file $TMP_DIR/latency_$clk.rep {
            report_clock_timing -clock $clk -type latency -nworst 5000000 -nosplit
        }
        set fi [open $TMP_DIR/latency_$clk.rep r]
        while {[gets $fi line] >= 0} {
            #debug# puts $line
            if {![regexp {^ } $line]} { continue }
            regsub {^ *} $line {} line
            #debug# puts $line
            if {[regexp {^[0-9]+} [lindex [split $line] 4]] || [regexp {^-[0-9]+} [lindex [split $line] 4]]} {
                set latency [lindex [split $line] 4]
                #debug# puts $latency
                for {set i $min} {$i < $max} {set i [expr $i + $step]} {
                    if {$latency < $min} {
                        incr count($clk,$min)
                        break
                    } elseif {$latency >= $i && $latency < [expr $i + $step]} {
                        set j "[format %.3f-%.3f $i [expr $i + $step]]"
                        incr count($clk,$j)
                        break
                    } elseif {$latency >= $max} {
                        incr count($clk,$max-inf)
                        break
                    }
                }
            }
        }
        close $fi
        set fo [open $TMP_DIR/histgram_$clk.dat w]
        puts $fo "$clk"
        puts $fo "Count"
        puts $fo "$count($clk,$min)"
        for {set i $min} {$i < $max} {set i [expr $i + $step]} {
            set j "[format %.3f-%.3f $i [expr $i + $step]]"
            puts $fo "$count($clk,$j)"
        }
        puts $fo "$count($clk,$max-inf)"
        close $fo
    }

    if {[info exist STA_MODE] && [string match "SYSTEM" $STA_MODE]} {
        exec cat $TMP_DIR/first_column.dat > $REP_DIR/latency_histgram_ALL_$STA_MODE.csv
        foreach clk $CLOCK_LIST {
            exec paste -d "," $REP_DIR/latency_histgram_ALL_$STA_MODE.csv $TMP_DIR/histgram_$clk.dat > $REP_DIR/latency_histgram_ALL_$STA_MODE.csv.tmp
            exec mv $REP_DIR/latency_histgram_ALL_$STA_MODE.csv.tmp $REP_DIR/latency_histgram_ALL_$STA_MODE.csv
            exec gzip -f $TMP_DIR/histgram_$clk.dat $TMP_DIR/latency_$clk.rep
        }
    } else {
        exec cat $TMP_DIR/first_column.dat > $REP_DIR/latency_histgram_ALL_$DFT_MODE.csv
        foreach clk $CLOCK_LIST {
            exec paste -d "," $REP_DIR/latency_histgram_ALL_$DFT_MODE.csv $TMP_DIR/histgram_$clk.dat > $REP_DIR/latency_histgram_ALL_$DFT_MODE.csv.tmp
            exec mv $REP_DIR/latency_histgram_ALL_$DFT_MODE.csv.tmp $REP_DIR/latency_histgram_ALL_$DFT_MODE.csv
            exec gzip -f $TMP_DIR/histgram_$clk.dat $TMP_DIR/latency_$clk.rep
        }
    }
}

