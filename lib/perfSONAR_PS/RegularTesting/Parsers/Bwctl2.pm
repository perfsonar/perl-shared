package perfSONAR_PS::RegularTesting::Parsers::Bwctl2;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Bwctl2;

=head1 DESCRIPTION

A module that provides simple functions for parsing bwctl2 output.

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use JSON;
use DateTime::Format::ISO8601;

use perfSONAR_PS::RegularTesting::Parsers::Iperf      qw(parse_iperf_output);
use perfSONAR_PS::RegularTesting::Parsers::Owamp      qw(parse_owamp_raw_output);
use perfSONAR_PS::RegularTesting::Parsers::Ping       qw(parse_ping_output);
use perfSONAR_PS::RegularTesting::Parsers::Traceroute qw(parse_traceroute_output);
use perfSONAR_PS::RegularTesting::Parsers::Tracepath  qw(parse_tracepath_output);
use perfSONAR_PS::RegularTesting::Parsers::ParisTraceroute  qw(parse_paristraceroute_output);

our @EXPORT_OK = qw( parse_bwctl2_output );

my $logger = get_logger(__PACKAGE__);

use DateTime;

=head2 parse_bwctl2_output()

=cut

sub parse_bwctl2_output {
    my $parameters = validate( @_, { stdout  => 1,
                                     stderr  => 0,
                                     tool    => 0,
                                   });
    my $stdout    = $parameters->{stdout};
    my $stderr    = $parameters->{stderr};
    my $tool      = $parameters->{tool};
    
    my $bwctl_obj;
    eval {
        $bwctl_obj = JSON->new->utf8(1)->decode($stdout);
    };
    if ($@) {
        return { error => "Problem parsing BWCTL output: ".$@ };
    }
    
    my %results = ();
    $results{start_time} = DateTime::Format::ISO8601->parse_datetime($bwctl_obj->{'bwctl'}->{'requested_time'}) if($bwctl_obj->{'bwctl'}->{'requested_time'});
    $results{end_time} = DateTime::Format::ISO8601->parse_datetime($bwctl_obj->{'bwctl'}->{'end_time'}) if($bwctl_obj->{'bwctl'}->{'end_time'});
    $results{sender_address} = $bwctl_obj->{'send'}->{'address'};
    $results{receiver_address} = $bwctl_obj->{'recv'}->{'address'};
    $results{tool} = $bwctl_obj->{'bwctl'}->{'tool'};
    $results{error} = join ' ', @{$bwctl_obj->{'bwctl'}->{'errors'}} if(@{$bwctl_obj->{'bwctl'}->{'errors'}} > 0);

    if (not $results{tool}) {
        unless ($results{error}) {
            $results{error} = "Tool is not defined";
        }
    }
    elsif ($results{tool} eq "iperf") {
        $results{results} = parse_iperf_output({ stdout => $bwctl_obj->{'send'}->{'results'} });
    }
    elsif ($results{tool} eq "iperf3") {
        $results{results} = $bwctl_obj->{'send'}->{'results'};
    }
    elsif ($results{tool} eq "traceroute") {
        $results{results} = parse_traceroute_output({ stdout => $bwctl_obj->{'send'}->{'results'} });
    }
    elsif ($results{tool} eq "tracepath") {
        $results{results} = parse_tracepath_output({ stdout => $bwctl_obj->{'send'}->{'results'} });
    }
    elsif ($tool eq "paris-traceroute") {
        $results{results} = parse_paristraceroute_output({ stdout => $bwctl_obj->{'send'}->{'results'} });
    }
    elsif ($results{tool} eq "ping") {
        $results{results} = parse_ping_output({ stdout => $bwctl_obj->{'send'}->{'results'} });
    }
    elsif ($results{tool} eq "owamp") {
        $results{results} = parse_owamp_raw_output({ stdout => $bwctl_obj->{'send'}->{'results'} });
    }
    else {
        $results{error} = "Unknown tool type: " . $results{tool};
    }

    $results{raw_results} = $stdout;

    return \%results;
}

1;