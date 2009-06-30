#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

bandwidthGraph.cgi - CGI script that graphs the output of a perfSONAR MA that
delivers bandwidth data.  

=head1 DESCRIPTION

Given a url of an MA, and a key value (corresponds to a specific bandwidth
result) graph using the Google graph API.

=cut

use CGI;
use XML::LibXML;
use Date::Manip;
use Socket;
use POSIX;

# change this to the location where you install perfSONAR-PS

use lib "/home/jason/RELEASE/RELEASE_3.1/Shared/lib";
#use lib "/usr/local/perfSONAR-PS/lib";

use perfSONAR_PS::Client::MA;
use perfSONAR_PS::Common qw( extract find );

my $cgi = new CGI;
print "Content-type: text/html\n\n";
if ( $cgi->param('key') and $cgi->param('url') ) {

    my $ma = new perfSONAR_PS::Client::MA( { instance => $cgi->param('url') } );

    my @eventTypes = ();
    my $parser     = XML::LibXML->new();
    my $sec = time;

    my $subject = "  <nmwg:key id=\"key-1\">\n";
    $subject .= "    <nmwg:parameters id=\"parameters-key-1\">\n";
    $subject .= "      <nmwg:parameter name=\"maKey\">" . $cgi->param('key') . "</nmwg:parameter>\n";
    $subject .= "    </nmwg:parameters>\n";
    $subject .= "  </nmwg:key>  \n";

#    my $time = 2592000;
    my $time = 86400*7;
    my $result = $ma->setupDataRequest(
        {
            start      => ( $sec - $time ),
            end        => $sec,
            subject    => $subject,
            eventTypes => \@eventTypes
        }
    );

    my $doc1 = $parser->parse_string( $result->{"data"}->[0] );
    my $datum1 = find( $doc1->getDocumentElement, "./*[local-name()='datum']", 0 );

    my $doc2;
    my $datum2;    
    my $result2;
    if( $cgi->param('key2') ) {
        my $subject2 = "  <nmwg:key id=\"key-2\">\n";
        $subject2 .= "    <nmwg:parameters id=\"parameters-key-2\">\n";
        $subject2 .= "      <nmwg:parameter name=\"maKey\">" . $cgi->param('key2') . "</nmwg:parameter>\n";
        $subject2 .= "    </nmwg:parameters>\n";
        $subject2 .= "  </nmwg:key>  \n";

        $result2 = $ma->setupDataRequest(
            {
                start      => ( $sec - $time ),
                end        => $sec,
                subject    => $subject2,
                eventTypes => \@eventTypes
            }
        );

        $doc2 = $parser->parse_string( $result2->{"data"}->[0] );
        $datum2 = find( $doc2->getDocumentElement, "./*[local-name()='datum']", 0 );
    }

    my %store = ();
    if ( $datum1 ) {
        foreach my $dt ( $datum1->get_nodelist ) {
            my $secs = UnixDate( $dt->getAttribute("timeValue"), "%s" );
            $store{$secs}{"src"} = eval( $dt->getAttribute("throughput") ) if $secs and $dt->getAttribute("throughput");
        }

    }
    if ( $datum2 ) {
        foreach my $dt ( $datum2->get_nodelist ) {
            my $secs = UnixDate( $dt->getAttribute("timeValue"), "%s" );
            $store{$secs}{"dest"} = eval( $dt->getAttribute("throughput") ) if $secs and $dt->getAttribute("throughput");
        }
    }

    my $counter = 0;
    foreach my $time ( keys %store ) {
        $counter++;
    }

    print "<html>\n";
    print "  <head>\n";
    print "    <title>perfSONAR-PS perfAdmin Bandwidth Graph";
    if ( $cgi->param('type') ) {
        print " ".$cgi->param('type');
    }
    print "</title>\n";

    if ( scalar keys %store > 0 ) {

        my $title = q{};
        if ( $cgi->param('src') and $cgi->param('dst') ) {

            my $display = $cgi->param('src');
            my $iaddr = Socket::inet_aton($display);
            my $shost = gethostbyaddr( $iaddr, Socket::AF_INET );
            $display = $cgi->param('dst');
            $iaddr = Socket::inet_aton($display);
            my $dhost = gethostbyaddr( $iaddr, Socket::AF_INET );
            $title = "Source: " . $cgi->param('src');         
            $title .= " (" . $shost . ") " if $shost;
            $title .= " Destination: " . $cgi->param('dst');
            $title .= " (" . $dhost . ") " if $dhost;
            $title .= " -- Mbits/sec";
        }
        else {
            $title = "Observed Bandwidth -- Mbits/sec";
        }

        print "    <script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n";
        print "    <script type=\"text/javascript\">\n";
        print "      google.load(\"visualization\", \"1\", {packages:[\"areachart\"]})\n";
        print "      google.setOnLoadCallback(drawChart);\n";
        print "      function drawChart() {\n";
        print "        var data = new google.visualization.DataTable();\n";
        print "        data.addColumn('datetime', 'Time');\n";
        print "        data.addColumn('number', 'Src -> Dest Bandwidth in Mbps');\n";
        if( $cgi->param('key2') ) {
            print "        data.addColumn('number', 'Dest -> Src Bandwidth in Mbps');\n";
        }

        my $doc1 = $parser->parse_string( $result->{"data"}->[0] );
        my $datum1 = find( $doc1->getDocumentElement, "./*[local-name()='datum']", 0 );

        my $doc2;
        my $datum2;
        if( $cgi->param('key2') ) {
            $doc2 = $parser->parse_string( $result2->{"data"}->[0] );
            $datum2 = find( $doc2->getDocumentElement, "./*[local-name()='datum']", 0 );
        }
        print "        data.addRows(" . $counter . ");\n";

        $counter = 0;
        foreach my $time ( sort keys %store ) {
            my $date  = ParseDateString( "epoch " . $time );
            my $date2 = UnixDate( $date, "%Y-%m-%d %H:%M:%S" );
            my @array = split( / /, $date2 );
            my @year  = split( /-/, $array[0] );
            my @time  = split( /:/, $array[1] );
            if ( $#year > 1 and $#time > 1 ) {
                if ( exists $store{$time}{"src"} and $store{$time}{"src"} ) {
                    print "        data.setValue(" . $counter . ", 0, new Date(" . $year[0] . "," . ( $year[1] - 1 ) . ",";
                    print $year[2] . "," . $time[0] . "," . $time[1] . "," . $time[2] . "));\n";
                    print "        data.setValue(" . $counter . ", 1, " . $store{$time}{"src"}/1000000. . ");\n" if exists $store{$time}{"src"};               
                }
                if ( exists $store{$time}{"dest"} and $store{$time}{"dest"} ) {
                    print "        data.setValue(" . $counter . ", 0, new Date(" . $year[0] . "," . ( $year[1] - 1 ) . ",";
                    print $year[2] . "," . $time[0] . "," . $time[1] . "," . $time[2] . "));\n" unless ( exists $store{$time}{"src"} and $store{$time}{"src"} );
                    print "        data.setValue(" . $counter . ", 2, " . $store{$time}{"dest"}/1000000. . ");\n" if exists $store{$time}{"dest"};         
                }
                $counter++ if ( exists $store{$time}{"dest"} and $store{$time}{"dest"} ) or ( exists $store{$time}{"src"} and $store{$time}{"src"} );         
            }
        }
        print "        var chart = new google.visualization.AreaChart(document.getElementById('chart_div'));\n";
        print "        chart.draw(data, {legendFontSize: 12, axisFontSize: 12, titleFontSize: 16, colors: ['#00cc00', '#0000ff'], width: 900, height: 400, min: 0, legend: 'bottom', title: '" . $title . "', titleY: 'Mbps'});\n";
        print "      }\n";
        print "    </script>\n";
        print "  </head>\n";
        print "  <body>\n";



        print "    <div id=\"chart_div\" style=\"width: 900px; height: 400px;\"></div>\n";
    }
    else {
        print "  </head>\n";
        print "  <body>\n";
        print "    <br><br>\n";
        print "    <h2 align=\"center\">Data Not Found - Try again later.</h2>\n";
        print "    <br><br>\n";
    }

    print "  </body>\n";
    print "</html>\n";
}
else {
    print "<html><head><title>perfSONAR-PS perfAdmin Bandwidth Graph</title></head>";
    print "<body><h2 align=\"center\">Graph error; Close window and try again.</h2></body></html>";
}

__END__

=head1 SEE ALSO

L<CGI>, L<XML::LibXML>, L<Date::Manip>, L<perfSONAR_PS::Client::MA>,
L<perfSONAR_PS::Common>

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

