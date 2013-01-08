package perfSONAR_PS::Utils::MARegistrationManager;

use strict;
use warnings;

our $VERSION = 3.3;

use fields 'LS_CLIENT', 'LS_KEY_DB', 'LOGGER';

use Digest::MD5 qw(md5_base64);
use Log::Log4perl qw(get_logger);
use Params::Validate qw( :all );
use URI;

use perfSONAR_PS::Client::LS::PSQueryObjects::PSInterfaceQueryObject;
use perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject;
use perfSONAR_PS::Client::LS::PSRecords::PSInterface;
use perfSONAR_PS::Client::LS::PSRecords::PSTest;
use perfSONAR_PS::Client::LS::PSRecords::PSService;
use SimpleLookupService::Client::Query;
use SimpleLookupService::Client::Registration;
use SimpleLookupService::Client::RecordManager;
use SimpleLookupService::Client::SimpleLS;

sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init {
    my ($self, @args) = @_;
    my %parameters = validate( @args, { ls_url => 1, ls_key_db => 1 } );
     
    $self->{LOGGER} = get_logger( "perfSONAR_PS::Utils::MARegistrationManager" );
    
    #initialize key database
    $self->{LS_KEY_DB} = $parameters{'ls_key_db'};
    my $ls_key_dbh = DBI->connect('dbi:SQLite:dbname=' .  $self->{LS_KEY_DB}, '', '');
    my $ls_key_create  = $ls_key_dbh->prepare('CREATE TABLE IF NOT EXISTS lsKeys (uri VARCHAR(255) PRIMARY KEY, expires BIGINT NOT NULL, checksum VARCHAR(255) NOT NULL, duplicateChecksum VARCHAR(255) NOT NULL)');
    $ls_key_create->execute();
    if($ls_key_create->err){
        $self->{LOGGER}->error( "Error creating key database: " . $ls_key_create->errstr );
        exit( -1 );
    }
    $ls_key_dbh->disconnect();
    
    #setup ls client
    ## read these options for backward compatibility. at moment just support one LS.
    my @ls_array = ();
    my @array = split( /\s+/, $parameters{"ls_url"} );
    foreach my $l ( @array ) {
        $l =~ s/(\s|\n)*//g;
        push @ls_array, $l if $l;
    }
    @array = split( /\s+/, $parameters{"ls_url"} );
    foreach my $l ( @array ) {
        $l =~ s/(\s|\n)*//g;
        push @ls_array, $l if $l;
    }
    ##create client
    $self->{LS_CLIENT} = SimpleLookupService::Client::SimpleLS->new();
    my $uri = URI->new($ls_array[0]); 
    my $ls_port =$uri->port();
    if(!$ls_port &&  $uri->scheme() eq 'https'){
        $ls_port = 443;
    }elsif(!$ls_port){
        $ls_port = 80;
    }
    $self->{LS_CLIENT}->init( host=> $uri->host(), port=> $ls_port );    
}

