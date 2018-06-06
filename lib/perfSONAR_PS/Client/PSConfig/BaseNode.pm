package perfSONAR_PS::Client::PSConfig::BaseNode;

use Mouse;
use JSON qw(to_json from_json);
use Digest::MD5 qw(md5_base64);
use Data::Validate::IP qw(is_ipv4 is_ipv6);
use Data::Validate::Domain qw(is_hostname);
use perfSONAR_PS::Client::PSConfig::Addresses::Address;
use perfSONAR_PS::Client::PSConfig::Addresses::RemoteAddress;
use URI;

has 'data' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'validation_error' => (is => 'ro', isa => 'Str', writer => '_set_validation_error');
has 'map_name' => (is => 'ro', isa => 'Str', writer => '_set_map_name');

=item checksum()

Calculates checksum for object that can be used in comparisons

=cut

sub checksum{
    #calculates checksum for comparing tasks, ignoring stuff like UUID and lead url
    my ($self) = @_;
        
    #disable canonical since we don't care at the moment
    my $data_copy = from_json(to_json($self->data, {canonical => 0, utf8 => 1}));
  
    #canonical should keep it consistent by sorting keys
    return md5_base64(to_json($data_copy, {canonical => 1, utf8 => 1}));
}

=item json()

Converts object to JSON. Accepts option HashRef with JSON formatting options. See perl 
JSON module for information on accepted parameters.

=cut

sub json {
     my ($self, $formatting_params) = @_;
     $formatting_params = {} unless $formatting_params;
     unless(exists $formatting_params->{'utf8'} && defined $formatting_params->{'utf8'}){
        $formatting_params->{'utf8'} = 1;
     }
     unless(exists $formatting_params->{'canonical'} && defined $formatting_params->{'canonical'}){
        #makes JSON loading faster
        $formatting_params->{'canonical'} = 0;
     }
     
     return to_json($self->data, $formatting_params);
}

=item remove()

Removes item from data HashRef with given key

=cut

sub remove {
    my ($self, $field) = @_;
    $self->_remove_map($self->_normalize_key($field));
}

=item remove_list_item()

Removes item from list in data HashRef with given key and index

=cut

sub remove_list_item{
    my ($self, $field, $index) = @_;
    $field = $self->_normalize_key($field);
    
    unless(defined $index && $index =~ /^\d+$/){
        return;
    }
    
    unless(exists $self->data()->{$field} && 
            ref $self->data()->{$field} eq 'ARRAY' && 
            @{$self->data()->{$field}} > $index){
        return;
    }
    
    splice @{$self->data()->{$field}}, $index, 1;
}

sub _add_list_item{
    my ($self, $field, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->data->{$field}){
        $self->data->{$field} = [];
    }

    push @{$self->data->{$field}}, $val;
}

sub _field{
    my ($self, $field, $val) = @_;
    if(defined $val){
        $self->data->{$field} = $val;
    }
    return $self->data->{$field};
}

sub _field_list{
    my ($self, $field, $val) = @_;
    
    #handle case where scalar provided
    if(defined $val){
        if(ref($val) eq 'ARRAY'){
            $self->data->{$field} = $val;
        }else{
            $self->data->{$field} = [$val];
        }
    }
    
    if($self->data->{$field} && ref($self->data->{$field}) ne 'ARRAY'){
        return [$self->data->{$field}];
    }
    
    return $self->data->{$field};
}

sub _field_map{
    my ($self, $field, $val) = @_;
    
    if(defined $val){
        unless(ref $val eq 'HASH'){
            $self->_set_validation_error("Unable to set $field. Value must be a hashref.");
            return;
        }
        my $tmp_map = {};
        foreach my $v(keys %{$val}){
            $tmp_map->{$v} = $val->{$v}->data;
        }
        $self->data->{$field} = $tmp_map;
    }
    
    return $self->data->{$field};
}

sub _field_map_item{
    my ($self, $field, $param, $val) = @_;
    
    unless(defined $field && defined $param){
        return undef;
    }
    
    if(defined $val){
        $self->data->{$field}->{$param} = $val;
    }
    
    unless($self->_has_field($self->data, $field)){
        return undef;
    }
    
    unless($self->_has_field($self->data->{$field}, $param)){
        return undef;
    }
    
    return $self->data->{$field}->{$param};
} 

