package perfSONAR_PS::NPToolkit::DataService::Communities;

use strict;
use warnings;

use perfSONAR_PS::Client::gLS::Keywords;
use Log::Log4perl qw(get_logger :easy :levels);
use Params::Validate qw(:all);

use perfSONAR_PS::Utils::DNS qw( reverse_dns resolve_address reverse_dns_multi resolve_address_multi );
use SimpleLookupService::Client::SimpleLS;
use perfSONAR_PS::Client::LS::PSRecords::PSService;
use perfSONAR_PS::Client::LS::PSRecords::PSInterface;
use SimpleLookupService::Client::Bootstrap;
use SimpleLookupService::Client::QueryMultiple;
use SimpleLookupService::QueryObjects::Network::HostQueryObject;
use perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject;
use perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject;
use Time::HiRes;

use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;
use Data::Dumper;
use JSON;

use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;

use base 'perfSONAR_PS::NPToolkit::DataService::BaseConfig';

sub get_host_communities {

    my $self = shift;

    my $communities = $self->{admin_info_conf}->get_keywords();

    return {communities => $communities};

}

sub add_host_communities {
    my $self = shift;
    my $caller = shift;
    my $args = $caller->{'input_params'};
    my $community = $args->{'community'};
    print %{$community};
    my $result;
    if($community && $community->{'is_set'}){
         my $community_value = $args->{'community'}->{'value'};
         print $community_value;
         my @values = split(',',$community_value);
         foreach my $value (@values){
            $result = $self->{admin_info_conf}->add_keyword({keyword=>$value});
         }
    }

    my $save_result = $self->save_config();
    return $save_result;

}

sub remove_host_communities {
    my $self = shift;
    my $caller = shift;
    my $args = $caller->{'input_params'};
    my $community = $args->{'community'};
    print %{$community};
    my $result;
    if($community && $community->{'is_set'}){
         my $community_value = $args->{'community'}->{'value'};
         print $community_value;
         my @values = split(',',$community_value);
         foreach my $value (@values){
            $result = $self->{admin_info_conf}->delete_keyword({keyword=>$value});
         }
    }

    my $save_result = $self->save_config();
    return $save_result;

}

