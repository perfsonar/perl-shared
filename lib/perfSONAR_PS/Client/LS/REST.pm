package perfSONAR_PS::Client::LS::REST;

=head1 NAME

perfSONAR_PS::Client::LS::REST - A simple client for interacting with the Lookup Service

=head1 DESCRIPTION

A simple client for interacting with the Lookup Service. Called "REST" as an easy way to 
distinguish between previous version of Lookup Service thatused SOAP/XML as the primary 
protocol where as the new version uses REST/JSON. 

=cut

use strict;
use warnings;

our $VERSION = 3.2;

use JSON qw( encode_json decode_json);
use LWP;
use Log::Log4perl qw( get_logger );
use Params::Validate qw( :all );
use URI;
use DateTime::Format::ISO8601

use perfSONAR_PS::Utils::ParameterValidation;

use fields 'INSTANCE', 'LOGGER', 'TIMEOUT';

my $TIMEOUT = 60; # default timeout

=head2 new($package { timeout => <timeout> })

Constructor for object.  Optional arguments:

=head2 timeout

timeout value to be used in the low level call

=cut
sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { timeout => 0 } );

    my $self = fields::new( $package );
    $self->{LOGGER} = get_logger( "perfSONAR_PS::Client::LS" );
    foreach my $param (qw/timeout/) {
        if ( exists $parameters->{$param} and $parameters->{$param} ) {
             $self->{"\U$param"} = $parameters->{$param};
        }
    }
    $self->{TIMEOUT} ||= $TIMEOUT;
    
    return $self;
}

=head2 setTimeout($self { timeout})

Required argument 'timeout' is timeout value for the call

=cut

sub setTimeout {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { timeout => 1 } );
    $self->{TIMEOUT} = $parameters->{timeout};
    return;
}

=head2 register($self { registration, uri})

Registers a new service record with the Lookup Service. It takes a 
perfSONAR_PS::Client::LS::Requests::Registration (or subclass) as the 
registration parameter and the URL where the registration should be sent as the 'uri' 
parameter
=cut
sub register {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { registration => 1, uri => 1} );
    
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{TIMEOUT});
    $ua->env_proxy();
    
    # Create a request
    my $req = HTTP::Request->new(POST => $parameters->{uri});
    $req->content_type('application/json');
    $req->content(encode_json($parameters->{registration}->getRegHash()));
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        my $jsonResp = decode_json($res->content);
        my $expires_unixtime = $self->_isoToUnix($jsonResp->{'record-expires'});
        return (0, {expires => $jsonResp->{'record-expires'}, expires_unixtime => $expires_unixtime, uri => $jsonResp->{'record-uri'}});
    } else {
        return (-1, { message => $res->status_line });
    }
}

=head2 renew($self { uri, base})

Renews a service already registered with the Lookup Service. The 'uri' parameter is 
required. It identifies the service to renew. If the URI is not an absolute URI then the 
optional parameter 'base' is used as the base of the URI.

=cut
sub renew {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { uri => 1, base => 0 } );
    my $uri = $self->_buildURI({
        uri => $parameters->{uri},
        base => $parameters->{base},   
    });
     
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{TIMEOUT});
    $ua->env_proxy();
    
    # Create a request
    my $req = HTTP::Request->new(POST => $uri);
    $req->content_type('application/json');
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        my $jsonResp = decode_json($res->content);
        my $expires_unixtime = $self->_isoToUnix($jsonResp->{'record-expires'});
        return (0, {expires => $jsonResp->{'record-expires'}, expires_unixtime => $expires_unixtime, uri => $jsonResp->{'record-uri'}});
    } else {
        return (-1, { message => $res->status_line });
    }
}

=head2 unregister($self { uri, base})

Deletes a service already registered with the Lookup Service. The 'uri' parameter is 
required. It identifies the service to remove. If the URI is not an absolute URI then the 
optional parameter 'base' is used as the base of the URI.

=cut
sub unregister {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { uri => 1, base => 0 } );
    my $uri = $self->_buildURI({
        uri => $parameters->{uri},
        base => $parameters->{base},   
    });
     
    my $ua = LWP::UserAgent->new;
    $ua->timeout($self->{TIMEOUT});
    $ua->env_proxy();
    
    # Create a request
    my $req = HTTP::Request->new(DELETE => $uri);
    $req->content_type('application/json');
    
    # Pass request to the user agent and get a response back
    my $res = $ua->request($req);

    # Check the outcome of the response
    if ($res->is_success) {
        my $jsonResp = decode_json($res->content);
        return (0, {uri => $jsonResp->{'record-uri'}});
    } else {
        return (-1, { message => $res->status_line });
    }
}

=head2 _buildURI($self { uri, base})

Private subroutine that build an absolute URI given a relative URI and the base URI to 
which it is relative.

=cut
sub _buildURI {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { uri => 1, base => 0 } );
    
    if($parameters->{uri} =~ /^\// && exists $parameters->{base} && $parameters->{base}){
        my $base_uri = new URI($parameters->{base});
        $base_uri->path($parameters->{uri});
        $parameters->{uri} = $base_uri->as_string;
    }elsif($parameters->{uri}=~ /^\//){
        return (-1, { message => "Relative URI specified with no base" });
    }elsif($parameters->{uri} =~ /^service/){
        #NOTE: TOTAL HACK. DELETE THIS ONCE THE URIS ARE GENERATED IN MORE SENSIBLE MANNER
        my $tmp = $parameters->{uri};
        $parameters->{base} =~ s/services\/*$//g;
        $parameters->{uri} = $parameters->{base} . $parameters->{uri};
    }
    
    return  $parameters->{uri};
}


=head2 _isoToUnix($self { uri, base})

Converts a given ISO 8601 date string to a unix timestamp

=cut
sub _isoToUnix {
    my ($self, $str) = @_;
    my $dt = DateTime::Format::ISO8601->parse_datetime($str);
    return $dt->epoch();
}