package perfSONAR_PS::Graphs::Functions;

use strict;
use warnings;

use Data::Dumper;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(select_summary_window combine_data);  # symbols to export on request

=head1 NAME

perfSONAR_PS::Graphs::Functions

=head1 DESCRIPTION

Module for performing data functions for the Graphs.

=cut

=head2 select_summary_window ({})
Selects summary window based on event type, desired window, and available windows (from esmond metadata)
=cut
sub select_summary_window {
    my $event_type = shift;
    my $summary_type = shift;
    my $window = shift;
    my $event = shift;

#warn "event type: $event_type; summary_type: $summary_type; window: $window; event: " . Dumper $event;

    my $ret_window = -1;
    my $next_smallest_window = -1;
    my $next_largest_window = -1;
    my $summaries = $event->{data}->{summaries};
    my $exact_match = 0;
    foreach my $summary (@$summaries) {
        if ($summary->{'summary-type'} eq $summary_type && $summary->{'summary-window'} == $window) {
            $ret_window = $window;
            $exact_match = 1;
            last;
        } elsif ($summary->{'summary-window'} < $window && $summary->{'summary-window'} > $next_smallest_window) {
            $next_smallest_window = $summary->{'summary-window'};
        } elsif ($next_largest_window == -1 || ($summary->{'summary-window'} > $window && $summary->{'summary-window'} < $next_largest_window)) {
           $next_largest_window = $summary->{'summary-window'};
        }
    }
    # if the requested window is 0 (base data) and we don't have a match,
    # this means we need to return -1 so the calling code can use base data instead
    if ($window == 0 && !$exact_match) {
        $ret_window = -1;
    } else {
        # if there's no exact match, accept the closest lower value
        $ret_window = $next_smallest_window if ($ret_window == -1 && !$exact_match);
        # if there's no lower value, take the closest larger value
        $ret_window = $next_largest_window if ($ret_window == -1 && !$exact_match);
    }
#warn "ret_window: $ret_window";
    return $ret_window;

}


=head2 combine_data ({})
Combines two hashes
=cut
sub combine_data {
    my $data1 = shift;
    my $data2 = shift;
    my $combined = {};

    while (my ($key, $val) = each %$data1) {
        $combined->{$key} = $val;
    }

    while (my ($key, $val) = each %$data2) {
        if(defined($val)) {
            $combined->{$key} = $val;
        }
    }
    return $combined;
}



1;
