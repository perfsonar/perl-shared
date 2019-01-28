package perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Config;

use Mouse;

use JSON::Validator;
#Ignore warning related to re-defining host verification method used by JSON::Validator
no warnings 'redefine';
use Data::Validate::Domain;
use Data::Validate::IP qw(is_ipv6);

use perfSONAR_PS::Client::PSConfig::Archive;
use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel;
use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress;
use perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass;
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig;
use perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or;
use perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag;
use perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel;
use perfSONAR_PS::Client::PSConfig::Host;
use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Client::PSConfig::Schedule;
use perfSONAR_PS::Client::PSConfig::Task;
use perfSONAR_PS::Client::PSConfig::Test;
use perfSONAR_PS::Client::PSConfig::Translators::MeshConfig::Schema qw(meshconfig_json_schema);
use URI;
use JSON;
use DateTime;

use constant META_DISPLAY_NAME => 'display-name';

extends 'perfSONAR_PS::Client::PSConfig::Translators::BaseTranslator';

has 'skip_validation' => (is => 'rw', isa => 'Bool', default => sub { 0 });
has 'use_force_bidirectional' => (is => 'rw', isa => 'Bool', default => sub { 0 });
has 'disable_bwctl' => (is => 'rw', isa => 'Bool', default => sub { 0 });

=item name()

Returns name of translator

=cut

sub name {
    return 'MeshConfig JSON';
}

=item can_translate()

Determines if given JSON object can be converted to MeshConfig format, if can prepare object
for translation

=cut


sub can_translate {
    my ($self, $raw_config, $json_obj) = @_;
    
    #need JSON
    return 0 unless($json_obj);

    #clear errors
    $self->_set_error('');

    #validate against schema
    my @errors = $self->validate($json_obj);
    if(@errors){
        my $err = "MeshConfig JSON is not valid. Encountered the following validation errors:\n\n";
        foreach my $error(@errors){
            $err .= "   Node: " . $error->path . "\n";
            $err .= "   Error: " . $error->message . "\n\n";
        }
        $self->_set_error($err);
        return 0;
    }
    
    #optimizations to prepare for translation
    $self->data($json_obj);
    $self->skip_validation(1);
    

    #looks good  
    return 1;
}

=item translate()

Translates MeshConfig file to pSConfig format

=cut

sub translate {
    my ($self, $raw_config, $json_obj) = @_;
    
    #clear errors
    $self->_set_error('');
    
    #First validate this config
    my @errors;
    unless($self->skip_validation()){
        @errors = $self->validate();
        if(@errors){
            my $err = "MeshConfig JSON is not valid. Encountered the following validation errors:\n\n";
            foreach my $error(@errors){
                $err .= "   Node: " . $error->path . "\n";
                $err .= "   Error: " . $error->message . "\n\n";
            }
            $self->_set_error($err);
            return;
        }
    }
    
    #init translation
    my $psconfig = new perfSONAR_PS::Client::PSConfig::Config();
    
    #set description
    my $now=DateTime->now;
    $now->set_time_zone("UTC");
    my $iso_now = $now->ymd('-') . 'T' . $now->hms(':') . '+00:00';
    my $top_meta = {
        "psconfig-translation" => {
            "source-format" => 'mesh-config-json',
            "time-translated" => $iso_now
        }
    };
    $self->_convert_description('', $self->data(), $top_meta);
    #set admins
    $self->_convert_administrators('', $self->data(), $top_meta);
    #set meta
    $psconfig->psconfig_meta($top_meta);
    
    #get global archives
    my $global_archive_refs = {};
    $self->_convert_measurement_archives($self->data(), $psconfig, $global_archive_refs);
    
    #get global hosts
    $self->_convert_hosts($self->data(), $psconfig, {}, {}, $global_archive_refs);
    
    #get host classes
    $self->_convert_host_classes($psconfig);
    
    #convert organizations to addresses and hosts and archives
    if($self->data()->{'organizations'}){
        foreach my $organization(@{$self->data()->{'organizations'}}){
            my $meta = {};
            my $org_tags = {}; #convert to list later
            my $org_archive_refs = {}; #note: we'll copy global_refs in tasks
            $self->_convert_description('organization', $organization, $meta);
            $self->_convert_administrators('organization', $organization, $meta);
            $self->_convert_measurement_archives($organization, $psconfig, $org_archive_refs);
            $self->_convert_tags($organization, $org_tags);
            $self->_convert_location('organization', $organization, $meta);
            $self->_convert_hosts($organization, $psconfig, $meta, $org_tags, $org_archive_refs);
            #convert sites
            if($organization->{'sites'}){
                foreach my $site(@{$organization->{'sites'}}){
                    my $site_tags = $self->_copy_hashref($org_tags); #convert to list later
                    my $site_archive_refs = $self->_copy_hashref($org_archive_refs);
                    $self->_convert_description('site', $site, $meta);
                    $self->_convert_administrators('site', $site, $meta);
                    $self->_convert_tags($site, $site_tags);
                    $self->_convert_location('site', $site, $meta);
                    $self->_convert_measurement_archives($site, $psconfig, $site_archive_refs);
                    $self->_convert_hosts($site, $psconfig, $meta, $site_tags, $site_archive_refs);
                }
            }
        }
    }
    
    #build groups, tests, schedules and tasks
    $self->_convert_tests($psconfig, $global_archive_refs);
    
    
    #build pSConfig Object and validate
    @errors = $psconfig->validate();
    if(@errors){
        my $err = "Generated PSConfig JSON is not valid. Encountered the following validation errors:\n\n";
        foreach my $error(@errors){
            $err .= "   Node: " . $error->path . "\n";
            $err .= "   Error: " . $error->message . "\n\n";
        }
        $self->_set_error($err);
        return;
    }
    
    return $psconfig;
}