sub register {
    my ($self, @args) = @_;
    my %parameters = validate( @args, { service_params => 1, interfaces => 1, test_set => 1} );
    
    #initialize values
    my $service_params = $parameters{service_params};
    my %test_set = %{$parameters{test_set}};
    
    #clean expired 
    $self->_clean_expired();
    
    #load URIs into database
    my ($uri_db, $service_reg_info) = $self->_load_uri_db();
    
    #find/register interface URIs for endpoints
    my %iface_uris = ();
    foreach my $host_interface(@{$parameters{interfaces}}){
        my $iface_query = perfSONAR_PS::Client::LS::PSQueryObjects::PSInterfaceQueryObject->new();
        $iface_query->init();
        $iface_query->setInterfaceAddresses($host_interface);
        
        $self->{LOGGER}->debug("iface_query is " .  $iface_query->toURLParameters());
        my $query_client = SimpleLookupService::Client::Query->new();
        $query_client->init(server => $self->{LS_CLIENT}, query => $iface_query);
        my($result_code, $results) = $query_client->query();
        if($result_code != 0){
            $self->{LOGGER}->warn("Error trying to lookup address $host_interface in LS: " . $results->{message});
            next;
        }elsif(@{$results} == 0){
            $self->{LOGGER}->debug("Unable to find $host_interface, registering");
            my $iface = new perfSONAR_PS::Client::LS::PSRecords::PSInterface();
            $iface->init(
                interfaceName => "MA:" . $host_interface, 
                interfaceAddresses => [$host_interface], 
            );
            my $reg_result =  $self->_register($iface);
            if($reg_result){
                $self->_save_reg_key($reg_result->getRecordUri(), 
                    $reg_result->getRecordExpiresAsUnixTS()->[0], $host_interface, $host_interface);
                $iface_uris{$host_interface} = $reg_result->getRecordUri();
            }
        }else {
            $self->{LOGGER}->debug("Found $host_interface");
            my $last_uri = '';
            foreach my $result(@{$results}){
                if(!$uri_db->{$result->getRecordUri()}){
                    #use first URI that is not registered by this MA. We prefer MAs 
                    # don't register hosts so this should occur when ls_reg_daemon is running
                    $iface_uris{$host_interface} = $result->getRecordUri();
               #     $self->{LOGGER}->info("Found record someone else maintains for $host_interface");
                    last;
                }
                $last_uri = $result->getRecordUri();
            }    
            
            #if our only option is a record maintained by this MA, then renew
            if(!$iface_uris{$host_interface}){
                $iface_uris{$host_interface} = $last_uri;
                $self->{LOGGER}->debug("Using record maintained by this MA for $host_interface");
                my $renew_result = $self->_renew($iface_uris{$host_interface});
                $self->_update_reg_key($renew_result->getRecordExpiresAsUnixTS()->[0], $renew_result->getRecordUri()) if($renew_result);
            }
        }
    }
    
    #find/register test-set URIs for endpoints
    my @test_set_uris = ();
    foreach my $src(keys %test_set){
        next if(!$iface_uris{$src});
        foreach my $dst(keys %{$test_set{$src}}){
            next if(!$iface_uris{$dst});
            foreach my $event_types(@{$test_set{$src}{$dst}}){
                #query test set
                my $testset_query = perfSONAR_PS::Client::LS::PSQueryObjects::PSTestQueryObject->new();
                $testset_query->init();
                $testset_query->setSource($iface_uris{$src});
                $testset_query->setDestination($iface_uris{$dst});
                $testset_query->setEventTypes($event_types);
                $self->{LOGGER}->debug("testset_query is " .  $testset_query->toURLParameters());
                my $query_client = SimpleLookupService::Client::Query->new();
                $query_client->init(server => $self->{LS_CLIENT}, query => $testset_query);
                my($result_code, $results) = $query_client->query();
                
                if($result_code != 0){
                    $self->{LOGGER}->warn("Error trying to lookup testset ${src}->${dst} in LS: " . $results->{message});
                    next;
                }elsif(@{$results} == 0){
                    $self->{LOGGER}->debug("Unable to find ${src}->${dst}, registering");
                    my $record = perfSONAR_PS::Client::LS::PSRecords::PSTest->new();
                    $record->init( eventType => $event_types, source => $iface_uris{$src}, 
                                    destination => $iface_uris{$dst}, testname => "$src to $dst");
                    my $reg_result =  $self->_register($record);
                    if($reg_result){
                        $self->_save_reg_key($reg_result->getRecordUri(), 
                            $reg_result->getRecordExpiresAsUnixTS()->[0], "$src->$dst", "$src->$dst");
                        push @test_set_uris, $reg_result->getRecordUri();
                    }
                }else{
                    $self->{LOGGER}->debug("Found test set ${src}->${dst}");
                    my $last_uri = '';
                    my $found = 0;
                    foreach my $result(@{$results}){
                        if(!$uri_db->{$result->getRecordUri()}){
                            #use first URI that is not registered by this MA.
                            push @test_set_uris, $result->getRecordUri();
                            $found = 1;
                            $self->{LOGGER}->debug("Found record someone else maintains for $src -> $dst");
                            last;
                        }
                        $last_uri = $result->getRecordUri();
                    }    
                    
                    #if our only option is a record maintained by this MA, then renew
                    if(!$found){
                        push @test_set_uris, $last_uri;
                        $self->{LOGGER}->debug("Using record maintained by this MA for $src -> $dst");
                        my $renew_result = $self->_renew($last_uri);
                        $self->_update_reg_key($renew_result->getRecordExpiresAsUnixTS()->[0], $renew_result->getRecordUri()) if($renew_result);
                    }                    
                }
            }
        }
    }
    $service_params->{'maTests'} = \@test_set_uris;
    
    #register pSB service
    my $service_checksum = '';
    foreach my $service_param('serviceLocator', 'serviceType', 'serviceName', 
        'eventTypes', 'maTypes', 'maTests', 'communities', 'domains', 'city', 'region', 
        'country',  'zip_code', 'latitude', 'longitude'){
        $service_checksum .= $self->_add_checksum_val($service_params->{$service_param});
    }
    $service_checksum = md5_base64($service_checksum);
    if($service_reg_info->{uri} && $service_reg_info->{checksum} eq $service_checksum){
        #if exists and checksum match, then renew
        $self->{LOGGER}->debug("Renewing MA service");
        my $renew_result = $self->_renew($service_reg_info->{uri});
        $self->_update_reg_key($renew_result->getRecordExpiresAsUnixTS()->[0], $renew_result->getRecordUri()) if($renew_result);
    }elsif($service_reg_info->{uri}){
        #if exists but diff checksums then unregister and re-register
        $self->{LOGGER}->debug("Removing and re-registering MA service");
        # unregister
        $self->_unregister($service_reg_info->{uri});
        $self->_delete_reg_key($service_reg_info->{uri});
        #register
        my $reg_result = $self->_register($self->_build_service_registration($service_params));
        $self->_save_reg_key($reg_result->getRecordUri(), 
                    $reg_result->getRecordExpiresAsUnixTS()->[0], $service_checksum, 'service') if($reg_result);
    }else{
        # doesn't exist so register
        $self->{LOGGER}->debug("Registering MA service");
        my $reg_result = $self->_register($self->_build_service_registration($service_params));
        $self->_save_reg_key($reg_result->getRecordUri(), 
                    $reg_result->getRecordExpiresAsUnixTS()->[0], $service_checksum, 'service') if($reg_result);
    }
}

