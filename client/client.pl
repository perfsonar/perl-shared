#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Log::Log4perl qw(:easy);
use XML::LibXML;
use File::Basename;


sub dump($$);
sub print_help();

my $dirname;
my $libdir;

# we need to figure out what the library is at compile time so that "use lib"
# doesn't fail. To do this, we enclose the calculation of it in a BEGIN block.
BEGIN {
	$dirname = dirname($0);
	$libdir = $dirname."/../lib";
}

use lib "$libdir";

use perfSONAR_PS::Transport;
use perfSONAR_PS::Common qw( readXML );
use perfSONAR_PS::Utils::NetLogger;

our $DEBUGFLAG;
our %opts = ();

our $help_needed;

my $ok = GetOptions (
		'debug'    	=> \$DEBUGFLAG,
		'server=s'	=> \$opts{HOST},
		'port=s'  	=> \$opts{PORT},
		'endpoint=s'	=> \$opts{ENDPOINT},
		'filter=s'	=> \$opts{FILTER},
		'help'     	=> \$help_needed
	);

# help?
if (not $ok or $help_needed) {
	print_help();
  	exit(1);	
}

# setup logging
our $level = $INFO;

if ($DEBUGFLAG) {
	$level = $DEBUG;    
}

Log::Log4perl->easy_init($level);
my $logger = get_logger("perfSONAR_PS");

# process two arguments
my $host;
my $port;
my $endpoint;
my $filter = '/';
my $file;
if (scalar @ARGV eq 2) {
	($host, $port, $endpoint) = &perfSONAR_PS::Transport::splitURI($ARGV[0]);

	if (!defined $host && !defined $port && !defined $endpoint) {
		print_help();
		 die "Argument 1 must be a URI if more than one parameter used.\n";
	}

	$file = $ARGV[1];
} elsif (scalar @ARGV eq 1) {
	$file = $ARGV[0];
} else {
	print_help();
	die "Invalid number of parameters: must be 1 for just a file, or 2 for a uri and a file";
}

if (!-f $file) {
	die "File $file does not exist";
}

# find options
if (defined $opts{HOST}) {
	$host = $opts{HOST};
}
if (defined $opts{PORT}) {
	$port = $opts{PORT};
}
if (defined $opts{ENDPOINT}) {
	$endpoint = $opts{ENDPOINT};
}
if (defined $opts{FILTER}) {
	$filter = $opts{FILTER};
}

if (!defined $host or !defined $port or !defined $endpoint) {
	print_help();
	die "You must specify the host, port and endpoint as either a URI or via the command line switches";
}

# start a transport agent
my $sender = new perfSONAR_PS::Transport($host, $port, $endpoint);

# Read the source XML file
my $xml = readXML($file);
# Make a SOAP envelope, use the XML file as the body.
my $envelope = &perfSONAR_PS::Common::makeEnvelope($xml);
my $error;

# Send/receive to the server, store the response for later processing
my $msg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.client.sendReceive.start",
	{host=>$host, port=>$port, endpoint=>$endpoint,});
$logger->debug($msg);

my $responseContent = $sender->sendReceive($envelope, "", \$error);

$msg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.client.sendReceive.end",);
$logger->debug($msg);

if ($error ne "") {
	die("Error sending request to service: $error");
}

# dump the content to screen, using the xpath statement if necessary
&dump($responseContent, $filter);

exit(0);

1;


###
# dumps the response to screen; using the xpath query filter if defined
###
sub dump($$) {
	my $response = shift;
	my $find = shift;

	my $xp;

	if(UNIVERSAL::can($response, "isa") ? "1" : "0" == 1 && $xml->isa('XML::LibXML')) {
		$xp = $response;
	} else {
		my $parser = XML::LibXML->new();
		$xp = $parser->parse_string($response);  
	}

	my @res = $xp->findnodes("$find");

	foreach my $n (@res) {
		print $n->toString() . "\n";
	}

	return;
}

sub print_help() {
 	print "$0: sends an xml file to the server on specified port.\n";
  	print "    ./client.pl [--server=xxx.yyy.zzz --port=n --endpoint=ENDPOINT] [URI] FILENAME\n";
}

=head1 NAME

client - A simple perfSONAR client.

=head1 DESCRIPTION

The purpose of this is to enable quick client side debugging of perfSONAR services.
 
=head1 SYNOPSIS
 
    # this will send the xml file echo-req.xml to srv4.dir.garr.it on port 8080
    # and endpoint /axis/services/MeasurementArchiveService
    $ client.pl \
           http://srv4.dir.garr.it:8080/axis/services/MeasurementArchiveService \
           echo-req.xml

    # ditto
    $ client.pl \
           --server=srv4.dir.garr.it \
           --port=8080 \
           --endpoint=/axis/services/MeasurementArchiveService \
           echo-req.xml
	       
    # this will override the port 8080 with the specified port 80
    $ client.pl \
           --port=80
           http://srv4.dir.garr.it:8080/axis/services/MeasurementArchiveService \
           echo-req.xml

    # this will override the endpoint with 
    # /perfsonar-RRDMA/services/MeasurementArchiveService
    $ client.pl \
           --endpoint=/perfsonar-RRDMA/services/MeasurementArchiveService
           http://srv4.dir.garr.it:8080/axis/services/MeasurementArchiveService \
           echo-req.xml
	        
    # this will filter the output of the returned xml to only show the elements
    # that have qname nmwg:data
    $ client.pl \
           --filter='//nmwg:data' \
           http://srv4.dir.garr.it:8080/axis/services/MeasurementArchiveService \
           echo-req.xml
	       
=head1 REQUIRES

Getopt::Long;
Log::Log4perl;
XML::LibXML;
perfSONAR_PS::Transport;
perfSONAR_PS::Common;

=head1 AUTHOR

Yee-Ting Li <ytl@slac.stanford.edu>

Based on original client by Jason Zurawski <zurawski@eecis.udel.edu>

=head1 VERSION

Current version is this one ;) 

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Jason Zurawski & Yee-Ting Li 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
