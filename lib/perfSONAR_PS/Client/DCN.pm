package perfSONAR_PS::Client::DCN;

use strict;
use warnings;

our $VERSION = 3.1;

use base 'perfSONAR_PS::Client::LS';
use fields 'CONF', 'LS_KEY';

=head1 NAME

perfSONAR_PS::Client::DCN

=head1 DESCRIPTION

Simple library to implement some perfSONAR calls that DCN tools will require.
The goal of this module is to provide some simple library calls that DCN
software may implement to receive information from perfSONAR deployments.

=cut

use Log::Log4perl qw( get_logger );
use Params::Validate qw( :all );
use Digest::MD5 qw( md5_hex );
use English qw( -no_match_vars );
use XML::LibXML;

use perfSONAR_PS::Common qw( genuid makeEnvelope find extract );
use perfSONAR_PS::Utils::ParameterValidation;
use perfSONAR_PS::Client::LS;

=head2 new($package { instance })

Constructor for object.  Optional argument of 'instance' is the LS instance
to be contacted for queries.  This can also be set via 'setInstance'.

=cut

sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { instance => 0 } );

    my $self = fields::new( $package );

    $self->{ALIVE}               = 0;
    $self->{CONF}                = ();
    $self->{CONF}->{serviceType} = "LS";
    $self->{CONF}->{serviceName} = "DCN LS";

    $self->{LOGGER} = get_logger( "perfSONAR_PS::Client::DCN" );
    if ( exists $parameters->{"instance"} and $parameters->{"instance"} ) {
        if ( $parameters->{"instance"} =~ m/^http:\/\// ) {
            $self->{INSTANCE}            = $parameters->{"instance"};
            $self->{CONF}->{accessPoint} = $parameters->{"instance"};
            $self->{LS_KEY}              = $self->getLSKey;
        }
        else {
            $self->{LOGGER}->error( "Instance must be of the form http://ADDRESS." );
        }
    }
    return $self;
}

=head2 setInstance($self { instance })

Required argument 'instance' is the LS instance to be contacted for queries.  

=cut

sub setInstance {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { instance => 1 } );

    $self->{ALIVE} = 0;
    if ( $parameters->{"instance"} =~ m/^http:\/\// ) {
        $self->{INSTANCE}            = $parameters->{"instance"};
        $self->{CONF}->{accessPoint} = $parameters->{"instance"};
        $self->{LS_KEY}              = $self->getLSKey;
    }
    else {
        $self->{LOGGER}->error( "Instance must be of the form http://ADDRESS." );
    }
    return;
}

=head2 getLSKey($self { })

Send an LSKeyRequest to the service to retrive the actual key value for the
registration of the 'DCN' service.

=cut

sub getLSKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    my $result = $self->keyRequestLS( { service => \%{ $self->{CONF} } } );
    if ( $result and exists $result->{key} and $result->{key} ) {
        return $result->{key};
    }
    else {
        $self->{LOGGER}->error( "Error in LSKeyRequest" );
        return;
    }
}

=head2 nameToId

Given a name (i.e. DNS 'hostname') return any matching link ids.

=cut

sub nameToId {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { name => 1 } );
    my @ids        = ();
    my $metadata   = q{};
    my %ns         = ( xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/" );

    my $q = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $q        .= "declare namespace nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\";\n";
    $q        .= "/nmwg:store[\@type=\"LSStore\"]/nmwg:data/nmwg:metadata/*[local-name()='subject']/nmtb:node[nmtb:address/text()=\"" . $parameters->{name} . "\"]\n";
    $metadata .= $self->queryWrapper( { query => $q } );

    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSQueryRequest", ns => \%ns, metadata => $metadata } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType and $eventType =~ m/^success/mx ) {
        my $links = find( $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 ), ".//nmtb:node/nmtb:relation[\@type=\"connectionLink\"]/nmtb:linkIdRef", 0 );
        if ( $links ) {
            foreach my $l ( $links->get_nodelist ) {
                my $value = extract( $l, 0 );
                push @ids, $value if $value;
            }
        }
        else {
            $self->{LOGGER}->error( "No link elements found in return: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
            return;
        }
    }
    else {
        $self->{LOGGER}->error( "EventType not found: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
    }
    return \@ids;
}

