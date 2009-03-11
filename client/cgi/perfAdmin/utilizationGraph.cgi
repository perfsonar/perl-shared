#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

utilizationGraph.cgi - CGI script that graphs the output of a perfSONAR MA that
delivers utilization data.  

=head1 DESCRIPTION

Given a url of an MA, and a key value (corresponds to a specific pair [in and
out] of utilization results) graph using the Google graph API.

=cut

use CGI;
use XML::LibXML;
use Date::Manip;
use Socket;
use POSIX;
use Data::Validate::IP qw(is_ipv4);

use lib "/home/zurawski/perfSONAR-PS/lib";
#use lib "/usr/local/perfSONAR-PS/lib";

use perfSONAR_PS::Client::MA;
use perfSONAR_PS::Common qw( extract find );

my $cgi = new CGI;
print "Content-type: text/html\n\n";

if ( ( $cgi->param('key1_type') or $cgi->param('key2_type') ) and $cgi->param('url') ) {

    my $ma = new perfSONAR_PS::Client::MA( { instance => $cgi->param('url') } );

    my @eventTypes = ();
    my $parser     = XML::LibXML->new();
    my ( $sec, $frac ) = Time::HiRes::gettimeofday;

    # 'in' data
    my $subject = q{};
    if ( $cgi->param('key1_type') eq "key" ) {
        $subject = "  <nmwg:key id=\"key-1\">\n";
        $subject .= "    <nmwg:parameters id=\"parameters-key-1\">\n";
        $subject .= "      <nmwg:parameter name=\"maKey\">" . $cgi->param('key1_1') . "</nmwg:parameter>\n";
        $subject .= "    </nmwg:parameters>\n";
        $subject .= "  </nmwg:key>  \n";
    }
    else {
        $subject = "  <nmwg:key id=\"key-1\">\n";
        $subject .= "    <nmwg:parameters id=\"parameters-key-1\">\n";
        $subject .= "      <nmwg:parameter name=\"file\">" . $cgi->param('key1_1') . "</nmwg:parameter>\n";
        $subject .= "      <nmwg:parameter name=\"dataSource\">" . $cgi->param('key1_2') . "</nmwg:parameter>\n";
        $subject .= "    </nmwg:parameters>\n";
        $subject .= "  </nmwg:key>  \n";
    }

    my $time;
    if ( $cgi->param('length') ) {
        $time = $cgi->param('length');
    }
    else {
        $time = 86400;
    }

    my $res;
    if ( $cgi->param('resolution') ) {
        $res = $cgi->param('resolution');
    }
    else {
        $res = 5;
    }
    
    my $result = $ma->setupDataRequest(
        {
            start                 => ( $sec - $time ),
            end                   => $sec,
            resolution            => $res,
            consolidationFunction => "AVERAGE",
            subject               => $subject,
            eventTypes            => \@eventTypes
        }
    );

    # 'out' data
    my $subject2 = q{};
    if ( $cgi->param('key2_type') eq "key" ) {
        $subject2 = "  <nmwg:key id=\"key-2\">\n";
        $subject2 .= "    <nmwg:parameters id=\"parameters-key-2\">\n";
        $subject2 .= "      <nmwg:parameter name=\"maKey\">" . $cgi->param('key2_1') . "</nmwg:parameter>\n";
        $subject2 .= "    </nmwg:parameters>\n";
        $subject2 .= "  </nmwg:key>  \n";
    }
    else {
        $subject2 = "  <nmwg:key id=\"key-2\">\n";
        $subject2 .= "    <nmwg:parameters id=\"parameters-key-2\">\n";
        $subject2 .= "      <nmwg:parameter name=\"file\">" . $cgi->param('key2_1') . "</nmwg:parameter>\n";
        $subject2 .= "      <nmwg:parameter name=\"dataSource\">" . $cgi->param('key2_2') . "</nmwg:parameter>\n";
        $subject2 .= "    </nmwg:parameters>\n";
        $subject2 .= "  </nmwg:key>  \n";
    }

    my $result2 = $ma->setupDataRequest(
        {
            start                 => ( $sec - $time ),
            end                   => $sec,
            resolution            => $res,
            consolidationFunction => "AVERAGE",
            subject               => $subject2,
            eventTypes            => \@eventTypes
        }
    );

    my $doc1 = $parser->parse_string( $result->{"data"}->[0] );
    my $datum1 = find( $doc1->getDocumentElement, "./*[local-name()='datum']", 0 );

    my $doc2 = $parser->parse_string( $result2->{"data"}->[0] );
    my $datum2 = find( $doc2->getDocumentElement, "./*[local-name()='datum']", 0 );

    my %store = ();
    my $counter = 0;
    if ( $datum1 and $datum2 ) {
        foreach my $dt ( $datum1->get_nodelist ) {
            $counter++;
        }

        foreach my $dt ( $datum1->get_nodelist ) {
            $store{ $dt->getAttribute("timeValue") }{"in"} = eval( $dt->getAttribute("value") );
        }
        foreach my $dt ( $datum2->get_nodelist ) {
            $store{ $dt->getAttribute("timeValue") }{"out"} = eval( $dt->getAttribute("value") );
        }
    }

    print "<html>\n";
    print "  <head>\n";
    print "    <title>perfSONAR-PS perfAdmin Utilization Graph</title>\n";
    
    if ( scalar keys %store > 0 ) {
        print "    <script type=\"text/javascript\" src=\"http://www.google.com/jsapi\"></script>\n";
        print "    <script type=\"text/javascript\">\n";
        print "      google.load(\"visualization\", \"1\", {packages:[\"areachart\"]})\n";
        print "      google.setOnLoadCallback(drawChart);\n";
        print "      function drawChart() {\n";
        print "        var data = new google.visualization.DataTable();\n";
        print "        data.addColumn('date', 'Time');\n";
        print "        data.addColumn('number', 'In');\n";
        print "        data.addColumn('number', 'Out');\n";

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
            print "        data.setValue(" . $counter . ", 1, " . $store{$time}{"in"} . ");\n"  if $store{$time}{"in"};
            print "        data.setValue(" . $counter . ", 2, " . $store{$time}{"out"} . ");\n" if $store{$time}{"out"};
            $counter++;
        }
   
        print "        var chart = new google.visualization.AreaChart(document.getElementById('chart_div'));\n";
        print "        chart.draw(data, {width: 900, height: 400, legend: 'bottom', title: 'Utilization'});\n";
        print "      }\n";
        print "    </script>\n";
        print "  </head>\n";
        print "  <body>\n";
        if ( $cgi->param('host') and $cgi->param('interface') ) {

            my $host = q{};
            if ( is_ipv4( $cgi->param('host') ) ) {
                my $iaddr = Socket::inet_aton( $cgi->param('host') );
                if ( defined $iaddr and $iaddr ) {
                    $host = gethostbyaddr( $iaddr, Socket::AF_INET );
                }
            }
            else {
                my $packed_ip = gethostbyname( $cgi->param('host') );
                if ( defined $packed_ip and $packed_ip ) {
                    $host = inet_ntoa( $packed_ip );
                }
            }
  
            print "    <table border=\"0\" cellpadding=\"0\" width=\"75%\" align=\"center\">";
            print "      <tr>\n";
            print "        <td align=\"right\" width=\"30%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <th align=\"left\" width=\"10%\">\n";
            print "          <font size=\"-1\"><i>Host</i>:</font>\n";
            print "        </th>\n";
            print "        <td align=\"left\" width=\"10%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <td align=\"left\" width=\"60%\">\n";
            print "          <font size=\"-1\">".$cgi->param('host')."</font>\n";
            print "        </td>\n";
            print "      </tr>\n";            
            if ( $host ) {
                print "      <tr>\n";
                print "        <td align=\"right\" width=\"40%\" colspan=3>\n";
                print "          <br>\n";
                print "        </td>\n";
                print "        <td align=\"left\" width=\"60%\">\n";
                print "          <font size=\"-1\">".$host."</font>\n";
                print "        </td>\n";
                print "      </tr>\n";   
            }             
            print "      <tr>\n";
            print "        <td align=\"right\" width=\"30%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <th align=\"left\" width=\"10%\">\n";
            print "          <font size=\"-1\"><i>Name</i>:</font>\n";
            print "        </th>\n";
            print "        <td align=\"left\" width=\"10%\">\n";
            print "          <br>\n";
            print "        </td>\n";
            print "        <td align=\"left\" width=\"60%\">\n";
            print "          <font size=\"-1\">".$cgi->param('interface')."</font>\n";
            print "        </td>\n";
            print "      </tr>\n";  
            print "    </table>\n";
        }
        print "    <div id=\"chart_div\"></div>\n";
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
    print "<html><head><title>perfSONAR-PS perfAdmin Utilization Graph</title></head>";
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

