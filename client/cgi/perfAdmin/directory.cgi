#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

directory.cgi - Script that takes a global inventory of the perfSONAR
information space and presents the results.

=head1 DESCRIPTION

Using the gLS infrastructure, locate all available perfSONAR services and
display the results in a tabulated form.  Using links to GUIs, present the
data for the viewer.

=cut

use HTML::Template;
use CGI;

use lib "/home/zurawski/perfSONAR-PS/lib";
#use lib "/usr/local/perfSONAR-PS/lib";

my $base   = "/home/zurawski/perfSONAR-PS/client/cgi/perfAdmin/cache";
my $template = HTML::Template->new( filename => "etc/directory.tmpl" );
my $CGI = CGI->new();

my %serviceMap = (
    "list.snmpma" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/characteristic/utilization/2.0",
            "http://ggf.org/ns/nmwg/tools/snmp/2.0"
        ],
        "TYPE" => "SNMP"
    },
    "list.psb.bwctl" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/iperf/2.0",
            "http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0",
            "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0"
        ],
        "TYPE" => "PSB_BWCTL"
    },
    "list.psb.owamp" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/owamp/2.0",
            "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921"
        ],
        "TYPE" => "PSB_OWAMP"
    },    
    "list.pinger" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/pinger/2.0/",
            "http://ggf.org/ns/nmwg/tools/pinger/2.0"
        ],
        "TYPE" => "PINGER"
    }
);

my %daemonMap = (
    "list.owamp" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/owamp/1.0"
        ],
        "TYPE" => "OWAMP"
    },
    "list.traceroute" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/traceroute/1.0"
        ],
        "TYPE" => "TRACEROUTE"
    },
    "list.ping" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/ping/1.0"
        ],
        "TYPE" => "PING"
    },
    "list.npad" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/npad/1.0"
        ],
        "TYPE" => "NPAD"
    },
    "list.ndt" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/ndt/1.0"
        ],
        "TYPE" => "NDT"
    },
    "list.bwctl" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/bwctl/1.0"
        ],
        "TYPE" => "BWCTL"
    },
    "list.phoebus" => {
        "EVENTTYPE" => [
            "http://ggf.org/ns/nmwg/tools/phoebus/1.0"
        ],
        "TYPE" => "PHOEBUS"
    }
);

my @daemonList = ();
my @serviceList = ();
my @anchors = ();
my $lastMod = "at an unknown time...";

if ( -d $base ) {

    my $hLSFile = $base . "/list.hls";
    if ( -f $hLSFile ) {
        my ($mtime) = (stat ( $hLSFile ) )[9];
        $lastMod = "on " . gmtime( $mtime ) . " UTC";
    }

    my @anch = ();
    my $counter1 = 0;
    foreach my $file ( keys %daemonMap ) {
        if ( -f $base . "/" . $file ) {
            open( READ, "<" . $base . "/" . $file ) or next;
            my @content = <READ>;
            close( READ );

            my @temp = ();          
            my $counter2 = 0;
            my $viewFlag = 0;
            foreach my $c ( @content ) {
                my @daemon = split(/\|/, $c);
                if ( $daemon[0] =~ m/^http:\/\// ) {
                    push @temp, { DAEMON => $daemon[0], NAME => $daemon[1], TYPE => $daemon[2], DESC => $daemon[3], COUNT1 => $counter1, COUNT2 => $counter2, VIEW => 1 };
                    $viewFlag++;
                }
                else {
                    push @temp, { DAEMON => $daemon[0], NAME => $daemon[1], TYPE => $daemon[2], DESC => $daemon[3], COUNT1 => $counter1, COUNT2 => $counter2, VIEW => 0 };
                }
                $counter2++;
            }
            push @daemonList, { TYPE => $daemonMap{ $file }{ "TYPE" }, CONTENTS => \@temp, VIEW => $viewFlag };

        }
        push @anch, { ANCHOR => $daemonMap{ $file }{ "TYPE" }, NAME => $daemonMap{ $file }{ "TYPE" }." Daemon" };
        $counter1++;
    }
    push @anchors, { ANCHOR => "daemons", TYPE => "Measurement Tools", ANCHORITEMS => \@anch };

    my @anch = ();        
    my $counter1 = 0;
    foreach my $file ( keys %serviceMap ) {
        if ( -f $base . "/" . $file ) {
            open( READ, "<" . $base . "/" . $file ) or next;
            my @content = <READ>;
            close( READ );

            my @temp = ();          
            my $counter2 = 0;
            foreach my $c ( @content ) {
                my @service = split(/\|/, $c);
                push @temp, { SERVICE => $service[0], NAME => $service[1], TYPE => $service[2], DESC => $service[3], COUNT1 => $counter1, COUNT2 => $counter2, EVENTTYPE => $serviceMap{ $file }{ "EVENTTYPE" }[0] };
                $counter2++;
            }
            push @serviceList, { TYPE => $serviceMap{ $file }{ "TYPE" }, CONTENTS => \@temp };
        }
        push @anch, { ANCHOR => $serviceMap{ $file }{ "TYPE" }, NAME => $serviceMap{ $file }{ "TYPE" }." Service" };
        $counter1++;
    }
    push @anchors, { ANCHOR => "services", TYPE => "perfSONAR Services", ANCHORITEMS => \@anch };
}

print $CGI->header();

$template->param(
    MOD => $lastMod,
    ANCHORTYPES => \@anchors,
    DAEMONS => \@daemonList,
    SERVICES => \@serviceList
);

print $template->output;

__END__

=head1 SEE ALSO

L<C>

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

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2007-2008, Internet2

All rights reserved.

=cut
