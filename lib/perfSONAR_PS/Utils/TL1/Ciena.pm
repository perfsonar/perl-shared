package perfSONAR_PS::Utils::TL1::Ciena;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::Utils::TL1::Ciena

=head1 DESCRIPTION

Cienna specific extensions to the TL1 utilities.

=cut

use Params::Validate qw(:all);
use Data::Dumper;

use base 'perfSONAR_PS::Utils::TL1::Base';
use fields 'READ_ALARMS', 'ALARMS';

=head2 initialize( $self, @params )

Prepare the object

=cut

sub initialize {
    my ( $self, @params ) = @_;

    my $parameters = validate(
        @params,
        {
            address    => 1,
            port       => 0,
            username   => 1,
            password   => 1,
            cache_time => 1,
        }
    );

    $parameters->{"type"}   = "ciena";
    $parameters->{"prompt"} = ";" if ( not $parameters->{"prompt"} );
    $parameters->{"port"}   = "3083" if ( not $parameters->{"port"} );

    return $self->SUPER::initialize( $parameters );
}

=head2 get_alarms( $self )

Get all alarms.

=cut

sub get_alarms {
    my ( $self ) = shift;
    my %args = @_;

    my $do_reload_stats = 0;

    unless ( $self->{READ_ALARMS} ) {
        $do_reload_stats = 1;
        $self->{READ_ALARMS} = 1;
    }

    if ( $self->{CACHE_TIME} + $self->{CACHE_DURATION} < time or $do_reload_stats ) {
        $self->readStats();
    }

    unless ( $self->{ALARMS} ) {
        return ( -1, "No alarms" );
    }

    my @ret_alarms = ();

    foreach my $alarm ( @{ $self->{ALARMS} } ) {
        my $matches = 1;
        foreach my $key ( keys %args ) {
            if ( $alarm->{$key} ) {
                if ( $alarm->{$key} ne $args{$key} ) {
                    $matches = 1;
                }
            }
        }

        if ( $matches ) {
            push @ret_alarms, $alarm;
        }
    }

    return ( 0, \@ret_alarms );
}

sub readStats {
    my ( $self ) = @_;

    if ( $self->{READ_ALARMS} ) {
        $self->readAlarms();
    }

    $self->{CACHE_TIME} = time;

    return;
}

=head2 readAlarms()

TBD

=cut

sub readAlarms {
    my ( $self ) = @_;

    my @alarms = ();

    my ( $successStatus, $results ) = $self->send_cmd( "RTRV-ALM-ALL:::" . $self->{CTAG} . "::;" );

    $self->{LOGGER}->debug( "Results: " . Dumper( $results ) );

    if ( $successStatus != 1 ) {
        $self->{ALARMS} = undef;
        return;
    }

    $self->{LOGGER}->debug( "Got ALM line\n" );

    foreach my $line ( @$results ) {
        $self->{LOGGER}->debug( "ALM LINE: " . $line . "\n" );

        # "ETH10G-1-2-2,ETH10G:CR,LOS,SA,01-29,19-03-54,NEND,RCV:\"Loss Of Signal\",NONE:0100000141-0008-0673,:YEAR=2006,MODE=NONE"
        # "ETH10G-1-2-2,ETH10G:CR,LOS,SA,01-29,19-03-54,NEND,RCV:\"Loss Of Signal\",NONE:0100000141-0008-0673,:YEAR=2006,MODE=NONE"

        #    "system,COM:MJ,LOGBUFOVFL-CMD,NSA,10-28,14-5-12:\"Log buffer overflow- cmd\""
        #    "oc192-1-4b-1,EQPT:MN,DATAFLT,NSA,10-26,21-44-14:\"Data integrity fault\""

        if ( $line =~ /"([^,]*),([^:]*):([^,]*),([^,]*),([^,]*),([^,]*),([^:,]*)(,[^:,]*)?(,[^:,]*)?:([^,]*),?([^:]*):([^,]*),?([^:]*):?(YEAR=([0-9])*)?,?(MODE=.*)?"/ ) {
            $self->{LOGGER}->debug( "Found a good line\n" );

            my $facility         = $1;
            my $facility_type    = $2;
            my $severity         = $3;
            my $alarmType        = $4;
            my $serviceAffecting = $5;
            my $date             = $6;
            my $time             = $7;
            my $nend             = $8;
            my $rcv              = $9;
            my $description      = $10;
            my $something        = $11;
            my $something2       = $12;
            my $something3       = $13;
            my $year             = $14;
            my $mode             = $15;

            $self->{LOGGER}->debug( "DESCRIPTION: '$description'\n" );
            $description =~ s/\\"//g;
            $self->{LOGGER}->debug( "DESCRIPTION: '$description'\n" );

            my %alarm = (
                facility         => $facility,
                facility_type    => $facility_type,
                severity         => $severity,
                alarmType        => $alarmType,
                serviceAffecting => $serviceAffecting,
                date             => $date,
                time             => $time,
                description      => $description,
            );

            push @alarms, \%alarm;
        }
    }

    $self->{ALARMS} = \@alarms;

    return;
}

sub login {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { inhibit_messages => { type => SCALAR, optional => 1, default => 1 }, } );

    #    my ($status, $lines) = $self->waitMessage({ type => "other" });
    #    if ($status != 0 or not defined $lines) {
    #        $self->{LOGGER}->debug("login failed");
    #        return -1;
    #    }

    $self->{LOGGER}->debug( "PASSWORD: $self->{PASSWORD}\n" );

    my ( $status, $lines ) = $self->send_cmd( "ACT-USER::" . $self->{USERNAME} . ":" . $self->{CTAG} . "::\"" . $self->{PASSWORD} . "\";" );

    if ( $status != 1 ) {
        return 0;
    }

    if ( $parameters->{inhibit_messages} ) {
        $self->send_cmd( "INH-MSG-ALL:::" . $self->{CTAG} . ";" );
    }

    return 1;
}

1;

__END__

=head1 SEE ALSO

L<Params::Validate>, L<Data::Dumper>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
