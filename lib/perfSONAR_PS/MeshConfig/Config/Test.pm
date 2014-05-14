package perfSONAR_PS::MeshConfig::Config::Test;
use strict;
use warnings;

our $VERSION = 3.1;

use Moose;
use Params::Validate qw(:all);

use perfSONAR_PS::MeshConfig::Config::Administrator;
use perfSONAR_PS::MeshConfig::Config::Group;
use perfSONAR_PS::MeshConfig::Config::TestParameters;
use perfSONAR_PS::MeshConfig::Config::MeasurementArchive;
use perfSONAR_PS::MeshConfig::Config::Mesh;
use perfSONAR_PS::MeshConfig::Config::ExpectedTestResults;

=head1 NAME

perfSONAR_PS::MeshConfig::Config::Test;

=head1 DESCRIPTION

=head1 API

=cut

extends 'perfSONAR_PS::MeshConfig::Config::Base';

has 'description'         => (is => 'rw', isa => 'Str');

has 'disabled'            => (is => 'rw', isa => 'Bool');

has 'administrators'      => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::MeshConfig::Config::Administrator]', default => sub { [] });
has 'members'             => (is => 'rw', isa => 'perfSONAR_PS::MeshConfig::Config::Group');
has 'parameters'          => (is => 'rw', isa => 'perfSONAR_PS::MeshConfig::Config::TestParameters');

has 'expected_results'    => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::MeshConfig::Config::ExpectedTestResults]', default => sub { [] });

has 'measurement_archives' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::MeshConfig::Config::MeasurementArchive]', default => sub { [] });

has 'parent'              => (is => 'rw', isa => 'perfSONAR_PS::MeshConfig::Config::Mesh');

sub lookup_administrators {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { address => 0, recursive => 1 } );
    my $address    = $parameters->{address};
    my $recursive  = $parameters->{recursive};

    if (scalar(@{ $self->administrators }) > 0) { # i.e. if there is actually a set of administrators
        return $self->administrators;
    }
    elsif ($recursive) {
        # If there's not a test-specific MA, lookup the host associated with the
        # address, and see if there's an MA for that host.
        my $hosts = $self->parent->lookup_hosts({ addresses => [ $address ] });

        return unless scalar(@$hosts) > 0;

        return $hosts->[0]->lookup_administrators({ recursive => $recursive });
    }
    else {
        return;
    }
}

sub lookup_measurement_archive {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { type => 1, address => 0 } );
    my $type       = $parameters->{type};
    my $address    = $parameters->{address};

    foreach my $measurement_archive (@{ $self->measurement_archives }) {
        if ($measurement_archive->type eq $type) {
            return $measurement_archive;
        }
    }

    if ($address) {
        # If there's not a test-specific MA, lookup the host associated with the
        # address, and see if there's an MA for that host.
        my $hosts = $self->parent->lookup_hosts({ addresses => [ $address ] });

        return unless scalar(@$hosts) > 0;

        return $hosts->[0]->lookup_measurement_archive({ type => $type });
    }

    return;
}

sub lookup_hosts {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { addresses => 1 } );
    my $addresses    = $parameters->{addresses};

    return $self->parent->lookup_hosts({ addresses => $addresses });
}

sub lookup_expected_results {
    my ($self, @args) = @_;
    my $parameters  = validate( @args, { type => 1, source => 1, destination => 1 } );
    my $type        = $parameters->{type};
    my $source      = $parameters->{source};
    my $destination = $parameters->{destination};

    my $expected_results;

    my $exact_match;
    my $source_match;
    my $destination_match;
    my $any_match;

    foreach my $expected_result (@{ $self->expected_results }) {
       next unless $type eq $expected_result->type;

       if ($expected_result->source eq $source and
           $expected_result->destination eq $destination) {
           $exact_match = $exact_match?$exact_match->merge($expected_result):$expected_result;
       }
       elsif ($expected_result->source eq $source and
              $expected_result->destination eq '*') {
           $source_match = $source_match?$source_match->($expected_result):$expected_result;
       }
       elsif ($expected_result->source eq '*' and
              $expected_result->destination eq $destination) {
           $destination_match = $destination_match?$destination_match->merge($expected_result):$expected_result;
       }
       elsif ($expected_result->source eq '*' and
              $expected_result->destination eq '*') {
           $any_match = $any_match?$any_match->merge($expected_result):$expected_result;
       }
    }

    my $result;
    foreach my $match ($exact_match, $source_match, $destination_match, $any_match) {
        next unless $match;

        if ($result) {
            $result = $result->merge($match);
        }
        else {
            $result = $match;
        }
    }

    return $result;
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

$Id: Base.pm 3658 2009-08-28 11:40:19Z aaron $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2009, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
