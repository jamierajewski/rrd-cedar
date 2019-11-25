#!/bin/bash -l

# To run:
# ./slack_uploader.sh [TIME_PERIOD]

# EXAMPLE
# curl -F file=@cycling.jpeg -F "initial_comment=Hello, Leadville" -F channels=C0R7MFNJD -H "Authorization: Bearer xoxp-123456789" https://slack.com/api/files.upload

if [ ! -f token ]; then
    echo "No token found; please put Slack API token in `token` file."
    exit 1
fi

TOKEN=$(cat token)

SINCE="last week"

if [[ "x$@" != "x" ]]; then
    SINCE=$@
fi

if [[ "$SINCE" == "yesterday" ]]; then
    PERIOD="days"
elif [[ "$SINCE" == "last week" ]]; then
    PERIOD="weeks"
elif [[ "$SINCE" == "last month" ]]; then
    PERIOD="months"
elif [[ "$SINCE" == "last year" ]]; then
    PERIOD="years"
# Default to showing the last week
else
    SINCE="last week"
    PERIOD="weeks"
fi

# First, call the plotting script with the appropriate argument (last day, last week, last month, last year)
../plotFromDB.sh "$SINCE"

# Get the date range
STARTDATE=$(date +%D)
ENDDATE=$(date +%D -d "$DATE1 -1 $PERIOD")

URL="https://slack.com/api/files.upload"

# Upload each of the 4 plots
curl -F file=@sp_cpu_queued.png -F "initial_comment=CPU Queued for $ENDDATE to $STARTDATE ($SINCE)" -F channels=CMMFDJ83F -H "Authorization: Bearer $TOKEN" $URL
curl -F file=@sp_cpu_running.png -F "initial_comment=CPU Running for $ENDDATE to $STARTDATE ($SINCE)" -F channels=CMMFDJ83F -H "Authorization: Bearer $TOKEN" $URL
curl -F file=@sp_gpu_queued.png -F "initial_comment=GPU Queued for $ENDDATE to $STARTDATE ($SINCE)" -F channels=CMMFDJ83F -H "Authorization: Bearer $TOKEN" $URL
curl -F file=@sp_gpu_running.png -F "initial_comment=GPU Running for $ENDDATE to $STARTDATE ($SINCE)" -F channels=CMMFDJ83F -H "Authorization: Bearer $TOKEN" $URL
