package perfSONAR_PS::MeshConfig::GUIAgent;

use strict;
use warnings;

our $VERSION = 3.1;

use Config::General;
use File::Basename;
use Log::Log4perl qw(get_logger);
use MIME::Lite;
use Params::Validate qw(:all);
use URI::Split qw(uri_split);
use YAML qw(LoadFile);

use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw(restart_service save_file);
use perfSONAR_PS::NPToolkit::Services::ServicesMap qw(get_service_object);

use perfSONAR_PS::MeshConfig::Utils qw(load_mesh);

use perfSONAR_PS::MeshConfig::Generators::MaDDash qw( generate_maddash_config );

use Module::Load;

use Moose;

has 'use_toolkit'            => (is => 'rw', isa => 'Bool');
has 'restart_services'       => (is => 'rw', isa => 'Bool');

has 'meshes'                 => (is => 'rw', isa => 'ArrayRef[HashRef]');

has 'maddash_yaml'           => (is => 'rw', isa => 'Str');
has 'maddash_options'        => (is => 'rw', isa => 'HashRef');

has 'send_error_emails'         => (is => 'rw', isa => 'Bool', default => 1);
has 'send_error_emails_to_mesh' => (is => 'rw', isa => 'Bool', default => 0);

has 'from_address'           => (is => 'rw', isa => 'Str');
has 'administrator_emails'   => (is => 'rw', isa => 'ArrayRef[Str]');

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
                                         maddash_yaml => 1,
                                         maddash_options => 1,
                                         addresses => 0,
                                         from_address => 0,
                                         administrator_emails => 0,
                                         send_error_emails    => 0,
                                         send_error_emails_to_mesh => 0,
                                      });
    my $meshes                 = $parameters->{meshes};
    my $use_toolkit            = $parameters->{use_toolkit};
    my $restart_services       = $parameters->{restart_services};
    my $maddash_yaml           = $parameters->{maddash_yaml};
    my $maddash_options        = $parameters->{maddash_options};
    my $addresses              = $parameters->{addresses};
    my $from_address           = $parameters->{from_address};
    my $administrator_emails   = $parameters->{administrator_emails};
    my $send_error_emails      = $parameters->{send_error_emails};
    my $send_error_emails_to_mesh = $parameters->{send_error_emails_to_mesh};

    $self->meshes($meshes) if defined $meshes;
    $self->use_toolkit($use_toolkit) if defined $use_toolkit;
    $self->restart_services($restart_services) if defined $restart_services;
    $self->maddash_yaml($maddash_yaml) if defined $maddash_yaml;
    $self->maddash_options($maddash_options) if defined $maddash_options;
    $self->addresses($addresses) if defined $addresses;
    $self->from_address($from_address) if defined $from_address;
    $self->administrator_emails($administrator_emails) if defined $administrator_emails;
    $self->send_error_emails($send_error_emails) if defined $send_error_emails;
    $self->send_error_emails_to_mesh($send_error_emails_to_mesh) if defined $send_error_emails_to_mesh;

    return;
}

sub run {
    my ($self) = @_;

    $self->__configure_guis();

    $self->__send_error_messages();

    return;
}

