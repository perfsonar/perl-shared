package perfSONAR_PS::Client::PSConfig::BaseConnect;

=head1 NAME

perfSONAR_PS::Client::PSConfig::BaseConnect - Abstract class for reading in a JSON from http or file

=head1 DESCRIPTION

Abstract class for reading in a JSON from http or file

=cut

use Mouse;
use Params::Validate qw(:all);
use perfSONAR_PS::Client::Utils qw(send_http_request build_err_msg);
use JSON qw(from_json to_json);
use Log::Log4perl qw(get_logger);
use URI;

use perfSONAR_PS::Client::PSConfig::ApiFilters;

our $VERSION = 4.1;

my $logger;
if(Log::Log4perl->initialized()) {
    #this is intended to be a lib reliant on someone else initializing env
    #detect if they did but quietly move on if not
    #anything using $logger will need to check if defined
    $logger = get_logger(__PACKAGE__);
}


has 'url' => (is => 'rw', isa => 'Str');
has 'save_filename' => (is => 'rw', isa => 'Str');
has 'bind_address' => (is => 'rw', isa => 'Str|Undef');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::ApiFilters', default => sub { new perfSONAR_PS::Client::PSConfig::ApiFilters(); });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

=item config_obj()

Abstract method to return a Config object to be used by this object

=cut

sub config_obj {
    ##
    # Override this with the type of config object you want returned
    die 'Override config_obj';
}

sub _merge_configs {
    my ($self, $psconfig1, $psconfig2) = @_;
    
    #if no configs then nothing to do
    unless($psconfig1 && $psconfig2){
        return;
    }
    
    #merge psconfig2 into psconfig1
    my @fields = ('addresses', 'address-classes', 'archives', 
                    'contexts', 'groups', 'hosts', 'schedules', 'subtasks', 
                    'tasks', 'tests');
    foreach my $field(@fields){
        #if no key, then next
        next unless exists $psconfig2->data()->{$field};
        #init psconfig1 if needed
        $psconfig1->data()->{$field} = {} unless exists $psconfig1->data()->{$field};
        #iterate through psconfig2 but do not overwrite any fields that already exist
        foreach my $psconfig2_key(keys %{$psconfig2->data()->{$field}}){
            if(exists $psconfig1->data()->{$field}->{$psconfig2_key}){
                logger->warn("PSConfig merge: Skipping $field field's $psconfig2_key because it already exists") if($logger);
            }else{
                $psconfig1->data()->{$field}->{$psconfig2_key} = $psconfig2->data()->{$field}->{$psconfig2_key};
            }
        }
    }
}

sub _config_from_file() {
    my $self = shift;
    
    #remove prefix
    my $filename = $self->url();
    chomp $filename;
    $filename =~ s/^file:\/\///g;
    my $psconfig;
    
    eval{
        my $json_text = do {
           open(my $fh, "<:encoding(UTF-8)", $filename) or die("Can't open $filename: $!");
           local $/;
           <$fh>
        };

        my $json_obj = from_json($json_text);
        if(!$json_obj){
            $self->_set_error("No config object found $filename.");
            return;
        }
        
        $psconfig = $self->config_obj();
        $psconfig->data($json_obj);
    };
    if($@){
        $self->_set_error($@);
        return;
    }
    
    return $psconfig;
}

sub _config_from_http() {
    my $self = shift;
    my $psconfig;
    
    eval{
        my $response = send_http_request(
            connection_type => 'GET', 
            url => $self->url, 
            timeout => $self->filters->timeout,
            ca_certificate_file => $self->filters->ca_certificate_file,
            ca_certificate_path => $self->filters->ca_certificate_path,
            verify_hostname => $self->filters->verify_hostname,
            local_address => $self->bind_address,
            #headers => $self->filters->headers()
        );

        if(!$response->is_success){
            my $msg = build_err_msg(http_response => $response);
            $self->_set_error($msg);
            return;
        }

        my $response_json = from_json($response->content);
        if(!$response_json){
            $self->_set_error("No task objects returned.");
            return;
        }
        
        $psconfig = $self->config_obj();
        $psconfig->data($response_json);
    };
    if($@){
        $self->_set_error($@);
        return;
    }
    
    return $psconfig;
}

=item get_config()

Loads configuration from file or URL and returns config object

=cut

sub get_config() {
    my $self = shift;
    
    #Make sure we have a URL
    if(!$self->url()){
        $self->_set_error("No URL defined.");
        return;
    }
    
    #Retrieve based on URL type
    my $uri = new URI($self->url());
    if(!$uri->scheme || $uri->scheme eq 'file'){
        #local file
        return $self->_config_from_file();
    }elsif($uri->scheme =~ /^https?$/){
        #http or https
        return $self->_config_from_http();
    }else{
        $self->_set_error("Unrecognized URL type (" . $self->url() . "). Must start with http://, file:// or be a file path");
        return;
    }
}

=item save_config()

Saves configuration file to disk

=cut

sub save_config() {
    my ($self, $psconfig, $formatting_params) = @_;
    $formatting_params = {} unless $formatting_params;
    my $filename = $self->save_filename();
    chomp $filename;
    $filename =~ s/^file:\/\///g;
    unless($filename) {
        $self->_set_error("No save_filename set");
        return;
    }
    
    eval{
        open(my $fh, ">:encoding(UTF-8)", $filename) or die("Can't open $filename: $!");
        print $fh $psconfig->json($formatting_params);
        close $fh;
    };
    if($@){
        $self->_set_error($@);
    }
}

=item expand_config()

Expands includes in config

=cut

sub expand_config() {
    my ($self, $psconfig1) = @_;
    
    #check if can handle includes
    unless($psconfig1->can('includes')){
         $self->_set_error("Configuration does not support includes");
         return;
    }
    
    #exit if no psconfig
    my $includes = $psconfig1->includes();
    unless($psconfig1 && $includes){
        return;
    }
    
    #iterate through includes and expand
    $self->_clear_error();#clear out errors
    my @errors = ();
    foreach my $include_url(@{$includes}){
        my $psconfig2_client = $self->blessed()->new(url=>$include_url);
        my $psconfig2 = $psconfig2_client->get_config();
        if($psconfig2_client->error()){
            #if error getting an include, proceed with the rest
            push @errors, "Error including $include_url: " . $psconfig2_client->error();
            next;
        }
        #do the merge
        $self->_merge_configs($psconfig1, $psconfig2);
    }
    if(@errors > 0){
         $self->_set_error(join "\n", @errors);
    }
}

sub _clear_error(){
    my ($self) = @_;
    $self->_set_error('');
}




__PACKAGE__->meta->make_immutable;

1;