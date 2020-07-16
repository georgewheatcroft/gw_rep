#!/usr/perl
use warnings;
use strict;
use Paws;

my $rds = Paws->service('RDS', region=>'eu-west-1');
my $DBInstanceMessage = $rds->DescribeDBInstances(MaxRecords => 100);
	
my $count = 1;
	foreach my $data (@{$DBInstanceMessage->{DBInstances}}){
				my %hash;	
				my $dbname = $data->{DBInstanceIdentifier};	
				my $dbsize = $data->{AllocatedStorage};
				
				print "Database: ".$dbname." its size=".$dbsize." Gb\n";
				
				createalarms($dbname, $dbsize);
			}

sub createalarms {
	my $dbname = shift;
    my $dbsize = shift;
		
		my $quarterofdb = $dbsize / 4; #25% of availiable storage on the database - used for setting when "lack of storage space remaining" 
		my $alarmthreshold = $quarterdb * 1073741824; #Convert Gigabyte to Bytes

		my $wat = Paws->service('CloudWatch', region=>'eu-west-1');	
		my $res = $wat->PutMetricAlarm(
			AlarmName=>'DB: '.$dbname.' - StorageSpaceLeft',
			Dimensions=>[{
				Name=>'DBInstanceIdentifier',
				Value=>$dbname,
			}],
			ComparisonOperator=>'LessThanOrEqualToThreshold',
			EvaluationPeriods  => 1,
			ActionsEnabled=>1,
			AlarmActions=>[
				'arn:aws:sns:eu-west-1:549610383227:Disk_Space_Usage_Alert',
			],
			AlarmDescription=>$dbname.' - Storage Space Alarm',
			DatapointsToAlarm => 1,
			TreatMissingData=>'ignore', #Else CloudWatch will treat its metric I am comparing to as "insufficient data" and do nothing
			MetricName=>'FreeStorageSpace',
			Namespace=>'AWS/RDS',
			Statistic=>'Average',
			Period=>60,	
			Threshold=>$alarmthreshold, #This is 25%
			);
}
