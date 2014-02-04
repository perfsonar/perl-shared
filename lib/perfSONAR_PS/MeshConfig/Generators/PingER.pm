package perfSONAR_PS::MeshConfig::Generators::PingER;
use strict;
use warnings;

our $VERSION = 3.1;

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4);
use Net::IP;
use XML::LibXML;
use Encode qw(encode);

use utf8;

use perfSONAR_PS::Utils::DNS qw(resolve_address reverse_dns);
use perfSONAR_PS::XML::Document;

use perfSONAR_PS::MeshConfig::Generators::Base;

use Moose;

extends 'perfSONAR_PS::MeshConfig::Generators::Base';

has 'pinger_landmarks'       => (is => 'rw', isa => 'perfSONAR_PS::XML::Document');

my %lookup_cache = ();

=head1 NAME

perfSONAR_PS::MeshConfig::Generators::PingER;

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

    my $landmarks;
    eval {
        my $existing_landmarks = XML::LibXML->load_xml(location => $self->config_file);

        $landmarks = $self->__parse_pinger_landmarks({ existing_configuration => $existing_landmarks->documentElement() });
    };
    if ($@) {
        my $msg = "Problem initializing pinger landmarks: ".$@;
        $logger->error($msg);
        return (-1, $msg);
    }

    $self->pinger_landmarks($landmarks);

    return (0, "");
}

sub add_mesh_tests {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { mesh => 1, tests => 1, host => 1 } );
    my $mesh  = $parameters->{mesh};
    my $tests = $parameters->{tests};
    my $host  = $parameters->{host};

    # Verify that there are tests to be run
    my $num_tests = 0;

    foreach my $test (@$tests) {
        unless ($test->parameters->type eq "pinger") {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $num_tests++;
    }

    return unless ($num_tests);

    # Verify that there is an MA for this host.
    my $measurement_archive = $host->lookup_measurement_archive({ type => "pinger", recursive => 0 });
    unless ($measurement_archive) {
        die("No PingER measurement archive for host: ".$host->description.": ".$host->addresses->[0]);
    }

    my %host_addresses = map { $_ => 1 } @{ $host->addresses };

    my %addresses_added = ();

    my $mesh_id = $mesh->description;
    $mesh_id =~ s/[^A-Za-z0-9_-]/_/g;

    my $i = 0;
    foreach my $test (@$tests) {
        unless ($test->parameters->type eq "pinger") {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $logger->debug("Adding: ".$test->description);

        eval {
            my $domain_id = "urn:ogf:network:domain=mesh_agent_".$mesh_id."-".$i;

            my %hosts = ();

            foreach my $pair (@{ $test->members->source_destination_pairs }) {
                next unless ($host_addresses{$pair->{source}->{address}});

                my $matching_hosts = $mesh->lookup_hosts({ addresses => [ $pair->{destination}->{address} ] });
                unless ($matching_hosts->[0]) {
                    die("No known 'host' element with address: ".$pair->{destination}->{address});
                }

                my $host_properties = $matching_hosts->[0];

                my ($hostname, $address) = __lookup_host($pair->{destination}->{address});
                unless ($address and $hostname) {
                    die("Problem looking up address: ".$pair->{destination}->{address});
                }

                $hosts{$address}  = { address => $address, hostname => $hostname };
                $hosts{$hostname} = { address => $address, hostname => $hostname };
            }

            __start_domain($self->pinger_landmarks, $domain_id);
              __add_comment($self->pinger_landmarks, $test->description);
              foreach my $pair (@{ $test->members->source_destination_pairs }) {
                  next unless ($host_addresses{$pair->{source}->{address}});
                  next unless ($host_addresses{$pair->{source}->{address}});

                  my $matching_hosts = $mesh->lookup_hosts({ addresses => [ $pair->{destination}->{address} ] });
                  my $host_properties = $matching_hosts->[0];

                  my $hostname = $hosts{$pair->{destination}->{address}}->{hostname};
                  my $address  = $hosts{$pair->{destination}->{address}}->{address};

                  if ($self->skip_duplicates) {
                      # Check if a specific test (i.e. same
                      # source/destination/test parameters) has been added
                      # before, and if so, don't add it.
                      my $already_added = $self->__add_test_if_not_added({ 
                                                                           source             => $pair->{source}->{address},
                                                                           destination        => $pair->{destination}->{address},
                                                                           packet_size        => $test->parameters->packet_size,
                                                                           count              => $test->parameters->packet_count,
                                                                           packet_interval    => $test->parameters->packet_interval,
                                                                           ttl                => $test->parameters->packet_ttl,
                                                                           measurement_period => $test->parameters->test_interval,
                                                                           measurement_offset => undef,
                                                                       });

                      if ($already_added) {
                          $logger->debug("Test between ".$pair->{source}->{address}." to ".$pair->{destination}->{address}." already exists. Not re-adding");
                          next;
                      }
                  }

                  __create_node($self->pinger_landmarks, {
                                    domain_id          => $domain_id,
                                    hostname           => $hostname,
                                    ip_address         => $address,
                                    description        => $host_properties->description,
                                    packet_size        => $test->parameters->packet_size,
                                    count              => $test->parameters->packet_count,
                                    packet_interval    => $test->parameters->packet_interval,
                                    ttl                => $test->parameters->packet_ttl,
                                    measurement_period => $test->parameters->test_interval,
                                    measurement_offset => undef,
                                });
              }
            __end_domain($self->pinger_landmarks);
        };
        if ($@) {
            die("Problem adding test ".$test->description.": ".$@);
        }
    }

    return;
}

sub get_config {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { });

    __end_topology($self->pinger_landmarks);

    my $landmarks = $self->pinger_landmarks->getValue;
    $landmarks = encode('ascii', $landmarks);
    return $landmarks;
}