sub _field_class{
    my ($self, $field, $class, $val) = @_;
    
    unless(defined $field && defined $class){
        return;
    }
    
    if(defined $val){
        if($self->_validate_class($field, $class, $val)){
            $self->data->{$field} = $val->data;
        }else{
            return;
        }
    }
    unless(exists $self->data->{$field}){
        return;
    }
    
    return $class->new(data => $self->data->{$field});
}

sub _field_class_list{
    my ($self, $field, $class, $val) = @_;
    
    if(defined $val){
        if(ref $val ne 'ARRAY'){
            $self->_set_validation_error("$field must be an arrayref");
            return;
        }
        my @tmp = ();
        foreach my $v(@{$val}){
            if($self->_validate_class($field, $class, $v)){
                push @tmp, $v->data;
            }else{
                return;
            }
        }
        $self->data->{$field} = \@tmp;
    }
    
    my @tmp_objs = ();
    foreach my $data(@{$self->data->{$field}}){
        push @tmp_objs, $class->new(data => $data);
    }
    return \@tmp_objs;
}

sub _field_class_list_item{
    my ($self, $field, $index, $class, $val) = @_;
    
    unless($field && exists $self->data->{$field} && 
            ref $self->data->{$field} eq 'ARRAY' &&
            defined $index &&
            @{$self->data->{$field}} > $index){
        return;
    }
    
    if(defined $val){
        if($self->_validate_class($field, $class, $val)){
            $self->data->{$field}->[$index] = $val->data;
        }else{
            return;
        }
    }
    
    return $class->new(data => $self->data->{$field}->[$index]);
}

sub _field_class_map{
    my ($self, $field, $class, $val) = @_;
    
    if(defined $val){
        unless(ref $val eq 'HASH'){
            $self->_set_validation_error("Unable to set $field. Value must be a hashref.");
            return;
        }
        my $tmp_map = {};
        foreach my $v(keys %{$val}){
            if($self->_validate_class($field, $class, $val->{$v})){
                $tmp_map->{$v} = $val->{$v}->data;
            }else{
                return;
            }
        }
        $self->data->{$field} = $tmp_map;
    }
    
    my %tmp_obj_map = ();
    foreach my $field_key(keys %{$self->data->{$field}}){
        my $tmp_obj = $self->_field_class_map_item($field, $field_key, $class);
        $tmp_obj_map{$field_key} = $tmp_obj;
    }
    
    return \%tmp_obj_map;
}

sub _field_class_map_item{
    my ($self, $field, $param, $class, $val) = @_;
    
    unless(defined $field && defined $param && defined $class){
        return undef;
    }
    
    if(defined $val){
        if($self->_validate_class($field, $class, $val)){
            $self->_init_field($self->data, $field);
            $self->data->{$field}->{$param} = $val->data;
        }else{
            return;
        }
    }
    
    unless($self->_has_field($self->data, $field)){
        return undef;
    }
    
    unless($self->_has_field($self->data->{$field}, $param)){
        return undef;
    }
    
    my $o = $class->new(data => $self->data->{$field}->{$param});
    $o->_set_map_name($param);
    return $o;
} 



sub _field_class_factory{
    my ($self, $field, $base_class, $factory_class, $val) = @_;

    unless(defined $field && defined $base_class && defined $factory_class){
        return;        
    }
    
    if(defined $val){
        if($self->_validate_class($field, $base_class, $val)){
           $self->data->{$field} = $val->data;
        }else{
            return;
        }
    }
    my $factory = $factory_class->new();
    return $factory->build($self->data->{$field});
}

sub _field_class_factory_list{
    my ($self, $field, $base_class, $factory_class, $val) = @_;
    if(defined $val){
        if(ref $val ne 'ARRAY'){
            $self->_set_validation_error("$field must be an arrayref");
            return;
        }
        my @tmp = ();
        foreach my $v(@{$val}){
            if($self->_validate_class($field, $base_class, $v)){
               push @tmp, $v->data;
            }else{
                return;
            }
        }
        $self->data->{$field} = \@tmp;
    }
    my @tmp_objs = ();
    my $factory = $factory_class->new();
    foreach my $data(@{$self->data->{$field}}){
        push @tmp_objs, $factory->build($data);
    }
    return \@tmp_objs;
}

