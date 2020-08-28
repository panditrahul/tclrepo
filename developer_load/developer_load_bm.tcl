proc delete_comp_list {n} {

# FIND ALL DISPLAYED COMPS
	*createmark comps 1 "all";
	set all_comps [hm_getmark comps 1];
	set total [llength $all_comps];
	clear_marks;
	
# LOOP
	set comp_list {}; 
	foreach index [range $n $total] { 
	lappend comp_list [lindex $all_comps $index]; 
	}
	
# DELETE COMPS
	clear_marks; eval *createmark comps 1 $comp_list; *deletemark comps 1;

}

proc comp_segment {no_of_segments} {

# STEP-0: PUT THE LOCATION WHERE THE SEGMENTS HAVE TO BE SAVED
set filepath "C:/Local_Folder/Mahindra_Testing/00-Repository/Break_Comps/";


*startnotehistorystate; # Begin History State

# STEP-2: DELETE COMPS -> Nth to Last AND RECORD CURRENT COMPS
set output [delete_comp_list $no_of_segments]; 
*createmark comps 1 "all";


# STEP-3: WRITE HM FILE WITH PROPER NOMENCLATURE
	set db1 "BIW_Segment_";	
	set db2 "_"; set ext ".hm";
	set min [hm_entityminid comps];
	set max [hm_entitymaxid comps];
	set filename $db1$min$db2$max$ext; puts $filename;
	set file $filepath$filename; 
	*writefile $file 1; 

*endnotehistorystate; # End History State

# UNDO COMP DELETE AFTER SAVING THE FILE !
*createmark comps 1 "all"; set comp_list [hm_getmark comps 1]; *undohistorystate;

# DELETE COMPS AND READY FOR ROUND-2 !
eval *createmark comps 1 $comp_list;
*deletemark comps 1;
}

proc main_loop {} {

set t [time_in];
foreach n [range 1 15] { comp_segment 15; }

set t [time_out $t];
puts [join_list "Execution-Time:" $t "seconds"];

}