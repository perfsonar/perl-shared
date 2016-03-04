package perfSONAR_PS::NPToolkit::WebService::Method;

use strict;
use warnings;
use JSON::XS;
use Carp qw( cluck confess );
use perfSONAR_PS::NPToolkit::WebService::Auth qw( is_authenticated  );
use perfSONAR_PS::NPToolkit::WebService::ParameterTypes;
use Data::Dumper;

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
        'authenticated'     => 1,
        'is_default'        => 1,
        'debug'             => 1,
        'request_methods'   => 1,
        'min_params'        => 1,
        'input_params'      => 1,
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
        authenticated       => 0,
        debug               => 0,
        request_methods     => undef,
        min_params          => 0,
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

    if( is_authenticated($cgi) ){
        $self->{authenticated} = 1;
    }
    if ( $self->{'auth_required'} == 1 && !$self->{authenticated} ) { 
        $self->_return_error(401, "Unauthorized");
        return;
    }

    my $method = $cgi->request_method();
    if ( defined ($self->{'request_methods'} )
            && !grep { $method eq $_ } @{$self->{'request_methods'}} ) { 
        $self->_return_error(405, "Method Not Allowed; Allowed: " . join ', ', @{$self->{'request_methods'}});
        return;
    }


    my $res = $self->_parse_input_parameters( $cgi );
    if (!defined $res) {
        #$self->_return_error(400, "Invalid parameters");
        return $res;
    }

    # call the callback
    my $callback    = $self->{'callback'};
    my $args = $self->{'input_params'};
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

sub add_input_parameter {
    my $self = shift;
    my %args = (
        type => 'text',
        required => 1,
        min_length => undef,
        max_length => 512,
        allow_empty => 1,
        multiple    => 0,
        @_
    );

    if (!defined $args{'name'}) {
        Carp::confess("name is a required parameter");
        return;
    }

    if (!defined $args{'description'}) {
        Carp::confess("description is a required parameter");
        return;
    }

    if (!exists $parameter_types->{ $args{'type'} } ) {
        Carp::confess("Invalid parameter type " . $args{'type'});
        return;
    }

    my $parameter_type = $parameter_types->{ $args{'type'} };
    my $name = $args{'name'};
    $args{'pattern'} = $parameter_type->{'pattern'};
    $args{'error_text'} = "Parameter '$name' " . $parameter_type->{'error_text'};

    $self->{'input_params'}{ $name } = \%args;

    return 1;
}

sub get_input_parameters {
    my $self = shift;
    my @params = ();
    while( my ($key, $val) = each %{ $self->{'input_params'} } ) {
        my %param = ();
        $param{'name'} = $key;
        $param{'description'} = $val->{'description'} if defined $val->{'description'};
        $param{'type'} = $val->{'type'} if defined $val->{'type'};
        push @params, \%param;
    }
    if (@params) {
        return \@params;
    } else {
        return;
    }
}

sub _parse_input_parameters {
    my ($self, $cgi) = @_;
    my $params = $self->{'input_params'} || {};

    # If there are no parameters, return success
    if (keys %$params == 0) {
        return 1;
    }

    my $min_params = $self->{'min_params'};
    my $set_params = {};
    # process each parameter
    foreach my $param_name(sort keys (%{$params})) {
        my $param = $params->{$param_name};
        my $type = $param->{'type'};
        my $required = $param->{'required'};
        my $min_length = $param->{'min_length'};
        my $max_length = $param->{'max_length'};
        my $allow_empty = $param->{'allow_empty'};
        my $multiple = $param->{'multiple'};

        # TODO: add min and max numerical value constraints

        my $value;
        my @role_values = $cgi->param('role');
        if (defined $cgi->param($param_name)) { 
            if ($param->{'multiple'} == 0) {
                $value = $cgi->param($param_name);
            } else {
                my @values = $cgi->param($param_name);
                $value = \@values;
            } 
        } elsif (defined $cgi->url_param($param_name)) {
            if ($param->{'multiple'} == 0) {
                $value = $cgi->url_param($param_name);
            } else {
                my @values = $cgi->url_param($param_name);
                $value = \@values;
            }

        }

        undef($self->{'input_params'}{$param_name}{'value'});
        $self->{'input_params'}{$param_name}{'is_set'} = 0;

        if ( ! defined($value) ) {
           if ($required ) {
                $self->_return_error(400, "Required input parameter ${param_name} is missing");
                return;
            } else {
                next;
            }
        }

        # trim whitespace from beginning and end
        $value =~ s/^\s+|\s+$//g;

        if ( $value eq '' and !$allow_empty ) {
            $self->_return_error(400, "Required input parameter ${param_name} is empty");
            return;
        }

        if ( defined ($min_length) && length($value) < $min_length) {
            $self->_return_error(400, "Input parameter ${param_name} is shorter than the minimum required length of $min_length");
            return;
        }

        if ( defined ($max_length) && length($value) > $max_length) {
            $self->_return_error(400, "Input parameter ${param_name} is longer than the maximum allowed length of $max_length");
            return;
        }

        # If it's a multiple value and it is an array like [ "" ]
        # then just make it an empty array
        # (this is what happens when the user supplies an empty value for 
        # multiple value type parameter)
        if ( $multiple == 1 && @$value && @$value == 1 && $value->[0] eq '' ) {
            $value = [];
        }

        my $pattern = $parameter_types->{$type}->{'pattern'}; 
        my $error_text = $parameter_types->{$type}->{'error_text'}; 
        if ( ( $value !~ /$pattern/ and $value ne ''  )  || ($value eq '' and !$allow_empty) ) {
            $self->_return_error(400, "Input parameter ${param_name} $error_text");

            return;

        }

        $self->{'input_params'}{$param_name}{'value'} = $value;
        $self->{'input_params'}{$param_name}{'is_set'} = 1;
        $self->{'set_params'}{$param_name} = $self->{'input_params'}{$param_name};

    }
    if (scalar keys %{$self->{'set_params'}} < $min_params) {
        $self->_return_error(400, "Must provide at least $min_params parameter(s)");
        return;
    }

}

sub _return_results {
    my ($self, $results) = @_;
    return $results;
}

sub _return_error {
    my ($self, $error_code, $error_message) = @_;
    $self->{error_code} = $error_code || 500;
    if ( ( not defined $error_message ) && defined $self->{'error_message'}) {
        $error_message = $self->{'error_message'};
    }
    $self->{error_message} = $error_message if (defined $error_message);

    return;
}

1;
