#!/usr/bin/perl -w

use strict;
use warnings;

our $VERSION = 3.2;

=head1 NAME

check_ls.pl

=head1 DESCRIPTION

NAGIOS plugin to check perfSONAR LS services.  

=head1 SYNOPSIS

NAGIOS plugin to check running LS instances for both:

 1) Liveness (e.g. EchoRequest message)
 2) Database access (e.g. LSQueryRequest message)
 
Display:

  OK:       If the service passes both checks
  WARNING:  If the service is alive, but the database check fails
  CRITICAL: If both checks fail
           
=cut

use FindBin qw($RealBin);
use lib "$RealBin/../../lib/";

use perfSONAR_PS::Common qw( find findvalue );
use perfSONAR_PS::Client::LS;
use perfSONAR_PS::Transport;
use Nagios::Plugin;
use XML::LibXML;
use LWP::Simple;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Socket;

sub get_ip_and_host {
    my ( $endpoint ) = @_;

    my $ip       = q{};
    my $hostname = q{};

    if ( is_ipv4( $endpoint ) ) {
        $ip = $endpoint;
        my $tmp_addr = Socket::inet_aton( $endpoint );
        if ( defined $tmp_addr and $tmp_addr ) {
            $hostname = gethostbyaddr( $tmp_addr, Socket::AF_INET );
        }
        $hostname = $endpoint unless $hostname;
    }
    elsif ( is_ipv6( $endpoint ) ) {
        $ip = $endpoint;

        #try to lookup v6 record?
        $hostname = $endpoint;
    }
    else {

        #if not ipv4 or ipv6 then assume a hostname
        $hostname = $endpoint;
        my $packed_ip = gethostbyname( $endpoint );
        if ( defined $packed_ip and $packed_ip ) {
            $ip = inet_ntoa( $packed_ip );
        }
        $ip = $endpoint unless $ip;
    }
    return { 'ip' => $ip, 'hostname' => $hostname };
}

my %NAGIOS_API_ECODES = ( 'OK' => 0, 'WARNING' => 1, 'CRITICAL' => 2, 'UNKNOWN' => 3 );

my $np = Nagios::Plugin->new(
    shortname => 'PS_LS_CHECK',
    usage     => "Usage: %s -u|--url <LS-service-url>"
);

$np->add_arg(
    spec     => "u|url=s",
    help     => "URL of the Lookup Service to contact.",
    required => 1
);

$np->getopts;

my $ls_url = $np->opts->{'u'};
my $msg    = q{};
my $code   = q{};

my $ls = new perfSONAR_PS::Client::LS( { instance => $ls_url } );
my ( $host, $port, $endpoint ) = &perfSONAR_PS::Transport::splitURI( $ls_url );
my $contact = get_ip_and_host( $host );

my $query = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
$query = "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
$query = "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
$query .= "/nmwg:store[\@type=\"LSStore-summary\"]//psservice:accessPoint[text()=\"http://" . $contact->{"hostname"} . ":" . $port . $endpoint . "\"]\n";

my $result = $ls->queryRequestLS( { query => $query, format => 1, eventType => "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0" } );
if ( not defined $result ) {
    $code = $NAGIOS_API_ECODES{CRITICAL};
    $msg  = "Service is not responding.";
}
elsif ( $result->{eventType} =~ m/^error/mx ) {

    # try the other possibility - the hLS registered w/ IP or HostName.
    $query = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $query = "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
    $query = "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
    $query .= "/nmwg:store[\@type=\"LSStore-summary\"]//psservice:accessPoint[text()=\"http://" . $contact->{"ip"} . ":" . $port . $endpoint . "\"]\n";

    my $result2 = $ls->queryRequestLS( { query => $query, format => 1, eventType => "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0" } );
    if ( not defined $result2 ) {
        $code = $NAGIOS_API_ECODES{CRITICAL};
        $msg  = "Service is not responding.";
    }
    elsif ( $result2->{eventType} =~ m/^error/mx ) {

        # warning, got an answer, not what we wanted
        $code = $NAGIOS_API_ECODES{WARNING};
        $msg  = "Service returned unexpected response.";
    }
    else {
        $code = $NAGIOS_API_ECODES{OK};
        $msg  = "Service functioning normally.";
    }
}
else {
    $code = $NAGIOS_API_ECODES{OK};
    $msg  = "Service functioning normally.";
}

$np->nagios_exit( $code, $msg );

__END__

=head1 SEE ALSO

L<Nagios::Plugin>, L<XML::LibXML>, L<LWP::Simple>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Client::LS>, L<Data::Validate::IP>, L<Socket>

To join the 'perfSONAR Users' mailing list, please visit:

  https://lists.internet2.edu/sympa/info/perfsonar-ps-users

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu
Sowmya Balasubramanian, sowmya@es.net
Andrew Lake, andy@es.net

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2011, Internet2 and the University of Delaware

All rights reserved.

=cut
