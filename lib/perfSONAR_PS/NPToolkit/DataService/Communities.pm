package perfSONAR_PS::NPToolkit::DataService::Communities;

use strict;
use warnings;

use perfSONAR_PS::Client::gLS::Keywords;
use Log::Log4perl qw(get_logger :easy :levels);
use Params::Validate qw(:all);

use SimpleLookupService::Client::SimpleLS;
use perfSONAR_PS::Client::LS::PSRecords::PSService;
use perfSONAR_PS::Client::LS::PSRecords::PSInterface;
use SimpleLookupService::Client::Bootstrap;
use SimpleLookupService::Client::Query;
use SimpleLookupService::QueryObjects::Network::HostQueryObject;
use perfSONAR_PS::Client::LS::PSQueryObjects::PSHostQueryObject;
use perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject;

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

    my $save_result = $self->save_state();
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

    my $save_result = $self->save_state();
    return $save_result;

}

sub get_hosts_in_community {
    my $self = shift;
    my $caller = shift;
    my $args = $caller->{'input_params'};
    my $community = $args->{'community'};

    my $test_type = $args->{'test_type'}->{'value'};

    warn "test_type: "  . $test_type;

    my $hostname = "ps-east.es.net"; # TODO: replace this so it queries all the ls servers
    my $port = 8090;
    my $server = SimpleLookupService::Client::SimpleLS->new();
    $server->init( { host => $hostname, port => $port } );
    $server->connect();

    my $query_object = perfSONAR_PS::Client::LS::PSQueryObjects::PSServiceQueryObject->new();
    $query_object->init();
    $query_object->addField({'key'=>'group-communities', 'value'=>'perfSONAR-PS'} );
    if ( $test_type ) {
       $query_object->setServiceType( $test_type );
    }
    my $query = new SimpleLookupService::Client::Query;
    $query->init( { server => $server } );
    my ($resCode, $res) = $query->query( $query_object );
    warn "resCode: " . $resCode;

    #$res = shift @$res;

    my $ret = [];

    foreach my $data_row ( @$res ) {
        my $locators = $data_row->getServiceLocators();
        my $site_name = $data_row->getSiteName();
        my $service_name = $data_row->getServiceName();
        my $row = {};
        $row->{'site_name'} = $site_name;
        $row->{'locators'} = $locators;
        $row->{'service_name'} = $service_name;
        $row->{'service_host'} = $data_row->getServiceHost();
        $row->{'dns_domains'} = $data_row->getDNSDomains();

        push @$ret, $row;


    }

    warn "res: " . Dumper $res;

    return $ret;


}

sub get_all_communities {
    my $self = shift;

    my $keyword_client = perfSONAR_PS::Client::gLS::Keywords->new( { cache_directory => $self->{config}->{cache_directory} } );
    my ($status, $res) = $keyword_client->get_keywords();
    $self->{LOGGER}->debug("keyword status: $status");
    if ( $status == 0) {
        $self->{LOGGER}->debug("Got keywords: ".Dumper($res));
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
