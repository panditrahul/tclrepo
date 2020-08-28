# LOAD FOLLOWING PACKAGES:
# 1. SURFACE_LOAD
# 2. GENERAL_LOAD
# 3. SOLID_LOAD
# 4. LINE_LOAD

proc prop_assign_mahindra {comp_id thk} {

# NOMENCLATURE 
set DB1 "99";
set DB2 "216";
set DB3 [expr $thk * 100];
if {$DB3 < 100} { set DB "0"; set DB3 $DB$DB3; }
set DB $DB1$DB2$DB3; 
set DB [format %.0f $DB]; 
set pname "SectShell_"; 
set pname $pname$DB;
puts $pname

# CHECK IF PROPERTY EXISTS
hm_markclearall 1;
*createmark props 1 "by name" $pname;
set PID [hm_getmark props 1];

# IF PROPERTY EXISTS ASSIGN TO $comp_id
if {[llength $PID] == 1} { *propertyupdateentity comps $comp_id $pname; puts "PROP EXISTS | ASSIGNED"}

# IF PROPERTY DOES NOT EXIST CREATE THE PROPERTY AND ASSIGN
if {[llength $PID] == 0} {
	
	# CREATE PROPERTY AND ASSIGN
	*createentity prop name = $pname;
	*propertyupdateentity comps $comp_id $pname;
	puts "PROP CREATED | ASSIGNED"
	
	# UPDATE PROP PARAMETERS CARD-IMAGE, ELFORM, SHRF, NIP
	*createmark props 1 "by name" $pname; set PID [hm_getmark props 1];
	*setvalue props id=$PID cardimage="SectShll"
	*setvalue props id=$PID STATUS=1 399=16;
	*setvalue props id=$PID STATUS=1 402=0.833;
	if {$thk < 1} { 
		*setvalue props id=$PID STATUS=1 427=3 
	} elseif {$thk >= 1} {
		*setvalue props id=$PID STATUS=1 427=5 
	}
	*setvalue props id=$PID id=$DB;

}

puts "-------------------------"
}

proc find_mig_bodies {lineid} {

# FIND ALL SURFS IN COMP
	hm_markclearall 1; hm_markclearall 2;

# CENTER NODE OF THE LINE
	set nid [line_center $lineid];

# COMP IN WHICH THE LINE RESIDES
	set body_a [get_comp_from_entity "lines" [lindex $lineid 0]]; 

# PUT ALL DISPLAYED COMPS IN THE MARK EXCEPT THE LINE COMPONENT
	*createmark comps 1 "displayed";
	*createmark comps 2 $body_a;
	*markdifference comps 1 comps 2;

# CREATE MARK OF SURFACES FOR ALL COMPS IN MARK I
	set comps [hm_getmark comps 1];
	set nearest_surface [find_nearest_surface $nid $comps];

# COMP IN WHICH THE NEAREST SURFACE RESIDES
	set body_b [get_comp_from_entity "surfs" $nearest_surface];


return [list $body_a $body_b];

}

proc mig_prop_thickness {body_a body_b type} {

	if {$type == "dura"} {
	
		set tshell_a [hm_getthickness comps $body_a]; # T_SHELL_A
		set tshell_b [hm_getthickness comps $body_b]; # T_SHELL_B
		
		# OFFSET AND MIG-THICKNESS FOR DURA
		set offset [expr ($tshell_a + $tshell_b)/2];
		set mig_thickness [list $tshell_a $tshell_b];
		set mig_thickness [lsort $mig_thickness];
		set mig_thickness [expr 2*[lindex $mig_thickness 0]];
	
	} elseif {$type == "nvh"} {
	
		set tshell_a [hm_getthickness comps $body_a]; # T_SHELL_A
		set tshell_b [hm_getthickness comps $body_b]; # T_SHELL_B
		
		# OFFSET AND MIG-THICKNESS FOR DURA
		set offset [expr ($tshell_a + $tshell_b)/2];
		set mig_thickness [list $tshell_a $tshell_b];
		set mig_thickness [lsort $mig_thickness];
		set mig_thickness [expr 1.5*[lindex $mig_thickness 1]];
	
	
	}
	
	set mig_thickness [round $mig_thickness 1];
	return $mig_thickness;

}

proc extend_offset_trim {lineid push offset db body} {

# CLEAR MARKS
clear_marks;


# FIND ATTACHED SURFACE AND THERE AREA
set surfids [get_surfs_from_lines $lineid];
set push_surf [lindex $surfids $push];


# DUPLICATE THE OPTION SURFACE, EXTEND THE SURFACE AND OFFSET IT
set pull [expr $offset*2]; # Extension value
set input_line_node [line_center $lineid]; # Input-Line Center
set copy_surf [copy_entity "surfs" $push_surf]; # Duplicate SURF
set ext_line [find_nearest_line $input_line_node $copy_surf]; 
set extsurf [extend_surface $copy_surf $ext_line $pull]; # Extend the SURF
set offsurf [offset_surfaces $extsurf [expr $offset +$db]]; # Offset the SURF


# TRIM SOLID BY OFFSET SURF
clear_marks
*createmark solids 1 "by comp" $body;
set solid_id [hm_getmark solids 1];
# trim_solid_by_surf $solid_id $offsurf;


# RETURN THE OFFSET SURFACE
return $offsurf;

}

