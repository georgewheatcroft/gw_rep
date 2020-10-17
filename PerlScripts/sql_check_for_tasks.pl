#!/usr/bin/perl 
use strict;
use Text::CSV;
use Getopt::Std;
use Switch;
use DBI;


my $file = $ARGV[0] or die "Need to get CSV file on the command line\n";; #this is the file being looked at
my $csv = Text::CSV->new ({
        binary    => 1,
        auto_diag => 1,
        sep_char  => ','    
        });
my $user = 'George';
my $password = 'not-my-password';
my $server = 'notmyserver';
our $yr_based_from =  2019;
our $dbh = DBI->connect("dbi:ODBC:Driver={/opt/microsoft/msodbcsql17/lib64/libmsodbcsql-17.6.so.1.1};Server=$server;UID=$user;PWD=$password", {
						PrintError => 0,
						RaiseError => 1}) || die "can't connect to the database: $DBI::errstr\n";
#a bodge to avoid issues from the length being too long or truncation
$dbh->{'LongReadLen'} =  9223372036854775807;
$dbh->{'LongTruncOk'} = 1;

#open the csv and assign
my $lineNo = 0;
my @tasks;
open(my $data, '<:encoding(utf8)', $file) or die "Could not open '$file' $!\n";
while (my $fields = $csv->getline($data)){
        $lineNo++;
        if($lineNo < 2){ #ignore the header line
                next;
        }
        push @tasks, $fields->[0];
}

open (FAILS, ">tmp/bad.tmp") || die "can't open bad.tmp";
open (QUERY, ">tmp/queries.tmp") || die "can't open queries.tmp";
open (RESULTS, ">out/results.tmp") || die "can't open results.tmp";

foreach my $task (@tasks){
        my $kCount = 1;
        my @usedWords = select_action($task);
        if (@usedWords == 0 || !@usedWords){
                print FAILS "$task produced NO words that could be used in a query!!\n";
				print RESULTS "$task produced NO words that could be used in a query!!\n";
        }
}


sub select_action () {
        my $task = shift;
        my $originalTask = $task; #make copy
        $task =~ s/\\C/\\\\C/g; #escape occasional \C that occurs in data  

        if ($task != m/audit(.+)| soa(.+)|s\.o\.a(.+)/i){
                warn "$task doesn't contain usual structure?!\n";
        }
        $task =~ s/audit|soa|s\.o\.a|re-audit|^iso\s|^iso\s-\s|//ig; # remove audit, iso and soa prefixes
        my $action; 
        
        if ($task =~ m/(\d+[^\s,A-Z]+)|(\d+)/){
                $action = "soa number rip";
        }else{
                $action = "general parse";
        }

        switch($action){ ## leave room to add in new actions if needed
                case "soa number rip" { return rip_soa_number($task, $originalTask) }
                case "general parse"  { return general_parse($task, $originalTask)  }
                else { die "an action couldn't be determined for $task so had to die. originalTask = $originalTask "}
        }
}

sub rip_soa_number (){
        my $task = shift;
        my $originalTask = shift;
        my @matches = ($task =~ /(\d+\.\d+\.\d+)|(\d+[^\s,A-Z]+)|(\d+)/g);
        if (@matches > 1){
                foreach (@matches){
                        if($_ ne ""){ #only bother to try finding the match where there is a number 
                                sql_query($_, $task, $originalTask);
                        }
                }
        }
        return @matches;
}

sub general_parse () {
        my $task = shift;
        my $originalTask = shift;
        my @matches = ($task =~ /(".*?")|(\w+\s+\w+)|(\w+\/\w+\s\w+)/g);
        if (@matches > 1){
                print "$task produced the matches: $matches[0]$matches[1]$matches[2]";

                my $query = "$matches[0]$matches[1]$matches[2]";
                sql_query($query, $task, $originalTask);
        }else{
                if ($matches[0] ne ""){
                        sql_query($matches[0], $task, $originalTask);
                }else{
                        print "$task produced no non-blank matches!!\n";
                }
        }
        return @matches;
}

sub sql_query () {
        my $param = shift;
        my $task = shift;
        my $originalTask = shift;

		my $sql = "SELECT COUNT(*) FROM TASKSLIST WHERE BASICDESC LIKE '%$param%'";
	    my $sth = $dbh->prepare($sql); 
		$sth->execute() || die "can't execute the sql: $sql";
		while ( my @row = $sth->fetchrow_array ) {
				print QUERY "$param returns $row[0] rows\n";
                if ($row[0] == 0){
                        print RESULTS "the match used $param gives $row[0] rows! is the task: $task too truncated? made from $originalTask \n" #it should return at least one row from db!
                }else{
                        $sql = $sql." AND DATEOFFINISH IS NULL 
                                      AND CONVERT(NVARCHAR(8), DOBYDATE, 112) > CONVERT(NVARCHAR(8), '2019-00-00 00:00:00', 112)"; #just to ensure we don't go too far back
                        $sth = $dbh->prepare($sql);
                        $sth->execute() || die "can't execute the sql: $sql";
                        while ( my @row = $sth->fetchrow_array ){
                                switch ($row[0]){
                                        case 1 { print RESULTS "#GOOD# there is a new task for $originalTask based on extract: $param\n" }
                                        case 0 { print  RESULTS "#BAD# there is no new task for $originalTask based on extract: $param\n-->${\get_owner($originalTask)} check it and make one?\n\n" }
                                        else   { print RESULTS "#ERROR# $sql returned $row[0] rows based on extract: $param from $originalTask \n" }
                                }
                                if ($row[0] == 1){
                                        print RESULTS "#GOOD# there is a new task for $originalTask based on extract: $param\n";
                                }else{
                                        print RESULTS "#BAD# there is no new task for $originalTask based on extract: $param\n-->${\get_owner($originalTask)} check it and make one?\n\n";
                                }
                        }
                }
		}
}

sub get_owner () {
        my $originalTask = shift;
        my $sql = "SELECT TOP 1 STAFFLIST.LASTNAME, TASKSLIST.TASKOWNER  
				   FROM TASKSLIST 
				   JOIN STAFFLIST ON TASKSLIST.TASKOWNER=STAFFLIST.STAFFLISTID 
				   WHERE TASKSLIST.SHORTDESC = '$originalTask' 
			       AND CONVERT(NVARCHAR(8), DOBYDATE, 112) > CONVERT(NVARCHAR(8), '$yr_based_from-00-00 00:00:00', 112)
				   ORDER BY TASKOWNER DESC"; #so where replacement staff are assigned we will be sure that they are there rather than old staff
        my $sth = $dbh->prepare($sql);
        $sth->execute();
		my $surnameRef = $sth->fetchall_arrayref;
		my $noOfSurnames = scalar(@{$surnameRef});
		if(($noOfSurnames) != 1){
				print FAILS "got $noOfSurnames surnames instead of 1 for task: $originalTask\nsql=\n$sql\n";
				return 'me@myteam.com'; #default is me 
		}
		return lookup_email($surnameRef, $originalTask);
}

sub lookup_email (){
        my $surnameRef = shift;
		my $originalTask = shift;
        switch(lc($surnameRef->[0]->[0])){
                case "personA"        { return 'personA@myteam.com' }
                case "personB"    { return 'personB@myteam.com' }
                case "personC"    { return 'personC@myteam.com' }
                case "me" { return 'me@myteam.com' }
                else { 
						print FAILS "$surnameRef->[0]->[0] not a member of current team?!\n gotten for task=$originalTask";
						return 'me@myteam.com'; # default is to set it to me
				     }
        }
}
