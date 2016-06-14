package perfSONAR_PS::NPToolkit::Config::RegularTesting;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::NPToolkit::Config::RegularTesting

=head1 DESCRIPTION

Module is a catch-all for configuring with Regular Testing tests.  In this
model, there are only tests. These tests can them have members added to them.
These members can either be hostnames, IPv4 or IPv6 addresses. The module then
takes care to make sure that these concepts can be done using the Regular
Testing model. The model currently assumes that in star configuration, the
center is always the local host.

=cut

use base 'perfSONAR_PS::NPToolkit::Config::Base';

use fields 'EXISTING_CONFIGURATION', 'TESTS', 'LOCAL_PORT_RANGES', 'REGULAR_TESTING_CONFIG_FILE';

use Params::Validate qw(:all);
use Storable qw(store retrieve freeze thaw dclone);

use JSON;

use Data::Dumper;
use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;

use perfSONAR_PS::RegularTesting::Config;
use perfSONAR_PS::RegularTesting::Test;
use perfSONAR_PS::RegularTesting::Target;
use perfSONAR_PS::RegularTesting::Schedulers::Streaming;
use perfSONAR_PS::RegularTesting::Tests::Powstream;
use perfSONAR_PS::RegularTesting::Schedulers::RegularInterval;
use perfSONAR_PS::RegularTesting::Tests::Bwctl;
use perfSONAR_PS::RegularTesting::Tests::Bwtraceroute;
use perfSONAR_PS::RegularTesting::Tests::Bwping;

use perfSONAR_PS::Common qw(genuid);

use perfSONAR_PS::RegularTesting::Utils::ConfigFile qw( parse_file save_string );

use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file restart_service stop_service );

# These are the defaults for the current NPToolkit
my %defaults = (
    regular_testing_config_file => "/etc/perfsonar/regulartesting.conf",
    traceroute_test_parameters => {
        description => "perfSONAR Toolkit Default Traceroute Test",
        test_interval => 600,
    },
);

=head2 init({ perfsonarbuoy_conf_template => 0, perfsonarbuoy_conf_file => 0, pinger_landmarks_file => 0 })

Initializes the client. Returns 0 on success and -1 on failure. The parameters
can be specified to set which files the module should use for reading/writing
the configuration.

=cut

sub init {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            regular_testing_config_file => 0,
        }
    );

    my ( $status, $res );

    ( $status, $res ) = $self->SUPER::init();
    if ( $status != 0 ) {
        return ( $status, $res );
    }

    # Initialize the defaults
    $self->{REGULAR_TESTING_CONFIG_FILE}  = $parameters->{regular_testing_config_file};

    $self->{REGULAR_TESTING_CONFIG_FILE}  = $defaults{regular_testing_config_file} unless $self->{REGULAR_TESTING_CONFIG_FILE};

    ( $status, $res ) = $self->reset_state();
    if ( $status != 0 ) {
        return ( $status, $res );
    }

    return ( 0, "" );
}

=head2 save({ restart_services => 0 })
    Saves the configuration to disk. The Regular Testing service can be
    restarted by specifying the "restart_services" parameter as 1. 
=cut

sub save {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { restart_services => 0, } );

    my ($status, $res);

    ($status, $res) = $self->generate_regular_testing_config();

    my $local_regular_testing_config_output = $res;

    $res = save_file( { file => $self->{REGULAR_TESTING_CONFIG_FILE}, content => $local_regular_testing_config_output } );
    if ( $res == -1 ) {
        return ( -1, "Couldn't save Regular Testing configuration" );
    }

    if ( $parameters->{restart_services} ) {
        $status = restart_service( { name => "regular_testing" } );
        if ( $status != 0 ) {
            return ( -1, "Problem running Regular Testing Agent" );
        }
    }

    return ( 0, "" );
}

=head2 last_modified()
    Returns when the site information was last saved.
=cut

sub last_modified {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my ($mtime) = (stat ( $self->{REGULAR_TESTING_CONFIG_FILE} ) )[9];

    return $mtime;
}

=head2 reset_state()
    Resets the state of the module to the state immediately after having run "init()".
=cut

sub reset_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    # Reset the tests
    $self->{TESTS} = ();

    my ( $status, $res );

    ( $status, $res ) = $self->parse_regular_testing_config({ file => $self->{REGULAR_TESTING_CONFIG_FILE} });
    if ( $status != 0 ) {
        $self->{TESTS} = {};
        $self->{LOGGER}->error( "Problem reading Regular Testing JSON: $res" );
        return ( -1, "Problem reading Regular Testing Configuration: $res" );
    }

    return ( 0, "" );
}

sub set_local_port_range {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_type => 1, min_port => 1, max_port => 1 } );

    my $test_type = $parameters->{test_type};
    my $min_port  = $parameters->{min_port};
    my $max_port  = $parameters->{max_port};

    unless ($test_type eq "pinger" or $test_type eq "owamp" or $test_type eq "bwctl_throughput") {
        return (-1, "Unknown test type: $test_type");
    }

    if ($test_type eq "owamp") {
        if ($max_port - $min_port < 3) {
            return (-1, "Invalid port range: must have at least 3 ports for owamp tests");
        }
    }

    if ($max_port < $min_port) {
        return (-1, "Invalid port range: min port < max port");
    }

    $self->{LOCAL_PORT_RANGES}->{$test_type}->{min_port} = $min_port;
    $self->{LOCAL_PORT_RANGES}->{$test_type}->{max_port} = $max_port;

    return (0, "");
}

sub get_local_port_range {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_type => 1 } );

    my $test_type = $parameters->{test_type};

    unless ($test_type eq "pinger" or $test_type eq "owamp" or $test_type eq "bwctl_throughput") {
        return (-1, "Unknown test type: $test_type");
    }

    return (0, $self->{LOCAL_PORT_RANGES}->{$test_type});
}

sub reset_local_port_range {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_type => 1 } );

    my $test_type = $parameters->{test_type};

    unless ($test_type eq "pinger" or $test_type eq "owamp" or $test_type eq "bwctl_throughput") {
        return (-1, "Unknown test type: $test_type");
    }

    delete($self->{LOCAL_PORT_RANGES}->{$test_type}) if ($self->{LOCAL_PORT_RANGES}->{$test_type});

    return (0, "");
}

=head2 get_tests({})
    Returns the set of tests as an array of hashes. Returns (0, \@tests) on success.
=cut