sub _field_class_factory_list_item{
    my ($self, $field, $index, $base_class, $factory_class, $val) = @_;
    
    unless($field && exists $self->data->{$field} && 
            ref $self->data->{$field} eq 'ARRAY' &&
            defined $index &&
            @{$self->data->{$field}} > $index){
        return;
    }
    
    if(defined $val){
        if($self->_validate_class($field, $base_class, $val)){
            $self->data->{$field}->[$index] = $val->data;
        }else{
            return;
        }
    }
    
    my $factory = $factory_class->new();
    return $factory->build($self->data->{$field}->[$index]);
}

sub _field_class_factory_map{
    my ($self, $field, $base_class, $factory_class, $val) = @_;
    
    if(defined $val){
        unless(ref $val eq 'HASH'){
            $self->_set_validation_error("Unable to set $field. Value must be a hashref.");
            return;
        }
        my $tmp_map = {};
        foreach my $v(keys %{$val}){
            if($self->_validate_class($field, $base_class, $val->{$v})){
                $tmp_map->{$v} = $val->{$v}->data;
            }else{
                return;
            }
        }
        $self->data->{$field} = $tmp_map;
    }
    
    my %tmp_obj_map = ();
    foreach my $field_key(keys %{$self->data->{$field}}){
        my $tmp_obj = $self->_field_class_factory_map_item($field, $field_key, $base_class, $factory_class);
        $tmp_obj_map{$field_key} = $tmp_obj;
    }
    
    return \%tmp_obj_map;
}

sub _field_class_factory_map_item{
    my ($self, $field, $param, $base_class, $factory_class, $val) = @_;
    
    unless(defined $field && defined $param && defined $base_class && defined $factory_class){
        return undef;
    }
    
    if(defined $val){
        if($self->_validate_class($field, $base_class, $val)){
            $self->_init_field($self->data, $field);
            $self->data->{$field}->{$param} = $val->data;
        }else{
            return;
        }
    }
    
    unless($self->_has_field($self->data, $field)){
        return undef;
    }
    
    unless($self->_has_field($self->data->{$field}, $param)){
        return undef;
    }
    
    my $factory = $factory_class->new();
    return $factory->build($self->data->{$field}->{$param});
} 

sub _add_field_class{
    my ($self, $field, $class, $val) = @_;
    
    unless(defined $field && defined $class && defined $val){
        return;
    }
    
    unless($self->data->{$field}){
        $self->data->{$field} = [];
    }
    
    if($self->_validate_class($field, $class, $val)){
        push @{$self->data->{$field}}, $val->data;
    }else{
        return;
    }
    
}

sub _field_refs{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if(ref $val ne 'ARRAY'){
            $self->_set_validation_error("$field must be an arrayref");
            return;
        }
        foreach my $v(@{$val}){
            unless($self->_validate_name($v)){
                $self->_set_validation_error("$field cannot be set to $val. Must contain only letters, numbers, periods, underscores, hyphens and colons.");
                return;
            }
        }

        $self->data->{$field} = $val;
    }
    return $self->data->{$field};
}

sub _add_field_ref{
    my ($self, $field, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->_validate_name($val)){
        $self->_set_validation_error("$field cannot be set to $val. Must contain only letters, numbers, periods, underscores, hyphens and colons.");
        return;
    }
    
    unless($self->data->{$field}){
        $self->data->{$field} = [];
    }
    
    push @{$self->data->{$field}}, $val;
}

