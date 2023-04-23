##################################################
#
# Fix transition value. Adjust transition value to design definition.
#
# Version  : v1r1 2012/08/09
# Comment  : Fixed getting threshold value.
#
##################################################

proc CHECK_PT_SHELL {} {
	if {[info exists ::synopsys_program_name] && $::synopsys_program_name == "pt_shell"} {
		return 0
	} else {
		puts stderr "* Error: Runs only PT-shell."
		return 1
	}
}

# filx transition value
proc FIX_TRANSITION {FILE_NAME} {
	# check environment
	if {[CHECK_PT_SHELL]} {return 1}
	if {![info exists ::TOP]} {
		puts {* Error: Undefined variable '$TOP'}
		return 1
	}

	# init values
	set cond "max"
	set flag 0

	# get design attribute
	set des_derate         [get_attri [get_designs $::TOP] rc_slew_derate_from_library]
	set des_thr_lower_fall [get_attri [get_designs $::TOP] rc_slew_lower_threshold_pct_fall]
	set des_thr_lower_rise [get_attri [get_designs $::TOP] rc_slew_lower_threshold_pct_rise]
	set des_thr_upper_fall [get_attri [get_designs $::TOP] rc_slew_upper_threshold_pct_fall]
	set des_thr_upper_rise [get_attri [get_designs $::TOP] rc_slew_upper_threshold_pct_rise]
	# check threshold value is same in rise/fall.
	if {$des_thr_lower_fall != $des_thr_lower_rise || $des_thr_upper_fall != $des_thr_upper_rise} {
		puts "* Error: Cannot fix transition. Different threshold rise/fall value for Design."
		puts "         rc_slew_lower_threshold_pct_fall: $des_thr_lower_fall"
		puts "         rc_slew_lower_threshold_pct_rise: $des_thr_lower_rise"
		puts "         rc_slew_upper_threshold_pct_fall: $des_thr_upper_fall"
		puts "         rc_slew_upper_threshold_pct_rise: $des_thr_upper_rise"
		return 1
	} else {
		set des_thr_lower $des_thr_lower_fall
		set des_thr_upper $des_thr_upper_fall
	}


	set c_val [catch {set fid [open $FILE_NAME]} code]
	if {$c_val} {
		puts stderr "* Error: $code"
		return 1
	}
	while {[gets $fid str] >= 0} {
		if {[regexp {^$} $str]} {set flag 0}
		if {$flag == 1} {
			# check input line
			if {[llength $str] != 5 && [llength $str] != 8} {
					puts "* Error: Missing data. $str"
					return 1
			}
			set pin   [lindex $str 0]
			set req   [lindex $str 1]
			set act   [lindex $str 2]
			set judge [lindex $str 4]
			if {![string is double $req]} {puts "# req # $str"}
			if {![string is double $act]} {puts "# act # $str"}
			if {![string is double [lindex 3]]} {puts "# slack # $str"}

			if {[sizeof_collection [get_ports -quiet $pin]] > 0} {puts $str; continue }
			if {[sizeof_collection [get_pins         $pin]] > 0} {
				if {$pin == [get_object_name [get_pins $pin]]} {
					set pin_obj [get_pins $pin]
					set delay_cond "_${cond}"
				} else {
					set cell_pin [regsub {.*/} $pin ""]
					set lib_cell [get_object_name [get_lib_cells -of [get_cells -of $pin]]]
					set pin_obj [get_lib_pins "${lib_cell}/${cell_pin}"]
					set delay_cond ""
				}
					set pin_derate         [get_attri $pin_obj rc_slew_derate_from_library${delay_cond}]
					set pin_thr_lower_fall [get_attri $pin_obj rc_slew_lower_threshold_pct_fall${delay_cond}]
					set pin_thr_lower_rise [get_attri $pin_obj rc_slew_lower_threshold_pct_rise${delay_cond}]
					set pin_thr_upper_fall [get_attri $pin_obj rc_slew_upper_threshold_pct_fall${delay_cond}]
					set pin_thr_upper_rise [get_attri $pin_obj rc_slew_upper_threshold_pct_rise${delay_cond}]
				if {($pin_thr_lower_rise != $pin_thr_lower_rise) || ($pin_thr_upper_fall != $pin_thr_upper_rise)} {
					puts "* Error: Cannot fix transition. Pin threshold rise/fall values are different."
					puts "         $pin"
					puts "         rc_slew_lower_threshold_pct_fall: $pin_thr_lower_fall"
					puts "         rc_slew_lower_threshold_pct_rise: $pin_thr_lower_rise"
					puts "         rc_slew_upper_threshold_pct_fall: $pin_thr_upper_fall"
					puts "         rc_slew_upper_threshold_pct_rise: $pin_thr_upper_rise"
					return 1
				} else {
					set pin_thr_lower $pin_thr_lower_fall
					set pin_thr_upper $pin_thr_upper_fall
				}
				#
				if {$des_derate == $pin_derate && $des_thr_upper == $pin_thr_upper && $des_thr_upper == $pin_thr_upper} {
					puts $str; continue
				} else {
					set multi "(($des_thr_upper - $des_thr_lower) / $des_derate) / (($pin_thr_upper - $pin_thr_lower) / $pin_derate)"
					set c_val [catch {set aaa [expr $multi]} code]
					if {$c_val} {
						puts "* Error: $code"
						puts $multi
						puts $str
						return 1
					}
					set fpoint [expr [string length $req] - [string last "." $req] - 1]
					set req_fixed [expr $req * $multi]
					set act_fixed [expr $act * $multi]
					set vio_fixed [expr $req_fixed - $act_fixed]

					puts [format "   #fix(%.${fpoint}f) %s" [expr $multi] $str]
					puts [format "   %s %5.${fpoint}f %5.${fpoint}f %5.${fpoint}f %s" $pin $req_fixed $act_fixed $vio_fixed $judge]

					# make library derate and slew_threshold value list.
					set lib [get_object_name [get_libs -of [get_lib_cells -of [get_cells -of $pin]]]]
					if {[info exists fixed(${lib},slew_derate)]} {
						if {$fixed(${lib},rc_slew_derate_from_library) != $pin_derate || \
						    $fixed(${lib},rc_slew_lower_threshold_pct_fall) != $pin_thr_lower || \
						    $fixed(${lib},rc_slew_lower_threshold_pct_rise) != $pin_thr_upper} {
							puts "# Information: derate or threshold value mismatch."
							puts "# for pin: $pin"
							puts "#         derate: $pin_derate thr_lower: $pin_thr_lower thr_upper: $pin_thr_upper"
							puts -nonewline "# before: derate: fixed(${lib},rc_slew_derate_from_library)"
							puts -nonewline " thr_lower: fixed(${lib},rc_slew_lower_threshold_pct_fall)"
							puts            " thr_upper: fixed(${lib},rc_slew_lower_threshold_pct_rise)"
						}

					} else {
						set fixed(${lib},rc_slew_derate_from_library) $pin_derate
						set fixed(${lib},rc_slew_lower_threshold_pct_fall) $pin_thr_lower
						set fixed(${lib},rc_slew_lower_threshold_pct_rise) $pin_thr_upper

					}
				}
				#break
			}
		} else {
			puts $str
		}
		if {[regexp {^\s*--*$} $str]} {set flag 1}
		if {[regexp {^\s*-min_transition$} $str]} {set cond "min"}
	}
	close $fid

	# output library derate and slew threshold value info
	set c_val [catch {set fid [open ${FILE_NAME}.info w]} code]
	if {$c_val} {
		puts stderr "* Error : $code"
		return 1
	}
	puts $fid ""
	puts $fid "# library derate and slew threshold values"
	puts $fid "Design : $::TOP"
	puts $fid ""
	puts $fid "For design"
	puts $fid "   design rc_slew_derate_from_library  $des_derate"
	puts $fid "   design rc_slew_lower_threshold_pct_fall  $des_thr_lower"
	puts $fid "   design rc_slew_lower_threshold_pct_rise  $des_thr_upper"
	puts $fid ""
	puts $fid "For library"
	foreach name [lsort [array names fixed]] {
		puts $fid [format "   %s  \t%f" [regsub {,} $name "\t "] $fixed($name)]
	}
	close $fid
};# end proc

define_proc_attributes FIX_TRANSITION \
 -info "adjust transition value to the design." \
 -define_args {
  {FILE_NAME  "slew report file"            "FILE_NAME"          string required}
 }


