# GCA check script for MCU
# v0r00	2014.01.07	Y.Oda      1st draft
# v0r03 2014.11.13      y.Oda      Change rule
# v0r04 2015.02.07      Y.Oda      comment out unneeded report
# v0r05 2018.06.12      A.Yoshida  Support PTC (exchanged from GCA) and set rule V02.01.05

#source -verbose /common/appl/Renesas/GCA/tcl/UDEF_Renesas.tcl
#source -verbose /common/appl/Renesas/GCA/RULES/V010700/tcl/UDEF_Renesas.tcl;
#source -verbose /common/appl/Renesas/GCA/RULES/V010800/tcl/UDEF_Renesas.tcl;
#source -verbose /common/appl/Renesas/GCA/RULES/V010900/tcl/UDEF_Renesas.tcl;
 source -verbose /common/appl/Renesas/GCA/RULES/V020105/tcl/UDEF_Renesas.tcl;


# Setup Renesas ruleset
RenesasCommonRule_STA		;# For STA

# enable_rule  [list *]
# disable_rule ${GCA_DISABLE_RULE}

#### SET CUSTOM RULES as follows,
source -verbose         ./scr/GCA_CUSTOM_RULES/UDEF_EXD_0008_NoSeqPin.tcl
enable_rule             UDEF_EXD_0008_NoSeqPin
set_rule_severity error UDEF_EXD_0008_NoSeqPin

disable_rule UDEF_InvalidPartialException ;# This is No optimistic result. Because this rule has already been checked a part of EXC_0006.


analyze_design
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