sub _field_anyobj{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if(ref $val eq 'HASH'){
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("Unable to set $field. Value must be a hashref.");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_anyobj_param {
    my ($self, $field, $param, $val) = @_;
    
    unless(defined $field && defined $param){
        return undef;
    }
    
    if(defined $val){
        $self->_init_field($self->data, $field);
        $self->data->{$field}->{$param} = $val;
    }
    
    unless($self->_has_field($self->data, $field)){
        return undef;
    }
    
    return $self->data->{$field}->{$param};
}

sub _field_enum{
    my ($self, $field, $val, $valid) = @_;
    if(defined $val){
        if(defined $valid){
            if(exists $valid->{$val}){
                $self->data->{$field} = $val;
            }else{
                $self->_set_validation_error("$field cannot be set to $val. Must be one of " . join(',', keys %{ $valid }) );
                return;
            }
        }else{
            $self->data->{$field} = $val;
        }
    }
    return $self->data->{$field};
}

sub _field_name{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($self->_validate_name($val)){
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must contain only letters, numbers, periods, underscores, hyphens and colons.");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_bool{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if("$val" eq '1'){
            $self->data->{$field} = JSON::true;
        }elsif("$val" eq '0'){
            $self->data->{$field} = JSON::false;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. It is a boolean and must be set to 0 or 1.");
            return;
        }
    }
    return $self->data->{$field} ? 1 : 0;
}

sub _field_ipversion{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($val == 4 || $val == 6){
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Allowed IP versions are 4 and 6");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_ipcidr{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($val =~ /^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))$/){
            #IPv4CIDR
            $self->data->{$field} = $val;
        }elsif($val =~ /^s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/([0-9]|[1-9][0-9]|1[0-1][0-9]|12[0-8]))$/){
            #IPv6CIDR
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be valid IPv4 or IPv6 CIDR.");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_host{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($self->_validate_host($val)){
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be valid IPv4, IPv6 or hostname.");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_host_list{
    my ($self, $field, $val) = @_;
    
    if(defined $val){
        if(ref $val ne 'ARRAY'){
            $self->_set_validation_error("$field must be an arrayref");
            return;
        }
        foreach my $v(@{$val}){
           unless($self->_validate_host($v)){
                $self->_set_validation_error("$field cannot be set to $v. Must be valid IPv4, IPv6 or hostname.");
                return;
            }
        }
        $self->data->{$field} = $val;
    }
    
    return $self->data->{$field};
}

sub _field_host_list_item{
    my ($self, $field, $index, $val) = @_;
    
    unless($field && exists $self->data->{$field} && 
            ref $self->data->{$field} eq 'ARRAY' &&
            defined $index &&
            @{$self->data->{$field}} > $index){
        return;
    }
    
    if(defined $val){
        if($self->_validate_host($val)){
            $self->data->{$field}->[$index] = $val;
        }else{
            return;
        }
    }
    
    return $self->data->{$field}->[$index];
}

sub _add_field_host{
    my ($self, $field, $val) = @_;
    
    unless(defined $val){
        return;
    }
    
    unless($self->_validate_host($val)){
        $self->_set_validation_error("$field cannot be set to $val. Must be valid IPv4, IPv6 or hostname.");
        return;
    }
    
    unless($self->data->{$field}){
        $self->data->{$field} = [];
    }
    
    push @{$self->data->{$field}}, $val;
}

sub _field_cardinal{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if(int($val) > 0){
            $self->data->{$field} = int($val);
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be integer greater than 0");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_int{
    my ($self, $field, $val) = @_;
    if(defined $val){
        $self->data->{$field} = int($val);
    }
    return $self->data->{$field};
}

sub _field_intzero{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if(int($val) >= 0){
            $self->data->{$field} = int($val);
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be integer greater than or equal to 0");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_probability{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($val >= 0.0 && $val <= 1.0){
            $self->data->{$field} = $val + 0.0;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be number between 0 and 1 (inclusive)");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_duration{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($self->_validate_duration($val)){
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be IS8601 duration");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_url{
    my ($self, $field, $val, $allowed_scheme_map) = @_;
    
    $allowed_scheme_map = $allowed_scheme_map ? $allowed_scheme_map : {'http'=>1, 'https' => 1, "file" => 1};
    
    if(defined $val){
        my $uri = new URI($val);
        unless($uri->scheme() && $allowed_scheme_map->{$uri->scheme()}){
            my $prefixes = join ",", keys %{ $allowed_scheme_map};
            $self->_set_validation_error("$field cannot be set to $val. URL must start with " . $prefixes);
            return;
        }
        if($uri->can('host_port')){
            #file:// does not do host-port, so need to make sure it can
            unless($self->_validate_urlhostport($uri->host_port())){
                $self->_set_validation_error("$field cannot be set to $val. Cannot determine valid URL host and port.");
                return;
            }
        }
        $self->data->{$field} = $uri->canonical . ""; #normalize URL
    }
    return $self->data->{$field};
}

sub _field_urlhostport{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($self->_validate_urlhostport($val)){
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be valid host/port combo or RFC2732 value.");
            return;
        }
    }
    return $self->data->{$field};
}

sub _field_timestampabsrel{
    my ($self, $field, $val) = @_;
    if(defined $val){
        if($self->_validate_duration($val)){
            $self->data->{$field} = $val;
        }elsif($val =~ /^([\+-]?\d{4}(?!\d{2}\b))((-?)((0[1-9]|1[0-2])(\3([12]\d|0[1-9]|3[01]))?|W([0-4]\d|5[0-2])(-?[1-7])?|(00[1-9]|0[1-9]\d|[12]\d{2}|3([0-5]\d|6[1-6])))([T\s]((([01]\d|2[0-3])((:?)[0-5]\d)?|24\:?00)([\.,]\d+(?!:))?)?(\17[0-5]\d([\.,]\d+)?)?([zZ]|([\+-])([01]\d|2[0-3]):?([0-5]\d)?)?)?)?$/){
            #IS8601 abs timestamp
            $self->data->{$field} = $val;
        }elsif($val =~ /^@(R\d*\/)?P(?:\d+(?:\.\d+)?Y)?(?:\d+(?:\.\d+)?M)?(?:\d+(?:\.\d+)?W)?(?:\d+(?:\.\d+)?D)?(?:T(?:\d+(?:\.\d+)?H)?(?:\d+(?:\.\d+)?M)?(?:\d+(?:\.\d+)?S)?)?$/){
            #IS8601 relative timestamp
            $self->data->{$field} = $val;
        }else{
            $self->_set_validation_error("$field cannot be set to $val. Must be valid IS8601 duration, absolute or relative timestamp.");
            return;
        }
    }
    return $self->data->{$field};
}

sub _normalize_key {
    my ($self, $field) = @_;
    $field =~ s/_/-/g; #normalize to json key in case used perl style key
    return $field;
}

sub _validate_class {
    my ($self, $field, $class, $val) = @_;
    if(defined $val){
        eval{ 
            unless($val->isa($class)){
                die("Value of $field is an object but must be of type $class");
            }    
        };
        if($@){
            $self->_set_validation_error("Error validating $field is of type $class: $@");
            return 0;
        }
        return 1;
    }
    return 0;
}

sub _validate_duration{
    my ($self, $val) = @_;
    if(defined $val){
        if($val =~ /^P(?:\d+(?:\.\d+)?W)?(?:\d+(?:\.\d+)?D)?(?:T(?:\d+(?:\.\d+)?H)?(?:\d+(?:\.\d+)?M)?(?:\d+(?:\.\d+)?S)?)?$/){
            return 1;
        }
    }
    return 0;
}

sub _validate_name{
    my ($self, $val) = @_;
    if(defined $val){
        if($val =~ /^[a-zA-Z0-9:._\-]+$/){
            return 1;
        }
    }
    return 0;
}

sub _validate_host{
    my ($self, $val) = @_;
    if(defined $val){
        if(is_ipv4($val) || is_ipv6($val) || is_hostname($val)){
            return 1;
        }
    }
    return 0;
}

sub _validate_urlhostport{
    my ($self, $val) = @_;
    if(defined $val){
        if($val =~ /^(([a-zA-Z0-9]|[a-zA-Z0-9][a-zA-Z0-9\-]*[a-zA-Z0-9])\.)*([A-Za-z0-9]|[A-Za-z0-9][A-Za-z0-9\-]*[A-Za-z0-9])(:[0-9]+)?$/){
            #hostname and port
            return 1;
        }elsif($val =~ /^\[(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9])\.){3,3}(25[0-5]|(2[0-4]|1{0,1}[0-9]){0,1}[0-9]))\](:[0-9]+)?$/){
             #ipv6 bracketed with port (RFC2732)
             return 1;
        }
    }
    return 0;
}

sub _has_field{
     my ($self, $parent, $field) = @_;
     return (exists $parent->{$field} && defined $parent->{$field});
}

sub _init_field{
     my ($self, $parent, $field) = @_;
     unless($self->_has_field($parent, $field)){
        $parent->{$field} = {};
     }
}

sub _get_map_names{
    my ($self, $field) = @_;
    
    unless($self->_has_field($self->data, $field)){
        return [];
    }
    
    my @names = keys %{$self->data()->{$field}};
    return \@names;
}

sub _remove_map_item{
    my ($self, $parent_field, $field) = @_;
    
    unless(exists $self->data()->{$parent_field} &&
            exists $self->data()->{$parent_field}->{$field}){
        return;
    }
    
    delete $self->data()->{$parent_field}->{$field};
}

sub _remove_map{
    my ($self, $field) = @_;
    
    unless(exists $self->data()->{$field}){
        return;
    }
    
    delete $self->data()->{$field};
}

__PACKAGE__->meta->make_immutable;


1;