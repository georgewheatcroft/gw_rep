#!/bin/bash

arr=($(cat getthese.txt | awk '/git/ {print $1}')); 
arr2=($(cat getthese.txt | awk '/svn/ {print $1}'));
echo "########GIT########";
for i in "${arr[@]}"
do 
       git clone "$i";  
done
echo "########SVN#######";
for svn in "${arr2[@]}"
do
       svn co "$svn";
done
echo "####Finished!####";
