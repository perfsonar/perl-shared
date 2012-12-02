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

our $VERSION = 3.2;

use JSON qw( encode_json decode_json);
use LWP;
use Params::Validate qw( :all );
use URI;
use DateTime::Format::ISO8601;


use fields 'INSTANCE', 'LOGGER', 'TIMEOUT', 'CONNECTIONTYPE', 'DATA', 'URL';

my $TIMEOUT = 60; # default timeout

my $CONNECTIONTYPE = 'GET'; #default connection type

my $DATA; #default empty data

=head2 new($package { timeout => <timeout> })

Constructor for object.  Optional arguments:

=head2 timeout

timeout value to be used in the low level call

connectionType: type of connectio


=cut
sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init{
	my ($self, @args) = @_;
	 my %parameters = validate( @args, { url=>1, timeout => 0, connectionType => 0, data => 0 } );
	  my @names = qw(url timeout connectionType data);
    foreach my $param (@names) {
        if ( exists $parameters{$param} and $parameters{$param} ) {
             $self->{"\U$param"} = $parameters{$param};
        }
    }
    $self->{TIMEOUT} ||= $TIMEOUT;
    
    $self->{CONNECTIONTYPE} ||= $CONNECTIONTYPE;
    
    $self->{DATA} ||= $DATA;
    
}

=head2 setTimeout($self { timeout})

Required argument 'timeout' is timeout value for the call

=cut

sub setTimeout {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { timeout => 1 } );
    $self->{TIMEOUT} = $parameters{timeout};
    return;
}

sub getTimeout {
    my ( $self, @args ) = @_;
    return $self->{TIMEOUT};
}

sub setConnectionType {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { connectionType => 1 } );
    $self->{CONNECTIONTYPE} = $parameters{connectionType};
    return;
}

sub getConnectionType {
    my ( $self, @args ) = @_;
    return $self->{CONNECTIONTYPE};
}

sub setData {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { data => 1 } );
    $self->{DATA} = $parameters{data};
    return;
}

sub getData {
    my ( $self, @args ) = @_;
    return $self->{DATA};
}

sub setUrl {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { url => 1 } );
    $self->{URL} = $parameters{url};
    return;
}

sub getUrl {
    my ( $self, @args ) = @_;
    return $self->{URL};
}



sub connect{
    my ( $self, @args ) = @_;
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{TIMEOUT});
    $ua->env_proxy();
  
    # Create a request
    my $req = HTTP::Request->new($self->{CONNECTIONTYPE} => $self->{URL});
    $req->content_type('application/json');
    $req->content($self->{DATA});
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);
    
    # Check the outcome of the response
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

1;