=item validate()

Validates config against JSON schema. Return list of errors if finds any, return empty 
lost otherwise

=cut

sub validate {
    my ($self, $json_obj) = @_;
    my $validator = new JSON::Validator();
    ##NOTE: Below works around the strict TLD requirements of JSON::Validator
    local *Data::Validate::Domain::is_domain = \&Data::Validate::Domain::is_hostname;
    $validator->schema(meshconfig_json_schema());

    return $validator->validate($json_obj ? $json_obj : $self->data());
}

sub _convert_description {
    my ($self, $prefix, $obj, $meta) = @_;
    
    $prefix .= '-' if($prefix);
    if($obj->{'description'}){
        $meta->{$prefix . META_DISPLAY_NAME()} = $obj->{'description'};
    }
}

sub _convert_toolkit_url {
    my ($self, $obj, $meta) = @_;
    
    if($obj->{'toolkit_url'}){
        if(lc($obj->{'toolkit_url'}) eq 'auto' && 
                $obj->{'addresses'} &&
                ref($obj->{'addresses'}) eq 'ARRAY' &&
                @{$obj->{'addresses'}} > 0 
        ){
            my $url_address = $obj->{'addresses'}->[0];
            $url_address = '[' . $url_address . ']' if(is_ipv6($url_address));
            $meta->{'ps-toolkit-url'} = "https://$url_address/toolkit" if($url_address);
        }else{
            $meta->{'ps-toolkit-url'} = $obj->{'toolkit_url'};
        }
    }
}

sub _convert_location {
    my ($self, $prefix, $obj, $meta) = @_;
    
    $prefix .= '-' if($prefix);
    if($obj->{'location'}){
        foreach my $key(keys %{$obj->{'location'}}){
            if(defined $obj->{$key}){
                $meta->{$prefix . "location-$key"} = $obj->{$key};
            }
        }
    }
}


sub _convert_administrators {
    my ($self, $prefix, $obj, $meta) = @_;
    
    $prefix .= '-' if($prefix);
    if($obj->{'administrators'}){
        my $admins = [];
        foreach my $admin(@{$obj->{'administrators'}}){
            push @{$admins}, $admin;
        }
        if(@{$admins}){
            $meta->{$prefix . "administrators"} = $admins;
        }
    }
}

sub _convert_tags {
    my ($self, $obj, $tags) = @_;
    
    if($obj->{'tags'}){
        foreach my $tag(keys %{$obj->{'tags'}}){
            $tags->{$tag} = 1;
        }
    }
}

sub _convert_measurement_archives {
    my ($self, $obj, $psconfig, $archive_refs) = @_;
    
    return unless($obj->{'measurement_archives'});
    
    foreach my $ma(@{$obj->{'measurement_archives'}}){
        next unless($ma->{'read_url'});
        my $url_obj = new URI($ma->{'read_url'});
        my $archive_name = $url_obj->host;
        next unless($archive_name);
        $archive_refs->{$archive_name} = 1;
        next if($psconfig->archive($archive_name));
        my $archive = new perfSONAR_PS::Client::PSConfig::Archive();
        $archive->archiver('esmond');
        $archive->archiver_data_param('url', $ma->{'read_url'});
        $archive->archiver_data_param('measurement-agent', '{% scheduled_by_address %}');
        $psconfig->archive($archive_name, $archive);
    }
}

sub _convert_host_classes {
    my ($self, $psconfig) = @_;
    
    if($self->data()->{'host_classes'}){
        foreach my $host_class(@{$self->data()->{'host_classes'}}){
            #only allow one data source in new format
            next if(@{$host_class->{'data_sources'}} != 1);
            my $data_source = $host_class->{'data_sources'}->[0];
            my $class_name = $host_class->{'name'};
            next unless($class_name);
            my $psconfig_address_class = new perfSONAR_PS::Client::PSConfig::AddressClasses::AddressClass();
            #create data source
            if($data_source->{'type'} eq 'current_mesh'){
                $psconfig_address_class->data_source(new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::CurrentConfig());
            }elsif($data_source->{'type'} eq 'requesting_agent'){
                $psconfig_address_class->data_source(new perfSONAR_PS::Client::PSConfig::AddressClasses::DataSources::RequestingAgent());
            }else{
                #shouldn't be possible, but skip if is
                next;
            }
            
            #create match filter
            my $match_filter = $self->_build_addr_class_filter($host_class->{'match_filters'});
            $psconfig_address_class->match_filter($match_filter) if($match_filter);
            
            #create exclude filter
            my $exclude_filter = $self->_build_addr_class_filter($host_class->{'exclude_filters'});
            $psconfig_address_class->exclude_filter($exclude_filter) if($exclude_filter);
            
            #NO LONGER SUPPORTED: host_properties
            $psconfig->address_class($class_name, $psconfig_address_class);
        }
    }
}

