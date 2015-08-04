package perfSONAR_PS::RegularTesting::Parsers::ParisTraceroute;

use strict;
use warnings;

our $VERSION = 3.5;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::ParisTraceroute;

=head1 DESCRIPTION

A module that provides simple functions for parsing paris-traceroute output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( parse_paristraceroute_output );

my $logger = get_logger(__PACKAGE__);

=head2 parse_paristraceroute_output()

=cut

sub parse_paristraceroute_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};


# [root@ps-lat alake]# paris-traceroute newy-pt1.es.net
# Traceroute to 198.124.238.54 using algorithm mda
# 
# 0 * -> 198.129.254.185 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 1 198.129.254.185 -> 198.129.100.1 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 2 198.129.100.1 -> 134.55.49.1 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 3 134.55.49.1 -> 134.55.40.5 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 4 134.55.40.5 -> 134.55.50.202 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 5 134.55.50.202 -> 134.55.49.58 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 6 134.55.49.58 -> 134.55.43.81 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 7 134.55.43.81 -> 134.55.42.42 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 8 134.55.42.42 -> 134.55.218.189 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 9 134.55.218.189 -> 134.55.209.34 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 10 134.55.209.34 -> 198.124.238.54 [ *1, *2, *3, *4, *5, *6,  ->  1,  2,  3,  4,  5,  6, ]
#
# [root@ps-lat alake]# paris-traceroute ps-bw.es.net
# Traceroute to 198.129.254.186 using algorithm mda
# 
# 0 * -> 198.129.254.186 [ *1, *2, *3, *4, *5, *6,  ->  1,  2,  3,  4,  5,  6, ]
#
# [root@ps-lat alake]# paris-traceroute google.com
# Traceroute to 74.125.239.104 using algorithm mda
# 
# 0 * -> 198.129.254.185 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 1 198.129.254.185 -> 198.129.100.1 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 2 198.129.100.1 -> 134.55.49.1 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 3 134.55.49.1 -> 134.55.38.146 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
# 4 134.55.38.146 -> * [ !1, !2, !3, !4, !5, !6,  -> *7, *8, *9, *10, *11, *12, ]
# 5 * -> * [ !7, !8, !9, !10, !11, !12,  -> *13, *14, *15, *16, *17, *18, ]
# 6 * -> * [ !13, !14, !15, !16, !17, !18,  -> *19, *20, *21, *22, *23, *24, ]
# 7 * [ !19, !20, !21, !22, !23, !24,  ]
    my %hops = ();
    for my $line (split('\n', $stdout)) {
        # Trim leading/trailing space
        chomp $line;

        if ($line =~ /^([0-9]+) (.+) -> (.+) \[.*\]/) {
            # Examples:
            #0 * -> 198.129.254.185 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
            #1 198.129.254.185 -> 198.129.100.1 [ *1, *2, *3, *4, *5, *6,  -> *1, *2, *3, *4, *5, *6, ]
            
            my $ttl = $1 + 1;
            my $src = $2;
            my $dst = $3;
            
            $hops{$ttl} = [] unless $hops{$ttl};
            my $query_num = scalar(@{ $hops{$ttl} }) + 1;
            my %hop_stats = (
                ttl => $ttl,
                queryNum => $query_num,
                hop => $dst,
            );

            push @{ $hops{$ttl} }, \%hop_stats;
        }
    }

    my @hops = ();
    foreach my $ttl (sort { $a <=> $b } keys %hops) {
        push @hops, @{ $hops{$ttl} };
    }

    return {
        hops => \@hops,
        path_mtu => undef,
    };
}

1;

__END__

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