sub get_tests {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my @tests = ();
    foreach my $key ( sort keys %{ $self->{TESTS} } ) {
        #$self->{LOGGER}->debug("lookup up test: ".$key.": ".Dumper($self->{TESTS}));
        my ( $status, $res ) = $self->lookup_test( { test_id => $key } );

        push @tests, $res;
    }
    return ( 0, \@tests );
}

=head2 lookup_test({ test_id => 1 })
    Returns the test with the specified test identifier. Returns (-1,
    $error_msg) on failure and (0, \%test_info) on success. \%test_info is a
    hash containing the test properties (description, parameters, members,
    etc).
=cut

sub lookup_test {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_id => 1, } );

    my $test_id = $parameters->{test_id};

    my $test = $self->{TESTS}->{$test_id};

    return ( -1, "Invalid test specified" ) unless ( $test );

    my %test_info = ();
    $test_info{id}          = $test_id;
    $test_info{type}        = $test->{type};
    $test_info{description} = $test->{description};
    $test_info{disabled}    = $test->{disabled};
    $test_info{parameters}  = $test->{parameters};
    $test_info{added_by_mesh} = $test->{added_by_mesh};

    my @members = ();
    foreach my $member_id ( keys %{ $test->{members} } ) {
        push @members, $test->{members}->{$member_id};
    }

    $test_info{members} = \@members;

    return ( 0, \%test_info );
}


=head2 add_test_owamp({ mesh_type => 1, name => 0, description => 1, packet_padding => 1, packet_interval => 1, bucket_width => 1, loss_threshold => 1, session_count => 1, disabled => 0 })
    Adds a new OWAMP test to the list. mesh_type must be "star" as mesh tests
    aren't currently supported. 'name' can be used to give the test the name
    that will be used in the owmesh file which would be autogenerated
    otherwise. packet_padding, packet_interval, bucket_width, loss_threshold and
    session_count correspond to the pSB powstream test parameters. Returns (-1, $error_msg)
    on failure and (0, $test_id) on success.
=cut 

sub add_test_owamp {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            name             => 0,
            description      => 1,
            packet_interval  => 1,
            sample_count     => 1,
            packet_padding   => 1,
            loss_threshold   => 0,
            session_count    => 0,
            bucket_width     => 0,
            test_interval    => 0,
            test_schedule    => 0,
            added_by_mesh    => 0,
            local_interface  => 0,
            disabled         => 0,
        }
    );

    $self->{LOGGER}->debug( "Adding owamp test" );

    my $test_id;
    do {
        $test_id = "test." . genuid();
    } while ( $self->{TESTS}->{$test_id} );

    my %test = ();
    $test{id}          = $test_id;
    $test{type}        = "owamp";
    $test{name}        = $parameters->{name};
    $test{description} = $parameters->{description} if ( defined $parameters->{description} );
    $test{added_by_mesh} = $parameters->{added_by_mesh};
    $test{disabled} = $parameters->{disabled} if ( defined $parameters->{disabled} );

    my %test_parameters = ();
    $test_parameters{packet_interval}  = $parameters->{packet_interval}  if ( defined $parameters->{packet_interval} );
    $test_parameters{loss_threshold}   = $parameters->{loss_threshold}   if ( defined $parameters->{loss_threshold} );
    $test_parameters{session_count}    = $parameters->{session_count}    if ( defined $parameters->{session_count} );
    $test_parameters{sample_count}     = $parameters->{sample_count}     if ( defined $parameters->{sample_count} );
    $test_parameters{packet_padding}   = $parameters->{packet_padding}   if ( defined $parameters->{packet_padding} );
    $test_parameters{bucket_width}     = $parameters->{bucket_width}     if ( defined $parameters->{bucket_width} );
    $test_parameters{test_interval}    = $parameters->{test_interval}    if ( defined $parameters->{test_interval} );
    $test_parameters{test_schedule}    = $parameters->{test_schedule}    if ( defined $parameters->{test_schedule} );
    $test_parameters{local_interface}  = $parameters->{local_interface}  if ( defined $parameters->{local_interface} );

    $test{parameters} = \%test_parameters;

    my %tmp = ();
    $test{members} = \%tmp;

    $self->{TESTS}->{$test_id} = \%test;

    return ( 0, $test_id );
}

=head2 update_test_owamp({ test_id => 1, name => 0, description => 0, packet_padding => 0, packet_interval => 0, bucket_width => 0, loss_threshold => 0, session_count => 0, disabled => 0 })
    Updates a existing OWAMP test. 'name' can be used to give the test the name
    that will be used in the owmesh file which would be autogenerated
    otherwise. packet_padding, packet_interval, bucket_width, loss_threshold and
    session_count correspond to the pSB powstream test parameters. Returns
    (-1, $error_msg) on failure and (0, "") on success.
=cut

sub update_test_owamp {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id          => 1,
            name             => 0,
            description      => 0,
            bucket_width     => 0,
            packet_padding   => 0,
            loss_threshold   => 0,
            packet_interval  => 0,
            session_count    => 0,
            sample_count     => 0,
            local_interface  => 0,
            disabled         => 0,
        }
    );

    $self->{LOGGER}->debug( "Updating owamp test " . $parameters->{test_id} );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );
    return ( -1, "Test is not owamp" ) unless ( $test->{type} eq "owamp" );
    return ( -1, "Test was added by the mesh configuration agent. It can't be updated.") if ($test->{added_by_mesh});


    $test->{name}                           = $parameters->{name}             if ( defined $parameters->{name} );
    $test->{description}                    = $parameters->{description}      if ( defined $parameters->{description} );
    $test->{disabled}                       = $parameters->{disabled}      if ( defined $parameters->{disabled} );
    $test->{parameters}->{packet_interval}  = $parameters->{packet_interval}  if ( defined $parameters->{packet_interval} );
    $test->{parameters}->{loss_threshold}   = $parameters->{loss_threshold}   if ( defined $parameters->{loss_threshold} );
    $test->{parameters}->{session_count}    = $parameters->{session_count}    if ( defined $parameters->{session_count} );
    $test->{parameters}->{sample_count}     = $parameters->{sample_count}     if ( defined $parameters->{sample_count} );
    $test->{parameters}->{packet_padding}   = $parameters->{packet_padding}   if ( defined $parameters->{packet_padding} );
    $test->{parameters}->{bucket_width}     = $parameters->{bucket_width}     if ( defined $parameters->{bucket_width} );
    $test->{parameters}->{local_interface}  = $parameters->{local_interface}  if ( defined $parameters->{local_interface} );

    return ( 0, "" );
}

