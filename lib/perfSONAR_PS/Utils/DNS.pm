package perfSONAR_PS::Utils::DNS;

=head1 NAME

perfSONAR_PS::Utils::DNS - A module that provides utility methods for interacting with DNS servers.

=head1 DESCRIPTION

This module provides a set of methods for interacting with DNS servers. This
module IS NOT an object, and the methods can be invoked directly. The methods
need to be explicitly imported to use them.

=head1 DETAILS

The API for this module aims to be simple; note that this is not an object and
each method does not have the 'self knowledge' of variables that may travel
between functions.

=head1 API

The API of perfSONAR_PS::Utils::DNS provides a simple set of functions for
interacting with DNS servers.
=cut

use base 'Exporter';

use strict;
use warnings;

use Net::DNS;
use NetAddr::IP;
use Regexp::Common;

our @EXPORT_OK = ( 'reverse_dns', 'resolve_address' );

=head2 resolve_address ($name)

Resolve an ip address to a DNS name.

=cut

sub resolve_address {
    my ($name) = @_;

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search($name);

    if ( not $query or $name !~ /$RE{net}{domain}/ ) {
        my @dns = ();
        push @dns, $name;
        return @dns;
    }

    my @addresses = ();
    foreach my $ans ( $query->answer ) {
        next if ( $ans->type ne "A" );

        push @addresses, $ans->address;
    }

    return @addresses;
}

=head2 reverse_dns ($ip)

Does a reverse DNS lookup on the given ip address. The ip must be in IPv4
dotted decimal or IPv6 colon-separated decimal form.

=cut

sub reverse_dns {
    my ($ip) = @_;

    my $tmp_ip = NetAddr::IP->new($ip);
    if ( not $tmp_ip ) {
        return;
    }

    my $addr = $tmp_ip->addr();
    if ( not $addr ) {
        return;
    }

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search("$addr");
    if ( not $query ) {
        return;
    }

    foreach my $ans ( $query->answer ) {
        next if ( $ans->type ne "PTR" );

        return $ans->ptrdname;
    }

    return;
}

1;

__END__

=head1 SEE ALSO

L<Exporter>, L<Net::DNS>, L<NetAddr::IP>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown <aaron@internet2.edu>

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
