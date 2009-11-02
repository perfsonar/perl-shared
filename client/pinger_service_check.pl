#!/usr/local/bin/perl -w
use lib qw(../lib);
use strict;
use warnings;
use perfSONAR_PS::Client::PingER;
use Data::Dumper;
use Getopt::Long;
use English;
use POSIX qw(strftime);
use JSON::XS;

use  Log::Log4perl  qw(:easy); 
my $url = 'http://localhost:8075/perfSONAR_PS/services/pinger/ma';
my ($debug, $help, $data);
my $ok = GetOptions (
                'debug|d'     => \$debug,       
                'url=s'       => \$url,
		'data'        => \$data,
                'help|?|h'    => \$help
        );
if(!$ok || !$url  || $help) {
   print " $0: sends an  XML request over SOAP to the pinger MA and prints response or returns conclusion about service's health \n";
   print " $0   [--url=<pinger_MA_url, default is localhost> --debug|-d  --verbose|v --data] \n";
   print " $0    --data - to check data for every metadata id for the past 30 minutes \n";
   print " $0    --check - to return conclusion about health \n";
   exit 0;
}
my $level = $INFO;

if ($debug) {
   $level = $DEBUG;    
}

Log::Log4perl->easy_init($level);
my $logger = get_logger("pinger_client");
  
my ($result, $metaids);
my $ma = new perfSONAR_PS::Client::PingER( { instance => $url } );
eval {
    $result = $ma->metadataKeyRequest();
};
if($EVAL_ERROR) {
    health_failed({MDKrequest => $EVAL_ERROR});
} 
unless($result) {
   health_failed({MDKrequest => 'No response from the service, its not running ?'});
}
eval {
    $metaids = $ma->getMetaData($result);
};
if($EVAL_ERROR ) {
    health_failed({metadata => $EVAL_ERROR});
}
my @metaids_arr = keys %$metaids;
unless(@metaids_arr) {
    health_failed({metadata =>  'No METADATA, check if landmarks file is empty'});
}
my $time_start =  time() -  1800;
my $time_end   =  time();
my $ptime = sub {strftime " %Y-%m-%d %H:%M", localtime(shift)};
my %keys =();

foreach  my $meta  (@metaids_arr) {
    $logger->debug("Metadata: src=$metaids->{$meta}{src_name} dst=$metaids->{$meta}{dst_name}  packetSize=$metaids->{$meta}{packetSize}\nMetadata Key(s):");
    map { $logger->debug(" $_ :")} @{$metaids->{$meta}{keys}};
    map {$keys{$_}++} @{$metaids->{$meta}{keys}};
}
unless(%keys) {
    health_failed({metadata =>  'No METADATA, check if landmarks file is empty'});
}

$ma = new perfSONAR_PS::Client::PingER( { instance => $url } );
my ($dresult, $data_md);
eval {
    $dresult= $ma->setupDataRequest( { 
    	 start => $time_start, 
    	 end =>   $time_end,  
    	 keys =>  [keys %keys],
    	 cf => 'AVERAGE',
    	 resolution => 5,
    }); 
};
if($EVAL_ERROR) {
    health_failed({SDrequest => $EVAL_ERROR});
}
eval {
    $data_md = $ma->getData($dresult);
};
if($EVAL_ERROR) {
    health_failed({data => $EVAL_ERROR});
}
my @data_arr = keys %{$data_md};
unless( @data_arr ) {
    health_failed({data => 'No data in the past 30 minutes, check if MP is running'});
}
unless(@data_arr == @metaids_arr) {
    health_failed({data => 'some data is missing, check if some of the hosts you pinging are blocked or not on the network'});
}
foreach my $key_id  (@data_arr) {
    $logger->debug("\n---- Key: $key_id");
    foreach my $id ( keys %{$data_md->{$key_id}{data}}) {
    	$logger->debug("---- MetaKey: $id");
    	foreach my $timev   (sort {$a <=> $b} keys %{$data_md->{$key_id}{data}{$id}}) {
    	      $logger->debug("Data: tm=" . $ptime->($timev) . " datums: ");
    	      map { $logger->debug("$_ = $data_md->{$key_id}{data}{$id}{$timev}{$_} ")} keys %{$data_md->{$key_id}{data}{$id}{$timev}};
       }  
  
    } 
} 
print encode_json {service => 'OK'};
exit 0;


sub health_failed {
  my $health = shift;
  $health->{service} = 'NOT OK';
  print encode_json $health;
  exit 1;
}
 
__END__
