#!/bin/sh
clear;
while : ; 
do 
	echo "[0;0H"
	NOW=$(date +%T)
	toilet  $NOW; #cool font
	cowsay "MOOOO!!"
	sleep .9 #to prevent lag effects - as the comands may take longer than milisecs to execute and thus would lead to lag effects if resolution =1 sec
done
