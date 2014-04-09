package perfSONAR_PS::Client::Esmond::DataPayload;

use Moose;
use DateTime;

has 'ts' => (is => 'rw', isa => 'Int');
has 'val' => (is => 'rw', isa => 'HashRef|ArrayRef|Str');

sub datetime {
    my $self = shift;
    return DateTime->from_epoch(epoch => $self->ts);
}

1;