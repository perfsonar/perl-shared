package perfSONAR_PS::Utils::TL1::Base;

use warnings;
use strict;

use POSIX;
use Net::Telnet;
use Data::Dumper;
use Log::Log4perl qw(get_logger :nowarn);

use Params::Validate qw(:all);
use perfSONAR_PS::Utils::ParameterValidation;

use fields 'USERNAME', 'PASSWORD', 'TYPE', 'ADDRESS', 'PORT', 'CACHE_DURATION', 'CACHE_TIME', 'LOGGER', 'MACHINE_TIME', 'LOCAL_MACHINE_TIME', 'PROMPT', 'CTAG', 'TELNET', 'MESSAGES', 'STATUS';

sub new {
    my ($class) = @_;

    my $self = fields::new($class);

    $self->{LOGGER} = get_logger($class);

    return $self;
}

sub initialize {
    my ($self, @params) = @_;

    #my $parameters = validateParams(@params,
    my $parameters = validate(@params,
            {
            type => 1,
            address => 1,
            port => 1,
            username => 1,
            password => 1,
            cache_time => 1,
            prompt => 1,
            ctag => 0,
            });

    $self->{USERNAME} = $parameters->{username};
    $self->{PASSWORD} = $parameters->{password};
    $self->{TYPE} = $parameters->{type};
    $self->{ADDRESS} = $parameters->{address};
    $self->{PORT} = $parameters->{port};
    $self->{PROMPT} = $parameters->{prompt};
    $self->{MESSAGES} = ();

    if ($parameters->{ctag}) {
        $self->{CTAG} = $parameters->{ctag};
    } else {
        $self->{CTAG} = int(rand(1000));
    }

    $self->{STATUS} = "UNCONNECTED";

    $self->{CACHE_TIME} = 0;
    $self->{CACHE_DURATION} = $parameters->{cache_time};

    return $self;
}

sub getType {
    my ($self) = @_;

    return $self->{TYPE};
}

sub setType {
    my ($self, $type) = @_;

    $self->{TYPE} = $type;

    return;
}

sub setUsername {
    my ($self, $username) = @_;

    $self->{USERNAME} = $username;

    return;
}

sub getUsername {
    my ($self) = @_;

    return $self->{USERNAME};
}

sub setPassword {
    my ($self, $password) = @_;

    $self->{PASSWORD} = $password;

    return;
}

sub getPassword {
    my ($self) = @_;

    return $self->{PASSWORD};
}

sub setAddress {
    my ($self, $address) = @_;

    $self->{ADDRESS} = $address;

    return;
}

sub getAddress {
    my ($self) = @_;

    return $self->{ADDRESS};
}

sub setAgent {
    my ($self, $agent) = @_;

    $self->{TL1AGENT} = $agent;

    return;
}

sub getAgent {
    my ($self) = @_;

    return $self->{TL1AGENT};
}

sub setCacheTime {
    my ($self, $time) = @_;

    $self->{CACHE_TIME} = $time;

    return $self->{CACHE_TIME};
}

sub getCacheTime {
    my ($self) = @_;

    return $self->{CACHE_TIME};
}

sub login {
    die("This method must be overriden by a subclass");
}

sub logout {
    return;
}

sub connect {
    my ($self, @params) = @_;
    my $parameters = validate(@params,
            {
                inhibitMessages => { type => SCALAR, optional => 1, default => 1 },
            });
 
    $self->{LOGGER}->debug(Dumper($self->{ADDRESS}));

    if (not $self->{TELNET} = Net::Telnet->new(Host => $self->{ADDRESS}, Port => $self->{PORT}, Timeout => 15, Errmode => "return")) {
        $self->{TELNET} = undef;
        return -1;
    }

    $self->{STATUS} = "LOGGING_IN";

    if (not $self->login({ inhibitMessages => $parameters->{inhibitMessages} })) {
        $self->{TELNET} = undef;
        $self->{STATUS} = "DISCONNECTED";
        return -1;
    }

    $self->{STATUS} = "CONNECTED";

    return 0;
}

sub disconnect {
    my ($self) = @_;

    $self->logout();

    $self->{MESSAGES} = ();

    if (not $self->{TELNET}) {
        return;
    }

    $self->{TELNET}->close;
    $self->{TELNET} = undef;

    $self->{STATUS} = "DISCONNECTED";

    return;
}

sub refresh_connection {
    my ($self) = @_;

   my ($status, $res) = $self->send_cmd("RTRV-HDR:::".$self->{CTAG}.";");
   if ($status != 0) {
       return (-1, $status);
   }

    return (0, "");
}

