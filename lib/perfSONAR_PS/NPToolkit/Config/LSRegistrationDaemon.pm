package perfSONAR_PS::NPToolkit::Config::LSRegistrationDaemon;

use strict;
use warnings;

our $VERSION = 3.5.1;

=head1 NAME

perfSONAR_PS::NPToolkit::Config::pSPSServiceDaemons

=head1 DESCRIPTION

Module for reading/writing commonly configured aspects of the perfSONAR-PS
service daemon. Currently, the external address, site location and site name
are configurable.

=cut

use Template;

use base 'perfSONAR_PS::NPToolkit::Config::Base';

use fields 'CONFIG_FILE', 'ORGANIZATION_NAME', 'PROJECTS', 'CITY', 'REGION', 'COUNTRY', 'ZIP_CODE','LATITUDE','LONGITUDE', 'ADMINISTRATOR_NAME', 'ADMINISTRATOR_EMAIL', 'ROLE', 'ACCESS_POLICY', 'ACCESS_POLICY_NOTES';

use Params::Validate qw(:all);
use Storable qw(store retrieve freeze thaw dclone);
use Data::Dumper;
use File::Basename qw(dirname basename);

use Config::General qw(ParseConfig SaveConfigString);
use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file restart_service );

my %defaults = (
    config_file  => "/etc/perfsonar/lsregistrationdaemon.conf",
);

=head2 init({ config_file => 1, service_name => 1 })

XXX

=cut

sub init {
    my ( $self, @params ) = @_;
    my $parameters = validate(
        @params,
        {
            config_file  => 0,
        }
    );

    $self->{CONFIG_FILE} = $defaults{config_file};

    $self->{CONFIG_FILE} = $parameters->{config_file} if $parameters->{config_file};

    my $res = $self->reset_state();
    if ( $res != 0 ) {
        return $res;
    }

    return 0;
}

=head2 get_organization_name({ organization_name => 1 })
Returns the name of the organization to advertise in the gLS
=cut

sub get_organization_name {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ORGANIZATION_NAME};
}

=head2 get_city({ city => 1 })
Returns the city of the service to advertise in the LS
=cut
sub get_city {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{CITY};
}

=head2 get_state({ city => 1 })
Returns the region/state of the service to advertise in the LS
=cut
sub get_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{REGION};
}

=head2 get_country({ country => 1 })
Returns the country of the service to advertise in the LS
=cut
sub get_country {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{COUNTRY};
}

=head2 get_zipcode({ country => 1 })
Returns the zip code of the service to advertise in the LS
=cut
sub get_zipcode {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ZIP_CODE};
}

=head2 get_latitude({ country => 1 })
Returns the latitude of the service to advertise in the LS
=cut
sub get_latitude {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{LATITUDE};
}

=head2 get_longitude({ country => 1 })
Returns the longitude of the service to advertise in the LS
=cut
sub get_longitude {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{LONGITUDE};
}

=head2 get_projects({ location => 1 })
Returns the location of the service to advertise in the gLS
=cut

sub get_projects {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{PROJECTS};
}

=head2 get_administrator_email({ location => 1 })
Returns the administrator email of the service to advertise in the gLS
=cut

sub get_administrator_email {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ADMINISTRATOR_EMAIL};
}

=head2 get_administrator_name({ location => 1 })
Returns the administrator name of the service to advertise in the gLS
=cut

sub get_administrator_name {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ADMINISTRATOR_NAME};
}

=head2 get_role()
Returns the node role type to advertise in the gLS
=cut

sub get_role {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ROLE};
}

=head2 get_access_policy()
Returns the node's access policy to advertise in the gLS
=cut

sub get_access_policy {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ACCESS_POLICY};
}

=head2 get_access_policy_notes()
Returns the node's access policy notes field to advertise in the gLS
=cut

sub get_access_policy_notes {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { } );

    return $self->{ACCESS_POLICY_NOTES};
}

=head2 set_organization_name({ organization_name => 1 })
Sets the name of the organization to advertise in the gLS
=cut

sub set_organization_name {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { organization_name => 1, } );

    my $organization_name = $parameters->{organization_name};

    $self->{ORGANIZATION_NAME} = $organization_name;

    return 0;
}

=head2 set_city({ city => 1 })
Sets the city of the service to advertise in the LS
=cut
sub set_city {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { city => 1, } );

    my $city = $parameters->{city};

    $self->{CITY} = $city;

    return 0;
}

=head2 set_state({ state => 1 })
Sets the state of the service to advertise in the LS
=cut
sub set_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { state => 1, } );

    my $state = $parameters->{state};

    $self->{REGION} = $state;

    return 0;
}

