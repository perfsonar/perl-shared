package perfSONAR_PS::MeshConfig::Config::Group::OrderedMesh;
use strict;
use warnings;

our $VERSION = 3.1;

use Moose;

=head1 NAME

perfSONAR_PS::MeshConfig::Config::Group::OrderedMesh;

=head1 DESCRIPTION

=head1 API

=cut

extends 'perfSONAR_PS::MeshConfig::Config::Group';

has 'members'             => (is => 'rw', isa => 'ArrayRef[Str]');

sub BUILD {
    my ($self) = @_;
    $self->type("ordered_mesh");
}

sub source_destination_pairs {
    my ($self) = @_;

    my @members = @{ $self->members };

    my @pairs = ();

    for (my $i = 0; $i <= $#members; $i++) {
        for (my $j = $i + 1; $j <= $#members; $j++) {
            my $local  = $members[$i];
            my $remote = $members[$j];

            # Specify 'no_agent' to ensure that the previous member will handle
            # both sides of the test.
            my $pair = $self->__build_pair({
                                            source_address => $local, source_no_agent => 0,
                                            destination_address => $remote, destination_no_agent => 1,
                                          });
            push @pairs, $pair;

            $pair = $self->__build_pair({
                                            source_address => $remote, source_no_agent => 1,
                                            destination_address => $local, destination_no_agent => 0,
                                          });
            push @pairs, $pair;
        }
    }

    return \@pairs;
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

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
