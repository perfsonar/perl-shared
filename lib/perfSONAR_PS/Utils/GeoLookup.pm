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

our @EXPORT_OK = qw(
    geoIPLookup
    geoIPVersion
);

=head2 geoIPLookup($ip)
 
 Get location information from an IP address
 
=cut

sub geoIPLookup {
    my ( $ip ) = @_;
    my $result = ();

    if ($ip) {
        my $record;
        if ( is_ipv4($ip) ) {
            my $city_file = _get_ipv4_city_db();
            return $result if ( ! -f $city_file );
            my $city_db = Geo::IP->open( $city_file, GEOIP_MEMORY_CACHE);

            $record = $city_db->record_by_addr( $ip );
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
        }
        elsif ( is_ipv6($ip) ) {
            # The City database seems to have only country info and the lat and long are for the center of it !?
            # so just use the Country db for ipv6
            my $country_ipv6_file =  '/usr/share/GeoIP/GeoIPv6.dat';
            if ( ! -f $country_ipv6_file ) {
                $country_ipv6_file =  '/usr/share/GeoIP/GeoIPv6-initial.dat';
                return $result if ( ! -f $country_ipv6_file );
            }
            my $country_ipv6_db = Geo::IP->open( $country_ipv6_file, GEOIP_MEMORY_CACHE);

            $record = $country_ipv6_db->country_code_by_addr_v6( $ip );
            $result->{'country'} = $record if ($record);
            $record = $country_ipv6_db->country_name_by_addr_v6( $ip );
            $result->{'country_full'} = $record if ($record);
        }
        else {
            warn "IP '".$ip."' was not detected as ipv4 or ipv6.";
        }

    }
    return $result;
}

sub geoIPVersion {
    my $city_file = _get_ipv4_city_db();
    my $gi = Geo::IP->open( $city_file, GEOIP_MEMORY_CACHE);
    my $info = $gi->database_info;
    my $libversion = $gi->lib_version;

    return { 'db' => $info,
             'lib' => $libversion };
}

sub _get_ipv4_city_db { 
    my $city_file = '/usr/share/GeoIP/GeoIPCity.dat';
    if ( !-f $city_file ) {
        $city_file = '/usr/share/GeoIP/GeoIPCity-initial.dat';
    }
    return $city_file;

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
 
 Copyright (c) 2008-2017, Internet2
 
 All rights reserved.
 
 =cut

# vim: expandtab shiftwidth=4 tabstop=4
