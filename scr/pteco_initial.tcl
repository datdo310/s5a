##############################################
# sub script for PTECO MCU Products
#  for making environment for child process


## initialize file and directory
sh mkdir LOG ${REPORT_DIR} ${APPLY_DIR}
sh ln -s ../../scr   .
sh ln -s ../../DB    .
sh ln -s ../../Gate  .
sh ln -s ../../LOAD  .
sh ln -s ../../bin   .
sh ln -s ../../PTECO     .
sh cp    ../../*.cfg .

source ./scr/common_proc.tcl
READ_PATH_INFO
cd ${APPLY_DIR}
sh cp -r ../../../${APPLY_DIR}/DFT       .
sh cp -r ../../../${APPLY_DIR}/System    .
sh ln -s ../../../${APPLY_DIR}/A*        .
sh ln -s ../../../${APPLY_DIR}/DFT_mask_info .
sh ln -s ../../../${APPLY_DIR}/META      .
sh ln -s ../../../${APPLY_DIR}/Skew      .
sh ln -s ../../../${APPLY_DIR}/dont_use  .
cd ..

## Additional constraints

if {$ADD_CONST != ""} {
     puts "Checking $ADD_CONST"
     ERROR_FILE  $ADD_CONST
#     APPEND_FILE $ADD_CONST $FILE_TENTATIVE
}

## delete warning for avoiding disk full (delete RC-004 RC-005 RC-009 RC011)
set sh_limited_messages { DES-002 PARA-004 PARA-006 PARA-007 PARA-040 PARA-041 PARA-043 PARA-044 \
       PARA-045  PARA-046  PARA-047  PARA-050  PARA-051 PARA-053 RC-002  \
       RC-104 PTE-014 PTE-060 PTE-070  SDF-036 UITE-494 LNK-039 LNK-038 }


