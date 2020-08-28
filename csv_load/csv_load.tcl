# CSV_READ: Pass the name of the csv file. It extracts and returns its contents. The csv file should be in the same directory as this functions.

# CSV_GET: Pass the csv data as returned from csv_read along with any specific row and col. The function returns the element in the nth row and nth col.

proc csv_read {csvname} {

# UNSET ALL DATA
set data {};
set nrows {};

# # GET CSV FILE NAME
# set where [file dirname [info script]];
# set csvname [file join $where $csvname];

#  IMPORT THE DATA IN CSV FILE
set fp [open $csvname r]; set file_data [read $fp]; close $fp;

#  SPLIT THE DATA FILE USING NEWLINE AND RETURN
set data [split $file_data "\n"];
return $data;

}


proc csv_get {csv_data nrow ncols} {

# PARSE DATA
set nrow [expr $nrow -1]; set ncol {}; 
foreach nc $ncols { lappend ncol [expr $nc -1]; }

# GET DATA IN THE NTH ROW
set rowdata [lindex $csv_data $nrow];
set rowdata [split $rowdata ","];

# GET COL DATA
set coldatas {};
foreach col $ncol {

# GET DATA IN THE NTH COL
set coldata [lindex $rowdata $col];
lappend coldatas $coldata;

}

# RETURN
return $coldatas;

}

