package perfSONAR_PS::Utils::LookupService;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::Utils::LookupService

=head1 DESCRIPTION

A module that provides utility methods for discover Lookup Service servers.
This module IS NOT an object, and the methods can be invoked directly. The
methods need to be explicitly imported to use them.

=head1 API

=cut

use base 'Exporter';

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use SimpleLookupService::Client::SimpleLS;
use perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject;
use SimpleLookupService::Client::Query;
use URI;
use Data::UUID;

our @EXPORT_OK = qw( discover_lookup_services discover_primary_lookup_service is_host_registered get_client_uuid set_client_uuid);

my $logger = get_logger(__PACKAGE__);

sub discover_primary_lookup_service {
    my $parameters = validate( @_, { locator_urls => 0 } );
    my $locator_urls = $parameters->{locator_urls};

    my $lookup_services = discover_lookup_services(locator_urls => $locator_urls);

    my ($primary_ls, $primary_ls_latency, $primary_ls_priority);

    foreach my $ls_info (@$lookup_services) {
        if (not $primary_ls or
              ($primary_ls_latency > $ls_info->{latency}) or
              ($primary_ls_latency == $ls_info->{latency} and $primary_ls_priority > $ls_info->{priority})) {
            $primary_ls = $ls_info->{locator};
            $primary_ls_latency = $ls_info->{latency};
            $primary_ls_priority = $ls_info->{priority};
        }
    }

    return $primary_ls;
}

sub discover_lookup_services {
    my $parameters = validate( @_, { locator_urls => 0 } );
    my $locator_urls = $parameters->{locator_urls};

    $locator_urls = [ "http://ps1.es.net:8096/lookup/activehosts.json" ] unless ($locator_urls);

    my @active_hosts = ();

    foreach my $url (@$locator_urls) {
        my $ua = new LWP::UserAgent();
        $ua->agent("SimpleLSBootStrap-v1.0");

        my $http_request = HTTP::Request->new( GET => $url );
        my $http_response = $ua->request($http_request);
        if (!$http_response->is_success) {
            $logger->error("Problem retrieving $url: " . $http_response->status_line);
            next;
        }

        #Convert to JSON
        my $activehostlist;
        eval {
            my $json = JSON->new()->relaxed();
            $activehostlist = $json->decode($http_response->content);
        };
        if ($@) {
            $logger->error("Problem decoding JSON from $url: " . $@);
            next;
        }

        #Determine URL
        foreach my $activehost (@{ $activehostlist->{hosts} }) {
        	my $url = URI->new($activehost->{locator});

        	unless ($url->host() and $url->port()) {
        	    $logger->error("Invalid URL: $url");
        	    next;
        	}

            if($activehost->{status} and $activehost->{status} eq "alive") {
            	my $ls = SimpleLookupService::Client::SimpleLS->new();
            	my $ret = $ls->init({host=>$url->host(), port=>$url->port()});
            	if($ret==0){
            		$ls->connect();
            		my $latency = $ls->getLatency();
                        next unless(defined $latency);
            		$latency =~ s/ms$//; #strip units
            		$activehost->{latency} = $latency;
                	push @active_hosts, $activehost;
            	}
            }
        }
    }

    return \@active_hosts;
}

sub is_host_registered{
    my ($address) = @_;
     
    my $ls_url = discover_primary_lookup_service();

    if (! $ls_url){
	$logger->error("Unable to determine ls_url");
	return;
    }

    my $server = SimpleLookupService::Client::SimpleLS->new();
    my $uri = URI->new($ls_url); 
    my $ls_port =$uri->port();
    if(!$ls_port &&  $uri->scheme() eq 'https'){
        $ls_port = 443;
    }elsif(!$ls_port){
        $ls_port = 80;
    }
    $server->init( host=> $uri->host(), port=> $ls_port );
    
    my $query = new perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject();
    $query->init();
    $query->setHostName($address);
    my $client = new SimpleLookupService::Client::Query();
    $client->init(server => $server, query => $query);
    my ($status, $host) = $client->query();
    if($status == 0 && @{$host} >= 1){
        return 1;
    }
    
    return 0;
}

=head2 get_client_uuid ({})
    Returns the UUID to use in the client-uuid field from a file
=cut

sub get_client_uuid {
    my ( @params ) = @_;
    my $parameters = validate( @params, {file => 1} );
    my $uuid_file = $parameters->{file};
    
    my $uuid;

    if ( open( FIN, "<", $uuid_file ) ) {
        while($uuid = <FIN>){
            if ( $uuid ){
                 chomp( $uuid );
                 last;
            }
        }
        close( FIN );
    }

    return $uuid;
}

=head2 set_client_uuid ({})
    Generates a UUID and stores in a file
=cut

sub set_client_uuid {
    my ( @params ) = @_;
    my $parameters = validate( @params, {file => 1} );
    my $uuid_file = $parameters->{file};
    my $ug   = new Data::UUID;
    my $uuid = $ug->create_str();

    open( FOUT, ">", $uuid_file ) or die "unable to open $uuid_file: $@";
    print FOUT "$uuid";
    close( FOUT );
    
    return $uuid;
}

1;

__END__

=head1 SEE ALSO

L<Net::DNS>, L<NetAddr::IP>, L<Regexp::Common>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 COPYRIGHT

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