=head2 idToName

Given a link id return any matching names (i.e. DNS 'hostname').

=cut

sub idToName {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { id => 1 } );
    my @names      = ();
    my $metadata   = q{};
    my %ns         = ( xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/" );

    my $q = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $q        .= "declare namespace nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\";\n";
    $q        .= "/nmwg:store[\@type=\"LSStore\"]/nmwg:data/nmwg:metadata/*[local-name()='subject']/nmtb:node[nmtb:relation[\@type=\"connectionLink\"]/nmtb:linkIdRef[text()=\"" . $parameters->{id} . "\"]]\n";
    $metadata .= $self->queryWrapper( { query => $q } );

    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSQueryRequest", ns => \%ns, metadata => $metadata } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType and $eventType =~ m/^success/mx ) {
        my $hostnames = find( $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 ), ".//nmtb:node/nmtb:address[\@type=\"hostname\"]", 0 );
        if ( $hostnames ) {
            foreach my $hn ( $hostnames->get_nodelist ) {
                my $value = extract( $hn, 0 );
                push @names, $value if $value;
            }
        }
        else {
            $self->{LOGGER}->error( "No link elements found in return: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
            return;
        }
    }
    else {
        $self->{LOGGER}->error( "EventType not found: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
    }
    return \@names;
}

=head2 insert($self { id name })

Given an id AND a name, register this infomration to the LS instance.

=cut

sub insert {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { id => 1, name => 1 } );

    unless ( $self->{LS_KEY} ) {
        $self->{LS_KEY} = $self->getLSKey;
    }

    my %ns = (
        perfsonar => "http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/",
        psservice => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/",
        dcn       => "http://ggf.org/ns/nmwg/tools/dcn/2.0/",
        nmtb      => "http://ogf.org/schema/network/topology/base/20070828/"
    );

    my $metadata = q{};
    if ( exists $self->{LS_KEY} and $self->{LS_KEY} ) {
        $metadata = $self->createKey( { key => $self->{LS_KEY} } );
    }
    else {
        $metadata = $self->createService( { service => \%{ $self->{CONF} } } );
    }

    my @data = ();
    $data[0] = $self->createNode( { id => $parameters->{id}, name => $parameters->{name} } );
    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSRegisterRequest", ns => \%ns, metadata => $metadata, data => \@data } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return -1;
    }

    my $code  = extract( find( $msg, "./nmwg:metadata/nmwg:eventType",        1 ), 0 );
    my $datum = extract( find( $msg, "./nmwg:data/*[local-name()=\"datum\"]", 1 ), 0 );
    if ( $code and $code =~ m/success/xm ) {
        $self->{LOGGER}->info( $datum ) if $datum;
        if ( $datum and $datum =~ m/^\s*\[\d+\] Data elements/m ) {
            my $num = $datum;
            $num =~ s/^\[//xm;
            $num =~ s/\].*//xm;
            if ( $num > 0 ) {
                return 0;
            }
        }
        return -1;
    }
    $self->{LOGGER}->error( $datum ) if $datum;
    return -1;
}

=head2 remove($self { id name })

Given an id or a name, delete this specific info from the LS instance.

=cut

