clear;


# INCLUDE LIBRARIES AND CSV FILES TO READ
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/mahindra_load/mahindra_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/csv_load/csv_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/general_load/general_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/surface_load/surface_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/solid_load/solid_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/mahindra_load/mahindra_load_II.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/mahindra_load/mahindra_load_III.tcl";
set csvdata [csv_read "P:/InDepth-MethodsDev/21-hmtools/hmtools/mahindra_toolset/SpotweldConnectorsCSVReview/SpotweldConnectorsCSVReview_Final.csv"];
#
#
proc clear_tabs {} {

hm_framework removetab "MeshControls";
hm_framework removetab "EntityState";
hm_framework removetab "Connector";
hm_framework removetab "Visualization";
hm_framework removetab "Entity State";

}
#
#
proc collapse_all {} {

hm_framework removetab "Model";
hm_framework addtab "Model";

}
#
#
proc clear_model {} {

*nodecleartempmark;
set entities [list "surfs" "points" "lines"];

foreach entity $entities {
*createmark $entity 1 "displayed";
*maskentitymark points 1 0;
}

}
#
#
proc next_comp {} {

# FIND ALL COMP IDS AND STORE IT
*createmark comps 1 "all";
set all_comps [hm_getmark comps 1];

# FIND THE CURRENT COMP
set current_comp_name [hm_info currentcomponent];
*createmark comps 1 "by name" $current_comp_name;
set current_comp [hm_getmark comps 1];

# FIND THE INDEX OF THE CURRENT-COMP IN ALL COMPS
set index [lsearch $all_comps $current_comp]; puts $index

# FIND NEXT COMP-ID INDEX
set next_comp [expr $index +1];
set next_comp [lindex $all_comps $next_comp];
set_comp $next_comp;

# ISOlATE THE NEXT COMP
*createmark comps 1 $next_comp;
*isolateentitybymark 1;

# DISPLAY COMMENT
clear;
*nodecleartempmark;
puts [join_list "CurrentCompID:" $next_comp "Name:" $current_comp_name];
*window 0 0 0 0 0;
*view "iso1";

}
#
#
proc back_comp {} {


# FIND ALL COMP IDS AND STORE IT
*createmark comps 1 "all";
set all_comps [hm_getmark comps 1];

# FIND THE CURRENT COMP
set current_comp_name [hm_info currentcomponent];
*createmark comps 1 "by name" $current_comp_name;
set current_comp [hm_getmark comps 1];

# FIND THE INDEX OF THE CURRENT-COMP IN ALL COMPS
set index [lsearch $all_comps $current_comp]; puts $index

# FIND NEXT COMP-ID INDEX
set next_comp [expr $index -1];
set next_comp [lindex $all_comps $next_comp];
set_comp $next_comp;

# ISOlATE THE NEXT COMP
*createmark comps 1 $next_comp;
*isolateentitybymark 1;

# DISPLAY COMMENT
clear;
*nodecleartempmark;
puts [join_list "CurrentCompID:" $next_comp "Name:" $current_comp_name];
*window 0 0 0 0 0;
*view "iso1";

}
#
#
proc hm_catia_rowcheck {csvdata nrow} {

# BLOCK-0: THRESHOLDS
set threshold 2;

# BLOCK-1: GET ALL ROW DATA	
	set rowdata [csv_get $csvdata $nrow [list 1 2 3 4 5 6 7 8 9 10 11 12]]; 
	set row [lindex $rowdata 0]; # Get row number
	set cloc [lindex $rowdata 1]; set cloc [lindex $cloc 0]; # Get connector location
	set layers [lindex $rowdata 3]; # Get layers
	set comp1 [lindex $rowdata 7]; set comp1 [lindex $comp1 0]; set comp1 [lindex $comp1 0]; # Get comp1
	set comp2 [lindex $rowdata 8]; set comp2 [lindex $comp2 0]; set comp2 [lindex $comp2 0];# Get comp2
	set comp3 [lindex $rowdata 9]; set comp3 [lindex $comp3 0]; set comp3 [lindex $comp3 0]; #Get comp3
	clear_marks;
	
# BLOCK-2: CREATE NODE AT CLOC
	set nid [create_node $cloc];
	
# BLOCK-3: FIND ALL THE COMPS 
	eval *createmark comps 1 [list $comp1 $comp2 $comp3];
	set comps [hm_getmark comps 1];
	*isolateentitybymark 1; *window 0 0 0; 

# BLOCK-4: FOR EACH COMP-> PROJECT NODE -> FIND DIST & VECTOR
	set node_dist {}; 
	set node_list {};
	set norm_list {};
	foreach cid $comps { 
	set output [project_nodeon_comp $nid $cid];
	lappend node_list [lindex $output 0];
	lappend node_dist [lindex $output 1];
	lappend norm_list [lindex $output 2];
	}

# BLOCK-5: CHECK IF ALL THE DISTANCES ARE WITHIN TOLERANCE
set max_dist [lsort -decreasing -real $node_dist];
if {[lindex $max_dist 0] > $threshold} { return "Warning"}


# BLOCK-6: CHECK IF VECTOR CROSS-PRODUCT IS CORRECT
# WIP

}
#
#
proc logfile {filename data} {

set loc [file dirname [info script]];
set logfile $loc$filename;	
set file [open $logfile "w+"];
foreach out $data { 
puts $file $out;
}
close $file;

}
#
#
proc endcode {t} {

puts [join_list "Execution-Time:" [time_out $t] "seconds."];

}







