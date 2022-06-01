package perfSONAR_PS::Utils::ISO8601;

use strict;
use warnings;

our $VERSION = 4.1;

=head1 NAME

perfSONAR_PS::Utils::ISO8601

=head1 DESCRIPTION

Utilities for working with ISO8601.

Much of code adapted from https://github.com/perlancar/perl-DateTime-Format-Duration-ISO8601

=head1 API

=cut

use base 'Exporter';
use DateTime::Duration;

our @EXPORT_OK = qw( parse_duration duration_to_seconds );

sub parse_duration_as_deltas {
    my ($duration_string) = @_;

    unless (defined $duration_string) {
        die 'Duration string undefined';
    }

    my $regex = qr{(?x)
        ^
        (?:(?<repeats>R(?<repetitions>[0-9]+)?))?
        P
        (?:(?<years>[0-9]+)Y)?
        (?:(?<months>[0-9]+)M)?
        (?:(?<days>[0-9]+)D)?
        (?:T
            (?:(?<hours>[0-9]+)H)?
            (?:(?<minutes>[0-9]+)M)?
            (?:(?<seconds>[0-9]+(?:\.([0-9]+))?)S)?
        )?
        $
    };

    unless ($duration_string =~ $regex) {
        die sprintf(
            '"%s": not a valid ISO 8601 duration string',
            $duration_string
        );
    }

    my %fields = map  { $_ => $+{ $_ } }
                 grep { defined $+{ $_ } }
                      keys %+;

    return \%fields;
}

sub parse_duration {
    my ($duration_string) = @_;

    my $duration_args = parse_duration_as_deltas($duration_string);

    return unless defined $duration_args;

    if ($duration_args->{ repeats }) {
        die sprintf(
            '"%s": duration repetitions are not supported',
            $duration_string
        );
    }

    # Convert ss.sss floating seconds to seconds and nanoseconds
    if (exists $duration_args->{ seconds }) {
        my ($seconds, $floating) = $duration_args->{ seconds } =~ qr{(?x)
            ([0-9]+)
            (\.[0-9]+)
        };

        if ($floating) {
            my $nanoseconds = $floating * 1_000_000_000;

            $duration_args->{ seconds } = $seconds;
            $duration_args->{ nanoseconds } = $nanoseconds;
        }
    }

    # DateTime::Duration only accepts integer values
    for my $field (keys %{ $duration_args }) {
        $duration_args->{ $field } = int($duration_args->{ $field });
    }

    return DateTime::Duration->new(%{ $duration_args });
}

sub duration_to_seconds {
    my ($duration_string) = @_;
    
    my $dur_obj = parse_duration($duration_string);
    
    if($dur_obj->years() || $dur_obj->months()){
        die "Cannot convert $duration_string to seconds because years and months are ambiguous";
    }
    
    my $total_seconds = int($dur_obj->seconds);
    $total_seconds += int($dur_obj->minutes) * 60;
    $total_seconds += int($dur_obj->hours()) * 3600;
    $total_seconds += int($dur_obj->days()) * 86400;
    $total_seconds += int($dur_obj->weeks()) * 86400 * 7;
    
    return $total_seconds;

}
