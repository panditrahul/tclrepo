# THIS SCRIPT IS RUN ON THE CATIA V5 CONNECTOR DATA FILE

proc catia_csv_review {csvfile r1 r2} {

# STEP-1: READ CONTENTS OF CSV FILE
set csvdata [csv_read $csvfile];

# STEP-2: SCAN ALL ROWS AND DOCUMENT PRODUCTION-NOS
set production_id_list {}; set main_output {};
foreach nrow [range $r1 $r2] {

	set con_name [csv_get $csvdata $nrow [list 1]]; # Find Connector Name.
	# set type [csv_get $csvdata $nrow [list 10]]; # Find Type.
	set JCPN [csv_get $csvdata $nrow [list 38 59 80 101 122]]; # Find JCPNs.
	set production_id [get_compid_from_jcpn $JCPN]; # Using JCPN find Comp-IDs.
	set production_id [lindex $production_id 0];
	
	# CHECK IF ANY PRODUCTION NOS HAVE MORE THAN ONE COMP
	set flag 0;
	foreach PRN $production_id { 
		set comps [get_compid_from_jcpn $PRN]; 
		set comps [lindex $comps 1];
		set no_of_comps [llength $comps];

		lappend production_id_list $PRN;
		if {(($no_of_comps == 0) && ($PRN != "N/A")) || ($no_of_comps > 1) } { 
			set flag [expr $flag +1];
		};		
	}
	
	set msg [join_list $nrow "," $con_name "," [lindex $production_id 0] "," [lindex $production_id 1] "," [lindex $production_id 2] "," [lindex $production_id 3] "," [lindex $production_id 4] "," $flag];
	puts $msg; lappend main_output $msg;
	
}

# STEP-3: FIND UNIQUE PRODUCTION-IDs
set UPRNS [unique_items $production_id_list];

# STEP-4: FOREACH UNIQUE PRN FIND THE CORRESPONDING COMPS 
set UPRN_COMPS {}; foreach UPRN $UPRNS {
	set comps [get_compid_from_jcpn $UPRN]; set comps [lindex $comps 1];
	set msg [join_list $UPRN $comps]; 
	lappend UPRN_COMPS $msg;
	puts $msg;
}


# STEP-5: WRITE TO FILE THE UNIQUE PRODUCTION NOs AND CORRESPONDING COMPS
	set logfile0 "CATIA_CSV_Review_UPRN_COMPS.log";
	set logfile1 "P:/InDepth-MethodsDev/21-hmtools/hmtools/mahindra_toolset/00-Repository/BIW_from_NT/";
	set logfile $logfile1$logfile0;
	set file [open $logfile "w+"];
	foreach out $UPRN_COMPS { puts $file $out; }
	puts "CATIA_CSV_Review_UPRN_COMPS.log Written"; close $file

# STEP-6: WRITE TO FILE THE MAIN OUTPUT
	set logfile0 "CATIA_CSV_Review_MAIN.log";
	set logfile1 "P:/InDepth-MethodsDev/21-hmtools/hmtools/mahindra_toolset/00-Repository/BIW_from_NT/";
	set logfile $logfile1$logfile0;
	set file [open $logfile "w+"];
	foreach out $main_output { puts $file $out; }
	puts "CATIA_CSV_Review_MAIN.log Written"; close $file;

}