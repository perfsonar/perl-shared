package perfSONAR_PS::NPToolkit::DataService::NTP;
use fields qw( LOGGER config config_file ntp ntp_conf failed_connect error_message );
use strict;
use warnings;

use Log::Log4perl qw(get_logger :easy :levels);
use POSIX;
use Data::Dumper;
use Params::Validate qw(:all);
use Net::IP;
use JSON qw(from_json);

use Data::Validate::IP qw(is_ipv4);

#use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file start_service restart_service stop_service );
use perfSONAR_PS::Utils::DNS qw( reverse_dns resolve_address );
use perfSONAR_PS::NPToolkit::Config::NTP;
use perfSONAR_PS::NPToolkit::Services::ServicesMap qw(get_service_object);
use perfSONAR_PS::Utils::Host qw(get_ntp_info);
use perfSONAR_PS::Utils::NTP qw( ping );


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
    my $ntp = get_service_object("ntp");
    $self->{ntp} = $ntp;
    my $ntp_conf = perfSONAR_PS::NPToolkit::Config::NTP->new();
    $ntp_conf->init( { ntp_conf => $config->{ntp_conf} } );
    $self->{ntp_conf} = $ntp_conf;
    $self->{failed_connect} = {};

    return $self;
}

sub get_ntp_information {

    my $self = shift;
    my $response = get_ntp_info();
    return $response;

}

sub get_ntp_configuration {
    my $self = shift;
    my $caller = shift;
    my $ntp_conf = $self->{'ntp_conf'};

    my %config = ();

    my $selected_servers = $ntp_conf->get_selected_servers( { as_hash => 1 } );
    my $known_servers = $ntp_conf->get_servers();

    $config{'selected_servers'} = $selected_servers;
    $config{'known_servers'} = $known_servers;


    return \%config;
}

sub update_ntp_configuration {
    my $self = shift;
    my $caller = shift;
    my $ntp_conf = $self->{'ntp_conf'};
    #my %config = ();
    my $input_data = $caller->{'input_params'}->{'POSTDATA'};
    my $json_text = $input_data->{'value'};

    my $data = from_json($json_text);

    my %result;

    if($data){
        my $enabled_servers =  $data->{'data'}->{'enabled_servers'};
        my %enable_result;
        my $available_servers = $ntp_conf->get_servers();

        if($enabled_servers){
            foreach my $enabled_server (keys %{$enabled_servers}){
                my $success;
                if($available_servers->{$enabled_server}){
                    $success = $ntp_conf->update_server(
                        {
                            address => $enabled_server,
                            description => $enabled_servers->{$enabled_server},
                            selected => 1
                        }
                    );
                }else{

                    $success = $ntp_conf->add_server(
                        {
                            address     => $enabled_server,
                            description => $enabled_servers->{$enabled_server},
                            selected    => 1,
                        }
                    );
                }

                $enable_result{$enabled_server} = $success;
            }
        }


        my $disabled_servers = $data->{'data'}->{'disabled_servers'};
        my %disable_result;
        if($disabled_servers){
            foreach my $disabled_server (keys %{$disabled_servers}){
                my $success = $ntp_conf->update_server(
                    {
                        address => $disabled_server,
                        description => $disabled_servers->{$disabled_server},
                        selected => 0 
                    }

                    );
                $disable_result{$disabled_server} = $success;
            }
        }

        my $deleted_servers =  $data->{'data'}->{'deleted_servers'};
        my %deleted_result;
        if($deleted_servers){
            foreach my $del_server (@{$deleted_servers}){
                my $success = $ntp_conf->delete_server( { address => $del_server } );
                $deleted_result{$del_server} =$success ;
            }
        }

        $result{'enabled_servers'} = \%enable_result;
        $result{'disabled_servers'} = \%disable_result;
        $result{'deleted_servers'} = \%deleted_result;

        $result{'save_config'} = $self->save_config();
    }

    if ( defined $result{'save_config'} ) {
        return \%result;
    } else {
        $caller->{'error_message'} = $self->{'error_message'} if defined $self->{'error_message'};
        return;
    }

}

sub get_selected_servers {
    my $self = shift;
    my $ntp_conf = $self->{ntp_conf};
    my $ntp_servers = $ntp_conf->get_selected_servers( { as_hash => 1 });
    my $vars_servers = $self->_format_servers($ntp_servers);
    return $vars_servers
}

sub get_known_servers {
    my $self = shift;
    my $ntp_conf = $self->{ntp_conf};

    my $ntp_servers = $ntp_conf->get_servers();
    my $vars_servers = $self->_format_servers($ntp_servers);
    return $vars_servers;
}

sub _format_servers {
    my ($self, $ntp_servers) = @_;
    my @vars_servers = ();
    my $failed_connect = $self->{failed_connect};
    foreach my $key ( sort { $ntp_servers->{$a}->{description} cmp $ntp_servers->{$b}->{description} } keys %{$ntp_servers} ) {
        my $ntp_server = $ntp_servers->{$key};

        my $display_address = $ntp_server->{address};
        if ( is_ipv4( $display_address ) or &Net::IP::ip_is_ipv6( $display_address ) ) {
            my $new_addr = reverse_dns( $display_address );
	    $display_address = $new_addr if ($new_addr);
        }

        my %server_info = (
            address         => $ntp_server->{address},
            display_address => $display_address,
            description     => $ntp_server->{description},
            selected        => $ntp_server->{selected},
	        #failed_connect  => $failed_connect->{$ntp_server->{address}},
        );

        push @vars_servers, \%server_info;
    }
    return \@vars_servers;


}