sub _build_addr_class_filter {
    my ($self, $filters) = @_;
    
    return unless($filters && @{$filters});
    
    # The semantics of old host class filters are that it must match all the different
    # types of filters, but may match any filter of each type. i.e. AND between
    # different filter types, OR between different filters of the same type.
    my $parent_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And();
    my $filters_by_type = {};
    foreach my $filter(@{$filters}){
        my $child_filter = $self->_build_addr_class_child_filter($filter);
        next unless($child_filter);
        $filters_by_type->{$child_filter->type()} = [] unless($filters_by_type->{$child_filter->type()});
        push @{$filters_by_type->{$child_filter->type()}}, $child_filter;
    }
    
    #build ORs
    foreach my $filter_type(keys %{$filters_by_type}){
        my $or_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or();
        foreach my $f(@{$filters_by_type->{$filter_type}}){
            $or_filter->add_filter($f);
        }
        $parent_filter->add_filter($or_filter) if(@{$or_filter->filters()});
    }
        
    return @{$parent_filter->filters()} ? $parent_filter : undef;
}

sub _build_addr_class_child_filter {
    my ($self, $filter) = @_;
    
    my $child_filter;
    if($filter->{'type'} eq 'address_type'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::IPVersion();
        if($filter->{'address_type'} eq 'ipv4'){
            $child_filter->ip_version(4);
        }elsif($filter->{'address_type'} eq 'ipv6'){
            $child_filter->ip_version(6);
        }else{
            return;
        }
    }elsif($filter->{'type'} eq 'and'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::And();
        foreach my $f(@{$filter->{'filters'}}){
            my $nf = $self->_build_addr_class_child_filter($f);
            $child_filter->add_filter($nf) if($nf);
        }
    }elsif($filter->{'type'} eq 'host_class'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::AddressClass();
        $child_filter->class($filter->{'class'});
    }elsif($filter->{'type'} eq 'netmask'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Netmask();
        $child_filter->netmask($filter->{'netmask'});
    }elsif($filter->{'type'} eq 'not'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Not();
        #old format supports multiple, which means we need old semantics
        my $grandchild_filter = $self->_build_addr_class_filter($filter->{'filters'});
        $child_filter->filter($grandchild_filter) if($grandchild_filter);
    }elsif($filter->{'type'} eq 'or'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Or();
        foreach my $f(@{$filter->{'filters'}}){
            my $nf = $self->_build_addr_class_child_filter($f);
            $child_filter->add_filter($nf) if($nf);
        }
    }elsif($filter->{'type'} eq 'organization'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host();
        my $jq = new perfSONAR_PS::Client::PSConfig::JQTransform();
        $jq->script('._meta."organization-display-name"=="' . $filter->{'description'} . '"');
        $child_filter->jq($jq);
    }elsif($filter->{'type'} eq 'site'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Host();
        my $jq = new perfSONAR_PS::Client::PSConfig::JQTransform();
        $jq->script('._meta."site-display-name"=="' . $filter->{'description'} . '"');
        $child_filter->jq($jq);
    }elsif($filter->{'type'} eq 'tag'){
        $child_filter = new perfSONAR_PS::Client::PSConfig::AddressClasses::Filters::Tag();
        $child_filter->tag($filter->{'tag'});
    }
    
    return $child_filter;
}

