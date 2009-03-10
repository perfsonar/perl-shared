package perfSONAR_PS::Services::MA::perfSONARBUOY;

use base 'perfSONAR_PS::Services::Base';

use fields 'LS_CLIENT', 'NAMESPACES', 'METADATADB', 'LOGGER', 'RES';

use strict;
use warnings;

our $VERSION = 0.10;

=head1 NAME

perfSONAR_PS::Services::MA::perfSONARBUOY - perfSONAR-BUOY Measurement Archive

=head1 DESCRIPTION

A module that provides methods for the perfSONARBUOY MA.  perfSONARBUOY exposes
data formerly collected by the former AMI framework, including BWCTL and
OWAMP data.  This data is stored in a database backend (commonly MySQL).  The
webservices interface provided by this MA currently exposes iperf data collected
via BWCTL and OWAMP data.

This module, in conjunction with other parts of the perfSONAR-PS framework,
handles specific messages from interested actors in search of BWCTL/OWAMP data.
There are three major message types that this service can act upon:

 - MetadataKeyRequest     - Given some metadata about a specific measurement, 
                            request a re-playable 'key' to faster access
                            underlying data.
 - SetupDataRequest       - Given either metadata or a key regarding a specific
                            measurement, retrieve data values.
 - MetadataStorageRequest - Store data into the archive (unsupported)
 
The module is capable of dealing with several characteristic and tool based
eventTypes related to the underlying data as well as the aforementioned message
types.  

=cut

use Log::Log4perl qw(get_logger);
use Module::Load;
use Digest::MD5 qw(md5_hex);
use English qw( -no_match_vars );
use Params::Validate qw(:all);
use Sys::Hostname;
use Fcntl ':flock';
use Date::Manip;
use Math::BigInt;

use perfSONAR_PS::Config::OWP;
use perfSONAR_PS::Config::OWP::Utils;
use perfSONAR_PS::Services::MA::General;
use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Client::LS::Remote;
use perfSONAR_PS::Error_compat qw/:try/;
use perfSONAR_PS::DB::File;
use perfSONAR_PS::DB::SQL;
use perfSONAR_PS::Utils::ParameterValidation;

my %ma_namespaces = (
    nmwg      => "http://ggf.org/ns/nmwg/base/2.0/",
    nmtm      => "http://ggf.org/ns/nmwg/time/2.0/",
    ifevt     => "http://ggf.org/ns/nmwg/event/status/base/2.0/",
    iperf     => "http://ggf.org/ns/nmwg/tools/iperf/2.0/",
    bwctl     => "http://ggf.org/ns/nmwg/tools/bwctl/2.0/",
    owd       => "http://ggf.org/ns/nmwg/characteristic/delay/one-way/20070914/",
    summary   => "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921/",
    owamp     => "http://ggf.org/ns/nmwg/tools/owamp/2.0/",
    select    => "http://ggf.org/ns/nmwg/ops/select/2.0/",
    average   => "http://ggf.org/ns/nmwg/ops/average/2.0/",
    perfsonar => "http://ggf.org/ns/nmwg/tools/org/perfsonar/1.0/",
    psservice => "http://ggf.org/ns/nmwg/tools/org/perfsonar/service/1.0/",
    nmwgt     => "http://ggf.org/ns/nmwg/topology/2.0/",
    nmwgtopo3 => "http://ggf.org/ns/nmwg/topology/base/3.0/",
    nmtb      => "http://ogf.org/schema/network/topology/base/20070828/",
    nmtl2     => "http://ogf.org/schema/network/topology/l2/20070828/",
    nmtl3     => "http://ogf.org/schema/network/topology/l3/20070828/",
    nmtl4     => "http://ogf.org/schema/network/topology/l4/20070828/",
    nmtopo    => "http://ogf.org/schema/network/topology/base/20070828/",
    nmtb      => "http://ogf.org/schema/network/topology/base/20070828/",
    nmwgr     => "http://ggf.org/ns/nmwg/result/2.0/"
);

=head2 init($self, $handler)

Called at startup by the daemon when this particular module is loaded into
the perfSONAR-PS deployment.  Checks the configuration file for the necessary
items and fills in others when needed. Initializes the backed metadata storage
(DBXML or a simple XML file) and builds the internal 'key hash' for the 
MetadataKey exchanges.  Finally the message handler loads the appropriate 
message types and eventTypes for this module.  Any other 'pre-startup' tasks
should be placed in this function.

Due to performance issues, the database access must be handled in two different
ways:

 - File Database - it is expensive to continuously open the file and store it as
                   a DOM for each access.  Therefore it is opened once by the
                   daemon and used by each connection.  A $self object can
                   be used for this.
 - XMLDB - File handles are opened and closed for each connection.

=cut

