package perfSONAR_PS::NPToolkit::DataService::Result;
use fields qw(results)

use strict;
use warnings;
use Params::Validate qw(:all);

sub new {
    my ( $class ) = @_;

    my $self = fields::new( $class );

    $self->{results} = undef;

    return $self;
}

sub results {
    my ($self, $results) = @_;
    if (defined $results) {
        $self->{results} = $results;
    }
    return $self->{results};
}

1;
