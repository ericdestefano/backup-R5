#!/bin/bash

SERVER_ADDR=10.0.7.50/data

#Get running VM list before backup and stick it into an array
mapfile -t VM_ARRAY < <( ssh eric@10.0.7.50 -i /home/eric/Documents/ssh/r5.key 'vboxmanage list runningvms' | awk '{print $1}' | sed -e 's/^"//' -e 's/"$//' )

#See if any VMs are running, and if not do not execute shutdown
if [ -z $VM_ARRAY ]
then
	echo "No Running VMs"
else

#Start shutdown of running VMs 
	for i in "${VM_ARRAY[@]}"
	do
	ssh eric@10.0.7.50 -i /home/eric/Documents/ssh/r5.key 'vboxmanage controlvm' $i acpipowerbutton
	sleep 30
	done
fi

#Check if any VMs are still running, and stick them into another array
mapfile -t VM_ARRAY_STILL_RUNNING < <( ssh eric@10.0.7.50 -i /home/eric/Documents/ssh/r5.key 'vboxmanage list runningvms' | awk '{print $1}' | sed -e 's/^"//' -e 's/"$//' )

#If any VMs are still running, bring them down hard, otherwise move on
if [ -z $VM_ARRAY_STILL_RUNNING ]
then
        echo "No Running VMs"
else

#Start hard shutdown of running VMs
        for i in "${VM_ARRAY_STILL_RUNNING[@]}"
        do
        ssh eric@10.0.7.50 -i /home/eric/Documents/ssh/r5.key 'vboxmanage controlvm' $i poweroff
        sleep 10
        done
fi

#Start the backup
rsync -e 'ssh -i /home/eric/Documents/ssh/r5.key' -ruv --progress eric@10.0.7.50:/mnt/data/* /mnt/backup/

#Start up previously shutdown VMs
        for i in "${VM_ARRAY[@]}"
        do
        ssh eric@10.0.7.50 -i /home/eric/Documents/ssh/r5.key 'vboxmanage startvm' $i --type headless
        sleep 10
        done

exit 0
