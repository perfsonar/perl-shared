#!/usr/bin/perl -w

use strict;
use warnings;

=head1 NAME

cache.pl - Build a cache of information from the global gLS infrastructure

=head1 DESCRIPTION

Contact the gLS's to gain a list of hLS instances (for now double up to be sure
we get things that may not have spun yet).  After this, contact each and get a
list of services.  Store the list in text files where they can be used by other
applications.

=cut

use XML::LibXML;
use Carp;
use Getopt::Long;
use Data::Dumper;
use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw( is_domain );
use Net::IPv6Addr;
use Net::CIDR;

use lib "/home/zurawski/perfSONAR-PS/lib";
#use lib "/usr/local/perfSONAR-PS/lib";

use perfSONAR_PS::Common qw( extract find unescapeString escapeString );
use perfSONAR_PS::Client::gLS;

my $DEBUGFLAG   = q{};
my $HELP        = q{};

my $status = GetOptions(
    'verbose'   => \$DEBUGFLAG,
    'help'      => \$HELP
);

if ( $HELP ) {
    print "$0: starts the gLS cache script.\n";
    print "\t$0 [--verbose --help]\n";
    exit(1);
}

my $parser = XML::LibXML->new();
my $hints  = "http://www.perfsonar.net/gls.root.hint";

my @private_list = ( "10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16" );

#my $base   = "/var/lib/hLS/cache";
my $base   = "/home/zurawski/perfSONAR-PS/client/cgi/perfAdmin/cache";

my %hls = ();
my %matrix1 = ();
my %matrix2 = ();
my $gls = perfSONAR_PS::Client::gLS->new( { url => $hints } );