sub init {
    my ( $self, $handler ) = @_;
    $self->{LOGGER} = get_logger("perfSONAR_PS::Services::MA::perfSONARBUOY");

    unless ( exists $self->{CONF}->{"root_hints_url"} ) {
        $self->{CONF}->{"root_hints_url"} = "http://www.perfsonar.net/gls.root.hints";
        $self->{LOGGER}->warn("gLS Hints file not set, using default at \"http://www.perfsonar.net/gls.root.hints\".");
    }

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"legacy"} ) {
        $self->{LOGGER}->warn("Setting value for 'legacy' to 0");
        $self->{CONF}->{"perfsonarbuoy"}->{"legacy"} = 0;
    }

    if ( exists $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} and $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} and -d $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} )
    {
        if ( exists $self->{DIRECTORY} and $self->{DIRECTORY} and -d $self->{DIRECTORY} ) {
            unless ( $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} =~ "^/" ) {
                $self->{LOGGER}->warn("Setting value for 'owmesn' to \"" . $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} . "\"");                
                $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"};
            }
        }
        else {
            $self->{LOGGER}->fatal("Value for 'owmesh' is not set.");
            return -1;            
        }
    }
    else {
        $self->{LOGGER}->fatal("Value for 'owmesh' is not set.");
        return -1;
    }

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"}
        and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} )
    {
        $self->{LOGGER}->fatal("Value for 'metadata_db_type' is not set.");
        return -1;
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} )
        {
            $self->{LOGGER}->fatal("Value for 'metadata_db_file' is not set.");
            return -1;
        }
        else {
            if ( exists $self->{DIRECTORY} and $self->{DIRECTORY} and -d $self->{DIRECTORY} ) {
                unless ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} =~ "^/" ) {
                    $self->{LOGGER}->warn("Setting value for \"metadata_db_file\" to \"" . $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} . "\"" );
                    $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
                }
            }
            else {
                $self->{LOGGER}->fatal("Cannot set value for \"metadata_db_type\".");
                return -1;
            }
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        eval { 
            load perfSONAR_PS::DB::XMLDB; 
        };
        if ($EVAL_ERROR) {
            $self->{LOGGER}->fatal("Couldn't load perfSONAR_PS::DB::XMLDB: $EVAL_ERROR");
            return -1;
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} )
        {
            $self->{LOGGER}->warn("Value for 'metadata_db_file' is not set, setting to 'psbstore.dbxml'.");
            $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} = "psbstore.dbxml";
        }

        if ( exists $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} )
        {
            if ( defined $self->{DIRECTORY} ) {
                unless ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} =~ "^/" ) {
                    $self->{LOGGER}->warn( "Setting the value of \"\" to \"" . $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} . "\"" );
                    $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} = $self->{DIRECTORY} . "/" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"};
                }
            }
            unless ( -d $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} ) {
                $self->{LOGGER}->warn( "Creating \"" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} . "\" for the \"metadata_db_name\"" );
                system( "mkdir " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} );
            }
        }
        else {
            $self->{LOGGER}->fatal("Value for 'metadata_db_name' is not set.");
            return -1;
        }
    }
    else {
        $self->{LOGGER}->fatal("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} ) {
        $self->{LOGGER}->warn( "Setting \"enable_registration\" to \"" . $self->{CONF}->{enable_registration} . "\" for legacy reasons." );
        $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} = $self->{CONF}->{enable_registration};
    }

    unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} ) {
        if ( exists $self->{CONF}->{enable_registration} and $self->{CONF}->{enable_registration} ) {
            $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} = $self->{CONF}->{enable_registration};
        }
        else {
            $self->{CONF}->{enable_registration} = 0;
            $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} = 0;
        }
        $self->{LOGGER}->warn( "Setting 'enable_registration' to \"" . $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} . "\"." );
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"enable_registration"} ) {
        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"} )
        {
            if ( defined $self->{CONF}->{"ls_instance"}
                and $self->{CONF}->{"ls_instance"} )
            {
                $self->{LOGGER}->warn( "Setting \"ls_instance\" to \"" . $self->{CONF}->{"ls_instance"} . "\"" );
                $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"} = $self->{CONF}->{"ls_instance"};
            }
            else {
                $self->{LOGGER}->warn("No LS instance specified for pSB service");
            }
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"} )
        {
            if ( defined $self->{CONF}->{"ls_registration_interval"}
                and $self->{CONF}->{"ls_registration_interval"} )
            {
                $self->{LOGGER}->warn( "Setting \"ls_registration_interval\" to \"" . $self->{CONF}->{"ls_registration_interval"} . "\"" );
                $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"} = $self->{CONF}->{"ls_registration_interval"};
            }
            else {
                $self->{LOGGER}->warn("Setting registration interval to 4 hours");
                $self->{CONF}->{"perfsonarbuoy"}->{"ls_registration_interval"} = 14400;
            }
        }

        if ( not $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"} ) {
            unless ( $self->{CONF}->{external_address} ) {
                $self->{LOGGER}->fatal("With LS registration enabled, you need to specify either the service accessPoint for the service or the external_address");
                return -1;
            }
            $self->{LOGGER}->info( "Setting service access point to http://" . $self->{CONF}->{external_address} . ":" . $self->{PORT} . $self->{ENDPOINT} );
            $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"} = "http://" . $self->{CONF}->{external_address} . ":" . $self->{PORT} . $self->{ENDPOINT};
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_description"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_description"} )
        {
            my $description = "perfSONAR_PS perfSONAR-BUOY MA";
            if ( $self->{CONF}->{site_name} ) {
                $description .= " at " . $self->{CONF}->{site_name};
            }
            if ( $self->{CONF}->{site_location} ) {
                $description .= " in " . $self->{CONF}->{site_location};
            }
            $self->{CONF}->{"perfsonarbuoy"}->{"service_description"} = $description;
            $self->{LOGGER}->warn("Setting 'service_description' to '$description'.");
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_name"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_name"} )
        {
            $self->{CONF}->{"perfsonarbuoy"}->{"service_name"} = "perfSONAR-BUOY MA";
            $self->{LOGGER}->warn("Setting 'service_name' to 'perfSONAR-BUOY MA'.");
        }

        unless ( exists $self->{CONF}->{"perfsonarbuoy"}->{"service_type"}
            and $self->{CONF}->{"perfsonarbuoy"}->{"service_type"} )
        {
            $self->{CONF}->{"perfsonarbuoy"}->{"service_type"} = "MA";
            $self->{LOGGER}->warn("Setting 'service_type' to 'MA'.");
        }
    }

    $handler->registerMessageHandler( "SetupDataRequest",   $self );
    $handler->registerMessageHandler( "MetadataKeyRequest", $self );

    my $error = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        unless ( $self->createStorage( {} ) == 0 ) {
            $self->{LOGGER}->fatal("Couldn't load the store file - service cannot start");
            return -1;
        }
        $self->{METADATADB} = new perfSONAR_PS::DB::File( { file => $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} } );
        $self->{METADATADB}->openDB( { error => \$error } );
        unless ( $self->{METADATADB} ) {
            $self->{LOGGER}->fatal("Couldn't initialize store file: $error");
            return -1;
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        my $error      = q{};
        my $metadatadb = $self->prepareDatabases;
        unless ($metadatadb) {
            $self->{LOGGER}->fatal( "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
            return -1;
        }

        unless ( $self->createStorage( { metadatadb => $metadatadb } ) == 0 ) {
            $self->{LOGGER}->fatal("Couldn't load the XMLDB - service cannot start");
            return -1;
        }

        $metadatadb->closeDB( { error => \$error } );
        $self->{METADATADB} = q{};
    }
    else {
        $self->{LOGGER}->fatal("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    return 0;
}

=head2 createStorage($self { metadatadb } )

Given the information in the AMI databases, construct appropriate metadata
structures into either a file or the XMLDB.  This allows us to maintain the 
query mechanisms as defined by the other services.  Also performs the steps
necessary for building the 'key' cache that will speed up access to the data
by providing a fast handle that points directly to a key.

=cut

sub createStorage {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { metadatadb => 0 } );

    my %defaults = (
        DBHOST  => "localhost",
        CONFDIR => $self->{CONF}->{"perfsonarbuoy"}->{"owmesh"}
    );
    my $conf = new perfSONAR_PS::Config::OWP::Conf(%defaults);

    my $error     = q{};
    my $errorFlag = 0;
    my $dbTr      = q{};

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        unless ( exists $parameters->{metadatadb} and $parameters->{metadatadb} ) {
            $parameters->{metadatadb} = $self->prepareDatabases;
            unless ( exists $parameters->{metadatadb} and $parameters->{metadatadb} ) {
                $self->{LOGGER}->fatal( "There was an error opening \"" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
                return -1;
            }
        }

        $dbTr = $parameters->{metadatadb}->getTransaction( { error => \$error } );
        unless ( $dbTr ) {
            $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
            undef $dbTr;
            $self->{LOGGER}->fatal( "Database error: \"" . $error . "\", aborting." );
            return -1;
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        my $fh = new IO::File "> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
        if ( defined $fh ) {
            print $fh "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n";
            print $fh "<nmwg:store xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"\n";
            print $fh "            xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\"\n";
            print $fh "            xmlns:owamp=\"http://ggf.org/ns/nmwg/tools/owamp/2.0/\"\n";
            print $fh "            xmlns:owd=\"http://ggf.org/ns/nmwg/characteristic/delay/one-way/20070914/\"\n";
            print $fh "            xmlns:summary=\"http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921/\"\n";
            print $fh "            xmlns:bwctl=\"http://ggf.org/ns/nmwg/tools/bwctl/2.0/\"\n";
            print $fh "            xmlns:iperf= \"http://ggf.org/ns/nmwg/tools/iperf/2.0/\">\n\n";
            $fh->close;
        }
        else {
            $self->{LOGGER}->fatal("File cannot be written.");
            return -1;
        }
    }
    else {
        $self->{LOGGER}->fatal("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    my $dbsourceBW = $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBTYPE" } ) . ":" . $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBNAME" } ) . ":" . $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBHOST" } );
    my $dbuserBW   = $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBUSER" } );
    my $dbpassBW   = $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBPASS" } );

    my $dbsourceOWP = $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBTYPE" } ) . ":" . $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBNAME" } ) . ":" . $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBHOST" } );
    my $dbuserOWP   = $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBUSER" } );
    my $dbpassOWP   = $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBPASS" } );

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"legacy"} ) {

        # BWCTL Database

        my @dbSchema_nodesBW = ( "node_id", "node_name", "uptime_addr", "uptime_port" );
        my @dbSchema_meshesBW = ( "mesh_id", "mesh_name", "mesh_desc", "tool_name", "addr_type" );
        my @dbSchema_node_mesh_mapBW = ( "mesh_id", "node_id" );
        my $dbBW = new perfSONAR_PS::DB::SQL( { name => $dbsourceBW, schema => \@dbSchema_nodesBW, user => $dbuserBW, pass => $dbpassBW } );
        my $result = $dbBW->openDB;

        if ( $result == -1 ) {
            $self->{LOGGER}->info( "\"" . hostname() . "\" failed...trying \"localhost\"." );
            $dbsourceBW = $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBTYPE" } ) . ":" . $self->confHierarchy( { conf => $conf, type => "BW", variable => "DBNAME" } ) . ":localhost";
            $dbBW = new perfSONAR_PS::DB::SQL( { name => $dbsourceBW, schema => \@dbSchema_nodesBW, user => $dbuserBW, pass => $dbpassBW } );
            $result = $dbBW->openDB;
        }

        my $result_nodesBW;
        my $result_meshesBW;
        my $result_node_mesh_mapBW;
        my %nodesBW  = ();
        my %meshesBW = ();
        my $data_len;
        if ( $result == 0 ) {
            $result_nodesBW = $dbBW->query( { query => "select * from nodes" } );
            %nodesBW        = ();
            $data_len       = $#{$result_nodesBW};
            for my $x ( 0 .. $data_len ) {
                my $data_len2 = $#{ $result_nodesBW->[$x] };
                my %temp      = ();
                for my $z ( 1 .. $data_len2 ) {
                    $temp{ $dbSchema_nodesBW[$z] } = $result_nodesBW->[$x][$z];
                }
                $nodesBW{ $x + 1 } = \%temp;
            }

            $dbBW->setSchema( { schema => \@dbSchema_meshesBW } );
            $result_meshesBW = $dbBW->query( { query => "select * from meshes" } );
            %meshesBW        = ();
            $data_len        = $#{$result_meshesBW};
            for my $x ( 0 .. $data_len ) {
                my $data_len2 = $#{ $result_meshesBW->[$x] };
                my %temp      = ();
                for my $z ( 1 .. $data_len2 ) {
                    $temp{ $dbSchema_meshesBW[$z] } = $result_meshesBW->[$x][$z];
                }
                $meshesBW{ $x + 1 } = \%temp;
            }

            $dbBW->setSchema( { schema => \@dbSchema_node_mesh_mapBW } );
            $result_node_mesh_mapBW = $dbBW->query( { query => "select * from node_mesh_map" } );
            $dbBW->closeDB;

            if ( $#{$result_nodesBW} == -1 or $#{$result_meshesBW} == -1 or $#{$result_node_mesh_mapBW} == -1 ) {
                $self->{LOGGER}->fatal("BW Database query returned 0 results, cannot make store file aborting.");
                return -1;
            }
        }

        # ------------------------------------------------------------------------------
        # ------------------------------------------------------------------------------

        # OWAMP Database

        my @dbSchema_nodesOWP = ( "node_id", "node_name", "uptime_addr", "uptime_port" );
        my @dbSchema_meshesOWP = ( "mesh_id", "mesh_name", "mesh_desc", "tool_name", "addr_type", "session_duration" );
        my $dbOWP = new perfSONAR_PS::DB::SQL( { name => $dbsourceOWP, schema => \@dbSchema_nodesOWP, user => $dbuserOWP, pass => $dbpassOWP } );
        $result = $dbOWP->openDB;

        if ( $result == -1 ) {
            $self->{LOGGER}->info( "\"" . hostname() . "\" failed...trying \"localhost\"." );
            $dbsourceOWP = $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBTYPE" } ) . ":" . $self->confHierarchy( { conf => $conf, type => "OWP", variable => "DBNAME" } ) . ":localhost";
            $dbOWP = new perfSONAR_PS::DB::SQL( { name => $dbsourceOWP, schema => \@dbSchema_nodesOWP, user => $dbuserOWP, pass => $dbpassOWP } );
            $result = $dbOWP->openDB;
        }

        my $result_nodesOWP;
        my $result_meshesOWP;
        my %nodesOWP  = ();
        my %meshesOWP = ();
        if ( $result == 0 ) {
            $result_nodesOWP = $dbOWP->query( { query => "select * from nodes" } );
            %nodesOWP        = ();
            $data_len        = $#{$result_nodesOWP};
            for my $x ( 0 .. $data_len ) {
                my $data_len2 = $#{ $result_nodesOWP->[$x] };
                my %temp      = ();
                for my $z ( 1 .. $data_len2 ) {
                    $temp{ $dbSchema_nodesOWP[$z] } = $result_nodesOWP->[$x][$z];
                }
                $nodesOWP{ $x + 1 } = \%temp;
            }

            $dbOWP->setSchema( { schema => \@dbSchema_meshesOWP } );
            $result_meshesOWP = $dbOWP->query( { query => "select * from meshes" } );
            %meshesOWP        = ();
            $data_len         = $#{$result_meshesOWP};
            for my $x ( 0 .. $data_len ) {
                my $data_len2 = $#{ $result_meshesOWP->[$x] };
                my %temp      = ();
                for my $z ( 1 .. $data_len2 ) {
                    $temp{ $dbSchema_meshesOWP[$z] } = $result_meshesOWP->[$x][$z];
                }
                $meshesOWP{ $x + 1 } = \%temp;
            }

            my @dbSchema_resOWP = ( "res", "description", "save_period", "plot_period", "plot_period_desc" );
            $dbOWP->setSchema( { schema => \@dbSchema_resOWP } );
            my $result_resOWP = $dbOWP->query( { query => "select * from resolutions" } );
            $data_len = $#{$result_resOWP};
            for my $x ( 0 .. $data_len ) {
                $self->{RES}->{ $result_resOWP->[$x][0] } = 1;
            }

            $dbOWP->closeDB;

            if ( $#{$result_nodesOWP} == -1 or $#{$result_meshesOWP} == -1 ) {
                $self->{LOGGER}->fatal("OWP Database query returned 0 results, cannot make store file, aborting.");
                return -1;
            }
        }

        my $id = 1;
        $data_len = $#{$result_meshesOWP};
        my $data_len2 = $#{$result_nodesOWP};
        for my $x ( 0 .. $data_len ) {
            for my $y ( 0 .. $data_len2 ) {
                for my $z ( 0 .. $data_len2 ) {

                    next if not( $conf->{ "NODE-" . $result_nodesOWP->[$y][1] }->{ $meshesOWP{ $x + 1 }->{"addr_type"} } ) or not( $conf->{ "NODE-" . $result_nodesOWP->[$z][1] }->{ $meshesOWP{ $x + 1 }->{"addr_type"} } );

                    my $metadata = q{};
                    $metadata = "<nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"metadata-" . $id . "\">\n";
                    $metadata .= "    <owamp:subject xmlns:owamp=\"http://ggf.org/ns/nmwg/tools/owamp/2.0/\" id=\"subject-" . $id . "\">\n";
                    $metadata .= "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";
                    if (   $meshesOWP{ $x + 1 }->{"addr_type"} eq "LAT6"
                        or $meshesOWP{ $x + 1 }->{"addr_type"} eq "LATV6" )
                    {
                        $metadata .= "        <nmwgt:src type=\"ipv6\" value=\"" . $conf->{ "NODE-" . $result_nodesOWP->[$y][1] }->{ $meshesOWP{ $x + 1 }->{"addr_type"} . "ADDR" } . "\" />\n";
                        $metadata .= "        <nmwgt:dst type=\"ipv6\" value=\"" . $conf->{ "NODE-" . $result_nodesOWP->[$z][1] }->{ $meshesOWP{ $x + 1 }->{"addr_type"} . "ADDR" } . "\" />\n";
                    }
                    else {
                        $metadata .= "        <nmwgt:src type=\"ipv4\" value=\"" . $conf->{ "NODE-" . $result_nodesOWP->[$y][1] }->{ $meshesOWP{ $x + 1 }->{"addr_type"} . "ADDR" } . "\" />\n";
                        $metadata .= "        <nmwgt:dst type=\"ipv4\" value=\"" . $conf->{ "NODE-" . $result_nodesOWP->[$z][1] }->{ $meshesOWP{ $x + 1 }->{"addr_type"} . "ADDR" } . "\" />\n";
                    }
                    $metadata .= "      </nmwgt:endPointPair>\n";
                    $metadata .= "    </owamp:subject>\n";
                    $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/owamp/2.0</nmwg:eventType>\n";
                    $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921</nmwg:eventType>\n";
                    $metadata .= "  </nmwg:metadata>";

                    my $data = q{};
                    $data = "<nmwg:data xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"data-" . $id . "\" metadataIdRef=\"metadata-" . $id . "\">\n";
                    $data .= "    <nmwg:key id=\"key-" . $id . "\">\n";
                    $data .= "      <nmwg:parameters id=\"parameters-key-" . $id . "\">\n";
                    $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/tools/owamp/2.0</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"type\">mysql</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"db\">" . $dbsourceOWP . "</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"user\">" . $dbuserOWP . "</nmwg:parameter>\n" if $dbuserOWP;
                    $data .= "        <nmwg:parameter name=\"pass\">" . $dbpassOWP . "</nmwg:parameter>\n" if $dbpassOWP;
                    $data .= "        <nmwg:parameter name=\"table\">" . "OWP_" . $meshesOWP{ $x + 1 }->{"mesh_name"} . "_" . $nodesOWP{ $y + 1 }->{"node_name"} . "_" . $nodesOWP{ $z + 1 }->{"node_name"} . "</nmwg:parameter>\n";
                    $data .= "      </nmwg:parameters>\n";
                    $data .= "    </nmwg:key>\n";
                    $data .= "  </nmwg:data>";

                    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
                        my $dHash  = md5_hex($data);
                        my $mdHash = md5_hex($metadata);
                        $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $metadata, type => "MAStore" } ), name => $mdHash, txn => $dbTr, error => \$error } );
                        $errorFlag++ if $error;
                        $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $data, type => "MAStore" } ), name => $dHash, txn => $dbTr, error => \$error } );
                        $errorFlag++ if $error;

                        $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                        $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                        $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                    }
                    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
                        my $fh = new IO::File ">> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
                        if ( defined $fh ) {
                            print $fh $metadata . "\n" . $data . "\n";
                            $fh->close;
                        }
                        else {
                            $self->{LOGGER}->fatal("File handle not defined, cannot be written.");
                            return -1;
                        }

                        my $dHash = md5_hex($data);
                        $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                        $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                        $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                    }
                    $id++;
                }
            }
        }

        $data_len = $#{$result_node_mesh_mapBW};
        for my $x ( 0 .. $data_len ) {
            for my $y ( 0 .. $data_len ) {
                if (    $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} eq $meshesBW{ $result_node_mesh_mapBW->[$y][0] }->{"mesh_name"}
                    and $nodesBW{ $result_node_mesh_mapBW->[$x][1] }->{"node_name"} ne $nodesBW{ $result_node_mesh_mapBW->[$y][1] }->{"node_name"} )
                {
                    my $metadata = q{};
                    $metadata = "<nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"metadata-" . $id . "\">\n";
                    $metadata .= "    <iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0/\" id=\"subject-" . $id . "\">\n";
                    $metadata .= "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";
                    if ( $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"addr_type"} eq "BWV6" ) {
                        $metadata .= "        <nmwgt:src type=\"ipv6\" value=\"" . $conf->{ "NODE-" . $nodesBW{ $result_node_mesh_mapBW->[$x][1] }->{"node_name"} }->{"BW6ADDR"} . "\" />\n";
                        $metadata .= "        <nmwgt:dst type=\"ipv6\" value=\"" . $conf->{ "NODE-" . $nodesBW{ $result_node_mesh_mapBW->[$y][1] }->{"node_name"} }->{"BW6ADDR"} . "\" />\n";
                    }
                    else {
                        $metadata .= "        <nmwgt:src type=\"ipv4\" value=\"" . $conf->{ "NODE-" . $nodesBW{ $result_node_mesh_mapBW->[$x][1] }->{"node_name"} }->{"BW4ADDR"} . "\" />\n";
                        $metadata .= "        <nmwgt:dst type=\"ipv4\" value=\"" . $conf->{ "NODE-" . $nodesBW{ $result_node_mesh_mapBW->[$y][1] }->{"node_name"} }->{"BW4ADDR"} . "\" />\n";
                    }
                    $metadata .= "      </nmwgt:endPointPair>\n";
                    $metadata .= "    </iperf:subject>\n";
                    $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/iperf/2.0</nmwg:eventType>\n";
                    $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0</nmwg:eventType>\n";
                    $metadata .= "    <nmwg:parameters id=\"parameters-" . $id . "\">\n";

                    if ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWWINDOWSIZE"} ) {
                        $metadata .= "      <nmwg:parameter name=\"windowSize\">" . $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWWINDOWSIZE"} . "</nmwg:parameter>\n";
                    }
                    elsif ( $conf->{"BWWINDOWSIZE"} ) {
                        $metadata .= "      <nmwg:parameter name=\"windowSize\">" . $conf->{"BWWINDOWSIZE"} . "</nmwg:parameter>\n";
                    }

                    if ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWBUFFERLEN"} ) {
                        $metadata .= "      <nmwg:parameter name=\"bufferLength\">" . $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWBUFFERLEN"} . "</nmwg:parameter>\n";
                    }
                    elsif ( $conf->{"BWBUFFERLEN"} ) {
                        $metadata .= "      <nmwg:parameter name=\"bufferLength\">" . $conf->{"BWBUFFERLEN"} . "</nmwg:parameter>\n";
                    }

                    if ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWTESTDURATION"} ) {
                        $metadata .= "      <nmwg:parameter name=\"timeDuration\">" . $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWTESTDURATION"} . "</nmwg:parameter>\n";
                    }
                    elsif ( $conf->{"BWTESTDURATION"} ) {
                        $metadata .= "      <nmwg:parameter name=\"timeDuration\">" . $conf->{"BWTESTDURATION"} . "</nmwg:parameter>\n";
                    }

                    if ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWREPORTINTERVAL"} ) {
                        $metadata .= "      <nmwg:parameter name=\"interval\">" . $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWREPORTINTERVAL"} . "</nmwg:parameter>\n";
                    }
                    elsif ( $conf->{"BWREPORTINTERVAL"} ) {
                        $metadata .= "      <nmwg:parameter name=\"interval\">" . $conf->{"BWREPORTINTERVAL"} . "</nmwg:parameter>\n";
                    }

                    if ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWUDP"} ) {
                        $metadata .= "      <nmwg:parameter name=\"protocol\">UDP</nmwg:parameter>\n";
                        $metadata .= "      <nmwg:parameter name=\"bandwidthLimit\">" . $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWUDPBANDWIDTHLIMIT"} . "</nmwg:parameter>\n"
                            if ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWUDPBANDWIDTHLIMIT"} );
                    }
                    elsif ( $conf->{ "MESH-" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} }->{"BWTCP"} ) {
                        $metadata .= "      <nmwg:parameter name=\"protocol\">TCP</nmwg:parameter>\n";
                    }

                    $metadata .= "    </nmwg:parameters>\n";
                    $metadata .= "  </nmwg:metadata>";

                    my $data = q{};
                    $data = "<nmwg:data xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"data-" . $id . "\" metadataIdRef=\"metadata-" . $id . "\">\n";
                    $data .= "    <nmwg:key id=\"key-" . $id . "\">\n";
                    $data .= "      <nmwg:parameters id=\"parameters-key-" . $id . "\">\n";
                    $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/tools/iperf/2.0</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"type\">mysql</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"db\">" . $dbsourceBW . "</nmwg:parameter>\n";
                    $data .= "        <nmwg:parameter name=\"user\">" . $dbuserBW . "</nmwg:parameter>\n" if $dbuserBW;
                    $data .= "        <nmwg:parameter name=\"pass\">" . $dbpassBW . "</nmwg:parameter>\n" if $dbpassBW;
                    $data
                        .= "        <nmwg:parameter name=\"table\">" . "BW_" . $meshesBW{ $result_node_mesh_mapBW->[$x][0] }->{"mesh_name"} . "_" . $nodesBW{ $result_node_mesh_mapBW->[$x][1] }->{"node_name"} . "_" . $nodesBW{ $result_node_mesh_mapBW->[$y][1] }->{"node_name"} . "</nmwg:parameter>\n";
                    $data .= "      </nmwg:parameters>\n";
                    $data .= "    </nmwg:key>\n";
                    $data .= "  </nmwg:data>";

                    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
                        my $dHash  = md5_hex($data);
                        my $mdHash = md5_hex($metadata);
                        $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $metadata, type => "MAStore" } ), name => $mdHash, txn => $dbTr, error => \$error } );
                        $errorFlag++ if $error;
                        $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $data, type => "MAStore" } ), name => $dHash, txn => $dbTr, error => \$error } );
                        $errorFlag++ if $error;

                        $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                        $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                        $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                    }
                    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
                        my $fh = new IO::File ">> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
                        if ( defined $fh ) {
                            print $fh $metadata . "\n" . $data . "\n";
                            $fh->close;
                        }
                        else {
                            $self->{LOGGER}->fatal("File handle cannot be written, aborting.");
                            return -1;
                        }

                        my $dHash = md5_hex($data);
                        $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                        $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                        $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                    }
                    $id++;
                }
            }
        }
    }
    else {
        my @measurementsets = $conf->get_sublist( LIST => 'MEASUREMENTSET' );
        my $id = 0;
        foreach my $m (@measurementsets) {

            my $addrType = $conf->get_val( MEASUREMENTSET => $m, ATTR => "ADDRTYPE" );
            my $group    = $conf->get_val( MEASUREMENTSET => $m, ATTR => "GROUP" );

            my $center = $conf->get_val( GROUP => $group, ATTR => "HAUPTNODE" );
            my @cn = ( "", $center );
            my @nodes = $conf->get_val( GROUP => $group, ATTR => "NODES" );

            foreach my $c_n (@cn) {
                foreach my $n (@nodes) {
                    next if $n eq $center;
                    my $metadata = q{};
                    my $data     = q{};

                    $metadata .= "  <nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"metadata-" . $id . "\">\n";

                    if ( $addrType =~ m/^BW/ ) {

                        # bwctl metadata

                        $metadata .= "    <iperf:subject xmlns:iperf=\"http://ggf.org/ns/nmwg/tools/iperf/2.0/\" id=\"subject-" . $id . "\">\n";

                        if ( not $c_n ) {
                            $metadata .= $self->generateStoreEndPointPair( { conf => $conf, type => $addrType, center => $center, n => $n } );
                        }
                        else {
                            $metadata .= $self->generateStoreEndPointPair( { conf => $conf, type => $addrType, center => $n, n => $center } );
                        }

                        $metadata .= "    </iperf:subject>\n";
                        $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/iperf/2.0</nmwg:eventType>\n";
                        $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0</nmwg:eventType>\n";

                        my $test        = $conf->get_val( MEASUREMENTSET => $m,    ATTR => "TESTSPEC" );
                        my $testTypeTCP = $conf->get_val( TESTSPEC       => $test, ATTR => "BWTCP" );
                        my $testTypeUDP = $conf->get_val( TESTSPEC       => $test, ATTR => "BWUDP" );

                        if ($testTypeTCP) {
                            my %tcpHash = (
                                "BWWINDOWSIZE"     => "windowSize",
                                "BWBUFFERLEN"      => "bufferLength",
                                "BWTESTDURATION"   => "timeDuration",
                                "BWREPORTINTERVAL" => "interval"
                            );
                            $metadata .= $self->generateStoreParameters( { conf => $conf, paramHash => \%tcpHash, test => $test, counter => $id } );
                        }
                        elsif ($testTypeUDP) {
                            my %udpHash = (
                                "BWWINDOWSIZE"        => "windowSize",
                                "BWBUFFERLEN"         => "bufferLength",
                                "BWTESTDURATION"      => "timeDuration",
                                "BWREPORTINTERVAL"    => "interval",
                                "BWUDPBANDWIDTHLIMIT" => "bandwidthLimit"
                            );
                            $metadata .= $self->generateStoreParameters( { conf => $conf, paramHash => \%udpHash, test => $test, counter => $id } );
                        }
                        $metadata .= "  </nmwg:metadata>\n";

                        $data .= "  <nmwg:data xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"data-" . $id . "\" metadataIdRef=\"metadata-" . $id . "\">\n";
                        $data .= "    <nmwg:key id=\"key-" . $id . "\">\n";
                        $data .= "      <nmwg:parameters id=\"parameters-key-" . $id . "\">\n";
                        $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/tools/iperf/2.0</nmwg:parameter>\n";
                        $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/characteristics/bandwidth/achieveable/2.0</nmwg:parameter>\n";
                        $data .= "        <nmwg:parameter name=\"db\">" . $dbsourceBW . "</nmwg:parameter>\n";
                        $data .= "        <nmwg:parameter name=\"user\">" . $dbuserBW . "</nmwg:parameter>\n" if $dbuserBW;
                        $data .= "        <nmwg:parameter name=\"pass\">" . $dbpassBW . "</nmwg:parameter>\n" if $dbpassBW;
                    }
                    elsif ( $addrType =~ m/^LAT/ ) {

                        # owamp metadata

                        $metadata .= "    <owamp:subject xmlns:owamp=\"http://ggf.org/ns/nmwg/tools/owamp/2.0/\" id=\"subject-" . $id . "\">\n";

                        if ( not $c_n ) {
                            $metadata .= $self->generateStoreEndPointPair( { conf => $conf, type => $addrType, center => $center, n => $n } );
                        }
                        else {
                            $metadata .= $self->generateStoreEndPointPair( { conf => $conf, type => $addrType, center => $n, n => $center } );
                        }

                        $metadata .= "    </owamp:subject>\n";
                        $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/tools/owamp/2.0</nmwg:eventType>\n";
                        $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921</nmwg:eventType>\n";

                        my $test = $conf->get_val( MEASUREMENTSET => $m, ATTR => "TESTSPEC" );
                        my %hash = ();
                        $metadata .= $self->generateStoreParameters( { conf => $conf, paramHash => \%hash, test => $test, counter => $id } );
                        $metadata .= "  </nmwg:metadata>\n";

                        $data .= "  <nmwg:data xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"data-" . $id . "\" metadataIdRef=\"metadata-" . $id . "\">\n";
                        $data .= "    <nmwg:key id=\"key-" . $id . "\">\n";
                        $data .= "      <nmwg:parameters id=\"parameters-key-" . $id . "\">\n";
                        $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/tools/owamp/2.0</nmwg:parameter>\n";
                        $data .= "        <nmwg:parameter name=\"eventType\">http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921</nmwg:parameter>\n";
                        $data .= "        <nmwg:parameter name=\"db\">" . $dbsourceOWP . "</nmwg:parameter>\n";
                        $data .= "        <nmwg:parameter name=\"user\">" . $dbuserOWP . "</nmwg:parameter>\n" if $dbuserOWP;
                        $data .= "        <nmwg:parameter name=\"pass\">" . $dbpassOWP . "</nmwg:parameter>\n" if $dbpassOWP;
                    }

                    $data .= "        <nmwg:parameter name=\"type\">mysql</nmwg:parameter>\n";
                    $data .= "      </nmwg:parameters>\n";
                    $data .= "    </nmwg:key>\n";
                    $data .= "  </nmwg:data>\n";

                    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
                        my $dHash  = md5_hex($data);
                        my $mdHash = md5_hex($metadata);
                        $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $metadata, type => "MAStore" } ), name => $mdHash, txn => $dbTr, error => \$error } );
                        $errorFlag++ if $error;
                        $parameters->{metadatadb}->insertIntoContainer( { content => $parameters->{metadatadb}->wrapStore( { content => $data, type => "MAStore" } ), name => $dHash, txn => $dbTr, error => \$error } );
                        $errorFlag++ if $error;

                        $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                        $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                        $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                    }
                    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
                        my $fh = new IO::File ">> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
                        if ( defined $fh ) {
                            print $fh $metadata . "\n" . $data . "\n";
                            $fh->close;
                        }
                        else {
                            $self->{LOGGER}->fatal("File handle cannot be written, aborting.");
                            return -1;
                        }

                        my $dHash = md5_hex($data);
                        $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$dHash} = "data-" . $id;
                        $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{ "data-" . $id } = $dHash;
                        $self->{LOGGER}->debug( "Key id $dHash maps to data element data-" . $id );
                    }
                    $id++;
                }
            }

        }
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        if ($errorFlag) {
            $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
            undef $dbTr;
            $self->{LOGGER}->fatal( "Database error: \"" . $error . "\", aborting." );
            return -1;
        }
        else {
            my $status = $parameters->{metadatadb}->commitTransaction( { txn => $dbTr, error => \$error } );
            if ( $status == 0 ) {
                undef $dbTr;
            }
            else {
                $parameters->{metadatadb}->abortTransaction( { txn => $dbTr, error => \$error } ) if $dbTr;
                undef $dbTr;
                $self->{LOGGER}->fatal( "Database error: \"" . $error . "\", aborting." );
                return -1;
            }
        }
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        my $fh = new IO::File ">> " . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"};
        if ( defined $fh ) {
            print $fh "</nmwg:store>\n";
            $fh->close;
        }
        else {
            $self->{LOGGER}->fatal("File handle cannot be written, aborting.");
            return -1;
        }
    }
    else {
        $self->{LOGGER}->fatal("Wrong value for 'metadata_db_type' set.");
        return -1;
    }
    return 0;
}

