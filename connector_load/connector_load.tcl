
proc connector_create {node comps layers} {

# HIDE DISPLAYED CONNECTORS
*createmark connectors 1 "displayed";
*maskmark connectors 1;

# CREATEMARK OF NODES AND PANELS
eval *createmark nodes 1 $node
eval *createmark comps 2 $comps
# set layers [hm_getmark comps 2];
# set layers [llength $layers];

# PARAMETERS FOR CREATING CONNECTORS
*createstringarray 8  "link_elems_geom=elems" "link_rule=now" "relink_rule=none" "tol_flag=1" "tol=25.000000"

# CREATE CONNECTORS FOR GIVEN COMPS AND NODE
*CE_ConnectorCreateByMark nodes 1 "spot" $layers comps 2 1 5;

# CREATE MARK
*createmark connectors 1 "displayed";
return [hm_getmark connectors 1];

}

proc connector_realize_nastran {connector_list} {

# CLEAR MARKS
hm_markclearall 1; hm_markclearall 2;

# CHANGE TYPE
eval *createmark connectors 1 $connector_list;
*setvalue connectors mark=1 spot_nastran_configname="sealing";

# CHANGE POST
eval *createmark connectors 1 $connector_list;
*setvalue connectors mark=1 ce_propertyscript_option="no/skip post script";

# CHANGE HOUSING COMP
eval *createmark connectors 1 $connector_list;
*setvalue connectors mark=1 ce_realizeto="elems to connector comp"

# REALIZE CONNECTORS
eval *createmark connectors 1 $connector_list;
*CE_Realize 1

# CLEAR MARKS
hm_markclearall 1; hm_markclearall 2;

}

# # FOR TESTING
# clear

# # CLEAR MARKS
# hm_markclearall 1; hm_markclearall 2;

# # SELECT NODE
# *createmarkpanel nodes 1 "Select Node: ";
# set nid [hm_getmark nodes 1];

# # SELECT COMPS
# *createmark comps 1 "displayed";
# set comps [hm_getmark comps 1];

# # CREATE CONNECTOR
# *createentity comps
# set connector_list [connector_create $nid $comps 2];

# # REALIZE CONNECTOR WITH NASTRAN
# connector_realize_nastran $connector_list;







