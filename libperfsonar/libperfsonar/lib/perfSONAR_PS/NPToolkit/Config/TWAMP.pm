package perfSONAR_PS::NPToolkit::Config::TWAMP;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::NPToolkit::Config::TWAMP

=head1 DESCRIPTION

Module for configuring TWAMP files. Extends OWAMP config just replacing ocations

=cut

use base 'perfSONAR_PS::NPToolkit::Config::OWAMP';

use Params::Validate qw(:all);

# These are the defaults for the current NPToolkit
my %defaults = (
    twampd_limits => "/etc/twamp-server/twamp-server.limits",
    twampd_pfs    => "/etc/twamp-server/twamp-server.pfs",
    twampd_conf   => "/etc/twamp-server/twamp-server.conf",
);

=head2 init({ twampd_limits => 0, twampd_pfs => 0, twampd_conf => 0 })

Initializes the client. Returns 0 on success and -1 on failure. The
twampd_limits and twampd_pfs parameters can be specified to set which files
the module should use for reading/writing the configuration.

=cut

sub init {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            twampd_limits => 0,
            twampd_pfs    => 0,
            twampd_conf   => 0,
        }
    );

    my $res;

    $res = $self->SUPER::init();
    if ( $res != 0 ) {
        return $res;
    }

    # Initialize the defaults - use OWAMP name since that is what parent uses
    $self->{OWAMPD_PFS_FILE}    = $defaults{twampd_pfs};
    $self->{OWAMPD_LIMITS_FILE} = $defaults{twampd_limits};
    $self->{OWAMPD_CONF_FILE}   = $defaults{twampd_conf};

    $self->{OWAMPD_PFS_FILE}    = $parameters->{twampd_pfs}    if ( $parameters->{twampd_pfs} );
    $self->{OWAMPD_LIMITS_FILE} = $parameters->{twampd_limits} if ( $parameters->{twampd_limits} );
    $self->{OWAMPD_CONF_FILE}   = $parameters->{twampd_conf}   if ( $parameters->{twampd_conf} );

    $res = $self->reset_state();
    if ( $res != 0 ) {
        return $res;
    }

    return 0;
}



1;