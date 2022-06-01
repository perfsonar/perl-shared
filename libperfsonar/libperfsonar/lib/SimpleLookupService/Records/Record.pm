package SimpleLookupService::Records::Record;

=head1 NAME

SimpleLookupService::Records::Record - The base class for Lookup Service Records

=head1 DESCRIPTION

A base class for Lookup Service records. It defines the fields used by all 
records. service,interface, host and person records are direct subclasses of this class. It 
allows for any key to be added with the addField function.

ttl - specified in minutes (max - 43200 minutes (30 days))

=cut

use strict;
use warnings;

our $VERSION = 3.3;

use Params::Validate qw(:all);
use JSON qw(encode_json decode_json to_json);
use Crypt::OpenSSL::RSA;
use SimpleLookupService::Keywords::KeyNames;
use DateTime::Format::ISO8601;
use Carp qw(cluck);
use Crypt::OpenSSL::RSA;
use MIME::Base64 qw(encode_base64 decode_base64);

use SimpleLookupService::Utils::Time qw(minutes_to_iso iso_to_minutes is_iso iso_to_unix);

use base 'SimpleLookupService::Message';

sub new {
    my $package = shift;

    my $self = fields::new($package);

    return $self;
}

sub init {
    my ($self, @args) = @_;
    my %parameters = validate(@args, { type => 1, uri => 0, expires => 0, ttl => 0, client_uuid => 0 });

    if (ref($parameters{type}) eq 'ARRAY' && scalar @{$parameters{type}} > 1) {
        cluck "Record Type array size cannot be > 1";
        return -1;
    }

    unless (ref($parameters{type}) eq 'ARRAY') {
        $parameters{type} = [ $parameters{type} ];
    }

    $self->{RECORD_HASH} = {
            (SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE) => $parameters{type}
    }; 
    
    if(defined $parameters{expires}){
    	if(ref($parameters{expires}) eq 'ARRAY' && scalar @{$parameters{expires}} > 1){
    		cluck "Expires array size cannot be > 1";
    		return -1;
    	}
    	
    	unless(ref($parameters{expires}) eq 'ARRAY'){
    		$parameters{expires} = [$parameters{expires}];
    	}
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $parameters{expires};
    } 
    
    if(defined $parameters{uri} ){
    	if(ref($parameters{uri}) eq 'ARRAY' && scalar @{$parameters{uri}} > 1){
    		cluck "Record URI size cannot be > 1";
    		return -1;                                           
    	}
    	
    	unless(ref($parameters{uri}) eq 'ARRAY'){
    		$parameters{uri} = [$parameters{uri}];
    	}
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $parameters{uri};
    }
    
    if(defined $parameters{ttl}){
    	
    	if(ref($parameters{ttl}) eq 'ARRAY' && scalar @{$parameters{ttl}} > 1){
    		cluck "Record TTL size cannot be > 1";
    		return -1;
    	}
    	my $tmp;
    	if(ref($parameters{ttl}) eq 'ARRAY'){
    		$tmp = $parameters{ttl}->[0];
    	}else{
    		$tmp = $parameters{ttl};
    	}
    	
    	if(is_iso($tmp)){
    		$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$tmp];
    	}else{
    		cluck "Record TTL should be iso";
    		return -1;
    	}
    	
    } 
    
    if(defined $parameters{client_uuid} ){
    	unless(ref($parameters{client_uuid}) eq 'ARRAY'){
    		$parameters{client_uuid} = [$parameters{client_uuid}];
    	}
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_CLIENT_UUID)} = $parameters{client_uuid};
    }
     
    return 0;
}

sub addField {
    my ($self, @args) = @_;
    my %parameters = validate(@args, { key => 1, value => 1 });

    if (ref($parameters{key}) eq 'ARRAY') {
        cluck "Lookup Service Key cannot be an array";
        return -1;
    }
    unless (ref($parameters{value}) eq 'ARRAY') {
        $parameters{value} = [ $parameters{value} ];
    }
    $self->{RECORD_HASH}->{$parameters{key}} = $parameters{value};
    return 0;
}

sub getValue {
    my ($self, $key) = @_;

    if (defined $self->{RECORD_HASH}->{$key}) {
        unless (ref($self->{RECORD_HASH}->{$key}) eq 'ARRAY') {
            return [ $self->{RECORD_HASH}->{$key} ];
        }
        return $self->{RECORD_HASH}->{$key};
    }
    else {
        return(undef);
    }

}



