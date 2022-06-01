package perfSONAR_PS::Client::PSConfig::JQTransform;

use Mouse;
use JSON;
use JSON::Validator;
use perfSONAR_PS::Utils::JQ qw( jq );

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

has 'error' => (is => 'ro', isa => 'Str|Undef', writer => '_set_error');

=item script()

Getter/Setter for JQ script. Can be string or array of strings where each item in list
is a line of the JQ script

=cut

sub script {
    my ($self, $val) = @_;
    return $self->_field_list('script', $val);
}

=item apply()

Applies JQ script to provided object

=cut

sub apply {
    my ($self, $json_obj) = @_;
    
    #reset error
    $self->_set_error(undef);
    
    #apply script
    my $transformed;
    eval{ $transformed = jq($self->script(), $json_obj); };
    if($@){
         $self->_set_error($@);
         return;
    }
    
    return $transformed;
}

=item validate()

Validates this object against JSON schema. Returns any errors found. Valid if list is empty.

=cut

sub validate {
    my $self = shift;
    my $validator = new JSON::Validator();
    #tweak it so we just look at JQTransformSpecification
    $validator->schema(_schema());
    
    #plug-in archive in a way that will validate
    return $validator->validate($self->data());
}

sub _schema() {

    my $raw_json = <<'EOF';
{
    "$schema": "http://json-schema.org/draft-04/schema#",
    "type": "object",
    "properties": {
        "script":   {
            "anyOf": [
                { "type": "string" },
                { "type": "array", "items": { "type": "string" } }
            ]
        }
    },
    "additionalProperties": false,
    "required": [ "script" ]
}   
EOF

    return from_json($raw_json);
}

__PACKAGE__->meta->make_immutable;

1;