croak "roots not found" unless ( $#{ $gls->{ROOTS} } > -1 );

for my $root ( @{ $gls->{ROOTS} } ) {
    print "Root:\t" , $root , "\n" if $DEBUGFLAG;
    my $result = $gls->getLSQueryRaw(
        {
            ls => $root,
            xquery => "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"; \ndeclare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n/nmwg:store[\@type=\"LSStore\"]/nmwg:metadata[./perfsonar:subject/psservice:service/psservice:serviceType[text()=\"LS\" or text()=\"hLS\" or text()=\"ls\" or text()=\"hls\"]]"
        }
    );
    if ( exists $result->{eventType} and not( $result->{eventType} =~ m/^error/ ) ) {
        print "\tEventType:\t" , $result->{eventType} , "\n" if $DEBUGFLAG;
        my $doc = $parser->parse_string( $result->{response} ) if exists $result->{response};
        my $service = find( $doc->getDocumentElement, ".//*[local-name()='service']", 0 );

        foreach my $s ( $service->get_nodelist ) {

            my $accessPoint = extract( find( $s, ".//*[local-name()='accessPoint']", 1 ), 0 );
            my $serviceName = extract( find( $s, ".//*[local-name()='serviceName']", 1 ), 0 );
            my $serviceType = extract( find( $s, ".//*[local-name()='serviceType']", 1 ), 0 );
            my $serviceDescription = extract( find( $s, ".//*[local-name()='serviceDescription']", 1 ), 0 );

            if ( $accessPoint ) {
                print "\t\thLS:\t" , $accessPoint , "\n" if $DEBUGFLAG;
                my $test = $accessPoint;
                $test =~ s/^http:\/\///;
                my ( $unt_test ) = $test =~ /^(.+):/;
                if ( $unt_test and is_ipv4( $unt_test ) ) {
                    if ( Net::CIDR::cidrlookup( $unt_test, @private_list ) ) {
                        print "\t\t\tReject:\t" , $unt_test , "\n" if $DEBUGFLAG;
                    }
                    else {
                        $hls{$accessPoint}{"INFO"} = $accessPoint."|".$serviceName."|".$serviceType."|".$serviceDescription;
                        $matrix1{$root}{$accessPoint} = 1;
                    }
                }
                elsif ( $unt_test and &Net::IPv6Addr::is_ipv6( $unt_test ) ) {
                    # do noting (for now)
                    $hls{$accessPoint}{"INFO"} = $accessPoint."|".$serviceName."|".$serviceType."|".$serviceDescription;
                    $matrix1{$root}{$accessPoint} = 1;
                }
                else {
                    if ( is_domain( $unt_test ) ) {
                        if ( $unt_test =~ m/^localhost/ ) {
                            print "\t\t\tReject:\t" , $unt_test , "\n" if $DEBUGFLAG;
                        }
                        else {
                            $hls{$accessPoint}{"INFO"} = $accessPoint."|".$serviceName."|".$serviceType."|".$serviceDescription;
                            $matrix1{$root}{$accessPoint} = 1;
                        }  
                    }
                    else {
                        print "\t\t\tReject:\t" , $unt_test , "\n" if $DEBUGFLAG;
                    }
                }
            }
        }
    }
    else {
        if ( $DEBUGFLAG ) {
            print "\tResult:\t" , Dumper($result) , "\n";
        }
    }
}

print "\n" if $DEBUGFLAG;

my %list = ();
my %dups = ();
foreach my $h ( keys %hls ) {
    print "hLS:\t" , $h , "\n" if $DEBUGFLAG;

    my $ls = new perfSONAR_PS::Client::LS( { instance => $h } );
    my $result = $ls->queryRequestLS(
        {
            query     => "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"; \ndeclare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n/nmwg:store[\@type=\"LSStore\"]\n",
            eventType => "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0",
            format    => 1
        }
    );

    if ( exists $result->{eventType} and $result->{eventType} eq "error.ls.query.ls_output_not_accepted" ) {
        # java hLS case...

        # XXX: JZ 10/13
        #
        # Need to use this eT:
        #
        # http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0

        $result = $ls->queryRequestLS(
            {
                query     => "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"; \ndeclare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n/nmwg:store[\@type=\"LSStore\"]\n",
                eventType => "http://ogf.org/ns/nmwg/tools/org/perfsonar/service/lookup/discovery/xquery/2.0"
            }
        );
    }
    
    if ( exists $result->{eventType} and not( $result->{eventType} =~ m/^error/ ) ) {
        print "\tEventType:\t" , $result->{eventType} , "\n" if $DEBUGFLAG;
        $result->{response} = unescapeString( $result->{response} );

        my $doc = $parser->parse_string( $result->{response} ) if exists $result->{response};

        my $md = find( $doc->getDocumentElement, "./nmwg:store/nmwg:metadata", 0 );
        my $d  = find( $doc->getDocumentElement, "./nmwg:store/nmwg:data",     0 );
        my %keywords = ();
        foreach my $m1 ( $md->get_nodelist ) {
            my $id = $m1->getAttribute("id");
            
            my $contactPoint = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='accessPoint']", 1 ), 0 );
            unless ( $contactPoint ) {
                $contactPoint = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='address']", 1 ), 0 );
                next unless $contactPoint;
            }
            my $serviceName = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='serviceName']", 1 ), 0 );
            unless ( $serviceName ) {
                $serviceName = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='name']", 1 ), 0 );
            }
            my $serviceType = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='serviceType']", 1 ), 0 );
            unless ( $serviceType ) {
                $serviceType = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='type']", 1 ), 0 );
            }
            my $serviceDescription = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='serviceDescription']", 1 ), 0 );
            unless ( $serviceDescription ) {
                $serviceDescription = extract( find( $m1, "./*[local-name()='subject']//*[local-name()='description']", 1 ), 0 );
            }

            foreach my $d1 ( $d->get_nodelist ) {
                my $metadataIdRef = $d1->getAttribute("metadataIdRef");
                next unless $id eq $metadataIdRef;

                # get the keywords
                my $keywords = find( $d1, "./nmwg:metadata/summary:parameters/nmwg:parameter", 0 );
                foreach my $k ( $keywords->get_nodelist ) {
                    my $name = $k->getAttribute("name");
                    next unless $name eq "keyword";
                    my $value = extract( $k, 0 );
                    if ( $value ) {
                        $keywords{$value} = 1;
                    }
                }

                # get the eventTypes
                my $eventTypes = find( $d1, "./nmwg:metadata/nmwg:eventType", 0 );
                foreach my $e ( $eventTypes->get_nodelist ) {
                    my $value = extract( $e, 0 );
                    if ( $value ) {
 
                        if ( $value eq "http://ggf.org/ns/nmwg/tools/snmp/2.0" ) {
                            $value = "http://ggf.org/ns/nmwg/characteristic/utilization/2.0";
                        }
                        if ( $value eq "http://ggf.org/ns/nmwg/tools/pinger/2.0/" ) {
                            $value = "http://ggf.org/ns/nmwg/tools/pinger/2.0";
                        }
                        if ( $value eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0" ) {
                            $value = "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0";
                        }
                        if ( $value eq "http://ggf.org/ns/nmwg/tools/iperf/2.0" ) {
                            $value = "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0";
                        }

# we should be tracking things here, eliminate duplicates
                        unless ( exists $dups{$value}{$contactPoint} and $dups{$value}{$contactPoint} ) {
                            $dups{$value}{$contactPoint} = 1;
                            $matrix2{$h}{$contactPoint} = 1;

                            if ( exists $list{$value} ) {
                                push @{ $list{$value} }, { CONTACT => $contactPoint, NAME => $serviceName, TYPE => $serviceType, DESC => $serviceDescription };
                            }
                            else {
                                my @temp = ( { CONTACT => $contactPoint, NAME => $serviceName, TYPE => $serviceType, DESC => $serviceDescription } );
                                $list{$value} = \@temp;
                            }

                        }
                    }
                }
                last;
            }
        }
        
        # store the keywords
        $hls{$h}{"KEYWORDS"} = \%keywords;    
    }
    else {
        delete $hls{$h};
        if ( $DEBUGFLAG ) {
            print "\tResult:\t" , Dumper($result) , "\n";
        }
    }
}

