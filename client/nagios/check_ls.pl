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
use Nagios::Plugin;
use perfSONAR_PS::Common qw( find findvalue );
use perfSONAR_PS::Client::LS;
use XML::LibXML;
use LWP::Simple;

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

my $query = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
$query = "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
$query = "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
$query .= "/nmwg:store[\@type=\"LSStore-summary\"]//psservice:accessPoint[text()=\"" . $ls_url . "\"]\n";

my $result = $ls->queryRequestLS( { query => $query, format => 1, eventType => "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0" } );
if ( not defined $result ) {
    $code = $NAGIOS_API_ECODES{CRITICAL};
    $msg  = "Service is not responding.";
}
elsif ( $result->{eventType} =~ m/^error/mx ) {

    # warning, got an answer, not what we wanted
    $code = $NAGIOS_API_ECODES{WARNING};
    $msg  = "Service returned unexpected response.";
}
else {
    $code = $NAGIOS_API_ECODES{OK};
    $msg  = "Service functioning normally.";
}

$np->nagios_exit( $code, $msg );

__END__

=head1 SEE ALSO

L<Nagios::Plugin>, L<XML::LibXML>, L<LWP::Simple>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Client::LS>

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
