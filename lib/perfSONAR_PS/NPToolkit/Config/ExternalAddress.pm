package perfSONAR_PS::NPToolkit::Config::ExternalAddress;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::NPToolkit::Config::ExternalAddress

=head1 DESCRIPTION

Module for configuring the NPToolkit's external addresses (default, ipv4 and
ipv6). This address is the address registered by the perfSONAR services, and
the one used for the perfSONAR-BUOY tests. The values are stored in a file
"/usr/local/etc/default_accesspoint" which is included in the perfSONAR service
configuration.

=cut

use base 'perfSONAR_PS::NPToolkit::Config::Base';

use fields 'EXTERNAL_ADDRESS_FILE', 'PRIMARY_ADDRESS', 'PRIMARY_IPV4', 'PRIMARY_IPV6', 'PRIMARY_ADDRESS_IFACE', 'PRIMARY_IPV4_IFACE', 'PRIMARY_IPV6_IFACE', 'PRIMARY_IFACE_SPEED', 'PRIMARY_IFACE_MTU';

use Params::Validate qw(:all);
use Storable qw(store retrieve freeze thaw dclone);
use Data::Dumper;
use Net::Interface;

use perfSONAR_PS::NPToolkit::ConfigManager::Utils qw( save_file restart_service );

# These are the defaults for the current NPToolkit
my %defaults = ( external_address_file => "/opt/perfsonar_ps/toolkit/etc/external_addresses", );

=head2 init({ external_address_file => 0 })

Initializes the client. Returns 0 on success and -1 on failure. The
external_address_file parameter can be specified to set which file the module
should use for reading/writing the configuration.

=cut

sub init {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { external_address_file => 0, } );

    # Initialize the defaults
    $self->{EXTERNAL_ADDRESS_FILE} = $defaults{external_address_file};

    # Override any
    $self->{EXTERNAL_ADDRESS_FILE} = $parameters->{external_address_file} if ( $parameters->{external_address_file} );

    my $res = $self->reset_state();
    if ( $res != 0 ) {
        return $res;
    }

    return 0;
}

=head2 save({ restart_services => 0 })
    Saves the configuration to disk. The dependent services can be restarted by
    specifying the "restart_services" parameter as 1. 
=cut

sub save {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { restart_services => 0, } );

    my $external_address_output = $self->generate_external_address_file();

    my ( $status, $res );

    $res = save_file( { file => $self->{EXTERNAL_ADDRESS_FILE}, content => $external_address_output } );
    if ( $res == -1 ) {
        return (-1, "Problem saving external address file");
    }

    return 0;
}

=head2 get_primary_address_mtu({})
Returns the mtu of the primary interface
=cut

sub get_primary_address_mtu {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my $ifcename = $self->get_primary_address_iface();
    my @all_ifs = Net::Interface->interfaces();
    foreach my $if (@all_ifs){
        if($if->name eq $ifcename  && $if->mtu){
          return $if->mtu;
        }
    }
 
    return 0;
}

=head2 get_primary_address({})
Returns the primary address for the toolkit
=cut

sub get_primary_address {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_ADDRESS};
}

=head2 get_primary_ipv4({})
Returns the primary IPv4 address for the toolkit
=cut

sub get_primary_ipv4 {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_IPV4};
}

=head2 get_primary_ipv6({})
Returns the primary IPv6 address for the toolkit
=cut

sub get_primary_ipv6 {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_IPV6};
}

=head2 get_primary_ipv6({})
Returns the speed of the primary interafce for the toolkit
=cut

sub get_primary_iface_speed {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_IFACE_SPEED};
}

=head2 get_primary_iface_mtu({})
Returns the mtu of the primary interface
=cut

sub get_primary_iface_mtu {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_IFACE_MTU};
}

=head2 set_primary_address({ address => 1 })
Sets the primary address for the toolkit
=cut

sub set_primary_address {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { address => 1, } );

    my $address = $parameters->{address};

    $self->{PRIMARY_ADDRESS} = $address;

    return 0;
}

=head2 set_primary_ipv4({ address => 1 })
Sets the primary IPv4 for the toolkit
=cut

sub set_primary_ipv4 {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { address => 1, } );

    my $address = $parameters->{address};

    $self->{PRIMARY_IPV4} = $address;

    return 0;
}

=head2 set_primary_ipv6({ address => 1 })
Sets the primary IPv6 for the toolkit
=cut

sub set_primary_ipv6 {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { address => 1, } );

    my $address = $parameters->{address};

    $self->{PRIMARY_IPV6} = $address;

    return 0;
}

=head2 get_primary_address_iface({})
Returns the primary interface for the toolkit
=cut

sub get_primary_address_iface {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_ADDRESS_IFACE};
}

