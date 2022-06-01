package SimpleLookupService::Client::Bootstrap;

=head1 NAME

SimpleLookupService::Client::Bootstrap - Returns the lookup service to use for the client

=head1 DESCRIPTION

A class for determining the lookup service to use when registering. Looks in a local file
and get this url to use

=cut

use strict;
use warnings;

use Params::Validate qw( :all );
use YAML::Syck;

our $VERSION = 3.3;

use fields 'URL', 'ALL_URLS';


sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init  {
	
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { file => 0} );
    
    
    my $minPriority;
    my $minLatency;
    my $minLocator;
    my $file = $parameters{file};
    if(!$file){
        #set default
        $file = '/opt/SimpleLS/bootstrap/etc/service_url';
    }
    
    $self->{URL} = '';
    my $string = YAML::Syck::LoadFile($file);
    my @hosts = @{$string->{'hosts'}};
    my @locators;
    foreach my $host(@hosts){
    	if(defined $host->{'status'} && $host->{'status'} eq 'alive' ){
    		push @locators, $host->{'locator'};
    		if (!defined $minLatency || ($minLatency == $host->{'latency'} && $minPriority> $host->{'priority'}) || ($minLatency> $host->{'latency'})){
    			$minLatency = $host->{'latency'};
    			$minPriority = $host->{'priority'};
    			$minLocator = $host->{'locator'};
    		}
    	}
    	
    }
    
    $self->{URL} = $minLocator;
    $self->{ALL_URLS} = \@locators;
   
    return 0;
}

sub register_url {
     my ( $self ) = @_;
     
     return $self->{URL};
}

sub query_urls{
	my ($self) = @_;
	
	return $self->{ALL_URLS};
}
