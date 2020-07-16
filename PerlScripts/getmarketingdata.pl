#!/usr/bin/perl

use strict;
use Data::Dumper;
use HTTP::Cookies;
use HTML::Form;
use JSON::XS;
use Text::CSV::Encoded;
use Text::CSV_XS;

my $ocsv = Text::CSV::Encoded->new({
		encoding_in=>'utf-8',
		encoding_out=>'utf-8',
		binary=>1});




my$bw = George::BW->new(
		user=>'my username',
		pwd=>'my password',
		host=>'https://somecompaniessite.com'
		);

open (DATA,">tmp.datafromsite") || die 'cant open the tmp.datafromsite file';
$ocsv->print(\*DATA, ['data_id','firstname','id','email','name','company','industry_name','role','addr']);
print DATA "\n";


my $x = $bw->get("https://somecompaniessite.com/login");
open(TMP, ">tmp.gw");
#print TMP $x;
close(TMP);
$bw->login("tmp.gw");

# I'm getting my_id from this request, then extracting into a hash for later ref
 my $x = $bw->get("https://somecompaniessite.com/session_info.json");
 open(TMP, ">tmp.gw3");
 print TMP $x;
 close(TMP);

 open(TMP, "tmp.gw3");
 $/ = undef;
 my $json = <TMP>;
 my $hash = decode_json($json);

 my $my_id = $hash->{user}->{id};

 print "-->$my_id<--\n";

  
 
my $data_id=1; #loop counter for getting index in data I push to site

#loop to go through each page, get the different details and store
for(my $page = 1;;$page++) {
	
	my $url = sprintf 'https://somecompaniessite.com/users/$my_id/users?page=%d&per_page=40&query[exclude_current_user]=true', $page; 

	my $json = $bw->get($url);
	open(TMP, ">tmp.gw4");
	print TMP $json;
	my $hash = decode_json($json);
	
	my $cnt = scalar(@{$hash->{users}});
	last if (!$cnt);

	foreach(@{$hash->{users}}) {
		my $uid = $_->{id};
		my $x = $bw->get("https://somecompaniessite.com/users/$uid");

		open(TMP,">tmp.gw7");
		print TMP $x;
		close(TMP);
		my $csrf;
		if ($x =~ /csrf-token" content="([^"]+)"/) {
			$csrf = $1;
		} else {
			print "can't find csrf for $_->{firstname}, $_->{lastname}\n";
			exit;
		}
		$x = $bw->get("https://somecompaniessite.com/users/$my_id/users/$uid?full_profile=true", { 
				'X-CSRF-Token'=>$csrf,
				'Referer'=>"https://somecompaniessite.com/users/$uid",
				'X-Requested-With'=>"XMLHttpRequest",
			});

		my $hash = decode_json($x);

		 my $range = 5;
         	 my $random_number = (int(rand($range))+1);
	       	sleep($random_number);
		
		     

		my %attrs = map( {$_->{customizable_attribute_id} => $_->{attr_value}}  @{$hash->{user}->{dynamic_attributes}});
		my $role = $attrs{5330}; #as this is what confusing id number is used as the key in the attrs json segment of data
		my $email = $hash->{user}->{email};
		my $name = $hash->{user}->{name}; 
		my $addr = $hash->{user}->{locations}->[0]->{address};
		my $company = $attrs{3899};#as this is what confusing id number is used as the key in the attrs json segment of data

		if (!defined($_->{industry_name})){
			$_->{industry_name} = "null";}
		if (!defined($hash->{user}->{email})){
			$hash->{user}->{email} = "not public";}
		$ocsv->print(\*DATA,[$data_id, $_->{firstname}, $_->{id}, $email,  $name, $company, $_->{industry_name}, $role, $addr]); 
		print DATA "\n";
                
		$data_id++;
		
	}
	print "--->$page<---\n";
}
print "!-->End<--!\n";
exit(0);

package George::BW;
use Data::Dumper;
use LWP;
use LWP::UserAgent::Determined; #this great lib wont give up after the first time it sees an error from request, instead will try again a few times;
sub login {
	my $self = shift;
	my $fname = shift;

	open(F,$fname) || die("can't open $fname: $!");
	my $rs = $/;
	$/ = undef;
	my $content =  <F>;
	close(F);
        #get forms into array
	my @forms = HTML::Form->parse($content, "https://somecompaniessite.com/login");
	my $cnt = scalar(@forms);
	print "I spy $cnt forms\n";
	if ($cnt == 0) {
		#no need to log in, we must have a cookie
		return;
	}
        #now enter details into collected forms 
	foreach my $form(@forms) {
		my @names = $form->param;
		$form->value('user[email]', $self->{args}->{user});
		$form->value('user[password]', $self->{args}->{pwd});
		foreach my $name (@names) {
			my $val = $form->value($name);
		}
		my $req = $form->make_request;
			my $x = $bw->do($req);
			open(TMP, ">tmp.gw2");
		
	}
}
#create lwp agent for submitting requests 
sub new {
	my ($class, %args) = @_;
	my $self = {};
	bless $self;

	$self->{args} = \%args;

	$self->{base_url} = $args{host} . '';

	my $cookie_db = $self->{BASE}.'/tmp/wp.cookies';
	$self->{cookie_jar} = HTTP::Cookies->new(
		file => $cookie_db,
		autosave => 1
		#, hide_cookie2=>1
		, ignore_discard=>1
	);

my $ua = LWP::UserAgent::Determined->new(keep_alive => 1,  ssl_opts => { verify_hostname => 0 },);
$ua->timeout(120);
$ua->timing("10,30,90,300");
my $http_codes_hr = $ua->codes_to_determinate();
$http_codes_hr->{500} = 1;
$http_codes_hr->{502} = 1;

my $range = 6;
my $random_number = (int(rand($range))+1);
#sleep($random_number);
$ua->agent('Mozilla/5.0');
$ua->requests_redirectable(['GET', 'HEAD', 'POST', 'PUT', 'DELETE']);

	$ua->cookie_jar( $self->{cookie_jar} );#saves logging in each time      

  $self->{ua}=$ua;

  	return $self;
}
#just does gets 
sub get {
	my $self = shift;
	my $url = shift;
	my $hdrs = shift;
        #my $range = 6;
        #my $random_number = (int(rand($range))+1);
        #sleep($random_number); -put back if it gets too gready 

	my $req = HTTP::Request->new( GET => $url);

		if ($hdrs) { 
			foreach(keys %$hdrs) {

				$req->header($_=>$hdrs->{$_});
			}
		}
	my $res = $self->{ua}->request($req);

	if ($res->is_success){
		return $res->content;
	}else{
		my $x = $res->status_line;
		die "bad: $x";
	}
}
#submits my requests
sub do {
    my $self = shift;
    my $req = shift;

    #my $range = 6;
    #my $random_number = (int(rand($range))+1);
    # sleep($random_number); -put back if it gets too greedy

    my $res = $self->{ua}->request($req);

    if ($res->is_success) {
		        return $res->content;
		    } else {
	            my $x = $res->status_line;
	            die "Bad: $x";
	        }
 }
								
							







								
