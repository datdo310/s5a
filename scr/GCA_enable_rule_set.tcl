## Enalble/Disabled RULEs for reduced Pseudo-Errors of ABU(R-Car/AMCU) w/ on 2020/10/12
if {[regexp $GCA_VER201903 $sh_product_version]} {
    if { $::dalt::version == "V02.01.06a3" } {
        set PTC_ENABLE_RULES [list \
            DES_0003 \
        ]

        set PTC_DISABLE_RULES [list \
            CLK_0033 \
            CNL_0005 \
            CTR_0006 \
            DRV_0001 \
            TRN_0001 \
            UDEF_InputDelayCheck_0001 \
            UDEF_OutputDelayCheck_0001 \
            UDEF_ReportThPointException \
            UDEF_VclkSrcLatencyCheck \
            UDEF_ZeroValueSetInOutDly \
            UDEF_InvalidPartialException \
        ]

        enable_rule             ${PTC_ENABLE_RULES}
        set_rule_severity error DES_0003

        disable_rule ${PTC_DISABLE_RULES}
    }
}
