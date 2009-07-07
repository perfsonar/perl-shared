#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

delayGraph.cgi - CGI script that graphs the output of a perfSONAR MA that
delivers delay data.  

=head1 DESCRIPTION

Given a url of an MA, and a key value (corresponds to a specific delay
result) graph using the Google graph API.  Note this instance is powered by
flash, so browsers will require that a flash player be installed and available.

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
    my ( $sec, $frac ) = Time::HiRes::gettimeofday;

    my $subject = "  <nmwg:key id=\"key-1\">\n";
    $subject .= "    <nmwg:parameters id=\"parameters-key-1\">\n";
    $subject .= "      <nmwg:parameter name=\"maKey\">" . $cgi->param('key') . "</nmwg:parameter>\n";
    $subject .= "    </nmwg:parameters>\n";
    $subject .= "  </nmwg:key>  \n";

    my $time = 7200;
    my $result = $ma->setupDataRequest(
        {
            start      => ( $sec - $time ),
            end        => $sec,
            resolution => 5,
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
                resolution => 5,
                subject    => $subject2,
                eventTypes => \@eventTypes
            }
        );

        $doc2 = $parser->parse_string( $result2->{"data"}->[0] );
        $datum2 = find( $doc2->getDocumentElement, "./*[local-name()='datum']", 0 );
    }

    my $flag1 = 0;
    my $flag2 = 0;
    my %store = ();
    if ( $datum1 ) {
        foreach my $dt ( $datum1->get_nodelist ) {
            my $s_secs = UnixDate( $dt->getAttribute("startTime"), "%s" );
            my $e_secs = UnixDate( $dt->getAttribute("endTime"),   "%s" );
            my $min    = eval( $dt->getAttribute("min_delay") );
            my $max    = eval( $dt->getAttribute("max_delay") );
            my $sent   = eval( $dt->getAttribute("sent") );

            my $loss = eval( $dt->getAttribute("loss") );
            $flag1 = 1 if $loss;
            my $dups = eval( $dt->getAttribute("duplicates") );
            $flag2 = 1 if $dups;

            $store{$e_secs}{"min"}{"src"}  = $min if $e_secs and $min;
            $store{$e_secs}{"max"}{"src"}  = $max if $e_secs and $max;
            $store{$e_secs}{"loss"}{"src"} = $loss if $e_secs and $loss;
            $store{$e_secs}{"dups"}{"src"} = $dups if $e_secs and $dups;
            $store{$e_secs}{"sent"}{"src"} = $sent if $e_secs and $sent;
        }
    }

    my $flag3 = 0;
    my $flag4 = 0;
    if ( $datum2 ) {
        foreach my $dt ( $datum2->get_nodelist ) {
            my $s_secs = UnixDate( $dt->getAttribute("startTime"), "%s" );
            my $e_secs = UnixDate( $dt->getAttribute("endTime"),   "%s" );
            my $min    = eval( $dt->getAttribute("min_delay") );
            my $max    = eval( $dt->getAttribute("max_delay") );
            my $sent   = eval( $dt->getAttribute("sent") );

            my $loss = eval( $dt->getAttribute("loss") );
            $flag3 = 1 if $loss;
            my $dups = eval( $dt->getAttribute("duplicates") );
            $flag4 = 1 if $dups;

            $store{$e_secs}{"min"}{"dst"}  = $min if $e_secs and $min;
            $store{$e_secs}{"max"}{"dst"}  = $max if $e_secs and $max;
            $store{$e_secs}{"loss"}{"dst"} = $loss if $e_secs and $loss;
            $store{$e_secs}{"dups"}{"dst"} = $dups if $e_secs and $dups;
            $store{$e_secs}{"sent"}{"dst"} = $sent if $e_secs and $sent;
        }
    }

    my $counter = 0;
    foreach my $time ( keys %store ) {
        $counter++;
    }

    print "<html>\n";
    print "  <head>\n";
    print "    <title>perfSONAR-PS perfAdmin Delay Graph</title>\n";
    
    if ( scalar keys %store > 0 ) {

        my $title = q{};
        if ( $cgi->param('src') and $cgi->param('dst') ) {
        
            if ( $cgi->param('shost') and $cgi->param('dhost') ) {
                $title = "Source: " . $cgi->param('shost');         
                $title .= " (" . $cgi->param('src') . ") ";
                $title .= " -- Destination: " . $cgi->param('dhost');
                $title .= " (" . $cgi->param('src') . ") ";
            }
            else {
                my $display = $cgi->param('src');
                my $iaddr = Socket::inet_aton($display);
                my $shost = gethostbyaddr( $iaddr, Socket::AF_INET );
                $display = $cgi->param('dst');
                $iaddr = Socket::inet_aton($display);
                my $dhost = gethostbyaddr( $iaddr, Socket::AF_INET );
                $title = "Source: " . $shost;         
                $title .= " (" . $cgi->param('src') . ") " if $shost;
                $title .= " -- Destination: " . $dhost;
                $title .= " (" . $cgi->param('dst') . ") " if $dhost;
            }
        }
        else {
            $title = "Observed Latency";
        }

        print "    <script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n";
        print "    <script type=\"text/javascript\">\n";
        print "      google.load(\"visualization\", \"1\", {packages:[\"annotatedtimeline\"]});\n";
        print "      google.setOnLoadCallback(drawChart);\n";
        print "      function drawChart() {\n";
        print "        var data = new google.visualization.DataTable();\n";

        print "        data.addColumn('datetime', 'Time');\n";

        print "        data.addColumn('number', 'Min Delay (Sec)');\n";
        print "        data.addColumn('number', 'Max Delay (Sec)');\n";
        if ($flag1) {
            print "        data.addColumn('string', 'Observed Loss');\n";
            print "        data.addColumn('string', 'text1');\n";
        }
        if ($flag2) {
            print "        data.addColumn('string', 'Observed Duplicates');\n";
            print "        data.addColumn('string', 'text2');\n";
        }
        if( $cgi->param('key2') ) {
            print "        data.addColumn('number', 'Min Delay (Sec)');\n";
            print "        data.addColumn('number', 'Max Delay (Sec)');\n";
            if ($flag3) {
                print "        data.addColumn('string', 'Observed Loss');\n";
                print "        data.addColumn('string', 'text1');\n";
            }
            if ($flag4) {
                print "        data.addColumn('string', 'Observed Duplicates');\n";
                print "        data.addColumn('string', 'text2');\n";
            }        
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
                if ( exists $store{$time}{"min"}{"src"} and $store{$time}{"min"}{"src"} ) {
                    print "        data.setValue(" . $counter . ", 0, new Date(" . $year[0] . "," . ( $year[1] - 1 ) . ",";
                    print $year[2] . "," . $time[0] . "," . $time[1] . "," . $time[2] . "));\n";
                                
                    print "        data.setValue(" . $counter . ", 1, " . $store{$time}{"min"}{"src"} . ");\n" if $store{$time}{"min"}{"src"};
                    print "        data.setValue(" . $counter . ", 2, " . $store{$time}{"max"}{"src"} . ");\n" if $store{$time}{"max"}{"src"};

                    if ( $store{$time}{"loss"}{"src"} ) {
                        print "        data.setValue(" . $counter . ", 3, 'Loss Observed');\n";
                        print "        data.setValue(" . $counter . ", 4, 'Lost " . $store{$time}{"loss"}{"src"} . " packets out of " . $store{$time}{"sent"}{"src"} . "');\n";
                    }
                    if ( $store{$time}{"dups"}{"src"} ) {
                        print "        data.setValue(" . $counter . ", " . (3 + ($flag2 * 2)) . ", 'Duplicates Observed');\n";
                        print "        data.setValue(" . $counter . ", " . (4 + ($flag2 * 2)) . ", '" . $store{$time}{"dups"}{"src"} . " duplicate packets out of " . $store{$time}{"sent"}{"src"} . "');\n";
                    }
                }
                if ( exists $store{$time}{"min"}{"dst"} and $store{$time}{"min"}{"dst"} ) {
                    print "        data.setValue(" . $counter . ", 0, new Date(" . $year[0] . "," . ( $year[1] - 1 ) . "," . $year[2] . "," . $time[0] . "," . $time[1] . "," . $time[2] . "));\n" unless ( exists $store{$time}{"min"}{"src"} and $store{$time}{"min"}{"src"} );
                                
                    print "        data.setValue(" . $counter . ", " . (3 + ($flag1 * 2) + ($flag2 * 2)) . ", " . $store{$time}{"min"}{"dst"} . ");\n" if $store{$time}{"min"}{"dst"};
                    print "        data.setValue(" . $counter . ", " . (4 + ($flag1 * 2) + ($flag2 * 2)) . ", " . $store{$time}{"max"}{"dst"} . ");\n" if $store{$time}{"max"}{"dst"};

                    if ( $store{$time}{"loss"}{"dst"} ) {
                        print "        data.setValue(" . $counter . ", " . (5 + ($flag1 * 2) + ($flag2 * 2)) . ", 'Loss Observed');\n";
                        print "        data.setValue(" . $counter . ", " . (6 + ($flag1 * 2) + ($flag2 * 2)) . ", 'Lost " . $store{$time}{"loss"}{"dst"} . " packets out of " . $store{$time}{"sent"}{"dst"} . "');\n";
                    }
                    if ( $store{$time}{"dups"}{"dst"} ) {
                        print "        data.setValue(" . $counter . ", " . (5 + ($flag1 * 2) + ($flag2 * 2) + ($flag4 * 2)) . ", 'Duplicates Observed');\n";
                        print "        data.setValue(" . $counter . ", " . (6 + ($flag1 * 2) + ($flag2 * 2) + ($flag4 * 2)) . ", '" . $store{$time}{"dups"}{"dst"} . " duplicate packets out of " . $store{$time}{"sent"}{"dst"} . "');\n";
                    }
                }
            }                        
            $counter++;
        }
    
        print "        var chart = new google.visualization.AnnotatedTimeLine(document.getElementById('chart_div'));\n";
        if ( $flag1 or $flag2 ) {
            print "        chart.draw(data, {legendPosition: 'newRow', displayAnnotations: true, colors: ['#ff8800', '#ff0000', '#0088ff', '#0000ff']});\n";
        }
        else {
            print "        chart.draw(data, {legendPosition: 'newRow', colors: ['#ff8800', '#ff0000', '#0088ff', '#0000ff']});\n";
        }
        print "      }\n";
        print "    </script>\n";
        print "  </head>\n";
        print "  <body>\n";
        print "    <h4 align=\"center\">" . $title . "</h4>\n";
        print "    <div id=\"chart_div\" style=\"width: 900px; height: 400px;\"></div>\n";
    }
    else {
        print "  </head>\n";
        print "  <body>\n";
        print "    <br><br>\n";
        print "    <h2 align=\"center\">Internal Error - Try again later.</h2>\n";
        print "    <br><br>\n";
    }

    print "  </body>\n";
    print "</html>\n";
}
else {
    print "<html><head><title>perfSONAR-PS perfAdmin Delay Graph</title></head>";
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

