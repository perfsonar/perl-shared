package perfSONAR_PS::RegularTesting::Utils::SerializableObject;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use JSON;

use Moose;

my $logger = get_logger(__PACKAGE__);

sub variable_map {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    return {};
}

sub parse {
    my ($class, $description, $strict) = @_;

    my $object = $class->new();

    my $meta = $object->meta;

    # Check if this should be handled by a subclass of the type
    if ($object->can("type")) {
        unless ($description->{type}) {
           die("Need to specify a 'type' for $class");
        }

        foreach my $subclass ($meta->subclasses) {
            next if $subclass eq $class;

            if ($subclass->can("type") and $subclass->type eq $description->{type}) {
                $meta = $subclass;
                $object = $subclass->new();
                last;
            }
        }
    }

    foreach my $attribute ($object->get_class_attrs()) {
        my $variable = $attribute->name;
        my $type     = $attribute->type_constraint;
        my $writer   = $attribute->get_write_method;

        $variable = $object->variable_map->{$variable} if $object->variable_map->{$variable};

        next unless (defined $description->{$variable});

        my $parsed_value = $object->parse_element_attribute({ name => $variable, type => $type, value => $description->{$variable}, strict => $strict });

        $object->$writer($parsed_value) if defined $parsed_value;
    }

    if ($strict) {
        foreach my $variable (keys %$description) {
            foreach my $mapped_name (keys %{ $object->variable_map }) {
                if ($object->variable_map->{$mapped_name} eq $variable) {
                    $variable = $mapped_name;
                    last;
                }
            }

            unless (UNIVERSAL::can($object, $variable)) {
                die("Unknown attribute: $variable");
            }
        }
    }

    return $object;
}

sub parse_element_attribute {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { name => 1, type => 1, value => 1, strict => 0 });
    my $name       = $parameters->{name};
    my $type       = $parameters->{type};
    my $value      = $parameters->{value};
    my $strict     = $parameters->{strict};

    my $parsed_value;

    $type = $type."";

    if (UNIVERSAL::can($type, "parse")) {
        $parsed_value = $type->parse($value, $strict);
    }
    elsif ($type =~ /ArrayRef\[(.*)\]/) {
        $value = [ $value ] unless ref($value) eq "ARRAY";

        my $array_type = $1;

        my @array = ();
        foreach my $element (@$value) {
            my $parsed = $self->parse_element_attribute({ name => $name, type => $array_type, value => $element, strict => $strict });
            push @array, $parsed;
        }

        $parsed_value = \@array;
    }
    elsif (JSON::is_bool($value)) {
        if ($value) {
            $parsed_value = 1;
        }
        else {
            $parsed_value = 0;
        }
    }
    else {
        $parsed_value = $value;
    }

    return $parsed_value;
}

sub unparse {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    my %hash = ();

    foreach my $attribute ($self->get_class_attrs()) {
        my $attr_name = $attribute->name;
        my $type      = $attribute->type_constraint;
        my $reader    = $attribute->get_read_method;
        my $writer    = $attribute->get_write_method;

        next if ($attr_name =~ /^_/);

        if ($attribute->has_default) {
            next if ($attribute->default($self) eq $self->$reader());
        }

        my $value = $self->$attr_name;

        next unless defined $value;

        my $unparsed_value;

        if ($type =~ /ArrayRef\[(.*)\]/) {
            my @array = ();
            foreach my $element (@$value) {
                if (UNIVERSAL::can($element, "unparse")) {
                    push @array, $element->unparse;
                }
                else {
                    push @array, $element;
                }
            }

            $unparsed_value = \@array;
        }
        elsif (UNIVERSAL::can($value, "unparse")) {
            $unparsed_value = $value->unparse;
        }
        else {
            $unparsed_value = $value;
        }

        my $variable_name = $self->variable_map->{$attr_name};

        $variable_name = $attr_name unless $variable_name;

        $hash{$variable_name} = $unparsed_value;
    }

    if ($self->can("type")) {
        $hash{type} = $self->type;
    }

    return \%hash;
}

sub get_class_attrs {
    my ($class) = @_;

    my @ancestors = reverse $class->meta->linearized_isa;

    my %attrs = ();
    foreach my $class (@ancestors) {
        for my $attribute ( map { $class->meta->get_attribute($_) } sort $class->meta->get_attribute_list ) {
            $attrs{$attribute->name} = $attribute;
        }
    }

    return values %attrs;
}


1;
