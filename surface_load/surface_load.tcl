
proc offset_surfaces {surfids offset} {

set send {}; foreach surfid $surfids {

	# CLEAR ALL MARKS 
	hm_markclearall 1; hm_markclearall 2;
	
	# OFFSET SURFACES
	*createmark surfaces 1 [hm_entitymaxid surfs];
	*createmark lines 1;
	*offset_surfaces_and_modify surfaces 1 0 1 0 $offset;
	
	# NOTE THE SURFACE ID OF NEWLY CREATED SURFACE
	set new_surfs [hm_entitymaxid surfs];
	lappend send $new_surfs;
	

}

# RETURN SURFACE ID OF NEWLY CREATED/OFFSET SURFACE
return $send;

}

proc create_surface_center {surfid} {

hm_markclearall 1; hm_markclearall 2;

# TAKE SURFACE ON MARK AND FIND CENTROID
*createmark surfaces 1 $surfid;
set center [hm_getcentroid surfs 1];

# CREATE TEMP CENTER NODE
set xnode1 [lindex $center 0];
set ynode1 [lindex $center 1];
set znode1 [lindex $center 2];
*createnode $xnode1 $ynode1 $znode1 0 0 0;

# RETURN THE NODE ID
set nid [hm_entitymaxid nodes];
return $nid

}

proc surface_get_big_lines {surface_id} {

hm_markclearall 1; hm_markclearall 2;

# TAKE LINES OF SURFACE OF MARK
*createmark lines 1 "by surface" $surface_id
set lines [hm_getmark lines 1];

# FOREACH LINE FIND THE LENGTH
set ext_lines {};
foreach line $lines {
lappend ext_lines [hm_linelength $line];
} 

# CREATE ARRAY OF LINE IDS AND LINE LENGTHS
set c {};
for {set i 0} {$i<[llength $ext_lines]} {incr i} {
set p1 [lindex $lines $i];
set p2 [lindex $ext_lines $i];
set p3 [lappend p1 $p2];
lappend c $p3;
}

# SORT THE ARRAY USING LINE LENGTH
set val [lsort -decreasing -real -index 1 $c]; # puts $val

# FIND THE LINE IDS
set line1 [lindex $val 0]; set line1 [lindex $line1 0];
set line2 [lindex $val 1]; set line2 [lindex $line2 0];

# RETURN THE LINES
eval *createmark lines 1 [list $line1 $line2];
hm_highlightmark lines 1 "high";
return [list $line1 $line2];
}

proc extend_surface {surfid lineids pull} {

hm_markclearall 1; hm_markclearall 2;

# EXTEND THE SURFACE ABOUT TWO LARGEST LINES
*createmark surfaces 1 $surfid;
*createmark surfaces 2;
eval *createmark lines 1 $lineids;
*createmark lines 2;
*connect_surfaces_11 1 2 4 0 $pull 15 30 1 0 2 30 3 0

# RETURN ID OF THE EXTENDED SURFACE
return [hm_entitymaxid surfs];
}

proc get_lines_from_surfs {surfs} {

hm_markclearall 1; hm_markclearall 2;
eval *createmark surfs 1 $surfs;
*findmark surfs 1 1 1 lines 0 2;
set lineids [hm_getmark lines 2];

# CREATE A LIST OF ALL LINE LENGTHS
set linelength {}; foreach line $lineids { lappend linelength [hm_linelength $line]; }

# SORT LINES BASED ON LENGTH
set lineids [sort_list $lineids $linelength];

# COMMENT THIS SECTION AFTER DEBUG
# eval *createmark lines 1 $lineids;
# *numbersmark lines 1 1

return $lineids;

}

proc get_surfs_from_lines {lines} {

hm_markclearall 1; hm_markclearall 2;
eval *createmark lines 1 $lines;
*findmark lines 1 1 1 surfaces 0 2;
set surfids [hm_getmark surfs 2];

# SORT SURFACES BASED ON AREA OF SURFACES
set area1 [hm_getareaofsurface surfs [lindex $surfids 0]];
set area2 [hm_getareaofsurface surfs [lindex $surfids 1]];
set surfids [sort_list $surfids [list $area1 $area2]];

# COMMENT THIS SECTION AFTER DEBUG
# eval *createmark surfs 1 $surfids;
# *numbersmark surfs 1 1

return $surfids;

}