sub send_cmd {
    my ($self, $cmd, $is_connecting) = @_;
    
    if (not $self->{TELNET}) {
        return (-1, undef);
    }

    unless ($self->{STATUS} eq "LOGGING_IN" or $self->{STATUS} eq "CONNECTED") {
        $self->{LOGGER}->error("Invalid status: ".$self->{STATUS});
        return (-1, undef);
    }

    $self->{LOGGER}->debug("Sending cmd: $cmd\n");

    my $res = $self->{TELNET}->send($cmd);

    my @retLines;
    my $successStatus;

    while(not defined $successStatus) {
        my ($status, $lines) = $self->waitMessage({ type => "response" });
        # connection error
        if ($status != 0) {
            $self->{LOGGER}->debug("connection error");
            return (-1, undef);
        }

        # connection closed
        if (not defined $lines) {
            $self->{LOGGER}->debug("connection closed");
            return (-1, undef);
        }

        @retLines = ();
        foreach my $line (@{ $lines }) {

            next if ($line =~ /$cmd/);

            if ($line =~ /(\d\d\d?\d?)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
                $self->setMachineTime("$1-$2-$3 $4:$5:$6");
                next;
            } elsif ($line =~ /^\s*M\s+$self->{CTAG}\s+(COMPLD|DENY)/) {
                if ($1 eq "COMPLD") {
                    $successStatus = 1;
                } elsif ($1 eq "DENY") {
                    $successStatus = 0;
                }
            } else {
                push @retLines, $line;
            }
        }
    }

    return ($successStatus, \@retLines);
}

sub waitMessage {
    my ($self, @args) = @_;
    my $args = validateParams(@args, 
            {
                type => { type => SCALAR },
                timeout => { type => SCALAR, optional => 1 },
            });

    my $type = $args->{type};

    $self->{LOGGER}->debug("waitMessage: ".$type);

    my $end;
    if (defined $args->{timeout}) {
        $end = time + $args->{timeout};
    }

    if (not defined $self->{MESSAGES}->{$type}) {
        $self->{MESSAGES}->{$type} = ();
    }

    while ($#{ $self->{MESSAGES}->{$type} } == -1) {
        my ($status, $lines);

        if ($end) {
            my $timeout = $end - time;
            if ($timeout <= 0) {
                $self->{LOGGER}->debug("timeout occurred: ".($args->{timeout}));

                return (1, undef);
            }

            ($status, $lines) = $self->readMessage({ timeout => $timeout });
        } else {
            ($status, $lines) = $self->readMessage();
        }

        if ($status == -1) {
            $self->{LOGGER}->debug("readMessage returned -1");
            return (-1, undef);
        }

        if ($status == 0 and defined $lines) {
            $self->processMessage($lines);
            $self->{LOGGER}->debug("Processed Message: ".Dumper($self->{MESSAGES}));
        }
    }

    my $lines = shift(@{ $self->{MESSAGES}->{$type} });

    return (0, $lines);
}

sub readMessage {
    my ($self, @args) = @_;
    my $args = validateParams(@args, 
            {
                timeout => { type => SCALAR, optional => 1 },
            });
 
    $self->{LOGGER}->debug("readMessage");

    if (not $self->{TELNET}) {
        $self->{LOGGER}->debug("readMessage: no TELNET");
        return (-1, undef);
    }

    my ($prematch, $prompt);
    if ($args->{timeout}) {
        ($prematch, $prompt) = $self->{TELNET}->waitfor(
                                                            Match => "/^".$self->{PROMPT}."/gm",
                                                            Timeout => $args->{timeout},
                                                            Errmode => "return",
                                                      );
    } else {
        ($prematch, $prompt) = $self->{TELNET}->waitfor(
                                                            Match => "/^".$self->{PROMPT}."/gm",
                                                            Errmode => "return",
                                                      );
    }

    my $retStatus;

    if (not defined $prematch) {
        my $errmsg = $self->{TELNET}->errmsg();
        $self->{LOGGER}->debug("Error message: $errmsg");
        if ($errmsg =~ /timed-out/) {
            $retStatus = 1; # a timeout occurred.            
        } elsif ($errmsg =~ /read eof/) {
            $self->{LOGGER}->debug("readMessage: read eof");
            $retStatus = 0; # connection closed.
        } else {
            $self->{LOGGER}->debug("readMessage: other error: ".$errmsg);
            $retStatus = -1; # an error occurred.
        }

        return ($retStatus, undef);
    } else {
        $self->{LOGGER}->debug("PREMATCH: ".$prematch."\n");

        my @lines = split('\n', $prematch);
        return (0, \@lines);
    }
}

