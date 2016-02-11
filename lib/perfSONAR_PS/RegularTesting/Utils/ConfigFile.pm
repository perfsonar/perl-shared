package perfSONAR_PS::RegularTesting::Utils::ConfigFile;

use strict;
use warnings;

our $VERSION = 3.5.1;

=head1 NAME

perfSONAR_PS::Utils::HTTPS

=head1 DESCRIPTION

A module that provides simple functions for retrieving HTTPS URLs that validate
the certificate.

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( parse_file save_file save_string );

my $logger = get_logger(__PACKAGE__);

=head2 parse_file()

=cut

sub parse_file {
    my $parameters = validate( @_, { file => 1 });
    my $file = $parameters->{file};

    unless (open(FILE, $file)) {
        my $msg = "Couldn't open $file";
        $logger->error($msg);
        return (-1, $msg);
    }

    my %config = ();
    my @blocks = { block => \%config };
    my $current_block = \%config;

    my $line = 0;

    while(<FILE>) {
        chomp;
        $line++;

        # Strip out comments that are in-line (skipping any # with a \ before it)
        s/([^\\])#.*/$1/g;

        # Strip out comments that are at the start of the line
        s/^\s*#.*//g;

        # Strip leading and trailing whitespace
        s/^\s+//;
        s/\s+$//;

        # skip blank lines
        next unless $_;

        if (/^<([^\/].*)>$/) {
            $logger->debug("Starting block: $1");

            # start block
            my %new_block = ();
            push @blocks, { name => $1, block => \%new_block };
            $current_block = \%new_block;
            next;
        }

        my ($variable, $value);

        if (/^<\/(.*)>$/) {
            if (scalar(@blocks) == 0) {
                my $msg = "Line $line. Closing block '$1' when none are open.";
                $logger->error($msg);
                return (-1, $msg);
            }

            # end block
            my $block = pop @blocks;
            $current_block = $blocks[$#blocks]->{block};

            $variable = $block->{name};
            $value    = $block->{block};

            $logger->debug("Ending block: $variable");
        }
        elsif (/^(\S+)\s+(.+)$/) {
            $variable = $1;
            $value    = $2;
            $value =~ s/\\(.)/$1/g;
        }
        else {
            my $msg = "Line $line malformed";
            $logger->error($msg);
            return (-1, $msg);
        }

        if ($current_block->{$variable} and ref($current_block->{$variable}) ne "ARRAY") {
            $current_block->{$variable} = [ $current_block->{$variable} ];
        }

        $logger->debug("Setting variable: $variable");

        if ($current_block->{$variable}) {
           push @{ $current_block->{$variable} }, $value;
        }
        else {
           $current_block->{$variable} = $value;
        }
    }

    close(FILE);

    if (scalar(@blocks) > 1) {
        my $msg = "Open block: ".$blocks[$#blocks]->{name};
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, \%config);
}

sub save_string {
    my $parameters = validate( @_, { config => 1 });
    my $config     = $parameters->{config};

    # Generate a Config::General version
    my $str = Config::General->new()->save_string($config);

    return (0, $str);
}

sub save_file {
    my $parameters = validate( @_, { file => 1, config => 1 });
    my $file       = $parameters->{file};
    my $config     = $parameters->{config};

    # Generate a Config::General version
    my $str = save_string(config => $config);

    unless (open(FILE, ">$file")) {
        my $msg = "Couldn't open $file for writing";
        $logger->error($msg);
        return (-1, $msg);
    }

    print FILE $str;

    close(FILE);

    return (0, "");
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
