#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

serviceTest.cgi - Test out a perfSONAR service (usually a MA) by doing a simple
query and attempting the visualize data (where applicable).

=head1 DESCRIPTION

Perform a metadata key request on a service and offer the ability to graph (if
available for the data type).  

=cut

use CGI;
use HTML::Template;
use XML::LibXML;
use Socket;
use Data::Validate::IP qw(is_ipv4);
use Net::IPv6Addr;

# change this to the location where you install perfSONAR-PS

use lib "/home/jason/RELEASE/RELEASE_3.1/Shared/lib";
#use lib "/usr/local/perfSONAR-PS/lib";

use perfSONAR_PS::Client::MA;
use perfSONAR_PS::Common qw( extract find );

my $template = q{};
my $cgi = CGI->new();
print $cgi->header();

my $service;
if ( $cgi->param('url') ) {
    $service = $cgi->param('url');
}
else {
    $template = HTML::Template->new( filename => "etc/serviceTest_error.tmpl" );
    $template->param( 
        ERROR => "Service URL not provided."
    );
    print $template->output;
    exit(1);
}

my $eventType;
if ( $cgi->param('eventType') ) {
    $eventType = $cgi->param('eventType');
    $eventType =~ s/(\s|\n)*//g;
}
else {
    $template = HTML::Template->new( filename => "etc/serviceTest_error.tmpl" );
    $template->param( 
        ERROR => "Service eventType not provided."
    );
    print $template->output;
    exit(1);
}

my $ma = new perfSONAR_PS::Client::MA( { instance => $service } );

my $subject;
my @eventTypes = ();
push @eventTypes, $eventType;
if ( $eventType eq "http://ggf.org/ns/nmwg/characteristic/utilization/2.0" ) {
    $subject = "    <netutil:subject xmlns:netutil=\"http://ggf.org/ns/nmwg/characteristic/utilization/2.0/\" id=\"s\">\n";
    $subject .= "      <nmwgt:interface xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
    $subject .= "    </netutil:subject>\n";
}
elsif ( $eventType eq "http://ggf.org/ns/nmwg/tools/iperf/2.0" or $eventType eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0" or $eventType eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0" ) {
    $subject = "    <iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0/\" id=\"subject\">\n";
    $subject .= "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
    $subject .= "    </iperf:subject>\n";
}
elsif ( $eventType eq "http://ggf.org/ns/nmwg/tools/owamp/2.0" or $eventType eq "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921" ) {
    $subject = "    <owamp:subject xmlns:owamp=\"http://ggf.org/ns/nmwg/tools/owamp/2.0/\" id=\"subject\">\n";
    $subject .= "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
    $subject .= "    </owamp:subject>\n";
}
elsif ( $eventType eq "http://ggf.org/ns/nmwg/tools/pinger/2.0/" or $eventType eq "http://ggf.org/ns/nmwg/tools/pinger/2.0" ) {
    $subject = "    <pinger:subject xmlns:pinger=\"http://ggf.org/ns/nmwg/tools/pinger/2.0/\" id=\"subject\">\n";
    $subject .= "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\" />\n";
    $subject .= "    </pinger:subject>\n";
}
else {
    $template = HTML::Template->new( filename => "etc/serviceTest_error.tmpl" );
    $template->param( 
        ERROR => "Unrecognized eventType: \"" . $eventType . "\"."
    );
    print $template->output;
    exit(1);
}

my $parser = XML::LibXML->new();
my $result = $ma->metadataKeyRequest(
    {
        subject    => $subject,
        eventTypes => \@eventTypes
    }
);

unless ( $#{ $result->{"metadata"} } > -1 ) {
    $template = HTML::Template->new( filename => "etc/serviceTest_error.tmpl" );
    $template->param( 
        ERROR => "MA <b><i>" . $service . "</i></b> experienced an error, is it functioning?"
    );
    print $template->output;
    exit(1);
}

my $metadata = $parser->parse_string( $result->{"metadata"}->[0] );
my $et = extract( find( $metadata->getDocumentElement, ".//nmwg:eventType", 1 ), 0 );