sub __parse_pinger_landmarks {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { existing_configuration => 1 });
    my $existing_configuration = $parameters->{existing_configuration};

    my $document = perfSONAR_PS::XML::Document->new();

    __start_topology($document);

    foreach my $domain ($existing_configuration->findnodes("./*[local-name()='domain']")) {
        my $id = $domain->getAttribute("id");

        next if ($id and $id =~ /urn:ogf:network:domain=mesh_agent_/);

        $document->addExistingXMLElement($domain);
    }

    return $document;
}

sub __lookup_host {
    my ($address) = @_;

    my ($new_hostname, $new_address);

    if ($lookup_cache{$address}) {
        $new_hostname = $lookup_cache{$address}->{hostname};
        $new_address  = $lookup_cache{$address}->{address};
    }
    else {
        if ( is_ipv4( $address ) or 
             &Net::IP::ip_is_ipv6( $address ) ) {

            $new_hostname = reverse_dns($address);
            $new_address  = $address;
        }
        elsif ( is_hostname( $address ) ) {
            my @addresses = resolve_address($address);

            $new_hostname = $address;
            $new_address  = $addresses[0];
        }
        else {
            die("Unknown address type: ".$address);
        }

        $lookup_cache{$address} = {
            hostname => $new_hostname,
            address  => $new_address,
        };
    }

    return ($new_hostname, $new_address);
}

sub __start_topology {
    my ($document) = @_;
    $document->startElement({
        prefix => "pingertopo",
        tag => "topology",
        namespace => "http://ogf.org/ns/nmwg/tools/pinger/landmarks/1.0/",
        extra_namespaces => {
            nmwg  => "http://ggf.org/ns/nmwg/base/2.0/",
            nmtl3 => "http://ogf.org/schema/network/topology/l3/20070707",
            nmtb  => "http://ogf.org/schema/network/topology/base/20070707/"
        },
    });
}

sub __end_topology {
    my ($document) = @_;

    $document->endElement("topology");
}

sub __add_comment {
    my ($document, $comment) = @_;
    $document->createElement({
        prefix => "nmtb",
        tag => "comments",
        namespace => "http://ogf.org/schema/network/topology/base/20070707/",
        content => $comment,
    });
}

sub __start_parameters {
    my ($document, @args) = @_;
    my $parameters = validate( @args, { });

    $document->startElement({
        prefix => "nmwg",
        tag => "parameters",
        namespace => "http://ggf.org/ns/nmwg/base/2.0/",
    });
}

