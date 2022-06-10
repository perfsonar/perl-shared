package perfSONAR_PS::NPToolkit::WebService::ParameterTypes;

use strict;
use warnings;

use Exporter;

use base 'Exporter';

our @EXPORT = qw( $parameter_types );

# parameter_types is a hashref containing keys for the parameter type.
# under each key is a 'pattern', a regex that is used to check the value,
# and 'error_text' which will be displayed in the form (for example):
# "only accepts integers"
# this will later be combined with the parameter name like this:
# "Parameter '$name' only accepts integers"

our $parameter_types = {};

$parameter_types->{'numeral'}->{'pattern'} = '^(\d+)$';
$parameter_types->{'numeral'}->{'error_text'} = 'only accepts numerals (0 through 9)';

$parameter_types->{'integer'}->{'pattern'} = '^(\-?\d+)$';
$parameter_types->{'integer'}->{'error_text'} = 'only accepts positive or negative integers';

$parameter_types->{'positive_integer'}->{'pattern'} = '^([1-9]+)$';
$parameter_types->{'positive_integer'}->{'error_text'} = 'only accepts positive integers (1-9)';

$parameter_types->{'number'}->{'pattern'} = '^(\-?\d+([.,]\d+)?)$';
$parameter_types->{'number'}->{'error_text'} = 'only accepts numbers';

# for now, accept any input for text (not just ascii)
#$parameter_types->{'text'}->{'pattern'} = '^([[:print:][:space:]]+)$';
$parameter_types->{'text'}->{'pattern'} = '.+';
$parameter_types->{'text'}->{'error_text'} = 'only accepts text';

$parameter_types->{'boolean'}->{'pattern'} = '^(0|1)$';
$parameter_types->{'boolean'}->{'error_text'} = 'only accepts boolean values (0 or 1)';

# very crude sanity check for postal codes
# accept a-z, A-Z, spaces, 0-9, dashes
# but no dash or space at beginning or end
$parameter_types->{'postal_code'}->{'pattern'} = '^[a-zA-Z0-9][a-zA-Z0-9\- ]{0,10}[a-zA-Z0-9]$';
$parameter_types->{'postal_code'}->{'error_text'} = 'only accepts postal codes (a-z, A-Z, spaces, 0-9, and dashes)';

1;
