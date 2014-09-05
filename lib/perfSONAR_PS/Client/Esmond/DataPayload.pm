package perfSONAR_PS::Client::Esmond::DataPayload;

use Mouse;

has 'ts' => (is => 'rw', isa => 'Int');
has 'val' => (is => 'rw', isa => 'HashRef|ArrayRef|Str');

sub datetime {
    my $self = shift;
    return DateTime->from_epoch(epoch => $self->ts);
}

__PACKAGE__->meta->make_immutable;

1;