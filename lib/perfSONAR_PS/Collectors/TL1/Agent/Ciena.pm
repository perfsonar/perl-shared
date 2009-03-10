package perfSONAR_PS::Collectors::TL1::Agent::Ciena;

use strict;
use warnings;
use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Utils::ParameterValidation;

our $VERSION = 0.09;

use base 'perfSONAR_PS::Collectors::TL1::Agent::Base';

use fields

sub new {
    my ($class) = @_;

    my $self = fields::new($class);
}

sub init {
    my ($self, $conf) = @_;

    unless ($conf->{PORT}) {
        $conf->{PORT} = 10201;
    }

    $self->SUPER::init($conf);

    return $self;
}

sub run {
	my ($self) = @_;

}
