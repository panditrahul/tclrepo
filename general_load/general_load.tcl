
# LOAD FOLLOWING PACKAGES:
# 1. SURFACE_LOAD
# 2. GENERAL_LOAD
# 3. SOLID_LOAD
# 4. LINE_LOAD

# INCLUDE LIBRARIES AND CSV FILES TO READ
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/csv_load/csv_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/surface_load/surface_load.tcl";
source "P:/InDepth-MethodsDev/21-hmtools/hmtools/functions_repository/solid_load/solid_load.tcl";

proc get_input {entity user_input} {

# CLEAR MARKS AND LIST
clear_marks;
*clearlist surfs 1;

*createlistpanel $entity 1 $user_input; 
set return_id [hm_getlist $entity 1];

# CLEAR MARKS
hm_markclearall 1; hm_markclearall 2;

return [list $return_id];

}

proc get_input_mark {entity user_input} {

# CLEAR MARKS AND LIST
clear_marks; *clearlist surfs 1;

*createmarkpanel $entity 1 $user_input; 
set return_id [hm_getmark $entity 1];
set return_id [lindex $return_id 0];

# CLEAR MARKS
hm_markclearall 1; hm_markclearall 2;
return $return_id;

}

proc get_comp_from_entity {entity entity_id} {

return [hm_getentityvalue $entity $entity_id "collector.id" 0];

}

proc get_comp {comp_name} {

if {$comp_name == ""} { set comp_name "InDepth_DB"; }

# CREATE COMP
set comp_name [hm_getincrementalname comps $comp_name -1]; 
*createentity comps name=$comp_name;

# RETURN COMP ID AND COMP NAME
set comp_id [hm_entitymaxid comps];
return [list $comp_id $comp_name];

}

proc clear_marks {} {

hm_markclearall 1; hm_markclearall 2;

}

proc set_comp {comp} {

*currentcollector components [hm_getcollectorname comps $comp];

}

proc hide_comp {comp} {

# FIND COMP NAME
set comp_name [hm_getcollectorname comps $comp];

# HIDE COMP
*createmark components 2 $comp_name;
*createstringarray 2 "elements_on" "geometry_on";
*hideentitybymark 2 1 2;

}

proc show_comp {comps} {

foreach comp $comps {
	# FIND COMP NAME
	set comp_name [hm_getcollectorname comps $comp];

	# HIDE COMP
	*createmark components 2 $comp_name;
	*createstringarray 2 "elements_on" "geometry_on";
	*showentitybymark 2 1 2;
	*window 0 0 0;
}

}

proc set_comp_prop {comp prop} {

*setvalue comps id=$comp propertyid=$prop;

}

proc delete_comp {comp} {

*createmark comps 1 $comp;
*deletemark comps 1;

}

proc delete {entity} {

clear_marks;

*createmark $entity 1 "displayed";
*startnotehistorystate {};
*deletemark $entity 1;
*endnotehistorystate {};

}

proc copy_entity {entity entity_id} {

	# DUPLICATE AND CREATE MARK OF SURFACES
	eval *createmark $entity 1 $entity_id;
	*duplicatemark $entity 1 1;
	return [hm_entitymaxid $entity];

}

proc translate_entity {entity entity_id vector push} {

clear_marks
*createmark $entity 1 $entity_id;

set vx [lindex $vector 0];
set vy [lindex $vector 1];
set vz [lindex $vector 2];

*createvector 1 $vx $vy $vz;
*translatemark $entity 1 1 $push;

}

proc duplicate_translate_entity {entity entity_id vector push} {

# DUPLICATE THE ENTITY
clear_marks;
set entity_id [copy_entity $entity $entity_id];

# TRANSLATE THE ENTITY
clear_marks;
*createmark $entity 1 $entity_id;

set vx [lindex $vector 0];
set vy [lindex $vector 1];
set vz [lindex $vector 2];

*createvector 1 $vx $vy $vz;
*translatemark $entity 1 1 $push;

return $entity_id;

}

proc get_tcl_location {} {

# Fetch parent script
set where [file dirname [info script]]
set send "/"; set send $where$send;
return $send;

}

