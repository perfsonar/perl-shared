package perfSONAR_PS::NPToolkit::DataService::BaseConfig;

use fields qw(LOGGER config_file admin_info_conf config authenticated regular_testing_conf load_regular_testing load_ls_registration ls_conf test_config_defaults_file error_code error_message);

use strict;
use warnings;

use Log::Log4perl qw(get_logger :easy :levels);
use Params::Validate qw(:all);
use Data::Dumper;

use Config::General;

use perfSONAR_PS::NPToolkit::Config::Version;
use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;
use perfSONAR_PS::NPToolkit::Config::LSRegistrationDaemon;
use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file start_service restart_service stop_service );


sub new {
    my ( $class, @params ) = @_;

    my $self = fields::new( $class );

    $self->{LOGGER} = get_logger( $class );
    # PARAMETERS
    # config_file is required
    # regular_testing_config_file is optional, even if load_regular_testing is specified
    # load_regular_testing is optional
        # if 1, load regular testing config
        # if 0 or not specified, do not load the regular testing config
    my $parameters = validate(
        @params,
        {
            config_file => 1,
            regular_testing_config_file => 0, 
            ls_config_file => 0, 
            test_config_defaults_file => 0, 
            load_regular_testing => 0, 
            load_ls_registration => 0,
        }
    );

    $self->{config_file} = $parameters->{config_file};
    my $config = Config::General->new( -ConfigFile => $self->{config_file} );
    $self->{config} = { $config->getall() };

    my $load_regular_testing = $parameters->{load_regular_testing} || 0;
    $self->{load_regular_testing} = $load_regular_testing;
    my $regular_testing_config_file = $parameters->{regular_testing_config_file};
    $config->{regular_testing_config_file} = $regular_testing_config_file;

    my $test_config_defaults_file = $parameters->{test_config_defaults_file};
    $config->{test_config_defaults_file} = $test_config_defaults_file;

    if ( $load_regular_testing ) {
        my $testing_conf = perfSONAR_PS::NPToolkit::Config::RegularTesting->new();
        my ( $status, $res ) = $testing_conf->init( { regular_testing_config_file => $regular_testing_config_file, test_config_defaults_file => $test_config_defaults_file } );
        if ( $status != 0 ) {
            return { error => "Problem reading testing configuration: $res" };
        }
        $self->{regular_testing_conf} = $testing_conf;
    }

    my $ls_config_file = $parameters->{ls_config_file};
    my $load_ls_registration = 0;
    $load_ls_registration = 1 if ( defined $parameters->{load_ls_registration} && $parameters->{load_ls_registration} == 1);
    if ($load_ls_registration) {
        my $ls_conf = perfSONAR_PS::NPToolkit::Config::LSRegistrationDaemon->new();
        my ( $status, $res ) = $ls_conf->init( { config_file => $ls_config_file  } );

        if ( $status != 0 ) {
            return { error => "Problem reading LS registration daemon configuration: $res" };
        }
        $self->{ls_conf} = $ls_conf;

    }

    return $self;
}

sub save_config {
    my $self = shift;
    my $administrative_info_conf = $self->{admin_info_conf};
    # TODO: Clean this up and see if the service restart is necessary
    my ($status, $res) = $administrative_info_conf->save( { restart_services => 0 } );
    my $error_msg;
    my $status_msg;
    if ($status != 0) {
        $error_msg = "Problem saving configuration: $res";
        return { 
            error_msg => $error_msg,
            success => 0,
        };
    } else {
        #$status_msg = "Configuration Saved And Services Restarted";
        $status_msg = "Configuration saved";
        #$is_modified = 0;
        #$initial_state_time = $administrative_info_conf->last_modified();
        return { 
            status_msg => $status_msg,
            success => 1,
        };
    }
    #save_state();

}

sub save_ls_config {
    my $self = shift;
    my $ls_conf = $self->{ls_conf};
    my $error_msg;
    my $status_msg;
    my ($status, $res) = $ls_conf->save( { restart_services => 1 } );

    if ($status != 0) {
        $error_msg = "Problem saving LS configuration: $res";
        return {
            error_msg => $error_msg,
            success => 0,
        };
    } else {
        #$status_msg = "Configuration Saved And Services Restarted";
        $status_msg = "LS Configuration saved";
        #$is_modified = 0;
        #$initial_state_time = $administrative_info_conf->last_modified();
        return {
            status_msg => $status_msg,
            success => 1,
        };
    }
}

1;