sub getRecordType {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)};
}

sub setRecordType {
    my ($self, $value) = @_;
    if (ref($value) eq 'ARRAY' && scalar(@{$value}) > 1) {
        cluck "Record Type array size cannot be > 1";
        return -1;
    }

    unless (ref($value) eq 'ARRAY') {
        $value = [ $value ];
    }

    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TYPE)} = $value;
    return 0;
}

sub getRecordTtlAsIso {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];
    
    if(defined $value){
	    if(is_iso($value)){
	    	return [$value];
	    	
	    }else{
	    	my $tmp = minutes_to_iso($value);
	
	    	return [$tmp];
	    }
    }
    
    return undef;

}

sub setRecordTtlAsIso {
    my ($self, $value) = @_;

    if (ref($value) eq 'ARRAY' && scalar(@{$value}) > 1) {
        cluck "Record Ttl array size cannot be > 1";
        return -1;
    }

    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	$ttl = $value->[0];
    }else{
    	$ttl = $value;
    }
    
    if(is_iso($ttl)){
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [$ttl];
    }else{
    	cluck "Record Ttl not in ISO 8601 format";
    	return -1;
    }  
    
    return 0;
}

sub getRecordTtlInMinutes {
    my $self = shift;
    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)}->[0];
    
    if(defined $value){
	    if(is_iso($value)){
	    	my $tmp = iso_to_minutes($value);
	
	    	return [$tmp];
	    }else{
	    	return [$value];
	    }
    }
    
    return undef;

}


sub setRecordTtlInMinutes {
    my ($self, $value) = @_;

    if (ref($value) eq 'ARRAY' && scalar(@{$value}) > 1) {
        cluck "Record Ttl array size cannot be > 1";
        return -1;
    }

    my $ttl = 0;
    if(ref($value) eq 'ARRAY'){
    	$ttl = $value->[0];
    }else{
    	$ttl = $value;
    }
    
    if(is_iso($ttl)){
    	cluck "Record Ttl should be in minutes (integer)";
    	return -1;
    }else{
    	
    	$self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_TTL)} = [minutes_to_iso($ttl)];
    }  
    
    return 0;
}


sub getRecordExpiresAsUnixTS {
    my $self = shift;
    my $expires = '';

    my $value = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
    if(ref($value) eq 'ARRAY'){
        $expires = $value->[0];
    }else{
        $expires = $value;
    }


    if (defined $expires){
        my $unixts = iso_to_unix($expires);
    	return [$unixts];
    }else{
    	return undef;
    }
   
}

sub getRecordExpires {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};

}

sub setRecordExpires {
    my ($self, $value) = @_;

    if (ref($value) eq 'ARRAY' && scalar(@{$value}) > 1) {
        cluck "Record Type array size cannot be > 1";
        return -1;
    }

    unless (ref($value) eq 'ARRAY') {
        $value = [ $value ];
    }

    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)} = $value;
    return 0;
}

sub getRecordUri {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)};
}

sub setRecordUri {
    my ($self, $value) = @_;
    if (ref($value) eq 'ARRAY' && scalar(@{$value}) > 1) {
        cluck "Record Type array size cannot be > 1";
        return -1;
    }

    unless (ref($value) eq 'ARRAY') {
        $value = [ $value ];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)} = $value;
    return 0;
}

sub getRecordClientUUID {
    my $self = shift;
    return $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_CLIENT_UUID)};
}

sub setRecordClientUUID {
    my ($self, $value) = @_;

    unless (ref($value) eq 'ARRAY') {
        $value = [ $value ];
    }
    $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_CLIENT_UUID)} = $value;
    return 0;
}

sub toJson() {
    my $self = shift;

    if (defined $self->getRecordHash()) {
        #return encode_json($self->getRecordHash());
        return to_json($self->getRecordHash(), { canonical => 1, utf8 => 1 });


    }
    else {
        return undef;
    }

}

#creates record object from json
sub fromJson() {
    my ($self, $jsonData) = @_;

    if (defined $jsonData && $jsonData ne '') {
        my $perlDS = decode_json($jsonData);
        $self->fromHashRef($perlDS);
        return 0;
    }
    else {
        cluck "Error creating record. empty data";
        return -1;
    }

}

