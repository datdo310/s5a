#############################################################
# Default MaxCapacitance constraints
#############################################################
##            v01r01 Y.Oda RV40F reuse from E1M-S
## 2017/03/09 v01r02 Y.Oda Add RV28F SignOff
##                         and support over 600MHz for RV40F
## 2017/10/10 v01r03 Y.Oda Change RV28F MaxCap


############################################################
# set constraint unit factor
############################################################
# time scale factor
set Tunit [get_attribute [current_design] time_unit_in_second]
set Tfactor [expr 1.0e-9/$Tunit]
# constraint scale factor
set Cunit [get_attribute [current_design] capacitance_unit_in_farad]
set Cfactor [expr 1.0e-12/$Cunit]

#------------------------------------------------------------
# proc : set_maxcap_per_freq_CORE
#------------------------------------------------------------
proc set_maxcap_per_freq_CORE {
    c_list
    Tfactor
    Cfactor
    freq_margin
    { process RV40F } 
} {
        if {[string match "RV40F" $process]} {
                puts "* Information: RV40F MaxTransition for Frequency are set"
                set_maxcap_per_freq_CORE_RV40F $c_list $Tfactor $Cfactor $freq_margin
        } elseif {[string match "RV28F" $process]} {
                puts "* Information: RV28F MaxTransition for Frequency are set"
                set_maxcap_per_freq_CORE_RV28F $c_list $Tfactor $Cfactor $freq_margin
        }
}

proc set_maxcap_per_freq_CORE_RV40F {
    c_list
    Tfactor
    Cfactor
    freq_margin
} {
# RANGE  : T >= 1.67ns Under 600MHz
#   MaxCap(clock_path) = 0.076*T + 0 [pF]
#   MaxCap(data_path)  = 0.152*T + 0.0 [pF]
# RANGE  : 1.67ns < T  Over 600MHz
#   MaxCap(clock_path) = 0.076*T/1.3 + 0 [pF]
#   MaxCap(data_path)  = 0.152*T/1.3 + 0.0 [pF]

    set TMAX1 [expr 1.67 * $Tfactor]

    foreach_in_collection clk $c_list {
        set period_tmp_tmp [get_attribute $clk period]
        set period_tmp [expr $period_tmp_tmp / (1 - $freq_margin) ]
        if { $period_tmp == "" } { continue }

        if { $period_tmp < $TMAX1 } {
            set clock_const [expr $Cfactor*($period_tmp*0.076+0)/1.3]
            set data_const  [expr $Cfactor*($period_tmp*0.152+0.0)/1.3]
	} else {
            set clock_const [expr $Cfactor*($period_tmp*0.076+0)]
            set data_const  [expr $Cfactor*($period_tmp*0.152+0.0)]
	}

            set_max_capacitance $clock_const $clk -clock_path -rise -fall
            set_max_capacitance $data_const $clk -data_path -rise -fall
    }
}


proc set_maxcap_per_freq_CORE_RV28F {
    c_list
    Tfactor
    Cfactor
    freq_margin
} {
#   MaxCap(clock_path) = 0.0418*2/1.06[mA]/(1.09[V]*f[MHz]) [pF]
#   MaxCap(data_path)  = 2*MaxCap(clock_path) [pF]
#   V:typical voltage

    set TMAX1 [expr 1.67 * $Tfactor]

    foreach_in_collection clk $c_list {
        set period_tmp_tmp [get_attribute $clk period]
        set period_tmp [expr $period_tmp_tmp / (1 - $freq_margin) ]
        if { $period_tmp == "" } { continue }
        set clock_const [expr $Cfactor*((0.0418*2/1.06)/1.09)*$period_tmp]
        set data_const  [expr $Cfactor*((0.0418*2/1.06)/1.09)*$period_tmp*2]

        set_max_capacitance $clock_const $clk -clock_path -rise -fall
        set_max_capacitance $data_const $clk -data_path -rise -fall
    }
}

############################################################
# Set MaxCapacitance constraints per frequency (MAIN)
############################################################
# get clock collection of core domain
set core_clk [get_clocks * -quiet]
# set_maxcap constraints per freq of core domain
#set_maxcap_per_freq_CORE $core_clk $Tfactor $Cfactor