proc get_surf_from_line {lines} {

hm_markclearall 1; hm_markclearall 2;
eval *createmark lines 1 $lines;
*findmark lines 1 1 1 surfaces 0 2;
set surfids [hm_getmark surfs 2];

# COMMENT THIS SECTION AFTER DEBUG
eval *createmark surfs 1 $surfids;
*numbersmark surfs 1 1;
return $surfids;

}


proc get_surfs_from_solid {solids} {

hm_markclearall 1; hm_markclearall 2;

*createmark solids 1 $solids;
*findmark solids 1 1 1 surfs 0 2;
set surfids [hm_getmark surfs 2];

# CREATE A LIST OF ALL SURFACE AREAS
set surfarea {}; foreach surfid $surfids { lappend surfarea [hm_getareaofsurface surfs $surfid]; }

# SORT LINES BASED ON LENGTH
set surfids [sort_list $surfids $surfarea];

# COMMENT THIS SECTION AFTER DEBUG
# eval *createmark surfs 1 $surfids;
# *numbersmark surfs 1 1;

return $surfids;

}

proc find_nearest_surface {node_id comp_id} {

# FIND LOCATION OF NODE
set nid [hm_nodevalue $node_id];
set nid [lindex $nid 0];
set nx [lindex $nid 0];
set ny [lindex $nid 1];
set nz [lindex $nid 2];
set nloc [list $nx $ny $nz];

# FIND ALL SURFS IN COMP
hm_markclearall 1; hm_markclearall 2;

# FIND ALL SURFS IN THE COMP
eval *createmark surfs 1 "by collector id" $comp_id;
set surf_ids [hm_getmark surfs 1];

# MAIN ACTIONS
set val [hm_getdistancefromnearestsurface $nloc $surf_ids];
return [lindex $val 1];

}

proc surf_midline {surfid} {


# FIND LINES FOR THE CREATION OF MIDLINE
set ext_lines [surface_get_big_lines $surfid];


# CREATE MIDLINE
*createlist lines 1 [lindex $ext_lines 0]
*createlist nodes 1
*createlist lines 2 [lindex $ext_lines 1]
*createlist nodes 2
*linescreatemidline 1 1 2 2


# RETURN ID OF THE NEWLYCREATE LINE
return [hm_entitymaxid lines];

}

proc create_surfs_by_lines {line1 line2} {

hm_markclearall 1;
hm_markclearall 2;

*surfacemode 4
eval *createmark lines 1 [list $line1 $line2];
*surfacesplineonlinesloop 1 1 1 3


}

proc find_surface_normal {surf_id node_id} {


hm_markclearall 1;
hm_markclearall 2;

# FIND LOCATION OF NODE
set nid [hm_nodevalue $node_id];
set nid [lindex $nid 0];
set nx [lindex $nid 0];
set ny [lindex $nid 1];
set nz [lindex $nid 2];

# FIND SURFACE NORMAL
set out [hm_getsurfacenormalatcoordinate $surf_id $nx $ny $nz];
set ux [lindex $out 3];
set uy [lindex $out 4];
set uz [lindex $out 5];

return [list $ux $uy $uz];
}

proc project_node_to_surface {surf_id node_id} {

hm_markclearall 1;
hm_markclearall 2;

*createmark nodes 1 $node_id;
*markprojectnormallytosurface nodes 1 $surf_id;

}

proc drag_line {lineid vector push} {

clear_marks;
*createlist lines 1 $lineid;
*createlist nodes 1
*createvector 1 [lindex $vector 0] [lindex $vector 1] [lindex $vector 2];
*draglinetoformsurface 1 1 1 $push

*createmarklast "surfs" 1;

return [hm_getmark surfs 1];

}


proc trim_surf_by_surf {comp trimsurf} {

clear_marks;

*createmark surfs 1 "by comp" $comp;
*createmark surfaces 2 $trimsurf
*surfmark_trim_by_surfmark 1 2 0

}