proc mig_lap {lineid mig_comp} {

# FIND MIG BODIES AND MIG_A SURFACE
	set input_line_node [line_center $lineid]; 
	set mig_bodies [find_mig_bodies $lineid];

	set body_a [lindex $mig_bodies 0]; # Comp-ID of Body-A
	set body_b [lindex $mig_bodies 1]; # Comp-ID of Body-B

	puts $body_a
	puts $body_b
	set tshell_a [hm_getthickness comps $body_a]; # T_SHELL_A
	set tshell_b [hm_getthickness comps $body_b]; # T_SHELL_B
	# set offset [expr ($tshell_a + $tshell_b)/2];
	set offset 2.6;
	
	
	set mig_a_surfs [get_surfs_from_lines $lineid]; # Surface-IDs from Input Line
 

# TRIMMING OPERATIONS
# set trim_comp [get_comp "TrimSurface_DB"]; # Trim Component
set_comp $body_b;
extend_offset_trim $lineid 1 $offset 5 $body_b; # HAZ-I Body-B
extend_offset_trim $lineid 1 $offset -5 $body_b; # HAZ-II Body-B
set offsurf [extend_offset_trim $lineid 1 $offset 0 $body_b]; # MIG Body-B
set_comp $body_a;
extend_offset_trim $lineid 1 0 -5 $body_a ; # HAZ Body-A


# # # FIND MIG-PAIR SURFACES FROM BODY-A AND BODY-B
# set_comp $mig_comp;
# set vector [find_surface_normal [lindex $mig_a_surfs 0] $input_line_node];
# translate_entity "nodes" $input_line_node $vector [divide $offset 2];
# project_node_to_surface $offsurf $input_line_node; 
# # delete_comp $trim_comp;
# set mig_b [find_nearest_surface $input_line_node $body_b];
# set mig_a [lindex $mig_a_surfs 1];

# # CREATE MIG SURFACE BETWEEN MIG-PAIRS
# # set_comp $mig_comp;
# set mid1 [surf_midline $mig_a];
# set mid2 [surf_midline $mig_b];
# create_surfs_by_lines $mid1 $mid2;

}

proc mig_t {lineid mig_comp} {

# FIND MIG BODIES AND MIG_A SURFACE
	set input_line_node [line_center $lineid]; 
	set mig_bodies [find_mig_bodies $lineid];

	set body_a [lindex $mig_bodies 0]; # Comp-ID of Body-A
	set body_b [lindex $mig_bodies 1]; # Comp-ID of Body-B

	set tshell_a [hm_getthickness comps $body_a]; # T_SHELL_A
	set tshell_b [hm_getthickness comps $body_b]; # T_SHELL_B
	set offset [expr ($tshell_a + $tshell_b)/2];
	
	set mig_a_surfs [get_surfs_from_lines $lineid]; # Surface-IDs from Input Line


# TRIMMING OPERATIONS
	set trim_comp [get_comp "TrimSurface_DB"]; # Trim Component
	extend_offset_trim $lineid 0 $offset 5 $body_b; # HAZ-I Body-B
	extend_offset_trim $lineid 0 $offset -5 $body_b; # HAZ-II Body-B
	set offsurf [extend_offset_trim $lineid 0 $offset 0 $body_b]; # MIG Body-B
	extend_offset_trim $lineid 1 0 -5 $body_a ; # HAZ Body-A


# # FIND MIG-PAIR SURFACES FROM BODY-A AND BODY-B
	# set vector [find_surface_normal [lindex $mig_a_surfs 1] $input_line_node];
	# translate_entity "nodes" $input_line_node $vector [divide $offset 2];
	# project_node_to_surface $offsurf $input_line_node; 
	# delete_comp $trim_comp;
	# set mig_b [find_nearest_surface $input_line_node $body_b];
	# set mig_a [lindex $mig_a_surfs 1];


# # CREATE MIG SURFACE BETWEEN MIG-PAIRS
	# set_comp $mig_comp;
	# set mid1 [surf_midline $mig_a];
	# set mid2 [surf_midline $mig_b];
	# create_surfs_by_lines $mid1 $mid2;

}
#
#
proc mig_linenorms {lineid} {

set surfid [get_surf_from_line $lineid]; # Find surface attached to the line 
set nodeids [line_center $lineid]; # Create nodes on the line 3x
set midnode [lindex $nodeids 0];
set basenode [lindex $nodeids 1];

set norm [find_surface_normal $surfid $midnode]; # Find Surface Normal
set para [vector_from_nodes $basenode $midnode]; # Find Parallel Vector

set offsetnorm [cross_product [lindex $norm 0] [lindex $norm 1] [lindex $norm 2] [lindex $para 0] [lindex $para 1] [lindex $para 2]];
set offsetnorm [list [lindex $offsetnorm 1] [lindex $offsetnorm 2] [lindex $offsetnorm 3]]


# Visualization
*createmark nodes 1 $midnode; 
*vectorcreate 1 [lindex $norm 0] [lindex $norm 1] [lindex $norm 2] 0; # Create Visual Vector
*vectorcreate 1 [lindex $para 0] [lindex $para 1] [lindex $para 2] 0; # Create Visual Vector
*vectorcreate 1 [lindex $offsetnorm 0] [lindex $offsetnorm 1] [lindex $offsetnorm 2] 0; # Create Visual Vector

return [list $norm $offsetnorm];

}