=head2 add_test_bwctl_throughput({ name => 0, description => 1, tool => 1, test_interval => 1, duration => 1, protocol => 1, udp_bandwidth => 0, buffer_length => 0, window_size => 0, report_interval => 0, test_interval_start_alpha => 0, tos_bits => 0, streams => 0, omit_interval => 0, send_only, receive_only, disabled => 0 })
    Adds a new BWCTL throughput test to the list.  'name' can be used to give
    the test the name that will be used in the owmesh file which would be
    autogenerated otherwise. tool, test_interval, duration, protocol,
    udp_bandwidth, buffer_length, window_size, report_interval,
    test_interval_start_alpha all correspond to the pSB throughput test
    parameters.

    Returns (-1, $error_msg) on failure and (0, $test_id) on success.
=cut

sub add_test_bwctl_throughput {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            name                      => 0,
            description               => 1,
            tool                      => 1,
            test_interval             => 0,
            test_schedule             => 0,
            duration                  => 1,
            protocol                  => 1,
            udp_bandwidth             => 0,
            buffer_length             => 0,
            window_size               => 0,
            report_interval           => 0,
            test_interval_start_alpha => 0,
            added_by_mesh             => 0,
            tos_bits                  => 0,
            streams                   => 0,
            omit_interval             => 0,
            send_only                 => 0,
            receive_only              => 0,
            local_interface           => 0,
            disabled                  => 0,
        }
    );

    $self->{LOGGER}->debug( "Add bwctl: " . Dumper( $parameters ) );

    my $test_id;
    do {
        $test_id = "test." . genuid();
    } while ( $self->{TESTS}->{$test_id} );

    my %test = ();
    $test{id}          = $test_id;
    $test{name}        = $parameters->{name};
    $test{description} = $parameters->{description};
    $test{type}        = "bwctl/throughput";
    $test{added_by_mesh} = $parameters->{added_by_mesh};
    $test{disabled}      = $parameters->{disabled}  if ( defined $parameters->{disabled} );

    my %test_parameters = ();
    $test_parameters{tool}                      = $parameters->{tool}                      if ( defined $parameters->{tool} );
    $test_parameters{test_interval}             = $parameters->{test_interval}             if ( defined $parameters->{test_interval} );
    $test_parameters{test_schedule}             = $parameters->{test_schedule}             if ( defined $parameters->{test_schedule} );
    $test_parameters{duration}                  = $parameters->{duration}                  if ( defined $parameters->{duration} );
    $test_parameters{protocol}                  = $parameters->{protocol}                  if ( defined $parameters->{protocol} );
    $test_parameters{udp_bandwidth}             = $parameters->{udp_bandwidth}             if ( defined $parameters->{udp_bandwidth} );
    $test_parameters{buffer_length}             = $parameters->{buffer_length}             if ( defined $parameters->{buffer_length} );
    $test_parameters{window_size}               = $parameters->{window_size}               if ( defined $parameters->{window_size} );
    $test_parameters{report_interval}           = $parameters->{report_interval}           if ( defined $parameters->{report_interval} );
    $test_parameters{test_interval_start_alpha} = $parameters->{test_interval_start_alpha} if ( defined $parameters->{test_interval_start_alpha} );
    $test_parameters{tos_bits}                  = $parameters->{tos_bits}                  if ( defined $parameters->{tos_bits} );
    $test_parameters{streams}                   = $parameters->{streams}                   if ( defined $parameters->{streams} );
    $test_parameters{omit_interval}             = $parameters->{omit_interval}             if ( defined $parameters->{omit_interval} );
    $test_parameters{send_only}                 = $parameters->{send_only}                 if ( defined $parameters->{send_only} );
    $test_parameters{receive_only}              = $parameters->{receive_only}              if ( defined $parameters->{receive_only} );
    $test_parameters{local_interface}           = $parameters->{local_interface}           if ( defined $parameters->{local_interface} );

    $test{parameters} = \%test_parameters;

    my %tmp = ();
    $test{members} = \%tmp;

    $self->{TESTS}->{$test_id} = \%test;

    return ( 0, $test_id );
}

=head2 update_test_bwctl_throughput({ test_id => 1, name => 0, description => 0, tool => 0, test_interval => 0, duration => 0, protocol => 0, udp_bandwidth => 0, buffer_length => 0, window_size => 0, report_interval => 0, test_interval_start_alpha => 0, tos_bits => 0, streams => 0, omit_interval => 0, send_only => 0, receive_only => 0 })
    Updates an existing BWCTL throughput test. mesh_type must be "star" as mesh tests
    aren't currently supported. 'name' can be used to give the test the name
    that will be used in the owmesh file which would be autogenerated
    otherwise. tool, test_interval, duration, protocol, udp_bandwidth,
    buffer_length, window_size, report_interval, test_interval_start_alpha all
    correspond to the pSB throughput test parameters. Returns (-1, $error_msg)
    on failure and (0, "") on success.
=cut

sub update_test_bwctl_throughput {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id       => 1,
            name          => 0,
            description   => 0,
            test_interval => 0,
            test_schedule => 0,
            tool          => 0,
            duration      => 0,
            protocol      => 0,
            udp_bandwidth => 0,
            buffer_length => 0,
            window_size   => 0,
            tos_bits      => 0,
            streams       => 0,
            omit_interval => 0,
            send_only     => 0,
            receive_only  => 0,
            local_interface => 0,
        }
    );

    $self->{LOGGER}->debug( "Updating bwctl test " . $parameters->{test_id} );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );
    return ( -1, "Test is not bwctl/throughput" ) unless ( $test->{type} eq "bwctl/throughput" );
    return ( -1, "Test was added by the mesh configuration agent. It can't be updated.") if ($test->{added_by_mesh});


    $test->{name}                                    = $parameters->{name}                      if ( defined $parameters->{name} );
    $test->{description}                             = $parameters->{description}               if ( defined $parameters->{description} );
    $test->{parameters}->{tool}                      = $parameters->{tool}                      if ( defined $parameters->{tool} );
    $test->{parameters}->{test_interval}             = $parameters->{test_interval}             if ( defined $parameters->{test_interval} );
    $test->{parameters}->{test_schedule}             = $parameters->{test_schedule}             if ( defined $parameters->{test_schedule} );
    $test->{parameters}->{duration}                  = $parameters->{duration}                  if ( defined $parameters->{duration} );
    $test->{parameters}->{protocol}                  = $parameters->{protocol}                  if ( defined $parameters->{protocol} );
    $test->{parameters}->{udp_bandwidth}             = $parameters->{udp_bandwidth}             if ( exists $parameters->{udp_bandwidth} );
    $test->{parameters}->{buffer_length}             = $parameters->{buffer_length}             if ( exists $parameters->{buffer_length} );
    $test->{parameters}->{window_size}               = $parameters->{window_size}               if ( exists $parameters->{window_size} );
    $test->{parameters}->{report_interval}           = $parameters->{report_interval}           if ( exists $parameters->{report_interval} );
    $test->{parameters}->{test_interval_start_alpha} = $parameters->{test_interval_start_alpha} if ( exists $parameters->{test_interval_start_alpha} );
    $test->{parameters}->{tos_bits}                  = $parameters->{tos_bits}                  if ( exists $parameters->{tos_bits} );
    $test->{parameters}->{streams}                   = $parameters->{streams}                   if ( exists $parameters->{streams} );
    $test->{parameters}->{omit_interval}             = $parameters->{omit_interval}             if ( exists $parameters->{omit_interval} );
    $test->{parameters}->{send_only}                 = $parameters->{send_only}                 if ( defined $parameters->{send_only} );
    $test->{parameters}->{receive_only}              = $parameters->{receive_only}              if ( defined $parameters->{receive_only} );
    $test->{parameters}->{local_interface}           = $parameters->{local_interface}  if ( defined $parameters->{local_interface} );

    return ( 0, "" );
}

