package perfSONAR_PS::Time;

use strict;
use warnings;

our $VERSION = 3.3;

use fields 'TYPE', 'STARTTIME', 'ENDTIME', 'DURATION', 'TIME';

=head1 NAME

perfSONAR_PS::Time

=head1 DESCRIPTION

A module that provides methods for the a simple time element that can represent
either single points in time or time ranges as unix timestamps.

=cut

use Log::Log4perl qw(get_logger);
use Data::Dumper;

=head2 new ($package, $type, $arg1, $arg2)

This allocates a perfSONAR_PS::Time element. The type parameter can be one of
'range', 'duration' or 'point'. If the type is 'point', then $arg1 is the time
parameter as a unix timestamp. If the type is 'range', then $arg1 is the
startTime and $arg2 is the endTime. If the type is 'duration', then $arg1 is the
startTime and $arg2 is the duration.

=cut

sub new {
    my ( $package, $type, $arg1, $arg2 ) = @_;
    my $logger = get_logger( "perfSONAR_PS::Time" );

    my $self = fields::new( $package );

    if ( defined $type and $type eq "range" ) {
        $self->{TYPE}      = "range";
        $self->{STARTTIME} = $arg1;
        $self->{ENDTIME}   = $arg2;
        $self->{DURATION}  = $arg2 - $arg1;
    }
    elsif ( defined $type and $type eq "duration" ) {
        $self->{TYPE}      = "duration";
        $self->{STARTTIME} = $arg1;
        $self->{DURATION}  = $arg2;
    }
    elsif ( defined $type and $type eq "point" ) {
        $self->{TYPE} = "point";
        $self->{TIME} = $arg1;
    }
    else {
        $logger->error( "Invalid type: $type" );
        return;
    }

    return $self;
}

=head2 getType ($self)

This function returns what type 'point', 'range' or 'duration' that this Time
element is.

=cut

sub getType {
    my ( $self ) = @_;
    return $self->{TYPE};
}

=head2 getTime ($self)

This function is valid for Time elements of type 'point' and simply returns the
point in time that this element describes.

=cut

sub getTime {
    my ( $self ) = @_;
    return $self->{TIME};
}

=head2 getStartTime ($self)

This function is valid for Time elements of type 'range' or 'duration' and
returns the starting point of the time range.

=cut

sub getStartTime {
    my ( $self ) = @_;
    if ( exists $self->{TYPE} and $self->{TYPE} eq "point" ) {
        return $self->{TIME};
    }
    else {
        return $self->{STARTTIME};
    }
}

=head2 getEndTime ($self)

This function is valid for Time elements of type 'range' or 'duration' and
returns the ending point of the time range.

=cut

sub getEndTime {
    my ( $self ) = @_;

    if ( exists $self->{TYPE} and $self->{TYPE} eq "duration" ) {
        return $self->{STARTTIME} + $self->{DURATION};
    }
    elsif ( exists $self->{TYPE} and $self->{TYPE} eq "range" ) {
        return $self->{ENDTIME};
    }
    else {
        return $self->{TIME};
    }
}

=head2 getDuration ($self)

This function is valid for Time elements of type 'duration' and returns the
duration of the time range.

=cut

sub getDuration {
    my ( $self ) = @_;
    return $self->{DURATION};
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Data::Dumper>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

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

Copyright (c) 2004-2009, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4

