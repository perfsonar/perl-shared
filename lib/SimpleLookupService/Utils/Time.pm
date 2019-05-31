package SimpleLookupService::Utils::Time;

use strict;
use warnings;

=head1 NAME

SimpleLookupService::Utils::Time

=head1 DESCRIPTION

A module that provides utility methods for manipulating unix timestamps, iso 8601 timestamps

=head1 API

=cut

use base 'Exporter';
use Carp qw(cluck);

use Params::Validate qw(:all);
use Net::DNS;
use NetAddr::IP;
use Regexp::Common;
use Data::Dumper;
use Socket;
use Socket6 qw(inet_ntop);

our @EXPORT_OK = qw( is_iso iso_to_minutes minutes_to_iso iso_to_unix);

=head2 is_iso($self { $isodate })

Returns true if value is ISO date or duration

=cut

sub is_iso{
    my ($value) = @_;

    ($value =~ m/P\w*T/)?return 1: return 0;
}


=head2 minutes_to_iso($self { $ttl })

Converts minutes to ISO 8601 duration

=cut

sub minutes_to_iso{
    my ($ttl) = @_;

    if(defined $ttl && $ttl eq ''){
        cluck "Empty ttl";
        return undef;
    }

    my $isottl;

    if($ttl =~ m/P\w*T/){
        cluck "Found iso format";
        return undef;
    }
    $isottl = "PT". $ttl ."M";

    return $isottl;
}


=head2 iso_to_minutes($self { $isoduration })

Converts a given ISO 8601 duration to a minutes

=cut

sub iso_to_minutes{
    my ($value) = @_;

    if(!defined $value){
        return undef;
    }
    my @splitDuration = split(/T/, $value);

    my %dHash = (
        "Y" => 525600,
        "M" => 43200,
        "W"  => 10080,
        "D" => 1440);

    my %tHash = (
        "H" => 60,
        "M" => 1,
        "S"  => 0.0167 );

    $splitDuration[0] =~ tr/P//d;

    my $minutes = 0;
    foreach my $key (keys %dHash){
        $splitDuration[0] =~ m/(\d+)$key/;
        $minutes += $dHash{$key}*$1 if $1;
    }

    if(scalar @splitDuration ==2){

        foreach my $key (keys %tHash){
            $splitDuration[1] =~ m/(\d+)$key/;
            $minutes += $tHash{$key}*$1 if $1;
        }
    }

    ($minutes>0)?return int($minutes+0.5):return undef;

}


=head2 iso_to_unix($self { uri, base})

Converts a given ISO 8601 date string to a unix timestamp

=cut
sub iso_to_unix {
    my ($str) = @_;
    my $dt = DateTime::Format::ISO8601->parse_datetime($str);
    return $dt->epoch();
}



1;