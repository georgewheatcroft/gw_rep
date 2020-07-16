#!/usr/bin/perl 
use strict;
use Data::Dumper;
use HTTP::Cookies;
use HTML::Form;
use JSON::XS;
use Text::CSV::Encoded;
use Text::CSV_XS;
use Storable qw (freeze);
use MIME::Base64;

my $bw = ProjectManagementSite::GW->new(
		user=>'george.w',
		pwd=>'not my password',
		host=>'project-management-site',
		);
#ntml auth
my $x = $bw->get("http://project-management-site/account/frmLogin.aspx");
open(TMP, ">tmp.gw");
print TMP $x;
close(TMP);

#login page
$bw->login("tmp.gw");

#get projects page 
 my $x = $bw->get("http://project-management-site/project/frmOurProjects.aspx");
 open(TMP, ">tmp.gw3");
 print TMP $x;
 close(TMP);

#get iso task breakdown data
$bw->getisodata("tmp.gw3");
 open(ISO, "tmp.gw4");
$/ = undef;
 my $json = <ISO>;
close (ISO);  

#ISO data operation - if can't decode, we must have returned something incorrect
my $hash;
eval  { $hash = decode_json($json) };  
	if ($@){	
	open (LOG, ">tmp.json_error");
		print LOG $json;
		close(LOG);
		die "json is borked";
		}
my %moan_hash;
foreach (@{$hash->{data}}) {
	
	if (!$_->{ActualFinishDate} ){
	my $progress = $_->{InPeriodTrafficLightTooltip};
#	print $progress;
	if ($progress =~ /overdue/){
                #told not to include these - if task is late people should be encouraged to review everything properly again  rather than a specific task
                #	my $id = $_->{TaskID};
                #my $desc = $_->{ShortDesc};
                #	my $shouldhavebeendonebynow = $_->{TargetDate};
	my $late_task_owner= $_->{FullName};	
		     
	$moan_hash{$desc} = $late_task_owner; 
		
			
	                	}
                        }
        }
#serialise hash, send off to a cloud server where a cgi script picks it up and emails the relevant person 
my $frozen = encode_base64 freeze(\%moan_hash);
my $site = "http://somecloudserverIdon'twishtodeclare/some/url/path/notificationbyemail.cgi";
my $headers = ['Content-Type'=>'json'];
my $last_request = HTTP::Request->new(POST=>$site,$headers,$frozen);	

	my $final_response = $bw->do($last_request);							
	print $final_response;

print "\n!-->End<--!\n";
exit(0);

package ProjectManagementSite::GW;
use Data::Dumper;
use LWP;
use LWP::UserAgent::Determined;
use HTTP::Request::Common;
use Authen::NTLM;
use URL::Encode;
use JSON::XS; # qw(encode_json);
ntlmv2(1);
use Encode qw(encode_utf8);
use WWW::Form::UrlEncoded qw/parse_urlencoded build_urlencoded/;
sub login {
	my $self = shift;
	my $fname = shift;

	open(F,$fname) || die("can't open $fname: $!");
	my $rs = $/;
	$/ = undef;
	my $content =  <F>;
	close(F);

	my @forms = HTML::Form->parse($content, "http://project-management-site/account/frmLogin.aspx");
	my $cnt = scalar(@forms);
	print "I spy $cnt forms\n";
	if ($cnt == 0) {
		#no need to log in, we must have a cookie
		return;
	}
	foreach my $form(@forms) {
		my @names = $form->param;
		$form->value('loginProjectManagementSite$UserName', $self->{args}->{user});
		$form->value('loginProjectManagementSite$Password', $self->{args}->{pwd});
		foreach my $name (@names) {
			my $val = $form->value($name);
		}
		my $req = $form->make_request;
				print Dumper ($req);
			my $x = $bw->do($req);
			open(TMP, ">tmp.gw2");
				print TMP $x;
		
	}
}
#data we were after from project site
sub getisodata {
	my $self = shift;
	my $fname = shift;

		my $url = "http://project-management-site/api/grid/";
		my $header = ['Content-Type' => 'application/x-www-form-urlencoded; charset=UTF-8']; 
		my $encoded_data = "GridCode=ProjectBreakDown&ProjectManagementSite%5B0%5D%5B%5D=ProjectID&ProjectManagementSite%5B0%5D%5B%5D=1421&ProjectManagementSite%5B1%5D%5B%5D=ReportingDate&ProjectManagementSite%5B1%5D%5B%5D=12+February+2020&ProjectManagementSite%5B2%5D%5B%5D=ReportingFromDate&ProjectManagementSite%5B2%5D%5B%5D=01+April+2019&ProjectManagementSite%5B3%5D%5B%5D=IncludeFuture&ProjectManagementSite%5B3%5D%5B%5D=true&ProjectManagementSite%5B4%5D%5B%5D=IncludeCompleted&ProjectManagementSite%5B4%5D%5B%5D=true";#hard coded as we were only interested in looking at tasks in one project - so hence only needed one request. screen scrape & request scripts have too short a lifespan to work out dynamic approach when working to time constraint and not essential
	print $encoded_data."\n\n\n\n";
		print Dumper($encoded_data);
	
my $request =	HTTP::Request->new('POST', $url, $header, $encoded_data);
		my $x = $bw->do($request);
			open(ISO, ">tmp.gw4");
				print ISO $x;
}

#make object for lwp useragent 
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
$http_codes_hr->{500} = 1; #if get error 500/502 from request, don't die, try waiting as per timing above
$http_codes_hr->{502} = 1;

$ua->agent('Mozilla/5.0');
$ua->requests_redirectable(['GET', 'HEAD', 'POST', 'PUT', 'DELETE']);
$ua->credentials('somelocalareanetworkentity:6050', '', 'george.w', 'not my password'); #other credentials set here in case I needed to ntlm auth by different method. used kerberos in the end
	$ua->cookie_jar( $self->{cookie_jar} );

#Get useragent to achieve ntlm authentification here, else fail and die   - MUST USE AS george.w
my $authen = $ua->get('http://project-management-site/account/frmLogin.aspx');
if ($authen->is_success) {
   print "authentication was achieved";;  # or whatever
}
else {
        print $authen->headers->as_string();;
    die $authen->status_line;

}

  $self->{ua}=$ua;
	

  	return $self;
}
#get requests   
sub get {
	my $self = shift;
	my $url = shift;
	my $hdrs = shift;
	my $req = HTTP::Request->new( GET => $url);

		if ($hdrs) { 
			foreach(keys %$hdrs) {

				$req->header($_=>$hdrs->{$_});
			}
		}
	my $res = $self->{ua}->request($req);
	#print Dumper($res);
	
	if ($res->is_success){
		return $res->content;
	}else{
				print Dumper($res);
		my $x = $res->status_line;
		die "bad: $x";
	}
}

#other requests 
sub do {
    my $self = shift;
    my $req = shift;

	print Dumper($req);
    my $res = $self->{ua}->request($req);

    if ($res->is_success) {
		        return $res->content;
		    } else {
			    #  print Dumper($res);
	            my $x = $res->status_line;
	            die "Bad: $x";
	        }
									}