=head2 set_country({ country => 1 })
Sets the country of the service to advertise in the LS
=cut
sub set_country {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { country => 1, } );

    my $country = $parameters->{country};

    $self->{COUNTRY} = $country;

    return 0;
}

=head2 set_zipcode({ country => 1 })
Sets the zipcode of the service to advertise in the LS
=cut
sub set_zipcode {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { zipcode => 1, } );

    my $zipcode = $parameters->{zipcode};

    $self->{ZIP_CODE} = $zipcode;

    return 0;
}

=head2 set_latitude({ latitude => 1 })
Sets the latitude of the service to advertise in the LS
=cut
sub set_latitude {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { latitude => 1, } );

    my $latitude = $parameters->{latitude};

    $self->{LATITUDE} = $latitude;

    return 0;
}

=head2 set_longitude({ longitude => 1 })
Sets the longitude of the service to advertise in the LS
=cut
sub set_longitude {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { longitude => 1, } );

    my $longitude = $parameters->{longitude};

    $self->{LONGITUDE} = $longitude;

    return 0;
}

=head2 set_projects({ projects => 1 })
Sets the projects of the service to advertise in the gLS
=cut

sub set_projects {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { projects => 1, } );

    my $projects = $parameters->{projects};

    $self->{PROJECTS} = $projects;

    return 0;
}

=head2 set_administrator_name({ administrator_name => 1 })
Sets the administrator's name
=cut

sub set_administrator_name {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { administrator_name => 1, } );

    my $admin_name = $parameters->{administrator_name};

    $self->{ADMINISTRATOR_NAME} = $admin_name;

    return 0;
}

=head2 set_administrator_email({ administrator_email => 1 })
Sets the administrator's email 
=cut

sub set_administrator_email {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { administrator_email => 1, } );

    my $admin_email = $parameters->{administrator_email};

    $self->{ADMINISTRATOR_EMAIL} = $admin_email;

    return 0;
}

=head2 set_role({ role => 1 })
Sets the node role the service to advertise in the LS
=cut
sub set_role {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { role => 1, } );

    my $role = $parameters->{role};

    $self->{ROLE} = $role;

    return 0;
}

=head2 set_access_policy({ access_policy => 1 })
Sets the node access policy to advertise in the LS
=cut
sub set_access_policy {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { access_policy => 1, } );

    my $access_policy = $parameters->{access_policy};

    $self->{ACCESS_POLICY} = $access_policy;

    return 0;
}

=head2 set_access_policy_notes({ access_policy_notes => 1 })
Sets the node access policy notes to advertise in the LS
=cut
sub set_access_policy_notes {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { access_policy_notes => 1, } );

    my $access_policy_notes = $parameters->{access_policy_notes};

    $self->{ACCESS_POLICY_NOTES} = $access_policy_notes;

    return 0;
}

=head2 last_modified()
    Returns when the site information was last saved.
=cut

sub last_modified {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my ($mtime) = (stat ( $self->{CONFIG_FILE} ) )[9];

    return $mtime;
}

=head2 save({ restart_services => 0 })
    Saves the configuration to disk. 
=cut

sub save {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { restart_services => 0, } );

    my $config = $self->load_config({ file => $self->{CONFIG_FILE} });
    unless ($config) {
        return -1;
    }

    delete($config->{administrator});
    if ($self->{ADMINISTRATOR_EMAIL} or $self->{ADMINISTRATOR_NAME}) {
        $config->{administrator} = {};
        $config->{administrator}->{name} = $self->{ADMINISTRATOR_NAME};
        $config->{administrator}->{email} = $self->{ADMINISTRATOR_EMAIL};
    }

    delete($config->{site_name});
    $config->{site_name} = $self->{ORGANIZATION_NAME} if $self->{ORGANIZATION_NAME};

    delete($config->{city});
    $config->{city} = $self->{CITY} if $self->{CITY};

    delete($config->{region});
    $config->{region} = $self->{REGION} if $self->{REGION};

    delete($config->{country});
    $config->{country} = $self->{COUNTRY} if $self->{COUNTRY};

    delete($config->{zip_code});
    $config->{zip_code} = $self->{ZIP_CODE} if $self->{ZIP_CODE};

    delete($config->{latitude});
    $config->{latitude} = $self->{LATITUDE} if defined $self->{LATITUDE};

    delete($config->{longitude});
    $config->{longitude} = $self->{LONGITUDE} if defined $self->{LONGITUDE};

    delete($config->{site_project});
    $config->{site_project} = $self->{PROJECTS} if $self->{PROJECTS};

    delete($config->{role});
    $config->{role} = $self->{ROLE} if $self->{ROLE};

    delete($config->{access_policy});
    $config->{access_policy} = $self->{ACCESS_POLICY} if $self->{ACCESS_POLICY};

    delete($config->{access_policy_notes});
    $config->{access_policy_notes} = $self->{ACCESS_POLICY_NOTES} if $self->{ACCESS_POLICY_NOTES};

    my $content = SaveConfigString( $config );

    my $res = save_file( { file => $self->{CONFIG_FILE}, content => $content } );
    if ( $res == -1 ) {
        return -1;
    }

    if ( $parameters->{restart_services} ) {
        $res = restart_service({ name => "ls_registration_daemon" });
        if ($res == -1) {
             return -1;
        }
    }

    return 0;
}

