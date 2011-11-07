#!/bin/bash 
# make-run.sh 
# make sure a process is always running.  
# Add the following to the crontab (i.e. crontab -e)
# */5 * * * * /home/ianpurton.com/projects/worker-servermonhq/make-run.sh PASSWORD

process=servermonitoringhq 
makerun="$HOME/projects/worker-servermonhq/bin/runjob.exp $1"  

if ps ax | grep -v grep | grep $process > /dev/null         
then                 
  exit         
else         
  $makerun
fi 
