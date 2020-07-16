#!/bin/bash

#info on script
help() {
cat << EOF
usage: ${0##*/} [-t "Text to search unzipped .jars for" ] [-h -q or -r] 
MUST be in the directory containing the jar's you wish to grep .
will return results of jars which had a match with text specified after -t, along with in what jars, in a resultsfromjarsearch.txt file
Always Specify text after -t and ONLY select one of -q , -r. Unless of course querying help

	-t text to search
	-h display this help
	-q quick, but not thorough. will not grep recursively
	-r thorough, will grep recursively
	
e.g. 
	${0##*/}  -t "secretCode.Factory" -r 
EOF
}


# initialise variables and files
pwd | LOCAT=$(); #use current directory
#check there are actually jars in this directory
COUNT=`ls -l $LOCAT*.jar 2>resultsfromjarsearch.txt | wc -l`;
if [ $COUNT == 0 ]
then
	echo "I saw no jars in this directory...";
	exit 1;
fi

:> resultsfromjarsearch.txt; #set and clearout the file

while getopts "t:hqr" opt; do
   case $opt in
	t)	gavetext='1';
		TEXT=$OPTARG #get text and set to var
		;;
	h)	
		help
		exit 0	
		;;	#for end of case statement

        q) #quick, but not recursive
		gaveopt='1';
        for f in $LOCAT*.jar; #Only interested in seeing whats inside jars
        do
                echo "I see $f file..";
                unzip -qq -o $f;
                grep -l -i "$TEXT" * --exclude=*.sh* --exclude=*.txt* >> resultsfromjarsearch.txt; #have to exclude the .sh script so can't self-grep
                if [ $? -eq 0 ]
                then
                        echo "Found match in $f for $TEXT"
                        echo "The above is for the jar $f" >>  resultsfromjarsearch.txt;
                else
                        echo "Didn't find a match in jar $f for $TEXT";
                fi
        done;;

        r) #recursive
		gaveopt='1';
        for f in $LOCAT*.jar;                                                                                                                                 	      do
		echo $TEXT;
                echo "I see $f file..";
                unzip -qq -o $f;
                grep -r -l -i "$TEXT" * --exclude=*.sh* --exclude=*.txt* >> resultsfromjarsearch.txt;                                                                 if [ $? -eq 0 ]
                then
                        echo "Found match in $f for $TEXT"
                        echo "The above is for the jar $f" >>  resultsfromjarsearch.txt;
                else
                        echo "Didn't find a match in jar $f for $TEXT";
                fi
        done;;

        \?)
                echo "Invalid option: -$OPTARG" >&2
                exit 1
                ;;
       	 '?')
		help >&2 
		exit 1
		;;
   esac
#exit 0;
done

#catch scenarios where user doesn't enter any opts
if [ -z "$gaveopt" ] || [ -z "$gavetext" ]
then	

	printf "\n!!!!----> You must specify -t input and either -q, -r or -h  <-----!!!!\n\n";
	help >&2
	exit 1;
fi	
	