=head2 get_primary_ipv4_iface({})
Returns the primary IPv4 interface for the toolkit
=cut

sub get_primary_ipv4_iface {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_IPV4_IFACE};
}

=head2 get_primary_ipv6_iface({})
Returns the primary IPv6 interface for the toolkit
=cut

sub get_primary_ipv6_iface {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    return $self->{PRIMARY_IPV6_IFACE};
}

=head2 set_primary_address_iface({ iface => 1 })
Sets the primary interface for the toolkit
=cut

sub set_primary_address_iface {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { iface => 1, } );

    my $iface = $parameters->{iface};

    $self->{PRIMARY_ADDRESS_IFACE} = $iface;

    return 0;
}

=head2 set_primary_ipv4_iface({ iface => 1 })
Sets the primary IPv4 interface for the toolkit
=cut

sub set_primary_ipv4_iface {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { iface => 1, } );

    my $iface = $parameters->{iface};

    $self->{PRIMARY_IPV4_IFACE} = $iface;

    return 0;
}

=head2 set_primary_ipv6_iface({ iface => 1 })
Sets the primary IPv6 interface for the toolkit
=cut

sub set_primary_ipv6_iface {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { iface => 1, } );

    my $iface = $parameters->{iface};

    $self->{PRIMARY_IPV6_IFACE} = $iface;

    return 0;
}

=head2 set_primary_iface_speed({ speed => 1 })
Sets the speed of the primary interface
=cut

sub set_primary_iface_speed {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { speed => 1, } );

    my $speed = $parameters->{speed};

    $self->{PRIMARY_IFACE_SPEED} = $speed;

    return 0;
}

=head2 set_primary_iface_mtu({ mtu => 1 })
Sets the mtu of the primary interface
=cut

sub set_primary_iface_mtu {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, { mtu => 1, } );

    my $mtu = $parameters->{mtu};

    $self->{PRIMARY_IFACE_MTU} = $mtu;

    return 0;
}


=head2 last_modified()
    Returns when the configuration was last saved.
=cut

sub last_modified {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my ($mtime) = (stat ( $self->{EXTERNAL_ADDRESS_FILE} ) )[9];

    return $mtime;
}

=head2 reset_state()
    Resets the state of the module to the state immediately after having run "init()".
=cut

sub reset_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my ( $status, $res ) = read_external_address_file( { file => $self->{EXTERNAL_ADDRESS_FILE} } );
    if ( $status == 0 ) {
        $self->{PRIMARY_IPV6}          = $res->{primary_ipv6};
        $self->{PRIMARY_IPV4}          = $res->{primary_ipv4};
        $self->{PRIMARY_ADDRESS}       = $res->{primary_address};
        $self->{PRIMARY_IPV6_IFACE}    = $res->{primary_ipv6_iface};
        $self->{PRIMARY_IPV4_IFACE}    = $res->{primary_ipv4_iface};
        $self->{PRIMARY_ADDRESS_IFACE} = $res->{primary_address_iface};
        $self->{PRIMARY_IFACE_SPEED}   = $res->{primary_iface_speed};
        $self->{PRIMARY_IFACE_MTU}   = $res->{primary_iface_mtu};
    }

    return 0;
}

=head2 read_external_address_file({ file => 1 })

Reads the external address file specified by the 'file' parameter. Returns (-1,
$error_msg) when an error occurs. Returns (0, \%hash) where hash has the keys
primary_ipv6, primary_ipv4 and primary_address.

=cut

sub read_external_address_file {
    my $parameters = validate( @_, { file => 1, } );

    unless ( open( EXTERNAL_ADDRESS_FILE, $parameters->{file} ) ) {
        my %info = ();
        return ( 0, \%info );
    }

    my $primary_address;
    my $primary_ipv4;
    my $primary_ipv6;
    my $primary_address_iface;
    my $primary_ipv4_iface;
    my $primary_ipv6_iface;
    my $primary_iface_speed;
    my $primary_iface_mtu;

    while ( <EXTERNAL_ADDRESS_FILE> ) {
        chomp;
        my ( $variable, $value ) = split( '=' );
        $value =~ s/^\s+//;
        $value =~ s/\s+$//;

        if ( $variable eq "default_accesspoint" ) {
            $primary_address = $value;
        }
        elsif ( $variable eq "default_ipv4_address" ) {
            $primary_ipv4 = $value;
        }
        elsif ( $variable eq "default_ipv6_address" ) {
            $primary_ipv6 = $value;
        }
        elsif ( $variable eq "default_accesspoint_iface" ) {
            $primary_address_iface = $value;
        }
        elsif ( $variable eq "default_ipv4_address_iface" ) {
            $primary_ipv4_iface = $value;
        }
        elsif ( $variable eq "default_ipv6_address_iface" ) {
            $primary_ipv6_iface = $value;
        }elsif ( $variable eq "default_iface_speed" ) {
            $primary_iface_speed = $value;
        }elsif ( $variable eq "default_iface_mtu" ) {
            $primary_iface_mtu = $value;
        }
    }

    close( EXTERNAL_ADDRESS_FILE );

    my %info = (
        primary_ipv6          => $primary_ipv6,
        primary_ipv4          => $primary_ipv4,
        primary_address       => $primary_address,
        primary_ipv6_iface    => $primary_ipv6_iface,
        primary_ipv4_iface    => $primary_ipv4_iface,
        primary_address_iface => $primary_address_iface,
        primary_iface_speed   => $primary_iface_speed,
        primary_iface_mtu   => $primary_iface_mtu,
    );

    return ( 0, \%info );
}

