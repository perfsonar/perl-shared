package perfSONAR_PS::RegularTesting::Results::Base;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use DateTime::Format::ISO8601;

use Moose;

my $logger = get_logger(__PACKAGE__);

sub type {
    die("'type' needs to be overridden");
}

sub parse {
    my ($class, $description, $strict) = @_;

    if ($class eq __PACKAGE__) {
        my $type = $description->{type};

        unless ($type) {
            die("No type information available. Can't parse results");
        }

        # i.e. pick the class that matches the type
        my $matching_subclass;
        foreach my $subclass ($class->meta->subclasses) {
            eval {
                if ($subclass->type eq $type) {
                    $matching_subclass = $subclass;
                }
            };
        }

        unless ($matching_subclass) {
            die("Unknown result type: $type");
        }

        return $matching_subclass->parse($description, $strict);
    }

    my $object = $class->new();

    my $meta = $object->meta;

    for my $attribute ( map { $meta->get_attribute($_) } sort $meta->get_attribute_list ) {
        my $variable = $attribute->name;
        my $type     = $attribute->type_constraint;
        my $writer   = $attribute->get_write_method;

        next unless (defined $description->{$variable});

        my $parsed_value;

        $type = $type.""; # convert to string

        if ($type =~ /ArrayRef\[(.*)\]/) {
            my $array_type = $1;

            my @array = ();
            foreach my $element (@{ $description->{$variable} }) {
                my $parsed;
                if ($array_type->can("parse")) {
                    $parsed = $array_type->parse($element, $strict);
                }
                else {
                    $parsed = $element;
                }

                push @array, $parsed;
            }

            $parsed_value = \@array;
        }
        elsif ($type->can("parse")) {
            $parsed_value = $type->parse($description->{$variable}, $strict);
        }
        elsif ($type eq "DateTime") {
            $parsed_value = DateTime::Format::ISO8601->parse_datetime($description->{$variable});
        }
        elsif (JSON::is_bool($description->{$variable})) {
            if ($description->{$variable}) {
                $parsed_value = 1;
            }
            else {
                $parsed_value = 0;
            }
        }
        else {
            $parsed_value = $description->{$variable};
        }

        $object->$writer($parsed_value) if defined $parsed_value;
    }

    if ($strict) {
        foreach my $key (keys %$description) {
            unless (UNIVERSAL::can($object, $key)) {
                die("Unknown attribute: $key");
            }
        }
    }

    return $object;
}

sub unparse {
    my ($self) = @_;

    my $description = $self->__unparse;

    $description->{'type'} = $self->type;

    return $description;
}

sub __unparse {
    my ($self) = @_;

    my $meta = $self->meta;

    my %description = ();

    for my $attribute ( sort $meta->compute_all_applicable_attributes ) {
        my $variable = $attribute->name;
        my $type     = $attribute->type_constraint;
        my $reader   = $attribute->get_read_method;
        my $value    = $self->$reader;

        next unless (defined $value);

        my $unparsed_value = $self->__unparse_attribute({ attribute => $variable, type => $type, value => $value });

        $description{$variable} = $unparsed_value;
    }

    return \%description;
}

sub __unparse_attribute {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { attribute => 1, type => 1, value => 1 } );
    my $attribute = $parameters->{attribute};
    my $type      = $parameters->{type};
    my $value     = $parameters->{value};

    my $unparsed_value;

    if ($type =~ /ArrayRef\[(.*)\]/) {
        my @array = ();
        foreach my $element (@$value) {
            if (UNIVERSAL::can($element, "__unparse")) {
                push @array, $element->__unparse;
            }
            else {
                push @array, $element;
            }
        }

        $unparsed_value = \@array;
    }
    elsif (UNIVERSAL::can($value, "__unparse")) {
        $unparsed_value = $value->__unparse;
    }
    elsif (UNIVERSAL::can($value, "iso8601")) {
        $unparsed_value = $value->iso8601();
    }
    else {
        $unparsed_value = $value;
    }

    return $unparsed_value;
}

1;