=head2 add_test_pinger({ description => 0, packet_size => 1, packet_count => 1, packet_interval => 1, test_interval => 1, test_offset => 1, ttl => 1, disabled => 0 })

    Adds a new ping test to the list. packet_size, packet_count,
    packet_interval, test_interval, test_offset, ttl all correspond to ping
    test parameters. Returns (-1, $error_msg) on failure and (0, $test_id) on
    success.

=cut

sub add_test_pinger {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            description     => 0,
            packet_size     => 1,
            packet_count    => 1,
            packet_interval => 1,
            test_interval   => 1,
            test_schedule   => 0,
            test_offset     => 0,
            ttl             => 1,
            added_by_mesh   => 0,
            local_interface => 0,
            disabled        => 0,
        }
    );

    my $description     = $parameters->{description};
    my $packet_interval = $parameters->{packet_interval};
    my $packet_count    = $parameters->{packet_count};
    my $packet_size     = $parameters->{packet_size};
    my $test_interval   = $parameters->{test_interval};
    my $test_schedule   = $parameters->{test_schedule};
    my $test_offset     = $parameters->{test_offset};
    my $ttl             = $parameters->{ttl};
    my $local_interface = $parameters->{local_interface};
    my $disabled        = $parameters->{disabled};

    my $test_id;

    # Find an empty domain
    do {
        $test_id = "test." . genuid();
    } while ( $self->{TESTS}->{$test_id} );

    my %members   = ();
    my %test_info = (
        id          => $test_id,
        type        => "pinger",
        description => $description,
        added_by_mesh => $parameters->{added_by_mesh},
        disabled        => $disabled,
        parameters  => {
            packet_interval => $packet_interval,
            packet_count    => $packet_count,
            packet_size     => $packet_size,
            test_interval   => $test_interval,
            test_schedule   => $test_schedule,
            test_offset     => $test_offset,
            ttl             => $ttl,
            local_interface => $local_interface,
        },
        members => \%members,
    );

    $self->{TESTS}->{$test_id} = \%test_info;

    return ( 0, $test_id );
}

=head2 update_test_pinger({ description => 0, packet_size => 0, packet_count => 0, packet_interval => 0, test_interval => 0, test_offset => 0, ttl => 0, disabled => 0 })

    Updates an existing ping test. packet_size, packet_count,
    packet_interval, test_interval, test_offset, ttl all correspond to ping
    test parameters. Returns (-1, $error_msg) on failure and (0, $test_id) on
    success.

=cut

sub update_test_pinger {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id => 1,

            description     => 0,
            packet_interval => 0,
            packet_count    => 0,
            packet_size     => 0,
            test_interval   => 0,
            test_schedule   => 0,
            test_offset     => 0,
            ttl             => 0,
            local_interface => 0,
            disabled        => 0,
        }
    );

    my $test_id = $parameters->{test_id};

    my $test = $self->{TESTS}->{$test_id};

    return ( -1, "Invalid test specified" ) unless ( $test );
    return ( -1, "Test was added by the mesh configuration agent. It can't be updated.") if ($test->{added_by_mesh});

    $test->{description} = $parameters->{description} if ( defined $parameters->{description} );
    $test->{disabled}    = $parameters->{disabled} if ( defined $parameters->{disabled} );

    $test->{parameters}->{packet_interval} = $parameters->{packet_interval} if ( defined $parameters->{packet_interval} );
    $test->{parameters}->{packet_count}    = $parameters->{packet_count}    if ( defined $parameters->{packet_count} );
    $test->{parameters}->{packet_size}     = $parameters->{packet_size}     if ( defined $parameters->{packet_size} );
    $test->{parameters}->{test_interval}   = $parameters->{test_interval}   if ( defined $parameters->{test_interval} );
    $test->{parameters}->{test_schedule}   = $parameters->{test_schedule}   if ( defined $parameters->{test_schedule} );
    $test->{parameters}->{test_offset}     = $parameters->{test_offset}     if ( defined $parameters->{test_offset} );
    $test->{parameters}->{ttl}             = $parameters->{ttl}             if ( defined $parameters->{ttl} );
    $test->{parameters}->{local_interface} = $parameters->{local_interface}  if ( defined $parameters->{local_interface} );

    return ( 0, "" );
}

=head2 add_test_traceroute({ name => 0, description => 1, test_interval => 1, packet_size => 0, timeout => 0, waittime => 0, first_ttl => 0, max_ttl => 0, pause => 0, protocol => 0, disabled => 0 })
    Add a new traceroute test of type STAR to the owmesh file. All parameters correspond
    to test parameters. Returns (-1, error_msg)  on failure and (0, $test_id) on success.
=cut

