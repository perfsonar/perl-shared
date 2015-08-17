package perfSONAR_PS::NPToolkit::DataService::BaseConfig;

use fields qw(LOGGER config_file admin_info_conf config authenticated);

use strict;
use warnings;

use Log::Log4perl qw(get_logger :easy :levels);
use Params::Validate qw(:all);
use Data::Dumper;

use Config::General;

use perfSONAR_PS::NPToolkit::Config::Version;
use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;
use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file start_service restart_service stop_service );


sub new {
    my ( $class, @params ) = @_;

    my $self = fields::new( $class );

    $self->{LOGGER} = get_logger( $class );
    my $parameters = validate(
        @params,
        {
            config_file => 1
        }
    );
    $self->{config_file} = $parameters->{config_file};
    my $config = Config::General->new( -ConfigFile => $self->{config_file} );
    $self->{config} = { $config->getall() };
    my $administrative_info_conf = perfSONAR_PS::NPToolkit::Config::AdministrativeInfo->new();
    $administrative_info_conf->init( { administrative_info_file => $self->{config}->{administrative_info_file} } );
    $self->{admin_info_conf} = $administrative_info_conf;

    return $self;
}


sub save_state {
    my $self = shift;
    my $administrative_info_conf = $self->{admin_info_conf};
    # TODO: Clean this up
    my $state = $administrative_info_conf->save_state();
    #$session->param( "administrative_info_conf", $state );
    #$session->param( "is_modified", $is_modified );
    #$session->param( "initial_state_time", $initial_state_time );
    return $self->save_config();
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

1;