package perfSONAR_PS::Client::PSConfig::Parsers::BaseTemplate;

=head1 NAME

perfSONAR_PS::Client::PSConfig::Parsers::BaseTemplate - A base library for filling in template variables in JSON

=head1 DESCRIPTION

A base library for filling in template variables in JSON

=cut

use Mouse;
use JSON;
use perfSONAR_PS::Utils::JQ qw( jq );

our $VERSION = 4.1;

has 'jq_obj' => (is => 'rw', isa => 'HashRef', default => sub { {} });
has 'replace_quotes' => (is => 'rw', isa => 'Bool', default => sub { 1 });
has 'error' => (is => 'ro', isa => 'Str', writer => '_set_error');

=item expand()

Parse the given perl object replace template variables with appropriate values. Returns copy
of object with expanded values.

=cut

sub expand {
    my ($self, $obj) = @_;
    
    #make sure we have an object, otherwise return what was given
    unless($obj){
        return $obj;
    }
    
    #reset error 
    $self->_set_error("");
    
    #convert to string so we get copy and can do replace
    my $json = to_json($obj);
    
    #handle quotes
    my $quote ="";
    if($self->replace_quotes){
        $quote = '"';
    }
    
    #find the variables used
    my %template_var_map = ();
    while($json =~ /\Q${quote}\E\{%\s+(.+?)\s+%\}\Q${quote}\E/g){
        my $template_var = $1;
        next if($template_var_map{$template_var});
        chomp $template_var;
        my $expanded_val = $self->_expand_var($template_var);
        unless(defined $expanded_val){
            return;
        }
        $template_var_map{$template_var} = $expanded_val;
    }
    
    #do the substutions 
    foreach my $template_var(keys %template_var_map){
        $json =~ s/\Q${quote}\E\{%\s+\Q${template_var}\E\s+%\}\Q${quote}\E/$template_var_map{$template_var}/g;
    }
    
    #convert back to object
    my $expanded_obj;
    eval{$expanded_obj = from_json($json)};
    if($@){
        $self->_set_error("Unable to create valid JSON after expanding template");
        return;
    }
    
    return $expanded_obj;
    
}

sub _expand_var {
    ##
    # There is probably a more generic way to do this, but starting here
    my ($self, $template_var) = @_;
    die("Override _expand_var");
}

sub _parse_jq {
    my ($self, $jq) = @_;
    
    #in conversions to and from json in expand(), quotes get escaped, so revert that here
    $jq =~ s/\\"/"/g;
    
    my $result;
    eval{
        my $jq_result = jq($jq, $self->jq_obj());
        $result = to_json($jq_result, {"allow_nonref" => 1, 'utf8' => 1});
    };
    if($@){
        $self->_set_error("Error handling jq template variable: " . $@);
        return;
    }
    
    return $result;
}


__PACKAGE__->meta->make_immutable;

1;

