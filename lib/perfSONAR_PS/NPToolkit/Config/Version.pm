package perfSONAR_PS::NPToolkit::Config::Version;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::NPToolkit::Config::Version

=head1 DESCRIPTION

Module for retrieving the current Toolkit version.

=cut

use Data::Dumper;

use base 'perfSONAR_PS::NPToolkit::Config::Base';

use fields 'NPTOOLKIT_VERSION_BIN', 'NPTOOLKIT_INSTALL_TYPE_BIN';

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger :nowarn);
use Storable qw(store retrieve freeze thaw dclone);

my %defaults = ( nptoolkit_version_bin => "/var/lib/perfsonar/bundles/bundle_version", 
                 nptoolkit_install_type_bin => "/var/lib/perfsonar/bundles/bundle_type",);

=head2 init({ nptoolkit_version_bin => 0 })

Initializes the client. Returns 0 on success and -1 on failure. The
nptoolkit_version_bin parameter can be specified to set which file the module
should run to get the current version.

=cut

sub init {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { enabled_services_file => 0, } );

    # Initialize the defaults
    $self->{NPTOOLKIT_VERSION_BIN} = $defaults{nptoolkit_version_bin};
    $self->{NPTOOLKIT_INSTALL_TYPE_BIN} = $defaults{nptoolkit_install_type_bin};
    
    # Override any
    $self->{NPTOOLKIT_VERSION_BIN} = $parameters->{enabled_services_file} if ( $parameters->{nptoolkit_version_bin} );

    my $res = $self->reset_state();
    if ( $res != 0 ) {
        return $res;
    }

    return 0;
}

=head2 save({ restart_services => 0 })
    Can't change the version number so drop it.
=cut

sub save {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { restart_services => 0, } );

    return 0;
}

=head2 last_modified()
    Returns when the site information was last saved.
=cut

sub last_modified {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my ($mtime) = (stat ( $self->{NPTOOLKIT_VERSION_BIN} ) )[9];

    return $mtime;
}

=head2 reset_state()
    Resets the state of the module to the state immediately after having run "init()".
=cut

sub reset_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return 0;
}

=head2 get_version ({})
    Returns the version of the installed package
=cut

sub get_version {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my $version;

    if ( open( FIN, "<", $self->{NPTOOLKIT_VERSION_BIN} ) ) {
        while($version = <FIN>){
            if ( $version ){
                 chomp( $version );
                 last;
            }
        }
        close( FIN );
    }

    return $version;
}

=head2 get_install_type ({})
    Returns the bundle type of the installed package
=cut

sub get_install_type {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my $type;

    if ( open( FIN, "<", $self->{NPTOOLKIT_INSTALL_TYPE_BIN} ) ) {
        while($type = <FIN>){
            if ( $type ){
                 chomp( $type );
                 last;
            }
        }
        close( FIN );
    }

    return $type;
}

=head2 save_state()
    Saves the current state of the module as a string. This state allows the
    module to be recreated later.
=cut

sub save_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my %state = ( nptoolkit_version_bin => $self->{NPTOOLKIT_VERSION_BIN},
                  nptoolkit_install_type_bin =>  $self->{NPTOOLKIT_INSTALL_TYPE_BIN});

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

    $self->{NPTOOLKIT_VERSION_BIN} = $state->{nptoolkit_version_bin};
    $self->{NPTOOLKIT_INSTALL_TYPE_BIN} = $state->{nptoolkit_install_type_bin};
    
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
