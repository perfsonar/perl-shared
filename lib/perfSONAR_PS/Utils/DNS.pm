package perfSONAR_PS::Utils::DNS;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::Utils::DNS

=head1 DESCRIPTION

A module that provides utility methods for interacting with DNS servers.  This
module provides a set of methods for interacting with DNS servers. This module
IS NOT an object, and the methods can be invoked directly. The methods need to
be explicitly imported to use them.

=head1 API

=cut

use base 'Exporter';

use Net::DNS;
use NetAddr::IP;
use Regexp::Common;

our @EXPORT_OK = qw( reverse_dns resolve_address );

=head2 resolve_address ($name)

Resolve an ip address to a DNS name.

=cut

sub resolve_address {
    my ( $name ) = @_;

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search( $name );

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
    my ( $ip ) = @_;

    my $tmp_ip = NetAddr::IP->new( $ip );
    unless ( $tmp_ip ) {
        return;
    }

    my $addr = $tmp_ip->addr();
    unless ( $addr ) {
        return;
    }

    my $res   = Net::DNS::Resolver->new;
    my $query = $res->search( "$addr" );
    unless ( $query ) {
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

L<Net::DNS>, L<NetAddr::IP>, L<Regexp::Common>

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
