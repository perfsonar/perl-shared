package perfSONAR_PS::MeshConfig::Agent;

use strict;
use warnings;

our $VERSION = 3.1;

use Config::General;
use File::Basename;
use Log::Log4perl qw(get_logger);
use MIME::Lite;
use Params::Validate qw(:all);
use URI::Split qw(uri_split);
use FreezeThaw qw(freeze thaw);

use perfSONAR_PS::Utils::Host qw(get_ips);
use perfSONAR_PS::Utils::DNS qw(resolve_address reverse_dns);
use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw(restart_service save_file);

use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4);
use Net::IP;

use perfSONAR_PS::MeshConfig::Utils qw(load_mesh);

use perfSONAR_PS::MeshConfig::Config::Mesh;
use perfSONAR_PS::MeshConfig::Generators::PingER;
use perfSONAR_PS::MeshConfig::Generators::perfSONARBUOY;
use perfSONAR_PS::MeshConfig::Generators::TracerouteMaster;

use Module::Load;

use Moose;

has 'use_toolkit'            => (is => 'rw', isa => 'Bool');
has 'restart_services'       => (is => 'rw', isa => 'Bool');

has 'meshes'                 => (is => 'rw', isa => 'ArrayRef[HashRef]');

has 'traceroute_master_conf' => (is => 'rw', isa => 'Str');
has 'owmesh_conf'            => (is => 'rw', isa => 'Str');
has 'pinger_landmarks'       => (is => 'rw', isa => 'Str');

has 'addresses'              => (is => 'rw', isa => 'ArrayRef[Str]');

has 'send_error_emails'         => (is => 'rw', isa => 'Bool', default => 1);

has 'from_address'           => (is => 'rw', isa => 'Str');
has 'administrator_emails'   => (is => 'rw', isa => 'ArrayRef[Str]');

has 'skip_redundant_tests'   => (is => 'rw', isa => 'Bool', default=>0);

has 'errors'                 => (is => 'rw', isa => 'ArrayRef[HashRef]');

my $logger = get_logger(__PACKAGE__);

sub init {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         meshes => 1,
                                         use_toolkit => 0,
                                         restart_services => 0,
                                         validate_certificate => 0,
                                         ca_certificate_file => 0,
                                         ca_certificate_path => 0,
                                         traceroute_master_conf => 1,
                                         owmesh_conf => 1,
                                         pinger_landmarks => 1,
                                         skip_redundant_tests => 0,
                                         addresses => 0,
                                         from_address => 0,
                                         administrator_emails => 0,
                                         send_error_emails    => 0,
                                      });
    my $meshes                 = $parameters->{meshes};
    my $use_toolkit            = $parameters->{use_toolkit};
    my $restart_services       = $parameters->{restart_services};
    my $traceroute_master_conf = $parameters->{traceroute_master_conf};
    my $owmesh_conf            = $parameters->{owmesh_conf};
    my $pinger_landmarks       = $parameters->{pinger_landmarks};
    my $addresses              = $parameters->{addresses};
    my $from_address           = $parameters->{from_address};
    my $administrator_emails   = $parameters->{administrator_emails};
    my $send_error_emails      = $parameters->{send_error_emails};
    my $skip_redundant_tests   = $parameters->{skip_redundant_tests};

    $self->meshes($meshes) if defined $meshes;
    $self->use_toolkit($use_toolkit) if defined $use_toolkit;
    $self->restart_services($restart_services) if defined $restart_services;
    $self->traceroute_master_conf($traceroute_master_conf) if defined $traceroute_master_conf;
    $self->owmesh_conf($owmesh_conf) if defined $owmesh_conf;
    $self->pinger_landmarks($pinger_landmarks) if defined $pinger_landmarks;
    $self->addresses($addresses) if defined $addresses;
    $self->from_address($from_address) if defined $from_address;
    $self->administrator_emails($administrator_emails) if defined $administrator_emails;
    $self->send_error_emails($send_error_emails) if defined $send_error_emails;
    $self->skip_redundant_tests($skip_redundant_tests);

    return;
}

sub run {
    my ($self) = @_;

    unless ($self->addresses) {
        $self->addresses($self->__get_addresses());
    }

    if (scalar(@{ $self->addresses }) == 0) {
        my $msg = "No addresses for this host";
        $logger->error($msg);
        $self->__add_error({ error_msg => $msg });
        return;
    }


    $self->__configure_host();

    $self->__send_error_messages();

    return;
}

