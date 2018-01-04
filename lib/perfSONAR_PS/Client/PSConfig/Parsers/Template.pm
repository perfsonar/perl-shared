package perfSONAR_PS::Client::PSConfig::Parsers::Template;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Parsers::Template - A library for filling in template variables in JSON

=head1 DESCRIPTION

A library for filling in template variables in JSON

=cut

use Mouse;
use JSON;
use perfSONAR_PS::Client::PSConfig::Config;

our $VERSION = 4.1;

has 'groups' => (is => 'rw', isa => 'ArrayRef[perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress]', default => sub {[]});
has 'scheduled_by_address' => (is => 'rw', isa => 'perfSONAR_PS::Client::PSConfig::Addresses::BaseAddress');
has 'flip' => (is => 'rw', isa => 'Bool', default => sub {0});
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

sub expand {
    my ($self, $obj) = @_;
    
    #convert to string so we get copy and can do replace
    my $json = to_json($obj);
    
    #find the variables used
    my %template_var_map = ();
    while($json =~ /"\s*\{%\s+(.+?)\s+%\}\s*"/g){
        my $template_var = $1;
        next if($template_var_map{$template_var});
        chomp $template_var;
        my $expanded_val = $self->expand_var($template_var);
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
    }
    
    return $expanded_obj;
    
}

sub expand_var {
    ##
    # There is probably a more generic way to do this, but starting here
    my ($self, $template_var) = @_;
    my $val;
    
    if($template_var =~ /address\[(\d+)\]/){
        $val = $self->_parse_group_address($1);
    }elsif($template_var eq 'scheduled_by_address'){
        $val = $self->_parse_scheduled_by_address();
    }elsif($template_var eq 'flip'){
        $val = $self->_parse_flip();
    }else{
        $self->_set_error("Unrecognized template variable $template_var");
    }
    
    return $val;
}

sub _parse_group_address {
    my ($self, $index) = @_;
    
    if($index > @{$self->groups()}){
        $self->_set_error("Invalid index is too big in group[$index] template variable");
        return;
    }
    
    #this should not happen, but here for completeness
    unless($self->groups()->[$index]->address()){
        $self->_set_error("Template variable group[$index] does not have an address");
        return;
    }
    
    return '"' . $self->groups()->[$index]->address() . '"';
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

__PACKAGE__->meta->make_immutable;

1;

