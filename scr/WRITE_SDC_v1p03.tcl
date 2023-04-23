###############################################
#  WRITE_SDC.tcl  
#Reject Logic0/output Logic1/output from SDC
#  version:   v0p9  added for MCU const files
#             v0p91 Delete AC for STA SDC
#             v1p00 Read SYS_ATOM.ptsc
#             v1p01 Read module/*.tcl
#             v1p02 handle without module/*.tcl
#             v1p03 add WRITE CU
###############################################
proc SDC_ITEM_REJECT_LOGIC_CASE { {SDC} } {

   set INPUT  [open $SDC]
   while {! [eof ${INPUT}]} {
      set LINE [gets ${INPUT}]
     #puts "#(Original) $LINE"
      regsub {^ *} ${LINE} {} TMP_LINE
      set LIST_LINE [split [regsub -all { +} ${TMP_LINE} { }]]
      #set INDEX [lsearch -regexp ${LIST_LINE} {.*\/?Logic[01]\/output.*}]
      set INDEX [lsearch -regexp ${LIST_LINE} {^\{?([^\{]*\/L|L)ogic[01]\/output[\}\]]*$}]


      if {${INDEX} > -1} {
         while {${INDEX} > -1} {
            set TARGET [lindex ${LIST_LINE} ${INDEX}]
            #regsub {[^\{]*\/?Logic[01]\/output} ${TARGET} "" TMP_LINE
            regsub {([^\{]*\/L|L)ogic[01]\/output} ${TARGET} "" TMP_LINE
            set NEW_LIST [lreplace ${LIST_LINE} ${INDEX} ${INDEX} ${TMP_LINE}]  
            set LIST_LINE ${NEW_LIST}
           #set INDEX [lsearch -regexp ${LIST_LINE} {.*\/?Logic[01]\/output.*}]
            set INDEX [lsearch -regexp ${LIST_LINE} {^\{?([^\{]*\/L|L)ogic[01]\/output[\}\]]*$}]
         }
         set NEW_LINE [join ${LIST_LINE}]
         if {[regexp {\{ *\}} $NEW_LINE] > 0} {
            set LINE [concat "#Empty-list made by rejecting Logic0/output,Logic1/output had disabled : " ${NEW_LINE}]
         } elseif {[regexp {\[ *get[^ ]+s +\]} $NEW_LINE] > 0} {
            set LINE [concat "#Command with empty-target made by rejecting Logic0/output,Logic1/output had disabled : " ${NEW_LINE}]
         } else {
            set LINE ${NEW_LINE}
         }
      }
      echo ${LINE}
   }
}

#Extract constraint with variable replacing
proc SDC_COMMAND_EXTRACTION { {CONST} {COMMAND} } {

      set INPUT  [open $CONST]

      set VAL_COUNT 0
      set VAL_LIST  ""
      set PUT_LINE false
      set LINE_BEFORE ""

      while {! [eof ${INPUT}]} {

         set LINE [gets ${INPUT}]

        #Extract variable at "set" line
         if {[regexp {^ *set +} ${LINE}] > 0} {

            regsub {^ *} ${LINE} {} TMP_LINE
            set LIST_LINE [split [regsub -all { +} ${TMP_LINE} { }]]
            regsub -all {\"} [lindex ${LIST_LINE} 2] {} TMP_LINE

            set PARAM [lindex ${LIST_LINE} 1]
            if {[llength $LIST_LINE] == 3} {
               #puts "$LIST_LINE"
               set VALUE [subst ${TMP_LINE}]
               set VALIABLE_([lindex ${LIST_LINE} 1]) ${VALUE}
               #puts "set $PARAM $VALUE"
               set $PARAM $VALUE
               #puts "fin"
               incr VAL_COUNT
               lappend VAL_LIST $PARAM
            } else {
               #puts "$LIST_LINE"
               #set VALIABLE_([lindex ${LIST_LINE} 1]) {}
               set $PARAM {Error_Cannot_Get_Variable}
            }


        #Not "set" line
         } else {

           #Judge to show line or not
            if { [regexp {^ *#} ${LINE}] == 1 } {
               set PUT_LINE false
            } elseif { [regexp ${COMMAND} ${LINE}] == 1 } {
               set PUT_LINE true
            } elseif { [regexp {\\$} ${LINE_BEFORE}] == 1 } {
               #No Processing
            } else {
               set PUT_LINE false
            }

            if {${PUT_LINE}} {

              #Replace variable
               if {[llength ${VAL_LIST}] > 0} {
                  foreach VAL ${VAL_LIST} {
                     if { [regexp {\$} ${LINE}] == 1 } {
                        if { [regexp {\$\{.*\}} ${LINE}] == 1 } {
                           regsub "\\\${$VAL}" ${LINE} $VALIABLE_($VAL) NEWLINE
                           #regsub "\\\${$VAL}" ${LINE} [subst $[subst ::$VAL]] NEWLINE
                        } else {
                           regsub "\\\$$VAL" ${LINE} $VALIABLE_($VAL) NEWLINE
                        }
                        set LINE    ${NEWLINE}
                     }
                     #puts "#set $VAL $VALIABLE_($VAL)"
                  }
               }
               echo "${LINE}"
            }
            set LINE_BEFORE ${LINE}
         }
      }
      close ${INPUT}
}


proc WRITE_SDC {{SDC} {VERSION 1.7} {STA_METHOD CIS} } {

   global MODE
   global STA_MODE
   global CLOCK_MODE
   global APPLY_DIR
   global CONDITION

   global DFT_MODE
   if {[info exist DFT_MODE]} {
      set SDC_MODE "${MODE}_${DFT_MODE}"
   } else {
      set SDC_MODE ${MODE}
   }

   set MODULE_CONST_DIR     "${APPLY_DIR}/System/module"
   set ASYNC_CONST_DIR      "${APPLY_DIR}/System/async"
   set SYS_COMMON_CONST_DIR "${APPLY_DIR}/System/Common"
   set DFT_COMMON_CONST_DIR "${APPLY_DIR}/DFT/Common"

  #Module constraints wanted to be skipped
   set MODULE_CONST_EXCEPTION [list \
      ${MODULE_CONST_DIR}/ASYN \
      ${MODULE_CONST_DIR}/check_hier_constraint \
      ${MODULE_CONST_DIR}/const_system_false.ptsc \
      ${MODULE_CONST_DIR}/const_system_module.ptsc \
      ${MODULE_CONST_DIR}/user.boundary.tcl \
   ]

  #Async constraints wanted to be skipped
   set ASYNC_CONST_EXCEPTION [list \
      ${ASYNC_CONST_DIR}/dbs.ptsc \
      ${ASYNC_CONST_DIR}/sat0.ptsc \
      ${ASYNC_CONST_DIR}/sat1.ptsc \
      ${ASYNC_CONST_DIR}/usb2.ptsc \
      ${ASYNC_CONST_DIR}/u7792hdbs000top0.ptsc \
   ]

   set START_TIME [date]
   if {${STA_MODE}=="SYSTEM" || $STA_METHOD=="MCU"} {
         puts "Canceling AC-Related constraints..."
         remove_input_delay  [all_inputs]
         remove_output_delay [all_outputs]
         remove_capacitance  [add_to_collection [all_inputs] [all_outputs]]
         #puts "update_timing..."
         #update_timing
   }

   puts "Start writing SDC..."
   write_sdc -version ${VERSION} -nosplit LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc

   if {$STA_METHOD=="MCU"} {
	  set cu_out [open LOG/${SDC_MODE}_CU_${CLOCK_MODE}.sdc "w"]
	  set fid    [open LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc]
	  while {[gets $fid str]>=0} {
	    if {[string match  "set_clock_uncertainty*" $str] } {
            	puts $cu_out "$str"
	    }
          }
	  close $fid
	  close $cu_out

          sh \
            grep -v '^set_load' LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc | \
            grep -v '^set_clock_uncertainty' | \
            grep -v '^set_clock_latency' \
            > LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc.mod
          sh mv LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc.mod LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
   }

   switch -regexp -- ${STA_MODE} {
         ^(SYSTEM) {
            if {$STA_METHOD=="MCU"} {
               set FILE_ACIN_SETUP  ${APPLY_DIR}/System/AC/SYS_AC_IN_SETUP_${CLOCK_MODE}.ptsc
               set FILE_ACOUT_SETUP ${APPLY_DIR}/System/AC/SYS_AC_OUT_SETUP_${CLOCK_MODE}.ptsc
               set FILE_ACIN_HOLD   ${APPLY_DIR}/System/AC/SYS_AC_IN_HOLD_${CLOCK_MODE}.ptsc
               set FILE_ACOUT_HOLD  ${APPLY_DIR}/System/AC/SYS_AC_OUT_HOLD_${CLOCK_MODE}.ptsc
               set FILE_MAXLOAD     ${APPLY_DIR}/System/AC/SYS_LOAD_SETUP.ptsc
               set FILE_MINLOAD     ${APPLY_DIR}/System/AC/SYS_LOAD_HOLD.ptsc
            } elseif {$STA_METHOD=="CIS"} {
               set FILE_ACIN_SETUP  ${APPLY_DIR}/System/AC/Inopen_AC_USER_${CLOCK_MODE}.tcl_max
               set FILE_ACOUT_SETUP ${APPLY_DIR}/System/AC/Outopen_AC_USER_${CLOCK_MODE}_ICC.tcl_max
               set FILE_ACIN_HOLD   ${APPLY_DIR}/System/AC/Inopen_AC_USER_${CLOCK_MODE}.tcl_min
               set FILE_ACOUT_HOLD  ${APPLY_DIR}/System/AC/Outopen_AC_USER_${CLOCK_MODE}_ICC.tcl_min
               set FILE_MAXLOAD     ${APPLY_DIR}/System/AC/SYS_LOAD_SETUP.ptsc
               set FILE_MINLOAD     ${APPLY_DIR}/System/AC/SYS_LOAD_HOLD.ptsc
            }
         }

         ^(DFT) {
            if {$STA_METHOD=="MCU"} {
               set FILE_ACIN_SETUP  ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_SETUP_${CLOCK_MODE}.ptsc
               set FILE_ACOUT_SETUP ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_SETUP_${CLOCK_MODE}.ptsc
               set FILE_ACIN_HOLD   ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_IN_HOLD_${CLOCK_MODE}.ptsc
               set FILE_ACOUT_HOLD  ${APPLY_DIR}/DFT/AC/${DFT_MODE}_AC_OUT_HOLD_${CLOCK_MODE}.ptsc
               set FILE_MAXLOAD     ${APPLY_DIR}/DFT/AC/${DFT_MODE}_LOAD_SETUP.ptsc
               set FILE_MINLOAD     ${APPLY_DIR}/DFT/AC/${DFT_MODE}_LOAD_HOLD.ptsc
            } elseif {$STA_METHOD=="CIS"} {
               set FILE_ACIN_SETUP  "NONE"
               set FILE_ACOUT_SETUP "NONE"
               set FILE_ACIN_HOLD   "NONE"
               set FILE_ACOUT_HOLD  "NONE"
               set FILE_MAXLOAD     "NONE"
               set FILE_MINLOAD     "NONE"
            }
         }
   }


   if {${STA_MODE}=="SYSTEM"} {
      puts "Picking-Up set_disable_clock_gating_check constraints from module constraints."
      echo "#set_disable_clock_gating_check" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
      if {[catch {set MODULE_CONST [glob ls ${SYS_COMMON_CONST_DIR}/SYS_ATOM.ptsc ${MODULE_CONST_DIR}/*.ptsc ${MODULE_CONST_DIR}/*.tcl]}] == 0 } {
         if {[llength ${MODULE_CONST}] > 0} {
            foreach CONST ${MODULE_CONST} {
               if {[file isfile ${CONST}]} {
                 #Extract set_disable_clock_gating_check constraint.
                  if {([llength ${MODULE_CONST_EXCEPTION}] > 0) && ([lsearch ${MODULE_CONST_EXCEPTION} ${CONST}] > -1)} {
                     puts "#   : ${CONST} - Skipped as user exception."
                  } else {
                     puts "#   : ${CONST}"
                     SDC_COMMAND_EXTRACTION ${CONST} "set_disable_clock_gating_check" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
                  }
               } else {
                  puts "#   : ${CONST} - Skipped"
               }
            }
         }
      } else {
         puts "Error: No module constraints at ${MODULE_CONST_DIR}."
      }

   } else {
      puts "Picking-Up set_disable_clock_gating_check constraints from module constraints for DFT."
      echo "#set_disable_clock_gating_check" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
      if {[catch {set MODULE_CONST [glob ls ${DFT_COMMON_CONST_DIR}/${DFT_MODE}_*.ptsc]}] == 0 } {
         if {[llength ${MODULE_CONST}] > 0} {
            foreach CONST ${MODULE_CONST} {
               if {[file isfile ${CONST}]} {
                 #Extract set_disable_clock_gating_check constraint.
                  if {([llength ${MODULE_CONST_EXCEPTION}] > 0) && ([lsearch ${MODULE_CONST_EXCEPTION} ${CONST}] > -1)} {
                     puts "#   : ${CONST} - Skipped as user exception."
                  } else {
                     puts "#   : ${CONST}"
                     SDC_COMMAND_EXTRACTION ${CONST} "set_disable_clock_gating_check" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
                  }
               } else {
                  puts "#   : ${CONST} - Skipped"
               }
            }
         }
      } else {
         puts "Error: No module constraints at ${DFT_COMMON_CONST_DIR}."
      }
   }
   puts "Rejecting no-required/invalid descriptions."

   SDC_ITEM_REJECT_LOGIC_CASE LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc > LOG/temporary_sdc_wo_LogicCase_${SDC_MODE}_${CLOCK_MODE}.sdc

   sh \
      grep -v 'sdc_version' LOG/temporary_sdc_wo_LogicCase_${SDC_MODE}_${CLOCK_MODE}.sdc | \
      grep -v 'set_operating_conditions' | \
      grep -v 'set_units' | \
      grep -v 'set_wire_load_mode' | \
      grep -v 'set_max_area' | \
      grep -v 'set_max_leakage_power' | \
      grep -v 'set_clock_uncertainty -hold' | \
      grep -v 'set_timing_derate' | \
      grep -v 'set_wire_load_selection_group' > ${SDC}

   if {${STA_MODE}=="SYSTEM" || ${STA_METHOD} == "MCU" } {
      echo "#AC Related" >> LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
      APPEND_FILE ${FILE_MAXLOAD}     ${SDC}
      APPEND_FILE ${FILE_MINLOAD}     ${SDC}
      if {$CLOCK_MODE == "PROP"} {
           sh cp ${SDC} ${SDC}.woAC
           sh gzip -9f ${SDC}.woAC
      }
      APPEND_FILE ${FILE_ACIN_SETUP}  ${SDC}
      APPEND_FILE ${FILE_ACOUT_SETUP} ${SDC}
      APPEND_FILE ${FILE_ACIN_HOLD}   ${SDC}
      APPEND_FILE ${FILE_ACOUT_HOLD}  ${SDC}
   }

   sh gzip -9f ${SDC}
   sh rm -rf LOG/temporary_sdc_${SDC_MODE}_${CLOCK_MODE}.sdc
   set END_TIME [date]

   if {$STA_METHOD=="CIS" && ${STA_MODE}=="SYSTEM"} {
      puts "Extract ASYNC constraints to SYSTEM-Mode SDC."
      if {[catch {set ASYNC_CONST [ls ${ASYNC_CONST_DIR}/*]}] == 0} {
         echo "#ASYNC-Constraints" > ${SDC}.async
         if {[llength ${ASYNC_CONST}] > 0} {
            foreach CONST ${ASYNC_CONST} {
               if {[file isfile ${CONST}]} {
                  if {([llength ${ASYNC_CONST_EXCEPTION}] > 0) && ([lsearch ${ASYNC_CONST_EXCEPTION} ${CONST}] > -1)} {
                     echo "#${CONST} - Skipped as user exception." >> ${SDC}.async
                  } else {
                     echo "#${CONST}" >> ${SDC}.async
                     sh cat ${CONST} >> ${SDC}.async
                  }
               } else {
                  echo "#${CONST} - Skipped, not the constraint file." >> ${SDC}.async
               }
            }

            puts "Loading ASYNC constarints for error-check."
            foreach CONST ${ASYNC_CONST} {
               if {[file isfile ${CONST}]} {
                  if {([llength ${ASYNC_CONST_EXCEPTION}] > 0) && ([lsearch ${ASYNC_CONST_EXCEPTION} ${CONST}] > -1)} {
                     puts "#${CONST} - Skipped as user exception."
                  } else {
                     puts "#${CONST}"
                     source -echo -verbose ${CONST}
                  }
               } else {
                  puts "#${CONST} - Skipped, not the constraint file."
               }
            }
         puts "Please check the error in log for async-constraint-descriptions."
         }
      } else {
         puts "Error: No async-constraints at ${ASYNC_CONST_DIR}."
      }
   }

   puts "START      : ${START_TIME}"
   puts "WRITE_END  : ${END_TIME}"
   puts "CHECK_END  : [date]"

}