sub get_hosts_in_community {
    my $self = shift;
    my $caller = shift;
    my $args = $caller->{'input_params'};
    my $community = $args->{'community'}->{'value'};

    my $test_type = $args->{'test_type'}->{'value'};

    warn "community: "  . $community;
    warn "test_type: "  . $test_type;

    my $hostname = "ps-west.es.net";
    my $port = 80;

    my $server = SimpleLookupService::Client::SimpleLS->new();
    $server->init( { host => $hostname, port => $port } );
    $server->connect();


    #my $query_host_object = perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject->new();
    #$query_host_object->init();
    #$query_host_object->addField({'key'=>'group-communities', 'value'=>$community} );
    # this filter doesn't work.
    #if ( $test_type ) {
    #   $query_host_object->setServiceType( $test_type );
    #}

    # The information we need is split between the Service and Host types. 
    # Host won't let us filter by service type, so we'll try to extract all
    # the host information from the service-locator

    my $ls_start = Time::HiRes::time();

    my $query_service_object = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
    $query_service_object->init();
    $query_service_object->addField({'key'=>'group-communities', 'value'=>$community} );
    if ( $test_type ) {
       $query_service_object->setServiceType( $test_type );
    }

    my $query = new SimpleLookupService::Client::QueryMultiple;
    $query->init( { bootstrap_server => $server } );
    $query->addQuery( $query_service_object );
    #$query->addQuery( $query_host_object );
    my ($resCode, $res) = $query->query();
    warn "resCode: " . $resCode;
    my $ls_end = Time::HiRes::time();
    my $ls_time = $ls_end - $ls_start;
    my $dns_cache = {}; # TODO: use an object-wide cache

    my $ret = [];

    warn "res: " . Dumper $res;

    my @all_addresses = ();

    # Extract all the addresses
    foreach my $data_row ( @$res ) {
        my $locators =  $data_row->getServiceLocators();

        foreach my $full_addr ( @$locators ) {
            my $addr;

            if ( $full_addr =~ /^(tcp|https?):\/\/\[([^\]]*)\]/ ) {
                $addr = $2;
            }
            elsif ( $full_addr =~ /^(tcp|https?):\/\/([^\/:]*)/ ) {
                $addr = $2;
            }
            else {
                $addr = $full_addr;
            }

            push @all_addresses, $addr;
        }

        #$self->lookup_addresses(\@addresses, $dns_cache);



        #push @$ret, $row;


    }

    # Look up all the addresses, in one batch
    my $dns_start = Time::HiRes::time();
    $self->lookup_addresses(\@all_addresses, $dns_cache);
    my $dns_end = Time::HiRes::time();
    my $dns_time = $dns_end - $dns_start;
    warn "DNS CACHE: " . Dumper $dns_cache;

    my $host_details_time = 0;

    # Build the result
    foreach my $data_row ( @$res ) {
        my $site_name = $data_row->getSiteName();
        my $locators =  $data_row->getServiceLocators();
        my $row = {};
        $row->{'hosts'} = [];
        $row->{'site_name'} = $site_name;
        $row->{'service_locators'} =  $locators;
        #$row->{'addresses'} = \@addresses;

        #$row->{'service_name'} =  $data_row->getServiceName();
        #$row->{'host_name'} =  $data_row->getHostName();
        #$row->{'communities'} = $data_row->getCommunities();
        #$row->{'interfaces'} =  $data_row->getInterfaces();

        my @addrs = ();
        my @dns_names = ();
        foreach my $contact ( @$locators ) {
            my ( $addr, $port );

            # if ( $full_addr =~ /^(tcp|https?):\/\/\[([^\]]*)\]/ ) {
            #     $addr = $2;
            # }
            # elsif ( $full_addr =~ /^(tcp|https?):\/\/([^\/:]*)/ ) {
            #     $addr = $2;
            # }
            # else {
            #     $addr = $full_addr;
            # }
            # The addresses here are tcp://ip:port or tcp://[ip]:[port] or similar
            if ( $contact =~ /^(tcp|https?):\/\/\[(.*)\]:(\d+)/ ) {
                $addr = $2;
                $port = $3;
            }
            elsif ( $contact =~ /^(tcp|https?):\/\/\[([^\]]*)\]/ ) {
                $addr = $2;
            }
            elsif ( $contact =~ /^(tcp|https?):\/\/(.*):(\d+)/ ) {
                $addr = $2;
                $port = $3;
            }
            elsif ( $contact =~ /^(tcp|https?):\/\/([^\/]*)/ ) {
                $addr = $2;
            }
            else {
                $addr = $contact;
            }

            my $cached_dns_info = $dns_cache->{$addr};
            my ($dns_name, $ip);

            $self->{LOGGER}->info("Address: ".$addr);

            my $description = $data_row->getServiceName()->[0];
            my $details_start = Time::HiRes::time();
            my $host = get_host_details( $addr, $port, $description );
            my $details_end = Time::HiRes::time();
            my $details_delta = $details_end - $details_start;
            warn "details delta: " . $details_delta;
            $host_details_time += $details_delta;
            warn "host: " . Dumper $host;

            if (is_ipv4($addr) or &Net::IP::ip_is_ipv6( $addr ) ) {
                if ( $cached_dns_info ) {
                    foreach my $dns_name (@$cached_dns_info) {
                        #push @dns_names, $dns_name;
                    }
                    $dns_name = $cached_dns_info->[0];
                    push @dns_names, $dns_name;
                }

                $ip = $addr;
            } else {
                push @dns_names, $addr;
                $dns_name = $addr;
                if ( $cached_dns_info ) {
                    $ip = join ', ', @{ $cached_dns_info };
                    $host->{'ip'} = $ip;
                }
            }
            $host->{'dns_names'} = \@dns_names;
            push @{ $row->{'hosts'} }, $host;
        }
        #$row->{'dns_names'} = \@dns_names;
        push @$ret, $row;

    }

    warn "host details time: $host_details_time";
    $dns_time = $dns_end - $dns_start;
    warn "dns time: $dns_time";
    warn "ls time: $ls_time";

    return $ret;


}

