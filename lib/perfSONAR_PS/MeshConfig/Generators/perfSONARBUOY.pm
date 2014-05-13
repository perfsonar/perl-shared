package perfSONAR_PS::MeshConfig::Generators::perfSONARBUOY;
use strict;
use warnings;

our $VERSION = 3.1;

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);
use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4);
use Net::IP;
use File::Basename;
use Encode qw(encode);

use OWP::Conf;
use perfSONAR_PS::Utils::DNS qw(resolve_address reverse_dns);
use perfSONAR_PS::XML::Document;

use Moose;

extends 'perfSONAR_PS::MeshConfig::Generators::Base';

has 'owmesh_conf'            => (is => 'rw', isa => 'HashRef');

=head1 NAME

perfSONAR_PS::MeshConfig::Generators::perfSONARBUOY;

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

    my $owmesh_conf;
    eval {
        my $owmesh_conf_directory = dirname($self->config_file);

        # Read in the existing configuration
        my %defaults = ( CONFDIR => $owmesh_conf_directory );
        my $conf = OWP::Conf->new( %defaults );

        $owmesh_conf = $self->__parse_owmesh_conf({ owmesh_conf => $conf });
    };
    if ($@) {
        my $msg = "Problem initializing owmesh.conf: ".$@;
        $logger->error($msg);
        return (-1, $msg);
    }

    $self->owmesh_conf($owmesh_conf);

    return (0, "");
}

sub add_mesh_tests {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { mesh => 1, tests => 1, host => 1 } );
    my $mesh                   = $parameters->{mesh};
    my $tests                  = $parameters->{tests};
    my $host                   = $parameters->{host};

    $self->__validate_perfsonarbuoy_configuration({
                                             mesh => $mesh,
                                             tests => $tests,
                                             host => $host, 
                                             variable_prefix => "BW",
                                             test_type => "perfsonarbuoy/bwctl",
                                           });

    $self->__validate_perfsonarbuoy_configuration({
                                             mesh => $mesh,
                                             tests => $tests,
                                             host => $host, 
                                             variable_prefix => "OWP",
                                             test_type       => "perfsonarbuoy/owamp",
                                           });

    $self->__validate_perfsonarbuoy_configuration({
                                             mesh => $mesh,
                                             tests => $tests,
                                             host => $host, 
                                             variable_prefix => "TRACE",
                                             test_type       => "traceroute",
                                           });

    $self->__owmesh_conf_generic_add_mesh_tests({
                                             mesh => $mesh,
                                             tests => $tests,
                                             host => $host, 
                                             variable_prefix => "BW",
                                             test_type       => "perfsonarbuoy/bwctl",
                                           });

    $self->__owmesh_conf_generic_add_mesh_tests({
                                             mesh => $mesh,
                                             tests => $tests,
                                             host => $host, 
                                             variable_prefix        => "OWP",
                                             test_type              => "perfsonarbuoy/owamp",
                                           });

    $self->__owmesh_conf_generic_add_mesh_tests({
                                             mesh => $mesh,
                                             tests => $tests,
                                             host => $host, 
                                             variable_prefix        => "TRACE",
                                             test_type              => "traceroute",
                                           });

    my $local = __get_node(owmesh_config => $self->owmesh_conf, mesh => $mesh, host => $host, no_agent => undef);

    push @{ $self->owmesh_conf->{LOCALNODES} }, $local->{ID};

    return;
}

