package perfSONAR_PS::Utils::GeoLookup;

use strict;
use warnings;

our $VERSION = 3.4;

=head1 NAME
 
 perfSONAR_PS::Utils::GeoLookup
 
=head1 DESCRIPTION
 
 A module that provides utility methods to resolve location information
 =head1 API
 
=cut

use Geo::IP;
use Data::Validate::IP;
 use Socket;     #this doesn't help
 use Socket6;
use Net::IP; # doesn't help
use base 'Exporter';
use Data::Dumper;
use JSON::XS;
require LWP::UserAgent;

our @EXPORT_OK = qw(
    geoLookup
    geoIPLookup
    geoWhoisLookup
    geoReverseLookup
);

my $REQUEST_TIMEOUT = 5;
my $REQUEST_FORMAT = "json";
my $GEOCODE_URL = "https://maps.googleapis.com/maps/api/geocode/${REQUEST_FORMAT}";

my $ua = LWP::UserAgent->new;
$ua->timeout($REQUEST_TIMEOUT);
$ua->env_proxy;

=head2 geoLookup($location)
 
 Get location information from existing address information
 
=cut

sub geoLookup {
    my ( $location ) = @_;
    
    my $result = ();
    my $address = "";
    if ($location->{"sitename"}) {
        $address .= $location->{"sitename"} . ", ";
    }
    if ($location->{"city"}) {
        $address .= $location->{"city"} . ", ";
    }
    if ($location->{"state"}) {
        $address .= $location->{"state"};
        if ($location->{"code"}) {
            $address .= " " . $location->{"code"};
        }
        $address .= ", ";
    }
    elsif ($location->{"code"}) {
        $address .= $location->{"code"} . ", ";
    }
    if ($location->{"country"}) {
        $address .= $location->{"country"};
    }
    if ($address) {
        my $request = "${GEOCODE_URL}?address=${address}";
        my $response = $ua->get($request);
        if ($response->is_success) {
            eval {
                my $json = decode_json($response->decoded_content);
                if ($json->{"status"} eq "OK") {
                    $result = parseGeocodeResult($json->{"results"}[0]);
                }
            };
        }
    }
    return $result;
}

=head2 geoIPLookup($ip)
 
 Get location information from an IP address
 
=cut

sub geoIPLookup {
    my ( $ip ) = @_;
    my $result = ();

    if ($ip) {
        my $record;
        if ( is_ipv4($ip) ) {
            my $geoip_city_file =  '/usr/share/GeoIP/GeoIPCity.dat';
            my $geoip_city = Geo::IP->open( $geoip_city_file, GEOIP_MEMORY_CACHE);

            $record = $geoip_city->record_by_addr( $ip );

        }
        elsif ( is_ipv6($ip) ) {
            # (requires perl-Geo-IP 1.45-1.e16)
            my $geoip_city_ipv6_file =  '/usr/share/GeoIP/GeoIPCityv6.dat';
            my $geoip_city_ipv6 = Geo::IP->open( $geoip_city_ipv6_file, GEOIP_MEMORY_CACHE);

            $record = $geoip_city_ipv6->record_by_addr_v6( $ip );
        }
        else {
            warn "IP '".$ip."' was not detected as ipv4 or ipv6.";
        }
    
        if ( $record ) {
            $result->{'city'} = $record->city            if ($record->city);
            $result->{'state'} = $record->region_name    if ($record->region_name);
            $result->{'state_abbr'} = $record->region    if ($record->region);  
            $result->{'country'} = $record->country_code if ($record->country_code);
            $result->{'country_full'} = $record->country_name if ($record->country_name);
            $result->{'code'} = $record->postal_code     if ($record->postal_code);                
            $result->{'time_zone'} = $record->time_zone  if ($record->time_zone);
            $result->{'latitude'} = $record->latitude    if ($record->latitude);
            $result->{'longitude'} = $record->longitude  if ($record->longitude);
        }
        #warn "IP: ".$ip; ###
        #warn "result " . Dumper $result;  ###
    }
    return $result;
}

=head2 geoWhoisLookup($address)
 
 Get location information from a whois lookup
 
=cut

sub geoWhoisLookup {
    my ( $address ) = @_;
    
    my $result = ();
    return $result
}

=head2 geoReverseLookup($lat, $long)
 
 Get location information from a latitude and longitude
 
=cut

sub geoReverseLookup {
    my ( $lat, $lng ) = @_;
    
    my $result = ();
    if ($lat && $lng) {
        my $request = "${GEOCODE_URL}?latlng=${lat},${lng}";
        my $response = $ua->get($request);
        if ($response->is_success) {
            eval {
                my $json = decode_json($response->decoded_content);
                if ($json->{"status"} eq "OK") {
                    $result = parseGeocodeResult($json->{"results"}[0]);
                }
            };
        }
    }
    return $result;
}

=head2 parseGeocodeResult($result)
 
 Parses a result from the Google geocoding API
 
=cut

sub parseGeocodeResult {
    my ( $result ) = @_;
    
    my $location = ();
    foreach my $component (@{$result->{"address_components"}}) {
        foreach my $type (@{$component->{"types"}}) {
            if ($type eq "establishment") {
                $location->{"sitename"} = $component->{"long_name"};
            }
            if ($type eq "locality") {
                $location->{"city"} = $component->{"long_name"};
            }
            if ($type eq "administrative_area_level_1") {
                $location->{"state"} = $component->{"long_name"};
            }
            if ($type eq "country") {
                $location->{"country"} = $component->{"short_name"};
            }
            if ($type eq "postal_code") {
                $location->{"code"} = $component->{"short_name"};
            }
        }
    }
    $location->{"latitude"} = $result->{"geometry"}->{"location"}->{"lat"};
    $location->{"longitude"} = $result->{"geometry"}->{"location"}->{"lng"};
    return $location;
}

1;

__END__

=head1 SEE ALSO
 
 To join the 'perfSONAR Users' mailing list, please visit:
 
 https://mail.internet2.edu/wws/info/perfsonar-user
 
 The perfSONAR-PS git repository is located at:
 
 https://code.google.com/p/perfsonar-ps/
 
 Questions and comments can be directed to the author, or the mailing list.
 Bugs, feature requests, and improvements can be directed here:
 
 http://code.google.com/p/perfsonar-ps/issues/list
 
 =head1 VERSION
 
 $Id: GeoLookup.pm 5533 2013-02-10 06:28:27Z asides $
 
 =head1 AUTHOR
 
 Andrew Sides, asides@es.net
 
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
