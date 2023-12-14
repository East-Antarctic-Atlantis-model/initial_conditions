# #!/bin/bash


# # Converting all files except output files to Unix format
# find /app/model -type f -not -path "/app/model/output_EA_*.*" -not -path "/app/model/d2utmp*" -not -path "/app/model/ARCHIVE*" -not -path "/app/model/temp*" | xargs dos2unix

# # Assign prm files
# echo "PRM_FILE is $PRM_FILE"
# echo "OUTPUT_DIR is $OUTPUT_DIR"

# # Running the Atlantis model
# atlantisMerged -i final_with_ice_input_v2.nc 0 -o output_f_.nc -r EA_run.prm -f EA_force.prm -p EA_physics.prm -b $PRM_FILE -h EA_harvest_nofishing.prm -s AntarcticGroups_v2_basicfoodweb.csv -d $OUTPUT_DIR -m EA_migrations.csv
# Find all prm, csv, and nc files (and any other extensions you want to include)


# Assign prm files
echo "PRM_FILE is $PRM_FILE"
echo "OUTPUT_DIR is $OUTPUT_DIR"

# List of specific prm files to convert (including $PRM_FILE)
find /app/model -type f \
    -not -path "/app/model/output_EA_*.*" \
    -not -path "/app/model/d2utmp*" \
    -not -path "/app/model/ARCHIVE*" \
    -not -path "/app/model/temp*" \
    -name $PRM_FILE \
    -name "final_with_ice_input_v2.nc"  \
    -name "EAAM_28_init.nc"  \
    -name "EAAM_28_polygons_xy.bgm"  \
    -name "EA_run.prm" \
    -name "EA_force.prm" \
    -name "EA_physics.prm" \
    -name "EA_harvest_nofishing.prm" \
    -name "AntarcticGroups_v2.csv" \
    -name "AntarcticGroups_v2_basicfoodwebs.csv" \
    -name "EA_migrations.csv" \
    | xargs dos2unix


# Running the Atlantis model
# Full food web version
atlantisMerged -i EAAM_28_init.nc 0 -o output_f_.nc -r EA_run.prm -f EA_force.prm -p EA_physics.prm -b EA_biol_newdiet_v30_B_121223_23 -h EA_harvest_nofishing.prm -s AntarcticGroups_v2.csv -d output_test -m EA_migrations.csv
# Basic food web (krill and ice krill are apex predators)
#atlantisMerged -i final_with_ice_input_v2.nc 0 -o output_f_.nc -r EA_run.prm -f EA_force.prm -p EA_physics.prm -b $PRM_FILE -h EA_harvest_nofishing.prm -s AntarcticGroups_v2_basicfoodweb.csv -d $OUTPUT_DIR -m EA_migrations.csv