sub _convert_hosts {
    my ($self, $obj, $psconfig, $meta, $tags, $archive_refs) = @_;
    
    return unless($obj->{'hosts'});
    
    foreach my $host(@{$obj->{'hosts'}}){
        #init properties
        my $host_meta = $self->_copy_hashref($meta); #convert to list later
        my $host_tags = $self->_copy_hashref($tags); #convert to list later
        my $host_archive_refs = $self->_copy_hashref($archive_refs); #convert to list later
        #convert meta field
        $self->_convert_description('', $host, $host_meta);
        $self->_convert_toolkit_url($host, $host_meta);
        $self->_convert_administrators('host', $host, $host_meta);
        $self->_convert_location('host', $host, $host_meta);
        #convert tags
        $self->_convert_tags($host, $host_tags);
        #convert archives
        $self->_convert_measurement_archives($host, $psconfig, $host_archive_refs);
        #bind addresses
        my $host_lead_bind_address = $host->{'lead_bind_address'};
        my $host_pscheduler_address = $host->{'pscheduler_address'};
        
        #convert addresses
        my $addr_display_name = $host_meta->{META_DISPLAY_NAME()};
        my $host_name;
        foreach my $address(@{$host->{'addresses'}}){
            my $psconfig_address = new perfSONAR_PS::Client::PSConfig::Addresses::Address();
            $psconfig_address->psconfig_meta_param(META_DISPLAY_NAME(), $addr_display_name) if($addr_display_name);
            #set host properties to be overridden if we end up with object
            $psconfig_address->lead_bind_address($host_lead_bind_address) if($host_lead_bind_address);
            $psconfig_address->pscheduler_address($host_pscheduler_address) if($host_pscheduler_address);
            #figure out the type of address we are dealing with
            if(ref($address) eq 'HASH'){
                next unless($address->{'address'});
                $psconfig_address->address($address->{'address'});
                $psconfig_address->lead_bind_address($address->{'lead_bind_address'}) if($address->{'lead_bind_address'});
                $psconfig_address->pscheduler_address($address->{'pscheduler_address'}) if($address->{'pscheduler_address'});
                $psconfig_address->tags($address->{'tags'}) if($address->{'tags'});
                #converts maps -> remote_addresses
                if($address->{'maps'}){
                    foreach my $map(@{$address->{'maps'}}){
                        my $remote = $self->_build_remote_address($psconfig_address, $map->{'remote_address'});
                        foreach my $field(@{$map->{'fields'}}){
                            my $label = new perfSONAR_PS::Client::PSConfig::Addresses::AddressLabel();
                            #not sure this is strictly required to be an address, but generally
                            # this is how people use it. may have to tweak if run into cases
                            # where people use it otherwise
                            $label->address($field->{'value'});
                            $remote->label($field->{'name'}, $label);
                        }
                    }
                }
                #converts pscheduler_address_maps -> remote_addresses
                if($address->{'pscheduler_address_maps'}){
                    foreach my $map(@{$address->{'pscheduler_address_maps'}}){
                        my $remote = $self->_build_remote_address($psconfig_address, $map->{'remote_address'});
                        $remote->pscheduler_address($map->{'service_address'});#always set top-level
                        # Add it to all labels
                        foreach my $label_name(@{$remote->label_names()}){
                            $remote->label($label_name)->pscheduler_address($map->{'service_address'});
                        }
                    }
                }
                #converts bind_maps -> remote_addresses
                if($address->{'bind_maps'}){
                    foreach my $map(@{$address->{'bind_maps'}}){
                        my $remote = $self->_build_remote_address($psconfig_address, $map->{'remote_address'});
                        $remote->lead_bind_address($map->{'lead_bind_address'}) if($map->{'lead_bind_address'});#always set top-level
                        # Add it to all labels
                        foreach my $label_name(@{$remote->label_names()}){
                            $remote->label($label_name)->lead_bind_address($map->{'lead_bind_address'}) if($map->{'lead_bind_address'});
                        }
                    }
                }
            }else{
                $psconfig_address->address($address);
            }
            #build host object if needed
            unless($host_name){
                $host_name = $host->{'description'};
                #fallback to first address we found if no description
                $host_name = $psconfig_address->address() unless($host_name);
                #replace spaces
                $host_name = $self->_format_name($host_name);
                my $psconfig_host = new perfSONAR_PS::Client::PSConfig::Host();
                #add tags
                my @tag_list = keys %{$host_tags};
                $psconfig_host->tags(\@tag_list) if(@tag_list);
                #add meta
                $psconfig_host->psconfig_meta($host_meta) if($host_meta);
                #add host_archive_refs
                my @archive_list = keys %{$host_archive_refs};
                $psconfig_host->archive_refs(\@archive_list) if(@archive_list);
                # no agent
                $psconfig_host->no_agent($host->{'no_agent'}) if(defined $host->{'no_agent'});
                # disabled
                $psconfig_host->disabled($host->{'disabled'}) if(defined $host->{'disabled'});
                #add to psconfig
                $psconfig->host($host_name, $psconfig_host);
            }
            $psconfig_address->host_ref($host_name);
            #add to psconfig
            $psconfig->address($psconfig_address->address(), $psconfig_address);
        }
    }
}

sub _build_remote_address {
    my ($self, $psconfig_address, $remote_address_str) = @_;
    
    my $remote = $psconfig_address->remote_address($remote_address_str);
    unless($remote){
        $remote = new perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress();
        $remote->address($psconfig_address->address());
        $psconfig_address->remote_address($remote_address_str, $remote);
    }
    
    return $remote;
}