sub __send_error_messages {
    my ($self) = @_;

    unless ($self->send_error_emails) {
        $logger->debug("Sending error messages is disabled");
        return;
    }

    if (not $self->errors or scalar(@{ $self->errors }) == 0) {
        $logger->debug("No errors reported");
        return;
    }


    # Build one email for each group of recipients. We may want to do this
    # per-recipient.
    my %emails_by_to = ();
    foreach my $error (@{ $self->errors }) {
        my @to_addresses = $self->__get_administrator_emails({ local => $self->administrator_emails, mesh => $error->{mesh}, host => $error->{host} });
        if (scalar(@to_addresses) == 0) {
            $logger->debug("No email address to send error message to: ".$error->{error_msg});
            next;
        }

        my $full_error_msg = "Mesh Error:\n";
        $full_error_msg .= "  Mesh: ".($error->{mesh}?$error->{mesh}->description:"")."\n";
        $full_error_msg .= "  Host: ".($error->{host}?$error->{host}->addresses->[0]:"")."\n";
        $full_error_msg .= "  Error: ".$error->{error_msg}."\n\n";

        my $hash_key = join("|", @to_addresses);

        unless ($emails_by_to{$hash_key}) {
            $emails_by_to{$hash_key} = { to => \@to_addresses, body => "" };
        }

        $emails_by_to{$hash_key}->{body} .= $full_error_msg;
    }

    my $from_address = $self->from_address;
    unless ($from_address) {
        my $hostname = `hostname -f 2> /dev/null`;
        chomp($hostname);
        unless($hostname) {
            $hostname = `hostname 2> /dev/null`;
            chomp($hostname);
        }
        unless($hostname) {
            $hostname = "localhost";
        }

        $from_address = "mesh_agent@".$hostname;
    }
 
    foreach my $email (values %emails_by_to) {
        $logger->debug("Sending email to: ".join(', ', @{ $email->{to} }).": ".$email->{body});
        my $msg = MIME::Lite->new(
                From     => $from_address,
                To       => $email->{to},
                Subject  =>'Mesh Errors',
                Data     => $email->{body},
            );

        unless ($msg->send) {
            $logger->error("Problem sending email to: ".join(', ', @{ $email->{to} }));
        }
    }

    return;
}

sub __get_administrator_emails {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         local => 0,
                                         mesh => 0,
                                         host => 0,
                                      });

    my $local = $parameters->{local};
    my $mesh  = $parameters->{mesh};
    my $host  = $parameters->{host};

    my %addresses = ();

    my $site = $host?$host->parent:undef;
    my $organization = $site?$site->parent:undef;

    foreach my $level ($host, $site, $organization, $mesh) { # i.e. host, site and mesh level administrators
        next unless ($level and $level->administrators);

        foreach my $admin (@{ $level->administrators }) {
            $addresses{$admin->email} = 1;
        }
    }

    if ($local) {
        foreach my $admin (@{ $local }) {
            $addresses{$admin} = 1;
        }
    }

    return keys %addresses;
}