sub remove {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { id => 0, name => 0 } );

    unless ( $parameters->{id} or $parameters->{name} ) {
        $self->{LOGGER}->error( "Must supply either a name or id." );
        return -1;
    }
    unless ( $self->{LS_KEY} ) {
        $self->{LS_KEY} = $self->getLSKey;
    }
    if ( exists $self->{LS_KEY} and $self->{LS_KEY} ) {
        my %ns = (
            dcn  => "http://ggf.org/ns/nmwg/tools/dcn/2.0/",
            nmtb => "http://ogf.org/schema/network/topology/base/20070828/"
        );
        my @data = ();
        $data[0] = $self->createNode( { id => $parameters->{id}, name => $parameters->{name} } );
        my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSDeregisterRequest", metadata => $self->createKey( { key => $self->{LS_KEY} } ), data => \@data } ) } );

        unless ( $msg ) {
            $self->{LOGGER}->error( "Message element not found in return." );
            return -1;
        }
        my $code  = extract( find( $msg, "./nmwg:metadata/nmwg:eventType",        1 ), 0 );
        my $datum = extract( find( $msg, "./nmwg:data/*[local-name()=\"datum\"]", 1 ), 0 );
        if ( $code and $code =~ m/success/xm ) {
            $self->{LOGGER}->info( $datum ) if $datum;
            if ( $datum and $datum =~ m/^Removed/xm ) {
                my $num = $datum;
                $num =~ s/^Removed\s{1}\[//xm;
                $num =~ s/\].*//xm;
                if ( $num > 0 ) {
                    return 0;
                }
            }
            return -1;
        }
        else {
            $self->{LOGGER}->error( $datum ) if $datum;
            return -1;
        }
    }
    return -1;
}

=head2 getMappings($self, { })

Return all link id to hostname mappings in the LS.

=cut

sub getMappings {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );
    my @lookup = ();

    my %ns = ( xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/" );

    my $q = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $q .= "declare namespace nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\";\n";
    $q .= "/nmwg:store[\@type=\"LSStore\"]/nmwg:data/nmwg:metadata/*[local-name()='subject']/nmtb:node\n";
    my $metadata = $self->queryWrapper( { query => $q } );

    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSQueryRequest", ns => \%ns, metadata => $metadata } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType and $eventType =~ m/^success/mx ) {
        my $datum = find( $msg, ".//*[local-name()='datum']", 0 )->get_node( 1 );
        unless ( $datum ) {
            $self->{LOGGER}->error( "No name elements found in return." );
            return;
        }

        foreach my $n ( $datum->getChildrenByTagNameNS( "http://ogf.org/schema/network/topology/base/20070828/", "node" ) ) {
            my $address = extract( find( $n, "./nmtb:address", 1 ), 0 );
            my $link = extract( find( $n, "./nmtb:relation[\@type=\"connectionLink\"]/nmtb:linkIdRef", 1 ), 0 );
            push @lookup, [ $address, $link ];
        }
    }
    else {
        $self->{LOGGER}->error( "EventType not found: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
    }
    return \@lookup;
}

=head2 createNode($self { id name })

Construct a node given an id and a name.

=cut

sub createNode {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { id => 0, name => 0 } );

    unless ( $parameters->{id} or $parameters->{name} ) {
        $self->{LOGGER}->error( "Must supply either a name or id." );
        return -1;
    }

    my $id   = md5_hex( $parameters->{name} . $parameters->{id} );
    my $node = "  <nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"metadata." . $id . "\">\n";
    $node .= "      <dcn:subject xmlns:dcn=\"http://ggf.org/ns/nmwg/tools/dcn/2.0/\" id=\"subject." . $id . "\">\n";
    $node .= "        <nmtb:node xmlns:nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\" id=\"node." . $id . "\">\n";
    $node .= "          <nmtb:address type=\"hostname\">" . $parameters->{name} . "</nmtb:address>\n" if exists $parameters->{name} and $parameters->{name};
    if ( exists $parameters->{id} and $parameters->{id} ) {
        $node .= "          <nmtb:relation type=\"connectionLink\">\n";
        $node .= "            <nmtb:linkIdRef>" . $parameters->{id} . "</nmtb:linkIdRef>\n";
        $node .= "          </nmtb:relation>\n";
    }
    $node .= "        </nmtb:node>\n";
    $node .= "      </dcn:subject>\n";
    $node .= "      <nmwg:eventType>http://oscars.es.net/OSCARS</nmwg:eventType>\n";
    $node .= "    </nmwg:metadata>\n";

    return $node;
}

