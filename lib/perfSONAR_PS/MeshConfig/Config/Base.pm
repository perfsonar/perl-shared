package perfSONAR_PS::MeshConfig::Config::Base;
use strict;
use warnings;

our $VERSION = 3.1;

use Moose;

use FreezeThaw qw(cmpStr);
use Clone qw(clone);

=head1 NAME

perfSONAR_PS::MeshConfig::Config::Base;

=head1 DESCRIPTION

=head1 API

=cut

has 'cache'                => (is => 'rw', isa => 'HashRef');
has 'unknown_attributes'  => (is => 'rw', isa => 'HashRef', default => sub { {} });

sub parse {
    my ($class, $description, $strict) = @_;

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
                if ($array_type =~ /perfSONAR_PS::MeshConfig::Config::/) {
                    $parsed = $array_type->parse($element, $strict);
                    $parsed->parent($object) if ($parsed->can("parent"));
                }
                else {
                    $parsed = $element;
                }

                push @array, $parsed;
            }

            $parsed_value = \@array;
        }
        elsif ($type =~ /perfSONAR_PS::MeshConfig::Config::/) {
            $parsed_value = $type->parse($description->{$variable}, $strict);
            $parsed_value->parent($object) if ($parsed_value->can("parent"));
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

    foreach my $key (keys %$description) {
        next if (UNIVERSAL::can($object, $key));

        if ($strict) {
            die("Unknown attribute: $key");
        }
        else {
            $object->unknown_attributes->{$key} = clone($description->{$key});
        }
    }

    return $object;
}

sub unparse {
    my ($self) = @_;

    my $meta = $self->meta;

    my %description = ();

    for my $attribute ( sort $meta->compute_all_applicable_attributes ) {
        my $variable = $attribute->name;
        my $type     = $attribute->type_constraint;
        my $reader   = $attribute->get_read_method;
        my $value    = $self->$reader;

        next if ($variable eq "parent" or $variable eq "cache" or $variable eq "unknown_attributes");

        next unless (defined $value);

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

        $description{$variable} = $unparsed_value;
    }

    foreach my $attribute (keys %{ $self->unknown_attributes }) {
        $description{$attribute} = $self->unknown_attributes->{$attribute};
    }

    return \%description;
}

sub compare {
    my ($self, $other) = @_;

    unless ($self->can("unparse") and $other->can("unparse")) {
        return 0;
    }

    my $self_hash = $self->unparse;
    my $other_hash = $other->unparse;

    return cmpStr($self_hash, $other_hash);
}

sub has_unknown_attributes {
    my ($self) = @_;

    return (scalar(keys %{ $self->unknown_attributes }) > 0);
}


1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: Base.pm 3658 2009-08-28 11:40:19Z aaron $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2009, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