sub get_config {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { } );

    # Restore the existing CentralHosts in case these meshes didn't configure
    # one (i.e. there were no traceroute tests).
    foreach my $variable_prefix ("", "BW", "OWP", "TRACE") {
        unless ($self->owmesh_conf->{$variable_prefix."CentralHost"}) {
            $self->owmesh_conf->{$variable_prefix."CentralHost"} = $self->owmesh_conf->{$variable_prefix."InitialCentralHost"};
        }
        delete($self->owmesh_conf->{$variable_prefix."InitialCentralHost"});
    }

    # If one LOCALNODE has OWPTESTPORTS set, presumably all of them need it.
    # This is a workaround for the fact that there is (currently) no way for
    # the test ports to be configured in the mesh.
    my $owp_test_ports;
    foreach my $node_name (@{ $self->owmesh_conf->{LOCALNODES} }) {
        my $node = $self->owmesh_conf->{NODE}->{$node_name};

        if ($node->{OWPTESTPORTS}) {
            $owp_test_ports = $node->{OWPTESTPORTS};
            last;
        }
    }

    if ($owp_test_ports) {
        foreach my $node_name (@{ $self->owmesh_conf->{LOCALNODES} }) {
            my $node = $self->owmesh_conf->{NODE}->{$node_name};

            $node->{OWPTESTPORTS} = $owp_test_ports;
        }
    }
   
    my $owmesh_conf = __build_owmesh_conf($self->owmesh_conf);

    $owmesh_conf = encode('ascii', $owmesh_conf);

    return $owmesh_conf;
}

sub __parse_owmesh_conf {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { owmesh_conf => 1 } );
    my $owmesh_conf = $parameters->{owmesh_conf};

    my %owmesh_config = ();

    my @variables = (
           "ConfigVersion", "SyslogFacility", "GroupName", "UserName", "DevNull", # Generic variables applicable to everything
           "CentralDBName", "CentralDBPass", "CentralDBType", "CentralDBUser",  # We don't autogenerate a collector configuration so copy all those variables over
           "SessionSumCmd", "CentralDataDir", "CentralArchDir", # We don't autogenerate a collector configuration so copy all those variables over
           "CentralHostTimeout", "SendTimeout", # Copy this over since we don't have a better use for it.
           "CentralHost", # Copy the CentralHost so that we can use it later if needed (i.e. if there are tests configured, but not via these meshes)
           "SecretName", # Copy the SecretName for now, but we need to figure out how to impart this in the future
           "DataDir", "SessionSuffix", "SummarySuffix", "BinDir", "Cmd", # Used by the master, but generic, or specific to the host it's running on.
           "TestPorts", # Only OWP Test Ports is supported currently...
    );

    foreach my $variable_prefix ("", "BW", "OWP", "TRACE") {
        foreach my $variable (@variables) {
            $logger->debug("Checking ".$variable_prefix.$variable);

            my $value = $owmesh_conf->get_val(ATTR => $variable, TYPE => $variable_prefix);

            $logger->debug($variable." is defined: ".$value) if defined $value;

            if ($variable_prefix ne "") {
                my $higher_value = $owmesh_conf->get_val(ATTR => $variable);

                if ($higher_value and $value eq $higher_value) {
                    $logger->debug("Existing higher value $higher_value for $variable is the same");
                    next;
                }
            }

            # Pull the existing owmesh configuration
            $owmesh_config{$variable_prefix.$variable} = $value if defined $value;

            # SecretName is a special case...
            if ($variable_prefix.$variable eq "SecretName" and $value) {
                push @variables, $value;
            }
        }

        # Backup the initial CentralHost so we can reuse them if the mesh doesn't
        # configure any tests. This is to handle the case where tests are
        # configured, but not through the mesh.
        $owmesh_config{$variable_prefix."InitialCentralHost"} = $owmesh_config{$variable_prefix."CentralHost"};
        delete($owmesh_config{$variable_prefix."CentralHost"});
    }

    # Add variables used by the __owmesh_conf_generic_add_mesh_tests
    # function.
    my ($status, $res) = __parse_owmesh_conf_structures(conf => $owmesh_conf);

    $owmesh_config{MEASUREMENTSET} = $res->{measurement_sets};
    $owmesh_config{NODE}           = $res->{nodes};
    $owmesh_config{GROUP}          = $res->{groups};
    $owmesh_config{TESTSPEC}       = $res->{testspecs};
    $owmesh_config{ADDRTYPES}      = $res->{addrtypes};
    $owmesh_config{LOCALNODES}     = $res->{localnodes};

    return \%owmesh_config;
}

