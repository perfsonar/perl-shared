package perfSONAR_PS::Client::PSConfig::BaseNode;

use Mouse;
use JSON qw(to_json from_json);
use Digest::MD5 qw(md5_base64);

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });

sub checksum{
    #calculates checksum for comparing tasks, ignoring stuff like UUID and lead url
    my ($self) = @_;
        
    #disable canonical since we don't care at the moment
    my $data_copy = from_json(to_json($self->data, {canonical => 0, utf8 => 1}));
  
    #canonical should keep it consistent by sorting keys
    return md5_base64(to_json($data_copy, {canonical => 1, utf8 => 1}));
}

sub json {
     my ($self, $formatting_params) = @_;
     $formatting_params = {} unless $formatting_params;
     unless(exists $formatting_params->{'utf8'} && defined $formatting_params->{'utf8'}){
        $formatting_params->{'utf8'} = 1;
     }
     unless(exists $formatting_params->{'canonical'} && defined $formatting_params->{'canonical'}){
        #makes JSON loading faster
        $formatting_params->{'canonical'} = 0;
     }
     
     return to_json($self->data, $formatting_params);
}

sub _has_field{
     my ($self, $parent, $field) = @_;
     return (exists $parent->{$field} && defined $parent->{$field});
}

sub _init_field{
     my ($self, $parent, $field) = @_;
     unless($self->_has_field($parent, $field)){
        $parent->{$field} = {};
     }
}

sub _get_map_names{
    my ($self, $field) = @_;
    
    unless($self->_has_field($self->data, $field)){
        return [];
    }
    
    my @names = keys %{$self->data()->{$field}};
    return \@names;
}

sub _remove_map_item{
    my ($self, $parent_field, $field) = @_;
    
    unless(exists $self->data()->{$parent_field} &&
            exists $self->data()->{$parent_field}->{$field}){
        return;
    }
    
    delete $self->data()->{$parent_field}->{$field};
}

sub _remove_map{
    my ($self, $field) = @_;
    
    unless(exists $self->data()->{$field}){
        return;
    }
    
    delete $self->data()->{$field};
}

__PACKAGE__->meta->make_immutable;

1;