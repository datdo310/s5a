#############################################################
# F/F's clockpin MaxTransition constraints
#############################################################
# v1r00: -                From E1M-S
# v1r01: 2017/10/06 Y.Oda Update for RV28F

#############################################################
# open maxtran_clkpin.log
#############################################################
if { [catch {open "LOG/maxtran_clkpin_${MODE}.log" w} log_fd] } {
    puts "Error: Cannot open file (maxtran_hvt_${STA_MODE}.log)."
    exit 1
}
puts $log_fd "# set hvt cell maxtran celltype list"
puts $log_fd "# Celltype  Pin  Constraint"


############################################################
# set constraint unit factor
############################################################
# time scale factor
set Tunit [get_attribute [current_design] time_unit_in_second]
set Tfactor [expr 1.0e-9/$Tunit]
# constraint scale factor
set Cunit [get_attribute [current_design] time_unit_in_second]
set Cfactor [expr 1.0e-9/$Cunit]

#############################################################
# reset all pin's max transition
#############################################################
if {[info exist PTECO_FIX_DRC]} {
    puts "* Information : Skip Reset maxtran constraints"
} else {
    puts "* Information : Reset maxtran constraints"
    set_max_transition 999.999 [get_pins * -hier]
    set_max_transition 999 [get_clocks *] -clock_path -rise -fall
    set_max_transition 999 [get_clocks *] -data_path  -rise -fall
}

############################################################
# MaxTransition constraints to FF clock pin
#
# RV40F
# PINS : CLK GT GTB
#   MaxTran             = 0.64
#
# RV28F
# PINS : CLK GT GTB
#   MaxTran             = 0.50
############################################################
array unset end_flag
if {[info exists PROCESS]} {
  if {[string match "RV40F" $PROCESS] } {
	set CONST_CLKPIN  [expr $Cfactor*0.64]
  } elseif {[string match "RV28F" $PROCESS] } {
	set CONST_CLKPIN  [expr $Cfactor*0.50]
  } else {
	puts "Error: set_maxtran_clkpin.tcl cannot support \$PROCESS = $PROCESS"
  }
} else {
	puts "Error: set_maxtran_clkpin.tcl cannot get \$PROCESS"
}
foreach_in_collection cell [get_cells * -hier -quiet -filter "is_sequential==true"] {
    set lib_cell_name [get_attribute $cell ref_name]
    if { [regexp {^THH} $lib_cell_name] || [regexp {^TMH} $lib_cell_name] || [regexp {^TSH} $lib_cell_name] 
			|| [regexp {^TWH} $lib_cell_name] || [regexp {^TLH} $lib_cell_name] || [regexp {^TULH} $lib_cell_name]  } {
    	# CELL : ^T\w*DFF,^T\w*DLAT, ^T\w*GTD* , CONSTRAINT : $CONST_CLKPIN
        if { [regexp {^T\w*DFF} $lib_cell_name] || [regexp {^T\w*DLAT} $lib_cell_name]
                                   || [regexp {^T\w*GTD} $lib_cell_name]  } {
	    set pin [get_pins [get_object_name $cell]/CLK -quiet]
            if { $pin != "" } {
                set_max_transition $CONST_CLKPIN $pin
                if { [info exists end_flag($lib_cell_name)] } { continue }
                puts $log_fd "$lib_cell_name CLK $CONST_CLKPIN"
            }
            set pin [get_pins [get_object_name $cell]/GT -quiet]
            if { $pin != "" } {
                set_max_transition $CONST_CLKPIN $pin
                if { [info exists end_flag($lib_cell_name)] } { continue }
                puts $log_fd "$lib_cell_name GT $CONST_CLKPIN"
            }
            set pin [get_pins [get_object_name $cell]/GTB -quiet]
            if { $pin != "" } {
                set_max_transition $CONST_CLKPIN $pin
                if { [info exists end_flag($lib_cell_name)] } { continue }
                puts $log_fd "$lib_cell_name GTB $CONST_CLKPIN"
            }
        }
    
    }
    set end_flag($lib_cell_name) 1
}

#############################################################
# close LOG/maxtran_clkpin.log
#############################################################
close $log_fd
