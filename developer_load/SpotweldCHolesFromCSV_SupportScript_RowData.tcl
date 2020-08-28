
	
# GET RELEVANT CSV DATA FOR GIVEN NROW
	set rowdata [csv_get $csvdata $nrow [list 1 2 3 4 5 6 7 8 9 10 11 12]]; 
	set row [lindex $rowdata 0]; # Get row number
	set cloc [lindex $rowdata 1]; # Get connector location
	set comp1 [lindex $rowdata 7]; set comp1 [lindex $comp1 0]; set comp1 [lindex $comp1 0]; # Get comp1
	set comp2 [lindex $rowdata 8]; set comp2 [lindex $comp2 0]; set comp2 [lindex $comp2 0];# Get comp2
	set comp3 [lindex $rowdata 9]; set comp3 [lindex $comp3 0]; set comp3 [lindex $comp3 0]; #Get comp3
	clear_marks;
	
# FIND COMPS IN Nth ROW -> FIND DISPLAYED COMPS -> FIND COMMON COMPS
	eval *createmark comps 1 [list $comp1 $comp2 $comp3];
	eval *createmark comps 2 "displayed";
	set csv_comps [hm_getmark comps 1];
	set disp_comps [hm_getmark comps 2];
	set comps [intersection $csv_comps $disp_comps];