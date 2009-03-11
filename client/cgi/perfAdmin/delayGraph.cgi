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

use lib "/home/zurawski/perfSONAR-PS/lib";
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

    my $flag1 = 0;
    my $flag2 = 0;
    my %store = ();
    my $counter = 0;
    if ( $datum1 ) {
        foreach my $dt ( $datum1->get_nodelist ) {
            $counter++;
        }
        
        foreach my $dt ( $datum1->get_nodelist ) {
            my $s_secs = UnixDate( $dt->getAttribute("startTime"), "%s" );
            my $e_secs = UnixDate( $dt->getAttribute("endTime"),   "%s" );
            my $min    = eval( $dt->getAttribute("min_delay") );
            my $max    = eval( $dt->getAttribute("max_delay") );
            my $sent   = eval( $dt->getAttribute("sent") );

            my $loss = eval( $dt->getAttribute("loss") );
            $flag1++ if $loss;
            my $dups = eval( $dt->getAttribute("duplicates") );
            $flag2++ if $dups;

            $store{$e_secs}{"min"}  = $min if $e_secs and $min;
            $store{$e_secs}{"max"}  = $max if $e_secs and $max;
            $store{$e_secs}{"loss"} = $loss if $e_secs and $loss;
            $store{$e_secs}{"dups"} = $dups if $e_secs and $dups;
            $store{$e_secs}{"sent"} = $sent if $e_secs and $sent;
        }
    }

    print "<html>\n";
    print "  <head>\n";
    print "    <title>perfSONAR-PS perfAdmin Delay Graph</title>\n";
    
    if ( scalar keys %store > 0 ) {
        print "    <script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n";
        print "    <script type=\"text/javascript\">\n";
        print "      google.load(\"visualization\", \"1\", {packages:[\"annotatedtimeline\"]});\n";
        print "      google.setOnLoadCallback(drawChart);\n";
        print "      function drawChart() {\n";
        print "        var data = new google.visualization.DataTable();\n";

        print "        data.addColumn('date', 'Time');\n";
        print "        data.addColumn('number', 'Min Delay');\n";
        print "        data.addColumn('number', 'Max Delay');\n";
        if ($flag1) {
            print "        data.addColumn('string', 'title1');\n";
            print "        data.addColumn('string', 'text1');\n";
        }
        if ($flag2) {
            print "        data.addColumn('string', 'title2');\n";
            print "        data.addColumn('string', 'text2');\n";
        }
        print "        data.addRows(" . $counter . ");\n";

        $counter = 0;
        foreach my $time ( sort keys %store ) {
            my $date  = ParseDateString( "epoch " . $time );
            my $date2 = UnixDate( $date, "%Y-%m-%d %H:%M:%S" );
            my @array = split( / /, $date2 );
            my @year  = split( /-/, $array[0] );
            my @time  = split( /:/, $array[1] );

            print "        data.setValue(" . $counter . ", 0, new Date(" . $year[0] . "," . ( $year[1] - 1 ) . ",";
            print $year[2] . "," . $time[0] . "," . $time[1] . "," . $time[2] . "));\n";
            print "        data.setValue(" . $counter . ", 1, " . $store{$time}{"min"} . ");\n" if $store{$time}{"min"};
            print "        data.setValue(" . $counter . ", 2, " . $store{$time}{"max"} . ");\n" if $store{$time}{"max"};

            if ( $store{$time}{"loss"} ) {
                print "        data.setValue(" . $counter . ", 3, 'Loss Observed');\n";
                print "        data.setValue(" . $counter . ", 4, 'Lost " . $store{$time}{"loss"} . " packets out of " . $store{$time}{"sent"} . "');\n";
            }
            if ( $store{$time}{"dups"} ) {
                print "        data.setValue(" . $counter . ", 5, 'Duplicates Observed');\n";
                print "        data.setValue(" . $counter . ", 6, '" . $store{$time}{"dups"} . " duplicate packets out of " . $store{$time}{"sent"} . "');\n";
            }
            $counter++;
        }
    
        print "        var chart = new google.visualization.AnnotatedTimeLine(document.getElementById('chart_div'));\n";
        if ( $flag1 or $flag2 ) {
            print "        chart.draw(data, {displayAnnotations: true});\n";
        }
        else {
            print "        chart.draw(data, {});\n";
        }
        print "      }\n";
        print "    </script>\n";
        print "  </head>\n";
        print "  <body>\n";
        if ( $cgi->param('src') and $cgi->param('dst') ) {

            my $display = $cgi->param('src');
            my $iaddr = Socket::inet_aton($display);
            my $shost = gethostbyaddr( $iaddr, Socket::AF_INET );
            $display = $cgi->param('dst');
            $iaddr = Socket::inet_aton($display);
            my $dhost = gethostbyaddr( $iaddr, Socket::AF_INET );

            print "    <table border=\"0\" cellpadding=\"0\" width=\"75%\" align=\"center\">";
            print "      <tr>\n";
            print "        <td align=\"right\" width=\"30%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <th align=\"left\" width=\"10%\">\n";
            print "          <font size=\"-1\"><i>Source</i>:</font>\n";
            print "        </th>\n";
            print "        <td align=\"left\" width=\"10%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <td align=\"left\" width=\"60%\">\n";
            print "          <font size=\"-1\">".$cgi->param('src')."</font>\n";
            print "        </td>\n";
            print "      </tr>\n";            
            if ( $shost ) {
                print "      <tr>\n";
                print "        <td align=\"right\" width=\"40%\" colspan=3>\n";
                print "          <br>\n";
                print "        </td>\n";
                print "        <td align=\"left\" width=\"60%\">\n";
                print "          <font size=\"-1\">".$shost."</font>\n";
                print "        </td>\n";
                print "      </tr>\n";   
            }             
            print "      <tr>\n";
            print "        <td align=\"right\" width=\"30%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <th align=\"left\" width=\"10%\">\n";
            print "          <font size=\"-1\"><i>Destination</i>:</font>\n";
            print "        </th>\n";
            print "        <td align=\"left\" width=\"10%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <td align=\"left\" width=\"60%\">\n";
            print "          <font size=\"-1\">".$cgi->param('dst')."</font>\n";
            print "        </td>\n";
            print "      </tr>\n";
            if ( $dhost ) {
                print "      <tr>\n";
                print "        <td align=\"right\" width=\"40%\" colspan=3>\n";
                print "          <br>\n";
                print "        </td>\n";
                print "        <td align=\"left\" width=\"60%\">\n";
                print "          <font size=\"-1\">".$dhost."</font>\n";
                print "        </td>\n";
                print "      </tr>\n";   
            }   
            print "    </table>\n";
        }
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

