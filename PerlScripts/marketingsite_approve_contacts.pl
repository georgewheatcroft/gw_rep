#!/usr/bin/perl -I/usr/local/lib/perl

use strict;
use JSON::XS;
use Data::Dumper;
use Getopt::Std;
use Text::CSV::Encoded;
use Text::CSV_XS;


my $Msite = Marketingsite->new( email=>'some email I wont declare', password=>'not my password');
my $token = $Msite->auth();

my @accept_array = $Msite->approvelist();
$Msite->acceptcontacts;


package Marketingsite;
use Data::Dumper;
use JSON::XS;
use HTTP::Cookies;
use LWP;
use Text::CSV::Encoded;
use Text::CSV_XS;
use Regexp::Assemble;

my $ocsv = Text::CSV::Encoded->new ({
		        encoding_in => 'utf-8',
			        encoding_out => "utf-8",
				        binary=>1,
				});

			open(CHEEK, ">tmp.cheek");
			$ocsv->print(\*CHEEK, ['some daft shit']);
			print CHEEK "\n";

sub new {
    my ($class,%args) = @_;

    my $self = {};
    bless $self;

    $self->{args} = \%args;

    $self->{base_url} = 'https://some-marketing-site.com';

	my $ua = LWP::UserAgent->new(keep_alive => 1,  ssl_opts => { verify_hostname => 0 },);
	$ua->timeout(240);
    $ua->agent('Mozilla/5.0');
    $ua->requests_redirectable(['GET', 'HEAD', 'POST', 'PUT', 'DELETE']);
	$ua->cookie_jar(HTTP::Cookies->new(
		file => '/tmp/wp.cookies'
		, autosave => 1
		, ignore_discard=>1
	));

    $self->{ua} = $ua;
    

	$self->{can_accept} = HTTP::Message::decodable;

	return $self;
}

#authenticate to the marketing site
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

	$self->{token} = $hash->{token}; #set the token to the lwp obj

	return $hash->{token};
}

#get list from a file I pulled from a database
sub approvelist {
	my $self = shift;
	
	my @idlist;

    	open (APPROVED, "<", "/some/path/tmp.finalapproved") || die $!; #reads the approved I collected 
	while (<APPROVED>) {
		chomp;
		push @idlist, $_;
	}
	#	my @idlist = (<APPROVED>);
	close APPROVED || die $!;

	#keep this death silent - so doesn't output into file that streams stdout from this script
	if (!@idlist){ exit ;}

my $approvedcount = scalar(@idlist);

$self->{accept_array} = \@idlist;

if(!$self->{accept_array}){ die "no desired contacts could be passed by program";}
 
return @idlist;

} 
#the final hurdle
sub acceptcontacts {

	
my $self = shift;

    my $url = "https://some-marketing-site.com/v2/api/v2/prospects/accept";
    my $req = HTTP::Request->new( POST => $url);
    $req->header(Accept=>"application/json");
    $req->header('Accept-Encoding'=>$self->{can_accept});
    $req->header('Host'=>'some-marketing-site.com');
    $req->header('Origin'=>'https://some-marketing-site.com');
    $req->content_type('application/json');
    $req->header(Authorization=>'Bearer '. $self->{token});
        my $content = encode_json({
			 contacts=>$self->{accept_array},
                         filters=>["segment=some-number-I-wont-declare"],   #harcoded - as we only auto approve contacts for one segement for now
						        });
					
	$req->content($content);
	  my $s = $req->as_string;

            if ($opt_L && -e $opt_L) {
	            open(CACHE, $opt_L) || die("Can't open '$opt_L': $!");
                    $/ = undef;
	            my $ret = <CACHE>;
	            return decode_json($ret);
	                             }
        my $res = $self->{ua}->request($req);
        if ($res->is_success) {
                 my $ret = $res->decoded_content;
	 
	my $resultfromapp;

	if ($ret =~ /"result":\{"ok":1,"nModified":([^"]+),"/){ #standard json return format from site if good, else, its failed
		$resultfromapp = $1;
		print "Number of Prospects Approved: $resultfromapp \n" ;
	}else{ print "Sorry I couldn't get a result for total approved, something must have gone badly wrong here!!\n Return from Approve Attempt: $ret";}

	}else{
		print Dumper($res);
		my $x = $res->status_line;
		die "Bad: $x";
	}
}