=head2 getTopologyKey($self { accessPoint serviceName serviceType serviceDescription })

Send an LSKeyRequest to the LS with some service information reguarding a
topology service.  The goal is to get a key, nothing will be returned on
failure.

=cut

sub getTopologyKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { accessPoint => 1, serviceName => 0, serviceType => 0, serviceDescription => 0 } );

    my %service = ();
    $service{accessPoint}        = $parameters->{accessPoint}        if $parameters->{accessPoint};
    $service{serviceName}        = $parameters->{serviceName}        if $parameters->{serviceName};
    $service{serviceType}        = $parameters->{serviceType}        if $parameters->{serviceType};
    $service{serviceDescription} = $parameters->{serviceDescription} if $parameters->{serviceDescription};

    my $result = $self->keyRequestLS( { service => \%service } );
    if ( $result and exists $result->{key} and $result->{key} ) {
        return $result->{key};
    }
    $self->{LOGGER}->error( "Key not found." );
    return;
}

=head2 getDomainKey($self { key })

Get the domain for a topology service given a key.

=cut

sub getDomainKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { key => 1 } );
    my @domains = ();

    my %ns = ( xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/" );
    my $q = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $q .= "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
    $q .= "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
    $q .= "declare namespace nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\";\n";
    $q .= "for \$metadata in /nmwg:store[\@type=\"LSStore\"]/nmwg:metadata\n";
    $q .= "  let \$metadata_id := \$metadata/\@id\n";
    $q .= "  let \$data := /nmwg:store[\@type=\"LSStore\"]/nmwg:data[\@metadataIdRef=\$metadata_id]\n";
    $q .= "  where \$metadata_id=\"" . $parameters->{key} . "\"\n";
    $q .= "  return \$data/nmwg:metadata/*[local-name()='subject']/nmtb:domain\n\n";
    my $metadata = $self->queryWrapper( { query => $q } );

    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSQueryRequest", ns => \%ns, metadata => $metadata } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType and $eventType =~ m/^success/mx ) {

        my $ds = find( $msg, "./nmwg:data/*[local-name()='datum']/nmtb:domain", 0 );
        if ( $ds ) {
            foreach my $d ( $ds->get_nodelist ) {
                my $value = $d->getAttribute( "id" );
                $value =~ s/urn:ogf:network:domain=//xm;
                push @domains, $value if $value;
            }
        }
        else {
            $self->{LOGGER}->error( "No domain elements found in return." );
            return;
        }
    }
    else {
        $self->{LOGGER}->error( "EventType not found: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
    }
    return \@domains;
}

=head2 getDomainService($self { accessPoint, serviceName, serviceType })

Get the domain of a topology service given service information

=cut