=head2 generateStoreParameters($self, { conf, paramHash, test, counter } )

Given the parameterse from an owmesh file, list these in nmwg form.

=cut

sub generateStoreParameters {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { conf => 1, paramHash => 1, test => 1, counter => 1 } );

    my $param    = "    <nmwg:parameters id=\"parameters-" . $parameters->{counter} . "\"";
    my $pCounter = 0;
    foreach my $p ( keys %{ $parameters->{paramHash} } ) {
        my $value = $parameters->{conf}->get_val( TESTSPEC => $parameters->{test}, ATTR => $p );
        unless ($value) {
            $value = $parameters->{conf}->get_val( ATTR => $p );
        }
        next unless $value;
        $param .= ">\n" if not $pCounter;
        $pCounter++;
        $param .= "      <nmwg:parameter name=\"" . $parameters->{paramHash}->{$p} . "\">" . $value . "</nmwg:parameter>\n";
    }
    if ($pCounter) {
        $param .= "    </nmwg:parameters>\n";
    }
    else {
        $param .= " />\n";
    }
    return $param;
}

=head2 generateStoreEndPointPair($self, { conf, type, center, n } );

Given two nodes (e.g. the src/dst) make an endPointPair element.

=cut

sub generateStoreEndPointPair {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { conf => 1, type => 1, center => 1, n => 1 } );

    ( my $choice = $parameters->{type} ) =~ s/^(BW|LAT)//;
    my $endPointPair = "      <nmwgt:endPointPair xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";

    my @srcPart = ();
    my @dstPart = ();
    if ( $choice == 6 ) {
        my $src = $parameters->{conf}->get_val( NODE => $parameters->{center}, TYPE => $parameters->{type}, ATTR => "ADDR" );
        if ( $src eq "1" ) {
            my @temp = $parameters->{conf}->get_val( NODE => $parameters->{center}, TYPE => $parameters->{type}, ATTR => "ADDR" );
            $src = $temp[0] if $temp[0];
        }
        @srcPart = split( /\]/, $src );
        $srcPart[0] =~ s/^\[//;
        $srcPart[1] =~ s/^:// if $srcPart[1];

        my $dst = $parameters->{conf}->get_val( NODE => $parameters->{n}, TYPE => $parameters->{type}, ATTR => "ADDR" );
        if ( $dst eq "1" ) {
            my @temp = $parameters->{conf}->get_val( NODE => $parameters->{n}, TYPE => $parameters->{type}, ATTR => "ADDR" );
            $dst = $temp[0] if $temp[0];
        }
        @dstPart = split( /\]/, $dst );
        $dstPart[0] =~ s/^\[//;
        $dstPart[1] =~ s/^:// if $dstPart[1];
    }
    elsif ( $choice == 4 ) {
        @srcPart = split( /:/, $parameters->{conf}->get_val( NODE => $parameters->{center}, TYPE => $parameters->{type}, ATTR => "ADDR" ) );
        @dstPart = split( /:/, $parameters->{conf}->get_val( NODE => $parameters->{n},      TYPE => $parameters->{type}, ATTR => "ADDR" ) );
    }
    else {
        return;
    }

    if ( $#srcPart > 0 ) {
        $endPointPair .= "        <nmwgt:src type=\"ipv" . $choice . "\" value=\"" . $srcPart[0] . "\" port=\"" . $srcPart[1] . "\" />\n";
    }
    else {
        $endPointPair .= "        <nmwgt:src type=\"ipv" . $choice . "\" value=\"" . $srcPart[0] . "\" />\n";
    }

    if ( $#dstPart > 0 ) {
        $endPointPair .= "        <nmwgt:dst type=\"ipv" . $choice . "\" value=\"" . $dstPart[0] . "\" port=\"" . $dstPart[1] . "\" />\n";
    }
    else {
        $endPointPair .= "        <nmwgt:dst type=\"ipv" . $choice . "\" value=\"" . $dstPart[0] . "\" />\n";
    }
    $endPointPair .= "      </nmwgt:endPointPair>\n";
    return $endPointPair;
}

