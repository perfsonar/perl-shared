package perfSONAR_PS::NPToolkit::WebService::Method;

use strict;
use warnings;
use JSON::XS;
use Carp qw( cluck confess );

sub new {
    my $that  = shift;
    my $class =ref($that) || $that;

    my %valid_parameter_list = (
        'expires'           => 1,
        'output_type'       => 1,
        'output_formatter'  => 1,        
        'name'              => 1,
        'callback'          => 1,
        'description'       => 1,
        'auth_required'     => 1,
        'logged_in'         => 1,
        'is_default'        => 1,
        'debug'             => 1,
    );

    # set the defaults
    my %args = (
        expires             => "-1d",
        output_type         => "application/json",
        output_formatter    => sub { encode_json( shift ) },
        name                => undef,
        callback            => undef,
        description         => undef,
        auth_required       => 0,
        logged_in           => 0,
        debug               => 0,
        @_
    );

    my $self = \%args;

    bless $self,$class;

    # validate the parameter list

    # only valid parameters
    foreach my $passed_param (keys %$self) {
        if (!(exists $valid_parameter_list{$passed_param})) {
            Carp::confess("invalid parameter [$passed_param]");
            return;
        }
    }
    # missing required parameters
    if (!defined $self->{'name'}) {
        Carp::confess("methods need a name");
        return;
    }
    if (!defined $self->{'description'}) {
        Carp::confess("methods need a description");
        return;
    }
    if (!defined $self->{'callback'}) {
        Carp::confess("need to define a proper callback");
        return;
    }

    return $self;

}

sub handle_request {
    my ($self, $cgi, $fh) = @_;

    if ( $self->{'auth_required'} == 1 && ( !defined( $cgi->auth_type() ) || $cgi->auth_type() eq '' )) {
        $self->_return_error(401, "Unauthorized");
        return;
    }

    # call the callback
    my $callback    = $self->{'callback'};
    my $results     =  &$callback($self);

    if (!defined $results) {
        $self->_return_error();
        return;
    } else {
        return $self->_return_results($results);
    }

}

sub set_router {
    my ($self, $router)  = @_;
    $self->{router} = $router;
}


sub _return_results {
    my ($self, $results) = @_;
    return $results;    
}

sub _return_error {
    my ($self, $error_code, $error_message) = @_;
    $self->{error_code} = $error_code || 500;
    $self->{error_message} = $error_message if (defined $error_message);

    return;

}

1;
