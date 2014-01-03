package perfSONAR_PS::MeshConfig::Generators::TracerouteMaster;
use strict;
use warnings;

our $VERSION = 3.1;

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use Moose;

extends 'perfSONAR_PS::MeshConfig::Generators::Base';

has 'traceroute_master_conf' => (is => 'rw', isa => 'HashRef');

=head1 NAME

perfSONAR_PS::MeshConfig::Generators::TracerouteMaster;

=head1 DESCRIPTION

=head1 API

=cut

my $logger = get_logger(__PACKAGE__);

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         config_file     => 1,
                                         skip_duplicates => 1,
                                      });

    my $config_file     = $parameters->{config_file};
    my $skip_duplicates = $parameters->{skip_duplicates};

    $self->SUPER::init({ config_file => $config_file, skip_duplicates => $skip_duplicates });

    my $traceroute_master_conf;
    eval {
        my %conf = Config::General->new($self->config_file)->getall;

        $traceroute_master_conf = $self->__parse_traceroute_master_conf({ traceroute_master_conf => \%conf });
    };
    if ($@) {
        my $msg = "Problem reading existing traceroute-master.conf: ".$@;
        $logger->error($msg);
        return (-1, $msg);
    }

    $self->traceroute_master_conf($traceroute_master_conf);

    return (0, "");
}

sub get_config {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { } );

    # Restore the existing collector urls in case these meshes didn't configure
    # one (i.e. there were no traceroute tests).
    unless ($self->traceroute_master_conf->{collector_urls}) {
        $self->traceroute_master_conf->{collector_urls} = $self->traceroute_master_conf->{initial_collector_urls};
    }

    delete($self->traceroute_master_conf->{initial_collector_urls});

    return __build_traceroute_master_conf($self->traceroute_master_conf);
}

sub add_mesh_tests {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { mesh => 1, tests => 1, host => 1 } );
    my $mesh                   = $parameters->{mesh};
    my $tests                  = $parameters->{tests};
    my $host                   = $parameters->{host};

    # Verify that there are tests to be run
    my $num_tests = 0;

    foreach my $test (@$tests) {
        unless ($test->parameters->type eq "traceroute") {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $num_tests++;
    }

    # Only update the configuration if there are tests to run.
    if ($num_tests) {
        # Verify that there is a measurement archive
        my $ma = $host->lookup_measurement_archive({ type => "traceroute", recursive => 1 });
        unless ($ma) {
            my $msg = "No measurement archive defined for tests of type traceroute";
            $logger->error($msg);
            die($msg);
        }

        if ($self->traceroute_master_conf->{collector_urls} and
            $self->traceroute_master_conf->{collector_urls} ne $ma->write_url) {
            my $msg = "Different MA for traceroute collector already exists";
            $logger->error($msg);
            die($msg);
        }

        $logger->debug("Setting traceroute MA url to: ".$ma->write_url);

        $self->traceroute_master_conf->{collector_urls} = $ma->write_url;
    }

    return;
}

sub __parse_traceroute_master_conf {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { traceroute_master_conf => 1 } );
    my $traceroute_master_conf = $parameters->{traceroute_master_conf};

    # Backup the initial collector_urls so we can reuse it if the mesh doesn't
    # configure any tests. This is to handle the case where traceroute tests
    # are configured, but not through the mesh.
    $traceroute_master_conf->{initial_collector_urls} = $traceroute_master_conf->{collector_urls};
    delete($traceroute_master_conf->{collector_urls});

    return $traceroute_master_conf;
}

sub __build_traceroute_master_conf {
    my ($conf_desc) = @_;

    my $text = "";
    foreach my $key (sort keys %$conf_desc) {
        if (ref($conf_desc->{$key}) eq "ARRAY") {
            foreach my $elm (@{ $conf_desc->{$key} }) {
                $text .= $key."\t".$elm."\n";
            }
        }
        else {
            $text .= $key."\t".$conf_desc->{$key}."\n";
        }
    }

    return $text;
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