=head2 confHierarchy($self, {  conf, type, variable } )

Return the properl member from the conf Hierarchy.

=cut

sub confHierarchy {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { conf => 1, type => 1, variable => 1 } );

    if ( exists $parameters->{conf}->{ $parameters->{variable} } and $parameters->{conf}->{ $parameters->{variable} } ) {
        return $parameters->{conf}->{ $parameters->{variable} };
    }
    elsif ( exists $parameters->{conf}->{ $parameters->{type} . $parameters->{variable} } and $parameters->{conf}->{ $parameters->{type} . $parameters->{variable} } ) {
        return $parameters->{conf}->{ $parameters->{type} . $parameters->{variable} };
    }
    elsif ( exists $parameters->{conf}->{ "CENTRAL" . $parameters->{variable} } and $parameters->{conf}->{ "CENTRAL" . $parameters->{variable} } ) {
        return $parameters->{conf}->{ "CENTRAL" . $parameters->{variable} };
    }
    elsif ( exists $parameters->{conf}->{ $parameters->{type} . "CENTRAL" . $parameters->{variable} } and $parameters->{conf}->{ $parameters->{type} . "CENTRAL" . $parameters->{variable} } ) {
        return $parameters->{conf}->{ $parameters->{type} . "CENTRAL" . $parameters->{variable} };
    }
    return;
}

=head2 prepareDatabases($self, { doc })

Opens the XMLDB and returns the handle if there was not an error.  The optional
argument can be used to pass an error message to the given message and 
return this in response to a request.

=cut

sub prepareDatabases {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { doc => 0 } );

    my $error = q{};
    my $metadatadb = new perfSONAR_PS::DB::XMLDB( { env => $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_name"}, cont => $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"}, ns => \%ma_namespaces, } );
    unless ( $metadatadb->openDB( { txn => q{}, error => \$error } ) == 0 ) {
        throw perfSONAR_PS::Error_compat( "error.ls.xmldb", "There was an error opening \"" . $self->{CONF}->{"ls"}->{"metadata_db_name"} . "/" . $self->{CONF}->{"ls"}->{"metadata_db_file"} . "\": " . $error );
        return;
    }
    return $metadatadb;
}

=head2 needLS($self {})

This particular service (perfSONARBUOY MA) should register with a lookup
service.  This function simply returns the value set in the configuration file
(either yes or no, depending on user preference) to let other parts of the
framework know if LS registration is required.

=cut

sub needLS {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, {} );

    return ( $self->{CONF}->{"perfsonarbuoy"}->{enable_registration} or $self->{CONF}->{enable_registration} );
}

=head2 registerLS($self $sleep_time)

Given the service information (specified in configuration) and the contents of
our metadata database, we can contact the specified LS and register ourselves.
We then sleep for some amount of time and do it again.

=cut

sub registerLS {
    my ( $self, $sleep_time ) = validateParamsPos( @_, 1, { type => SCALARREF }, );

    my ( $status, $res );
    my $ls = q{};

    my @ls_array = ();
    my @array = split( /\s+/, $self->{CONF}->{"perfsonarbuoy"}->{"ls_instance"} );
    foreach my $l (@array) {
        $l =~ s/(\s|\n)*//g;
        push @ls_array, $l if $l;
    }
    @array = split( /\s+/, $self->{CONF}->{"ls_instance"} );
    foreach my $l (@array) {
        $l =~ s/(\s|\n)*//g;
        push @ls_array, $l if $l;
    }

    my @hints_array = ();
    @array = split( /\s+/, $self->{CONF}->{"root_hints_url"} );
    foreach my $h (@array) {
        $h =~ s/(\s|\n)*//g;
        push @hints_array, $h if $h;
    }

    if ( !defined $self->{LS_CLIENT} ) {
        my %ls_conf = (
            SERVICE_TYPE        => $self->{CONF}->{"perfsonarbuoy"}->{"service_type"},
            SERVICE_NAME        => $self->{CONF}->{"perfsonarbuoy"}->{"service_name"},
            SERVICE_DESCRIPTION => $self->{CONF}->{"perfsonarbuoy"}->{"service_description"},
            SERVICE_ACCESSPOINT => $self->{CONF}->{"perfsonarbuoy"}->{"service_accesspoint"},
        );
        $self->{LS_CLIENT} = new perfSONAR_PS::Client::LS::Remote( \@ls_array, \%ls_conf, \@hints_array );
    }

    $ls = $self->{LS_CLIENT};

    my $error         = q{};
    my @resultsString = ();
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        @resultsString = $self->{METADATADB}->query( { query => "/nmwg:store/nmwg:metadata", error => \$error } );
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        my $metadatadb = $self->prepareDatabases;
        unless ($metadatadb) {
            $self->{LOGGER}->error("Database could not be opened.");
            return -1;
        }
        @resultsString = $metadatadb->query( { query => "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata", txn => q{}, error => \$error } );
        $metadatadb->closeDB( { error => \$error } );
    }
    else {
        $self->{LOGGER}->error("Wrong value for 'metadata_db_type' set.");
        return -1;
    }

    if ( $#resultsString == -1 ) {
        $self->{LOGGER}->error("No data to register with LS");
        return -1;
    }
    $ls->registerStatic( \@resultsString );
    return 0;
}

