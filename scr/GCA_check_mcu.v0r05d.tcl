# GCA check script for MCU
# v0r00	2014.01.07	Y.Oda      1st draft
# v0r03 2014.11.13      y.Oda      Change rule
# v0r04 2015.02.07      Y.Oda      comment out unneeded report
# v0r05 2018.06.12      A.Yoshida  Support PTC (exchanged from GCA) and set rule V02.01.05
# v0r05a 2020.04.30     A.Yoshida  Support PTC2019 and set rule V02.01.06
# v0r05b 2020.05.29     A.Yoshida  set variable hide_waived_violations(true) and set exception_convergence_pessimism_reduction.tbc
# v0r05c 2020.06.07     A.Yoshida  set get_pseudo_error_of_DES0002
# v0r05d 2020.06.29     A.Yoshida  apply PTC variables

# ADD v0r05b for using 2019.03-sp5-1-VAL-20200306 only
if {[regexp $GCA_VER201903 $sh_product_version]} {
   source /common/appl/Synopsys/primetime/2019.03-sp5-1-VAL-20200306/exception_convergence_pessimism_reduction.tbc ;# Objective is reduce pseudo error of EXC_0014/15
}

#source -verbose /common/appl/Renesas/GCA/tcl/UDEF_Renesas.tcl
#source -verbose /common/appl/Renesas/GCA/RULES/V010700/tcl/UDEF_Renesas.tcl;
#source -verbose /common/appl/Renesas/GCA/RULES/V010800/tcl/UDEF_Renesas.tcl;
#source -verbose /common/appl/Renesas/GCA/RULES/V010900/tcl/UDEF_Renesas.tcl;
#source -verbose /common/appl/Renesas/GCA/RULES/V020105/tcl/UDEF_Renesas.tcl;
 source -verbose /common/appl/Renesas/GCA/RULES/V020106/tcl/UDEF_Renesas.tcl;

# Setup Renesas ruleset
RenesasCommonRule_STA		;# For STA

# enable_rule  [list *]
# disable_rule ${GCA_DISABLE_RULE}

#### SET CUSTOM RULES as follows,
##source -verbose         ./scr/GCA_CUSTOM_RULES/UDEF_EXD_0008_NoSeqPin.tcl ;# Removed from V020106 which is included native rule set
##enable_rule             UDEF_EXD_0008_NoSeqPin
##set_rule_severity error UDEF_EXD_0008_NoSeqPin

##disable_rule UDEF_InvalidPartialException ;# This is No optimistic result. Because this rule has already been checked a part of EXC_0006. ;# Removed on 2020.04.30


analyze_design

# READ WAIVER RULES on 2020/6/12
if { ${PTC_USE_WAIVER_RULE} == "true" } {

    if {![info exists PTC_WAIVER_RULE_FILE]} {
        set PTC_WAIVER_RULE_FILE [exec /bin/ls ${PTC_WAIVER_RULE_DIR}]
    } 
    puts "Information: set Waiver RULE ${PTC_WAIVER_RULE_FILE}"

    foreach tmp ${PTC_WAIVER_RULE_FILE} {
        if { [regexp {.tcl} $tmp] } { 
            puts "Information: execute Waiver RULE ${tmp}..."
            source -echo -verbose ${PTC_WAIVER_RULE_DIR}/${tmp}

            if {${tmp} == "remove_DES0002_noise.tcl"} {
                get_pseudo_error_of_DES0002 ;# Waived as Pseudo_Errors for DES_0002
            }
        }
    }
}


#report_constraint_analysis \
#              -format standard -style full \
#              -include {statistics violations user_messages } \
#              -output ./Report/result.GCA_check.${LOAD_MODEL}.${MODE}${NWORD}
#
#report_constraint_analysis \
#              -format standard -style full \
#              -include {violations} \
#              -output ./Report/result.GCA_check.vio.${LOAD_MODEL}.${MODE}${NWORD}

report_constraint_analysis \
              -format csv -style summary \
              -include {violations} \
              -output ./Report/result.GCA_check.vio.${LOAD_MODEL}.${MODE}${NWORD}.summary.csv

report_constraint_analysis \
              -format csv -style full \
              -include {violations} \
              -output ./Report/result.GCA_check.vio_full.${LOAD_MODEL}.${MODE}${NWORD}.summary.csv

#### apply on 2020/6/29
if {[regexp $GCA_VER201903 $sh_product_version]} {

    if {${PTC_HIDE_WAIVED_REPORT} == "true"} {
    	report_constraint_analysis \
		-format csv -style full \
		-include {violations details waiver_info} \
		-output ./Report/result.GCA_check.vio_detail_w_WAIVE.${LOAD_MODEL}.${MODE}${NWORD}.summary.csv

	set_app_var hide_waived_violations true ;# Hide Waived Error/Warning Items
    }

    report_constraint_analysis \
              -format csv -style full \
              -include {violations details waiver_info} \
              -output ./Report/result.GCA_check.vio_detail.${LOAD_MODEL}.${MODE}${NWORD}.summary.csv
}

set_app_var hide_waived_violations false ;# reset hidden wavied items before save session

#### BOTTOM ####
