#!/usr/bin/perl -w

use strict;
use warnings;

# TODO: Determine how the build path will be set
#use FindBin qw($RealBin);
#use lib ("/usr/local/nagios/perl/lib");
use Nagios::Plugin;
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Statistics::Descriptive;
use perfSONAR_PS::Common qw( find findvalue );
use perfSONAR_PS::Client::MA;
use XML::LibXML;

use constant BW_SCALE => 10e8;
use constant BW_LABEL => 'Gbps';

my $np = Nagios::Plugin->new( shortname => 'PS_CHECK_THROUGHPUT',
                              usage => "Usage: %s -u|--url <service-url> -s|--source <source-addr> -d|--destination <dest-addr> -r <number-seconds-in-past> -w|--warning <threshold> -c|--critical <threshold>" );

#get arguments
$np->add_arg(spec => "u|url=s",
             help => "URL of the MA service to contact",
             required => 1 );
$np->add_arg(spec => "s|source=s",
             help => "Source of the test to check",
             required => 1 );
$np->add_arg(spec => "d|destination=s",
             help => "Destination of the test to check",
             required => 1 );
$np->add_arg(spec => "r|range=i",
             help => "Time range (in seconds) in the past to look at data. i.e. 60 means look at last 60 seconds of data.",
             required => 1 );
$np->add_arg(spec => "w|warning=s",
             help => "threshold of service count that leads to WARNING status",
             required => 1 );
$np->add_arg(spec => "c|critical=s",
             help => "threshold of service count that leads to CRITICAL status",
             required => 1 );
$np->getopts;                              

#create client
my $ma_url = $np->opts->{'u'};
my $ma = new perfSONAR_PS::Client::MA( { instance => $ma_url } );

# Define subject
my $subject = "<iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0\" id=\"subject\">\n";
$subject .=   "    <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">";
$subject .=   "        <nmwgt:src type=\"" . &get_endpoint_type( $np->opts->{'s'} ) . "\" value=\"" . $np->opts->{'s'} . "\"/>";
$subject .=   "        <nmwgt:dst type=\"" . &get_endpoint_type( $np->opts->{'d'} ) . "\" value=\"" . $np->opts->{'d'} . "\"/>";
$subject .=   "    </nmwgt:endPointPair>";
$subject .=   "</iperf:subject>\n";

# Set eventType
my @eventTypes = ("http://ggf.org/ns/nmwg/tools/iperf/2.0");

my $endTime = time;
my $startTime = $endTime - $np->opts->{'r'};
my $result = $ma->setupDataRequest(
        {
            start      => $startTime,
            end        => $endTime,
            subject    => $subject,
            eventTypes => \@eventTypes
        }
    ) or $np->nagios_die( "Error contacting MA $ma_url" );

my $parser = XML::LibXML->new();
my $doc;
eval{
    $doc = $parser->parse_string(@{$result->{data}});
};
if($@){
    $np->nagios_die( "Error parsing MA response" );
}
my $avg_throughput = find($doc->getDocumentElement, "./*[local-name()='datum']/\@throughput", 0);
if( !defined $avg_throughput){
    $np->nagios_die( "Error extracting throughput from MA response" );
}
if( @{$avg_throughput} == 0 ){
    $np->nagios_die( "No throughput data returned" );
}

my $stats = Statistics::Descriptive::Sparse->new();
foreach my $min_i (@{$avg_throughput}) {
    $stats->add_data( $min_i->getValue() );
}

$np->add_perfdata(
        label => 'Count',
        value => $stats->count(),
    );
$np->add_perfdata(
        label => 'Min',
        value => $stats->min()/BW_SCALE . BW_LABEL,
    );
$np->add_perfdata(
        label => 'Max',
        value => $stats->max()/BW_SCALE . BW_LABEL,
    );
$np->add_perfdata(
        label => 'Average',
        value => $stats->mean()/BW_SCALE . BW_LABEL,
    );
$np->add_perfdata(
        label => 'Standard_Deviation',
        value => $stats->standard_deviation()/BW_SCALE . BW_LABEL,
    );

my $code = $np->check_threshold(
     check => $stats->mean()/BW_SCALE,
     warning => $np->opts->{'w'},
     critical => $np->opts->{'c'},
   );

my $msg = "";   
if($code eq OK || $code eq WARNING || $code eq CRITICAL){
    $msg = "Average throughput is " . $stats->mean()/BW_SCALE . BW_LABEL;
}else{
    $msg = "Error analyzing results";
}
$np->nagios_exit($code, $msg);

sub get_endpoint_type(){
    my $endpoint = shift @_;
    my $type = "hostname";
    
    if( is_ipv4($endpoint) ){
        $type = "ipv4";
    }elsif( is_ipv6($endpoint) ){
        $type = "ipv6";
    }
    
    return $type;
}