sub __configure_host {
    my ($self) = @_;

    my $perfsonarbuoy_generator = perfSONAR_PS::MeshConfig::Generators::perfSONARBUOY->new();
    my ($status, $res) = $perfsonarbuoy_generator->init({ config_file => $self->owmesh_conf, skip_duplicates => $self->skip_redundant_tests });
    if ($status != 0) {
        my $msg = "Problem initializing perfSONARBUOY owmesh.conf: ".$res;
        $logger->error($msg);
        $self->__add_error({ error_msg => $msg });

        return;
    }

    my $traceroute_master_generator = perfSONAR_PS::MeshConfig::Generators::TracerouteMaster->new();
    ($status, $res) = $traceroute_master_generator->init({ config_file => $self->traceroute_master_conf, skip_duplicates => $self->skip_redundant_tests });
    if ($status != 0) {
        my $msg = "Problem initializing traceroute-master.conf: ".$res;
        $logger->error($msg);
        $self->__add_error({ error_msg => $msg });

        return;
    }


    my $pinger_generator = perfSONAR_PS::MeshConfig::Generators::PingER->new();
    ($status, $res) = $pinger_generator->init({ config_file => $self->pinger_landmarks, skip_duplicates => $self->skip_redundant_tests });
    if ($status != 0) {
        my $msg = "Problem initializing pinger landmarks: ".$res;
        $logger->error($msg);
        $self->__add_error({ error_msg => $msg });

        return;
    }

    # The $dont_change variable lets us know at the end whether or not we
    # should go through with writing the files, and restarting the daemons. If
    # a user has specified that a mesh must exist, or no updates occur, we
    # don't change anything.
    my $dont_change = 0;

    foreach my $mesh_params (@{ $self->meshes }) {
        # Grab the mesh from the server
        my ($status, $res) = load_mesh({
                                      configuration_url => $mesh_params->{configuration_url},
                                      validate_certificate => $mesh_params->{validate_certificate},
                                      ca_certificate_file => $mesh_params->{ca_certificate_file},
                                      ca_certificate_path => $mesh_params->{ca_certificate_path},
                                   });
        if ($status != 0) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Problem with mesh configuration: ".$res;
            $logger->error($msg);
            $self->__add_error({ error_msg => $msg });
            next;
        }

        my $mesh = $res;

        # Make sure that the mesh is valid
        eval {
            $mesh->validate_mesh();
        };
        if ($@) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Invalid mesh configuration: ".$@;
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, error_msg => $msg });
            next;
        }

        # Find the host block associated with this machine
        my $hosts = $mesh->lookup_hosts({ addresses => $self->addresses });
        unless ($hosts->[0]) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Can't find any host blocks associated with the addresses on this machine: ".join(", ", @{ $self->addresses });
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, error_msg => $msg });
            next;
        }

        if (scalar(@$hosts) > 1) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Multiple 'host' elements associated with the addresses on this machine: ".join(", ", @{ $self->addresses });
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, error_msg => $msg });
            next;
        }

        my $host = $hosts->[0];

        # Find the tests that this machine is expected to run
        my $tests = $mesh->lookup_tests_by_addresses({ addresses => $host->addresses });
        if (scalar(@$tests) == 0) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "No tests for this host to run: ".join(", ", @{ $self->addresses });
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, host => $host, error_msg => $msg });
            next;
        }

        # Add the PingER tests to the PingER landmarks
        eval {
            $pinger_generator->add_mesh_tests({ mesh => $mesh,
                                                tests => $tests,
                                                host => $host,
                                             });
        };
        if ($@) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Problem adding PingER tests: $@";
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, host => $host, error_msg => $msg });
        }

        # Add the perfSONARBUOY tests to the PingER landmarks
        eval {
            $perfsonarbuoy_generator->add_mesh_tests({ mesh => $mesh,
                                                       tests => $tests,
                                                       host => $host,
                                                    });
        };
        if ($@) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Problem adding perfSONARBUOY tests: $@";
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, host => $host, error_msg => $msg });
        }

        # Add the perfSONARBUOY to the traceroute master generator
        eval {
            $traceroute_master_generator->add_mesh_tests({ mesh => $mesh,
                                                           tests => $tests,
                                                           host => $host,
                                                        });
        };
        if ($@) {
            if ($mesh_params->{required}) {
                $dont_change = 1;
            }

            my $msg = "Problem adding Traceroute tests: $@";
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, host => $host, error_msg => $msg });
        }
    }

    if ($dont_change) {
        my $msg = "Problem with required meshes, not changing configuration";
        $logger->error($msg);
        $self->__add_error({ error_msg => $msg });
        return;
    }

    my $pinger_landmarks       = $pinger_generator->get_pinger_landmarks();
    my $owmesh_conf            = $perfsonarbuoy_generator->get_owmesh_conf();
    my $traceroute_master_conf = $traceroute_master_generator->get_traceroute_master_conf();

    my $wrote_pinger;
    my $wrote_perfsonarbuoy;
    my $wrote_traceroute;

    # Write the new configuration files
    $res = $self->__write_file({ file => $self->pinger_landmarks, contents => $pinger_landmarks });
    $wrote_pinger = $res;

    $res = $self->__write_file({ file => $self->owmesh_conf, contents => $owmesh_conf });
    $wrote_perfsonarbuoy = $res;
    $wrote_traceroute = $res;

    $res = $self->__write_file({ file => $self->traceroute_master_conf, contents => $traceroute_master_conf });
    $wrote_traceroute = $res unless $wrote_traceroute;  # Don't change yes to no. If we've written either, restart traceroute.

    if ($self->restart_services) {
        foreach my $service ("pinger", "perfsonarbuoy_owamp", "perfsonarbuoy_bwctl", "traceroute_scheduler") {
            next if ($service eq "pinger" and not $wrote_pinger);

            next if ($service =~ "perfsonarbuoy" and not $wrote_perfsonarbuoy);

            next if ($service =~ "traceroute" and not $wrote_traceroute);

            ($status, $res) = $self->__restart_service({ name => $service });
            if ($status != 0) {
                my $msg = "Problem restarting service $service: ".$res;
                $logger->error($msg);
                foreach my $mesh_params (@{ $self->meshes }) {
                    $self->__add_error({ mesh => $mesh_params->{mesh}, host => $mesh_params->{host}, error_msg => $msg });
                }
            }
        }
    }

    return;
}

