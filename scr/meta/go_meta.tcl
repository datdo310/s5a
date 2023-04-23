set meta_dir "meta/[sh date '+%m%d']"
restore_session ./LOAD/save.NO_LOAD.MAX_LT3V_DFT_SETUP_MBIST
source ./scr/meta/run_make_meta_size.tcl
restore_session ./LOAD/save.NO_LOAD.MAX_LT3V_DFT_SETUP_SCAN
source ./scr/meta/run_make_meta_size.tcl
restore_session ./LOAD/save.NO_LOAD.MAX_LT3V_SYSTEM_SETUP
source ./scr/meta/run_make_meta_size.tcl
source $meta_dir/size_cell_meta_system.tcl
source $meta_dir/annotated_delay_meta_system.tcl
update_timing
exec csh ./scr/meta/01_make_META_STARTEND.csh
source ./scr/meta/02_make_META_STARTEND.tcl
