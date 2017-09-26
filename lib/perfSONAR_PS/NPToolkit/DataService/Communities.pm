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

use LWP::UserAgent;
use Data::Validate::IP qw(is_ipv4);
use Data::Validate::Domain qw(is_hostname);
use Net::IP;
use Data::Dumper;
use JSON;

use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;

use base 'perfSONAR_PS::NPToolkit::DataService::BaseConfig';

sub get_host_communities {

    my $self = shift;

    my $ls_conf = $self->{ls_conf};
    my $config = $ls_conf->load_config( { file => $ls_conf->{'CONFIG_FILE'} } );
    my $communities = $config->{site_project};

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

    my $cache = $args->{'cache'}->{'value'};

    my $ret = $self->lookup_servers( $test_type, $community, $cache );

    if ( defined $self->{'error_message'} ) {
        $caller->{'error_message'} = $self->{'error_message'};
        return;
    }

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

# Looks up servers from the local LS cache
sub lookup_servers {
    my ( $self, $test_type, $keyword, $cache ) = @_;

    my $error_msg;
    my $dns_cache = {};

    my ($status, $res) = $self->lookup_servers_cache($test_type, $keyword, $cache);


    if ($status != 0) {
        $self->{'error_message'} = $res;
        return;
    }

    my @addresses = ();

    foreach my $service (@{ $res->{hosts} }) {
        foreach my $full_addr (@{ $service->{addresses} }) {
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


            push @addresses, $addr;
        }
    }


    $self->lookup_addresses(\@addresses, $dns_cache);

    my @hosts = ();

    my @hosts_simple = ();

    foreach my $service (@{ $res->{hosts} }) {
        my @addrs = ();
        my @dns_names = ();
        my $ipv4 = 0;
        my $ipv6 = 0;
        my $host_address;
        my $host_ip;
        my $host_dns_name;
        my %host_row = ();
        my $port;
        my $pscheduler_url;

        foreach my $contact (@{ $service->{addresses} }) {

            my $addr;
            if ( $test_type eq "pinger" ) {
                $addr = $contact;
                if ( $contact =~ /^(https?):\/\/\[([^\]]*)\](:(\d+))?\/pscheduler/ ) {
                    $addr = $2;
                    my $proto = $1;                    
                    $port = $4;
                    if ( ! $port ) {
                        $port = ( $proto eq "http" ? 80 : 443 );

                    }
                    $pscheduler_url = $contact;
                }
                elsif ( $contact =~ /^(https?):\/\/([^\/:]*)(:(\d+))?\/pscheduler/ ) {
                    $addr = $2;
                    my $proto = $1;                    
                    $port = $4;
                    if ( ! $port ) {
                        $port = ( $proto eq "http" ? 80 : 443 );

                    }
                    $pscheduler_url = $contact;
                } 

            }
            else {
                # The addresses here are 
                # http(s)://ip:port/pscheduler
                # or tcp://ip:port or tcp://[ip]:[port] 
                # or similar
                #
                
                if ( $contact =~ /^(https?):\/\/\[([^\]]*)\](:(\d+))?\/pscheduler/ ) {
                    $addr = $2;
                    my $proto = $1;                    
                    $port = $4;
                    if ( ! $port ) {
                        $port = ( $proto eq "http" ? 80 : 443 );

                    }
                    $pscheduler_url = $contact;
                }
                elsif ( $contact =~ /^(https?):\/\/([^\/:]*)(:(\d+))?\/pscheduler/ ) {
                    $addr = $2;
                    my $proto = $1;
                    $port = $4;
                    if ( ! $port ) {
                        $port = ( $proto eq "http" ? 80 : 443 );

                    }
                    $pscheduler_url = $contact;
                } 
                elsif ( $contact =~ /^tcp:\/\/\[(.*)\]:(\d+)$/ ) {
                    $addr = $1;
                    $port = $2;
                }
                elsif ( $contact =~ /^tcp:\/\/\[(.*)\]$/ ) {
                    $addr = $1;
                }
                elsif ( $contact =~ /^tcp:\/\/(.*):(\d+)$/ ) {
                    $addr = $1;
                    $port = $2;
                }
                elsif ( $contact =~ /^tcp:\/\/(.*)$/ ) {
                    $addr = $1;
                }
                else {
                    $addr = $contact;
                }
            }

            my $cached_dns_info = $dns_cache->{$addr};
            my ($dns_name, $ip);

            $self->{'LOGGER'}->info("Address: ".$addr);

            if (is_ipv4($addr) or &Net::IP::ip_is_ipv6( $addr ) ) {
                if ( $cached_dns_info ) {
                    foreach my $dns_name (@$cached_dns_info) {
                        push @dns_names, $dns_name;
                    }
                    $dns_name = $cached_dns_info->[0];
                }

                $ip = $addr;
            } else {
                push @dns_names, $addr;
                $dns_name = $addr;
                if ( $cached_dns_info ) {
                    $ip = join ', ', @{ $cached_dns_info };
                }
            }

            # XXX improve this

            next if $addr =~ m/^10\./;
            next if $addr =~ m/^192\.168\./;
            next if $addr =~ m/^172\.16/;

            if ( defined $ip ) {
                my @ips = split(', ', $ip);
                if ( @ips ) {
                    foreach my $ipaddr (@ips) {
                        if (is_ipv4($ipaddr) ) {
                            $ipv4 = 1;
                        } elsif ( &Net::IP::ip_is_ipv6( $ipaddr ) ) {
                            $ipv6 = 1;
                        }

                    }
                } 

            } else {  # No ips found
                $ipv4 = 0;
                $ipv6 = 0;
            }

            $host_ip = $ip;
            $host_dns_name = $dns_name;
            if ( $dns_name ) {
                $host_address = $dns_name;
            } else {
                $host_address = $ip;
            }

            push @addrs, { address => $addr, dns_name => $dns_name, ip => $ip, port => $port };
        }
        # This happens if the above loop doesn't finish, i.e. it was a
        # private ip address
        next if !$host_address; 

        my %service_info = ();
        $service_info{"name"} = $service->{name};
        $service_info{"description"} = $service->{description};
        $service_info{"dns_names"}   = \@dns_names;
        $service_info{"addresses"}   = \@addrs;

        $host_row{"name"} = $service->{name};
        $host_row{"description"} = $service->{description};
        $host_row{"ipv4"} = $ipv4;
        $host_row{"ipv6"} = $ipv6;
        $host_row{"address"} = $host_address;
        $host_row{"ip"} = $host_ip;
        $host_row{"dns_name"} = $host_dns_name;
        $host_row{"port"} = $port;
        $host_row{"pscheduler_url"} = $pscheduler_url if $pscheduler_url;

        push @hosts_simple, \%host_row;

        # This "service_info" more complex format was used by the old toolkit
        # probably not needed but leaving it here in case we do need it
        push @hosts, \%service_info;
    }

    my %lookup_info = ();
    #$lookup_info{hosts}   = \@hosts_simple;
    $lookup_info{keyword} = $keyword;
    $lookup_info{check_time} = $res->{check_time};

    #$lookup_info->{$test_id} = \%lookup_info;

    my $ret = {};
    $ret->{'hosts'} = \@hosts_simple;
    #$ret->{'hosts_old'} = \@hosts;
    $ret->{'lookup_info'} = \%lookup_info;
    return $ret;

}

