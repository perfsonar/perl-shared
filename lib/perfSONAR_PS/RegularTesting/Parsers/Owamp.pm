package perfSONAR_PS::RegularTesting::Parsers::Owamp;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Owamp;

=head1 DESCRIPTION

A module that provides simple functions for parsing owamp output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use Config::General;

use perfSONAR_PS::RegularTesting::Utils qw(owpdelay);

our @EXPORT_OK = qw( parse_owamp_raw_output parse_owamp_summary_file parse_owamp_raw_file );

my $logger = get_logger(__PACKAGE__);

=head2 parse_owamp_raw_output()

=cut

sub parse_owamp_raw_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};

    my @packets = ();

    for my $line (split('\n', $stdout)) {
        # 76 15427415053766410295 0 2.32831e-10 00000000000000000000 1 0.000127792 255
        if ($line =~ /^(\d+) (\d+) (\d) ([-.0-9e+]*) (\d+) (\d) ([-.0-9e+]*) (\d+)$/) {
            my $sequence_number          = $1;
            my $source_timestamp         = $2;
            my $source_synchronized      = $3;
            my $source_error             = $4;
            my $destination_timestamp    = $5;
            my $destination_synchronized = $6;
            my $destination_error        = $7;
            my $ttl                      = $8;

            my %packet_desc = (
                sequence_number => $sequence_number
            );

            # i.e. not a lost or duplicate packet
            if ($destination_timestamp != 0) {
                $packet_desc{delay} = owpdelay($source_timestamp, $destination_timestamp);
                $packet_desc{ttl}   = $ttl;
                $packet_desc{max_error} = ($source_error > $destination_error ? $source_error :  $destination_error);
            }

            push @packets, \%packet_desc;
        }
    }

    return {
        pings => \@packets
    };
}

sub parse_owamp_summary_file {
    my $parameters = validate( @_, { summary_file => 1, });
    my $summary_file = $parameters->{summary_file};

    my $retval;

    eval {
        my $conf = Config::General->new($summary_file);
        my %conf_hash = $conf->getall;
        $retval = \%conf_hash;
    };
    if ($@) {
        $logger->error("Problem reading summary file: ".$summary_file.": ".$@);
    }

    return $retval;
}

sub parse_owamp_raw_file {
    my $parameters = validate( @_, { owstats => 1, raw_file => 1, });
    my $owstats  = $parameters->{owstats};
    my $raw_file = $parameters->{raw_file};

    my $retval;

    eval {
        my $output = `$owstats -R $raw_file`;
        $retval = parse_owamp_raw_output({ stdout => $output });
    };
    if ($@) {
        $logger->error("Problem reading summary file: ".$raw_file.": ".$@);
    }

    return $retval;
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: Host.pm 5139 2012-06-01 15:48:46Z aaron $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 COPYRIGHT

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
