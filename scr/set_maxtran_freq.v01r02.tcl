#############################################################
# Default MaxTransition constraints
#############################################################
##            v01r01 Y.Oda	RV40F reuse from E1M-S
## 2017/02/27 v01r02 Y.Oda	Add RV28F SignOff

############################################################
# set constraint unit factor
############################################################
# time scale factor
set Tunit [get_attribute [current_design] time_unit_in_second]
set Tfactor [expr 1.0e-9/$Tunit]
# constraint scale factor
set Cunit [get_attribute [current_design] time_unit_in_second]
set Cfactor [expr 1.0e-9/$Cunit]

proc set_maxtran_per_freq_CORE {
    c_list
    Tfactor
    Cfactor
    freq_margin
    { process RV40F }
} {
	if {[string match "RV40F" $process]} {
		puts "Information: RV40F MaxTransition for Frequency are set"
		set_maxtran_per_freq_CORE_RV40F $c_list $Tfactor $Cfactor $freq_margin
	} elseif {[string match "RV28F" $process]} {
		puts "Information: RV28F MaxTransition for Frequency are set"
		set_maxtran_per_freq_CORE_RV28F $c_list $Tfactor $Cfactor $freq_margin
	}
}

## RV40F Frequency Transition Procedure
proc set_maxtran_per_freq_CORE_RV40F {
    c_list
    Tfactor
    Cfactor
    freq_margin
} {
#------------------------------------------------------------
# proc : set_maxtran_per_freq_CORE_RV40F
#------------------------------------------------------------
# RANGE  : T >= 5ns
#   MaxTran(clock_path) = 0*T   + 1.2 [ns]
#   MacTran(data_path)  = 0.0*T + 2.4 [ns]
# RANGE  : 5ns > T >= 3.1ns
#   MaxTran(clock_path) = 0.24*T + 0 [ns]
#   MacTran(data_path)  = 0.48*T + 0.0 [ns]
# RANGE  : 3.1ns > T  Over 320MHz
#   MaxTran(clock_path) = 0.16*T + 0 [ns]
#   MacTran(data_path)  = 0.32*T + 0.0 [ns]

    puts "Information: set_maxtran_per_freq_CORE_RV40F"

    set TMAX1 [expr 5   * $Tfactor]
    set TMAX2 [expr 3.1 * $Tfactor]
    foreach_in_collection clk $c_list {
        set period_tmp_tmp [get_attribute $clk period]
        set period_tmp [expr $period_tmp_tmp / (1 - $freq_margin) ]
        if { $period_tmp == "" } { continue }
        if { $period_tmp >= $TMAX1 } {
            set clock_const [expr $Cfactor*($period_tmp*0+1.2)]
            set data_const  [expr $Cfactor*($period_tmp*0.0+2.4)]
            set_max_transition $clock_const $clk -clock_path -rise -fall
            set_max_transition $data_const  $clk -data_path  -rise -fall
        } elseif { $period_tmp < $TMAX1 && $period_tmp >= $TMAX2 } {
            set clock_const [expr $Cfactor*($period_tmp*0.24+0)]
            set data_const  [expr $Cfactor*($period_tmp*0.48+0.0)]
            set_max_transition $clock_const $clk -clock_path -rise -fall
            set_max_transition $data_const  $clk -data_path  -rise -fall
        } elseif { $period_tmp < $TMAX2 } {
            set clock_const [expr $Cfactor*($period_tmp*0.16+0)]
            set data_const  [expr $Cfactor*($period_tmp*0.32+0.0)]
            set_max_transition $clock_const $clk -clock_path -rise -fall
            set_max_transition $data_const  $clk -data_path  -rise -fall
        } else {
            puts "Error(transition setting): unconstrained for maxtran freq for [get_object_name $clk]"
            set_max_transition 0.001 $clk -clock_path -rise -fall
            set_max_transition 0.001 $clk -data_path  -rise -fall
            
        }
    }
}

## RV28F Frequency Transition Procedure
proc set_maxtran_per_freq_CORE_RV28F {
    c_list
    Tfactor
    Cfactor
    freq_margin
} {
#------------------------------------------------------------
# proc : set_maxtran_per_freq_CORE_RV40F
#------------------------------------------------------------
# RANGE  : T >= 5ns
#   MaxTran(clock_path) = 0*T   + 1.2 [ns]
#   MacTran(data_path)  = 0.0*T + 2.4 [ns]
# RANGE  : 5ns > T >= 3.4ns
#   MaxTran(clock_path) = 0.24*T + 0 [ns]
#   MacTran(data_path)  = 0.48*T + 0.0 [ns]
# RANGE  : 3.4ns > T  Over 300MHz
#   MaxTran(clock_path) = 0.16*T + 0 [ns]
#   MacTran(data_path)  = 0.32*T + 0.0 [ns]

    puts "Information: set_maxtran_per_freq_CORE_RV28F"

    set TMAX1 [expr 5   * $Tfactor]
    set TMAX2 [expr 3.4 * $Tfactor]
    foreach_in_collection clk $c_list {
        set period_tmp_tmp [get_attribute $clk period]
        set period_tmp [expr $period_tmp_tmp / (1 - $freq_margin) ]
        if { $period_tmp == "" } { continue }
        if { $period_tmp >= $TMAX1 } {
            set clock_const [expr $Cfactor*($period_tmp*0+1.2)]
            set data_const  [expr $Cfactor*($period_tmp*0.0+2.4)]
            set_max_transition $clock_const $clk -clock_path -rise -fall
            set_max_transition $data_const  $clk -data_path  -rise -fall
        } elseif { $period_tmp < $TMAX1 && $period_tmp >= $TMAX2 } {
            set clock_const [expr $Cfactor*($period_tmp*0.24+0)]
            set data_const  [expr $Cfactor*($period_tmp*0.48+0.0)]
            set_max_transition $clock_const $clk -clock_path -rise -fall
            set_max_transition $data_const  $clk -data_path  -rise -fall
        } elseif { $period_tmp < $TMAX2 } {
            set clock_const [expr $Cfactor*($period_tmp*0.16+0)]
            set data_const  [expr $Cfactor*($period_tmp*0.32+0.0)]
            set_max_transition $clock_const $clk -clock_path -rise -fall
            set_max_transition $data_const  $clk -data_path  -rise -fall
        } else {
            puts "Error(transition setting): unconstrained for maxtran freq for [get_object_name $clk]"
            set_max_transition 0.001 $clk -clock_path -rise -fall
            set_max_transition 0.001 $clk -data_path  -rise -fall
            
        }
    }
}


############################################################
# Set MaxTransition constraints per frequency (MAIN)
############################################################
# get clock collection of core domain
set core_clk [get_clocks * -quiet]
# set_maxtran constraints per freq of core domain
#set_maxtran_per_freq_CORE $core_clk $Tfactor $Cfactor $freq_margin

