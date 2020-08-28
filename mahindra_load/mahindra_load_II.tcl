
# ----- SUPPORT TOOLS FOR CSV REVIEW SCRIPT-I (FETCH DATA) ----------------- #

# INCLUDE LIBRARIES
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/csv_load/csv_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/general_load/general_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/surface_load/surface_load.tcl";

# ------------------------- GLOBAL LOAD CSV FILES -------------------------------- #
#
proc load_spotdata {} {

	global spotdata;
	set spotdata [csv_read "P:/InDepth-MethodsDev/21-hmtools/hmtools/mahindra_toolset/SpotweldConnectorsCSVReview/SpotweldConnectorsCSVReview_Final.csv"];

}
#
# ----- SUPPORT TOOLS FOR CSV REVIEW SCRIPT-I (FETCH DATA) ----------------- #
#
proc get_model_info {} {

hm_markclearall 1; hm_markclearall 2;

# FIND COMPONENT IDS OF ALL COMPS
*createmark comps 1 "all";
set comp_ids [hm_getmark comps 1];

# SCAN THROUGH ALL COMPS AND DOCUMENT PRN AND NAME
set prn {};
set name {};
set compid {};
	foreach comp_id $comp_ids {
	set comp_name [hm_getcollectorname comps $comp_id];
	set comp_name [split $comp_name "_"];
	
	lappend prn [lindex $comp_name 0];
	lappend name [lindex $comp_name end];
	lappend compid $comp_id;
	
}

# RETURN PRN AND NAME
return [list $prn $name $compid];

}
#
proc get_prn_from_jcpn {jcpn_list} {

# 
set prn {};
set layers 3;
	foreach jcpn $jcpn_list {
		set jcpn [split $jcpn "_"];	
		set jcpn [lindex $jcpn 0];
		if {$jcpn == "N/A"} { set jcpn "N/A"; set layers [expr $layers -1]; };
		lappend prn [lindex $jcpn 0];
	}
return [list $prn $layers];
}
#
proc get_compid_from_prn {PRN cloc} {

# GET ALL PRN NAME AND COMP-ID FROM THE MODEL
set model_info [get_model_info]; # Find $prn $name $compid

# CASE:1- IF PASSED PRN IS "N/A"
if {$PRN == "N/A"} { return "N/A";} 
	
# FIND INDEX
set index [lsearch -all [lindex $model_info 0] $PRN];

# CASE:2- NO COMPS ARE FOUND, RETURN {NOT-FOUND} {NOT-FOUND}
if {[llength $index] == 0} { return "Not-Found"; } 

# CASE:3- ONLY ONE COMP FOUND, RETURN {COMP-ID} {COMP-ID}
if {[llength $index] == 1} { return [lindex [lindex $model_info 2] $index];	} 

# CASE:4- MORE THAN ONE COMP FOUND, RETURN {CLOSEST COMP-ID} {COMP-IDS}
if {[llength $index] > 1} { 
	set comp_list {};
	
	foreach ind $index { 
	lappend comp_list [lindex [lindex $model_info 2] $ind];
	}
	
	set nid [create_node $cloc];
	set nearest_surf [find_nearest_surface $nid $comp_list];
	set nearest_comp [get_comp_from_entity "surfs" $nearest_surf];
	
	return [list $nearest_comp $comp_list];
}

}
#
# ----- SUPPORT TOOLS FOR CSV REVIEW SCRIPT-II (WARNINGS) --------------- #
#
proc catia_proximity {cloc comp_list} {

# BLOCK-0: THRESHOLDS
set threshold 5;

# BLOCK-2: CREATE NODE AT CLOC
	set nid [create_node $cloc];
	
# BLOCK-3: FIND ALL THE COMPS 
	eval *createmark comps 1 $comp_list;
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
if {[lindex $max_dist 0] > $threshold} { return "Warning: Comps Away From Spot Location."}


# BLOCK-6: CHECK IF VECTOR CROSS-PRODUCT IS CORRECT
# WIP

}
#
proc catia_missing {comp_list} {


	set COMP1 [lindex $comp_list 0];
	set COMP2 [lindex $comp_list 1];
	set COMP3 [lindex $comp_list 2];
	
	# CHECK IF ALL COMPS ARE PRESENT
	set comment " ";
	if {($COMP1 == "Not-Found") || ($COMP2 == "Not-Found") || ($COMP3 == "Not-Found")} {
	set comment "Warning: Missing CAD."; }

}
#
# ----- SUPPORT TOOLS FOR ELEM BASED ROW REVIEW---------- #
#
proc review_beams {} {

*createmark props 1 "by name" "Review_Beam";
set props [hm_getmark props 1];

if {$props == ""} {

# BULK: CREATE BEAM SECT
*beamsectioncreatestandardsolver 11 0 "HMCirc" 0
*beamsectionsetdataroot 1 1 0 2 7 1 0 1 1 0 0 0 0
*createdoublearray 3 2.125 2.125 2.125;
*beamsectionsetdatastandard 1 3 1 11 0 "HMCirc"
set beamsect [hm_entitymaxid beamsect];


# CREATE PROPERTY
*createentity props cardimage=PSHELL name="Review_Beam";
set props [hm_entitymaxid props];
*setvalue props id=$props cardimage="PBEAML";
*setvalue props id=$props STATUS=2 3186={beamsects $beamsect};
*createmark properties 1 "Review_Beam"
*syncpropertybeamsectionvalues 1
}


*createmark props 1 "by name" "Review_Beam";
set props [hm_getmark props 1];
return $props;

}
#
proc visualize_cylinder {nid vector} {

set nid2 [copy_entity nodes $nid]; # Node-ID: 2
set nid3 [copy_entity nodes $nid]; # Node-ID: 3

translate_entity "nodes" $nid2 $vector 10; # TRANSLATE Node-ID: 2
translate_entity "nodes" $nid3 $vector -10; # TRANSLATE Node-ID: 3


*createvector 1 1.0000 1.0000 1.0000; *barelement $nid $nid2 1 0 0 0 0
*createvector 1 1.0000 1.0000 1.0000; *barelement $nid $nid3 1 0 0 0 0

set nodes [list $nid2 $nid3];
eval *createmark nodes 1 $nodes;
*nodemarkcleartempmark 1;

clear_marks;
*createmark nodes 1 $nid;
*numbersmark nodes 1 1;
}
#
# ----- TOOLS FOR MODEL REVIEW  --------------- #
#
proc catiarow_review {nrow} {

global spotdata;

# BLOCK: GET RELEVANT CSV DATA FOR GIVEN NROW
	set rowdata [csv_get $spotdata $nrow [list 1 2 3 4 5 6 7 8 9 10]]; 
	set row [lindex $rowdata 0]; # Get row number
	set layers [lindex $rowdata 2]; # Layers
	set cloc [lindex $rowdata 1]; # Get connector location
	set comp1 [lindex $rowdata 6]; 
	set comp2 [lindex $rowdata 7]; 
	set comp3 [lindex $rowdata 8];
	set warning [lindex $rowdata 9];
	clear_marks;
	

	# BLOCK: CREATE NODE AT CONNECTOR LOCATION
	set nid [create_node $cloc];

	
	# BLOCK: FOR EACH COMP IN THR ROW, CREATE CYLINDER AND PERFORM TRIMMING OPERATION
	eval *createmark comps 1 [list $comp1 $comp2 $comp3]; 
	set comps [hm_getmark comps 1];
	foreach cid $comps {	

	
	# BLOCK: FIND THE NORMAL TO THE SURFACE
	set output [project_nodeon_comp $nid $cid];
	set nid2 [lindex $output 0];
	set norm [lindex $output 2];

	
	# BLOCK: VISUALIZE WELD
	visualize_cylinder $nid $norm;
		
}
	
	# BLOCK: FIND COMPS IN Nth ROW -> SHOW COMPS
	show_comp $comps; 
	*window 0 0 0;
	
	# PUTS MSG
	set rowdata [join_list "Row-Now:" $nrow ", Layers:" $layers ", CID1:" $comp1 ", CID-2:" $comp2 ", CID-3:" $comp3 ", Warning:"  $warning ", Node-ID:" $nid];
	set rowdata [replace "{" "" $rowdata];
	set rowdata [replace "}" "" $rowdata]; puts $rowdata;
}
#
proc catiarow {nrows} {

*displaynone;
*nodecleartempmark;
set prop [review_beams];
set comp [get_comp "SpotWeldVisualize"];
set comp [lindex $comp 0];
set_comp_prop $comp $prop;
foreach nrow $nrows { catiarow_review $nrow; }
show_comp $comp;

}
#
proc catia_findrows {compid} {

*nodecleartempmark;
global spotdata;
set rowlist {};
set complist {};
foreach nrow [range 2 3849] { 

	set rowdata [csv_get $spotdata $nrow [list 1 2 3 4 5 6 7 8 9 10]]; 
	set row [lindex $rowdata 0]; # Get row number
	set layers [lindex $rowdata 2]; # Layers
	set cloc [lindex $rowdata 1]; # Get connector location
	set comp1 [lindex $rowdata 6]; 
	set comp2 [lindex $rowdata 7]; 
	set comp3 [lindex $rowdata 8];
	set warning [lindex $rowdata 9];
	set comps [list $comp1 $comp2 $comp3];
	
	set ind [find $compid $comps];
	
	if {$ind != "Not-Found"} {
	
	lappend rowlist $nrow;
	lappend complist $comps;
	
	# COMMENT THIS SECTION AFTER DEBUGGING
	# set rowdata [join_list "Row-Now:" $nrow ", Layers:" $layers ", CID1:" $comp1 ", CID-2:" $comp2 ", CID-3:" $comp3 ", Warning:"  $warning];
	# set rowdata [replace "{" "" $rowdata];
	# set rowdata [replace "}" "" $rowdata]; 
	# puts $rowdata;
	}

}

set complist [replace "{" "" $complist];
set complist [replace "}" "" $complist]; 
set complist [unique_items $complist];

return [list $rowlist $complist];
}
#
# ----- TOOLS FOR PUNCHING HOLE  --------------- #
#
proc catia_punchrow {csvdata nrow} {


# BLOCK: GET RELEVANT CSV DATA FOR GIVEN NROW
	set rowdata [csv_get $csvdata $nrow [list 1 2 3 4 5 6 7 8 9 10]]; 
	set row [lindex $rowdata 0]; # Get row number
	set layers [lindex $rowdata 2]; # Layers
	set cloc [lindex $rowdata 1]; # Get connector location
	set comp1 [lindex $rowdata 6]; 
	set comp2 [lindex $rowdata 7]; 
	set comp3 [lindex $rowdata 8];
	set warning [lindex $rowdata 9];
	clear_marks;
	

	# BLOCK: CREATE NODE AT CONNECTOR LOCATION
	set nid [create_node $cloc];

	
	# BLOCK: FOR EACH COMP IN THR ROW, CREATE CYLINDER AND PERFORM TRIMMING OPERATION
	eval *createmark comps 1 [list $comp1 $comp2 $comp3]; 
	set comps [hm_getmark comps 1];
	foreach cid $comps {	

	
	# BLOCK: FIND THE NORMAL TO THE SURFACE
	set output [project_nodeon_comp $nid $cid];
	set nid2 [lindex $output 0];
	set norm [lindex $output 2];

	
	# # BLOCK: CREATE CYLINDER
	set solid2 [create_cylinder $nid2 $norm 2.25 10]; 
	*createmark solids 1 "by comp" $cid;
	set solid1 [hm_getmark solids 1];
	
	
	# BLOCK: PERFORM TRIMMING OPERATION
	# solid_boolean_subtract $solid1 $solid2;
	
	
}
	
	# BLOCK: FIND COMPS IN Nth ROW -> ISOLATE COMPS
	set current_comp [hm_entitymaxid comps];
	eval *createmark comps 1 [list $comp1 $comp2 $comp3 $current_comp]; 
	*isolateentitybymark 1; 
	*window 0 0 0;
	
	
	# PUTS MSG
	set rowdata [join_list "Row-Now:" $nrow ", Layers:" $layers ", CID1:" $comp1 ", CID-2:" $comp2 ", CID-3:" $comp3 ", Warning:"  $warning ", Node-ID:" $nid];
	set rowdata [replace "{" "" $rowdata];
	set rowdata [replace "}" "" $rowdata]; puts $rowdata;

}


