if ( $et eq "error.ma.storage" ) {
    $template = HTML::Template->new( filename => "etc/serviceTest_error.tmpl" );
    $template->param( 
        ERROR => "MA <b><i>" . $service . "</i></b> experienced an error, be sure it is configured and populated with data."
    );
}
else {
    if ( $eventType eq "http://ggf.org/ns/nmwg/characteristic/utilization/2.0" ) {
        $template = HTML::Template->new( filename => "etc/serviceTest_utilization.tmpl" );

        my %lookup = ();
        foreach my $d ( @{ $result->{"data"} } ) {
            my $data          = $parser->parse_string($d);
            my $metadataIdRef = $data->getDocumentElement->getAttribute("metadataIdRef");
            my $key           = extract( find( $data->getDocumentElement, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
            if ( $key ) {
                $lookup{$metadataIdRef}{"key1"} = $key if $metadataIdRef;
                $lookup{$metadataIdRef}{"key2"} = "";
                $lookup{$metadataIdRef}{"type"} = "key";
            }
            else {
                $key = extract( find( $data->getDocumentElement, ".//nmwg:parameter[\@name=\"file\"]", 1 ), 0 );
                $lookup{$metadataIdRef}{"key1"} = $key if $key and $metadataIdRef;
                $key = extract( find( $data->getDocumentElement, ".//nmwg:parameter[\@name=\"dataSource\"]", 1 ), 0 );
                $lookup{$metadataIdRef}{"key2"} = $key if $key and $metadataIdRef;
                $lookup{$metadataIdRef}{"type"} = "nonkey";
            }
        }

        my %list = ();
        foreach my $md ( @{ $result->{"metadata"} } ) {
            my $metadata   = $parser->parse_string($md);
            my $metadataId = $metadata->getDocumentElement->getAttribute("id");
            my $dir        = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:direction", 1 ), 0 );
            my $host       = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:hostName", 1 ), 0 );
            my $name       = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:ifName", 1 ), 0 );
            if ( $list{$host}{$name} ) {
                if ( $dir eq "in" ) {
                    $list{$host}{$name}->{"key1_1"} = $lookup{$metadataId}{"key1"};
                    $list{$host}{$name}->{"key1_2"} = $lookup{$metadataId}{"key2"};
                    $list{$host}{$name}->{"key1_type"} = $lookup{$metadataId}{"type"};
                }
                else {
                    $list{$host}{$name}->{"key2_1"} = $lookup{$metadataId}{"key1"};
                    $list{$host}{$name}->{"key2_2"} = $lookup{$metadataId}{"key2"};
                    $list{$host}{$name}->{"key2_type"} = $lookup{$metadataId}{"type"};
                }
            }
            else {
                my %temp = ();
                if ( $dir eq "in" ) {
                    $temp{"key1_1"} = $lookup{$metadataId}{"key1"};
                    $temp{"key1_2"} = $lookup{$metadataId}{"key2"};
                    $temp{"key1_type"} = $lookup{$metadataId}{"type"};                    
                }
                else {
                    $temp{"key2_1"} = $lookup{$metadataId}{"key1"};
                    $temp{"key2_2"} = $lookup{$metadataId}{"key2"};
                    $temp{"key2_type"} = $lookup{$metadataId}{"type"};
                }
                $temp{"hostName"}      = $host;
                $temp{"ifName"}        = $name;
                $temp{"ifIndex"}       = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:ifIndex", 1 ), 0 );
                $temp{"ipAddress"}     = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:ipAddress", 1 ), 0 );
                $temp{"ifDescription"} = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:ifDescription", 1 ), 0 );
                unless ( exists $temp{"ifDescription"} and $temp{"ifDescription"} ) {
                    $temp{"ifDescription"} = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:description", 1 ), 0 );
                }
                $temp{"ifAddress"}     = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:ifAddress", 1 ), 0 );
                $temp{"capacity"}      = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:interface/nmwgt:capacity", 1 ), 0 );
                
                if ( $temp{"capacity"} ) {
                    $temp{"capacity"} /= 1000000;
                    if ( $temp{"capacity"} < 1000 ) {
                        $temp{"capacity"} .= " Mbps";
                    }
                    elsif ( $temp{"capacity"} < 1000000 ) {
                        $temp{"capacity"} /= 1000;
                        $temp{"capacity"} .= " Gbps";
                    }
                    elsif ( $temp{"capacity"} < 1000000000 ) {
                        $temp{"capacity"} /= 1000000;
                        $temp{"capacity"} .= " Tbps";
                    }
                }                
                $list{$host}{$name}    = \%temp;
            }
        }

        my @interfaces = ();
        my $counter = 0;
        foreach my $host ( sort keys %list ) {
            foreach my $name ( sort keys %{ $list{$host} } ) {

                    push @interfaces, { ADDRESS => $list{$host}{$name}->{"ipAddress"}, HOST => $list{$host}{$name}->{"hostName"}, IFNAME => $list{$host}{$name}->{"ifName"}, IFINDEX => $list{$host}{$name}->{"ifIndex"}, DESC => $list{$host}{$name}->{"ifDescription"}, IFADDRESS => $list{$host}{$name}->{"ifAddress"}, CAPACITY => $list{$host}{$name}->{"capacity"}, KEY1TYPE => $list{$host}{$name}->{"key1_type"}, KEY11 => $list{$host}{$name}->{"key1_1"}, KEY12 => $list{$host}{$name}->{"key1_2"}, KEY2TYPE => $list{$host}{$name}->{"key2_type"}, KEY21 => $list{$host}{$name}->{"key2_1"}, KEY22 => $list{$host}{$name}->{"key2_2"}, COUNT => $counter, SERVICE => $service };

                $counter++;
            }
        }

        $template->param( 
            EVENTTYPE => $eventType,
            SERVICE => $service,
            INTERFACES => \@interfaces
        );

    }
    elsif ( $eventType eq "http://ggf.org/ns/nmwg/tools/iperf/2.0" or $eventType eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0" or $eventType eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0" ) {
        $template = HTML::Template->new( filename => "etc/serviceTest_psb_bwctl.tmpl" );


        my %lookup = ();
        foreach my $d ( @{ $result->{"data"} } ) {
            my $data          = $parser->parse_string($d);
            my $metadataIdRef = $data->getDocumentElement->getAttribute("metadataIdRef");
            my $key           = extract( find( $data->getDocumentElement, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
            $lookup{$metadataIdRef} = $key if $key and $metadataIdRef;
        }

        my %list = ();
        foreach my $md ( @{ $result->{"metadata"} } ) {
            my $metadata   = $parser->parse_string($md);
            my $metadataId = $metadata->getDocumentElement->getAttribute("id");

            my $src  = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:endPointPair/nmwgt:src", 1 ), 0 );
            my $saddr;
            my $shost;
            if ( is_ipv4( $src ) ) {
                $saddr = $src;
                my $iaddr = Socket::inet_aton( $src );
                if ( defined $iaddr and $iaddr ) {
                    $shost = gethostbyaddr( $iaddr, Socket::AF_INET );
                }
            }
            elsif ( &Net::IPv6Addr::is_ipv6( $src ) ) {
                $saddr = $src;
                $shost = $src;
                # do something?
            }
            else {
                $shost = $src;
                my $packed_ip = gethostbyname( $src );
                if ( defined $packed_ip and $packed_ip ) {
                    $saddr = inet_ntoa( $packed_ip );
                }
            }
                                
            my $dst  = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:endPointPair/nmwgt:dst", 1 ), 0 );
            my $daddr;
            my $dhost;
            if ( is_ipv4( $dst ) ) {
                $daddr = $dst;
                my $iaddr = Socket::inet_aton( $dst );
                if ( defined $iaddr and $iaddr ) {
                    $dhost = gethostbyaddr( $iaddr, Socket::AF_INET );
                }
            }
            elsif ( &Net::IPv6Addr::is_ipv6( $dst ) ) {
                $daddr = $dst;
                $dhost = $dst;
                # do something?
            }
            else {
                $dhost = $dst;
                my $packed_ip = gethostbyname( $dst );
                if ( defined $packed_ip and $packed_ip ) {
                    $daddr = inet_ntoa( $packed_ip );
                }
            }

            my $type = extract( find( $metadata->getDocumentElement, "./*[local-name()='parameters']/*[local-name()='parameter' and \@name=\"protocol\"]", 1 ), 0 );
            
            my %temp = ();
            $temp{"key"}     = $lookup{$metadataId};
            $temp{"src"}     = $shost;
            $temp{"dst"}     = $dhost;
            $temp{"saddr"}   = $saddr;
            $temp{"daddr"}   = $daddr;
            if ( $type ) {
                $temp{"type"}    = $type;
                $list{$shost}{$dhost}{$type} = \%temp;
            }
            else {
                $list{$shost}{$dhost} = \%temp;
            }
        }

        my @pairs = ();
        my %mark = ();
        my $counter = 0;
        foreach my $src ( sort keys %list ) {     
            foreach my $dst ( sort keys %{ $list{$src} } ) {
                next if exists $mark{$src}{$dst} and $mark{$src}{$dst};
                if ( exists $list{$src}{$dst}->{"src"} and exists $list{$src}{$dst}->{"dst"} and exists $list{$src}{$dst}->{"key"} ) {
                    $mark{$dst}{$src} = 1 if exists $list{$dst}{$src}->{"key"} and $list{$dst}{$src}->{"key"};
                    push @pairs, { SADDRESS => $list{$src}{$dst}->{"saddr"}, SHOST => $list{$src}{$dst}->{"src"}, DADDRESS => $list{$src}{$dst}->{"daddr"}, DHOST => $list{$src}{$dst}->{"dst"}, PROTOCOL => $list{$src}{$dst}->{"type"}, KEY => $list{$src}{$dst}->{"key"}, KEY2 => $list{$dst}{$src}->{"key"}, COUNT => $counter, SERVICE => $service };
                    $counter++;
                }
                else {
                    foreach my $type ( sort keys %{ $list{$src}{$dst} } ) {
                        $mark{$dst}{$src} = 1 if exists $list{$dst}{$src}->{"key"} and $list{$dst}{$src}->{"key"};
                        push @pairs, { SADDRESS => $list{$src}{$dst}->{"saddr"}, SHOST => $list{$src}{$dst}->{"src"}, DADDRESS => $list{$src}{$dst}{$type}->{"daddr"}, DHOST => $list{$src}{$dst}{$type}->{"dst"}, PROTOCOL => $list{$src}{$dst}{$type}->{"type"}, KEY => $list{$src}{$dst}{$type}->{"key"}, KEY2 => $list{$dst}{$src}->{"key"}, COUNT => $counter, SERVICE => $service };
                        $counter++;
                    }
                }
            }
        }

        $template->param( 
            EVENTTYPE => $eventType,
            SERVICE => $service,
            PAIRS => \@pairs
        );
    }
    elsif ( $eventType eq "http://ggf.org/ns/nmwg/tools/owamp/2.0" or $eventType eq "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921" ) {
        $template = HTML::Template->new( filename => "etc/serviceTest_psb_owamp.tmpl" );

        my %lookup = ();
        foreach my $d ( @{ $result->{"data"} } ) {
            my $data          = $parser->parse_string($d);
            my $metadataIdRef = $data->getDocumentElement->getAttribute("metadataIdRef");
            my $key           = extract( find( $data->getDocumentElement, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
            $lookup{$metadataIdRef} = $key if $key and $metadataIdRef;
        }

        my %list = ();
        foreach my $md ( @{ $result->{"metadata"} } ) {
            my $metadata   = $parser->parse_string($md);
            my $metadataId = $metadata->getDocumentElement->getAttribute("id");

            my $src = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:endPointPair/nmwgt:src", 1 ), 0 );
            my $dst = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:endPointPair/nmwgt:dst", 1 ), 0 );

            my %temp = ();
            $temp{"key"}      = $lookup{$metadataId};
            $temp{"src"}      = $src;
            $temp{"dst"}      = $dst;
            $list{$src}{$dst} = \%temp;
        }

        my @pairs = ();
        my $counter = 0;
        foreach my $src ( sort keys %list ) {
            foreach my $dst ( sort keys %{ $list{$src} } ) {
            
                my $display = $list{$src}{$dst}->{"src"};
                $display =~ s/:.*$//;
                my $iaddr = Socket::inet_aton( $display );
                my $shost = gethostbyaddr( $iaddr, Socket::AF_INET );
                $shost = $list{$src}{$dst}->{"src"} unless $shost;

                $display = $list{$src}{$dst}->{"dst"};
                $display =~ s/:.*$//;
                $iaddr = Socket::inet_aton( $display );
                my $dhost = gethostbyaddr( $iaddr, Socket::AF_INET );
                $dhost = $list{$src}{$dst}->{"dst"} unless $dhost;
                                            
                push @pairs, { SADDRESS => $list{$src}{$dst}->{"src"}, SHOST => $shost, DADDRESS => $list{$src}{$dst}->{"dst"}, DHOST => $dhost, KEY => $list{$src}{$dst}->{"key"}, COUNT => $counter, SERVICE => $service };
                $counter++;
            }
        }

        $template->param( 
            EVENTTYPE => $eventType,
            SERVICE => $service,
            PAIRS => \@pairs
        );
    }
    elsif ( $eventType eq "http://ggf.org/ns/nmwg/tools/pinger/2.0/" or $eventType eq "http://ggf.org/ns/nmwg/tools/pinger/2.0" ) {
        $template = HTML::Template->new( filename => "etc/serviceTest_pinger.tmpl" );

        my %lookup = ();
        foreach my $d ( @{ $result->{"data"} } ) {
            my $data          = $parser->parse_string($d);
            my $metadataIdRef = $data->getDocumentElement->getAttribute("metadataIdRef");
            my $key           = extract( find( $data->getDocumentElement, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
            $lookup{$metadataIdRef} = $key if $key and $metadataIdRef;
        }

        my %list = ();
        foreach my $md ( @{ $result->{"metadata"} } ) {
            my $metadata   = $parser->parse_string($md);
            my $metadataId = $metadata->getDocumentElement->getAttribute("id");

            my $src = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:endPointPair/nmwgt:src", 1 ), 0 );
            my $dst = extract( find( $metadata->getDocumentElement, "./*[local-name()='subject']/nmwgt:endPointPair/nmwgt:dst", 1 ), 0 );
            my $packetsize = extract( find( $metadata->getDocumentElement, "./*[local-name()='parameters']/nmwg:parameter[\@name=\"packetSize\"]", 1 ), 0 );

            my %temp = ();
            $temp{"key"}      = $lookup{$metadataId};
            $temp{"src"}      = $src;
            $temp{"dst"}      = $dst;
	    $temp{"packetsize"} = $packetsize?$packetsize:1000;  
            $list{$src}{$dst} = \%temp;
        }

        my @pairs = ();
        my $counter = 0;
        foreach my $src ( sort keys %list ) {
            foreach my $dst ( sort keys %{ $list{$src} } ) {

                my $packed_ip = gethostbyname( $list{$src}{$dst}->{"src"} );
                my $sip_address = $list{$src}{$dst}->{"src"};
                $sip_address = inet_ntoa( $packed_ip ) if defined $packed_ip;
                
                $packed_ip = gethostbyname( $list{$src}{$dst}->{"dst"} );
                my $dip_address = $list{$src}{$dst}->{"dst"};
                $dip_address = inet_ntoa( $packed_ip ) if defined $packed_ip;
                
                my $present = 0;
                $present++ if -f "./pinger/index.cgi";

                my $p_time = time - 43200;
                my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime($p_time);
                my $p_start = sprintf "%04d-%02d-%02dT%02d:%02d:%02d", ( $year + 1900 ), ( $mon + 1 ), $mday, $hour, $min, $sec;
                $p_time += 43200;
                ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = gmtime($p_time);
                my $p_end = sprintf "%04d-%02d-%02dT%02d:%02d:%02d", ( $year + 1900 ), ( $mon + 1 ), $mday, $hour, $min, $sec;
                                            
                push @pairs, { PACKETSIZE => $list{$src}{$dst}->{"packetsize"}, SHOST => $list{$src}{$dst}->{"src"}, SADDRESS => $sip_address, DHOST => $list{$src}{$dst}->{"dst"}, DADDRESS => $dip_address, COUNT => $counter, SERVICE => $service, PRESENT => $present, STARTTIME => $p_start, ENDTIME => $p_end };
                $counter++;
            }
        }

        $template->param( 
            EVENTTYPE => $eventType,
            SERVICE => $service,
            PAIRS => \@pairs
        );
    }
    else {
        $template = HTML::Template->new( filename => "etc/serviceTest_error.tmpl" );
        $template->param( 
            ERROR => "Unrecognized eventType: \"" . $eventType . "\"."
        );
    }
}

print $template->output;

__END__

=head1 SEE ALSO

L<C>

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