sub getDomainService {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { accessPoint => 1, serviceName => 0, serviceType => 0 } );
    my @domains = ();

    my %ns = ( xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/" );
    my $q = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $q .= "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
    $q .= "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
    $q .= "declare namespace nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\";\n\n";
    $q .= "for \$metadata in /nmwg:store[\@type=\"LSStore\"]/nmwg:metadata\n";
    $q .= "  let \$metadata_id := \$metadata/\@id\n";
    $q .= "  let \$data := /nmwg:store[\@type=\"LSStore\"]/nmwg:data[\@metadataIdRef=\$metadata_id]\n";
    $q .= "  where \$metadata/*[local-name()='subject']/*[local-name()='service']/*[local-name()='accessPoint' and text()=\"" . $parameters->{accessPoint} . "\"]\n";
    if ( exits $parameters->{serviceType} and $parameters->{serviceType} ) {
        $q .= "        and \$metadata/*[local-name()='subject']/*[local-name()='service']/*[local-name()='serviceType' and text()=\"" . $parameters->{serviceType} . "\"]\n";
    }
    if ( exists $parameters->{serviceName} and $parameters->{serviceName} ) {
        $q .= "        and \$metadata/*[local-name()='subject']/*[local-name()='service']/*[local-name()='serviceName' and text()=\"" . $parameters->{serviceName} . "\"]\n";
    }
    $q .= "  return \$data/nmwg:metadata/*[local-name()='subject']/nmtb:domain\n\n";
    my $metadata = $self->queryWrapper( { query => $q } );

    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSQueryRequest", ns => \%ns, metadata => $metadata } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType and $eventType =~ m/^success/mx ) {
        my $ds = find( $msg, "./nmwg:data/psservice:datum/nmtb:domain", 0 );
        if ( $ds ) {
            foreach my $d ( $ds->get_nodelist ) {
                my $value = $d->getAttribute( "id" );
                $value =~ s/urn:ogf:network:domain=//xm;
                push @domains, $value if $value;
            }
        }
        else {
            $self->{LOGGER}->error( "No domain elements found in return." );
            return;
        }
    }
    else {
        $self->{LOGGER}->error( "EventType not found: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
    }
    return \@domains;
}

=head2 getTopologyServices($self { domain })

Get the topology service instances that are registered with an LS.  The 
optional 'domain' parameter will return only TS instances that match a
particular domain string.

=cut