sub select_closest {
    my $self = shift;
    my $caller = shift;
    my $count = $caller->{'input_params'}->{'count'}->{'value'} || 5;

    my @servers = ();
    my $failed_connect = {};
    my ($error_msg, $status_msg);

    my $ntp_conf = $self->{'ntp_conf'};
    my $ntp_servers = $ntp_conf->get_servers();

    foreach my $key ( keys %{$ntp_servers} ) {
        my $ntp_server = $ntp_servers->{$key};

        push @servers, $ntp_server->{address};
    }

    my ( $status, $res1, $res2 ) = $self->find_closest_servers( { servers => \@servers, maximum_number => $count } );
    if ( $status != 0 ) {
        $error_msg = "Error finding closest servers";
        return { error => $error_msg };
    }

    foreach my $key ( keys %{$ntp_servers} ) {
        my $ntp_server = $ntp_servers->{$key};

        $ntp_conf->update_server( { address => $ntp_server->{address}, selected => 0 } );
    }

    foreach my $address ( @$res1 ) {
        $ntp_conf->update_server( { address => $address->{address}, selected => 1 } );
    }

    my %new_failed_connect = ();
    foreach my $address ( @$res2 ) {
        $new_failed_connect{$address} = 1;
    }
    $failed_connect = \%new_failed_connect;

    $status_msg = "Selected Closest";
    return { selected => $res1,
             message  => 'Selected closest servers',
             failed_connect => $res2,   
    };
}

sub find_closest_servers {
    my ($self, @params) = @_;
    my $parameters = validate(
        @params,
        {
            servers        => 1,
            maximum_number => 0,
        }
    );
    my $servers = $parameters->{servers};
    my $maximum_number = $parameters->{maximum_number};

    my ( $status, $results ) = ping({ hostnames => $servers, timeout => 60 });
    my @failed_hosts = ();
    my @succeeded_hosts = ();

    foreach my $host (keys %$results) {
        if ($results->{$host}->{rtt}) {
            push @succeeded_hosts, { address => $host, rtt => $results->{$host}->{rtt} };
        }
        else {
            push @failed_hosts, $host;
        }
    }

    @succeeded_hosts = sort { $a->{rtt} <=> $b->{rtt} } @succeeded_hosts;

    # make sure we only grab the maximum number

    if ( $parameters->{maximum_number} && scalar(@succeeded_hosts) > $parameters->{maximum_number}) {
        splice @succeeded_hosts, $maximum_number;
    }

    return ( 0, \@succeeded_hosts, \@failed_hosts );
}

sub add_server {
    my $self = shift;
    my $caller = shift;
    my $params = $caller->{'input_params'};

    my $address = $params->{'address'}->{'value'};
    my $description = $params->{'description'}->{'value'};
    my $ntp_conf = $self->{ntp_conf};

    if ( $ntp_conf->lookup_server( { address => $address } ) ) {
    	my $error_msg = "Server $address already exists";
        return { "error" => $error_msg };
    }

    $ntp_conf->add_server(
        {
            address     => $address,
            description => $description,
            selected    => 1,
        }
    );

    $self->{LOGGER}->info( "Server $address added" );

    my $status_msg = "Server $address added";

    return $self->save_config();
}

sub delete_server {
    my $self = shift;
    my $caller = shift;
    my $address = $caller->{'input_params'}->{'address'}->{'value'};
    my $logger = $self->{LOGGER};

    $logger->info( "Deleting Server: $address" );

    $self->{'ntp_conf'}->delete_server( { address => $address } );

    my $status_msg = "Server $address deleted";
    return $self->save_config();
}

sub enable_server {
    my $self = shift;
    my $caller = shift;
    my $address = $caller->{'input_params'}->{'address'}->{'value'};
    my $state = 'enabled';

    return $self->_set_server_state($address, $state);
}

sub disable_server {
    my $self = shift;
    my $caller = shift;
    my $address = $caller->{'input_params'}->{'address'}->{'value'};
    my $state = 'disabled';

    return $self->_set_server_state($address, $state);
}

sub _set_server_state {
    my ($self, $address, $state) = @_;

    my $ntp_conf = $self->{'ntp_conf'};
    my $logger = $self->{'LOGGER'};

    return unless ( $ntp_conf->lookup_server( { address => $address } ) );

    my $status_msg;

    if ( $state and $state eq "enabled" ) {
        $status_msg = "Server $address selected";
        $logger->info( "Enabling server $address" );
        $ntp_conf->update_server( { address => $address, selected => 1 } );
    } else {
        $logger->info( "Disabling server $address" );
        $status_msg = "Server $address unselected";
        $ntp_conf->update_server( { address => $address, selected => 0 } );
    }

    return $self->save_config();
}

sub save_config {
    my $self = shift;

    my ($status, $res) = $self->{'ntp_conf'}->save( { restart_services => 1 } );
    if ($status != 0) {
        $self->{'error_message'} =  "Problem saving configuration: $res";
        return;
    } else {
        return { message => "Configuration Saved And Services Restarted" };
    }

}


1;

# vim: expandtab shiftwidth=4 tabstop=4