=head2 handleMessageBegin($self, { ret_message, messageId, messageType, msgParams, request, retMessageType, retMessageNamespaces })

Stub function that is currently unused.  Will be used to interact with the 
daemon's message handler.

=cut

sub handleMessageBegin {
    my ( $self, $ret_message, $messageId, $messageType, $msgParams, $request, $retMessageType, $retMessageNamespaces ) = @_;

    #   my ($self, @args) = @_;
    #      my $parameters = validateParams(@args,
    #            {
    #                ret_message => 1,
    #                messageId => 1,
    #                messageType => 1,
    #                msgParams => 1,
    #                request => 1,
    #                retMessageType => 1,
    #                retMessageNamespaces => 1
    #            });

    return 0;
}

=head2 handleMessageEnd($self, { ret_message, messageId })

Stub function that is currently unused.  Will be used to interact with the 
daemon's message handler.

=cut

sub handleMessageEnd {
    my ( $self, $ret_message, $messageId ) = @_;

    #   my ($self, @args) = @_;
    #      my $parameters = validateParams(@args,
    #            {
    #                ret_message => 1,
    #                messageId => 1
    #            });

    return 0;
}

=head2 handleEvent($self, { output, messageId, messageType, messageParameters, eventType, subject, filterChain, data, rawRequest, doOutputMetadata })

Current workaround to the daemon's message handler.  All messages that enter
will be routed based on the message type.  The appropriate solution to this
problem is to route on eventType and message type and will be implemented in
future releases.

=cut

sub handleEvent {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            output            => 1,
            messageId         => 1,
            messageType       => 1,
            messageParameters => 1,
            eventType         => 1,
            subject           => 1,
            filterChain       => 1,
            data              => 1,
            rawRequest        => 1,
            doOutputMetadata  => 1,
        }
    );

    my @subjects = @{ $parameters->{subject} };
    my @filters  = @{ $parameters->{filterChain} };
    my $md       = $subjects[0];

    # this module outputs its own metadata so it needs to turn off the daemon's
    # metadata output routines.
    ${ $parameters->{doOutputMetadata} } = 0;

    my %timeSettings = ();

    # go through the main subject and select filters looking for parameters.
    my $new_timeSettings = getFilterParameters( { m => $md, namespaces => $parameters->{rawRequest}->getNamespaces(), default_resolution => $self->{CONF}->{"perfsonarbuoy"}->{"default_resolution"} } );

    $timeSettings{"CF"}                   = $new_timeSettings->{"CF"}                   if ( defined $new_timeSettings->{"CF"} );
    $timeSettings{"RESOLUTION"}           = $new_timeSettings->{"RESOLUTION"}           if ( defined $new_timeSettings->{"RESOLUTION"} and $timeSettings{"RESOLUTION_SPECIFIED"} );
    $timeSettings{"RESOLUTION_SPECIFIED"} = $new_timeSettings->{"RESOLUTION_SPECIFIED"} if ( $new_timeSettings->{"RESOLUTION_SPECIFIED"} );

    if ( exists $new_timeSettings->{"START"}->{"value"} ) {
        if ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "unix" ) {
            $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
        }
        elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "iso" ) {
            $new_timeSettings->{"START"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"START"}->{"value"}, "%s" ) )->bstr();
        }
        else {
            $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
        }
    }
    $timeSettings{"START"} = $new_timeSettings->{"START"};

    if ( exists $new_timeSettings->{"END"}->{"value"} ) {
        if ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "unix" ) {
            $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
        }
        elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "iso" ) {
            $new_timeSettings->{"END"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"END"}->{"value"}, "%s" ) )->bstr();
        }
        else {
            $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
        }
    }
    $timeSettings{"END"} = $new_timeSettings->{"END"};

    if ( $#filters > -1 ) {
        foreach my $filter_arr (@filters) {
            my @filters = @{$filter_arr};
            my $filter  = $filters[-1];

            $new_timeSettings = getFilterParameters( { m => $filter, namespaces => $parameters->{rawRequest}->getNamespaces(), default_resolution => $self->{CONF}->{"perfsonarbuoy"}->{"default_resolution"} } );

            $timeSettings{"CF"}                   = $new_timeSettings->{"CF"}                   if ( defined $new_timeSettings->{"CF"} );
            $timeSettings{"RESOLUTION"}           = $new_timeSettings->{"RESOLUTION"}           if ( defined $new_timeSettings->{"RESOLUTION"} and $new_timeSettings->{"RESOLUTION_SPECIFIED"} );
            $timeSettings{"RESOLUTION_SPECIFIED"} = $new_timeSettings->{"RESOLUTION_SPECIFIED"} if ( $new_timeSettings->{"RESOLUTION_SPECIFIED"} );

            if ( exists $new_timeSettings->{"START"}->{"value"} ) {
                if ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "unix" ) {
                    $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
                }
                elsif ( exists $new_timeSettings->{"START"}->{"type"} and lc( $new_timeSettings->{"START"}->{"type"} ) eq "iso" ) {
                    $new_timeSettings->{"START"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"START"}->{"value"}, "%s" ) )->bstr();
                }
                else {
                    $new_timeSettings->{"START"}->{"internal"} = time2owptime( $new_timeSettings->{"START"}->{"value"} )->bstr();
                }
            }
            else {
                $new_timeSettings->{"START"}->{"internal"} = q{};
            }

            if ( exists $new_timeSettings->{"END"}->{"value"} ) {
                if ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "unix" ) {
                    $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
                }
                elsif ( exists $new_timeSettings->{"END"}->{"type"} and lc( $new_timeSettings->{"END"}->{"type"} ) eq "iso" ) {
                    $new_timeSettings->{"END"}->{"internal"} = time2owptime( UnixDate( $new_timeSettings->{"END"}->{"value"}, "%s" ) )->bstr();
                }
                else {
                    $new_timeSettings->{"END"}->{"internal"} = time2owptime( $new_timeSettings->{"END"}->{"value"} )->bstr();
                }
            }
            else {
                $new_timeSettings->{"END"}->{"internal"} = q{};
            }

            # we conditionally replace the START/END settings since under the
            # theory of filter, if a later element specifies an earlier start
            # time, the later start time that appears higher in the filter chain
            # would have filtered out all times earlier than itself leaving
            # nothing to exist between the earlier start time and the later
            # start time. XXX I'm not sure how the resolution and the
            # consolidation function should work in this context.

            if ( exists $new_timeSettings->{"START"}->{"internal"} and ( ( not exists $timeSettings{"START"}->{"internal"} ) or $new_timeSettings->{"START"}->{"internal"} > $timeSettings{"START"}->{"internal"} ) ) {
                $timeSettings{"START"} = $new_timeSettings->{"START"};
            }

            if ( exists $new_timeSettings->{"END"}->{"internal"} and ( ( not exists $timeSettings{"END"}->{"internal"} ) or $new_timeSettings->{"END"}->{"internal"} < $timeSettings{"END"}->{"internal"} ) ) {
                $timeSettings{"END"} = $new_timeSettings->{"END"};
            }
        }
    }

    # If no resolution was listed in the filters, go with the default
    if ( not defined $timeSettings{"RESOLUTION"} ) {
        $timeSettings{"RESOLUTION"}           = $self->{CONF}->{"perfsonarbuoy"}->{"default_resolution"};
        $timeSettings{"RESOLUTION_SPECIFIED"} = 0;
    }

    my $cf         = q{};
    my $resolution = q{};
    my $start      = q{};
    my $end        = q{};

    $cf         = $timeSettings{"CF"}                  if ( $timeSettings{"CF"} );
    $resolution = $timeSettings{"RESOLUTION"}          if ( $timeSettings{"RESOLUTION"} );
    $start      = $timeSettings{"START"}->{"internal"} if ( $timeSettings{"START"}->{"internal"} );
    $end        = $timeSettings{"END"}->{"internal"}   if ( $timeSettings{"END"}->{"internal"} );

    $self->{LOGGER}->debug("Request filter parameters: cf: $cf resolution: $resolution start: $start end: $end");

    if ( $parameters->{messageType} eq "MetadataKeyRequest" ) {
        return $self->maMetadataKeyRequest(
            {
                output             => $parameters->{output},
                metadata           => $md,
                filters            => \@filters,
                time_settings      => \%timeSettings,
                request            => $parameters->{rawRequest},
                message_parameters => $parameters->{messageParameters}
            }
        );
    }
    elsif ( $parameters->{messageType} eq "SetupDataRequest" ) {
        return $self->maSetupDataRequest(
            {
                output             => $parameters->{output},
                metadata           => $md,
                filters            => \@filters,
                time_settings      => \%timeSettings,
                request            => $parameters->{rawRequest},
                message_parameters => $parameters->{messageParameters}
            }
        );
    }
    else {
        throw perfSONAR_PS::Error_compat( "error.ma.message_type", "Invalid Message Type" );
        return;
    }
    return;
}

=head2 maMetadataKeyRequest($self, { output, metadata, time_settings, filters, request, message_parameters })

Main handler of MetadataKeyRequest messages.  Based on contents (i.e. was a
key sent in the request, or not) this will route to one of two functions:

 - metadataKeyRetrieveKey          - Handles all requests that enter with a 
                                     key present.  
 - metadataKeyRetrieveMetadataData - Handles all other requests
 
The goal of this message type is to return a pointer (i.e. a 'key') to the data
so that the more expensive operation of XPath searching the database is avoided
with a simple hashed key lookup.  The key currently can be replayed repeatedly
currently because it is not time sensitive.  

=cut

sub maMetadataKeyRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            output             => 1,
            metadata           => 1,
            time_settings      => 1,
            filters            => 1,
            request            => 1,
            message_parameters => 1
        }
    );
    my $mdId  = q{};
    my $dId   = q{};
    my $error = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB} = $self->prepareDatabases( { doc => $parameters->{output} } );
        unless ( $self->{METADATADB} ) {
            throw perfSONAR_PS::Error_compat("Database could not be opened.");
            return;
        }
    }
    unless ( ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" )
        or ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) )
    {
        throw perfSONAR_PS::Error_compat("Wrong value for 'metadata_db_type' set.");
        return;
    }

    my $nmwg_key = find( $parameters->{metadata}, "./nmwg:key", 1 );
    if ($nmwg_key) {
        $self->metadataKeyRetrieveKey(
            {
                metadatadb         => $self->{METADATADB},
                key                => $nmwg_key,
                metadata           => $parameters->{metadata},
                filters            => $parameters->{filters},
                request_namespaces => $parameters->{request}->getNamespaces(),
                output             => $parameters->{output}
            }
        );
    }
    else {
        $self->metadataKeyRetrieveMetadataData(
            {
                metadatadb         => $self->{METADATADB},
                time_settings      => $parameters->{time_settings},
                metadata           => $parameters->{metadata},
                filters            => $parameters->{filters},
                request_namespaces => $parameters->{request}->getNamespaces(),
                output             => $parameters->{output}
            }
        );

    }
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB}->closeDB( { error => \$error } );
    }
    return;
}

=head2 metadataKeyRetrieveKey($self, { metadatadb, key, metadata, filters, request_namespaces, output })

Because the request entered with a key, we must handle it in this particular
function.  We first attempt to extract the 'maKey' hash and check for validity.
An invalid or missing key will trigger an error instantly.  If the key is found
we see if any chaining needs to be done (and appropriately 'cook' the key), then
return the response.

