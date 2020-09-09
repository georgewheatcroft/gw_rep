#!/bin/bash

echo "I am currently set to unmount and remount your Windows OS drive for awful wsl->Windows read errors. If I fail you'll have to either kill existing processes, try the sudo operations I do or restart wsl yourself"

read -p 'drive to unmount [e.g. c]: ' INPUT
LOWER_DRIVE=$(echo "$INPUT" | awk '{print tolower($0)}')
UPPER_DRIVE=$( echo "$INPUT" | awk '{print toupper($0)}')
echo "################# Unmounting $LOWER_DRIVE ###############"

sudo umount /mnt/"$LOWER_DRIVE"
if [ $? -ne 0 ]
then
        echo "unmounting $LOWER_DRIVE drive failed!"
        echo "if its busy, try lsof | grep /mnt/$LOWER_DRIVE"
        exit 3
else
        echo "Unmounting complete, now remounting"
        #magic way of mounting windows drives
        sudo mount -t drvfs "$UPPER_DRIVE":\\ /mnt/"$LOWER_DRIVE"

        if [ $? -ne 0 ] 
        then
                echo "failed to remount $LOWER_DRIVE drive"
        else 
                echo "successfully remounted $LOWER_DRIVE drive"
        fi
fi

        