sub getTopologyServices {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { domain => 0 } );
    my %services = ();

    my %ns = ( xquery => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/" );
    my $q = "declare namespace nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\";\n";
    $q .= "declare namespace perfsonar=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/\";\n";
    $q .= "declare namespace psservice=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/\";\n";
    $q .= "declare namespace nmtb=\"http://ogf.org/schema/network/topology/base/20070828/\";\n";
    if ( exists $parameters->{domain} and $parameters->{domain} ) {
        $q .= "for \$data in /nmwg:store[\@type=\"LSStore\"]/nmwg:data[./nmwg:metadata/*[local-name()='subject']/nmtb:domain[\@id=\"urn:ogf:network:domain=" . $parameters->{domain} . "\"]]\n";
    }
    else {
        $q .= "for \$data in /nmwg:store[\@type=\"LSStore\"]/nmwg:data[./nmwg:metadata/*[local-name()='subject']/nmtb:domain]\n";
    }
    $q .= " let \$metadataidref := \$data/\@metadataIdRef\n";
    $q .= " let \$metadata := /nmwg:store[\@type=\"LSStore\"]/nmwg:metadata[\@id=\$metadataidref]\n";
    $q .= " return \$metadata/*[local-name()='subject']/*[local-name()='service']\n\n";
    my $metadata = $self->queryWrapper( { query => $q } );

    my $msg = $self->callLS( { message => $self->createLSMessage( { type => "LSQueryRequest", ns => \%ns, metadata => $metadata } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType and $eventType =~ m/^success/mx ) {
        my $ss = find( $msg, "./nmwg:data/psservice:datum/*[local-name()='service']", 0 );
        if ( $ss ) {
            foreach my $s ( $ss->get_nodelist ) {
                my $t1 = extract( find( $s, "./*[local-name()='accessPoint']", 1 ), 0 );
                if ( $t1 ) {
                    my %temp = ();
                    my $t2   = extract( find( $s, "./*[local-name()='serviceType']", 1 ), 0 );
                    my $t3   = extract( find( $s, "./*[local-name()='serviceName']", 1 ), 0 );
                    my $t4   = extract( find( $s, "./*[local-name()='serviceDescription']", 1 ), 0 );
                    $temp{"serviceType"}        = $t2 if $t2;
                    $temp{"serviceName"}        = $t3 if $t3;
                    $temp{"serviceDescription"} = $t4 if $t4;
                    $services{$t1} = \%temp;
                }
            }
        }
        else {
            $self->{LOGGER}->error( "No domain elements found in return." );
            return;
        }
    }
    else {
        $self->{LOGGER}->error( "EventType not found: " . $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "datum" )->get_node( 1 )->toString );
    }
    return \%services;
}

=head2 queryTS($self, { topology })

Given the name of a topology service, this performs a simple query to dump it's
contents.  The contents are XML, but returned in string form.  Check the
returned hash to see if an error occured.

=cut

sub queryTS {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { topology => 1 } );

    my $echo_service = perfSONAR_PS::Client::Echo->new( $parameters->{topology} );
    my ( $status, $res ) = $echo_service->ping();
    if ( $status == -1 ) {
        $self->{LOGGER}->error( "Ping to " . $parameters->{topology} . " failed: $res" );
        return;
    }

    my ( $host, $port, $endpoint ) = perfSONAR_PS::Transport::splitURI( $parameters->{topology} );
    unless ( $host and $port and $endpoint ) {
        $self->{LOGGER}->error( "Topology URI: \"" . $parameters->{topology} . "\" is malformed." );
        return;
    }
    my $sender = new perfSONAR_PS::Transport( $host, $port, $endpoint );
    unless ( $sender ) {
        $self->{LOGGER}->error( "TS could not be contaced." );
        return;
    }

    my $error = q{};
    my $responseContent = $sender->sendReceive( makeEnvelope( $self->createLSMessage( { type => "SetupDataRequest", metadata => "<nmwg:eventType>http://ggf.org/ns/nmwg/topology/query/all/20070809</nmwg:eventType>\n" } ) ), q{}, \$error );
    if ( $error ) {
        $self->{LOGGER}->error( "sendReceive failed: $error" );
        return;
    }

    my $msg    = q{};
    my $parser = XML::LibXML->new();
    if ( $responseContent and ( not $responseContent =~ m/^\d+/xm ) ) {
        my $doc = q{};
        eval { $doc = $parser->parse_string( $responseContent ); };
        if ( $EVAL_ERROR ) {
            $self->{LOGGER}->error( "Parser failed: " . $EVAL_ERROR );
        }
        else {
            $msg = $doc->getDocumentElement->getElementsByTagNameNS( "http://ggf.org/ns/nmwg/base/2.0/", "message" )->get_node( 1 );
        }
    }

    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }

    my %result = ();
    my $eventType = extract( find( $msg, "./nmwg:metadata/nmwg:eventType", 1 ), 0 );
    if ( $eventType ) {
        $result{"eventType"} = $eventType;
        if ( $eventType and $eventType eq "http://ggf.org/ns/nmwg/topology/query/all/20070809" ) {
            $result{"response"} = $msg->getChildrenByLocalName( "data" )->get_node( 1 )->getChildrenByLocalName( "topology" )->get_node( 1 )->toString;
        }
        else {
            $result{"response"} = extract( find( $msg, "./nmwg:data/nmwgr:datum", 1 ), 0 );
            unless ( $result{"response"} ) {
                $result{"response"} = extract( find( $msg, "./nmwg:data/nmwg:datum", 1 ), 0 );
            }
        }
    }
    return \%result;
}

=head2 queryWrapper($self { })

Given some XQuery/Xpath expression, insert this into a 'canned' subject/parameter/eventType for an LSQueryRequest

=cut

sub queryWrapper {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 0 } );

    my $query = "    <xquery:subject id=\"subject." . genuid() . "\" xmlns:xquery=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/\">\n";
    $query .= $parameters->{query};
    $query .= "    </xquery:subject>\n";
    $query .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0</nmwg:eventType>\n";
    $query .= "  <xquery:parameters id=\"parameters." . genuid() . "\" xmlns:xquery=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/service/lookup/xquery/1.0/\">\n";
    $query .= "    <nmwg:parameter name=\"lsOutput\">native</nmwg:parameter>\n";
    $query .= "  </xquery:parameters>\n";
    return $query;
}