#creates record object from perl data structure
sub fromHashRef() {
    my ($self, $perlDS) = @_;

    if (defined $perlDS) {
        foreach my $key (keys %{$perlDS}) {
            $self->{RECORD_HASH}->{$key} = ${perlDS}->{$key};
        }
    }
    else {
        cluck "Error creating record. Empty hash";
        return -1;
    }

    return 0;
}


sub _is_iso {
    my ($self, $value) = @_;

    ($value =~ m/P\w*T/) ? return 1 : return 0;
}

sub _minutes_to_iso {
    my ($self, $ttl) = @_;

    if (defined $ttl && $ttl eq '') {
        cluck "Empty ttl";
        return undef;
    }

    my $isottl;

    if ($ttl =~ m/P\w*T/) {
        cluck "Found iso format";
        return undef;
    }
    $isottl = "PT" . $ttl . "M";

    return $isottl;
}

sub _iso_to_minutes {
    my ($self, $value) = @_;

    if (!defined $value) {
        return undef;
    }
    my @splitDuration = split(/T/, $value);

    my %dHash = (
        "Y" => 525600,
        "M" => 43200,
        "W" => 10080,
        "D" => 1440);

    my %tHash = (
        "H" => 60,
        "M" => 1,
        "S" => 0.0167);

    $splitDuration[0] =~ tr/P//d;

    my $minutes = 0;
    foreach my $key (keys %dHash) {
        $splitDuration[0] =~ m/(\d+)$key/;
        $minutes += $dHash{$key} * $1 if $1;
    }

    if (scalar @splitDuration == 2) {

        foreach my $key (keys %tHash) {
            $splitDuration[1] =~ m/(\d+)$key/;
            $minutes += $tHash{$key} * $1 if $1;
        }
    }

    ($minutes > 0) ? return int($minutes + 0.5) : return undef;

}


=head2 _isoToUnix($self { uri, base})

Converts a given ISO 8601 date string to a unix timestamp

=cut
sub _isoToUnix {
    my ($self, $str) = @_;
    my $dt = DateTime::Format::ISO8601->parse_datetime($str);
    return $dt->epoch();
}

=head2 normalizedJson($self)

# Creates canonicalized json of user-defined fields.

=cut


sub normalizedJson {

    my ($self) = @_;

    my $json_data = $self->toJson();
    my $data_copy = decode_json($json_data);

    if (exists($data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)})) {
        delete $data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_EXPIRES)};
    }

    if (exists($data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)})) {
        delete $data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_URI)};
    }
    if (exists($data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE)})) {
        delete $data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE)};
    }

    if (exists($data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_RECORD_STATE)})) {
        delete $data_copy->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_RECORD_STATE)};
    }

    my $canonical_json = to_json($data_copy, { canonical => 1, utf8 => 1 });

    return $canonical_json;

}

=head2 normalizedJson($self)

# Adds signature to the record using the provided private key

=cut

sub addsign {
    my ($self, $private_key) = @_;
    my $message = $self->normalizedJson();
    my $key_string = $private_key;
    my $rsa_priv = Crypt::OpenSSL::RSA->new_private_key($key_string);
    $rsa_priv->use_sha256_hash();

    my $signature = $rsa_priv->sign($message);
    my $encodedSignature = encode_base64($signature);
    $self->addField({ "key" => (SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE), "value" => $encodedSignature });
    return 0;
}

=head2 normalizedJson($self)

# Verifies signature

=cut

sub verify {
    my ($self, $public_key) = @_;
    my $message = $self->normalizedJson();

    my $encodedSignature = $self->{RECORD_HASH}->{(SimpleLookupService::Keywords::KeyNames::LS_KEY_SIGNATURE)};
    my $signature = decode_base64(@{$encodedSignature}[0]);
    my $key_string = $public_key;

    if ($signature) {
        my $rsa_pub = Crypt::OpenSSL::RSA->new_public_key($key_string);
        $rsa_pub->use_sha256_hash();
        #verify
        if ($rsa_pub->verify($message, $signature)) {
            return 0;
        }
    }
    cluck "Signature could not be verified";
    return -1;
}