sub add_test_traceroute {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            name          => 0,
            description   => 1,
            test_interval => 1,
            test_schedule => 0,
            packet_size   => 0,
            timeout       => 0,
            waittime      => 0,
            first_ttl     => 0,
            max_ttl       => 0,
            pause         => 0,
            protocol      => 0,
            added_by_mesh => 0,
            local_interface => 0,
            tool            => 0,
            disabled        => 0,
        }
    );

    $self->{LOGGER}->debug( "Add: " . Dumper( $parameters ) );

    my $test_id;
    do {
        $test_id = "test." . genuid();
    } while ( $self->{TESTS}->{$test_id} );

    my %test = ();
    $test{id}          = $test_id;
    $test{name}        = $parameters->{name};
    $test{description} = $parameters->{description};
    $test{disabled}    = $parameters->{disabled} if ( defined $parameters->{disabled} );
    $test{type}        = "traceroute";
    $test{added_by_mesh} = $parameters->{added_by_mesh};

    my %test_parameters = ();
    $test_parameters{test_interval}             = $parameters->{test_interval}             if ( defined $parameters->{test_interval} );
    $test_parameters{test_schedule}             = $parameters->{test_schedule}             if ( defined $parameters->{test_schedule} );
    $test_parameters{packet_size}               = $parameters->{packet_size}               if ( defined $parameters->{packet_size} );
    $test_parameters{timeout}                   = $parameters->{timeout}                   if ( defined $parameters->{timeout} );
    $test_parameters{waittime}                  = $parameters->{waittime}                  if ( defined $parameters->{waittime} );
    $test_parameters{first_ttl}                 = $parameters->{first_ttl}                 if ( defined $parameters->{first_ttl} );
    $test_parameters{max_ttl}                   = $parameters->{max_ttl}                   if ( defined $parameters->{max_ttl} );
    $test_parameters{pause}                     = $parameters->{pause}                     if ( defined $parameters->{pause} );
    $test_parameters{protocol}                  = $parameters->{protocol}                  if ( defined $parameters->{protocol} );
    $test_parameters{local_interface}           = $parameters->{local_interface}           if ( defined $parameters->{local_interface} );
    $test_parameters{tool}                      = $parameters->{tool}                      if ( defined $parameters->{tool} );

    $test{parameters} = \%test_parameters;

    my %tmp = ();
    $test{members} = \%tmp;

    $self->{TESTS}->{$test_id} = \%test;

    return ( 0, $test_id );
}

=head2 update_test_traceroute({ name => 0, description => 1, test_interval => 1, packet_size => 0, timeout => 0, waittime => 0, first_ttl => 0, max_ttl => 0, pause => 0, protocol => 0, disabled => 0 })
    Updates an existing traceroute test. All other parameters corresponf to
    test parameters.

    Returns (-1, $error_msg) on failure and (0, "") on success.
=cut

sub update_test_traceroute {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id       => 1,
            name          => 0,
            description   => 0,
            test_interval => 0,
            test_schedule => 0,
            packet_size   => 0,
            timeout       => 0,
            waittime      => 0,
            first_ttl     => 0,
            max_ttl       => 0,
            pause         => 0,
            protocol      => 0,
            local_interface => 0,
            tool          => 0,
            disabled      => 0,
        }
    );

    $self->{LOGGER}->debug( "Updating traceroute test " . $parameters->{test_id} );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );
    return ( -1, "Test is not traceroute" ) unless ( $test->{type} eq "traceroute" );


    $test->{name}                                    = $parameters->{name}                      if ( defined $parameters->{name} );
    $test->{description}                             = $parameters->{description}               if ( defined $parameters->{description} );
    $test->{disabled}    = $parameters->{disabled} if ( defined $parameters->{disabled} );
    $test->{parameters}->{test_interval}             = $parameters->{test_interval}             if ( defined $parameters->{test_interval} );
    $test->{parameters}->{test_schedule}             = $parameters->{test_schedule}             if ( defined $parameters->{test_schedule} );
    $test->{parameters}->{packet_size}               = $parameters->{packet_size}               if ( defined $parameters->{packet_size} );
    $test->{parameters}->{timeout}                   = $parameters->{timeout}                   if ( defined $parameters->{timeout} );
    $test->{parameters}->{waittime}                  = $parameters->{waittime}                  if ( defined $parameters->{waittime} );
    $test->{parameters}->{first_ttl}                 = $parameters->{first_ttl}                 if ( defined $parameters->{first_ttl} );
    $test->{parameters}->{max_ttl}                   = $parameters->{max_ttl}                   if ( defined $parameters->{max_ttl} );
    $test->{parameters}->{pause}                     = $parameters->{pause}                     if ( defined $parameters->{pause} );
    $test->{parameters}->{protocol}                  = $parameters->{protocol}                  if ( defined $parameters->{protocol} );
    $test->{parameters}->{local_interface}           = $parameters->{local_interface}           if ( defined $parameters->{local_interface} );
    $test->{parameters}->{tool}                      = $parameters->{tool}                      if ( defined $parameters->{tool} );
    
    return ( 0, "" );
}

=head2 enable_test ({ test_id => 1 })
    Enables the test with the "test_id" identifier from the list. Returns (0,
    "") if the test no longer is in the least, even if it never was.
=cut

sub enable_test {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_id => 1, } );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );

    return ( -1, "Test was added by the mesh configuration agent. It can't be updated.") if ($test->{added_by_mesh});

    delete($test->{disabled});

    return ( 0, "" );
}

=head2 disable_test ({ test_id => 1 })
    Disables the test with the "test_id" identifier from the list. Returns (0,
    "") if the test no longer is in the least, even if it never was.
=cut

sub disable_test {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_id => 1, } );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );

    return ( -1, "Test was added by the mesh configuration agent. It can't be updated.") if ($test->{added_by_mesh});

    $test->{disabled} = 1;

    return ( 0, "" );
}

=head2 delete_test ({ test_id => 1 })
    Removes the test with the "test_id" identifier from the list. Returns (0,
    "") if the test no longer is in the least, even if it never was.
=cut

sub delete_test {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { test_id => 1, } );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    delete( $self->{TESTS}->{ $parameters->{test_id} } );

    return ( 0, "" );
}

=head2 delete_all_tests ()
    Removes all the tests  from the list. Returns (0,
    "") if the tests were deleted successfully or if no tests were present.
=cut

sub delete_all_tests {
    my ( $self ) = shift;

    $self->{TESTS} =();

    return ( 0, "" );
}

=head2 add_test_member ({ test_id => 1, address => 1, port => 0, name => 0, description => 0, sender => 0, receiver => 0 })
    Adds a new address to the test. Address can be any of hostname/ipv4/ipv6.
    Port specifies which port should be connected to, this is ignored in ping
    tests. The sender/receiver fields can be set to 1 or 0 and specify whether that
    test member should do a send or receive test.
    Returns (0, $member_id) on success and (-1, $error_msg) on failure.
