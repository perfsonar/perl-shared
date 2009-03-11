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

    my $time = 86400;
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

    my %store = ();
    my $counter = 0;
    if ( $datum1 ) {
        foreach my $dt ( $datum1->get_nodelist ) {
            $counter++;
        }

        foreach my $dt ( $datum1->get_nodelist ) {
            my $secs = UnixDate( $dt->getAttribute("timeValue"), "%s" );
            $store{$secs} = eval( $dt->getAttribute("throughput") ) if $secs and $dt->getAttribute("throughput");
        }
    }

    print "<html>\n";
    print "  <head>\n";
    print "    <title>perfSONAR-PS perfAdmin Bandwidth Graph";
    if ( $cgi->param('type') ) {
        print " ".$cgi->param('type');
    }
    print "</title>\n";

    if ( scalar keys %store > 0 ) {
        print "    <script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n";
        print "    <script type=\"text/javascript\">\n";
        print "      google.load(\"visualization\", \"1\", {packages:[\"areachart\"]})\n";
        print "      google.setOnLoadCallback(drawChart);\n";
        print "      function drawChart() {\n";
        print "        var data = new google.visualization.DataTable();\n";
        print "        data.addColumn('date', 'Time');\n";
        print "        data.addColumn('number', 'Bandwidth');\n";

        my $doc1 = $parser->parse_string( $result->{"data"}->[0] );
        my $datum1 = find( $doc1->getDocumentElement, "./*[local-name()='datum']", 0 );

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
            print "        data.setValue(" . $counter . ", 1, " . $store{$time} . ");\n" if $store{$time};
            $counter++;
        }

        print "        var chart = new google.visualization.AreaChart(document.getElementById('chart_div'));\n";
        print "        chart.draw(data, {width: 900, height: 400, legend: 'bottom', title: 'Bandwidth'});\n";
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

