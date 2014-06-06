package perfSONAR_PS::MeshConfig::Utils;

use strict;
use warnings;

our $VERSION = 3.1;

use JSON;
use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use URI::Split qw(uri_split);

use perfSONAR_PS::Utils::HTTPS qw(https_get);

use perfSONAR_PS::MeshConfig::Config::Mesh;

use base 'Exporter';

our @EXPORT_OK = qw( load_mesh );

my $logger = get_logger(__PACKAGE__);

sub load_mesh {
    my $parameters = validate( @_, { 
                                     configuration_url => 1,
                                     validate_certificate => 0,
                                     ca_certificate_file => 0,
                                     ca_certificate_path => 0,
                                     relaxed_checking    => 0,
                                   });
    my $configuration_url      = $parameters->{configuration_url};
    my $validate_certificate   = $parameters->{validate_certificate};
    my $ca_certificate_file    = $parameters->{ca_certificate_file};
    my $ca_certificate_path    = $parameters->{ca_certificate_path};
    my $relaxed_checking       = $parameters->{relaxed_checking};

    my ($status, $res);

    ($status, $res) = __load_json({ url                  => $configuration_url,
                                    validate_certificate => $validate_certificate,
                                    ca_certificate_file  => $ca_certificate_file,
                                    ca_certificate_path  => $ca_certificate_path,
                                 });

    unless ($status == 0) {
        return ($status, $res);
    }

    my $json = $res;

    # parse any "include" attributes
    ($status, $res) = __process_include_directives({ 
                                                     hash                 => $json,
                                                     validate_certificate => $validate_certificate,
                                                     ca_certificate_file  => $ca_certificate_file,
                                                     ca_certificate_path  => $ca_certificate_path,
                                                  });
    unless ($status == 0) {
        return ($status, $res);
    }


    my $config;
    eval {
        my $strict = ($relaxed_checking?0:1);

        $config = perfSONAR_PS::MeshConfig::Config::Mesh->parse($json, $strict);
    };
    if ($@) {
        my $msg = "Invalid mesh configuration: ".$@;
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, $config);
}

sub __process_include_directives {
    my $parameters = validate( @_, { 
                                     hash                 => 1,
                                     validate_certificate => 0,
                                     ca_certificate_file  => 0,
                                     ca_certificate_path  => 0,
                                   });

    my $hash                   = $parameters->{hash};
    my $validate_certificate   = $parameters->{validate_certificate};
    my $ca_certificate_file    = $parameters->{ca_certificate_file};
    my $ca_certificate_path    = $parameters->{ca_certificate_path};

    if ($hash->{include}) {
        foreach my $url (@{ $hash->{include} }) {
            $logger->debug("Loading $url");
            my ($status, $res) = __load_json({ url                  => $url,
                                               validate_certificate => $validate_certificate,
                                               ca_certificate_file  => $ca_certificate_file,
                                               ca_certificate_path  => $ca_certificate_path,
                                            });

            unless ($status == 0) {
                return ($status, $res);
            }

            my $json = $res;

            ($status, $res) = __merge_hash(hash => $hash, new_hash => $json);
        }

        delete($hash->{include});
    }

    foreach my $key (keys %{ $hash }) {
        if (ref($hash->{$key}) eq "ARRAY") {
            foreach my $element (@{ $hash->{$key} }) {
                if (ref($element) eq "HASH") {
                    my ($status, $res) = __process_include_directives({ hash                 => $element,
                                                                        validate_certificate => $validate_certificate,
                                                                        ca_certificate_file  => $ca_certificate_file,
                                                                        ca_certificate_path  => $ca_certificate_path,
                                                                     });
                    unless ($status == 0) {
                        return ($status, $res);
                    }
                }
            }
        }
        elsif (ref($hash->{$key}) eq "HASH") {
            my ($status, $res) = __process_include_directives({ hash                 => $hash->{$key},
                                                                validate_certificate => $validate_certificate,
                                                                ca_certificate_file  => $ca_certificate_file,
                                                                ca_certificate_path  => $ca_certificate_path,
                                                             });
            unless ($status == 0) {
                return ($status, $res);
            }
        }
    }

    return (0, "");
}

sub __merge_hash {
    my $parameters = validate( @_, { 
                                     hash     => 1,
                                     new_hash => 1,
                                   });
    my $hash     = $parameters->{hash};
    my $new_hash = $parameters->{new_hash};

    foreach my $key (keys %{ $new_hash }) {
        unless ($hash->{$key}) {
            $hash->{$key} = $new_hash->{$key};
            next;
        }

        if (ref($hash->{$key}) ne ref($hash->{$key})) {
            my $msg = "Problem merging '$key' elements";
            $logger->error($msg);
            return (-1, $msg);
        }

        if (ref($hash->{$key}) eq "ARRAY") {
            $logger->debug("Appending $key array");
            push @{ $hash->{$key} }, @{ $new_hash->{$key} };
        }
        elsif (ref($hash->{$key}) eq "HASH") {
            $logger->debug("Merging $key hashes");
            my ($status, $res) = __merge_hash($hash->{$key}, $new_hash->{$key});
            unless ($status == 0) {
                return ($status, $res);
            }
        }
        else {
            $logger->debug("Using $key value from original hash");
        }
    }

    return (0, "");
}

sub __load_json {
    my $parameters = validate( @_, { 
                                     url                  => 1,
                                     validate_certificate => 0,
                                     ca_certificate_file  => 0,
                                     ca_certificate_path  => 0,
                                   });
    my $url                    = $parameters->{url};
    my $validate_certificate   = $parameters->{validate_certificate};
    my $ca_certificate_file    = $parameters->{ca_certificate_file};
    my $ca_certificate_path    = $parameters->{ca_certificate_path};

    my ($status, $res);

    my $uri = URI->new($url);
    if ($uri->scheme eq "file") {
        eval {
            $status = 0;
            $res = "";
            open(FILE, $uri->path) or die("Couldn't open ".$uri->path);
            while(<FILE>) { 
                $res .= $_;
            }
            close(FILE);
        };
        if ($@) {
            $status = -1;
            $res = $@;
        }
    }
    else {
        ($status, $res) = https_get({ url                 => $url,
                                      verify_certificate  => $validate_certificate,
                                      verify_hostname     => $validate_certificate,
                                      ca_certificate_file => $ca_certificate_file,
                                      ca_certificate_path => $ca_certificate_path,
                                   });
    }

    if ($status != 0) {
        $logger->debug("Problem retrieving mesh configuration from $url: ".$res);
        return ($status, $res);
    }

    my $json;
    eval {
        $json = JSON->new->decode($res);
    };
    if ($@) {
        my $msg = "Problem parsing json for $url: ".$@;
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, $json);
}

1;
