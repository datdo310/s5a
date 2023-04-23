###################
# Halfcycle-Check #
###################

check_resource Get_HalfCycle-Net

set TIMING_PATH 1
set TURN        0

set VALID_PERIOD     7.00
set ALL_CLOCKS      [all_clocks]
set TO_CLOCKS       [get_clocks ${ALL_CLOCKS} -filter "period<=${VALID_PERIOD}"]

set FILTER_PERIOD    3.34
set REMAINED_CLOCKS ${TO_CLOCKS}
set TARGET_CLOCKS   [get_clocks ${ALL_CLOCKS} -filter "period<=${FILTER_PERIOD}"]

set DIR "./Half"

if {[file exist $DIR] && [file isdirectory $DIR]} {
    puts "Directory Half already exists."
} else {
    file mkdir $DIR
}

file delete HALF_NET.list
file delete ${DIR}/TMP_HALFCYCLE_REP_${MODE}_NET.rep

   puts "Valid clock_period for extraction: Under ${VALID_PERIOD}ns"

while { [sizeof_collection ${REMAINED_CLOCKS}] > 0 } {
   puts " Now processing the period under ${FILTER_PERIOD}ns"
   set START_CLOCKS ${TARGET_CLOCKS}
   set END_CLOCKS   ${TO_CLOCKS}
   set NUM_CLOCKS   [sizeof_collection ${START_CLOCKS}]

   set RT_GROUP ""

   while { ${TIMING_PATH} > 0 } {

      set TIMING_PATH 0
      incr TURN

      puts " Checking half-cycle combination for the period under ${FILTER_PERIOD}ns turn ${TURN}..."
      set RISE_FALL [get_timing_path -rise_from ${START_CLOCKS} -fall_to ${END_CLOCKS} ]
      set FALL_RISE [get_timing_path -fall_from ${START_CLOCKS} -rise_to ${END_CLOCKS} ]
      set RISE_FALL_SIZE [ sizeof_collection ${RISE_FALL} ]
      set FALL_RISE_SIZE [ sizeof_collection ${FALL_RISE} ]

      puts "Rise -> Fall : ${RISE_FALL_SIZE}"
      if { ${RISE_FALL_SIZE} > 0 } {
         foreach_in_collection rise_fall ${RISE_FALL} {
            set START_CLOCK  [get_object_name [ get_attribute ${rise_fall} startpoint_clock ] ]
            set END_CLOCK    [get_object_name [ get_attribute ${rise_fall} endpoint_clock ] ]
            set START_END    [ list ${START_CLOCK} ${END_CLOCK} ]
            set RT_OPT "-rise_from \[get_clocks ${START_CLOCK}\] -fall_to \[get_clocks ${END_CLOCK}\]"
            check_resource " Half-Cycle : ${START_CLOCK}(r) - ${END_CLOCK}(f)"
            lappend RT_GROUP ${RT_OPT}
            incr TIMING_PATH
         }
      }
      puts "Fall -> Rise : ${FALL_RISE_SIZE}"
      if { ${FALL_RISE_SIZE} > 0 } {
         foreach_in_collection fall_rise ${FALL_RISE} {
            set START_CLOCK  [get_object_name [ get_attribute ${fall_rise} startpoint_clock ] ]
            set END_CLOCK    [get_object_name [ get_attribute ${fall_rise} endpoint_clock ] ]
            set START_END    [ list ${START_CLOCK} ${END_CLOCK} ]
            set RT_OPT "-fall_from \[get_clocks ${START_CLOCK}\] -rise_to \[get_clocks ${END_CLOCK}\]"
            check_resource " Half-Cycle : ${START_CLOCK}(f) - ${END_CLOCK}(r)"
            lappend RT_GROUP ${RT_OPT}
            incr TIMING_PATH
         }
      }

      set i 0
      if { ${TIMING_PATH} > 0 } {

         redirect -append ${DIR}/TMP_HALFCYCLE_REP_${MODE}_NET.rep {
            foreach tmp $RT_GROUP {
               incr i
               puts "#Running ${i}\/${TIMING_PATH}"
               puts "report_timing -nosplit $tmp -nets -nworst 1000 -max 100000000000 -uniq"
               eval "report_timing -nosplit $tmp -nets -nworst 1000 -max 100000000000 -uniq"
            }
         }

         puts "Turn ${TURN} Finished."

         puts "# Extracting Half-Cycle net from report..."
         sh grep '(net)' ${DIR}/TMP_HALFCYCLE_REP_${MODE}_NET.rep | awk '{print \$1}' | sort -u >> LOAD/HALF_NET.list

         set HALF_CYCLE_NETS [READ_LISTFILE LOAD/HALF_NET.list]
         foreach half_cycle_nets ${HALF_CYCLE_NETS} {
            check_resource "Set false-path to the net ${half_cycle_nets} already extracted..."
            set_false_path -through [get_nets ${half_cycle_nets}]
         }
      }
   }
      set FILTER_PERIOD   [expr ${FILTER_PERIOD} * 2.0]
      set REMAINED_CLOCKS [remove_from_collection ${REMAINED_CLOCKS} ${TARGET_CLOCKS}]
      if { [sizeof_collection ${REMAINED_CLOCKS}] > 0 } {
         set TARGET_CLOCKS   [get_clocks ${REMAINED_CLOCKS} -filter "period<=${FILTER_PERIOD}"]
      }
      #if { ${FILTER_PERIOD} > ${VALID_PERIOD} } {
      #   puts "Analysing for target periods had finished."
      #   set REMAINED_CLOCKS 0
      #}

}

check_resource HalfCycle-Net_Gotten.

redirect LOAD/KEY_HALF_CYCLE_NET {puts "OK"}