=head2 reset_state()
    Resets the state of the module to the state immediately after having run "init()".
=cut

sub reset_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my $config = $self->load_config({ file => $self->{CONFIG_FILE} });
    unless ($config) {
        return -1;
    }

    $self->{ORGANIZATION_NAME} = $config->{site_name};
    $self->{CITY}              = $config->{city};
    $self->{REGION}            = $config->{region};
    $self->{COUNTRY}           = $config->{country};
    $self->{ZIP_CODE}          = $config->{zip_code};
    $self->{LATITUDE}          = $config->{latitude};
    $self->{LONGITUDE}         = $config->{longitude};
    $self->{ADMINISTRATOR_NAME} = $config->{administrator}->{name};
    $self->{ADMINISTRATOR_EMAIL} = $config->{administrator}->{email};
    $self->{PROJECTS}          = $config->{project};
    if ($self->{PROJECTS} and ref($self->{PROJECTS}) ne "ARRAY") {
        $self->{PROJECTS} = [ $self->{PROJECTS} ];
    }
    $self->{ROLE}                   = $config->{role};
    $self->{ACCESS_POLICY}          = $config->{access_policy};
    $self->{ACCESS_POLICY_NOTES}    = $config->{access_policy_notes};

    return 0;
}

=head2 load_config()
    Resets the state of the module to the state immediately after having run "init()".
=cut
sub load_config {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { file => 1 } );

    my $file = $parameters->{file};

    my %config;
    eval {
        %config = ParseConfig(-ConfigFile => $file, -AutoTrue => 1, -UTF8 => 1);
    };
    if ($@) {
        return undef;
    }

    return \%config;
}

=head2 save_state()
    Saves the current state of the module as a string. This state allows the
    module to be recreated later.
=cut

sub save_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my %state = (
        config_file                 => $self->{CONFIG_FILE},
        service_name                => $self->{SERVICE_NAME},
        organization_name           => $self->{ORGANIZATION_NAME},
        projects                    => $self->{PROJECTS},
        city                        => $self->{CITY},
        region                      => $self->{REGION},
        country                     => $self->{COUNTRY},
        zip_code                    => $self->{ZIP_CODE},
        latitude                    => $self->{LATITUDE},
        longitude                   => $self->{LONGITUDE},
        administrator_name          => $self->{ADMINISTRATOR_NAME},
        administrator_email         => $self->{ADMINISTRATOR_EMAIL},
        role                        => $self->{ROLE},
        access_policy               => $self->{ACCESS_POLICY},
        access_policy_notes         => $self->{ACCESS_POLICY_NOTES},
    );

    my $str = freeze( \%state );

    return $str;
}

=head2 restore_state({ state => \$state })
    Restores the modules state based on a string provided by the "save_state"
    function above.
=cut

sub restore_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { state => 1, } );

    my $state = thaw( $parameters->{state} );

    $self->{CONFIG_FILE}                 = $state->{config_file};
    $self->{SERVICE_NAME}                = $state->{service_name};
    $self->{ORGANIZATION_NAME}           = $state->{organization_name};
    $self->{PROJECTS}                    = $state->{projects};
    $self->{CITY}                        = $state->{city};
    $self->{REGION}                      = $state->{region};
    $self->{COUNTRY}                     = $state->{country};
    $self->{ZIP_CODE}                    = $state->{zip_code};
    $self->{LATITUDE}                    = $state->{latitude};
    $self->{LONGITUDE}                   = $state->{longitude};
    $self->{ADMINISTRATOR_NAME}          = $state->{administrator_name};
    $self->{ADMINISTRATOR_EMAIL}         = $state->{administrator_email};
    $self->{ROLE}                        = $state->{role};
    $self->{ACCESS_POLICY}               = $state->{access_policy};
    $self->{ACCESS_POLICY_NOTES}         = $state->{access_policy_notes};
    
    return;
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR-PS Users' mailing list, please visit:

  https://lists.internet2.edu/sympa/info/perfsonar-ps-users

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 COPYRIGHT

Copyright (c) 2008-2010, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