sub processMessage {
    my ($self, $lines) = @_;

    $self->{LOGGER}->debug("processMessage");

    foreach my $line (@{ $lines }) {
        $self->{LOGGER}->debug("LINE: $line");

        if ($line =~ /(\d\d\d?\d?)-(\d\d)-(\d\d) (\d\d):(\d\d):(\d\d)/) {
            $self->setMachineTime("$1-$2-$3 $4:$5:$6");
            last;
        }
    }

    my $type = $self->categorizeMessage($lines);

    if (not $type) {
        return 0;
    }

    if (not defined $self->{MESSAGES}->{$type}) {
        $self->{MESSAGES}->{$type} = ();
    }

    push @{ $self->{MESSAGES}->{$type} }, $lines;

    return 0;
}

sub clearMessages {
    my ($self) = @_;

    $self->{MESSAGES} = ();

    return;
}

sub categorizeMessage {
    my ($self, $lines) = @_;

    foreach my $line (@{ $lines }) {
        if ($line =~ /REPT ALM/) {
            $self->{LOGGER}->debug("category: alarm");

            return "alarm";
        } elsif ($line =~ /REPT EVT/) {
            $self->{LOGGER}->debug("category: event");

            return "event";
        } elsif ($line =~ /DENY/ or $line =~ /COMPLD/) {
            $self->{LOGGER}->debug("category: response");

            return "response";
        }
    }

    $self->{LOGGER}->debug("category: other");

    # return 'undef' to delete the message

    return "other";
}

sub setMachineTime {
    my ($self, $time) = @_;

    my ($curr_date, $curr_time) = split(" ", $time);
    my ($year, $month, $day) = split("-", $curr_date);
    my ($hour, $minute, $second) = split(":", $curr_time);

    $self->{LOGGER}->debug("Setting machine time: $year-$month-$day $hour:$minute:$second");

    # make sure it's in 4 digit year form
    if (length($year) == 2) {
        # I don't see why it'd ever not be +2000, but...
        if ($year < 70) {
            $year += 100;
        }
    } else {
        $year -= 1900;
    }

    $month--;

    my $machine_ts = POSIX::mktime($second, $minute, $hour, $day, $month, $year, 0, 0);

    $self->{LOCAL_MACHINE_TIME} = time;
    $self->{MACHINE_TIME} = $machine_ts;

    return;
}

sub getMachineTime {
    my ($self) = @_;

    my $diff = time - $self->{LOCAL_MACHINE_TIME};
    my $machine_ts = $self->{MACHINE_TIME} + $diff;

    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime($machine_ts);

    $mon++;
    $year += 1900;

    my $readable_time = sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);

#    $self->{LOGGER}->debug("Returning machine time: ".$readable_time."\n");

    return $readable_time;
}

sub getMachineTime_TS {
    my ($self) = @_;

    my $diff = time - $self->{LOCAL_MACHINE_TIME};
    my $machine_ts = $self->{MACHINE_TIME} + $diff;

    return $machine_ts;
}

sub convertPMDateTime {
	my ($self, $date, $time) = @_;

	# guess the year of the interval based on the current machine time
	my ($month, $day) = split('-', $date);
	my ($hour, $minute) = split('-', $time);
	my ($switch_date, $switch_time) = split(' ', $self->getMachineTime());

	my ($switch_year, $switch_month, $switch_day) = split('-', $switch_date);
	my ($switch_hour, $switch_minute, $switch_second) = split(':', $switch_time);

	# Calculate the year
	my $year;

	if ($switch_month eq $month) {
		$year = $switch_year;
	} elsif ($switch_month ne $month) {
		if ($switch_month == 1) {
			$year = $switch_year - 1;
		} else {
			$year = $switch_year;
		}
	}

	return sprintf "%4d-%02d-%02d %02d:%02d:%02d", $year,$month,$day,$hour,$minute,0;
}

sub convertTimeStringToTimestamp {
	my ($self, $time_str) = @_;

	# guess the year of the interval based on the current machine time
	my ($date, $time) = split(' ', $time_str);

	my ($year, $month, $day) = split('-', $date);
	my ($hour, $minute, $second) = split(':', $time);

    return POSIX::mktime($second, $minute, $hour, $day, $month - 1, $year - 1900, 0, 0);
}

sub convertMachineTSToLocalTS {
    my ($self, $machine_timestamp) = @_;

    my $diff = $self->{MACHINE_TIME} - $self->{LOCAL_MACHINE_TIME};

    return $machine_timestamp + $diff;
}

1;

# vim: expandtab shiftwidth=4 tabstop=4
