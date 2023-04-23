set_app_var timing_override_max_capacitance_transition_lib_constraint false; # using conflict constraints for maxtran/cap

#############
# maxtran
puts "Information: maxtran relax_value $MAXTRANCAP_FREQ_RELAX"

# Frequency base constraints
source ./scr/set_maxtran_freq.tcl
set_maxtran_per_freq_CORE $core_clk $Tfactor $Cfactor $MAXTRANCAP_FREQ_RELAX $PROCESS


# Registers clock pin
source ./scr/set_maxtran_clkpin.tcl

# Lowdrive output
if {[string match "RV40F" $PROCESS] } {
    source ./scr/DLC_proc_RV40F.tcl         ;# From DelayCalc team(get_min_period.tcl, get_half_cycle_path_v2.tcl, dlclt_maxtran_lowdrv_proc.scr)
    source ./scr/set_maxtran_lowdrv_RV40F.tcl       ;# Apply constraints
} elseif { [string match "RV28F" $PROCESS] } {
    #source ./scr/DLC_proc_RV28F.tcl         ;# From DelayCalc team(get_min_period.tcl, get_half_cycle_path_v2.tcl, dlclt_maxtran_lowdrv_proc.scr)
    #source ./scr/set_maxtran_lowdrv_RV28F.tcl       ;# Apply constraints
    #ULVT(7T)
    set_max_transition 0.7 -lib_pin [get_lib_pins -quiet */*D1BWP7T40P140ULVT/* -filter "pin_direction ==out"]
    set_max_transition 0.7 -lib_pin [get_lib_pins -quiet */*D0*BWP7T40P140ULVT/* -filter "pin_direction ==out"]
    #ULVT(8T)
    set_max_transition 0.7 -lib_pin [get_lib_pins -quiet */TULH*X0*/* -filter "pin_direction ==out"]
    #SVT(7T)
    set_max_transition 0.6 -lib_pin [get_lib_pins -quiet */*D2BWP7T40P140/* -filter "pin_direction ==out"]
    set_max_transition 0.6 -lib_pin [get_lib_pins -quiet */*D1BWP7T40P140/* -filter "pin_direction ==out"]
    set_max_transition 0.6 -lib_pin [get_lib_pins -quiet */*D0*BWP7T40P140/* -filter "pin_direction ==out"]
    #SVT(8T)
    set_max_transition 0.6 -lib_pin [get_lib_pins -quiet */TSH*X1?/* -filter "pin_direction ==out"]
    set_max_transition 0.6 -lib_pin [get_lib_pins -quiet */TSH*X0*/* -filter "pin_direction ==out"]
    #HVT(7T)
    set_max_transition 0.4 -lib_pin [get_lib_pins -quiet */*D2BWP7T40P140HVT/* -filter "pin_direction ==out"]
    set_max_transition 0.4 -lib_pin [get_lib_pins -quiet */*D1BWP7T40P140HVT/* -filter "pin_direction ==out"]
    set_max_transition 0.4 -lib_pin [get_lib_pins -quiet */*D0*BWP7T40P140HVT/* -filter "pin_direction ==out"]
    #HVT(8T)
    set_max_transition 0.4 -lib_pin [get_lib_pins -quiet */THH*X20/* -filter "pin_direction ==out"]
    set_max_transition 0.4 -lib_pin [get_lib_pins -quiet */THH*X1?/* -filter "pin_direction ==out"]
    set_max_transition 0.4 -lib_pin [get_lib_pins -quiet */THH*X0*/* -filter "pin_direction ==out"]
}


# Half cycle path
if {[string match "RV40F" $PROCESS]} {
    source ./scr/set_maxtran_half_cycle.tcl
    set_maxtran_half_cycle -freq_margin $MAXTRANCAP_FREQ_RELAX
}

#(6) async pin transition
if { [string match "RV28F" $PROCESS] } {
    SET_INIT_VAR   MAXTRAN_ASYNC_CONST	0.80
    SET_ASYNC_TRAN $MAXTRAN_ASYNC_CONST	0  ;# Not Overwrite Maxtran
}

# Skewed transition
set DRV_SMC_MAXTRAN         0.4
set DRV_SMC_MAXTRAN_PINS    "SE TE SMC SPE SPEA SPEB"
foreach pinname $DRV_SMC_MAXTRAN_PINS {
    foreach_in_collection smc_pin [get_pins -quiet -hier -filter "full_name=~*/$pinname&&is_hierarchical==false"] {
        set org_tran [get_attribute $smc_pin max_transition]
        if {$DRV_SMC_MAXTRAN < $org_tran} {
            set_max_transition $DRV_SMC_MAXTRAN $smc_pin
        }
    }
}

#############
# maxcap

source ./scr/set_maxcap_freq.tcl
set_maxcap_per_freq_CORE $core_clk $Tfactor $Cfactor $MAXTRANCAP_FREQ_RELAX $PROCESS
source ./scr/add_maxcap_of_hv.tcl
