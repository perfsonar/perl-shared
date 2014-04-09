package perfSONAR_PS::Client::Esmond::BaseNode;

use Moose;
use perfSONAR_PS::Client::Esmond::ApiFilters;

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'api_url' => (is => 'rw', isa => 'Str|Undef');
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::Esmond::ApiFilters|Undef');

1;