=cut

sub add_test_member {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id     => 1,
            address     => 1,
            port        => 0,
            name        => 0,
            description => 0,
            sender      => 0,
            receiver    => 0,
            test_ipv4   => 0,
            test_ipv6   => 0,
            skip_default_rules => 0,
            id          => 0
        }
    );

    $self->{LOGGER}->debug( "Adding address " . $parameters->{address} . " to test " . $parameters->{test_id} );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );

    my $name    = $parameters->{name};
    my $address = $parameters->{address};

    $address = $1 if ($address =~ /^\[(.*)\]$/);

    my $id;
    do {
        $id = "member." . genuid();
    } while ( $test->{members}->{$id} );

    my %member = ();
    $member{id}          = $id;
    $member{address}     = $address;
    $member{name}        = $name;
    $member{port}        = $parameters->{port};
    $member{description} = $parameters->{description};
    $member{sender}      = $parameters->{sender};
    $member{receiver}    = $parameters->{receiver};
    $member{test_ipv4}   = $parameters->{test_ipv4};
    $member{test_ipv6}   = $parameters->{test_ipv6};

    $test->{members}->{$id} = \%member;

    $self->{LOGGER}->debug("Added new test member: ".Dumper(\%member));

    $self->configure_default_tests() unless $parameters->{skip_default_rules};

    return ( 0, $id );
}

=head2 update_test_member ({ test_id => 1, member_id => 1, port => 0, name => 0, description => 0, sender => 0, receiver => 0 })
    Updates an existing member in a test.  Port specifies which port should be
    connected to. The sender/receiver fields can be set to 1 or 0 and specify
    whether that test member should do a send or receive test.
=cut

sub update_test_member {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id     => 1,
            member_id   => 1,
            address     => 0,
            port        => 0,
            description => 0,
            sender      => 0,
            receiver    => 0,
            test_ipv4   => 0,
            test_ipv6   => 0,
            skip_default_rules => 0,
        }
    );

    $self->{LOGGER}->debug( "Updating test member " . $parameters->{member_id} . " in test " . $parameters->{test_id} );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );

    my $member = $test->{members}->{ $parameters->{member_id} };

    return ( -1, "Test member does not exist" ) unless ( $member );

    $member->{address}     = $parameters->{address}     if ( defined $parameters->{address} );
    $member->{port}        = $parameters->{port}        if ( defined $parameters->{port} );
    $member->{description} = $parameters->{description} if ( defined $parameters->{description} );
    $member->{sender}      = $parameters->{sender}      if ( defined $parameters->{sender} );
    $member->{receiver}    = $parameters->{receiver}    if ( defined $parameters->{receiver} );
    $member->{test_ipv4}   = $parameters->{test_ipv4}   if ( defined $parameters->{test_ipv4} );
    $member->{test_ipv6}   = $parameters->{test_ipv6}   if ( defined $parameters->{test_ipv6} );

    $self->configure_default_tests() unless $parameters->{skip_default_rules};

    return ( 0, "" );
}

=head2 remove_test_member ( { test_id => 1, member_id => 1 })
    Removes the specified member from the test. Returns (-1, $error_msg) if an
    error occurs and (0, "") if the test no longer contains the specified
    member.
=cut

sub remove_test_member {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            test_id   => 1,
            member_id => 1,
            skip_default_rules => 0,
        }
    );

    $self->{LOGGER}->debug( "Removing test member " . $parameters->{member_id} . " from test " . $parameters->{test_id} );

    my $test = $self->{TESTS}->{ $parameters->{test_id} };

    return ( -1, "Test does not exist" ) unless ( $test );

    delete( $test->{members}->{ $parameters->{member_id} } );

    $self->configure_default_tests() unless $parameters->{skip_default_rules};

    return ( 0, "" );
}

=head2 save_state()
    Saves the current state of the module as a string. This state allows the
    module to be recreated later.
=cut

sub save_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my %state = (
        tests                       => $self->{TESTS},
        existing_configuration      => $self->{EXISTING_CONFIGURATION},
        local_port_ranges           => $self->{LOCAL_PORT_RANGES},
        regular_testing_config_file => $self->{REGULAR_TESTING_CONFIG_FILE},
    );

    my $str = freeze( \%state );

    return $str;
}

=head2 restore_state({ state => \$state })
    Restores the modules state based on a string provided by the "save_state"
    function above.
=cut

sub restore_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { state => 1, } );

    my $state = thaw( $parameters->{state} );

    $self->{REGULAR_TESTING_CONFIG_FILE} = $state->{regular_testing_config_file};
    $self->{EXISTING_CONFIGURATION}      = $state->{existing_configuration};
    $self->{TESTS}                       = $state->{tests};
    $self->{LOCAL_PORT_RANGES}           = $state->{local_port_ranges};

    return;
}

sub configure_default_tests {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    # Initialize the default traceroute test, and make sure that its test set
    # are only those hosts that are in non-mesh added, non-traceroute tests.
    foreach my $test ( values %{ $self->{TESTS} } ) {
        next unless ($test->{description} eq $defaults{traceroute_test_parameters}->{description});

        $self->delete_test({ test_id => $test->{id} });
    }

    my ($status, $res) = $self->add_test_traceroute($defaults{traceroute_test_parameters});

    return ($status, $res) unless ($status == 0);

    my $traceroute_test_id = $res;

    my %hosts_to_add = ();
    foreach my $test ( values %{ $self->{TESTS} } ) {
        next if $test->{added_by_mesh} or $test->{type} eq "traceroute";

        foreach my $member (values %{ $test->{members} }) {
            unless ($hosts_to_add{$member->{address}}) {
                my %new_member = %$member;

                $hosts_to_add{$member->{address}} = \%new_member;
            }

            $hosts_to_add{$member->{address}}->{test_ipv4} = 1 if $member->{test_ipv4};
            $hosts_to_add{$member->{address}}->{test_ipv6} = 1 if $member->{test_ipv6};
        }
    }

    # Don't do a default traceroute test if we're already doing one as part of
    # another test
    foreach my $test ( values %{ $self->{TESTS} } ) {
        next unless $test->{type} eq "traceroute";
        foreach my $member (values %{ $test->{members} }) {
            delete($hosts_to_add{$member->{address}});
        }
    }

    foreach my $member (values %hosts_to_add) {
        my ($status, $res) = $self->add_test_member({
                                 test_id     => $traceroute_test_id,
                                 address     => $member->{address},
                                 name        => $member->{name},
                                 description => $member->{description},
                                 sender      => 1,
                                 receiver    => 1,
                                 test_ipv4   => $member->{test_ipv4},
                                 test_ipv6   => $member->{test_ipv6},
                                 skip_default_rules => 1,
                             });
        if ($status != 0) {
            $self->{LOGGER}->warn("Problem adding ".$member->{address}." to default traceroute test: ".$res);
        }
    }

    return (0, "");
}

