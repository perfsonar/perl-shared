package perfSONAR_PS::MeshConfig::Config::Group::Star;
use strict;
use warnings;

our $VERSION = 3.1;

use Moose;

=head1 NAME

perfSONAR_PS::MeshConfig::Config::Group::Star;

=head1 DESCRIPTION

=head1 API

=cut

extends 'perfSONAR_PS::MeshConfig::Config::Group';

has 'center_address'       => (is => 'rw', isa => 'Str');
has 'members'             => (is => 'rw', isa => 'ArrayRef[Str]');
has 'no_agents'           => (is => 'rw', isa => 'ArrayRef[Str]');

sub BUILD {
    my ($self) = @_;
    $self->type("star");
}

sub source_destination_pairs {
    my ($self) = @_;

    my %no_agent_map = ();
    if ($self->no_agents) {
        %no_agent_map = map { $_ => 1 } @{ $self->no_agents };
    }

    my @pairs = ();
    foreach my $member (@{ $self->members }) {
        next if $member eq $self->center_address;

        foreach my $pair ([ $self->center_address, $member ], [ $member, $self->center_address ]) {
            my $source = $pair->[0];
            my $destination = $pair->[1];

            my $pair = $self->__build_pair({
                                            source_address => $source, source_no_agent => $no_agent_map{$source},
                                            destination_address => $destination, destination_no_agent => $no_agent_map{$destination},
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
