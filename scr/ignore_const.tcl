########################################################
# v0r01 : Added SDC file name selection. MOBILE/CIS
########################################################

set SDC_IGNORE_CONST_LIST	"./scr/IGNORE_CONST.list"
set TMP_IGNORE_CONST_LIST	".tmp.IGNORE_CONST_LIST"
if  {$STA_METHOD == "MOBILE"} {
	set SDC_FILE_NAME		"./CONST/SDC_integratedDFT.ptsc"
} elseif {$STA_METHOD == "CIS"} {
	set SDC_FILE_NAME		"./CONST/SDC_${DFT_MODE}.ptsc"
}

set I_IGNOR_CONST  [open "${SDC_IGNORE_CONST_LIST}" r]
set O_IGNOR_CONST  [open "${TMP_IGNORE_CONST_LIST}" w]

#---------------------------------------------------------------------
while {[gets $I_IGNOR_CONST str]>=0} {
	if { [regexp "^#" $str] } { continue }
	if { [regexp "^\s*$" [string trim $str]] } { continue }
	set CONST [lindex $str 0]
	puts $O_IGNOR_CONST $CONST
}

close $I_IGNOR_CONST
close $O_IGNOR_CONST

set I_SDC  [open "|gzip -dc ${SDC_FILE_NAME}.ORG.gz | egrep -v -f ${TMP_IGNORE_CONST_LIST}" r]
set O_SDC  [open "|gzip > ${SDC_FILE_NAME}.gz" w]

#----[ Main Loop ]----------------------------------------------------
while {[gets $I_SDC str]>=0} {
	if { [regexp "^#" $str] } { continue }
	if { $str == "" } { continue }
	puts $O_SDC $str
}

eval exec "rm -f ${TMP_IGNORE_CONST_LIST}"

close $I_SDC
close $O_SDC

