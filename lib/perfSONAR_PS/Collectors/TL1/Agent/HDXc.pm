package perfSONAR_PS::Collectors::TL1::Agent::HDXc;


use strict;
use warnings;
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Utils::ParameterValidation;
use perfSONAR_PS::Utils::TL1::HDXc;

our $VERSION = 0.09;

use fields 'AGENT', 'LOGGER', 'AID_TYPE', 'AID', 'COUNTER';

sub new {
    my ($class, @params) = @_;

    my $parameters = validateParams(@params,
            {
            address => 0,
            port => 0,
            username => 0,
            password => 0,
            agent => 0,
            aid => 1,
            counter => 1,
            aid_type => 1,
            });

    my $self = fields::new($class);

    $self->{LOGGER} = get_logger("perfSONAR_PS::Collectors::TL1::Agent::HDXc");

    # we need to be able to generate a new tl1 agent or reuse an existing one. Not neither.
    if (not $parameters->{agent} and
             (not $parameters->{address} or
             not $parameters->{port} or
             not $parameters->{username} or
             not $parameters->{password})
       ) {
        return;
    }

    if (not defined $parameters->{agent}) {
	$parameters->{agent} = perfSONAR_PS::Utils::TL1::HDXc->new();
	$parameters->{agent}->initialize(
                    username => $parameters->{username},
                    password => $parameters->{password},
                    address => $parameters->{address},
                    port => $parameters->{port},
                    cache_time => 300
                );
    }

    $self->counter($parameters->{counter});
    $self->agent($parameters->{agent});
    $self->aid($parameters->{aid});
    $self->aid_type($parameters->{aid_type});

    return $self;
}

sub run {
	my ($self) = @_;

	if ($self->{AID_TYPE} eq "line") {
		return $self->{AGENT}->getLine_PM($self->{AID}, $self->{COUNTER});
	} elsif ($self->{AID_TYPE} eq "sect") {
		return $self->{AGENT}->getSect_PM($self->{AID}, $self->{COUNTER});
	}
}

sub agent {
    my ($self, $agent) = @_;

    if ($agent) {
        $self->{AGENT} = $agent;
    }

    return $self->{AGENT};
}

sub counter {
    my ($self, $counter) = @_;

    if ($counter) {
        $self->{COUNTER} = $counter;
    }

    return $self->{COUNTER};
}

sub aid {
    my ($self, $aid) = @_;

    if ($aid) {
        $self->{AID} = $aid;
    }

    return $self->{AID};
}

sub aid_type {
    my ($self, $aid_type) = @_;

    if ($aid_type and ($aid_type eq "sect" or $aid_type eq "line")) {
        $self->{AID_TYPE} = $aid_type;
    }

    return $self->{AID_TYPE};
}
