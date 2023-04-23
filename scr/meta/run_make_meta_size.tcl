#-------------------------------------------------------------------------------
# set variables for your product
#-------------------------------------------------------------------------------
set ver         v003_eco01
set product_dir /svhome/rhflash/data/u2c8
set const_dir   ${product_dir}/4_implement/48_constraints
set sta_dir     ${product_dir}/4_implement/46_sta
set scr_dir     ./scr/meta
set HALF_LIST_SYSTEM ${scr_dir}/system_half.list
#-------------------------------------------------------------------------------

if { $STA_MODE == "SYSTEM"} {
    set mode system
    set HALF_LIST $HALF_LIST_SYSTEM
} elseif { $DFT_MODE == "SCAN" } {
    set mode scan 
} elseif { $DFT_MODE == "MBIST" } {
    set mode mbist
} else {
    puts "* Error: The variable \"mode\" is unknown. "
}

if { [info exists mode] } {
    if {$mode == "system" } {
        cat ${const_dir}/${ver}/480_timing/META/SYS_SYNC_FF.list | sort -u > ${scr_dir}/METAFF_SYS_sort.list
        set SYNC_FF_LIST ${scr_dir}/METAFF_SYS_sort.list
    } elseif { $mode == "scan" } {
        cat ${const_dir}/${ver}/480_timing/META/SCAN_SYNC_FF.list | sort -u > ${scr_dir}/METAFF_SCAN_sort.list
        set SYNC_FF_LIST ${scr_dir}/METAFF_SCAN_sort.list
    } elseif { $mode == "mbist" } {
        cat ${const_dir}/${ver}/480_timing/META/MBIST_SYNC_FF.list | sort -u > ${scr_dir}/METAFF_MBIST_sort.list
        set SYNC_FF_LIST ${scr_dir}/METAFF_MBIST_sort.list
    } else {
        puts "* Error: There is no SYNC_FF.list related ${mode} mode."
    }
    
    if { [info exists SYNC_FF_LIST] } {
        set date [sh date '+%m%d']
        set outdir ./meta/${date}
        sh mkdir -p $outdir

        set OUT_INFO_FILE  $outdir/${mode}_meta.info
        set OUT_SIZE_TCL   $outdir/size_cell_meta_${mode}.tcl
        set OUT_ANNO       $outdir/annotated_delay_meta_${mode}.tcl

        source -echo -verbose ${scr_dir}/make_meta_size.tcl
    }
}