proc tcl_out_append {filename data} {

	# ROUTINE TO WRITE TO FILE
	set file $filename;
	set file [open $file "a+"]
	puts $file $data
	close $file
	
}

proc tcl_out {filename data} {

	# ROUTINE TO WRITE TO FILE
	set file $filename;
	set file [open $file "w+"]
	puts $file $data
	close $file
	
}

proc logfile {filename data} {

set loc [file dirname [info script]];
set db "/"; set logfile $loc$db$filename;	
set file [open $logfile "w+"];
foreach out $data { 
puts $file $out;
}
close $file;
puts "Data Written to File";
}

proc endcode {t} {

puts [join_list "Execution-Time:" [time_out $t] "seconds."];

}

proc time_in {} {
return [clock clicks -milliseconds]; 
}

proc time_out {time_in} {
set time_out [clock clicks -milliseconds]; 
set total_time [expr $time_out - $time_in];
set total_time [divide $total_time 1000];
return $total_time;
}

proc nid_dist {nid1 nid2} {

set dist [hm_getdistance nodes $nid1 $nid2 0]; 
return $dist;

}

proc vector_from_nodes {nodeid1 nodeid2} {

package require hwat
set coord1 [expr [hm_nodevalue $nodeid1]]
set coord2 [expr [hm_nodevalue $nodeid2]]
set vectorcomps [::hwat::math::GetVector $coord1 $coord2];
set vectorcomps [unit_vector $vectorcomps];
return $vectorcomps;
}

proc project_nodeon_comp {nid cid} {


# FOR THE GIVEN NODE AND COMP-ID FIND THE NEAREST SURFACE
set surfid [find_nearest_surface $nid $cid];


# DUPLICATE THE GIVEN NODE AND PROJECT IT TO THE NEAREST SURFACE
set nid2 [copy_entity "nodes" $nid];
project_node_to_surface $surfid $nid2;


# FIND THE DISTANCE BETWEEN THE TWO NODES
set dist [nid_dist $nid $nid2];


# FIND SURFACE NORMAL AT GIVEN NODE ON THE NEAREST SURFACE
set norm [find_surface_normal $surfid $nid];


# RETURN NODE-ID OF PROJECTED NODE, DISTANCE AND NORMAL
return [list $nid2 $dist $norm];

}

proc isolate_comps {list} {

eval *createmark comps 1 $list;
*isolateentitybymark 1; *window 0 0 0; 

}

# ------------ LIST ----------------- #

proc mean {data} {

# CALCULATE THE MEAN OF THE DATA
set mean [ expr ([join $data +])/[llength $data]];
return $mean;

}

proc stdev {data} {

# CALCULATE THE MEAN OF THE DATA
set mean [ expr ([join $data +])/[llength $data]];

# CALCULATE THE STANDARD DEVIATION OF THE DATA
set std 0; foreach x $data {
    set db0 [expr $x - $mean];
	set db1 [expr $db0 * $db0];
	set std [expr $std + $db1];
}
set std [expr $std / 2500];
set std [expr sqrt($std)];

# ROUND OFF THE VALUES
set mean [expr {double(round(10000*$mean))/10000}];
set std [expr {double(round(10000*$std))/10000}];

# RETURN THE MEAN AND STANDARD DEVIATION
return $std;
}

proc most_common {list} {

# CREATE COUNTERS
set counters {}
foreach item $list {
    dict incr counters $item
}

# FIND UNIQUE ITEMS AND ITS QUANTITY
set list1 {}; set list2 {};
dict for {item count} $counters {
    lappend list1 $item;
	lappend list2 $count;
}

# SORT LIST OF UNIQUE AND QUANTITY
set unique_elems $list1;
set most_common [sort_list $list1 $list2];

# RETURN
return $most_common;

}

proc unique_items {list} {

# CREATE COUNTERS
set counters {}
foreach item $list {
    dict incr counters $item
}

# FIND UNIQUE ITEMS AND ITS QUANTITY
set list1 {}; set list2 {};
dict for {item count} $counters {
    lappend list1 $item;
	lappend list2 $count;
}

# SORT LIST OF UNIQUE AND QUANTITY
set unique_items $list1;

# RETURN
return $unique_items;

}

