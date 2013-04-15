package SimpleLookupService::Client::SimpleLS;

=head1 NAME

SimpleLookupService::Client::SimpleLS - A simple client for interacting with the Lookup Service

=head1 DESCRIPTION

A simple client for interacting with the Lookup Service. This has a basic connect() methods that establishes a
http connection to the specified URI. The type of httpconnection(GET,POST,DELETE,PUT), timeout and data to be passed are the fields that can be
set.

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use JSON qw( encode_json decode_json);
use LWP;
use Params::Validate qw( :all );
use URI;
use DateTime::Format::ISO8601;

use Net::Ping;
use Time::HiRes;



use fields 'INSTANCE', 'LOGGER', 'TIMEOUT', 'CONNECTIONTYPE', 'DATA', 'HOST','PORT','URL', 'ERRORMESSAGE', 'STATUS', 'LATENCY';

my $DEFAULTTIMEOUT = 300;
my $TIMEOUT = 60; # default timeout

my $CONNECTIONTYPE = 'GET'; #default connection type

my $DATA; #default empty data


=head2 new($package { timeout => <timeout> })

Constructor for object.  Optional arguments:

=head2 timeout

timeout value to be used in the low level call

connectionType: type of connection


=cut
sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}


#initializes a SimpleLS client class
sub init{
	my ($self, @args) = @_;
	 my %parameters = validate( @args, { host=>1, port=>1, timeout => 0, connectionType => 0, data => 0 } );
	  my @names = qw(host port timeout connectionType data);
    foreach my $param (@names) {
        if ( exists $parameters{$param} and $parameters{$param} ) {
             $self->{"\U$param"} = $parameters{$param};
        }
    }
    
    $self->{URL} = "http://".$self->{HOST}.":".$self->{PORT}."/";
    
    $self->{TIMEOUT} ||= $TIMEOUT;
    
    $self->{CONNECTIONTYPE} ||= $CONNECTIONTYPE;
    
    $self->{DATA} ||= $DATA;
    
    $self->{STATUS} = 'unknown';
    
    return 0;
    
}

=head2 setTimeout($self { timeout})

Required argument 'timeout' is timeout value for the call

=cut

sub setTimeout {
    my ( $self, $timeout ) = @_;
    
    if(defined $timeout && $timeout <= $DEFAULTTIMEOUT){
    	$self->{TIMEOUT} = $timeout;
    	return 0;
    }else{
    	return -1;
    }
   
}

sub getTimeout {
    my $self  = shift;
    return $self->{TIMEOUT};
}

sub setConnectionType {
    my ( $self, $connection ) = @_;
    
    if(defined $connection && $self->_isValidConnection($connection)){
    	$self->{CONNECTIONTYPE} = $connection;
    	return 0;
    }else{
    	return -1;
    }
    
    
}

sub getConnectionType {
    my $self  = shift;
    return $self->{CONNECTIONTYPE};
}

sub setData {
    my ( $self, $data ) = @_;
    if(defined $data){
    	$self->{DATA} = $data;
    	return 0;
    }else{
    	return -1;
    }
    
}

sub getData {
    my $self  = shift;
    return $self->{DATA};
}

sub getUrl {
    my $self  = shift;
    return $self->{URL};
}

sub setUrl {
    my ( $self, $url ) = @_;
    if(defined $url){
    	$self->{URL} = $url;
    	my $uri = URI->new($url);
    	$self->{HOST} = $uri->host;
    	$self->{PORT} = $uri->port;
    	return 0;
    }else{
    	return -1;
    }
}

sub setHost {
    my ( $self, $host ) = @_;
    if(defined $host){
    	$self->{HOST} = $host;
    	return 0;
    }else{
    	return -1;
    }
    
}

sub getHost {
    my $self  = shift;
    return $self->{HOST};
}


sub setPort {
    my ( $self, $port ) = @_;
    if(defined $port){
    	$self->{PORT} = $port;
    	return 0;
    }else{
    	return -1;
    }
    
}

sub getPort {
    my $self  = shift;
    return $self->{PORT};
}



#establishes a logical connection and checks if host is alive by pinging the host
#Status and Latency results are recorded
sub connect{
	my $self = shift;
	my $p = Net::Ping->new();
    $p->hires();
    $p->port_number($self->{PORT});
    
    my ($ret, $duration, $ip) = $p->ping($self->{HOST}, 5.5);
    
    if(defined $ret && $ret){
    	$self->{STATUS} = 'alive'; 
    	$self->{LATENCY} =  sprintf "%.2fms", (1000 * $duration);
    }elsif(!defined $ret){
    	$self->{STATUS} = 'unknown';
    }else{
    	$self->{STATUS} = 'unreachable';
    }
    
    $p->close();
    
    return 0;
}

#tears down the logical connection
sub disconnect{
	my $self= shift;
	$self->{STATUS} = 'unknown';
	$self->{LATENCY} = undef;
	
	return 0;
}


#getStatus - returns the status if host is alive or not

sub getStatus{
	my $self = shift;
	
	return $self->{STATUS};
}

#getLatency - returns the RTT in milliseconds

sub getLatency{
	my $self = shift;
	
	return $self->{LATENCY};
	
}

# establishes a HTTP connection and sends the message
sub send{
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { resourceLocator => 0} );
    
    my $url = $self->{URL};
    if(defined $parameters{resourceLocator}){
    	$url = "http://".$self->{HOST}.":".$self->{PORT}."/".$parameters{resourceLocator};
    }
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{TIMEOUT});
    $ua->env_proxy();
  
    # Create a request
    my $req = HTTP::Request->new($self->{CONNECTIONTYPE} => $url);
    $req->content_type('application/json');
    $req->content($self->{DATA});
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
    
    # Return response
    return $res;
}

=head2 _isoToUnix($self { uri, base})

Converts a given ISO 8601 date string to a unix timestamp

=cut
sub _isoToUnix {
    my ($self, $str) = @_;
    my $dt = DateTime::Format::ISO8601->parse_datetime($str);
    return $dt->epoch();
}

sub _isValidConnection{
	my ($self, $connection) = @_;
	if($connection eq 'POST' || $connection eq 'GET' || $connection eq 'DELETE' || $connection eq 'PUT'){
		return 1;
	}else{
		return 0;
	}
}

1;
