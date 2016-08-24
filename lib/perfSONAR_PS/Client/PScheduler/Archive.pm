package perfSONAR_PS::Client::PScheduler::Archive;

use Mouse;

has 'name' => (is => 'rw', isa => 'Str');
has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });

sub data_param {
    my ($self, $field, $val) = @_;
    
    unless(defined $field){
        return undef;
    }
    
    if(defined $val){
        $self->data->{$field} = $val;
    }
    
    return $self->data->{$field};
}

__PACKAGE__->meta->make_immutable;

1;