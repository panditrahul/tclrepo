

proc panel_review {csvdata} {

# BLOCK: FIND DISPLAYED COMP
clear_marks;
*createmark comps 1 "displayed";
set test [hm_getmark comps 1];
set test [lindex $test 0];
puts "Tool works with only one Displayed Comp.";


# BLOCK: SCAN EACH ROW AND PERFORM ACTIVITY
set comp_list {};
foreach nrow [range 2 3849] {

# GET ALL ROW DATA	
	set rowdata [csv_get $csvdata $nrow [list 1 2 3 4 5 6 7 8 9 10]]; 
	set row [lindex $rowdata 0]; # Get row number
	set cloc [lindex $rowdata 1]; # Get connector location
	set layers [lindex $rowdata 2];
	set comp1 [lindex $rowdata 6];
	set comp2 [lindex $rowdata 7];
	set comp3 [lindex $rowdata 8];
	set warning [lindex $rowdata 9];
	
	if {($comp1 == $test ) || ($comp2 == $test) || ($comp3 == $test)} {
	set nid [create_node $cloc];
	set rowdata [join_list "RowNo:" $nrow "," $layers "," $comp1 "," $comp2 "," $comp3 ","  $warning "," $nid];
	set rowdata [replace "{" "" $rowdata];
	set rowdata [replace "}" "" $rowdata]; puts $rowdata;
	lappend comp_list [list $comp1 $comp2 $comp3];
	}	
	
}

# BLOCK: ISOLATE THE COMPS
set comp_list [replace "{" "" $comp_list];
set comp_list [replace "}" "" $comp_list];
isolate_comps $comp_list;

}