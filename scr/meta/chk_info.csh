#!/bin/csh -f

mkdir -p work
cd work
foreach f (`ls -1tr ../*.info`)
    set mode = `echo $f:t:r | sed 's/_meta//'`
    echo "Mode: $mode"
    grep Error $f > $mode.error
  
    if (! -z $mode.error ) then
        grep "No cell"     $mode.error > no_cell.$mode
        grep no_clock      $mode.error > no_clock.$mode
        grep unconstrained $mode.error > unconst.$mode
        grep timing        $mode.error > 800m.$mode
        grep -v "No cell"  $mode.error | grep -v no_clock | grep -v unconstrained | grep -v timing > other.$mode

        if (! -z 800m.$mode ) then
            awk -F, '$8 != 1.230 {print}' 800m.$mode > 800m.${mode}_NG
        endif
    endif

    awk -F, '{print $2,$4}' $f | grep DFF | grep -v ZMX | grep -v SDFSYN | grep -v T5C | grep -v SDFF | sort -u > dff.$mode
end