=cut

sub metadataKeyRetrieveKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            key                => 1,
            metadata           => 1,
            filters            => 1,
            request_namespaces => 1,
            output             => 1
        }
    );

    my $mdId    = "metadata." . genuid();
    my $dId     = "data." . genuid();
    my $hashKey = extract( find( $parameters->{key}, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
    unless ($hashKey) {
        my $msg = "Key error in metadata storage: cannot find 'maKey' in request message.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $hashId = $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$hashKey};
    unless ($hashId) {
        my $msg = "Key error in metadata storage: 'maKey' cannot be found.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $query = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $query = "/nmwg:store/nmwg:data[\@id=\"" . $hashId . "\"]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $query = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data[\@id=\"" . $hashId . "\"]";
    }

    if ( $parameters->{metadatadb}->count( { query => $query } ) != 1 ) {
        my $msg = "Key error in metadata storage: 'maKey' should exist, but matching data not found in database.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $mdIdRef;
    my @filters = @{ $parameters->{filters} };
    if ( $#filters > -1 ) {
        $mdIdRef = $filters[-1][0]->getAttribute("id");
    }
    else {
        $mdIdRef = $parameters->{metadata}->getAttribute("id");
    }

    createMetadata( $parameters->{output}, $mdId, $mdIdRef, $parameters->{key}->toString, undef );
    my $key2 = $parameters->{key}->cloneNode(1);
    my $params = find( $key2, ".//nmwg:parameters", 1 );
    $self->addSelectParameters( { parameter_block => $params, filters => $parameters->{filters} } );
    createData( $parameters->{output}, $dId, $mdId, $key2->toString, undef );
    return;
}

=head2 metadataKeyRetrieveMetadataData($self, $metadatadb, $metadata, $chain,
                                       $id, $request_namespaces, $output)

Similar to 'metadataKeyRetrieveKey' we are looking to return a valid key.  The
input will be partially or fully specified metadata.  If this matches something
in the database we will return a key matching the description (in the form of
an MD5 fingerprint).  If this metadata was a part of a chain the chaining will
be resolved and used to augment (i.e. 'cook') the key.

=cut

sub metadataKeyRetrieveMetadataData {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            time_settings      => 1,
            metadata           => 1,
            filters            => 1,
            request_namespaces => 1,
            output             => 1
        }
    );

    my $mdId        = q{};
    my $dId         = q{};
    my $queryString = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }

    my $results             = $parameters->{metadatadb}->querySet( { query => $queryString } );
    my %et                  = ();
    my $eventTypes          = find( $parameters->{metadata}, "./nmwg:eventType", 0 );
    my $supportedEventTypes = find( $parameters->{metadata}, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
    foreach my $e ( $eventTypes->get_nodelist ) {
        my $value = extract( $e, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }
    foreach my $se ( $supportedEventTypes->get_nodelist ) {
        my $value = extract( $se, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:data";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data";
    }

    if ( $eventTypes->size() or $supportedEventTypes->size() ) {
        $queryString = $queryString . "[./nmwg:key/nmwg:parameters/nmwg:parameter[(\@name=\"supportedEventType\" or \@name=\"eventType\")";
        foreach my $e ( sort keys %et ) {
            $queryString = $queryString . " and (\@value=\"" . $e . "\" or text()=\"" . $e . "\")";
        }
        $queryString = $queryString . "]]";
    }

    my $dataResults = $parameters->{metadatadb}->querySet( { query => $queryString } );
    if ( $results->size() > 0 and $dataResults->size() > 0 ) {
        my %mds = ();
        foreach my $md ( $results->get_nodelist ) {
            my $curr_md_id = $md->getAttribute("id");
            next if not $curr_md_id;
            $mds{$curr_md_id} = $md;
        }

        foreach my $d ( $dataResults->get_nodelist ) {
            my $curr_d_mdIdRef = $d->getAttribute("metadataIdRef");
            next if ( not $curr_d_mdIdRef or not exists $mds{$curr_d_mdIdRef} );

            my $curr_md = $mds{$curr_d_mdIdRef};

            my $dId  = "data." . genuid();
            my $mdId = "metadata." . genuid();

            my $md_temp = $curr_md->cloneNode(1);
            $md_temp->setAttribute( "metadataIdRef", $curr_d_mdIdRef );
            $md_temp->setAttribute( "id",            $mdId );

            $parameters->{output}->addExistingXMLElement($md_temp);

            my $hashId  = $d->getAttribute("id");
            my $hashKey = $self->{CONF}->{"perfsonarbuoy"}->{"idToHash"}->{$hashId};
            unless ($hashKey) {
                my $msg = "Key error in metadata storage: 'maKey' cannot be found.";
                $self->{LOGGER}->error($msg);
                throw perfSONAR_PS::Error_compat( "error.ma.storage", $msg );
            }

            startData( $parameters->{output}, $dId, $mdId, undef );
            $parameters->{output}->startElement( { prefix => "nmwg", tag => "key", namespace => "http://ggf.org/ns/nmwg/base/2.0/" } );
            startParameters( $parameters->{output}, "params.0" );
            addParameter( $parameters->{output}, "maKey", $hashKey );

            my %attrs = ();
            $attrs{"type"} = $parameters->{time_settings}->{"START"}->{"type"} if $parameters->{time_settings}->{"START"}->{"type"};
            addParameter( $parameters->{output}, "startTime", $parameters->{time_settings}->{"START"}->{"value"}, \%attrs ) if ( defined $parameters->{time_settings}->{"START"}->{"value"} );

            %attrs = ();
            $attrs{"type"} = $parameters->{time_settings}->{"END"}->{"type"} if $parameters->{time_settings}->{"END"}->{"type"};
            addParameter( $parameters->{output}, "endTime", $parameters->{time_settings}->{"END"}->{"value"}, \%attrs ) if ( defined $parameters->{time_settings}->{"END"}->{"value"} );

            if ( defined $parameters->{time_settings}->{"RESOLUTION"} and $parameters->{time_settings}->{"RESOLUTION_SPECIFIED"} ) {
                addParameter( $parameters->{output}, "resolution", $parameters->{time_settings}->{"RESOLUTION"} );
            }
            addParameter( $parameters->{output}, "consolidationFunction", $parameters->{time_settings}->{"CF"} ) if ( defined $parameters->{time_settings}->{"CF"} );
            endParameters( $parameters->{output} );
            $parameters->{output}->endElement("key");
            endData( $parameters->{output} );
        }
    }
    else {
        my $msg = "Database \"" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} . "\" returned 0 results for search";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage", $msg );
    }
    return;
}

=head2 maSetupDataRequest($self, $output, $md, $request, $message_parameters)

Main handler of SetupDataRequest messages.  Based on contents (i.e. was a
key sent in the request, or not) this will route to one of two functions:

 - setupDataRetrieveKey          - Handles all requests that enter with a 
                                   key present.  
 - setupDataRetrieveMetadataData - Handles all other requests
 
Chaining operations are handled internally, although chaining will eventually
be moved to the overall message handler as it is an important operation that
all services will need.

The goal of this message type is to return actual data, so after the metadata
section is resolved the appropriate data handler will be called to interact
with the database of choice (i.e. mysql, sqlite, others?).  

=cut

sub maSetupDataRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            output             => 1,
            metadata           => 1,
            filters            => 1,
            time_settings      => 1,
            request            => 1,
            message_parameters => 1
        }
    );

    my $mdId  = q{};
    my $dId   = q{};
    my $error = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB} = $self->prepareDatabases( { doc => $parameters->{output} } );
        unless ( $self->{METADATADB} ) {
            throw perfSONAR_PS::Error_compat("Database could not be opened.");
            return;
        }
    }
    unless ( ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" )
        or ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) )
    {
        throw perfSONAR_PS::Error_compat("Wrong value for 'metadata_db_type' set.");
        return;
    }

    my $nmwg_key = find( $parameters->{metadata}, "./nmwg:key", 1 );
    if ($nmwg_key) {
        $self->setupDataRetrieveKey(
            {
                metadatadb         => $self->{METADATADB},
                metadata           => $nmwg_key,
                filters            => $parameters->{filters},
                message_parameters => $parameters->{message_parameters},
                time_settings      => $parameters->{time_settings},
                request_namespaces => $parameters->{request}->getNamespaces(),
                output             => $parameters->{output}
            }
        );
    }
    else {
        $self->setupDataRetrieveMetadataData(
            {
                metadatadb         => $self->{METADATADB},
                metadata           => $parameters->{metadata},
                filters            => $parameters->{filters},
                time_settings      => $parameters->{time_settings},
                message_parameters => $parameters->{message_parameters},
                output             => $parameters->{output}
            }
        );
    }
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $self->{METADATADB}->closeDB( { error => \$error } );
    }
    return;
}

=head2 setupDataRetrieveKey($self, $metadatadb, $metadata, $chain, $id,
                            $message_parameters, $request_namespaces, $output)

Because the request entered with a key, we must handle it in this particular
function.  We first attempt to extract the 'maKey' hash and check for validity.
An invalid or missing key will trigger an error instantly.  If the key is found
we see if any chaining needs to be done.  We finally call the handle data
function, passing along the useful pieces of information from the metadata
database to locate and interact with the backend storage (i.e. rrdtool, mysql, 
sqlite).  

=cut