=head2 generate_external_address_file({})

Takes the internal set of addresses and creates a string representing the
"default_accesspoint" file.

=cut

sub generate_external_address_file {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    # The chosen names for this file are quite stupid, but retained for
    # backward compatibility.

    my $output = "";

    my $addr = $self->{PRIMARY_ADDRESS};
    $addr = "" unless ( $addr );

    my $ipv4_addr = $self->{PRIMARY_IPV4};
    $ipv4_addr = "" unless ( $ipv4_addr );

    my $ipv6_addr = $self->{PRIMARY_IPV6};
    $ipv6_addr = "" unless ( $ipv6_addr );

    my $addr_iface = $self->{PRIMARY_ADDRESS_IFACE};
    $addr_iface = "" unless ( $addr_iface );

    my $ipv4_addr_iface = $self->{PRIMARY_IPV4_IFACE};
    $ipv4_addr_iface = "" unless ( $ipv4_addr_iface );

    my $ipv6_addr_iface = $self->{PRIMARY_IPV6_IFACE};
    $ipv6_addr_iface = "" unless ( $ipv6_addr_iface );
    
    my $primary_iface_speed = $self->{PRIMARY_IFACE_SPEED};
    $primary_iface_speed = "" unless ( $primary_iface_speed );
    
    my $primary_iface_mtu = $self->{PRIMARY_IFACE_MTU};
    $primary_iface_mtu = "" unless ( $primary_iface_mtu );


    $output .= "external_address=" . $addr . "\n";
    $output .= "default_accesspoint=" . $addr . "\n";
    $output .= "default_ipv4_address=" . $ipv4_addr . "\n";
    $output .= "default_ipv6_address=" . $ipv6_addr . "\n";
    $output .= "default_accesspoint_iface=" . $addr_iface . "\n";
    $output .= "default_ipv4_address_iface=" . $ipv4_addr_iface . "\n";
    $output .= "default_ipv6_address_iface=" . $ipv6_addr_iface . "\n";
    $output .= "default_iface_speed=" . $primary_iface_speed . "\n";
    $output .= "default_iface_mtu=" . $primary_iface_mtu . "\n";
    
    return $output;
}

=head2 save_state()
    Saves the current state of the module as a string. This state allows the
    module to be recreated later.
=cut

sub save_state {
    my ( $self, @params ) = @_;
    my $parameters = validate( @params, {} );

    my %state = (
        primary_address      => $self->{PRIMARY_ADDRESS},
        primary_ipv4_address => $self->{PRIMARY_IPV4},
        primary_ipv6_address => $self->{PRIMARY_IPV6},
        primary_address_iface      => $self->{PRIMARY_ADDRESS_IFACE},
        primary_ipv4_address_iface => $self->{PRIMARY_IPV4_IFACE},
        primary_ipv6_address_iface => $self->{PRIMARY_IPV6_IFACE},
        primary_iface_speed        => $self->{PRIMARY_IFACE_SPEED},
        primary_iface_mtu        => $self->{PRIMARY_IFACE_MTU},
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

    $self->{PRIMARY_IPV6} = $state->{primary_ipv6};
    $self->{PRIMARY_IPV4} = $state->{primary_ipv4};
    $self->{PRIMARY_ADDRESS} = $state->{primary_address};
    $self->{PRIMARY_IPV6_IFACE} = $state->{primary_ipv6_iface};
    $self->{PRIMARY_IPV4_IFACE} = $state->{primary_ipv4_iface};
    $self->{PRIMARY_ADDRESS_IFACE} = $state->{primary_address_iface};
    $self->{PRIMARY_IFACE_SPEED} = $state->{primary_iface_speed};
    $self->{PRIMARY_IFACE_MTU} = $state->{primary_iface_mtu};
    
    $self->{LOGGER}->debug( "State: " . Dumper( $state ) );
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