proc join_list {inc args} {

# READ VARIABLE LIST
set list $inc;
foreach el $args {
	lappend list $el;
}

# PERFORM ACTION
set concat_list {};
foreach nlist $list { 

if {[llength $nlist]==1} { lappend concat_list [lindex $nlist 0];}
if {[llength $nlist] > 1} { lappend concat_list $nlist;}

}
return $concat_list;

}

proc range {start cutoff} {
 
 set range_list {};
 for {set i $start} {$i<=$cutoff} {incr i} {
 
	lappend range_list $i;
 
 }
        
    return $range_list;
 }

proc sort_list {list_col_1 list_col_2} {

# CLEAR MARKS
hm_markclearall 1; hm_markclearall 2;

# CREATE ARRAY OF LINE IDS AND LINE LENGTHS
set array {};
for {set i 0} {$i<[llength $list_col_2]} {incr i} {
set p1 [lindex $list_col_1 $i];
set p2 [lindex $list_col_2 $i];
set p3 [lappend p1 $p2];
lappend array $p3;
}

# SORT THE ARRAY USING LENGTH
set val [lsort -decreasing -real -index 1 $array]; # puts $val
set sorted {}; for {set i 0} {$i<[llength $list_col_2]} {incr i} {
set m [lindex $val $i];
lappend sorted [lindex $m 0];
}

# RETURN
return $sorted;

}

proc get_items_from_list {list r1 r2} {

set r1 [expr $r1 -1];
set r2 [expr $r2 -1];

if {$r2 > [llength $list]} { set r2 [llength $list];}

set ret {}; foreach item [range $r1 $r2] {

lappend ret [lindex $list $item];

}
return $ret;
}

proc intersection {a b} {
set send {};
foreach elem $a {
set flag [lsearch $b $elem];
if {$flag != -1} { lappend send $elem; }
}
return $send;
}

proc replace {what with data} {

return [string map [list $what $with] $data];

}

proc find {item list} {

set out [lsearch -all $list $item];
if {[lindex $out 0]>=0} {
return $out;
} else {return "Not-Found"}

}

# ----- MISC-SURFS ----- #

proc create_node {loc} {

*createnode [lindex $loc 0] [lindex $loc 1] [lindex $loc 2];

return [hm_entitymaxid nodes];

}

proc dist {} {

# MARKS
set surfid [get_input "surfs" ""]; set surfid [lindex $surfid 0];
*createmark surfs 1 [lindex $surfid 0];
*createmark surfs 2 [lindex $surfid 1]; 

# ACTION
set sdist [hm_measureshortestdistance surfs 1 0 surfs 2 0 0];
set shortest_distance [lindex $sdist 0];
set x1 [lindex $sdist 5]; set x2 [lindex $sdist 9];
set y1 [lindex $sdist 6]; set y2 [lindex $sdist 10];
set z1 [lindex $sdist 7]; set z2 [lindex $sdist 11];
# d dx dy dz id1 x1 y1 z1 id2 x2 y2 z2

# CREATE NODE-LINE
set nid1 [create_node [list $x1 $y1 $z1]];
set nid2 [create_node [list $x2 $y2 $z2]];
*createlist nodes 2 $nid1 $nid2;
*createnodesbetweennodelist 2 1 0 0;
*createlist nodes 2 $nid1 $nid2;
*createnodesbetweennodelist 2 50 0 0;


# RETURN
hm_usermessage [join_list "The Shortest Distance is:" $shortest_distance "units"];
return $shortest_distance;

}

proc dist_bw_lines {line1 line2} {

*createmark lines 1 $line1;
*createmark lines 2 $line2;

set line_length [hm_measureshortestdistance lines 1 0 lines 2 0 0];
return [lindex $line_length 0];
}

proc approx_surf_width {surf} {

# puts [hm_getboundingbox surfs 1 0 0 0]
# Find lines from the surface
set lineids [get_lines_from_surfs $surf];

# Find the distance between the largest two lines
set dist_lines [dist_bw_lines [lindex $lineids 0] [lindex $lineids 1]];

return $dist_lines;

}