sub __add_error {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         mesh => 0,
                                         host => 0,
                                         error_msg => 1,
                                      });

    my @errors = ();
    @errors = @{ $self->errors } if ($self->errors);

    push @errors, $parameters;

    $self->errors(\@errors);

    return;
}

sub __write_file {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { file => 1, contents => 1 } );
    my $file  = $parameters->{file};
    my $contents = $parameters->{contents};

    unless ($self->__compare_file({ file => $file, contents => $contents })) {
        $logger->info($file." is unchanged.");
        return;
    }

    $logger->debug("Writing ".$file);

    eval {
        if ($self->use_toolkit) {
            my $res = save_file( { file => $file, content => $contents } );
            if ( $res == -1 ) {
                die("Couldn't save ".$file."via toolkit daemon");
            }
        } 
        else {
            open(FILE, ">".$file) or die("Couldn't open $file");
            print FILE $contents;
            close(FILE);
        }
    };
    if ($@) {
        my $msg = "Problem writing to $file: $@";
        $logger->error($msg);

        foreach my $mesh_params (@{ $self->meshes }) {
            $self->__add_error({ mesh => $mesh_params->{mesh}, host => $mesh_params->{host}, error_msg => $msg });
        }

        return;
    }

    return 1;
}

sub __compare_file {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { file => 1, contents => 1 } );
    my $file  = $parameters->{file};
    my $contents = $parameters->{contents};

    $logger->debug("Checking for changes in ".$file);

    my $differ = 1;

    if (open(FILE, $file)) {
        $logger->debug("Reading ".$file);
        my $file_contents = do { local $/; <FILE> };
        $differ = 0 if ($file_contents eq $contents);
        $logger->debug($file." changed") if ($differ);
        close(FILE);
    }

    return $differ;
}

sub __restart_service {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { name => 1 } );
    my $name  = $parameters->{name};

    eval {
        if ($self->use_toolkit) {
            my $res = restart_service( { name => $name } );
            if ( $res == -1 ) {
                die("Couldn't restart service ".$name." via toolkit daemon");
            }
        } 
        else {
            my $services_conf = perfSONAR_PS::NPToolkit::Config::Services->new();
            $services_conf->init();

            my $service_info = $services_conf->lookup_service( { name => $name } );
            unless ($service_info) {
                my $msg = "Invalid service: $name";
                $logger->error($msg);
                die($msg);
            }

            my @service_names;

            if ( ref $service_info->{service_name} eq "ARRAY" ) {
                @service_names = @{ $service_info->{service_name} };
            }
            else {
                @service_names = ( $service_info->{service_name} );
            }
 
            foreach my $service_name ( @service_names ) {
                my $cmd = "service " . $service_name . " restart";
                $logger->debug($cmd);
                my $output = "";
                open FH, $cmd." 2>&1 | " or die "Problem exec'ing $cmd";
                while(<FH>) {
                    $output .= $_;
                }
                my $result = $?;

                close(FH);

                $logger->debug("Script output for $cmd: ".$output);

                unless ($result == 0) {
                    die("Couldn't restart $service_name");
                }
            }
        } 
    };
    if ($@) {
        my $msg = "Problem restarting $name: $@";
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, "");
}

sub __get_addresses {
    my $hostname = `hostname -f 2> /dev/null`;
    chomp($hostname);

    my @ips = get_ips();

    my %ret_addresses = ();

    my @all_addressses = ();
    @all_addressses = @ips;
    push @all_addressses, $hostname if ($hostname);

    foreach my $address (@all_addressses) {
        next if ($ret_addresses{$address});

        $ret_addresses{$address} = 1;

        if ( is_ipv4( $address ) or 
             &Net::IP::ip_is_ipv6( $address ) ) {
            my $hostname = reverse_dns($address);

            push @all_addressses, $hostname if ($hostname);
        }
        elsif ( is_hostname( $address ) ) {
            my $hostname = $address;

            my @addresses = resolve_address($hostname);

            push @all_addressses, @addresses;
        }
    }

    my @ret_addresses = keys %ret_addresses;

    return \@ret_addresses;
}