=head2 parse_regular_testing_config
    Parses the specified mesh file, and loads the tests into the object's
    configuration.
=cut

sub parse_regular_testing_config {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { file => 1, } );
    my $file = $parameters->{file};

    return ( 0, {} ) unless ( -e $file );

    my $config;

    eval {
        my ($status, $res) = parse_file( file => $file );

        $config = perfSONAR_PS::RegularTesting::Config->parse($res);
    };
    if ($@) {
        my $res = "Problem reading Regular Testing configurat: $@";
        $self->{LOGGER}->error( $res );
        return ( -1, $res );
    }

    my @unhandled_tests = ();

    foreach my $test (@{ $config->tests }) {
        my ($status, $res);

        my ($test_schedule, $test_interval);
        if ($test->schedule->can("interval")) {
            $test_interval = $test->schedule->interval;
        }
        elsif ($test->schedule->can("time_slots")) {
            $test_schedule = $test->schedule->time_slots;
        }

        if ($test->parameters->type eq "powstream") {
            ($status, $res) = $self->add_test_owamp({
                                          description => $test->description,
                                          local_interface => $test->local_interface,
                                          packet_interval => $test->parameters->inter_packet_time,
                                          packet_padding => $test->parameters->packet_length,
                                          sample_count => $test->parameters->resolution / $test->parameters->inter_packet_time,
                                          added_by_mesh => $test->added_by_mesh,
                              });
        }
        elsif ($test->parameters->type eq "bwping/owamp") {
            my $interval;
            ($status, $res) = $self->add_test_owamp({
                                          description => $test->description,
                                          local_interface => $test->local_interface,
                                          packet_interval => $test->parameters->inter_packet_time,
                                          packet_padding => $test->parameters->packet_length,
                                          sample_count => $test->parameters->packet_count,
                                          test_interval => $test_interval,
                                          test_schedule => $test_schedule,
                                          added_by_mesh => $test->added_by_mesh,
                              });
        }
        elsif ($test->parameters->type eq "bwping") {
            ($status, $res) = $self->add_test_pinger({
                                          description => $test->description,
                                          local_interface => $test->local_interface,
                                          packet_size => $test->parameters->packet_length,
                                          ttl => $test->parameters->packet_ttl,
                                          packet_count => $test->parameters->packet_count,
                                          packet_interval => $test->parameters->inter_packet_time,

                                          test_interval => $test_interval,
                                          test_schedule => $test_schedule,
                                          added_by_mesh => $test->added_by_mesh,
                              });
        }
        elsif ($test->parameters->type eq "bwtraceroute") {
            ($status, $res) = $self->add_test_traceroute({
                                          description => $test->description,
                                          local_interface => $test->local_interface,
                                          tool => $test->parameters->tool,
                                          packet_size => $test->parameters->packet_length,
                                          first_ttl => $test->parameters->packet_first_ttl,
                                          max_ttl  => $test->parameters->packet_max_ttl,

                                          test_interval => $test_interval,
                                          test_schedule => $test_schedule,
                                          added_by_mesh => $test->added_by_mesh,
                              });
        }
        elsif ($test->parameters->type eq "bwctl") {
            my $protocol = ($test->parameters->use_udp?"udp":"tcp");
            my $window_size = $test->parameters->window_size;
            $window_size /= 1048576 if ( defined ( $window_size ) && $window_size >= 1048576);

            ($status, $res) = $self->add_test_bwctl_throughput({
                                          description => $test->description,
                                          local_interface => $test->local_interface,
                                          tool => $test->parameters->tool,
                                          protocol => $protocol,
                                          duration => $test->parameters->duration,
                                          udp_bandwidth => $test->parameters->udp_bandwidth,
                                          buffer_length => $test->parameters->buffer_length,

                                          tos_bits => $test->parameters->packet_tos_bits,
                                          streams  => $test->parameters->streams,
                                          omit_interval  => $test->parameters->omit_interval,
                                          send_only  => $test->parameters->send_only,
                                          receive_only  => $test->parameters->receive_only,
                                            
                                          #report_interval => $test->parameters->report_interval,
                                          window_size => $window_size,
                                          #test_interval_start_alpha => $test->parameters->random_start_percentage,

                                          test_interval => $test_interval,
                                          test_schedule => $test_schedule,
                                          added_by_mesh => $test->added_by_mesh,
                              });
        }
        else {
            $res = "Invalid test type: ".$test->parameters->type;
            $self->{LOGGER}->error( $res );
            return ( -1, $res );
        }

        if ($status != 0) {
            $res = "Problem adding test: ".$res;
            $self->{LOGGER}->error( $res );
            return ( -1, $res );
        }

        my $test_id = $res;

        foreach my $target (@{ $test->targets }) {
            my ($ipv4, $ipv6) = (1, 1);

            foreach my $params ($test->parameters, $target->override_parameters) {
                next unless $params;

                if ($params->force_ipv4) {
                    $ipv4 = 1;
                    $ipv6 = 0;
                }
                elsif ($params->force_ipv6) {
                    $ipv4 = 0;
                    $ipv6 = 1;
                }
            }

            $self->add_test_member({ test_id => $test_id, address => $target->address, description => $target->description, sender => 1, receiver => 1, test_ipv4 => $ipv4, test_ipv6 => $ipv6 });
        }

        if ($test->disabled) {
            $self->disable_test({ test_id => $test_id });
        }

        push @unhandled_tests, $test if $test->added_by_mesh;
    }

    # Clear out the tests we've handled above
    $config->tests(\@unhandled_tests);

    $self->{EXISTING_CONFIGURATION} = $config->unparse();

    return ( 0, "" );
}

=head2 generate_regular_testing_config()
    Generates a string representation of the tests as a Mesh Config JSON.
