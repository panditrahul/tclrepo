proc line_center {line_id} {

clear_marks;
*createdoublearray 2 0 1;
*nodecreateatlineparams $line_id 1 2 1 0 0;

clear_marks;
*createmark nodes 1 -2;
set midnode [hm_getmark nodes 1];

clear_marks;
*createmark nodes 1 -1;
set basenode [hm_getmark nodes 1];

return [list $midnode $basenode];

}


proc find_nearest_line {node_id surf_id} {

# FIND LOCATION OF NODE
set nid [hm_nodevalue $node_id];
set nid [lindex $nid 0];
set nx [lindex $nid 0];
set ny [lindex $nid 1];
set nz [lindex $nid 2];
set nloc [list $nx $ny $nz];

# FIND ALL SURFS IN COMP
hm_markclearall 1; hm_markclearall 2;

# FIND LINES IN SURFACE
set line_ids [get_lines_from_surfs $surf_id];

# MAIN ACTIONS
set val [hm_getdistancefromnearestline $nloc $line_ids];
return [lindex $val 1];

}