sub _add_checksum_val {
    my ($self, $val) = @_;
    
    my $result = '';
    
    if(!defined $val){
        return $result;
    }
    
    if(ref($val) eq 'ARRAY'){
        $result = join ',', sort @{$val};
    }else{
        $result = $val;
    }
    
    return $result;
}

sub _register {
    my ( $self, $record ) = @_;

    #Register
    my $ls_client = new SimpleLookupService::Client::Registration();
    $ls_client->init({server => $self->{LS_CLIENT}, record => $record});
    my ($resCode, $res) = $ls_client->register();

    if($resCode == 0){
        $self->{LOGGER}->debug( "Registration succeeded with uri: " . $res->getRecordUri() );
    }else{
        $self->{LOGGER}->error( "Problem registering: " . $res->{message} );
        return '';
    }
    
    return $res;
}

sub _renew {
    my ( $self, $uri ) = @_;
    my $ls_client = new SimpleLookupService::Client::RecordManager();
    $ls_client->init({ server => $self->{LS_CLIENT}, record_id => $uri  });
    my ($resCode, $res) = $ls_client->renew();
    if ( $resCode == 0 ) {
        $self->{LOGGER}->debug( "Renewed $uri");
    }
    else {
        $self->{LOGGER}->error( "Couldn't renew registration for $uri. Error was: " . $res->{message} );
    }
    
    return $res;
}

sub _unregister {
    my ( $self, $uri ) = @_;
    my $ls_client = new SimpleLookupService::Client::RecordManager();
    $ls_client->init({ server => $self->{LS_CLIENT}, record_id => $uri  });
    my ($resCode, $res) = $ls_client->delete();
    if ( $resCode == 0 ) {
        $self->{LOGGER}->debug( "Unregistered $uri");
    }
    else {
        $self->{LOGGER}->error( "Couldn't unregister registration for $uri. Error was: " . $res->{message} );
    }
}


sub _save_reg_key {
    my ( $self, $uri, $expires, $checksum, $dup_checksum ) = @_;
    
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->{"LS_KEY_DB"}, '', '');
    my $stmt  = $dbh->prepare('INSERT INTO lsKeys VALUES(?, ?, ?, ?)');
    $stmt->execute($uri, $expires, $checksum, $dup_checksum);
    if($stmt->err){
        $self->{LOGGER}->warn( "Error adding key: " . $stmt->errstr );
    }
    $dbh->disconnect();
}