=cut
sub generate_regular_testing_config {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { include_mesh_tests => 0 } );
    my $include_mesh_tests = $parameters->{include_mesh_tests};

    my @tests = ();

    # Build test objects
    foreach my $test_desc (values %{ $self->{TESTS} }) {
        my ($parameters, $schedule);

        next if ($test_desc->{added_by_mesh} and not $include_mesh_tests);

        if ($test_desc->{parameters}->{test_interval}) {
            $schedule = perfSONAR_PS::RegularTesting::Schedulers::RegularInterval->new();
            $schedule->interval($test_desc->{parameters}->{test_interval});
        }
        elsif ($test_desc->{parameters}->{test_schedule}) {
            $schedule = perfSONAR_PS::RegularTesting::Schedulers::TimeBasedSchedule->new();
            $schedule->time_slots($test_desc->{parameters}->{test_schedule});
        }
        else {
            $schedule = perfSONAR_PS::RegularTesting::Schedulers::Streaming->new();
        }

        if ($test_desc->{type} eq "owamp") {
            if ($schedule->type eq "streaming") {
                $parameters = perfSONAR_PS::RegularTesting::Tests::Powstream->new();
                my $resolution = $test_desc->{parameters}->{sample_count} * $test_desc->{parameters}->{packet_interval};
                $parameters->resolution($resolution);
            }
            else {
                $parameters = perfSONAR_PS::RegularTesting::Tests::BwpingOwamp->new();
                $parameters->packet_count($test_desc->{parameters}->{sample_count});
            }

            $parameters->packet_length($test_desc->{parameters}->{packet_padding}) if defined $test_desc->{parameters}->{packet_padding};
            $parameters->inter_packet_time($test_desc->{parameters}->{packet_interval}) if defined $test_desc->{parameters}->{packet_interval};
        }
        elsif ($test_desc->{type} eq "bwctl/throughput") {
            $parameters = perfSONAR_PS::RegularTesting::Tests::Bwctl->new();

            $parameters->tool($test_desc->{parameters}->{tool}) if defined $test_desc->{parameters}->{tool};
            $parameters->use_udp(1) if ($test_desc->{parameters}->{protocol} and $test_desc->{parameters}->{protocol} eq "udp");
            $parameters->duration($test_desc->{parameters}->{duration}) if defined $test_desc->{parameters}->{duration};
            $parameters->udp_bandwidth($test_desc->{parameters}->{udp_bandwidth}) if defined $test_desc->{parameters}->{udp_bandwidth};
            $parameters->buffer_length($test_desc->{parameters}->{buffer_length}) if defined $test_desc->{parameters}->{buffer_length};
            $parameters->window_size($test_desc->{parameters}->{window_size} * 1024 * 1024) if defined $test_desc->{parameters}->{window_size}; # convert to bps for the regular testing
            $parameters->packet_tos_bits($test_desc->{parameters}->{tos_bits}) if defined $test_desc->{parameters}->{tos_bits};
            $parameters->streams($test_desc->{parameters}->{streams}) if defined $test_desc->{parameters}->{streams};
            $parameters->omit_interval($test_desc->{parameters}->{omit_interval}) if defined $test_desc->{parameters}->{omit_interval};
            $parameters->send_only($test_desc->{parameters}->{send_only}) if defined $test_desc->{parameters}->{send_only};
            $parameters->receive_only($test_desc->{parameters}->{receive_only}) if defined $test_desc->{parameters}->{receive_only};
        }
        elsif ($test_desc->{type} eq "pinger") {
            $parameters = perfSONAR_PS::RegularTesting::Tests::Bwping->new();
            $parameters->packet_count($test_desc->{parameters}->{packet_count}) if $test_desc->{parameters}->{packet_count};
            $parameters->packet_length($test_desc->{parameters}->{packet_size}) if $test_desc->{parameters}->{packet_size};
            $parameters->packet_ttl($test_desc->{parameters}->{ttl}) if $test_desc->{parameters}->{ttl};
            $parameters->inter_packet_time($test_desc->{parameters}->{packet_interval}) if $test_desc->{parameters}->{packet_interval};
            $parameters->send_only(1);
        }
        elsif ($test_desc->{type} eq "traceroute") {
            $parameters = perfSONAR_PS::RegularTesting::Tests::Bwtraceroute->new();
            $parameters->tool($test_desc->{parameters}->{tool}) if $test_desc->{parameters}->{tool};
            $parameters->packet_length($test_desc->{parameters}->{packet_size}) if defined $test_desc->{parameters}->{packet_size};
            $parameters->packet_first_ttl($test_desc->{parameters}->{first_ttl}) if defined $test_desc->{parameters}->{first_ttl};
            $parameters->packet_max_ttl($test_desc->{parameters}->{max_ttl}) if defined $test_desc->{parameters}->{max_ttl};
            $parameters->send_only(1);
        }
       
        $parameters->test_ipv4_ipv6(1);

        my @targets = ();
        foreach my $member (values %{ $test_desc->{members} }) {
            my $target = perfSONAR_PS::RegularTesting::Target->new();
            $target->address($member->{address});
            $target->description($member->{description}) if $member->{description};

            unless ($member->{test_ipv4}) {
                my $override_parameters = $parameters->meta->new_object();
                $override_parameters->force_ipv6(1);
                $target->override_parameters($override_parameters);
            }

            unless ($member->{test_ipv6}) {
                my $override_parameters = $parameters->meta->new_object();
                $override_parameters->force_ipv4(1);
                $target->override_parameters($override_parameters);
            }

            push @targets, $target;
        }

        my $test = perfSONAR_PS::RegularTesting::Test->new();
        $test->description($test_desc->{description}) if $test_desc->{description};
        $test->local_interface($test_desc->{parameters}->{local_interface}) if $test_desc->{parameters}->{local_interface};
        $test->disabled($test_desc->{disabled}) if $test_desc->{disabled};
        $test->schedule($schedule);
        $test->parameters($parameters);
        $test->targets(\@targets);

        $test->added_by_mesh(1) if $test_desc->{added_by_mesh};

        push @tests, $test;
    }

    # Copy the existing configuration
    my $new_config = perfSONAR_PS::RegularTesting::Config->parse($self->{EXISTING_CONFIGURATION});

    # Add the newly generated tests to the config
    push @{ $new_config->tests },  @tests;

    # Generate a Config::General version
    my ($status, $res) = save_string(config => $new_config->unparse());

    return ($status, $res) unless $status == 0;

    return (0, $res);
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR-PS Users' mailing list, please visit:

  https://lists.internet2.edu/sympa/info/perfsonar-ps-users

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

Copyright (c) 2008-2010, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
