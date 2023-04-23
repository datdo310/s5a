#############################################################
# Default MaxCapacitance constraints
#############################################################

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
} {
    foreach_in_collection clk $c_list {
        set period_tmp_tmp [get_attribute $clk period]
        set period_tmp [expr $period_tmp_tmp / (1 - $freq_margin) ]
        if { $period_tmp == "" } { continue }

#M.K 20121225# AOI: 0.144/1.25 , Utsusemi 0.095/1.25
#M.K 20121225#            set clock_const [expr $Cfactor*($period_tmp*0.1152+0)]
#M.K 20121225#            set data_const [expr $Cfactor*($period_tmp*0.2304+0.0)]
            set clock_const [expr $Cfactor*($period_tmp*0.076+0)]
            set data_const [expr $Cfactor*($period_tmp*0.152+0.0)]

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