sub setupDataRetrieveKey {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            metadata           => 1,
            filters            => 1,
            time_settings      => 1,
            message_parameters => 1,
            request_namespaces => 1,
            output             => 1
        }
    );

    my $mdId    = q{};
    my $dId     = q{};
    my $results = q{};

    my $hashKey = extract( find( $parameters->{metadata}, ".//nmwg:parameter[\@name=\"maKey\"]", 1 ), 0 );
    unless ($hashKey) {
        my $msg = "Key error in metadata storage: cannot find 'maKey' in request message.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $hashId = $self->{CONF}->{"perfsonarbuoy"}->{"hashToId"}->{$hashKey};
    $self->{LOGGER}->debug("Received hash key $hashKey which maps to $hashId");
    unless ($hashId) {
        my $msg = "Key error in metadata storage: 'maKey' cannot be found.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $query = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $query = "/nmwg:store/nmwg:data[\@id=\"" . $hashId . "\"]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $query = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data[\@id=\"" . $hashId . "\"]";
    }

    $results = $parameters->{metadatadb}->querySet( { query => $query } );
    if ( $results->size() != 1 ) {
        my $msg = "Key error in metadata storage: 'maKey' should exist, but matching data not found in database.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    # XXX Jul 22, 2008
    #
    # BEGIN Hack
    #
    # I shouldn't have to do this, we need to store this in the key somewhere

    my $md_id_val = $results->get_node(1)->getAttribute("metadataIdRef");
    my $query2    = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $query2 = "/nmwg:store/nmwg:metadata[\@id=\"" . $md_id_val . "\"]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $query2 = "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata[\@id=\"" . $md_id_val . "\"]";
    }

    my $results2 = $parameters->{metadatadb}->querySet( { query => $query2 } );
    if ( $results2->size() != 1 ) {
        my $msg = "Key error in metadata storage: 'metadataIdRef' " . $md_id_val . " should exist, but matching data not found in database.";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage_result", $msg );
        return;
    }

    my $src_b = find( $results2->get_node(1), "./*[local-name()='subject']/*[local-name()='endPointPair']/*[local-name()='src']", 1 );
    my $src_p = $src_b->getAttribute("port");
    my $src   = extract( $src_b, 0 );
    $src .= ":" . $src_p if $src_p;

    my $dst_b = find( $results2->get_node(1), "./*[local-name()='subject']/*[local-name()='endPointPair']/*[local-name()='dst']", 1 );
    my $dst_p = $dst_b->getAttribute("port");
    my $dst   = extract( $dst_b, 0 );
    $dst .= ":" . $dst_p if $dst_p;

    # END Hack

    my $sentKey      = $parameters->{metadata}->cloneNode(1);
    my $results_temp = $results->get_node(1)->cloneNode(1);
    my $storedKey    = find( $results_temp, "./nmwg:key", 1 );

    my %l_et = ();
    my $l_supportedEventTypes = find( $storedKey, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
    foreach my $se ( $l_supportedEventTypes->get_nodelist ) {
        my $value = extract( $se, 0 );
        if ($value) {
            $l_et{$value} = 1;
        }
    }

    $mdId = "metadata." . genuid();
    $dId  = "data." . genuid();

    my $mdIdRef = $parameters->{metadata}->getAttribute("id");
    my @filters = @{ $parameters->{filters} };
    if ( $#filters > -1 ) {
        $self->addSelectParameters( { parameter_block => find( $sentKey, ".//nmwg:parameters", 1 ), filters => \@filters } );

        $mdIdRef = $filters[-1][0]->getAttribute("id");
    }

    createMetadata( $parameters->{output}, $mdId, $mdIdRef, $sentKey->toString, undef );
    $self->handleData(
        {
            id                 => $mdId,
            data               => $results_temp,
            output             => $parameters->{output},
            time_settings      => $parameters->{time_settings},
            et                 => \%l_et,
            src                => $src,
            dst                => $dst,
            message_parameters => $parameters->{message_parameters}
        }
    );

    return;
}

=head2 setupDataRetrieveMetadataData($self, $metadatadb, $metadata, $id, 
                                     $message_parameters, $output)

Similar to 'setupDataRetrieveKey' we are looking to return data.  The input
will be partially or fully specified metadata.  If this matches something in
the database we will return a data matching the description.  If this metadata
was a part of a chain the chaining will be resolved passed along to the data
handling function.

=cut

sub setupDataRetrieveMetadataData {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            metadatadb         => 1,
            metadata           => 1,
            filters            => 1,
            time_settings      => 1,
            message_parameters => 1,
            output             => 1
        }
    );

    my $mdId = q{};
    my $dId  = q{};

    my $queryString = q{};
    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:metadata[" . getMetadataXQuery( { node => $parameters->{metadata} } ) . "]";
    }

    my $results = $parameters->{metadatadb}->querySet( { query => $queryString } );

    my %et                  = ();
    my $eventTypes          = find( $parameters->{metadata}, "./nmwg:eventType", 0 );
    my $supportedEventTypes = find( $parameters->{metadata}, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
    foreach my $e ( $eventTypes->get_nodelist ) {
        my $value = extract( $e, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }
    foreach my $se ( $supportedEventTypes->get_nodelist ) {
        my $value = extract( $se, 0 );
        if ($value) {
            $et{$value} = 1;
        }
    }

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "file" ) {
        $queryString = "/nmwg:store/nmwg:data";
    }
    elsif ( $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_type"} eq "xmldb" ) {
        $queryString = "/nmwg:store[\@type=\"MAStore\"]/nmwg:data";
    }

    if ( $eventTypes->size() or $supportedEventTypes->size() ) {
        $queryString = $queryString . "[./nmwg:key/nmwg:parameters/nmwg:parameter[(\@name=\"supportedEventType\" or \@name=\"eventType\")";
        foreach my $e ( sort keys %et ) {
            $queryString = $queryString . " and (\@value=\"" . $e . "\" or text()=\"" . $e . "\")";
        }
        $queryString = $queryString . "]]";
    }
    my $dataResults = $parameters->{metadatadb}->querySet( { query => $queryString } );

    my %used = ();
    for my $x ( 0 .. $dataResults->size() ) {
        $used{$x} = 0;
    }

    my $base_id = $parameters->{metadata}->getAttribute("id");
    my @filters = @{ $parameters->{filters} };
    if ( $#filters > -1 ) {
        my @filter_arr = @{ $filters[-1] };

        $base_id = $filter_arr[0]->getAttribute("id");
    }

    if ( $results->size() > 0 and $dataResults->size() > 0 ) {
        my %mds = ();
        foreach my $md ( $results->get_nodelist ) {
            next if not $md->getAttribute("id");

            # XXX Jul 22, 2008
            #
            # BEGIN Hack
            #
            # I shouldn't have to do this, we need to store this in the key somewhere

            my $src_b = find( $md, "./*[local-name()='subject']/*[local-name()='endPointPair']/*[local-name()='src']", 1 );
            my $src_p = $src_b->getAttribute("port");
            my $src   = extract( $src_b, 0 );
            $src .= ":" . $src_p if $src_p;

            my $dst_b = find( $md, "./*[local-name()='subject']/*[local-name()='endPointPair']/*[local-name()='dst']", 1 );
            my $dst_p = $dst_b->getAttribute("port");
            my $dst   = extract( $dst_b, 0 );
            $dst .= ":" . $dst_p if $dst_p;

            # END Hack

            my %l_et                  = ();
            my $l_eventTypes          = find( $md, "./nmwg:eventType", 0 );
            my $l_supportedEventTypes = find( $md, ".//nmwg:parameter[\@name=\"supportedEventType\" or \@name=\"eventType\"]", 0 );
            foreach my $e ( $l_eventTypes->get_nodelist ) {
                my $value = extract( $e, 0 );
                if ($value) {
                    $l_et{$value} = 1;
                }
            }
            foreach my $se ( $l_supportedEventTypes->get_nodelist ) {
                my $value = extract( $se, 0 );
                if ($value) {
                    $l_et{$value} = 1;
                }
            }

            my %hash = ();
            $hash{"md"}                     = $md;
            $hash{"et"}                     = \%l_et;
            $hash{"src"}                    = $src;
            $hash{"dst"}                    = $dst;
            $mds{ $md->getAttribute("id") } = \%hash;
        }

        foreach my $d ( $dataResults->get_nodelist ) {
            my $idRef = $d->getAttribute("metadataIdRef");

            next if ( not defined $idRef or not defined $mds{$idRef} );

            my $md_temp = $mds{$idRef}->{"md"}->cloneNode(1);
            my $d_temp  = $d->cloneNode(1);
            $mdId = "metadata." . genuid();
            $md_temp->setAttribute( "metadataIdRef", $base_id );
            $md_temp->setAttribute( "id",            $mdId );
            $parameters->{output}->addExistingXMLElement($md_temp);
            $self->handleData(
                {
                    id                 => $mdId,
                    data               => $d_temp,
                    output             => $parameters->{output},
                    time_settings      => $parameters->{time_settings},
                    et                 => $mds{$idRef}->{"et"},
                    src                => $mds{$idRef}->{"src"},
                    dst                => $mds{$idRef}->{"dst"},
                    message_parameters => $parameters->{message_parameters}
                }
            );
        }
    }
    else {
        my $msg = "Database \"" . $self->{CONF}->{"perfsonarbuoy"}->{"metadata_db_file"} . "\" returned 0 results for search";
        $self->{LOGGER}->error($msg);
        throw perfSONAR_PS::Error_compat( "error.ma.storage", $msg );
    }
    return;
}

=head2 handleData($self, $id, $data, $output, $et, $message_parameters)

Directs the data retrieval operations based on a value found in the metadata
database's representation of the key (i.e. storage 'type').  Current offerings
only interact with rrd files and sql databases.

=cut

sub handleData {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            id                 => 1,
            data               => 1,
            output             => 1,
            et                 => 1,
            time_settings      => 1,
            message_parameters => 1,
            src                => 1,
            dst                => 1
        }
    );

    my $type = extract( find( $parameters->{data}, "./nmwg:key/nmwg:parameters/nmwg:parameter[\@name=\"type\"]", 1 ), 0 );
    if ( lc($type) eq "mysql" or lc($type) eq "sql" ) {
        $self->retrieveSQL(

            {
                d                  => $parameters->{data},
                mid                => $parameters->{id},
                output             => $parameters->{output},
                time_settings      => $parameters->{time_settings},
                et                 => $parameters->{et},
                src                => $parameters->{src},
                dst                => $parameters->{dst},
                message_parameters => $parameters->{message_parameters}
            }
        );
    }
    else {
        my $msg = "Database \"" . $type . "\" is not yet supported";
        $self->{LOGGER}->error($msg);
        getResultCodeData( $parameters->{output}, "data." . genuid(), $parameters->{id}, $msg, 1 );
    }
    return;
}

=head2 retrieveSQL($self, $d, $mid, $output, $et, $message_parameters)

Given some 'startup' knowledge such as the name of the database and any
credentials to connect with it, we start a connection and query the database
for given values.  These values are prepared into XML response content and
return in the response message.

=cut

