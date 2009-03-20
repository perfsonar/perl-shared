package perfSONAR_PS::Utils::Host;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::Utils::Host

=head1 DESCRIPTION

A module that provides functions for querying information about the host on
which the application is running. 

=head1 API

=cut

use base 'Exporter';

our @EXPORT_OK = qw( get_ips );

=head2 get_ips()

A function that returns the non-loopback IP addresses from a host. The current
implementation parses the output of the /sbin/ifconfig command to look for the
IP addresses.

=cut
sub get_ips {
    my @ret_interfaces = ();

    my $IFCONFIG;
    open( $IFCONFIG, "-|", "/sbin/ifconfig" ) or return;
    my $is_eth = 0;
    while ( <$IFCONFIG> ) {
        if ( /Link encap:([^ ]+)/ ) {
            if ( lc( $1 ) eq "ethernet" ) {
                $is_eth = 1;
            }
            else {
                $is_eth = 0;
            }
        }

        next unless $is_eth;

        if ( /inet addr:(\d+\.\d+\.\d+\.\d+)/ ) {
            push @ret_interfaces, $1;
        }
        elsif ( /inet6 addr: (\d*:[^\/ ]*)(\/\d+)? +Scope:Global/ ) {
            push @ret_interfaces, $1;
        }
    }
    close( $IFCONFIG );

    return @ret_interfaces;
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
