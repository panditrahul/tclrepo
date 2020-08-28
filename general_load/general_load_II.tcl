
# LOAD FOLLOWING PACKAGES:
# 1. SURFACE_LOAD
# 2. GENERAL_LOAD
# 3. SOLID_LOAD
# 4. LINE_LOAD

# INCLUDE LIBRARIES AND CSV FILES TO READ
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/general_load/general_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/csv_load/csv_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/surface_load/surface_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/solid_load/solid_load.tcl";

# ----- PROPERTY AND MAT ASSIGNMENT RELATED ----- #

proc rapid_mid_extract {comp} {

	# CLEAR_MARKS
	clear_marks;

	# FIND NAME OF COMP
	set comp_name [hm_getcollectorname comps $comp];

	# CREATE COMP TO HOLD THE MIFSURFACE
	set midcomp [get_comp $comp_name];
	
	# TAKE SURFACES ON MARK
	*createmark surfs 1 "by collector id" $comp;

	# EXTRACT MIDSURFACE IN THE CURRENT COMP
	*midsurface_extract_10 surfaces 1 -1 0 1 1 9 0 20 0 0 10 0 10 -2 undefined 0 0 0;
	
	# RETURN
	return [lindex $midcomp 0];

}

proc get_shell_info {comp_id} {

# DISPLAY POINTS AND CREATE VIEW
hm_markclearall 1;
*fixedpointhandle 1

# CREATE MARK OF SURFACES IN COLLECTOR
*createmark surfaces 1 "by collector id" $comp_id;
*createmark points 1 "by surface on mark" 1
set points [hm_getmark points 1]
 
# FOREACH POINT FIND THE ATTACHED SURFACES AND THERE THICKNESSES
set data_thk {}; foreach point $points {

	# FOR THE GIVEN POINT FIND THE SURFACES ATTACHED AND THERE THICKNESSES (UNPARSED)
	set surfInfo [hm_getsurfacethicknessvalues points $point];
	 
	# FIND HOW MANY SURFACES ARE ATTACHED TO THE POINT
	set nsurfs [llength $surfInfo];
	 
	# FOREACH ATTACHED SURF FIND THE THICKNESS AND APPEND TO TVAL LIST
	set surfs {}; set tval {}; 
	for {set i 0} {$i < $nsurfs} {incr i} { 
		set db [lindex $surfInfo $i];
		set surf_id [lindex $db 0];
		set thk [lindex $db 1];
		set tval [lappend tval $thk];
	}

	# FIND MEAN OF TVAL LIST AND APPEND TO data_thk 
	set tval_mean [mean $tval];
	set data_thk [lappend data_thk $tval_mean];
}

# FIND AVERAGE OF THICKNESSES AND STANDARD DEVIATION
set mean_thickness [mean $data_thk]; 
set stdev_thickness [stdev $data_thk];
set mean_thickness [expr {double(round(1000*$mean_thickness))/1000}];


# RETURN THE MEAN THICKNESS
set comp_name [hm_getcollectorname comps $comp_id]; *fixedpointhandle 0;
return [list $comp_id $comp_name $mean_thickness $stdev_thickness];
}

proc prop_assign_nastran {comp_id thk} {

# NAME OF PROPERTY | REMOVE DOT
set thk2 [ string map {. p} $thk];
set pname "PSHELL_";
set pname $pname$thk2;

# CHECK IF PROPERTY EXISTS
hm_markclearall 1;
*createmark props 1 "by name" $pname;
set PFLG [hm_getmark props 1];

# IF PROPERTY EXISTS ASSIGN TO $comp_id
if {[llength $PFLG] == 1} { *propertyupdateentity comps $comp_id $pname; }

# IF PROPERTY DOES NOT EXIST CREATE THE PROPERTY AND ASSIGN
if {[llength $PFLG] == 0} {
*createentity prop name = $pname;
*propertyupdateentity comps $comp_id $pname;
}

# IF THE PROPERTY WAS CREATED UPDATES ITS PARAMETERS
if {[llength $PFLG] == 0} {
*setvalue props name=$pname cardimage="PSHELL"
*setvalue props name=$pname STATUS=1 95=$thk;
}
}

proc mat_assign {comp_id name} {

# CHECK IF MAT EXISTS
hm_markclearall 1;
*createmark material 1 "by name" $name;
set matid [hm_getmark material 1];

# IF MATERIAL EXISTS ASSIGN TO $comp_id
if {[llength $matid] == 1} { *setvalue comps id=$comp_id materialid={mats $matid} }

# IF PROPERTY DOES NOT EXIST CREATE THE PROPERTY AND ASSIGN
if {[llength $matid] == 0} {
*createentity material name = $name;
set matid [hm_entitymaxid material];
*setvalue comps id=$comp_id materialid={mats $matid};
}

# UPDATE MATERIAL PROPERTIES

return $matid
}

proc find_thin_solids {} {

# CREATE ASSEMBLY 
set assy_name [hm_getincrementalname assy "Midsurface_Assy" -1];
*createentity assembly name=$assy_name; 
set assy_id [hm_entitymaxid assy];

# FOR DISPLAYED COMPS
*createmark comps 1 "displayed"
set comps [hm_getmark comps 1 ];

set logdata {}; set thin_comps {}; set thick_comps {};
lappend logdata [join_list "Comp-ID" "Comment"];
foreach comp $comps {

	# CLEAR_MARKS
	hm_markclearall 1;
	hm_markclearall 2;

	# FIND NAME OF COMP
	set comp_name [hm_getcollectorname comps $comp];

	# CREATE COMP TO HOLD THE MIDSURFACE--> MOVE TO ASSY
	set comp_name [hm_getincrementalname comps $comp_name -1]
	*createentity comps name=$comp_name;
	*createmark comps 1 [hm_entitymaxid comps];
	*assemblyaddmark $assy_id components 1;
	clear_marks;

	# TAKE SURFACES ON MARK
	*createmark surfs 1 "by collector id" $comp;

	# EXTRACT MIDSURFACE IN THE CURRENT COMP
	if { [ catch {*midsurface_extract_10 surfaces 1 -1 0 1 1 9 0 20 0 0 10 0 10 -2 undefined 0 0 0} ] } {	
		lappend thick_comps comp; set log [join_list $comp  "," "NOT-THIN-SOLID"];	
	} else { 	
		lappend thin_comps comp; set log [join_list $comp "," "THIN-SOLID"];	
	};
	
	lappend logdata $log;
}

# ISOLATE THIN SOLIDS
eval *createmark solids 1 "by comp" $thick_comps;
*maskentitymark solids 1 0;


# WRITE THE LOG-DATA TO THE FILE
	set logfile "MidSurfaceThicknessReview.csv";
	set file [open $logfile "w+"];
	foreach out $logdata { puts $file $out; }
	close $file
	puts "Execution Done.";

}