sub retrieveSQL {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            d                  => 1,
            mid                => 1,
            time_settings      => 1,
            output             => 1,
            et                 => 1,
            message_parameters => 1,
            src                => 1,
            dst                => 1
        }
    );

    my $timeType = "iso";
    if ( defined $parameters->{message_parameters}->{"timeType"} ) {
        if ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "unix" ) {
            $timeType = "unix";
        }
        elsif ( lc( $parameters->{message_parameters}->{"timeType"} ) eq "iso" ) {
            $timeType = "iso";
        }
    }

    unless ( $parameters->{d} ) {
        $self->{LOGGER}->error("No data element.");
        throw perfSONAR_PS::Error_compat( "error.ma.storage", "No data element found." );
    }

    my $dbconnect = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"db\"]",    1 ), 1 );
    my $dbuser    = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"user\"]",  1 ), 1 );
    my $dbpass    = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"pass\"]",  1 ), 1 );
    my $dbtable   = extract( find( $parameters->{d}, "./nmwg:key//nmwg:parameter[\@name=\"table\"]", 1 ), 1 );

    unless ($dbconnect) {
        $self->{LOGGER}->error( "Data element " . $parameters->{d}->getAttribute("id") . " is missing some SQL elements" );
        throw perfSONAR_PS::Error_compat( "error.ma.storage", "Unable to open associated database" );
    }

    my $dataType = "";
    foreach my $eventType ( keys %{ $parameters->{et} } ) {
        if ( $eventType eq "http://ggf.org/ns/nmwg/tools/owamp/2.0" ) {
            $dataType = "OWAMP";
            last;
        }
        elsif ($eventType eq "http://ggf.org/ns/nmwg/tools/bwctl/2.0"
            or $eventType eq "http://ggf.org/ns/nmwg/tools/iperf/2.0" )
        {
            $dataType = "BWCTL";
            last;
        }
    }

    my $id       = "data." . genuid();
    my @dbSchema = ();
    my $res;
    my $query = q{};

    # XXX Jul 22, 2008
    #
    # Still need to worry about the legacy case

    if ( $self->{CONF}->{"perfsonarbuoy"}->{"legacy"} ) {
        if ( $dataType eq "BWCTL" ) {
            @dbSchema = ( "ti", "time", "throughput", "jitter", "lost", "sent" );
        }
        elsif ( $dataType eq "OWAMP" ) {
            @dbSchema = ( "res", "si", "ei", "start", "end", "min", "max", "minttl", "maxttl", "sent", "lost", "dups", "err", "pending" );

            # set res
            if ( exists $parameters->{time_settings}->{"RESOLUTION"} and $parameters->{time_settings}->{"RESOLUTION"} ) {
                my $min = 999999;
                my $max = -999999;
                foreach my $r ( keys %{ $self->{RES} } ) {
                    $min = $r if $r < $min;
                    $max = $r if $r > $max;
                }
                foreach my $r ( keys %{ $self->{RES} } ) {
                    if ( $r < $parameters->{time_settings}->{"RESOLUTION"} ) {
                        $min = $r if $r > $min;
                    }
                    else {
                        $max = $r if $r < $max;
                    }
                }
                if ( ( $parameters->{time_settings}->{"RESOLUTION"} - $min ) < ( $max - $parameters->{time_settings}->{"RESOLUTION"} ) ) {
                    $res = $min;
                }
                else {
                    $res = $max;
                }
            }
            else {
                $res = 999999;
                foreach my $r ( keys %{ $self->{RES} } ) {
                    $res = $r if $r < $res;
                }
            }

        }
        else {
            my $msg = "Improper eventType found.";
            $self->{LOGGER}->error($msg);
            getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $msg, 1 );
            return;
        }

        if ( $parameters->{time_settings}->{"START"}->{"internal"} or $parameters->{time_settings}->{"END"}->{"internal"} ) {
            if ($res) {
                $query = "select * from " . $dbtable . " where res = \"" . $res . "\" and";
            }
            else {
                $query = "select * from " . $dbtable . " where";
            }

            my $queryCount = 0;
            if ( $parameters->{time_settings}->{"START"}->{"internal"} ) {
                if ( $dataType eq "BWCTL" ) {
                    $query = $query . " time > " . $parameters->{time_settings}->{"START"}->{"internal"};
                }
                elsif ( $dataType eq "OWAMP" ) {
                    $query = $query . " start > " . $parameters->{time_settings}->{"START"}->{"internal"};
                }
                $queryCount++;
            }
            if ( $parameters->{time_settings}->{"END"}->{"internal"} ) {
                if ($queryCount) {
                    if ( $dataType eq "BWCTL" ) {
                        $query = $query . " and time < " . $parameters->{time_settings}->{"END"}->{"internal"} . ";";
                    }
                    elsif ( $dataType eq "OWAMP" ) {
                        $query = $query . " and end < " . $parameters->{time_settings}->{"END"}->{"internal"} . ";";
                    }
                }
                else {
                    if ( $dataType eq "BWCTL" ) {
                        $query = $query . " time < " . $parameters->{time_settings}->{"END"}->{"internal"} . ";";
                    }
                    elsif ( $dataType eq "OWAMP" ) {
                        $query = $query . " end < " . $parameters->{time_settings}->{"END"}->{"internal"} . ";";
                    }
                }
            }
        }
        else {
            if ($res) {
                $query = "select * from " . $dbtable . " where res = \"" . $res . "\";";
            }
            else {
                $query = "select * from " . $dbtable . ";";
            }
        }
    }
    else {

        # XXX Jul 22, 2008
        #
        # New case, watch that the names of the tables have changed

        # XXX Sept 19, 2008
        #
        # Want to limit the max amount of data returned (e.g. set an artificial limit at 1000 for now)
        # we also need to worry about the joining of tables.  If we span multiple months this is a given,
        # if we are trying to meet the 1000 limit this is also a givens

        # new data format

        if ( $dataType eq "BWCTL" ) {

            my @nodeSchema = ( "node_id", "node_name", "longname", "addr", "first", "last" );
            my $nodedb = new perfSONAR_PS::DB::SQL( { name => $dbconnect, schema => \@nodeSchema, user => $dbuser, pass => $dbpass } );

            $nodedb->openDB;
            my $result_d = $nodedb->query( { query => "select * from DATES;" } );
            $nodedb->closeDB;
            unless ( $#{$result_d} > -1 ) {
                my $msg = "No data in database";
                $self->{LOGGER}->error($msg);
                getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $msg, 1 );
                return;
            }

            foreach my $row ( @{$result_d} ) {
                my $year = $row->[0];
                my $mon  = $row->[1];
                $mon = "0" . $mon if $mon =~ m/^\d$/;

                $nodedb->openDB;
                my $result1 = $nodedb->query( { query => "select distinct node_id from " . $year . $mon . "_NODES where addr=\"" . $parameters->{src} . "\";" } );
                my $result2 = $nodedb->query( { query => "select distinct node_id from " . $year . $mon . "_NODES where addr=\"" . $parameters->{dst} . "\";" } );
                $nodedb->closeDB;

                if ( $#{$result1} == -1 or $#{$result2} == -1 ) {
                    my $msg = "Cannot find data range tables in database, aborting.";
                    $self->{LOGGER}->error($msg);
                    getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $msg, 1 );
                    return;
                }
                else {
                    @dbSchema = ( "send_id", "recv_id", "tspec_id", "ti", "timestamp", "throughput", "jitter", "lost", "sent" );
                    if ( $parameters->{time_settings}->{"START"}->{"internal"} or $parameters->{time_settings}->{"END"}->{"internal"} ) {
                        if ( $query ) {
                            $query = $query . " union select * from " . $year . $mon . "_DATA where send_id=\"" . $result1->[0][0] . "\" and recv_id=\"" . $result2->[0][0] . "\" and";
                        }
                        else {
                            $query = "select * from " . $year . $mon . "_DATA where send_id=\"" . $result1->[0][0] . "\" and recv_id=\"" . $result2->[0][0] . "\" and";
                        }

                        my $queryCount = 0;
                        if ( $parameters->{time_settings}->{"START"}->{"internal"} ) {
                            $query = $query . " timestamp > " . $parameters->{time_settings}->{"START"}->{"internal"};
                            $queryCount++;
                        }
                        if ( $parameters->{time_settings}->{"END"}->{"internal"} ) {
                            if ( $queryCount ) {
                                $query = $query . " and timestamp < " . $parameters->{time_settings}->{"END"}->{"internal"};
                            }
                            else {
                                $query = $query . " timestamp < " . $parameters->{time_settings}->{"END"}->{"internal"};
                            }
                        }
                    }
                    else {
                        if ( $query ) {
                            $query = $query . " union select * from " . $year . $mon . "_DATA where send_id=\"" . $result1->[0][0] . "\" and recv_id=\"" . $result2->[0][0] . "\"";
                        }
                        else {
                            $query = "select * from " . $year . $mon . "_DATA where send_id=\"" . $result1->[0][0] . "\" and recv_id=\"" . $result2->[0][0] . "\"";
                        }
                    }
                }
            }
            $query = $query . ";" if $query;
        }
        else {
            my $msg = "Improper eventType found.";
            $self->{LOGGER}->error($msg);
            getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $msg, 1 );
            return;
        }
    }

    my $datadb = new perfSONAR_PS::DB::SQL( { name => $dbconnect, schema => \@dbSchema, user => $dbuser, pass => $dbpass } );

    $datadb->openDB;
    my $result = $datadb->query( { query => $query } );
    $datadb->closeDB;

    if ( $#{$result} == -1 ) {
        my $msg = "Query returned 0 results";
        $self->{LOGGER}->error($msg);
        getResultCodeData( $parameters->{output}, $id, $parameters->{mid}, $msg, 1 );
        return;
    }
    else {

        if ( $dataType eq "BWCTL" ) {
            my $prefix = "iperf";
            my $uri    = "http://ggf.org/ns/nmwg/tools/iperf/2.0/";

            startData( $parameters->{output}, $id, $parameters->{mid}, undef );
            my $len = $#{$result};
            for my $a ( 0 .. $len ) {
                my %attrs = ();

                # XXX Jul 22, 2008
                #
                # This needs to be cleaner too, until the legacy dies

                if ( $self->{CONF}->{"perfsonarbuoy"}->{"legacy"} ) {
                    if ( $timeType eq "unix" ) {
                        $attrs{"timeType"} = "unix";
                        $attrs{ $dbSchema[1] . "Value" } = owptime2exacttime( $result->[$a][1] );
                    }
                    else {
                        $attrs{"timeType"} = "iso";
                        $attrs{ $dbSchema[1] . "Value" } = owpexactgmstring( $result->[$a][1] );
                    }

                    $attrs{ $dbSchema[2] } = $result->[$a][2] if $result->[$a][2];
                    $attrs{ $dbSchema[3] } = $result->[$a][3] if $result->[$a][3];
                    $attrs{ $dbSchema[4] } = $result->[$a][4] if $result->[$a][4];
                    $attrs{ $dbSchema[5] } = $result->[$a][5] if $result->[$a][5];

                    $parameters->{output}->createElement(
                        prefix     => $prefix,
                        namespace  => $uri,
                        tag        => "datum",
                        attributes => \%attrs
                    );
                }
                else {
                    if ( $timeType eq "unix" ) {
                        $attrs{"timeType"} = "unix";

                        #                        $attrs{ $dbSchema[4] . "Value" } = owptime2exacttime( $result->[$a][4] );
                        $attrs{"timeValue"} = owptime2exacttime( $result->[$a][4] );
                    }
                    else {
                        $attrs{"timeType"} = "iso";

                        #                        $attrs{ $dbSchema[4] . "Value" } = owpexactgmstring( $result->[$a][4] );
                        $attrs{"timeValue"} = owpexactgmstring( $result->[$a][4] );
                    }

                    $attrs{ $dbSchema[5] } = $result->[$a][5] if $result->[$a][5];
                    $attrs{ $dbSchema[6] } = $result->[$a][6] if $result->[$a][6];
                    $attrs{ $dbSchema[7] } = $result->[$a][7] if $result->[$a][7];
                    $attrs{ $dbSchema[8] } = $result->[$a][8] if $result->[$a][8];

                    $parameters->{output}->createElement(
                        prefix     => $prefix,
                        namespace  => $uri,
                        tag        => "datum",
                        attributes => \%attrs
                    );
                }
            }
            endData( $parameters->{output} );
        }
        elsif ( $dataType eq "OWAMP" ) {
            my $prefix = "summary";
            my $uri    = "http://ggf.org/ns/nmwg/characteristic/delay/summary/20070921/";

            startData( $parameters->{output}, $id, $parameters->{mid}, undef );
            my $len = $#{$result};
            for my $a ( 0 .. $len ) {

                # XXX Jul 22, 2008
                #
                # Owamp needs to be brought up to date.

                if ( $self->{CONF}->{"perfsonarbuoy"}->{"legacy"} ) {
                    my %attrs = ();
                    if ( $timeType eq "unix" ) {
                        $attrs{"timeType"}  = "unix";
                        $attrs{"startTime"} = owptime2exacttime( $result->[$a][3] );
                        $attrs{"endTime"}   = owptime2exacttime( $result->[$a][4] );
                    }
                    else {
                        $attrs{"timeType"}  = "iso";
                        $attrs{"startTime"} = owpexactgmstring( $result->[$a][3] );
                        $attrs{"endTime"}   = owpexactgmstring( $result->[$a][4] );
                    }

                    #min
                    $attrs{"min_delay"} = $result->[$a][5] if defined $result->[$a][5];

                    # max
                    $attrs{"max_delay"} = $result->[$a][6] if defined $result->[$a][6];

                    #sent
                    $attrs{ $dbSchema[9] } = $result->[$a][9] if defined $result->[$a][9];

                    #lost
                    $attrs{"loss"} = $result->[$a][10] if defined $result->[$a][10];

                    #dups
                    $attrs{"duplicates"} = $result->[$a][11] if defined $result->[$a][11];

                    #err
                    $attrs{"maxError"} = $result->[$a][12] if defined $result->[$a][12];

                    $parameters->{output}->createElement(
                        prefix     => $prefix,
                        namespace  => $uri,
                        tag        => "datum",
                        attributes => \%attrs
                    );
                }
                else {
                }
            }
            endData( $parameters->{output} );
        }
    }
    return;
}

=head2 addSelectParameters($self, { parameter_block, filters })

Re-construct the parameters block.

=cut

sub addSelectParameters {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(
        @args,
        {
            parameter_block => 1,
            filters         => 1,
        }
    );

    my $params       = $parameters->{parameter_block};
    my @filters      = @{ $parameters->{filters} };
    my %paramsByName = ();

    foreach my $p ( $params->childNodes ) {
        if ( $p->localname and $p->localname eq "parameter" and $p->getAttribute("name") ) {
            $paramsByName{ $p->getAttribute("name") } = $p;
        }
    }

    foreach my $filter_arr (@filters) {
        my @filters = @{$filter_arr};
        my $filter  = $filters[-1];

        $self->{LOGGER}->debug( "Filter: " . $filter->toString );

        my $select_params = find( $filter, "./select:parameters", 1 );
        if ($select_params) {
            foreach my $p ( $select_params->childNodes ) {
                if ( $p->localname and $p->localname eq "parameter" and $p->getAttribute("name") ) {
                    my $newChild = $p->cloneNode(1);
                    if ( $paramsByName{ $p->getAttribute("name") } ) {
                        $params->replaceChild( $newChild, $paramsByName{ $p->getAttribute("name") } );
                    }
                    else {
                        $params->addChild($newChild);
                    }
                    $paramsByName{ $p->getAttribute("name") } = $newChild;
                }
            }
        }
    }
    return;
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Module::Load>, L<Digest::MD5>, L<English>,
L<Params::Validate>, L<Sys::Hostname>, L<Fcntl>, L<Date::Manip>,
L<Math::BigInt>, L<perfSONAR_PS::Config::OWP>,
L<perfSONAR_PS::Config::OWP::Utils>, L<perfSONAR_PS::Services::MA::General>,
L<perfSONAR_PS::Common>, L<perfSONAR_PS::Messages>,
L<perfSONAR_PS::Client::LS::Remote>, L<perfSONAR_PS::Error_compat>,
L<perfSONAR_PS::DB::File>, L<perfSONAR_PS::DB::SQL>,
L<perfSONAR_PS::Utils::ParameterValidation>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2007-2009, Internet2

All rights reserved.

=cut
