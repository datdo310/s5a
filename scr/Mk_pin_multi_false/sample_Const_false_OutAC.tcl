#########################################################################################
#   False setting of Output multiple AC
#      Made by mk_outputAC_false : Sat Jan 18 13:59:38 2014
#########################################################################################
#
# Target port : P4_1
#
#set_false_path -through [r_get_cellpin PFC_TOP/adcsm0_dt_adflag3] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/adcsm1_dt_adflag3] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/gtm_atom0_out_2] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/pic2_HZOUT0] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]

#
# Target port : P4_1
#
#set_false_path -through [r_get_cellpin PFC_TOP/adcsm0_dt_adflag3] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/adcsm1_dt_adflag3] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/gtm_atom0_out_2] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/pic2_HZOUT0] -through [get_ports P4_1] -to [get_clocks v_clk_lsb_adc]

#
# Target port : P5_4
#
#set_false_path -through [r_get_cellpin PFC_TOP/gtm_atom0_out_1] -through [get_ports P5_4] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/adcsm1_adend0] -through [get_ports P5_4] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/exbc_mdout[11]] -through [get_ports P5_4] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/pic2_HZOUT0] -through [get_ports P5_4] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/exbc_mdc[1]] -through [get_ports P5_4] -to [get_clocks v_clk_lsb_adc]

#
# Target port : P5_5
#
#set_false_path -through [r_get_cellpin PFC_TOP/rlin31_lin3_tx_out] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/adcsm0_adend0] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/gtm_atom0_out_4] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/csih0_top_csihtso0] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/exbc_mdout[12]] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/csih0_csih0sso] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]
#set_false_path -through [r_get_cellpin PFC_TOP/exbc_mdc[1]] -through [get_ports P5_5] -to [get_clocks v_clk_lsb_adc]