open( FILE, ">" . $base . "/list.glsmap" ) or croak "can't open glsmap list";
foreach my $g ( keys %matrix1 ) {
    print FILE $g;
    my $counter = 0;
    foreach my $h ( keys %{ $matrix1{ $g } } ) {
        if ( $counter ) {
            print FILE "," , $h;
        }
        else {
            print FILE "|" , $h;
        }
        $counter++;
    }
    print FILE "\n";
}
close(FILE);

open( FILE2, ">" . $base . "/list.hlsmap" ) or croak "can't open hls list";
foreach my $h ( keys %matrix2 ) {
    print FILE2 $h;
    my $counter = 0;
    foreach my $s ( keys %{ $matrix2{ $h } } ) {
        if ( $counter ) {
            print FILE2 "," , $s;
        }
        else {
            print FILE2 "|" , $s;
        }
        $counter++;
    }
    print FILE2 "\n";
}
close(FILE2);

# should we do some verification/validation here?
open( HLS, ">" . $base . "/list.hls" ) or croak "can't open hls list";
foreach my $h ( keys %hls ) {
    print HLS $hls{$h}{"INFO"};
    if ( exists $hls{$h}{"KEYWORDS"} and $hls{$h}{"KEYWORDS"} ) {
        my $counter = 0;
        foreach my $k ( keys %{ $hls{$h}{"KEYWORDS"} } ) {
            if( $counter ) {
                print HLS "," , $k;
            }
            else {
                print HLS "|" , $k;
            }
            $counter++;
        }
    }
    print HLS "\n";
}
close(HLS);

my %counter = ();
foreach my $et ( keys %list ) {
    my $file = q{};
    if ( $et eq "http://ggf.org/ns/nmwg/characteristic/utilization/2.0" or $et eq "http://ggf.org/ns/nmwg/tools/snmp/2.0" ) {
        $file = "list.snmpma";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/pinger/2.0/" or $et eq "http://ggf.org/ns/nmwg/tools/pinger/2.0" ) {
        $file = "list.pinger";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/acheiveable/2.0" or $et eq "http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0" or $et eq "http://ggf.org/ns/nmwg/tools/iperf/2.0" ) {
        $file = "list.psb.bwctl";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/owamp/2.0" ) {
        $file = "list.psb.owamp";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/bwctl/1.0" ) {
        $file = "list.bwctl";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/traceroute/1.0" ) {
        $file = "list.traceroute";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/npad/1.0" ) {
        $file = "list.npad";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/ndt/1.0" ) {
        $file = "list.ndt";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/owamp/1.0" ) {
        $file = "list.owamp";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/ping/1.0" ) {
        $file = "list.ping";
    }
    elsif ( $et eq "http://ggf.org/ns/nmwg/tools/phoebus/1.0" ) {
        $file = "list.phoebus";
    }
    next unless $file;

    my $writetype = ">";
    $writetype = ">>" if exists $counter{$file};
    $counter{$file} = 1;

    open( OUT, $writetype . $base . "/" . $file ) or croak "can't open $base/$file.";
    foreach my $host ( @{ $list{$et} } ) {
        print OUT $host->{"CONTACT"}, "|";
        print OUT $host->{"NAME"} if $host->{"NAME"};
        print OUT "|";
        print OUT $host->{"TYPE"} if $host->{"TYPE"};
        print OUT "|";
        print OUT $host->{"DESC"} if $host->{"DESC"};
        print OUT "\n";
        print $file , " - " ,$host->{"CONTACT"} , "\n" if $DEBUGFLAG;
    }
    close(OUT);


}

=head1 SEE ALSO

L<XML::LibXML>, L<perfSONAR_PS::Common>, L<perfSONAR_PS::Client::gLS>

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

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

