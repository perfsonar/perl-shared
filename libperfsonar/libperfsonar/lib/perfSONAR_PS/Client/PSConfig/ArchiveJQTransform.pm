package perfSONAR_PS::Client::PSConfig::ArchiveJQTransform;

use Mouse;
use JSON;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

=item script()

Getter/Setter for JQ script. Can be string or array of strings where each item in list
is a line of the JQ script

=cut

sub script{
    my ($self, $val) = @_;
    
    return $self->_field_list('script', $val);
}

=item output_raw()

Tells pscheduler to output in raw format instead of JSON

=cut

sub output_raw{
    my ($self, $val) = @_;
    return $self->_field_bool('output-raw', $val);
}

=item args()

Additional args pScheduler will pass to jq parser

=cut

sub args{
    my ($self, $val) = @_;
    return $self->_field_anyobj('args', $val);
}


__PACKAGE__->meta->make_immutable;

1;
