#!/usr/bin/perl -w

use strict;
use warnings;
use CGI;
use HTML::Template;
use XML::LibXML;

# change this to the location where you install perfSONAR-PS

use lib "/home/jason/RELEASE/RELEASE_3.1/Shared/lib";
use perfSONAR_PS::Client::DCN;
use perfSONAR_PS::Common qw( escapeString find extract );

my $cgi = new CGI;
my $parser = XML::LibXML->new();

my $INSTANCE = "http://dcn-ls.internet2.edu:8005/perfSONAR_PS/services/hLS";
if ( $cgi->param('hls') ) {
    $INSTANCE = $cgi->param('hls');
}

my $template = HTML::Template->new( filename => "etc/view.tmpl" );

my @data = ();
my $ls = new perfSONAR_PS::Client::LS( { instance => $INSTANCE } );
my @eT = ( "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/query/xquery/2.0", "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0" );
my @store = ( "LSStore", "LSStore-summary", "LSStore-control" );

foreach my $e ( @eT ) {
    foreach my $s ( @store ) {
        my $METADATA = q{};
        my $q = "/nmwg:store[\@type=\"".$s."\"]/nmwg:metadata";
        my $result = $ls->queryRequestLS( { query => $q, eventType => $e, format => 1 } );
        if ( exists $result->{eventType} and not ( $result->{eventType} =~ m/^error/ ) ) {
            my $doc = $parser->parse_string( $result->{response} ) if exists $result->{response};        
            my $md = find( $doc->getDocumentElement, ".//nmwg:metadata", 0 );
            foreach my $m ( $md->get_nodelist ) {
                $METADATA .= escapeString( $m->toString ) . "\n";
            }
        }
        else {
            $METADATA = "EventType:\t" , $result->{eventType} . "\tResponse:\t" . $result->{response};
        }

        my $DATA = q{};
        $q = "/nmwg:store[\@type=\"".$s."\"]/nmwg:data";
        $result = $ls->queryRequestLS( { query => $q, eventType => $e, format => 1 } );
        if ( exists $result->{eventType} and not ( $result->{eventType} =~ m/^error/ ) ) {
            my $doc = $parser->parse_string( $result->{response} ) if exists $result->{response};        
            my $data = find( $doc->getDocumentElement, ".//nmwg:data", 0 );
            foreach my $d ( $data->get_nodelist ) {
                $DATA .= escapeString( $d->toString ) . "\n";
            }
        }
        else {
            $DATA = "EventType:\t" , $result->{eventType} . "\tResponse:\t" . $result->{response};
        }
        
        push @data, { COLLECTION => $e, STORE => $s, METADATA => $METADATA, DATA => $DATA };
    }
}

print $cgi->header();

$template->param(
    INSTANCE => $INSTANCE,
    DATA => \@data
);

print $template->output;
