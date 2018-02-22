package perfSONAR_PS::Client::PSConfig::Archive;

use Mouse;
use JSON::Validator;
use perfSONAR_PS::Client::PSConfig::JQTransform;
use perfSONAR_PS::Client::PSConfig::Schema qw(psconfig_json_schema);

extends 'perfSONAR_PS::Client::PSConfig::BaseMetaNode';

=item archiver()

Gets/sets archiver

=cut

sub archiver{
    my ($self, $val) = @_;
    return $self->_field('archiver', $val);
}

=item archiver_data()

Gets/sets data

=cut

sub archiver_data{
    my ($self, $val) = @_;
    return $self->_field_anyobj('data', $val);
}

=item archiver_data_param()

Gets/sets data parameter at given field

=cut

sub archiver_data_param {
    my ($self, $field, $val) = @_;
    return $self->_field_anyobj_param('data', $field, $val);
}

=item transform()

Gets/sets transform

=cut

sub transform{
    my ($self, $val) = @_;
    return $self->_field_class('transform', 'perfSONAR_PS::Client::PSConfig::JQTransform', $val);
}

=item ttl()

Gets/sets ttl

=cut

sub ttl{
    my ($self, $val) = @_;
    return $self->_field_duration('ttl', $val);
}

=item validate()

Validates archive against JSON schema. Returns list of errors. Will be empty list if no
errors.

=cut

sub validate {
    my $self = shift;
    my $validator = new JSON::Validator();
    my $schema = psconfig_json_schema();
    #tweak it so we just look at ArchiveSpecification
    $schema->{'required'} = [ 'archives' ];
    $validator->schema($schema);
    
    #plug-in archive in a way that will validate
    return $validator->validate({'archives' => {"archive" => $self->data()}});
}




__PACKAGE__->meta->make_immutable;

1;
