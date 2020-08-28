
proc create_cylinder2 {nid vector radius drag} {

# FOR A GIVEN NODE CREATE LINE CIRCLE
set vector [lindex $vector 0];
*createlist nodes 1 $nid;
*createvector 1 [lindex $vector 0] [lindex $vector 1] [lindex $vector 2];
*createcirclefromcenterradius 1 1 $radius 360 0;
set LID [hm_entitymaxid lines];

# USING THE LINE CIRCLE CREATE A SURFACE
*createmark lines 1 $LID
*surfacecreatedraglinealongvector 1 1 $drag 0 0;
*surfacecreatedraglinealongvector 1 1 -$drag 0 0;

# RETURN ID OF THE SURFACE CREATED
return [hm_entitymaxid surfs 1];
}


proc create_cylinder {nid vector radius drag} {

hm_markclearall 1; hm_markclearall 2;

# FOR A GIVEN NODE CREATE LINE CIRCLE
*createlist nodes 1 $nid;
*createvector 1 [lindex $vector 0] [lindex $vector 1] [lindex $vector 2];
*createcirclefromcenterradius 1 1 $radius 360 0;
set LID [hm_entitymaxid lines];

# USING THE LINE CIRCLE CREATE A SURFACE
*createmark lines 1 $LID
*surfacesplineonlinesloop 1 1 1 67

# DRAG THE SURFACE TO CREATE CYLINDER
set SURFID [hm_entitymaxid surfs];
*createmark surfaces 1 $SURFID
*solid_offset_from_surfs 1 $drag 4 0


# RETURN ID OF THE SOLID CREATED
return [hm_entitymaxid solids 1];

}

proc create_sphere {nid radius} {

# FIND LOCATION OF NODE
set loc [hm_nodevalue $nid];
set loc [lindex $loc 0];
set xloc [lindex $loc 0];
set yloc [lindex $loc 1];
set zloc [lindex $loc 2];

# CREATE SPHERE
*solidspherefull $xloc $yloc $zloc $radius;

# RETURN ID OF THE SOLID CREATED
return [hm_entitymaxid solids 1];

}

proc solid_boolean_subtract {sol1 sol2} {

hm_markclearall 1; hm_markclearall 2;

# PERFORM BOOLEAN OPERATION A - B
eval *createmark solids 1 $sol1;
eval *createmark solids 2 $sol2
*boolean_merge_solids 1 2 2 3

}

proc trim_solid_by_surf {solid_ids surface_ids} {

hm_markclearall 1; hm_markclearall 2;
eval *createmark solids 1 $solid_ids;
eval *createmark surfaces 2 $surface_ids;
*trim_solids_by_surfaces 1 2 0

}


proc sort_comps_by_volume {comps} {

set volume {};
foreach comp $comps {
	eval *createmark solids 1 "by comp" $comp;
	set solidID [hm_getmark solids 1];
	lappend volume [hm_getvolumeofsolid solids $solidID];
}

set comps [sort_list $comps $volume];
return [list $comps];

}















