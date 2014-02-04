package perfSONAR_PS::MeshConfig::Config::ExpectedTestResults;
use strict;
use warnings;

our $VERSION = 3.1;

use Moose;

use perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::PerfSONARBUOYOwamp;
use perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::PerfSONARBUOYBwctl;
#use perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::Traceroute;
#use perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::PingER;

=head1 NAME

perfSONAR_PS::MeshConfig::Config::ExpectedTestResults;

=head1 DESCRIPTION

=head1 API

=cut

extends 'perfSONAR_PS::MeshConfig::Config::Base';

has 'type'                => (is => 'rw', isa => 'Str');

override 'parse' => sub {
    my ($class, $description, $strict) = @_;

    if ($class eq __PACKAGE__) {
        unless ($description->{type}) {
            die("Unspecified expected test results type");
        }

        if ($description->{type} eq "perfsonarbuoy/owamp") {
            return perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::PerfSONARBUOYOwamp->parse($description, $strict);
        }
        elsif ($description->{type} eq "perfsonarbuoy/bwctl") {
            return perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::PerfSONARBUOYBwctl->parse($description, $strict);
        }
#        elsif ($description->{type} eq "traceroute") {
#            return perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::Traceroute->parse($description, $strict);
#        }
#        elsif ($description->{type} eq "pinger") {
#            return perfSONAR_PS::MeshConfig::Config::ExpectedTestResults::PingER->parse($description, $strict);
#        }
        else {
            die("Unknown expected test results type: ".$description->{type});
        }
    }
    else {
        return super($class, $description, $strict);
    }
};

sub merge {
    my ($self, $other) = @_;

    if (ref($self) ne ref($other)) {
        die("Trying to merge ".ref($self)." with ".ref($other));
    }

    my $new = ref($self)->new();

    foreach my $object ($self, $other) {
        my $meta = $object->meta;

        for my $attribute ( sort $meta->compute_all_applicable_attributes ) {
            my $variable    = $attribute->name;
            my $reader      = $attribute->get_read_method;
            my $writer      = $attribute->get_write_method;
            my $value       = $new->$reader;
            my $other_value = $object->$reader;

            next if defined $value;
    
            next unless defined $other_value;

            $new->$writer($other_value); 
        }
    }

    return $new;
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

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
