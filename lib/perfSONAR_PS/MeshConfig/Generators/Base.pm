package perfSONAR_PS::MeshConfig::Generators::Base;
use strict;
use warnings;

our $VERSION = 3.1;

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use Moose;

has 'config_file'            => (is => 'rw', isa => 'Str');
has 'tests_added'            => (is => 'rw', isa => 'HashRef');
has 'skip_duplicates'        => (is => 'rw', isa => 'Bool');

=head1 NAME

perfSONAR_PS::MeshConfig::Generators::Base;

=head1 DESCRIPTION

=head1 API

=cut

my $logger = get_logger(__PACKAGE__);

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         config_file      => 1,
                                         skip_duplicates  => 1,
                                      });

    my $config_file     = $parameters->{config_file};
    my $skip_duplicates = $parameters->{skip_duplicates};

    $self->config_file($config_file);
    $self->skip_duplicates($skip_duplicates);
    $self->tests_added({});

    return (0, "");
}

sub __add_test_if_not_added {
    my ($self, $parameters) = @_;

    my $key = $self->__build_test_key($parameters);

    my $result = $self->tests_added->{$key};

    $self->tests_added->{$key} = 1;

    return $result;
}

sub __build_test_key {
    my ($self, $parameters) = @_;

    my $key = "";
    foreach my $parameter (sort keys %{ $parameters }) {
        $key .= $parameter;
        $key .= "=";
        $key .= $parameters->{$parameter} if $parameters->{$parameter};
        $key .= "|";
    }

    return $key;
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
