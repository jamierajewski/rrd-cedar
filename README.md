# rrd-cedar
Round-robin database for monitoring Cedar usage by user

## Usage
1. Clone this repo

2. Swap out the placeholder token with the real slack bot token

3. Set up a crontab to run on a schedule based on how often you want new data retrieved. For example, to get data every 10 minutes:
```
*/10     *       *       *       *       bash -l ~/rrd-cedar/saveToDB.sh
```
Then, in the saveToDB.sh, change the `--step ...` argument to that value in seconds (so here, 10 minutes is 600).

*NOTE* - Don't set it to be too frequent as this will put a large strain on the slurm accounting system. Try to keep it at 5 minutes or above.

4. Add an entry to the crontab for uploading to slack on whichever schedules you'd like. For example, to schedule for daily and weekly plots:
```
1       0       *       *       SUN     cd ~/rrd-cedar/slack_uploader && bash -l slack_uploader.sh last week
0       0       *       *       *       cd ~/rrd-cedar/slack_uploader && bash -l slack_uploader.sh yesterday
```

## To modify users
Open up saveToDB.sh and add/delete names in the `users` string at the top.