sub __send_error_messages {
    my ($self) = @_;

    return unless $self->send_error_emails;

    if (not $self->errors or scalar(@{ $self->errors }) == 0) {
        $logger->debug("No errors reported");
        return;
    }

    # Build one email for each group of recipients. We may want to do this
    # per-recipient.
    my %emails_by_to = ();
    foreach my $error (@{ $self->errors }) {
        my @to_addresses = $self->__get_administrator_emails({ local => $self->administrator_emails, mesh => $error->{mesh} });
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
                                      });

    my $local = $parameters->{local};
    my $mesh  = $parameters->{mesh};

    my %addresses = ();

    if ($self->send_error_emails_to_mesh and $mesh->administrators) {
        foreach my $admin (@{ $mesh->administrators }) {
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

sub __configure_guis {
    my ($self) = @_;

    my @meshes = ();

    foreach my $mesh_params (@{ $self->meshes }) {
        # Grab the mesh from the server
        my ($status, $res) = load_mesh({
                                      configuration_url => $mesh_params->{configuration_url},
                                      validate_certificate => $mesh_params->{validate_certificate},
                                      ca_certificate_file => $mesh_params->{ca_certificate_file},
                                      ca_certificate_path => $mesh_params->{ca_certificate_path},
                                   });
        if ($status != 0) {
            my $msg = "Problem with mesh configuration: ".$res;
            $logger->error($msg);
            $self->__add_error({ error_msg => $msg });
            return;
        }

        my $mesh = $res;

        # Make sure that the mesh is valid
        eval {
            $mesh->validate_mesh();
        };
        if ($@) {
            my $msg = "Invalid mesh configuration: ".$@;
            $logger->error($msg);
            $self->__add_error({ mesh => $mesh, error_msg => $msg });
            next;
        }

        push @meshes, $mesh;
    }

    my ($status, $res) = $self->__generate_maddash_config({ meshes => \@meshes });
    if ($status != 0) {
        my $msg = "Problem generating maddash configuration: ".$res;
        $logger->error($msg);
        foreach my $mesh (@meshes) {
            $self->__add_error({ mesh => $mesh, error_msg => $msg });
        }
        return;
    }

    my $maddash_yaml = $res;

    my $wrote_maddash       = 1;

    # Write the new configuration files
    ($status, $res) = $self->__write_file({ file => $self->maddash_yaml, contents => $maddash_yaml });
    if ($status != 0) {
        my $msg = "Problem writing maddash.yaml: ".$res;
        $logger->error($msg);
        foreach my $mesh (@meshes) {
            $self->__add_error({ mesh => $mesh, error_msg => $msg });
        }

        $wrote_maddash = 0;
    }

    if ($self->restart_services) {
        foreach my $service ("maddash") {
            next if ($service eq "maddash" and not $wrote_maddash);

            ($status, $res) = $self->__restart_service({ name => $service });
            if ($status != 0) {
                my $msg = "Problem restarting service $service: ".$res;
                $logger->error($msg);
                foreach my $mesh (@meshes) {
                    $self->__add_error({ mesh => $mesh, error_msg => $msg });
                }
            }
        }
    }

    return;
}

sub __generate_maddash_config {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { meshes => 1, } );
    my $meshes  = $parameters->{meshes};

    my $maddash_config;
    eval {
        my $maddash_yaml = LoadFile($self->maddash_yaml);

        $maddash_config = generate_maddash_config({ meshes => $meshes, existing_maddash_yaml => $maddash_yaml, maddash_options => $self->maddash_options });
    };
    if ($@) {
        my $msg = "Problem generating maddash configuration: ".$@;
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, $maddash_config);
}

sub __add_error {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { 
                                         mesh => 0,
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
        return (-1, $msg);
    }

    return (0, "");
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
            my $service_obj = get_service_object($name);
            unless ($service_info) {
                my $msg = "Invalid service: $name";
                $logger->error($msg);
                die($msg);
            }

            die if ($service_obj->restart);
        } 
    };
    if ($@) {
        my $msg = "Problem restarting $name: $@";
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, "");
}

sub __send_email {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { to_addresses => 1, subject => 1, body => 1 });
    my $to_addresses = $parameters->{to_addresses};
    my $subject      = $parameters->{subject};
    my $body         = $parameters->{body};

    my $msg = MIME::Lite->new(
        From     => 'aaron@internet2.edu',
        To       => 'aaron@internet2.edu',
        Cc       => 'aaron@internet2.edu',
        Subject  => 'testing',
        Data     =>  "This is the email body",
    );

    $msg->send or die("Couldn't send email");
}