sub _update_reg_key {
    my ( $self, $expires, $uri ) = @_;
    
    $self->{LOGGER}->debug("Updating - expires: $expires, uri: $uri");
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->{"LS_KEY_DB"}, '', '');
    my $stmt  = $dbh->prepare('UPDATE lsKeys SET expires=? WHERE uri=?');
    $stmt->execute( $expires, $uri);
    if($stmt->err){
        $self->{LOGGER}->warn( "Error updating key $uri: " . $stmt->errstr );
        $dbh->disconnect();
        return '';
    }
    $dbh->disconnect();
}

sub _delete_reg_key {
    my ( $self, $uri ) = @_;
    
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->{"LS_KEY_DB"}, '', '');
    my $stmt  = $dbh->prepare('DELETE FROM lsKeys WHERE uri=?');
    $stmt->execute($uri);
    if($stmt->err){
        $self->{LOGGER}->warn( "Error deleting key $uri: " . $stmt->errstr );
        $dbh->disconnect();
        return '';
    }
    $dbh->disconnect();
}
sub _load_uri_db {
    my ( $self ) = @_;
    
    my $uri_db = {};
    my $service_reg_info = { uri=> '', checksum => ''};
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->{"LS_KEY_DB"}, '', '');
    my $stmt  = $dbh->prepare('SELECT uri, checksum, duplicateChecksum FROM lsKeys');
    $stmt->execute();
    if($stmt->err){
        $self->{LOGGER}->warn( "Error loading URIs: " . $stmt->errstr );
        $dbh->disconnect();
        return ($uri_db, $service_reg_info);
    }
    while(my @row = $stmt->fetchrow_array()){
        $uri_db->{$row[0]} = $row[1];
        if($row[2] eq 'service'){
            $service_reg_info->{uri} = $row[0];
            $service_reg_info->{checksum} = $row[1];
        }
    }
    $dbh->disconnect();
    
    return ($uri_db, $service_reg_info);
}

sub _build_service_registration {
    my ( $self, $service_params ) = @_;

    my $service = perfSONAR_PS::Client::LS::PSRecords::PSService->new();
    $service->init(
        serviceLocator => $service_params->{serviceLocator}, 
        serviceType => $service_params->{serviceType}, 
    	serviceName => $service_params->{serviceName},
    );
    $service->setServiceEventType($service_params->{'eventTypes'}) if($service_params->{'eventTypes'});
    $service->setMAType($service_params->{'maTypes'}) if($service_params->{'maTypes'});
    $service->setMATests($service_params->{'maTests'}) if($service_params->{'maTests'});
    $service->setCommunities($service_params->{'communities'}) if($service_params->{'communities'});
    $service->setDNSDomains($service_params->{'domains'}) if($service_params->{'domains'});
    $service->setSiteName($service_params->{'site_name'}) if($service_params->{'site_name'});
    $service->setCity($service_params->{'city'}) if($service_params->{'city'});
    $service->setRegion($service_params->{'region'}) if($service_params->{'region'});
    $service->setCountry($service_params->{'country'}) if($service_params->{'country'});
    $service->setZipCode($service_params->{'zip_code'}) if($service_params->{'zip_code'});
    $service->setLatitude($service_params->{'latitude'}) if($service_params->{'latitude'});
    $service->setLongitude($service_params->{'longitude'}) if($service_params->{'longitude'});
    
    return $service;
}

sub _clean_expired {
    my ( $self ) = @_;
 
    #delete expired entries from local db
    my $dbh = DBI->connect('dbi:SQLite:dbname=' . $self->{"LS_KEY_DB"}, '', '');
    my $ls_key_clean_expired  = $dbh->prepare('DELETE FROM lsKeys WHERE expires < ?');
    $ls_key_clean_expired->execute(time);
    if($ls_key_clean_expired->err){
        $self->{LOGGER}->error( "Error cleaning out expired keys: " . $ls_key_clean_expired->errstr );
    }
    $dbh->disconnect();
}