sub __end_parameters {
    my ($document, @args) = @_;
    my $parameters = validate( @args, { });
    my $name       = $parameters->{name};
    my $value      = $parameters->{value};

    $document->endElement("parameters");
}

sub __create_parameter {
    my ($document, @args) = @_;
    my $parameters = validate( @args, { name => 1, value => 1, });
    my $name       = $parameters->{name};
    my $value      = $parameters->{value};

    $document->createElement({
        prefix => "nmwg",
        tag => "parameter",
        namespace => "http://ggf.org/ns/nmwg/base/2.0/",
        attributes => { name => $name },
        content => $value,
    });
}

sub __create_node {
    my ($document, @args) = @_;
    my $parameters = validate( @args, {
                                        domain_id => 1,
                                        hostname => 1,
                                        ip_address => 1,
                                        description => 1,
                                        packet_size => 1,
                                        count => 1,
                                        packet_interval => 1,
                                        ttl => 1,
                                        measurement_period => 1,
                                        measurement_offset => 1
                                      });
    my $domain_id = $parameters->{domain_id};
    my $hostname = $parameters->{hostname};
    my $ip_address = $parameters->{ip_address};
    my $description = $parameters->{description};
    my $packet_size = $parameters->{packet_size};
    my $count = $parameters->{count};
    my $packet_interval = $parameters->{packet_interval};
    my $ttl = $parameters->{ttl};
    my $measurement_period = $parameters->{measurement_period};
    my $measurement_offset = $parameters->{measurement_offset};

    my $node_id = $domain_id.":node=".$hostname;

    $document->startElement({
        prefix => "pingertopo",
        tag => "node",
        namespace => "http://ogf.org/ns/nmwg/tools/pinger/landmarks/1.0/",
        attributes => { id => $node_id },
    });
        $document->createElement({
            prefix => "nmtb",
            tag => "description",
            namespace => "http://ogf.org/schema/network/topology/base/20070707/",
            content => $description,
        });


        $document->createElement({
            prefix => "nmtb",
            tag => "hostName",
            namespace => "http://ogf.org/schema/network/topology/base/20070707/",
            content => $hostname,
        });

    __start_parameters($document);
      __create_parameter($document, { name => "packetSize", value => $packet_size });
      __create_parameter($document, { name => "count", value => $count });
      __create_parameter($document, { name => "packetInterval", value => $packet_interval });
      __create_parameter($document, { name => "ttl", value => $ttl });
      __create_parameter($document, { name => "measurementPeriod", value => $measurement_period });
      __create_parameter($document, { name => "measurementOffset", value => $measurement_offset });
    __end_parameters($document);

    __create_port($document, { id => $node_id.":port=$ip_address", address => $ip_address });

    $document->endElement("node");
}

sub __create_port {
    my ($document, @args) = @_;
    my $parameters = validate( @args, { id => 1, address => 1 });
    my $id         = $parameters->{id};
    my $address    = $parameters->{address};

    my $type;

    if ( is_ipv4( $address ) ) {
        $type = "IPv4";
    }
    elsif ( &Net::IP::ip_is_ipv6( $address ) ) {
        $type = "IPv6";
    }
    else {
        die("Unknown address type, not IPv4 or IPv6: ".$address);
    }

    $document->startElement({
        prefix => "nmtl3",
        tag => "port",
        namespace => "http://ogf.org/schema/network/topology/l3/20070707",
        attributes => { id => $id },
    });

    $document->createElement({
        prefix => "nmtl3",
        tag => "ipAddress",
        namespace => "http://ogf.org/schema/network/topology/l3/20070707",
        attributes => { type => $type },
        content => $address
    });


    $document->endElement("port");
}


sub __start_domain {
    my ($document, $id) = @_;
    $document->startElement({
        prefix => "pingertopo",
        tag => "domain",
        namespace => "http://ogf.org/ns/nmwg/tools/pinger/landmarks/1.0/",
        attributes => { id => $id },
    });
}

sub __end_domain {
    my ($document) = @_;

    $document->endElement("domain");
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
