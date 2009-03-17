package perfSONAR_PS::Utils::TL1::Infinera;

use warnings;
use strict;

use Params::Validate qw(:all);
use Data::Dumper;

use base 'perfSONAR_PS::Utils::TL1::Base';
use fields 'READ_ALARMS', 'ALARMS';

sub initialize {
    my ($self, @params) = @_;

    my $parameters = validate(@params,
            {
            address => 1,
            port => 0,
            username => 1,
            password => 1,
            cache_time => 1,
            });

    $parameters->{"type"} = "ome";
    $parameters->{"prompt"} = "TL1>>" if (not $parameters->{"prompt"});
    $parameters->{"port"} = "9090" if (not $parameters->{"port"});

    return $self->SUPER::initialize($parameters);
}

sub getAlarms {
    my ($self) = shift;
    my %args = @_;

    my $do_reload_stats = 0;

    if (not $self->{READ_ALARMS}) {
        $do_reload_stats = 1;
        $self->{READ_ALARMS} = 1;
    }

    if ($self->{CACHE_TIME} + $self->{CACHE_DURATION} < time or $do_reload_stats) {
        $self->readStats();
    }

    if (not $self->{ALARMS}) {
        return (-1, "No alarms");
    }

    my @ret_alarms = ();

    foreach my $alarm (@{ $self->{ALARMS} }) {
        my $matches = 1;
        foreach my $key (keys %args) {
            if ($alarm->{$key}) {
                if ($alarm->{$key} ne $args{$key}) {
                    $matches = 1;
                }
            }
        }

        if ($matches) {
            push @ret_alarms, $alarm;
        }
    }

    return (0, \@ret_alarms);
}

sub readStats {
    my ($self) = @_;

    $self->connect();
    $self->login();

    if ($self->{READ_ALARMS}) {
        $self->readAlarms();
    }

    $self->{CACHE_TIME} = time;
    $self->disconnect();

    return;
}

sub readAlarms {
    my ($self) = @_;

    my @alarms = ();

    my ($successStatus, $results) = $self->send_cmd("RTRV-ALM-ALL:::".$self->{CTAG}."::;");

    if ($successStatus != 1) {
        $self->{ALARMS} = undef;
        return;
    }

    $self->{LOGGER}->debug("Got ALM line\n");    

    foreach my $line (@$results) {
        $self->{LOGGER}->debug("ALM LINE: ".$line."\n");

# "1-A-3-T1-1,SNC:CR,SNCFAIL,SA,10-28,15-40-38,NEND,NA:\"Signaled SNC failure\""
#    1. "1-A-3-T1-1,
#    2. SNC:
#    3. CR,
#    4. SNCFAIL,
#    5. SA,
#    6. 10-28,
#    7. 15-40-38,
#    8. NEND,
#    9. NA:
#    10. \"Signaled SNC failure\""

        if ($line =~ /"([^,]*),([^:]*):([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^,]*),([^:]*):(.*)"/) {
            $self->{LOGGER}->debug("Found a good line\n");

            my $facility = $1;
            my $facility_type = $2;
            my $severity = $3;
            my $alarmType = $4;
            my $serviceAffecting = $5;
            my $date = $6;
            my $time = $7;
            my $unknown1 = $8;
            my $unknown2 = $9;
            my $description = $10;

            $self->{LOGGER}->debug("DESCRIPTION: '$description'\n");
            $description =~ s/\\"//g;
            $self->{LOGGER}->debug("DESCRIPTION: '$description'\n");

            my %alarm = (
                facility => $facility,
                facility_type => $facility_type,
                severity => $severity,
                alarmType => $alarmType,
                serviceAffecting => $serviceAffecting,
                date => $date,
                time => $time,
                description => $description,
            );

            push @alarms, \%alarm;
        }
    }

    $self->{ALARMS} = \@alarms;
}

sub login {
    my ($self) = @_;

    if (not $self->{TELNET}) {
        return -1;
    }

    $self->{TELNET}->print("\n");
    $self->{TELNET}->waitfor(String => 'TL1');

    $self->{LOGGER}->debug("PASSWORD: $self->{PASSWORD}\n");

    my ($status, $lines) = $self->send_cmd("ACT-USER::".$self->{USERNAME}.":".$self->{CTAG}."::".$self->{PASSWORD}.";");

    if ($status != 1) {
        return -1;
    }

    $self->send_cmd("INH-MSG-ALL:::".$self->{CTAG}.";");

    return 0;
}

1;

# vim: expandtab shiftwidth=4 tabstop=4
