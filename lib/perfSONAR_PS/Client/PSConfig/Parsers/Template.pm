package perfSONAR_PS::Client::PSConfig::Parsers::Template;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Parsers::Template - A library for filling in template variables in JSON

=head1 DESCRIPTION

A library for filling in template variables in JSON

=cut

use Mouse;
use JSON;
use perfSONAR_PS::Client::PSConfig::Config;
use perfSONAR_PS::Utils::JQ qw( jq );

our $VERSION = 4.1;

has 'groups' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress]', default => sub {[]});
has 'scheduled_by_address' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress');
has 'jq_obj' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'flip' => (is => 'rw', isa => 'Bool', default => sub {0});
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

=item expand()

Parse the given perl object replace template variables with appropriate values. Returns copy
of object with expanded values.

=cut

sub expand {
    my ($self, $obj) = @_;
    
    #make sure we have an object, otherwise return what was given
    unless($obj){
        return $obj;
    }
    
    #reset error 
    $self->_set_error("");
    
    #convert to string so we get copy and can do replace
    my $json = to_json($obj);
    
    #find the variables used
    my %template_var_map = ();
    while($json =~ /"\s*\{%\s+(.+?)\s+%\}\s*"/g){
        my $template_var = $1;
        next if($template_var_map{$template_var});
        chomp $template_var;
        my $expanded_val = $self->_expand_var($template_var);
        unless(defined $expanded_val){
            return;
        }
        $template_var_map{$template_var} = $expanded_val;
    }
    
    #do the substutions 
    foreach my $template_var(keys %template_var_map){
        $json =~ s/"\s*\{%\s+\Q${template_var}\E\s+%\}\s*"/$template_var_map{$template_var}/g;
    }
    
    #convert back to object
    my $expanded_obj;
    eval{$expanded_obj = from_json($json)};
    if($@){
        $self->_set_error("Unable to create valid JSON after expanding template");
        return;
    }
    
    return $expanded_obj;
    
}

sub _expand_var {
    ##
    # There is probably a more generic way to do this, but starting here
    my ($self, $template_var) = @_;
    my $val;

    if($template_var =~ /^address\[(\d+)\]$/){
        $val = $self->_parse_group_address($1);
    }elsif($template_var =~ /^pscheduler_address\[(\d+)\]$/){
        $val = $self->_parse_pscheduler_address($1);
    }elsif($template_var =~ /^lead_bind_address\[(\d+)\]$/){
        $val = $self->_parse_lead_bind_address($1);
    }elsif($template_var eq 'scheduled_by_address'){
        $val = $self->_parse_scheduled_by_address();
    }elsif($template_var eq 'flip'){
        $val = $self->_parse_flip();
    }elsif($template_var eq 'localhost'){
        $val = $self->_parse_localhost();
    }elsif($template_var =~ '^jq (.+)$'){
        $val = $self->_parse_jq($1);
    }else{
        $self->_set_error("Unrecognized template variable $template_var");
    }
    
    return $val;
}

sub _parse_group_address {
    my ($self, $index) = @_;
    
    if($index >= @{$self->groups()}){
        $self->_set_error("Index is too big in group[$index] template variable");
        return;
    }
    
    #this should not happen, but here for completeness
    unless($self->groups()->[$index]->address()){
        $self->_set_error("Template variable group[$index] does not have an address");
        return;
    }
    
    return '"' . $self->groups()->[$index]->address() . '"';
}

sub _parse_pscheduler_address {
    my ($self, $index) = @_;
    
    if($index >= @{$self->groups()}){
        $self->_set_error("Index is too big in group[$index] template variable");
        return;
    }
    
    #this should not happen, but here for completeness
    my $address = $self->groups()->[$index]->pscheduler_address();
    #fallback to address
    $address = $self->groups()->[$index]->address() unless($address);
    unless($address){
        $self->_set_error("Template variable group[$index] does not have a pscheduler-address nor address");
        return;
    }
    
    return '"' . $address . '"';
}

sub _parse_lead_bind_address {
    my ($self, $index) = @_;
    
    if($index >= @{$self->groups()}){
        $self->_set_error("Index is too big in group[$index] template variable");
        return;
    }
    
    #this should not happen, but here for completeness
    my $address = $self->groups()->[$index]->lead_bind_address();
    #fallback to address
    $address = $self->groups()->[$index]->address() unless($address);
    unless($address){
        $self->_set_error("Template variable group[$index] does not have a lead-bind-address or address");
        return;
    }
    
    return '"' . $address . '"';
}

sub _parse_scheduled_by_address {
    my ($self) = @_;
    
    #should not be possible, but double-check
    unless($self->scheduled_by_address()){
        $self->_set_error("No scheduled_by_address value provided. This is likely a bug in the software.");
        return;
    }
    
    #also should not happen, but here for completeness
    unless($self->scheduled_by_address()->address()){
        $self->_set_error("scheduled_by_address cannot be determined. This is likely a bug in the software.");
        return;
    }
    
    return '"' . $self->scheduled_by_address()->address(). '"';
}

sub _parse_flip {
    my ($self, $index) = @_;

    return ($self->flip() ? JSON::true : JSON::false);
}

sub _parse_localhost {
    my ($self) = @_;
    
    #if flipped, use scheduled_by_address
    if($self->flip()){
        return $self->_parse_scheduled_by_address();
    }
    
    #otherwise use localhost
    return '"localhost"';
}

sub _parse_jq {
    my ($self, $jq) = @_;
    
    #in conversions to and from json in expand(), quotes get escaped, so revert that here
    $jq =~ s/\\"/"/g;
    
    my $result;
    eval{
        my $jq_result = jq($jq, $self->jq_obj());
        $result = to_json($jq_result, {"allow_nonref" => 1, 'utf8' => 1});
    };
    if($@){
        $self->_set_error("Error handling jq template variable: " . $@);
        return;
    }
    
    return $result;
}

__PACKAGE__->meta->make_immutable;

1;

