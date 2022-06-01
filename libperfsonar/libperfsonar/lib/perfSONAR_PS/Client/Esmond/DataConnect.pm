package perfSONAR_PS::Client::Esmond::DataConnect;

use Mouse;
use perfSONAR_PS::Client::Esmond::ApiFilters;
use perfSONAR_PS::Client::Esmond::Summary;
use JSON qw(to_json);

extends 'perfSONAR_PS::Client::Esmond::BaseDataNode';

has 'uri' => (is => 'rw', isa => 'Str');

override '_uri' => sub {
    my $self = shift;
    return $self->uri();
};

__PACKAGE__->meta->make_immutable;

1;