sub __build_owmesh_conf {
    my ($owmesh_desc) = @_;

    my $text = "";

    foreach my $key (sort keys %$owmesh_desc) {
        if (ref($owmesh_desc->{$key}) eq "ARRAY") {
            $text .= $key."\t";
            $text .= "[[ ".join("  ", @{ $owmesh_desc->{$key} })." ]]";
        }
        elsif (ref($owmesh_desc->{$key}) eq "HASH") {
            foreach my $subkey (sort keys %{ $owmesh_desc->{$key} }) {
                $text .= "<$key=$subkey>\n";
                $text .= __build_owmesh_conf($owmesh_desc->{$key}->{$subkey});
                $text .= "</$key>\n";
            }
        }
        else {
            if (defined $owmesh_desc->{$key}) {
                $text .= $key."\t".$owmesh_desc->{$key};
            }
            else {
                $text .= "!".$key;
            }
        }

        $text .= "\n";
    }

    return $text;
}

sub __validate_perfsonarbuoy_configuration {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { mesh => 1, tests => 1, host => 1, variable_prefix => 1, test_type => 1 } );
    my $mesh                   = $parameters->{mesh};
    my $tests                  = $parameters->{tests};
    my $host                   = $parameters->{host};
    my $variable_prefix        = $parameters->{variable_prefix};
    my $test_type              = $parameters->{test_type};

    # Verify that there are tests to be run
    my $num_tests = 0;

    foreach my $test (@$tests) {
        unless ($test->parameters->type eq $test_type) {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $num_tests++;
    }

    unless ($num_tests) {
        $logger->debug("No tests defined of type: ".$test_type);
        return;
    }

    # Verify that there is a measurement archive
    my $ma = $host->lookup_measurement_archive({ type => $test_type, recursive => 1 });
    unless ($ma) {
        my $msg = "No measurement archive defined for tests of type $test_type";
        $logger->error($msg);
        die($msg);
    }

    unless ($ma->write_url) {
        my $msg = "No write_url defined for MA of type $test_type";
        $logger->error($msg);
        die($msg);
    }

    if ($self->owmesh_conf->{$variable_prefix."CentralHost"} and
        $self->owmesh_conf->{$variable_prefix."CentralHost"} ne $ma->write_url) {
        my $msg = "Existing MA for this host that differs from ".$ma->write_url;
        $logger->error($msg);
        die($msg);
    }

    # Validate the test parameters before we start modifying the configuration.
    foreach my $test (@$tests) {
        unless ($test->parameters->type eq $test_type) {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        # Handle the special-cases for each test type
        if ($test->parameters->type eq "perfsonarbuoy/bwctl") {
             if ($test->parameters->protocol) {
                 unless ($test->parameters->protocol eq "udp" or
                         $test->parameters->protocol eq "tcp") {
                     die("Unknown test protocol: ".$test->parameters->protocol);
                 }
             }
    
             unless ($test->parameters->tool eq "bwctl/iperf") {
                 die("Only supported tool type is 'bwctl/iperf'");
             }
        }
        elsif ($test->parameters->type eq "traceroute") {
             unless ($test->parameters->protocol eq "udp" or
                     $test->parameters->protocol eq "icmp") {
                 die("Unknown test protocol: ".$test->parameters->protocol);
             }
        }
    }

    return;
}

sub __owmesh_conf_generic_add_mesh_tests {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { mesh => 1, tests => 1, host => 1, variable_prefix => 1, test_type => 1 } );
    my $mesh                   = $parameters->{mesh};
    my $tests                  = $parameters->{tests};
    my $host                   = $parameters->{host};
    my $variable_prefix        = $parameters->{variable_prefix};
    my $test_type              = $parameters->{test_type};

    # Verify that there are tests to be run
    my $num_tests = 0;

    foreach my $test (@$tests) {
        unless ($test->parameters->type eq $test_type) {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $num_tests++;
    }

    unless ($num_tests) {
        $logger->debug("No tests defined of type: ".$test_type);
        return;
    }

    my $ma = $host->lookup_measurement_archive({ type => $test_type, recursive => 1 });
    unless ($ma) {
        my $msg = "No measurement archive defined for tests of type $test_type";
        $logger->error($msg);
        die($msg);
    }

    $self->owmesh_conf->{$variable_prefix."CentralHost"} = $ma->write_url;

    # Add each test type as a new test_spec/group
    my %host_addresses = map { $_ => 1 } @{ $host->addresses };

    my $i = 0;
    foreach my $test (@$tests) {
        unless ($test->parameters->type eq $test_type) {
            $logger->debug("Skipping: ".$test->parameters->type);
            next;
        }

        if ($test->disabled) {
            $logger->debug("Skipping disabled test: ".$test->description);
            next;
        }

        $logger->debug("Adding: ".$test->description);

        my $base_id = $mesh->description."_".$variable_prefix;

        my $test_id;
        my $i = 1;
        do {
            $test_id = $base_id;
            $test_id .= "-".$i unless ($i == 1);
            $test_id = __build_id(id => $test_id);
            $i++;
        }
        while(exists $self->owmesh_conf->{TESTSPEC}->{$test_id});

        my $test_spec = __build_test_spec({ variable_prefix => $variable_prefix, test => $test });

        $self->owmesh_conf->{TESTSPEC}->{$test_id} = $test_spec;

        push @{ $self->owmesh_conf->{"ADDRTYPES"} }, $test_id;

        my @pairs = @{ $test->members->source_destination_pairs };

        # Find the 'center' nodes for the star we'll generate.
        my %centers = ();
        foreach my $pair (@pairs) {
            my $sender = $pair->{"source"};
            my $receiver = $pair->{"destination"};

            # Skip if we're not a sender or receiver.
            next unless ($host_addresses{$sender->{address}} or $host_addresses{$receiver->{address}});

            # Skip if it's a loopback test.
            next if ($host_addresses{$sender->{address}} and $host_addresses{$receiver->{address}});

            # Skip if we're 'no_agent'
            next if (($host_addresses{$sender->{address}} and $sender->{no_agent}) or
                       ($host_addresses{$receiver->{address}} and $receiver->{no_agent}));

            # Skip duplicate tests
            if ($self->skip_duplicates) {
                my %test_parameters           = %$test_spec;
                $test_parameters{source}      = $sender->{address};
                $test_parameters{destination} = $receiver->{address};

                my $already_added = $self->__add_test_if_not_added(\%test_parameters);

                if ($already_added) {
                    $logger->debug("Test between ".$sender->{address}." to ".$receiver->{address}." already exists. Not re-adding");
                    next;
                }
            }

            if ($host_addresses{$sender->{address}}) {
                # We're the sender. We send in 3 cases:
                #   1) we're traceroute (there is no 'reverse' traceroute test)
                #   2) the far side is no_agent and won't be performing this test.
                #   3) the force_bidirectional flag is set so we perform both send and receive
                $centers{$sender->{address}} = {} unless ($centers{$sender->{address}});
                $centers{$sender->{address}}->{$receiver->{address}} = {} unless ($centers{$sender->{address}}->{$receiver->{address}});

                if ($receiver->{no_agent} or 
                    $test->parameters->type eq "traceroute" or
                    ($test->parameters->can("force_bidirectional") and $test->parameters->force_bidirectional)) {
                    $centers{$sender->{address}}->{$receiver->{address}}->{send_to} = 1;
                }
            }
            else {
                # we're the receiver. receiver always receives. Except traceroute, where we can't.
                if ($test->parameters->type eq "traceroute") {
                    if ($sender->{no_agent}) {
                        $logger->warn("Listed as a receiver for a test, but the far side isn't running an agent.");
                    }
                }
                else {
                    $centers{$receiver->{address}} = {} unless ($centers{$receiver->{address}});
                    $centers{$receiver->{address}}->{$sender->{address}} = {} unless ($centers{$receiver->{address}}->{$sender->{address}});

                    $centers{$receiver->{address}}->{$sender->{address}}->{receive_from} = 1;
                }
            }
        }

        my $j = 0;

        # Go through and create a star that corresponds to the group. (From the
        # perspective of this node, all tests are 'stars').
        foreach my $center (keys %centers) {
            $j++;

            my @members = ();
            my @exclude_senders = ();
            my @exclude_receivers = ();

            # Create the center node
            my $hauptnode = __get_node(owmesh_config => $self->owmesh_conf, mesh => $mesh, host => $host, no_agent => undef);
            $hauptnode->{$test_id."ADDR"} = $center;
            push @members, $hauptnode->{ID};

            my $group_id = $test_id."_".$j;

            foreach my $remote_side (keys %{ $centers{$center} }) {

                # If the mesh validated, there will always be a matching host element
                my $matching_hosts = $mesh->lookup_hosts({ addresses => [ $remote_side ] });

                my $remote_host = $matching_hosts->[0];

                my $remote_node = __get_node(owmesh_config => $self->owmesh_conf, mesh => $mesh, host => $remote_host, no_agent => 1);
                $remote_node->{$test_id."ADDR"} = $remote_side;

                push @members, $remote_node->{ID};
                unless ($centers{$center}->{$remote_side}->{receive_from}) {
                    push @exclude_senders, $remote_node->{ID};
                }

                unless ($centers{$center}->{$remote_side}->{send_to}) {
                    push @exclude_receivers, $remote_node->{ID};
                }
            }

            # Add a group with the source sending to the destination
            $self->owmesh_conf->{GROUP}->{$group_id} = {
                GROUPTYPE       => "STAR",
                HAUPTNODE       => $hauptnode->{ID},
                NODES           => \@members,
                EXCLUDE_SENDERS => \@exclude_senders,
                EXCLUDE_RECEIVERS => \@exclude_receivers,
            };

            # Add a measurement set combining the group and test spec defined
            # above.
            $self->owmesh_conf->{MEASUREMENTSET}->{$group_id} = {
                GROUP        => $group_id,
                ADDRTYPE     => $test_id,
                TESTSPEC     => $test_id,
                DESCRIPTION  => $test->description,
                EXCLUDE_SELF => 1,
                ADDED_BY_MESH => 1
            };
        }
    }

    return;
}

sub __build_id {
    my $parameters = validate( @_, { id => 1 } );
    my $id = $parameters->{id};

    $id = uc($id);
    $id =~ s/[^A-Z0-9_]/_/g;

    return $id;
}

sub __get_node {
    my $parameters = validate( @_, { owmesh_config => 1, mesh => 1, host => 1, no_agent => 1 } );
    my $owmesh_config = $parameters->{owmesh_config};
    my $mesh          = $parameters->{mesh};
    my $host          = $parameters->{host};
    my $no_agent      = $parameters->{no_agent};

    # Generate an id for the node
    my $base_id = $mesh->description . "_" . $host->addresses->[0];
    $base_id = uc($base_id);
    $base_id =~ s/[^A-Z0-9_]/_/g;

    my $node_num = 1;

    my $node;
    do {
        my $node_id = $base_id;
        $node_id .= "-".$node_num unless ($node_num == 1);

        $node = $owmesh_config->{NODE}->{$node_id};
        unless ($node) {
           $node = {
               ID => $node_id,
               LONGNAME => $host->description?$host->description:$host->addresses->[0],
               CONTACTADDR => $host->addresses->[0],
               NOAGENT => $no_agent,
           };

           $owmesh_config->{NODE}->{$node_id} = $node;
        }

        $node_num++;
    } while(($no_agent or $node->{NOAGENT}) and not ($no_agent and $node->{NOAGENT}));

    return $node;
}

sub __build_test_spec {
    my $parameters = validate( @_, { variable_prefix => 1, test => 1 } );
    my $variable_prefix        = $parameters->{variable_prefix};
    my $test                   = $parameters->{test};

    my %parameter_mappings = (
        "perfsonarbuoy/bwctl" => {
            'duration'        => 'TestDuration',
            'interval'        => 'TestInterval',
            'tos_bits'        => 'TosBits',
            'buffer_length'   => 'BufferLength',
            'report_interval' => 'ReportInterval',
            'udp_bandwidth'   => 'UDPBandwidthLimit',
            'window_size'     => 'WindowSize',
            'ipv4_only'       => 'IPv4Only',
            'ipv6_only'       => 'IPv6Only',
            'random_start_percentage' => 'TestIntervalStartAlpha',
        },
        "perfsonarbuoy/owamp" => {
            'bucket_width'    => 'BUCKETWIDTH',
            'packet_interval' => 'INTERVAL',
            'loss_threshold'  => 'LOSSTHRESH',
            'packet_padding'  => 'PACKETPADDING',
            'session_count'   => 'SESSIONCOUNT',
            'sample_count'    => 'SAMPLECOUNT',
            'ipv4_only'       => 'IPV4ONLY',
            'ipv6_only'       => 'IPV6ONLY',
        },
        "traceroute" => {
            'test_interval'   => 'TESTINTERVAL',
            'packet_size'     => 'PACKETSIZE',
            'timeout'         => 'TIMEOUT',
            'waittime'        => 'WAITTIME',
            'first_ttl'       => 'FIRSTTTL',
            'max_ttl'         => 'MAXTTL',
            'pause'           => 'PAUSE',
            'ipv4_only'       => 'IPV4ONLY',
            'ipv6_only'       => 'IPV6ONLY',
        },
    );

    my %test_spec = ();

    foreach my $attr (keys %{ $parameter_mappings{$test->parameters->type} }) {
        my $key = $parameter_mappings{$test->parameters->type}->{$attr};

        $test_spec{$variable_prefix.$key} = $test->parameters->$attr;
    }

    # Set the test_spec description to the test's description since that's what
    # the Toolkit GUI displays as the test description.
    $test_spec{DESCRIPTION} = $test->description;

    # Handle the special-cases for each test type
    if ($test->parameters->type eq "perfsonarbuoy/bwctl") {
         if ($test->parameters->protocol eq "udp") {
             $test_spec{BWUDP} = 1;
         }
         elsif ($test->parameters->protocol eq "tcp") {
             $test_spec{BWTCP} = 1;
         }
         else {
             die("Unknown test protocol: ".$test->parameters->protocol);
         }

         unless ($test->parameters->tool) {
             $logger->debug("Setting tool type to be bwctl/iperf");
             $test_spec{TOOL} = "bwctl/iperf";
         }
         elsif ($test->parameters->tool ne "bwctl/iperf") {
             die("Only supported tool type is 'bwctl/iperf'");
         }
         else {
             $test_spec{TOOL} = $test->parameters->tool;
         }
    }
    elsif ($test->parameters->type eq "perfsonarbuoy/owamp") {
         $test_spec{TOOL} = "powstream";
    }
    elsif ($test->parameters->type eq "traceroute") {
         $test_spec{TOOL} = "traceroute";

         if ($test->parameters->protocol eq "udp") {
             ;
         }
         elsif ($test->parameters->protocol eq "icmp") {
             $test_spec{$variable_prefix."TCP"} = 1;
         }
         else {
             die("Unknown test protocol: ".$test->parameters->protocol);
         }
    }

    return \%test_spec;
}

sub __parse_owmesh_conf_structures {
    my $parameters = validate( @_, { conf => 1, } );
    my $conf = $parameters->{conf};

    my @measurementset_attrs = ('TESTSPEC', 'ADDRTYPE', 'GROUP', 'DESCRIPTION', 'EXCLUDE_SELF', 'ADDED_BY_MESH');
    my @group_attrs = ('GROUPTYPE','NODES','SENDERS','RECEIVERS','INCLUDE_RECEIVERS','EXCLUDE_RECEIVERS','INCLUDE_SENDERS','EXCLUDE_SENDERS','HAUPTNODE');
    my @node_attrs  = ('ADDR', 'LONGNAME', 'OWPTESTPORTS', 'NOAGENT', 'CONTACTADDR');
    my @testspec_attrs  = (
        'TOOL',
        'OWPIPV4ONLY',
        'OWPIPV6ONLY',
        'OWPINTERVAL',
        'OWPLOSSTHRESH',
        'OWPSESSIONCOUNT',
        'OWPSAMPLECOUNT',
        'OWPPACKETPADDING',
        'OWPBUCKETWIDTH',
        'DESCRIPTION',
        'TRACETESTINTERVAL',
        'TRACEPACKETSIZE',
        'TRACETIMEOUT',
        'TRACEWAITTIME',
        'TRACEFIRSTTTL',
        'TRACEMAXTTL',
        'TRACEPAUSE',
        'TRACEICMP',
        'BWTCP',
        'BWUDP',
        'BWTestInterval',
        'BWTestDuration',
        'BWWindowSize',
        'BWReportInterval',
        'BWUDPBandwidthLimit',
        'BWBufferLen',
        'BWTestIntervalStartAlpha',
        'BWIPv4Only',
        'BWIPv6Only',
    );

    my %nodes            = ();
    my %groups           = ();
    my %testspecs        = ();
    my %measurement_sets = ();
    my @addrtypes        = ();
    my @localnodes       = ();

    eval {
        my %addrtypes        = ();

        # Only include the local nodes that were for tests that we didn't add.
        my @measurement_sets = $conf->get_sublist( LIST => 'MEASUREMENTSET' );

        foreach my $measurement_set ( @measurement_sets ) {
            next if ($measurement_sets{$measurement_set});

            $measurement_sets{$measurement_set} = {};

            my $measurement_set_desc = $measurement_sets{$measurement_set};

            foreach my $attr (@measurementset_attrs) {
                __get_ref( $conf, $measurement_set_desc, $attr, { MEASUREMENTSET => $measurement_set });
            }

            if ($measurement_set_desc->{ADDED_BY_MESH}) {
                $logger->debug("Measurement Set '".$measurement_set_desc->{DESCRIPTION}."' was added by the mesh");
                delete($measurement_sets{$measurement_set});
                next;
            }

            my $addrtype = $measurement_set_desc->{ADDRTYPE};

            $addrtypes{$addrtype} = 1;

            my $group    = $measurement_set_desc->{GROUP};

            unless ($groups{$group}) {
                $groups{$group} = {};

                my $group_desc = $groups{$group};

                foreach my $attr (@group_attrs) {
                    __get_ref($conf, $group_desc, $attr, { GROUP => $group });
                }

                foreach my $node ( @{ $group_desc->{NODES} } ) {
                    $nodes{$node} = {} unless $nodes{$node};

                    my $node_desc = $nodes{$node};

                    foreach my $attr (@node_attrs) {
                        __get_ref($conf, $node_desc, $attr, { NODE => $node });
                        __get_ref($conf, $node_desc, $measurement_set_desc->{ADDRTYPE}.$attr, { NODE => $node });
                    }
                }
            }

            my $testspec = $measurement_set_desc->{TESTSPEC};
            unless ($testspecs{$testspec}) {
                $testspecs{$testspec} = {};

                my $testspec_desc = $testspecs{$testspec};

                foreach my $attr (@testspec_attrs) {
                    __get_ref($conf, $testspec_desc, $attr, { TESTSPEC => $testspec });
                }
            }
        }

        # Only include the local nodes that were for tests that we didn't add.
        my @temp_local_nodes = $conf->get_val(  ATTR => 'LOCALNODES'  );
        foreach my $node (@temp_local_nodes) {
            push @localnodes, $node if ($nodes{$node});
        }

        @addrtypes = keys %addrtypes;
    };
    if ( $@ ) {
        return ( -1, $@ );
    }

    return ( 0, { measurement_sets => \%measurement_sets, nodes => \%nodes, groups => \%groups, testspecs => \%testspecs, addrtypes => \@addrtypes, localnodes => \@localnodes });
}

sub __get_ref {
    my ( $conf, $hash, $attr, $params ) = @_;

    my %params = %$params;
    $params{ATTR} = $attr;

    eval {
        my $val = $conf->get_ref( %params );
        $hash->{$attr} = $val if defined ($val);
    };

    return;
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