sub lookup_servers_cache {
    my ( $self, $service_type, $keyword, $cache ) = @_;

    my $ua = LWP::UserAgent->new;
    
    

    # NEXT STEPS:
    # 1. query ls cache ($cache) for services based on the test type and community
    # 2. Make a list of host UUIDs while doing #1 (hash keyed on UUID)
    # 3. Query, the ls cache for hosts, using the hash of the UUIDs, and extract host info from there]
    # {
    #     'addresses' => [, 
    #             'tcp://[2001:4118:900:cc00:215:17ff:fece:cd]:4823'
    #       ],
    #       name' => 'Institute of Experimental Physics, Slovak Academy of Sciences BWCTL Server',
    #       description' => 'Institute of Experimental Physics, Slovak Academy of Sciences, Kosice, SK'
    # }
    #

    my $error_msg;

    my $query = {};


    my @hosts = ();

    # bwctl/owamp type lookup
    my $service_types = {
        "bwctl/throughput" => "bwctl",
        "rtt" => "ping"
    };

    my $old_service_type = $service_types->{ $service_type } || $service_type;

    # pscheduler type lookup
    my $ps_types = {
        "bwctl/throughput" => "throughput",
        "bwctl" => "throughput",
        "owamp" => "latency",
        "pinger" => "rtt",
        "traceroute" => "trace"

    };
    
    my $ps_service_type = $ps_types->{ $service_type } || $service_type;



    $query->{'query'} = {
        "constant_score" => {
            filter => {
                bool => {
                    must => [
                        { match => { "type" => "service" } },
                        { term => { "group-communities.keyword" => $keyword } },
                        { bool => {
                                should => [
                                    { term => { "service-type.keyword" => $old_service_type } },
                                    { term => { "pscheduler-tests.keyword" => "$ps_service_type" } }


                                ]

                            }
                        }
                        
                    ]

                }

            }


        }


    };

    my $pattern = "^https?://[^/]+/perfsonar/?";
    my $re = qr/$pattern/;
    my $url = $cache;
    if ( $url =~ $re ) {
        my $req = HTTP::Request->new(
            POST => $url
        );

        my $json = encode_json($query);

        if ( defined $json ) {
            $req->content( $json );

        }

        # perform http $method request on the URL
        my $res = $ua->request($req);

        # success
        if ( $res->is_success ) {
            #print $cgi->header('application/json');
            my $message = $res->decoded_content;
            my $data = decode_json( $message );
            $data = $self->extract_addresses_from_json( $data );
            @hosts = @$data;
            #print $message;
        } else {
            # if there is an error, return the error message and code
            #error($res->message, $res->code);
        }
    } else {
        # url does not appear to be a valid esmond archive
        my $description = "Error: not a valid ps cache URL";
        #error( $description );
    }

    return (0, { hosts => \@hosts });
}

sub extract_addresses_from_json {
    my ( $self, $data ) = @_;

    my $out = [];

    my $hits = $data->{'hits'}->{'hits'};

    foreach my $source ( @$hits ) {
        my $row = $source->{'_source'};
        my $addresses = $row->{'service-locator'};
        my $name = $row->{'service-name'};
        my $description = $row->{'location-sitename'};
        my $service_type = $row->{'service-type'};

        my $outrow = {
            addresses => $addresses,
            name => $name,
            description => $description,
            service_type => $service_type
        };

        push @$out, $outrow;



    }

    return $out;

}


sub lookup_addresses {
    my ( $self, $addresses, $dns_cache ) = @_;

    my %addresses_to_lookup = ();
    my %hostnames_to_lookup = ();

    foreach my $addr (@{ $addresses }) {
            next if not defined $addr;
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
