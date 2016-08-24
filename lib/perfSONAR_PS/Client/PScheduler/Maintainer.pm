package perfSONAR_PS::Client::PScheduler::Maintainer;

use Mouse;

has 'name' => (is => 'rw', isa => 'Str');
has 'email' => (is => 'rw', isa => 'Str');
has 'href' => (is => 'rw', isa => 'Str');

__PACKAGE__->meta->make_immutable;

1;