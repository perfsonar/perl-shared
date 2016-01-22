package perfSONAR_PS::NPToolkit::DataService::Communities;

use strict;
use warnings;

use perfSONAR_PS::Client::gLS::Keywords;
use Log::Log4perl qw(get_logger :easy :levels);
use Params::Validate qw(:all);

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

sub get_all_communities {
    my $self = shift;

    my $keyword_client = perfSONAR_PS::Client::gLS::Keywords->new( { cache_directory => $self->{config}->{cache_directory} } );
    my ($status, $res) = $keyword_client->get_keywords();
    $self->{LOGGER}->debug("keyword status: $status");
    if ($status == 0) {
        $self->{LOGGER}->debug("Got keywords: ".Dumper($res));
        return $res;
    }

    return {};
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
