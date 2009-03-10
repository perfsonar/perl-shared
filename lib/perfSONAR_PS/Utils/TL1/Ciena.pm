package perfSONAR_PS::Utils::TL1::Ciena;

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
    $parameters->{"prompt"} = ";" if (not $parameters->{"prompt"});
    $parameters->{"port"} = "3083" if (not $parameters->{"port"});

    return $self->SUPER::initialize($parameters);
}

sub getVCG {
    my ($self, $name) = @_;

    return;
}

sub getSNC {
    my ($self, $name) = @_;

    return;
}

sub getETH {
    my ($self, $aid) = @_;

    return;
}

sub getOCN {
    my ($self, $aid) = @_;

    return;
}

sub getOCH {
    return;
}

sub getGTP {
    my ($self, $name) = @_;

    return;
}

sub getSect {
    return;
}

sub getLineByName {
    return;
}

sub getLine {
    return;
}

sub getCrossconnect {
    return;
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
        return undef;
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

    return \@ret_alarms;
}

sub getETH_PM {
    return;
}

sub getSTS_PM {
    return;
}

sub getOCN_PM {
    return;
}

sub readStats {
    my ($self) = @_;

    $self->{LOGGER}->debug("Connecting");
    $self->connect();
    $self->{LOGGER}->debug("Done");
    $self->login();
    $self->{LOGGER}->debug("Logged In");

    if ($self->{READ_ALARMS}) {
        $self->readAlarms();
    }

    $self->{CACHE_TIME} = time;
    $self->{LOGGER}->debug("Disconnecting");
    $self->disconnect();

    return;
}

sub readAlarms {
    my ($self) = @_;

    my @alarms = ();

    my ($successStatus, $results) = $self->send_cmd("RTRV-ALM-ALL:::".$self->{CTAG}."::;");

    $self->{LOGGER}->debug("Results: ".Dumper($results));

    if ($successStatus != 1) {
        $self->{ALARMS} = undef;
        return;
    }

    $self->{LOGGER}->debug("Got ALM line\n");    

    foreach my $line (@$results) {
        $self->{LOGGER}->debug("ALM LINE: ".$line."\n");

#   ACC-CIENA-1 08-10-28 14:56:38
        if ($line =~ /(\d\d)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
            $self->setMachineTime("$1-$2-$3 $4:$5:$6");
            next;
        }

#    "system,COM:MJ,LOGBUFOVFL-CMD,NSA,10-28,14-5-12:\"Log buffer overflow- cmd\""
#    "oc192-1-4b-1,EQPT:MN,DATAFLT,NSA,10-26,21-44-14:\"Data integrity fault\""

        if ($line =~ /"([^,]*),([^:]*):([^,]*),([^,]*),([^,]*),([^,]*),([^:]*):(.*)"/) {
            $self->{LOGGER}->debug("Found a good line\n");

            my $facility = $1;
            my $facility_type = $2;
            my $severity = $3;
            my $alarmType = $4;
            my $serviceAffecting = $5;
            my $date = $6;
            my $time = $7;
            my $description = $8;

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

    $self->{LOGGER}->debug("PASSWORD: $self->{PASSWORD}\n");

    my ($status, $lines) = $self->send_cmd("ACT-USER::".$self->{USERNAME}.":".$self->{CTAG}."::".$self->{PASSWORD}.";");

    if ($status != 1) {
        $self->{LOGGER}->debug("send_cmd failed\n");
        return -1;
    }

    $self->send_cmd("INH-MSG-ALL:::".$self->{CTAG}.";");

    return 0;
}

1;

# vim: expandtab shiftwidth=4 tabstop=4
