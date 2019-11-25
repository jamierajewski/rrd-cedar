#!/bin/bash -l

# Credit to Joshua Hignight for allowing me to use
# his script as a base; modified by Jamie Rajewski

#SINCE="12/10/2016"
#SINCE="last month"
SINCE="last week"
#SINCE="yesterday"

if [[ "x$@" != "x" ]]; then
        SINCE=$@
fi

if [[ "$SINCE" == "yesterday" ]]; then
        XGRID="--x-grid HOUR:1:HOUR:4:HOUR:4:0:%H:%M"
elif [[ "$SINCE" == "last day" ]]; then
        XGRID="--x-grid HOUR:1:HOUR:4:HOUR:4:0:%m/%d^M%H:%M"
elif [[ "$SINCE" == "last week" ]]; then
        XGRID="--x-grid HOUR:6:DAY:1:DAY:1:0:%m/%d"
elif [[ "$SINCE" == "last month" ]]; then
        XGRID="--x-grid DAY:1:WEEK:1:WEEK:1:0:%m/%d"
elif [[ "$SINCE" == "last year" ]]; then
        XGRID="--x-grid MONTH:1:MONTH:2:MONTH:2:0:%m-%Y"
else
        XGRID=""
fi

declare -a RRD_DATABASE
declare -a USER
declare -a NAME

i=0
for rrd in ~/rrd-cedar/*.cedar.rrd; do
        RRD_DATABASE[$i]=$rrd
        rrd=`basename $rrd .cedar.rrd`
        USER[$i]=${rrd}
        NAME[$i]=${USER[$i]}

        i=$((i+1))
done

COLOR=('#e6194b' '#3cb44b' '#ffe119' '#4363d8' '#f58231' '#911eb4' '#46f0f0' '#f032e6' '#bcf60c' '#fabebe' '#008080' '#e6beff' '#9a6324' '#fffac8' '#800000' '#aaffc3' '#808000' '#ffd8b1' '#000075' '#808080' '#ffffff' '#000000')

for queue in cpu gpu; do
	for st in R Q; do
		st_full="running"
		if [[ "$st" == "Q" ]]; then
			st_full="queued"
		fi

		DEF_LINE_DEF=""
		DEF_LINE_LINE=""
		DEF_LINE_AREA=""
		SUM=""

		for j in `seq 0 $((i-1))`; do		
			DEF_LINE_DEF=${DEF_LINE_DEF}" DEF:${USER[$j]}_${queue}=${RRD_DATABASE[$j]}:${USER[$j]}_${queue}_$st:AVERAGE "
			DEF_LINE_LINE=${DEF_LINE_LINE}" LINE2:${USER[$j]}_${queue}${COLOR[$(($j % ${#COLOR[@]}))]}:${USER[$j]}@${queue}"
			if [[ $j -eq 0 ]]; then
				SUM="${USER[$j]}_${queue},UN,0,${USER[$j]}_${queue},IF"
				DEF_LINE_AREA=${DEF_LINE_AREA}" AREA:${USER[$j]}_${queue}${COLOR[$j]}:${USER[$j]}@${queue}"
			else
				SUM=${SUM}",${USER[$j]}_${queue},UN,0,${USER[$j]}_${queue},IF,+"
				DEF_LINE_AREA=${DEF_LINE_AREA}" STACK:${USER[$j]}_${queue}${COLOR[$j]}:${USER[$j]}@${queue}"
			fi	     
		done
		HLINE=""
		HLINE2=""

		rrdtool graph sp_${queue}_${st_full}.png \
			--start `date --date="${SINCE}" +%s ` --end `date +%s` \
			--height 300 --width 900 --alt-y-grid --lower-limit 0 --rigid \
			--vertical-label "# of ${queue^^} ${st_full} jobs" \
			--watermark "Generated `date +'%Y-%m-%d %H:%M'`" \
			--font DEFAULT:11: \
			${XGRID} \
			${DEF_LINE_DEF} \
			CDEF:all=${SUM} LINE2:all${COLOR[$i]}:"Total" \
			GPRINT:all:AVERAGE:"(avg %6.1lf)" \
			${HLINE} \
			${DEF_LINE_LINE}
		# rrdtool graph sp_stack_${queue}_${st_full}.png \
		# 	--start `date --date="${SINCE}" +%s ` --end `date +%s` \
		# 	--height 300 --width 900 --alt-y-grid --lower-limit 0 --rigid \
		# 	--vertical-label "# of ${queue^^} ${st_full} jobs" \
		# 	--watermark "Generated `date +'%Y-%m-%d %H:%M'`" \
		# 	--font DEFAULT:11: \
		# 	${XGRID} \
		# 	${HLINE2} \
		# 	${DEF_LINE_DEF} \
		# 	${DEF_LINE_AREA}
	done
done
