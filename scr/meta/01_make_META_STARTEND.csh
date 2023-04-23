#!/bin/csh

foreach mod (DBG_TOP MEM_TOP PERI_TOP PFC_TOP PFSS_TOP SYS_TOP TEST_TOP)
    grep "$mod" apply/META/SYS_SYNC_FF.list | awk '{print "report_timing -nosplit -start_end_pair -sort_by group -slack_lesser_than inf -to [get_pins -of [get_cells", $1"] -filter \"is_data_pin==true\"]"}' > ENDPOINT_METAS_$mod.tcl
    grep "$mod" apply/META/SYS_SYNC_FF.list | awk '{print "report_timing -nosplit -start_end_pair -sort_by group -slack_lesser_than inf -from [get_pins -of [get_cells", $1"] -filter \"is_clock_pin==true\"]"}' > STARTPOINT_METAS_$mod.tcl
end