proc approx_solid_thickness {solids} {

# FIND ATTACHED SURFS
set surfs [get_surfs_from_solid $solids];

# FIND THE APPROX WIDTH OF ALL SURFACE
set surf_thickness_list {};
foreach surf $surfs {	

	set surf_width [approx_surf_width $surf];
	set surf_width [round $surf_width 5];
	lappend surf_thickness_list $surf_width;
	
}

# FIND MOST COMMON THICKNESS
set common_thickness [most_common $surf_thickness_list]; 
set approx_thickness [lindex $common_thickness 0];
return $approx_thickness;


}

# -------- MATH ----------- #

proc divide {n1 n2} {

return [expr double($n1)/$n2];

}

proc round {variable precision} {

set precision [expr 1e$precision];
return [expr {double(round($precision*$variable))/$precision}];


}

proc timesheet {} {

# DEFINE AND READ CSV FILE.
clear;
set csvloc "C:/Users/Rahul.U/Downloads/";
set csvfile "Timesheet.csv"; set csvfile $csvloc$csvfile; set csvdata [csv_read $csvfile];


# DOCUMENT ALL DATES AND HOURS
puts " ";
puts "----------Date-Wise-Description----------";
set ncols [llength $csvdata];
set ncols [expr $ncols -1];
set all_dates {}; 
set all_hours {};
set full_description {};
foreach nrow [range 2 $ncols] { 

	set day [csv_get $csvdata $nrow 2];
	set date [csv_get $csvdata $nrow 3];
	set hours [csv_get $csvdata $nrow 5]; 
	set project [csv_get $csvdata $nrow 6];
	
	set about [csv_get $csvdata $nrow 8]; 
	set about [lindex $about 0];
	set about [get_items_from_list $about 1 8];
	
	lappend all_dates $date;
	lappend all_hours $hours;

	set msg [join_list "RowNow:" $nrow "|" $date "|" $day "|" $hours "|" $about "|" $project ];
	set msg [replace "{" "" $msg];
	set msg [replace "}" "" $msg];
	puts $msg;
	
}


# FIND UNIQUE DATES
set unique_dates [unique_items $all_dates];


# FOREACH UNIQUE DATE FIND ALL HOURS
puts " ";
puts "----------Date-Wise-Hours----------";
set date_hours {}; foreach date $unique_dates {
	set index [lsearch -all $all_dates $date]; 
	set hours 0;
foreach ind $index {
	set hour [lindex $all_hours $ind]; 
	set hour [lindex $hour 0];
	set hours [expr $hours + $hour];
	}
	puts [join_list $date $hours];
}


# SAVE THE FILE
set t [time_in]; set ext ".csv"; 
set oldname "Timesheet.csv";
set newname "Timesheet_Reviewed_"; 
set newname $newname$t$ext;
set source $csvloc$oldname;
set target $csvloc$newname;
# file rename -force $source $target;
puts " "; puts "File Reviewed."

}

proc unit_vector {vec} {

set m1 [lindex $vec 0];
set m2 [lindex $vec 1];
set m3 [lindex $vec 2];

set mag [expr ($m1*$m1) + ($m2*$m2) + ($m3*$m3)];
set mag [expr sqrt($mag)];

set m1 [divide $m1 $mag];
set m2 [divide $m2 $mag];
set m3 [divide $m3 $mag];

return [list $m1 $m2 $m3];

}

proc cross_product {u1 u2 u3 v1 v2 v3} {

# puts [join_list $u1 $u2 $u3 $v1 $v2 $v3]
set m1 [expr ($u2*$v3) - ($u3*$v2)];
set m2 [expr ($u3*$v1) - ($u1*$v3) ];
set m3 [expr ($u1*$v2) - ($u2*$v1)];

set mag [expr ($m1*$m1) + ($m2*$m2) + ($m3*$m3)];
set mag [expr sqrt($mag)];

return [list $mag $m1 $m2 $m3];
}







