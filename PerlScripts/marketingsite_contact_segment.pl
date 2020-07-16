#!/usr/bin/perl -I/usr/local/lib/perl

use strict;
use JSON::XS;
use Data::Dumper;
use Getopt::Std;
use Text::CSV::Encoded;
use Text::CSV_XS;

our $opt_L;

my $ocsv = Text::CSV::Encoded->new ({
	encoding_in => 'utf-8',
	encoding_out => "utf-8",
	binary=>1,
});


getopts(':L:');


my $Msite = Marketingsite->new( email=>'some.emaily@somecompany.com', password=>'not my password');
my $token = $Msite->auth();


open(SEG, ">tmp.SEGNEW");
$ocsv->print(\*SEG, ['Segment','ID','Role','First_Name','Last_Name','Company','Specific_Location','Country_Location','APP_OR_REJECT','SOME_SITE_SEGMENTS_GUID','TID','CREATED_BY','CREATED_DATE','UPDATED_BY','UPDATED_DATE']); #last six headers for database table's columns I filled in the backend
print SEG "\n";

for(my $page=1;;$page++) {
	my $j = $hub->segments($page);
	#print OUT Dumper($j); 
	#print OUT "\n";
	my $cnt = @{$j->{data}};
	if (!$cnt) {
		exit;
	}
	extract_page($j);
}

#where I take json data I got, order and write to a file which I later insert into a database table
sub extract_page {
	my $j = shift;

	foreach my $datum (@{$j->{data}}) {
		my $name = 1;
  		my $person = $datum->{personId};
		#		my $name = $datum->{name};
		my $status = $datum->{status};
		my $id = $datum->{_id};
		my $companyinitialthing = $person->{companyId};
		my $company = $companyinitialthing->{fullName};		

		my $legalname = $companyinitialthing->{legalName};
	
	
		my $location = $person->{locationCountryCode};
		my $roleupper = $person->{title};
		my $role = lc($roleupper);
		my $specificlocation = $companyinitialthing->{LocationCity};
		my $firstname = $person->{firstName};
		my $lastname = $person->{lastName};
                
                 #the empty strings at end are a hack to ensure compatibility with database table columns when inserting
		 $ocsv->print(\*SEG, ['the name of the only segment I needed to get',$id,$roleupper,$firstname,$lastname,$company,$specificlocation,$location,'','','','','','','']);

				print SEG "\n";
	}
}

package Marketingsite;
use Data::Dumper;
use JSON::XS;
use HTTP::Cookies;
use LWP;

sub new {
    my ($class,%args) = @_;

    my $self = {};
    bless $self;

    $self->{args} = \%args;

    $self->{base_url} = 'https://some-marketing-site';

    my $ua = LWP::UserAgent->new(keep_alive => 1,  ssl_opts => { verify_hostname => 0 },);
    $ua->timeout(240);
    $ua->agent('Mozilla/5.0');
    $ua->requests_redirectable(['GET', 'HEAD', 'POST', 'PUT', 'DELETE']);
    $ua->cookie_jar(HTTP::Cookies->new(
		file => '/tmp/wp.cookies',
                autosave => 1,
                ignore_discard=>1,
	));

    $self->{ua} = $ua;

    $self->{can_accept} = HTTP::Message::decodable;

    return $self;
}

#authenticate with marketing site
sub auth {
    my $self = shift;
    my $path = shift;

    my $url = $self->{base_url} . '/auth/local' . $path;
    my $req = HTTP::Request->new( POST => $url);
    $req->content_type('application/json');
    $req->header(Accept=>"application/json");
	$req->header('Accept-Encoding'=>$self->{can_accept});

	my $content = encode_json({
		email=>$self->{args}->{email},
		password=>$self->{args}->{password}
	});

	$req->content($content);

	my $s = $req->as_string;

    my $res = $self->{ua}->request($req);

    if ($res->is_success) {
       } else {
                print Dumper($res);
                my $x = $res->status_line;
                die "Bad: $x";
    }
    my $j = $res->decoded_content;

    my $hash = decode_json($j);

    $self->{token} = $hash->{token};

    return $hash->{token};
}



#main getter of data - only needed to get data for one segment in the end       
sub segments {
    my $self = shift;
	my $page = shift;

    my $url = $self->{base_url} . "/v2/api/v2/someurlnonsense-I-wontdeclare=$page";
    my $req = HTTP::Request->new( GET => $url);
    $req->header(Accept=>"application/json");
	$req->header('Accept-Encoding'=>$self->{can_accept});
    $req->content_type('application/json');
    $req->header(Authorization=>'Bearer '. $self->{token});
	$req->header('Referer' => 'https://some-marketing-site/v2/someurlnonsense-I-wontdeclare');

	if ($opt_L && -e $opt_L) {
		open(CACHE, $opt_L) || die("Can't open '$opt_L': $!");
		$/ = undef;
		my $ret = <CACHE>;
		return decode_json($ret);
	}

    my $res = $self->{ua}->request($req);

    if ($res->is_success) {
		my $ret = $res->decoded_content;
		if ($opt_L) {
			open(CACHE, ">$opt_L") || warn("can't write to $opt_L: $!");
			print CACHE $ret;
		}
		return decode_json($ret);
    } else {
        print Dumper($res);
        my $x = $res->status_line;
        die "Bad: $x";
    }
}

