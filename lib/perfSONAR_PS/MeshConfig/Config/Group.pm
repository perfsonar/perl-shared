package perfSONAR_PS::MeshConfig::Config::Group;
use strict;
use warnings;

our $VERSION = 3.1;

use Moose;
use Params::Validate qw(:all);

use perfSONAR_PS::MeshConfig::Config::Group::Star;
use perfSONAR_PS::MeshConfig::Config::Group::Mesh;
use perfSONAR_PS::MeshConfig::Config::Group::Disjoint;
use perfSONAR_PS::MeshConfig::Config::Group::OrderedMesh;

=head1 NAME

perfSONAR_PS::MeshConfig::Config::Group;

=head1 DESCRIPTION

=head1 API

=cut

extends 'perfSONAR_PS::MeshConfig::Config::Base';

has 'type'      => (is => 'rw', isa => 'Str');
has 'parent'    => (is => 'rw', isa => 'perfSONAR_PS::MeshConfig::Config::Test');

override 'parse' => sub {
    my ($class, $description, $strict) = @_;

    if ($class eq __PACKAGE__) {
        unless ($description->{type}) {
            die("Unspecified group type");
        }

        if ($description->{type} eq "mesh") {
            return perfSONAR_PS::MeshConfig::Config::Group::Mesh->parse($description, $strict);
        }
        elsif ($description->{type} eq "star") {
            return perfSONAR_PS::MeshConfig::Config::Group::Star->parse($description, $strict);
        }
        elsif ($description->{type} eq "disjoint") {
            return perfSONAR_PS::MeshConfig::Config::Group::Disjoint->parse($description, $strict);
        }
        elsif ($description->{type} eq "ordered_mesh") {
            return perfSONAR_PS::MeshConfig::Config::Group::OrderedMesh->parse($description, $strict);
        }
        else {
            die("Unknown group type");
        }
    }
    else {
        return super($class, $description, $strict);
    }
};

sub lookup_hosts {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { addresses => 1 } );
    my $addresses    = $parameters->{addresses};

    return $self->parent->lookup_hosts({ addresses => $addresses });
}

sub __build_pair {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                        source_address  => 1,
                                        source_no_agent => 0,
                                        destination_address  => 1,
                                        destination_no_agent => 0,
                                      });
    my $source_address       = $parameters->{source_address};
    my $source_no_agent      = $parameters->{source_no_agent};
    my $destination_address  = $parameters->{destination_address};
    my $destination_no_agent = $parameters->{destination_no_agent};

    my %pair = (
                 source => { address => $source_address, no_agent => $source_no_agent },
                 destination => { address => $destination_address, no_agent => $destination_no_agent },
               );

    foreach my $side ("source", "destination") {
        next if (defined $pair{$side}->{no_agent});

        my $hosts = $self->lookup_hosts({ addresses => [ $pair{$side}->{address} ] });
        unless (scalar(@$hosts) > 0) {
            my $msg = "Unknown host: ".$pair{$side}->{address};
            die("Unknown host: ".$pair{$side}->{address});
        }

        $pair{$side}->{no_agent} = $hosts->[0]->no_agent;
    }

    return \%pair;
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
