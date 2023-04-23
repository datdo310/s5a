source ./scr/r_tcl.proc.tcl
source ./Mk_pin_multi_false/proc_pin_multi_false.tcl
set PAD_INST    PFC_TOP

mk_inputAC_false  $PAD_INST ./Mk_pin_multi_false/Input_True.list  ./Mk_pin_multi_false/sample_Const_false_InAC.tcl
mk_outputAC_false $PAD_INST ./Mk_pin_multi_false/Output_True.list ./Mk_pin_multi_false/sample_Const_false_OutAC.tcl