return
# BLOCK: CREATE COMP FOR VISUAL-CYLINDERS
*nodecleartempmark;
set comp [get_comp "SpotWelds"];
set comp [lindex $comp 0];
set prop [review_beams];
set_comp_prop $comp $prop;

# BLOCK: PEFORM OPERATION
set t [time_in];
foreach row $nrow {
catiarow_punch $csvdata $row;
}
endcode $t;






















return 
# BLOCK-1: READ CSV FILE
set csvdata [csv_read "P:/InDepth-MethodsDev/21-hmtools/hmtools/mahindra_toolset/SpotweldConnectorsCSVReview/SpotweldConnectorsCSVReview.csv"];

# SCAN EACH ROW AND PERFORM REVIEW
set warning_rows {};
	foreach nrow [range 2 3849] {
	*nodecleartempmark; set output [hm_catia_rowcheck $csvdata $nrow];
	if {$output == "Warning"} { lappend warning_rows $nrow; puts $nrow; }}


































return

clear; *nodecleartempmark;  set t [time_in];

# BLOCK-1: READ CSV FILE.
set csvdata [csv_read "P:/InDepth-MethodsDev/21-hmtools/hmtools/mahindra_toolset/SpotweldConnectorsCSVReview/SpotweldConnectorsCSVReview.csv"];


# BLOCK-2: BOOK-KEEPING
set logdata {};
set log [join_list "RowNo" "," "Layers" "," "MaxDist" "," "STATUS"]; puts $log;
lappend logdata $log;

*startnotehistorystate; # Begin History State
foreach nrow [range 225 230] {

# BLOCK-3: GET ALL ROW DATA	
	set rowdata [csv_get $csvdata $nrow [list 1 2 3 4 5 6 7 8 9 10 11 12]]; 
	set row [lindex $rowdata 0]; # Get row number
	set cloc [lindex $rowdata 1]; # Get connector location
	set layers [lindex $rowdata 3]; # Get layers
	set comp1 [lindex $rowdata 7]; set comp1 [lindex $comp1 0]; set comp1 [lindex $comp1 0]; # Get comp1
	set comp2 [lindex $rowdata 8]; set comp2 [lindex $comp2 0]; set comp2 [lindex $comp2 0];# Get comp2
	set comp3 [lindex $rowdata 9]; set comp3 [lindex $comp3 0]; set comp3 [lindex $comp3 0]; #Get comp3
	clear_marks;


# BLOCK-4: CREATE NODE
	set nid [create_node [lindex $cloc 0]];
	

# BLOCK-5: FIND ALL COMPS IN THE Nth ROW AND ISOLATE THEM
	eval *createmark comps 1 [list $comp1 $comp2 $comp3];
	set comps [hm_getmark comps 1];
	*isolateentitybymark 1;
	*window 0 0 0 0 0;

	
# BLOCK-6:
	foreach cid $comps { 
	
	# FIND NEAREST SURFACE AND THE NODE-ID OF PROJECTED NODE
	set out [node_comp_distance $nid $cid];
	set nsurf [lindex $out 0];
	set dist [lindex $out 1];
	set nid2 [lindex $out 2];

	
	# FIND THE NORMAL TO THE SURFACE
	set normal [find_surface_normal $nsurf $nid2];
	
	# CREATE CYLINDER
	set solid2 [create_cylinder $nid2 $normal 3.0 15];
	
	# PERFORM TRIMMING OPERATION
	*createmark solids 1 "by comp" $cid;
	set solid1 [hm_getmark solids 1];
	solid_boolean_subtract $solid1 $solid2;
	
	}
	
	
}
*endnotehistorystate; # End History State

# # BLOCK-4: FOR EACH COMP IN THR ROW FIND THE DISTANCE FROM THE CONNECTOR AND GET THE STATUS
	# set dist_list {}; set status "";
	# foreach cid $comps { lappend dist_list [node_comp_distance $nid $cid]; }
	
	# set dist_list [lsort -decreasing $dist_list]; 
	# set max_dist [lindex $dist_list 0];
	# if {$max_dist > 5} { set status "ISSUE"; }
	
	# set log [join_list $nrow "," $layers "," $dist_list "," $status];
	# puts $log; lappend logdata $log;
	
# }


# # BLOCK-5: WRITE THE LOGDATA AND DISPLAY EXECUTION TIME
# set csvloc [file dirname [info script]];
# set csvfile "/SpotweldConnectorsFromCSV-Status.csv";
# set logfile $csvloc$csvfile;	
# set file [open $logfile "w+"];
# foreach out $logdata { puts $file $out; }; close $file;
# puts "--------------------------------------"
# puts [join_list "Execution-Time:" [time_out $t] "seconds."];




























