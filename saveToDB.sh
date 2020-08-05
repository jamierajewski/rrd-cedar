#!/bin/bash -l

max_number_jobs=10000
set -euo pipefail

# The main; fetch the list of users then iterate over it, applying the function to each
#USERS=$(getent group rpp-kenclark | cut -d ":" -f4) 
USERS=jpyanez,kenclark,moore,hignight,gaertner,kleonard,jrajewsk,ckopper,iceprod,dghuman,mliubar,wym109,ssarkar,mfens

# Ping squeue ONCE, then REGEX it to reduce load on slurm
SQUEUE_OUT=$(squeue -r -u $USERS -t R,PD -h)

fetch_and_update(){
    RRD_DATABASE=~/rrd-cedar/${1}.cedar.rrd

    if [[ ! -e ${RRD_DATABASE} ]]; then
        rrdtool create ${RRD_DATABASE} --step 600 \
                DS:${1}_cpu_R:GAUGE:600:0:${max_number_jobs} \
                DS:${1}_cpu_Q:GAUGE:600:0:${max_number_jobs} \
		DS:${1}_gpu_R:GAUGE:600:0:${max_number_jobs} \
		DS:${1}_gpu_Q:GAUGE:600:0:${max_number_jobs} \
		RRA:AVERAGE:0.5:1:1500  \
                RRA:AVERAGE:0.5:30:1500 \
                RRA:AVERAGE:0.5:360:7500
    fi

    # Get the running and pending jobs and store them
    R_TOTAL=$(echo "$SQUEUE_OUT" | awk -v user="$1" 'BEGIN {r=0} {if ($2 == user && $5 == "R") {r+=1}} END {print r}')
    Q_TOTAL=$(echo "$SQUEUE_OUT" | awk -v user="$1" 'BEGIN {q=0} {if ($2 == user && $5 == "PD") {q+=1}} END {print q}')
    
    R_GPU=$(echo "$SQUEUE_OUT" | awk -v user="$1" 'BEGIN {r=0} {if ($2 == user && $5 == "R" && $9 ~ /gpu/) {r+=1}} END {print r}')
    Q_GPU=$(echo "$SQUEUE_OUT" | awk -v user="$1" 'BEGIN {q=0} {if ($2 == user && $5 == "PD" && $9 ~ /gpu/) {q+=1}} END {print q}')

    R_CPU=$(echo "$R_TOTAL - $R_GPU" | bc)
    Q_CPU=$(echo "$Q_TOTAL - $Q_GPU" | bc)

    
    # Now create the readout
    RRD_OUT=$(echo "N:$R_CPU:$Q_CPU:$R_GPU:$Q_GPU")

    # DEBUG
    #echo "$1 -- $RRD_OUT"
    rrdtool update ${RRD_DATABASE} ${RRD_OUT}
}

IFS=',' read -ra SPLIT <<< "$USERS"
for USER in "${SPLIT[@]}"; do
    fetch_and_update "$USER"
done
