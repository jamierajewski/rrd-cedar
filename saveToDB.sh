#!/bin/bash -l

max_number_jobs=10000
set -o pipefail

fetch_and_update(){
    RRD_DATABASE=~/rrd-cedar/${1}.cedar.rrd

    if [[ ! -e ${RRD_DATABASE} ]]; then
        rrdtool create ${RRD_DATABASE} --step 120 \
                DS:${1}_cpu_R:GAUGE:600:0:${max_number_jobs} \
                DS:${1}_cpu_Q:GAUGE:600:0:${max_number_jobs} \
		RRA:AVERAGE:0.5:1:1500  \
                RRA:AVERAGE:0.5:30:1500 \
                RRA:AVERAGE:0.5:360:7500
    fi

    # Get the running and pending jobs and store them
    R=$(squeue -u $1 -t R -h | wc -l)
    Q=$(squeue -u $1 -t PD -h | wc -l)
    
    # Now create the readout
    RRD_OUT=$(echo "N:$R:$Q")

    # DEBUG
    #echo "$1 -- $RRD_OUT"
    rrdtool update ${RRD_DATABASE} ${RRD_OUT}
}

# The main; fetch the list of users then iterate over it, applying the function to each
USERS=$(getent group rpp-kenclark | cut -d ":" -f4)

IFS=',' read -ra SPLIT <<< "$USERS"
for USER in "${SPLIT[@]}"; do
    fetch_and_update "$USER"
done