sub get_host_details {
    my ( $address, $port, $description ) = @_;

    my %hostname;

    my @addresses = split(',', $address);
    foreach my $addr (@addresses) {
        $addr = $1 if ($addr =~ /^\[(.*)\]$/);

        my ($host, $ipv4, $ipv6);

        # Discover the hostname, and figure out if ipv4 or ipv6 testing should
        # be done.
        if ( is_ipv4( $addr ) ) {
            $host = reverse_dns( $addr );
            $ipv4 = 1;
            $ipv6 = 0;
        }
        elsif ( &Net::IP::ip_is_ipv6( $addr ) ) {
            $host = reverse_dns( $addr );
            $ipv4 = 0;
            $ipv6 = 1;
        }
        elsif ( is_hostname( $addr ) ) {
            $host = $addr;
            $ipv4 = 0;
            $ipv6 = 0;
            my @host_addrs = resolve_address($addr);
            foreach my $host_addr (@host_addrs) {
                if ( &Net::IP::ip_is_ipv6( $host_addr ) ) {
                    $ipv6 = 1;
                }
                elsif ( is_ipv4( $host_addr ) ) {
                    $ipv4 = 1;
                }
            }
        }
        else {
            my $error_msg = "Can't parse the specified address: '$addr'";
            warn $error_msg;
        }

        # Set the description
        my $new_description = $description;
        $new_description = $host unless $new_description;
        $new_description = $addr unless $new_description;


        warn( "Adding address: $addr Port: $port Description: $description" );

        my %host = ();
        $host{'address'} = $addr;
        $host{'port'} = $port;
        $host{'description'} = $description;
        $host{'test_ipv4'} = $ipv4;
        $host{'test_ipv6'} = $ipv6;
        return \%host;

        #  my ( $status, $res ) = $testing_conf->add_test_member({
        #              test_id     => $test_id,
        #              address     => $addr,
        #              port        => $port,
        #              description => $description,
        #              sender      => 1,
        #              receiver    => 1,
        #              test_ipv4   => $ipv4,
        #              test_ipv6   => $ipv6,
        #  });

        #  if ( $status != 0 ) {
        #      $error_msg = "Failed to add member to test: $res";
        #      return display_body();
        #  }
    }

    my $status_msg = "Host(s) Added To Test";
}

sub lookup_addresses {
    my $self = shift;
    my $addresses = shift;
    my $dns_cache = shift;

    my %addresses_to_lookup = ();
    my %hostnames_to_lookup = ();

    foreach my $addr (@$addresses) {
            $addr = $1 if ($addr =~ /^\[(.*)\]$/);

            next if ($dns_cache->{$addr});

            if (is_ipv4($addr) or &Net::IP::ip_is_ipv6( $addr ) ) {
                $self->{'LOGGER'}->debug("$addr is an IP");
                $addresses_to_lookup{$addr} = 1;
            } elsif (is_hostname($addr)) {
                $hostnames_to_lookup{$addr} = 1;
                $self->{'LOGGER'}->debug("$addr is a hostname");
            } else {
                $self->{'LOGGER'}->debug("$addr is unknown");
            }
    }

    my @addresses_to_lookup = keys %addresses_to_lookup;
    my @hostnames_to_lookup = keys %hostnames_to_lookup;

    my $resolved_hostnames = resolve_address_multi({ addresses => \@hostnames_to_lookup, timeout => 2 });
    foreach my $hostname (keys %{ $resolved_hostnames }) {
        $dns_cache->{$hostname} = $resolved_hostnames->{$hostname};
    }

    my $resolved_addresses = reverse_dns_multi({ addresses => \@addresses_to_lookup, timeout => 2 });

    foreach my $ip (keys %{ $resolved_addresses }) {
        $dns_cache->{$ip} = $resolved_addresses->{$ip};
    }

    return;
}

sub get_all_communities {
    my $self = shift;
    my $caller = shift;

    my $keyword_client = perfSONAR_PS::Client::gLS::Keywords->new( { cache_directory => $self->{config}->{cache_directory} } );
    my ($status, $res) = $keyword_client->get_keywords();
    $self->{LOGGER}->debug("keyword status: $status");
    if ( $status == 0) {
        $self->{LOGGER}->debug("Got keywords: ".Dumper($res));
    } else {
        my $error_msg = "Error retrieving global keywords";
        $self->{LOGGER}->debug('Got no keywords: ' . Dumper $res );
        #return { "error" => $error_msg };
        $caller->{error_message} = $error_msg;
        return;
    }
    return $res;

}

sub update_host_communities {
    my $self = shift;
    my $caller = shift;

    #my %config = ();
    my $input_data = $caller->{'input_params'}->{'POSTDATA'};

    my $json_text = $input_data->{'value'};

    my $data = from_json($json_text);

    my %result=();

     if($data){
         my $community_list =  $data->{'communities'};
         my %community_result;
        if($community_list){
             my $success = $self->{admin_info_conf}->delete_all_keywords(); 
             #if delete is successful then update, else return error without saving to config file.
             if($success==0){
                 foreach my $community (@{$community_list}){
                     my $success = $self->{admin_info_conf}->add_keyword({keyword=>$community});
                     $community_result{$community} =$success ;
                 }
             }else{
                 $result{'delete_all_keywords'} = -1;
                 return \%result;
             }

         }

         $result{'community'} = \%community_result;



         $result{'save_config'} = $self->save_config();
    }


    return \%result;

}


1;

# vim: expandtab shiftwidth=4 tabstop=4