sub _convert_tests {
    my ($self, $psconfig, $global_archive_refs) = @_;
    
    #build tests
    my $test_checksums = {};
    my $group_checksums = {};
    my $schedule_checksums = {};
    my $group_count = 0;
    my $test_counts = {};
    my $schedule_count = 0;
    my $task_count = 0;
    if($self->data()->{'tests'}){
        foreach my $test(@{$self->data()->{'tests'}}){
            my $meta = {};
            my $archive_refs = $self->_copy_hashref($global_archive_refs);
            my $psconfig_task = new perfSONAR_PS::Client::PSConfig::Task();
            $self->_convert_description('', $test, $meta);
            $self->_convert_administrators('', $test, $meta);
            $self->_convert_measurement_archives($test, $psconfig, $archive_refs);
            $psconfig_task->disabled($test->{'disabled'}) if(defined $test->{'disabled'});
            if($test->{'references'}){
                foreach my $reference(@{$test->{'references'}}){
                    if($reference->{'name'} && defined $reference->{'value'}){
                        $psconfig_task->reference_param($reference->{'name'}, $reference->{'value'});
                    }
                }
            }
            #members
            next unless($test->{'members'} && $test->{'members'}->{'type'});
            my $psconfig_group;
            if($test->{'members'}->{'type'} eq 'mesh'){
                $psconfig_group = new perfSONAR_PS::Client::PSConfig::Groups::Mesh();
                $psconfig_group->default_address_label($test->{'members'}->{'address_map_field'}) if($test->{'members'}->{'address_map_field'});
                foreach my $member(@{$test->{'members'}->{'members'}}){
                    $psconfig_group->add_address($self->_build_address_selector($member));
                }
            }elsif($test->{'members'}->{'type'} eq 'disjoint'){
                $psconfig_group = new perfSONAR_PS::Client::PSConfig::Groups::Disjoint();
                $psconfig_group->default_address_label($test->{'members'}->{'address_map_field'}) if($test->{'members'}->{'address_map_field'});
                foreach my $a_member(@{$test->{'members'}->{'a_members'}}){
                    $psconfig_group->add_a_address($self->_build_address_selector($a_member));
                }
                foreach my $b_member(@{$test->{'members'}->{'b_members'}}){
                    $psconfig_group->add_b_address($self->_build_address_selector($b_member));
                }
            }elsif($test->{'members'}->{'type'} eq 'star'){
                $psconfig_group = new perfSONAR_PS::Client::PSConfig::Groups::Disjoint();
                $psconfig_group->default_address_label($test->{'members'}->{'address_map_field'}) if($test->{'members'}->{'address_map_field'});
                if($test->{'members'}->{'center_address'}){
                    $psconfig_group->add_a_address($self->_build_address_selector($test->{'members'}->{'center_address'}));
                }
                foreach my $b_member(@{$test->{'members'}->{'members'}}){
                    $psconfig_group->add_b_address($self->_build_address_selector($b_member));
                }
            }else{
                #ignore ordered mesh or anything else
                next;
            }
            my $group_name = "group_${group_count}"; #no good name to use, so this will have to due
            if($group_checksums->{$psconfig_group->checksum()}){
                $group_name = $group_checksums->{$psconfig_group->checksum()};
            }else{
                $group_checksums->{$psconfig_group->checksum()} = $group_name;
                $group_count++;
                $psconfig->group($group_name, $psconfig_group);
            }
            $psconfig_task->group_ref($group_name);
            
            #parameters
            next unless($test->{'parameters'} && $test->{'parameters'}->{'type'});
            my $psconfig_test = new perfSONAR_PS::Client::PSConfig::Test();
            my $psconfig_schedule = new perfSONAR_PS::Client::PSConfig::Schedule();
            my $empty_schedule_checksum = $psconfig_schedule->checksum();
            if($test->{'parameters'}->{'type'} eq 'perfsonarbuoy/bwctl'){
                $self->convert_psb_bwctl($test->{'parameters'}, $psconfig_task, $psconfig_test, $psconfig_schedule);
            }elsif($test->{'parameters'}->{'type'} eq 'perfsonarbuoy/owamp'){
                $self->convert_psb_owamp($test->{'parameters'}, $psconfig_task, $psconfig_test, $psconfig_schedule);
            }elsif($test->{'parameters'}->{'type'} eq 'pinger'){
                $self->convert_pinger($test->{'parameters'}, $psconfig_task, $psconfig_test, $psconfig_schedule);
            }elsif($test->{'parameters'}->{'type'} eq 'simplestream'){
                $self->convert_simplestream($test->{'parameters'}, $psconfig_task, $psconfig_test, $psconfig_schedule);
            }elsif($test->{'parameters'}->{'type'} eq 'traceroute'){
                $self->convert_trace($test->{'parameters'}, $psconfig_task, $psconfig_test, $psconfig_schedule);
            }else{
                #ignore ordered mesh or anything else
                next;
            }
            
            #add test
            my $test_name;
            if($test_checksums->{$psconfig_test->checksum()}){
                $test_name = $test_checksums->{$psconfig_test->checksum()};
            }else{
                my $test_count = $test_counts->{$psconfig_test->type()} ? $test_counts->{$psconfig_test->type()} : 0;
                $test_name = $psconfig_test->type() . "_$test_count";
                $test_checksums->{$psconfig_test->checksum()} = $test_name;
                $psconfig->test($test_name, $psconfig_test);
                $test_counts->{$psconfig_test->type()} = $test_count + 1;
            }
            $psconfig_task->test_ref($test_name);
            
            #add schedule if not empty
            if($empty_schedule_checksum ne $psconfig_schedule->checksum()){
                my $schedule_name;
                if($schedule_checksums->{$psconfig_schedule->checksum()}){
                    $schedule_name = $schedule_checksums->{$psconfig_schedule->checksum()};
                }else{
                    $schedule_name = "schedule_${schedule_count}";
                    $schedule_checksums->{$psconfig_schedule->checksum()} = $schedule_name;
                    $psconfig->schedule($schedule_name, $psconfig_schedule);
                    $schedule_count++;
                }
                $psconfig_task->schedule_ref($schedule_name);
            }
            
            #set last few options
            #add meta
            $psconfig_task->psconfig_meta($meta) if($meta);
            #add host_archive_refs
            my @archive_list = keys %{$archive_refs};
            $psconfig_task->archive_refs(\@archive_list) if(@archive_list);
            
            #add task
            my $task_name = "task_${task_count}";
            if($test->{'description'}){
                $task_name = $self->_format_name($test->{'description'});
            }else{
                $task_count++;
            }
            $psconfig->task($task_name, $psconfig_task);
            
            #if force_bidirectional, set a second task
            if($self->use_force_bidirectional() && $test->{'parameters'}->{'force_bidirectional'}){
                #copy task
                my $bidir_task = new perfSONAR_PS::Client::PSConfig::Task(
                    'data' => from_json(to_json($psconfig_task->data()))
                );
                $bidir_task->scheduled_by(1);
                if($test->{'description'}){
                    $bidir_task->psconfig_meta_param(META_DISPLAY_NAME, $test->{'description'} . ' (Scheduled by Destination)');
                }
                $psconfig->task($task_name . '_scheduled_by_dest', $bidir_task);
            }
        }
    }
}

