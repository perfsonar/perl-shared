#!/usr/bin/perl -w -I ../lib

=head1 NAME

dump.pl - Dumps the contents of an XMLDB.

=head1 DESCRIPTION

Given the information on an XMLDB, connect and dump all metadata and data
elements.

=head1 SYNOPSIS

./dump.pl [--verbose --help --environment=/path/to/env --container=container.dbxml --type=(LSStore|LSStore-control|LSStore-summary)]

=cut

use strict;
use warnings;
use Getopt::Long;
use perfSONAR_PS::DB::XMLDB;

my $DEBUG = '';
my $HELP = '';
my %opts = ();
GetOptions('verbose' => \$DEBUG,
           'help' => \$HELP,
           'type=s' => \$opts{TYPE}, 
           'environment=s' => \$opts{ENV}, 
           'container=s' => \$opts{CONT});

if(!(defined $opts{ENV} and $opts{CONT}) or $HELP) {
  print "$0: Loads into the specified container in the XML DB environment the contents of the store file.\n";
  print "$0 [--verbose --help --environment=/path/to/env/xmldb --container=container.dbxml --type=(LSStore|LSStore-control|LSStore-summary)]\n";
  exit(1);
}

my $XMLDBENV = "./xmldb/";
my $XMLDBCONT = "lsstore.dbxml";
my $XMLDBTYPE = "LSStore";
if(defined $opts{ENV}) {
  $XMLDBENV = $opts{ENV};
}
if(defined $opts{CONT}) {
  $XMLDBCONT = $opts{CONT};
}

if(defined $opts{TYPE}) {
  $XMLDBTYPE = $opts{TYPE};
}

my %ns = (
    nmwg          => "http://ggf.org/ns/nmwg/base/2.0/",
    nmtm          => "http://ggf.org/ns/nmwg/time/2.0/",
    ifevt         => "http://ggf.org/ns/nmwg/event/status/base/2.0/",
    iperf         => "http://ggf.org/ns/nmwg/tools/iperf/2.0/",
    bwctl         => "http://ggf.org/ns/nmwg/tools/bwctl/2.0/",
    owamp         => "http://ggf.org/ns/nmwg/tools/owamp/2.0/",
    netutil       => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
    neterr        => "http://ggf.org/ns/nmwg/characteristic/errors/2.0/",
    netdisc       => "http://ggf.org/ns/nmwg/characteristic/discards/2.0/",
    snmp          => "http://ggf.org/ns/nmwg/tools/snmp/2.0/",   
    select        => "http://ggf.org/ns/nmwg/ops/select/2.0/",
    average       => "http://ggf.org/ns/nmwg/ops/average/2.0/",
    perfsonar     => "http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/",
    psservice     => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/",
    xquery        => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/",
    xpath         => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xpath/1.0/",
    nmwgt         => "http://ggf.org/ns/nmwg/topology/2.0/",
    nmwgtopo3     => "http://ggf.org/ns/nmwg/topology/base/3.0/",
    pinger        => "http://ggf.org/ns/nmwg/tools/pinger/2.0/",
    nmwgr         => "http://ggf.org/ns/nmwg/result/2.0/",
    traceroute    => "http://ggf.org/ns/nmwg/tools/traceroute/2.0/",
    tracepath     => "http://ggf.org/ns/nmwg/tools/traceroute/2.0/",
    ping          => "http://ggf.org/ns/nmwg/tools/ping/2.0/",
    summary       => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/summarization/2.0/",        
    ctrlplane     => "http://ogf.org/schema/network/topology/ctrlPlane/20070707/",
    CtrlPlane     => "http://ogf.org/schema/network/topology/ctrlPlane/20070626/",
    ctrlplane_oct => "http://ogf.org/schema/network/topology/ctrlPlane/20071023/",
    ethernet      => "http://ogf.org/schema/network/topology/ethernet/20070828/",
    ipv4          => "http://ogf.org/schema/network/topology/ipv4/20070828/",
    ipv6          => "http://ogf.org/schema/network/topology/ipv6/20070828/",
    nmtb          => "http://ogf.org/schema/network/topology/base/20070828/",
    nmtl2         => "http://ogf.org/schema/network/topology/l2/20070828/",
    nmtl3         => "http://ogf.org/schema/network/topology/l3/20070828/",
    nmtl4         => "http://ogf.org/schema/network/topology/l4/20070828/",
    nmtopo        => "http://ogf.org/schema/network/topology/base/20070828/",
    nmtb          => "http://ogf.org/schema/network/topology/base/20070828/",
    sonet         => "http://ogf.org/schema/network/topology/sonet/20070828/",
    transport     => "http://ogf.org/schema/network/topology/transport/20070828/"  
);

my $error = q{};
my $metadatadb = new perfSONAR_PS::DB::XMLDB({
  env => $XMLDBENV, 
  cont => $XMLDBCONT,
  ns => \%ns
});
unless($metadatadb->openDB({ txn => q{}, error => \$error }) == 0) {
  print "There was an error opening \"".$XMLDBENV."/".$XMLDBCONT."\": ".$error;
  exit(1);
}

my $query = " /nmwg:store[\@type=\"".$XMLDBTYPE."\"]/nmwg:metadata";   
$query =~ s/\s+\// collection('$XMLDBCONT')\//gmx;
print "QUERY:\t" , $query , "\n" if $DEBUG;

my @resultsString = $metadatadb->query({ query => $query, txn => q{}, error => \$error });

my $len = $#resultsString;
for my $x (0..$len) {
  print $resultsString[$x] , "\n";
}
unless($#resultsString > -1) {
  print "Nothing returned for search.\n";        
}   

$query = "/nmwg:store[\@type=\"".$XMLDBTYPE."\"]/nmwg:data";   
$query =~ s/\s+\// collection('$XMLDBCONT')\//gmx;
print "QUERY:\t" , $query , "\n" if $DEBUG;  

@resultsString = $metadatadb->query({ query => $query, txn => q{}, error => \$error });

$len = $#resultsString;
for my $y (0..$len) {
  print $resultsString[$y] , "\n";
}
unless($#resultsString > -1) {
  print "Nothing returned for search.\n";        
}   

$metadatadb->closeDB;

exit(1);

=head1 SEE ALSO

L<strict>, L<warnings>, L<Getopt::Long>, L<perfSONAR_PS::DB::XMLDB>

To join the 'perfSONAR-PS' mailing list, please visit:

https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

https://svn.internet2.edu/svn/perfSONAR-PS

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id:$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2008, Internet2 and the University of Delaware

All rights reserved.

=cut