1;

__END__

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use perfSONAR_PS::Client::DCN;

    my $dcn = new perfSONAR_PS::Client::DCN( { instance => "http://some.host.edu/perfSONAR_PS/services/LS" } );
    
    # 
    # or 
    # 
    # my $dcn = new perfSONAR_PS::Client::DCN;
    # $dcn->setInstance( { instance => "http://some.host.edu/perfSONAR_PS/services/LS" } );

    my $name = "some.hostname.edu";
    my $id = "urn:ogf:network:domain=some.info.about.this.link";

    # Get link id values given a host name
    # 
    my $ids = $dcn->nameToId({ name => $name });
    foreach my $i (@$ids) {
      print $name , "\t=\t" , $i , "\n";
    }
    
    # Get host names given link id values
    #
    my $names = $dcn->idToName( { id => $id } );
    foreach my $n (@$names) {
      print $id , "\t=\t" , $n , "\n";
    }

    # Insert a new entry into the LS given a host name and link id
    # 
    $code = $dcn->insert({ name => "test", id => "test" });
    print "Insert of \"test\" and \"test\" failed.\n" if($code == -1); 

    # Remove an entry from the LS given the host name and link id
    # 
    my $code = $dcn->remove({ name => "test", id => "test" });
    print "Removal of \"test\" and \"test\" failed.\n" if($code == -1);
       
    # Dump all of the nodes from the LS, returns a matrix in host name/link id
    # format.
    # 
    my $map = $dcn->getMappings;
    foreach my $m (@$map) {
      foreach my $value (@$m) {
        print $value , "\t";
      }
      print "\n";
    }    

    # The DCN module has associated 'registration' info to make it act like
    # a service.  This info will be registered with an LS, and will have a key
    # associated with it.  This call will get that key from the LS.
    # 
    my $key = $dcn->getLSKey;
    print "The DCN registration key is \"" , $key , "\".\n" if($key);

    # Like the previous call, get us the key for some other service.
    # 
    $key = $dcn->getTopologyKey({ accessPoint => "http://some.topology.service.edu:8080/perfSONAR_PS/services/topology" });
    print "Found key \"" , $key , "\" for topology service.\n" if($key);
    
    # Get the domain a particular topology service is responsible for given
    # the LS key that corresponds to the service
    # 
    my $domains = $dcn->getDomainKey({ key => "$key" });
    foreach my $d (@$domains) {
      print "Domain:\t" , $d , "\n";
    }

    # Get the domain a particular topology service is responsible for given
    # the service information of the service
    # 
    $domains = $dcn->getDomainService({ accessPoint => "http://some.topology.service.edu:8080/perfSONAR_PS/services/topology", serviceType => "MA" });
    foreach my $d (@$domains) {
      print "Domain:\t" , $d , "\n";
    }

    # Get the services that are responsible for a particular domain.  Returns
    # a hash reference to the structure.  Omit the 'domain' argument to simply
    # get ALL of the topology services in this LS.
    # 
    my $service = $dcn->getTopologyServices({ domain => "I2" });

    my $services = $dcn->getTopologyServices;
    foreach my $s (sort keys %$services) {
      print $s , "\n";
      foreach my $s2 (sort keys %{$services->{$s}}) {
        print "\t" , $s2 , " - " , $services->{$s}->{$s2} , "\n";

        # Dump the topology file
        # 

        my $topo = $dcn->queryTS( { topology => $s } );
        print "\t\t" , $topo->{eventType} , "\n" , $topo->{response} , "\n\n";
      }
      print "\n";
    }

    exit(1);
    
=head1 SEE ALSO

L<Log::Log4perl>, L<Params::Validate>, L<Digest::MD5>, L<English>,
L<XML::LibXML>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Utils::ParameterValidation>, L<perfSONAR_PS::Client::LS>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2009, Internet2 and the University of Delaware

All rights reserved.

=cut

