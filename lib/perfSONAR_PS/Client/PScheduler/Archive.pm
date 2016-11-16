package perfSONAR_PS::Client::PScheduler::Archive;

use Mouse;
use Params::Validate qw(:all);
use JSON qw(to_json);
use Digest::MD5 qw(md5_base64);

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

sub checksum() {
    #calculates checksum for comparing tasks, ignoring stuff like UUID and lead url
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 'include_private' => 0} );
    
    #disable canonical since we don't care at the moment
    my $archive= { 'name' => $self->name(), 'data' => {} };
    #clear our private fields that won't get displayed by remote tasks
    foreach my $datum(keys %{$self->data()}){
        if($datum =~ /^_/ && !$parameters->{'include_private'}){
            $archive->{'data'}->{$datum} = '';
        }else{
            $archive->{'data'}->{$datum} = $self->data()->{$datum};
        }
    }
        
    #canonical should keep it consistent by sorting keys
    return md5_base64(to_json($archive, {'canonical' => 1}));
}

__PACKAGE__->meta->make_immutable;

1;