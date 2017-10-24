package perfSONAR_PS::Client::PSConfig::ApiFilters;

use Mouse;
use JSON;

has 'timeout' => (is => 'rw', isa => 'Int', default => sub { 60 });
has 'ca_certificate_file' => (is => 'rw', isa => 'Str|Undef');
has 'ca_certificate_path' => (is => 'rw', isa => 'Str|Undef');
has 'verify_hostname' => (is => 'rw', isa => 'Bool|Undef');



__PACKAGE__->meta->make_immutable;

1;
