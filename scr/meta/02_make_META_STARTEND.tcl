foreach mod {DBG_TOP MEM_TOP PERI_TOP PFC_TOP PFSS_TOP SYS_TOP TEST_TOP} {
    echo "* Information: Getting ENDPOINTs of META $mod..."
    source -echo -verbose ENDPOINT_METAS_$mod.tcl > ENDPOINT_METAS_${mod}_path.rep
    exec apply/Kobetsu/Checker/x_go_rep2csv_mod ENDPOINT_METAS_${mod}_path.rep ENDPOINT_METAS_${mod}_path.csv.tmp
    exec perl ./scr/meta/META_STARTEND_attach_person.pl ENDPOINT_METAS_${mod}_path.csv.tmp ENDPOINT_METAS_${mod}_path.csv
    exec perl ./scr/meta/make_excel_META_STARTEND.pl ENDPOINT_METAS_${mod}_path.csv $mod
    exec rm ENDPOINT_METAS_${mod}_path.csv.tmp

    echo "* Information: Getting STARTPOINTs of META $mod..."
    source -echo -verbose STARTPOINT_METAS_$mod.tcl > STARTPOINT_METAS_${mod}_path.rep
    exec apply/Kobetsu/Checker/x_go_rep2csv_mod STARTPOINT_METAS_${mod}_path.rep STARTPOINT_METAS_${mod}_path.csv.tmp
    exec perl ./scr/meta/META_STARTEND_attach_person.pl STARTPOINT_METAS_${mod}_path.csv.tmp STARTPOINT_METAS_${mod}_path.csv
    exec perl ./scr/meta/make_excel_META_STARTEND.pl STARTPOINT_METAS_${mod}_path.csv $mod
    exec rm STARTPOINT_METAS_${mod}_path.csv.tmp
}
