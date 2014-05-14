package perfSONAR_PS::RegularTesting::Parsers::Traceroute;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Iperf;

=head1 DESCRIPTION

A module that provides simple functions for parsing traceroute output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Net::Traceroute;
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( parse_traceroute_output );

my $logger = get_logger(__PACKAGE__);

=head2 parse_traceroute_output()

=cut

sub parse_traceroute_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};

    my ($source_addr, $destination_addr);
    my ($packet_size);
    my %traceroutes = ();

    my @traceroutes = ();

    my $error;

    my $traceroute = Net::Traceroute->new();
    eval {
        $traceroute->_parse($stdout);

        for(my $hop_i = 1; $hop_i <= $traceroute->hops; $hop_i++){
            for(my $query_i = 1; $query_i <= $traceroute->hop_queries($hop_i); $query_i++){
                my $query_status = $traceroute->hop_query_stat($hop_i, $query_i);

                my $hop_stats = {
                    ttl => $hop_i,
                    queryNum => $query_i,
                };

                if($query_status == $traceroute->TRACEROUTE_OK()){
                    $hop_stats->{'hop'} = $traceroute->hop_query_host($hop_i, $query_i);
                    $hop_stats->{'delay'} = $traceroute->hop_query_time($hop_i, $query_i);
                }else{
                    my $error;
                    if($query_status == $traceroute->TRACEROUTE_TIMEOUT()){
                        $error = "requestTimedOut"; 
                    }elsif($query_status == $traceroute->TRACEROUTE_UNREACH_NET()){
                        $error = "noRouteToTarget"; 
                    }elsif($query_status == $traceroute->TRACEROUTE_UNREACH_HOST()){
                        $error = "unknownDestinationAddress"; 
                    }elsif($query_status == $traceroute->TRACEROUTE_UNREACH_SRCFAIL()){
                        $error = "interfaceInactiveToTarget"; 
                    }elsif($query_status == $traceroute->TRACEROUTE_UNKNOWN()){
                        $error = "unknown"; 
                    }else{
                        #TRACEROUTE_UNREACH_PROTO,TRACEROUTE_UNREACH_NEEDFRAG
                        #TRACEROUTE_UNREACH_FILTER_PROHIB, TRACEROUTE_BSDBUG
                        $error = "internalError";
                    }
                    $hop_stats->{'error'} = $error;
                }

                push @traceroutes, $hop_stats;
            }
        }
    };
    if ($@) {
        my $msg = "Problem parsing traceroute output: $@";
        $logger->error($msg);
        $error = $msg;
    };

    my $results = {
        hops => \@traceroutes
    };

    $results->{error} = $error if $error;

    return $results;
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

$Id: Host.pm 5139 2012-06-01 15:48:46Z aaron $

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
