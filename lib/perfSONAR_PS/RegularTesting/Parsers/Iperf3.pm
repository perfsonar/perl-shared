package perfSONAR_PS::RegularTesting::Parsers::Iperf3;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::RegularTesting::Parsers::Iperf3;

=head1 DESCRIPTION

A module that provides simple functions for parsing iperf output

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use JSON;

our @EXPORT_OK = qw( parse_iperf3_output );

my $logger = get_logger(__PACKAGE__);

=head2 parse_iperf3_output()

=cut

sub parse_iperf3_output {
    my $parameters = validate( @_, { stdout  => 1, });
    my $stdout  = $parameters->{stdout};

    my $json_text = "";
    my $in_json;
    foreach my $line (split('\n', $stdout)) {
        if ($json_text eq "" and $line =~ /^{$/) {
            $in_json = 1;
        }

        $json_text .= $line if $in_json;

        if ($line =~ /^}$/) {
            last;
        }
    }

    my $parsed;
    eval {
        $parsed = JSON->new->utf8(1)->decode($json_text);
    };
    if ($@) {
        return { error => "Problem parsing output: ".$@ };
    }

    return $parsed;
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