sub _build_address_selector {
    my ($self, $member) = @_;
    
    my $sel;
    if($member =~ /^host_class::/){
        $member =~ s/^host_class:://;
        $sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::Class();
        $sel->class($member);
    }else{
        $sel = new perfSONAR_PS::Client::PSConfig::AddressSelectors::NameLabel();
        $sel->name($member);
    }
    
    return $sel;
}


sub convert_psb_bwctl {
    my ($self, $test_params, $psconfig_task, $psconfig_test, $psconfig_schedule) = @_;
    
    #test type
    $psconfig_test->type("throughput");
    
    #tool
    if($test_params->{'tool'}){
        my @tools = split ",", $test_params->{'tool'};
        foreach my $tool(@tools){
            chomp $tool;
            $tool =~ s/^bwctl\///;
            unless($self->disable_bwctl()){
                if($tool eq 'iperf'){
                    $psconfig_task->add_tool('bwctliperf2');
                }elsif($tool eq 'iperf3'){
                    $psconfig_task->add_tool('bwctliperf3');
                }
            }
            $psconfig_task->add_tool($tool);
        }
    }
    
    #schedule params - not all of these are consistent so not moving to function
    $psconfig_schedule->repeat($self->_seconds_to_iso($test_params->{'interval'})) if($test_params->{'interval'});
    if($test_params->{'slip'}){
        $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'slip'}));
    }elsif($test_params->{'interval'}){
        if($test_params->{'interval'} > 43200){
            $psconfig_schedule->slip($self->_seconds_to_iso(43200));
        }else{
            $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'interval'}));
        }
    }
    $psconfig_schedule->sliprand(1) unless(defined $test_params->{'slip_randomize'} && !$test_params->{'slip_randomize'});
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    #test params (duration)
    $psconfig_test->spec_param('duration', $self->_seconds_to_iso($test_params->{'duration'})) if($test_params->{'duration'});
    $psconfig_test->spec_param('omit', $self->_seconds_to_iso($test_params->{'omit_interval'})) if($test_params->{'omit_interval'});
    $psconfig_test->spec_param('interval', $self->_seconds_to_iso($test_params->{'report_interval'})) if($test_params->{'report_interval'});
    #test params (int)
    $psconfig_test->spec_param('parallel', int($test_params->{'streams'})) if($test_params->{'streams'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'tos_bits'})) if($test_params->{'tos_bits'});
    $psconfig_test->spec_param('buffer-length', int($test_params->{'buffer_length'})) if($test_params->{'buffer_length'});
    $psconfig_test->spec_param('window-size', int($test_params->{'window_size'})) if($test_params->{'window_size'});
    $psconfig_test->spec_param('client-cpu-affinity', int($test_params->{'client_cpu_affinity'})) if(defined $test_params->{'client_cpu_affinity'});
    $psconfig_test->spec_param('server-cpu-affinity', int($test_params->{'server_cpu_affinity'})) if(defined $test_params->{'server_cpu_affinity'});
    $psconfig_test->spec_param('flow-label', int($test_params->{'flow_label'})) if($test_params->{'flow_label'});
    $psconfig_test->spec_param('mss', int($test_params->{'mss'})) if($test_params->{'mss'});
    $psconfig_test->spec_param('dscp', int($test_params->{'dscp'})) if(defined $test_params->{'dscp'});
    #test params (boolean)
    $psconfig_test->spec_param('no-delay', JSON::true) if($test_params->{'no_delay'});
    #test params (string)
    $psconfig_test->spec_param('congestion', $test_params->{'congestion'}) if($test_params->{'congestion'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($test_params->{'ipv4_only'});
    $psconfig_test->spec_param('ip-version', 6) if($test_params->{'ipv6_only'});
    #test params (protocol)
    if($test_params->{'protocol'} && $test_params->{'protocol'} eq 'udp'){
        $psconfig_test->spec_param('udp', JSON::true);
        $psconfig_test->spec_param('bandwidth', int($test_params->{'udp_bandwidth'})) if($test_params->{'udp_bandwidth'});
    }elsif($test_params->{'tcp_bandwidth'}){
        $psconfig_test->spec_param('bandwidth', int($test_params->{'tcp_bandwidth'}));
    }
}

sub convert_psb_owamp {
    my ($self, $test_params, $psconfig_task, $psconfig_test, $psconfig_schedule) = @_;
    
    #test type
    $psconfig_test->type("latencybg");
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    $psconfig_test->spec_param('flip', '{% flip %}');
    #test params (int)
    $psconfig_test->spec_param('packet-count', int($test_params->{'sample_count'})) if($test_params->{'sample_count'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'tos_bits'})) if($test_params->{'tos_bits'});
    $psconfig_test->spec_param('packet-padding', int($test_params->{'packet_padding'})) if(defined $test_params->{'packet_padding'});
    #test params (numeric)
    $psconfig_test->spec_param('packet-interval', $test_params->{'packet_interval'} * 1.0) if($test_params->{'packet_interval'});
    $psconfig_test->spec_param('bucket-width', $test_params->{'bucket_width'} * 1.0) if($test_params->{'bucket_width'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($test_params->{'ipv4_only'});
    $psconfig_test->spec_param('ip-version', 6) if($test_params->{'ipv6_only'});
    #test params (boolean)
    $psconfig_test->spec_param('output-raw', JSON::true) if($test_params->{'output_raw'});
}

sub convert_pinger {
    my ($self, $test_params, $psconfig_task, $psconfig_test, $psconfig_schedule) = @_;
    
    #test type
    $psconfig_test->type("rtt");
    
    #schedule params - not all of these are consistent so not moving to function
    $psconfig_schedule->repeat($self->_seconds_to_iso($test_params->{'test_interval'})) if($test_params->{'test_interval'});
    if($test_params->{'slip'}){
        $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'slip'}));
    }elsif($test_params->{'test_interval'}){
        if($test_params->{'test_interval'} > 43200){
            $psconfig_schedule->slip($self->_seconds_to_iso(43200));
        }else{
            $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'test_interval'}));
        }
    }
    $psconfig_schedule->sliprand(1) unless(defined $test_params->{'slip_randomize'} && !$test_params->{'slip_randomize'});
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    #test params (int)
    $psconfig_test->spec_param('count', int($test_params->{'packet_count'})) if($test_params->{'packet_count'});
    $psconfig_test->spec_param('length', int($test_params->{'packet_size'})) if($test_params->{'packet_size'});
    $psconfig_test->spec_param('ttl', int($test_params->{'packet_ttl'})) if($test_params->{'packet_ttl'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'tos_bits'})) if($test_params->{'tos_bits'});
    $psconfig_test->spec_param('flowlabel', int($test_params->{'flowlabel'})) if(defined $test_params->{'flowlabel'});
    $psconfig_test->spec_param('deadline', int($test_params->{'deadline'})) if(defined $test_params->{'flowlabel'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($test_params->{'ipv4_only'});
    $psconfig_test->spec_param('ip-version', 6) if($test_params->{'ipv6_only'});
    #test params (boolean)
    $psconfig_test->spec_param('hostnames', JSON::true) if($test_params->{'hostnames'});
    $psconfig_test->spec_param('suppress-loopback', JSON::true) if($test_params->{'suppress_loopback'});
    #test params (duration)
    $psconfig_test->spec_param('interval', $self->_seconds_to_iso($test_params->{'packet_interval'})) if($test_params->{'packet_interval'});
    $psconfig_test->spec_param('deadline', $self->_seconds_to_iso($test_params->{'deadline'})) if($test_params->{'deadline'});
    $psconfig_test->spec_param('timeout', $self->_seconds_to_iso($test_params->{'timeout'})) if($test_params->{'timeout'});
}

sub convert_simplestream {
    my ($self, $test_params, $psconfig_task, $psconfig_test, $psconfig_schedule) = @_;
    
    #test type
    $psconfig_test->type("simplestream");
    
    #tool
    if($test_params->{'tool'}){
        my @tools = split ",", $test_params->{'tool'};
        foreach my $tool(@tools){
            chomp $tool;
            $psconfig_task->add_tool($tool);
        }
    }
    
    #schedule params - not all of these are consistent so not moving to function
    $psconfig_schedule->repeat($self->_seconds_to_iso($test_params->{'interval'})) if($test_params->{'interval'});
    if($test_params->{'slip'}){
        $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'slip'}));
    }elsif($test_params->{'interval'}){
        if($test_params->{'interval'} > 43200){
            $psconfig_schedule->slip($self->_seconds_to_iso(43200));
        }else{
            $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'interval'}));
        }
    }
    $psconfig_schedule->sliprand(1) unless(defined $test_params->{'slip_randomize'} && !$test_params->{'slip_randomize'});
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    $psconfig_test->spec_param('dest-node', '{% pscheduler_address[1] %}');
    #test params (duration)
    $psconfig_test->spec_param('dawdle', $self->_seconds_to_iso($test_params->{'dawdle'})) if($test_params->{'dawdle'});
    $psconfig_test->spec_param('timeout', $self->_seconds_to_iso($test_params->{'timeout'})) if($test_params->{'timeout'});
    #test params (numeric)
    $psconfig_test->spec_param('fail', $test_params->{'fail'} * 1.0) if(defined $test_params->{'fail'});
    #test params (string)
    $psconfig_test->spec_param('test-material', $test_params->{'test_material'}) if($test_params->{'test_material'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($test_params->{'ipv4_only'});
    $psconfig_test->spec_param('ip-version', 6) if($test_params->{'ipv6_only'});
}

sub convert_trace {
    my ($self, $test_params, $psconfig_task, $psconfig_test, $psconfig_schedule) = @_;
    
    #test type
    $psconfig_test->type("trace");
    
    #tool
    if($test_params->{'tool'}){
        my @tools = split ",", $test_params->{'tool'};
        foreach my $tool(@tools){
            chomp $tool;
            $tool =~ s/^bwctl\///;
            unless($self->disable_bwctl()){
                if($tool eq 'traceroute'){
                    $psconfig_task->add_tool('bwctltraceroute');
                }elsif($tool eq 'tracepath'){
                    $psconfig_task->add_tool('bwctltracepath');
                }
            }
            $psconfig_task->add_tool($tool);
        }
    }
    
    #schedule params - not all of these are consistent so not moving to function
    $psconfig_schedule->repeat($self->_seconds_to_iso($test_params->{'test_interval'})) if($test_params->{'test_interval'});
    if($test_params->{'slip'}){
        $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'slip'}));
    }elsif($test_params->{'test_interval'}){
        if($test_params->{'test_interval'} > 43200){
            $psconfig_schedule->slip($self->_seconds_to_iso(43200));
        }else{
            $psconfig_schedule->slip($self->_seconds_to_iso($test_params->{'test_interval'}));
        }
    }
    $psconfig_schedule->sliprand(1) unless(defined $test_params->{'slip_randomize'} && !$test_params->{'slip_randomize'});
    
    #test params (template)
    $psconfig_test->spec_param('source', '{% address[0] %}');
    $psconfig_test->spec_param('dest', '{% address[1] %}');
    $psconfig_test->spec_param('source-node', '{% pscheduler_address[0] %}');
    
    #test params (int)
    $psconfig_test->spec_param('length', int($test_params->{'packet_size'})) if($test_params->{'packet_size'});
    $psconfig_test->spec_param('first-ttl', int($test_params->{'first_ttl'})) if($test_params->{'first_ttl'});
    $psconfig_test->spec_param('hops', int($test_params->{'max_ttl'})) if($test_params->{'max_ttl'});
    $psconfig_test->spec_param('queries', int($test_params->{'queries'})) if($test_params->{'queries'});
    $psconfig_test->spec_param('ip-tos', int($test_params->{'tos_bits'})) if($test_params->{'tos_bits'});
    #test params (boolean)
    $psconfig_test->spec_param('as', JSON::true) if($test_params->{'as'});
    $psconfig_test->spec_param('fragment', JSON::true) if($test_params->{'fragment'});
    $psconfig_test->spec_param('hostnames', JSON::true) if($test_params->{'hostnames'});
    #test params (duration)
    ## deprecated version of wait
    $psconfig_test->spec_param('wait', $self->_seconds_to_iso($test_params->{'timeout'})) if($test_params->{'timeout'});
    ## deprecated version of sendwait
    $psconfig_test->spec_param('sendwait', $self->_seconds_to_iso($test_params->{'waittime'})) if($test_params->{'waittime'});
    $psconfig_test->spec_param('wait', $self->_seconds_to_iso($test_params->{'wait'})) if($test_params->{'wait'});
    $psconfig_test->spec_param('sendwait', $self->_seconds_to_iso($test_params->{'sendwait'})) if($test_params->{'sendwait'});
    #test param (ip version)
    $psconfig_test->spec_param('ip-version', 4) if($test_params->{'ipv4_only'});
    $psconfig_test->spec_param('ip-version', 6) if($test_params->{'ipv6_only'});
    #test params (string)
    ## deprecated probe-type
    $psconfig_test->spec_param('probe-type', $test_params->{'protocol'}) if($test_params->{'protocol'});
    $psconfig_test->spec_param('algorithm', $test_params->{'algorithm'}) if($test_params->{'algorithm'});
    $psconfig_test->spec_param('probe-type', $test_params->{'probe_type'}) if($test_params->{'probe_type'});
}

sub _copy_hashref {
    my ($self, $obj) = @_;
    
    my $new_obj = {};
    foreach my $k(keys %{$obj}){
        $new_obj->{$k} = $obj->{$k};
    }
    
    return $new_obj;
}

sub _seconds_to_iso {
    my ($self, $secs) = @_;
    
    $secs = int($secs);
    return "PT${secs}S";
}

sub _format_name {
    my ($self, $val) = @_;
    
    #replace spaces
    $val =~ s/\s/_/g;
    #replace invalid character
    $val =~ s/[^a-zA-Z0-9:._\\-]//g;
    
    return $val;
}


__PACKAGE__->meta->make_immutable;

1;
