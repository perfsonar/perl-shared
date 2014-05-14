package perfSONAR_PS::DB::XMLDB;

use strict;
use warnings;

our $VERSION = 3.3;

use fields 'ENVIRONMENT', 'CONTAINERFILE', 'NAMESPACES', 'ENV', 'MANAGER', 'CONTAINER', 'INDEX', 'LOGGER', 'NETLOGGER', 'DISABLETXN';

=head1 NAME

perfSONAR_PS::DB::XMLDB

=head1 DESCRIPTION

A module that provides methods for dealing with the Sleepycat [Oracle] XML
database.  This module wraps methods and techniques from the Sleepycat::DbXml
API for interacting with the Sleepycat [Oracle] XML database.  The module is to
be treated as an object, where each instance of the object represents a direct
connection to a single database and collection. Each method may then be invoked
on the object for the specific database.  

=cut

use Sleepycat::DbXml 'simple';
use Log::Log4perl qw(get_logger);
use XML::LibXML;
use English qw( -no_match_vars );
use Params::Validate qw(:all);

use perfSONAR_PS::Common;
use perfSONAR_PS::Utils::NetLogger;
use perfSONAR_PS::Utils::ParameterValidation;

=head2 new($package, { env, cont, ns, disableTxn }) 

Create a new XMLDB object.  All arguments are optional:

 * env - path to the xmldb data directory
 * cont - name of the 'container' inside of the xmldb
 * ns - hash reference of namespace values to register
 * disableTxn - boolean that will allow the user (when set to '1' to proceed
                without using dbxml transactions

The arguments can be set (and re-set) via the appropriate function calls.  

=cut

sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { env => 0, cont => 0, ns => 0, disableTxn => 0 } );

    my $self = fields::new( $package );
    $self->{LOGGER} = get_logger( "perfSONAR_PS::DB::XMLDB" );
    $self->{NETLOGGER} = get_logger( "NetLogger" );
    $self->{DISABLETXN} = 0;
    if ( exists $parameters->{disableTxn} and $parameters->{disableTxn} ) {
        $self->{DISABLETXN} = 1;
    }
    if ( exists $parameters->{env} and $parameters->{env} ) {
        $self->{ENVIRONMENT} = $parameters->{env};
    }
    if ( exists $parameters->{cont} and $parameters->{cont} ) {
        $self->{CONTAINERFILE} = $parameters->{cont};
    }
    if ( exists $parameters->{ns} and $parameters->{ns} ) {
        $self->{NAMESPACES} = \%{ $parameters->{ns} };
    }
    return $self;
}

=head2 setDisableTxn($self, { disableTxn })

(Re-)Sets the "disableTxn" flag - preventing the use of XMLDB transactions for 
all database operations.  

=cut

sub setDisableTxn {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { disableTxn => 1 } );

    if ( exists $parameters->{disableTxn} and $parameters->{disableTxn} ) {
        $self->{DISABLETXN} = 1;
        return 0;
    }
    $self->{LOGGER}->error( "Cannot set disableTxn flag." );
    return -1;
}

=head2 setEnvironment($self, { env })

(Re-)Sets the "environment" (the directory where the xmldb was created, such as 
'/usr/local/LS/xmldb'; this should not be confused with the actual 
installation directory).

=cut

sub setEnvironment {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { env => 1 } );

    if ( exists $parameters->{env} and $parameters->{env} ) {
        $self->{ENVIRONMENT} = $parameters->{env};
        return 0;
    }
    $self->{LOGGER}->error( "Cannot set environment." );
    return -1;
}

=head2 setContainer($self, { cont })

(Re-)Sets the "container" (a specific file that lives in the environment, such
as 'snmpstore.dbxml'; many containers can live in a single environment).

=cut

sub setContainer {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { cont => 1 } );

    if ( exists $parameters->{cont} and $parameters->{cont} ) {
        $self->{CONTAINERFILE} = $parameters->{cont};
        return 0;
    }
    $self->{LOGGER}->error( "Cannot set container." );
    return -1;
}

=head2 setNamespaces($self, { ns })

(Re-)Sets the hash reference containing a prefix to namespace mapping.  All
namespaces that may appear in the container should be mapped (there is no harm
is sending mappings that will not be used).

=cut

sub setNamespaces {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { ns => 1 } );

    if ( exists $parameters->{ns} and $parameters->{ns} ) {
        $self->{NAMESPACES} = \%{ $parameters->{ns} };
        return 0;
    }
    $self->{LOGGER}->error( "Cannot set namespaces hash." );
    return -1;
}

=head2 prep($self, { txn, error })

Prepares the database for use, this is called only once usually when the
service starts up.  The purpose of this function is to create the database (if
brand new) or perform recovery operations (if the database exists already).  A
transaction element may be passed in from the caller, or this argument can be
left blank for an atomic operation.  The error argument is optional.

=cut

sub prep {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { txn => 0, error => 0 } );

    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.prep.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }
    eval {
        $self->{ENV} = new DbEnv( 0 );

        if ( $self->{DISABLETXN} == 1 ) {
            # XXX: JZ 11/7/2008 - These options were removed: Db::DB_JOINENV | Db::DB_REGISTER
            $self->{ENV}->open( $self->{ENVIRONMENT}, Db::DB_CREATE | Db::DB_RECOVER | Db::DB_JOINENV | Db::DB_INIT_LOG | Db::DB_INIT_LOCK | Db::DB_INIT_MPOOL );

            # XXX: JZ 11/7/2008 - These options were removed: DbXml::DBXML_ALLOW_EXTERNAL_ACCESS | DbXml::DBXML_ALLOW_AUTO_OPEN
            $self->{MANAGER} = new XmlManager( $self->{ENV} );

            # XXX: JZ 11/7/2008 - This option was removed: Db::DB_DIRTY_READ
            $self->{CONTAINER} = $self->{MANAGER}->openContainer( $self->{CONTAINERFILE}, Db::DB_CREATE | DbXml::DBXML_TRANSACTIONAL );

            # XXX: JZ 11/7/2008 - Disable index for now
            #        unless ( $self->{CONTAINER}->getIndexNodes ) {
            #            my $dbUC = $self->{MANAGER}->createUpdateContext();
            #            $self->{INDEX} = $self->{CONTAINER}->addIndex( "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            #        }
        }
        else {
            # XXX: JZ 11/7/2008 - These options were removed: Db::DB_JOINENV | Db::DB_REGISTER
            $self->{ENV}->open( $self->{ENVIRONMENT}, Db::DB_CREATE | Db::DB_RECOVER | Db::DB_JOINENV | Db::DB_INIT_LOG | Db::DB_INIT_LOCK | Db::DB_INIT_MPOOL | Db::DB_INIT_TXN );

            # XXX: JZ 11/7/2008 - These options were removed: DbXml::DBXML_ALLOW_EXTERNAL_ACCESS | DbXml::DBXML_ALLOW_AUTO_OPEN
            $self->{MANAGER} = new XmlManager( $self->{ENV} );

            $dbTr = $self->{MANAGER}->createTransaction() if $atomic;

            # XXX: JZ 11/7/2008 - This option was removed: Db::DB_DIRTY_READ
            $self->{CONTAINER} = $self->{MANAGER}->openContainer( $dbTr, $self->{CONTAINERFILE}, Db::DB_CREATE | DbXml::DBXML_TRANSACTIONAL );

            # XXX: JZ 11/7/2008 - Disable index for now
            #        unless ( $self->{CONTAINER}->getIndexNodes ) {
            #            my $dbUC = $self->{MANAGER}->createUpdateContext();
            #            $self->{INDEX} = $self->{CONTAINER}->addIndex( $dbTr, "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            #        }

            if ( $atomic ) {
                $dbTr->commit;
                undef $dbTr;
            }
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.prep.end", {status=>-1,error=>$msg,});
        $self->{NETLOGGER}->debug( $nlmsg );
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.prep.end", {status=>-1,error=>$msg,});
        $self->{NETLOGGER}->debug( $nlmsg );
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.prep.end", {status=>-1,error=>$msg,});
        $self->{NETLOGGER}->debug( $nlmsg );
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.prep.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 openDB($self, { txn, error })

Opens the database environment and containers.  A transaction element may be
passed in from the caller, or this argument can be left blank for an atomic
operation.  The error argument is optional. 

=cut

sub openDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { txn => 0, error => 0 } );

    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.openDB.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }
    eval {
        $self->{ENV} = new DbEnv( 0 );

        if ( $self->{DISABLETXN} == 1 ) {
            $self->{ENV}->open( $self->{ENVIRONMENT}, Db::DB_CREATE | Db::DB_JOINENV | Db::DB_INIT_LOG | Db::DB_INIT_LOCK | Db::DB_INIT_MPOOL );

            # XXX: JZ 11/7/2008 - These options were removed: DbXml::DBXML_ALLOW_EXTERNAL_ACCESS | DbXml::DBXML_ALLOW_AUTO_OPEN
            $self->{MANAGER} = new XmlManager( $self->{ENV} );

            # XXX: JZ 11/7/2008 - These options were removed: Db::DB_DIRTY_READ
            $self->{CONTAINER} = $self->{MANAGER}->openContainer( $self->{CONTAINERFILE}, Db::DB_CREATE | DbXml::DBXML_TRANSACTIONAL );

            # XXX: JZ 11/7 - Disable index for now
            #        unless ( $self->{CONTAINER}->getIndexNodes ) {
            #            my $dbUC = $self->{MANAGER}->createUpdateContext();
            #            $self->{INDEX} = $self->{CONTAINER}->addIndex( "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            #        }
        }
        else {
            $self->{ENV}->open( $self->{ENVIRONMENT}, Db::DB_CREATE | Db::DB_JOINENV | Db::DB_INIT_LOG | Db::DB_INIT_LOCK | Db::DB_INIT_MPOOL | Db::DB_INIT_TXN );

            # XXX: JZ 11/7/2008 - These options were removed: DbXml::DBXML_ALLOW_EXTERNAL_ACCESS | DbXml::DBXML_ALLOW_AUTO_OPEN
            $self->{MANAGER} = new XmlManager( $self->{ENV} );

            $dbTr = $self->{MANAGER}->createTransaction() if $atomic;

            # XXX: JZ 11/7/2008 - These options were removed: Db::DB_DIRTY_READ
            $self->{CONTAINER} = $self->{MANAGER}->openContainer( $dbTr, $self->{CONTAINERFILE}, Db::DB_CREATE | DbXml::DBXML_TRANSACTIONAL );

            # XXX: JZ 11/7 - Disable index for now
            #        unless ( $self->{CONTAINER}->getIndexNodes ) {
            #            my $dbUC = $self->{MANAGER}->createUpdateContext();
            #            $self->{INDEX} = $self->{CONTAINER}->addIndex( $dbTr, "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            #        }

            if ( $atomic ) {
                $dbTr->commit;
                undef $dbTr;
            }
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.openDB.end", {status=>-1,error=>$msg,});
        $self->{NETLOGGER}->debug( $nlmsg );
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.openDB.end", {status=>-1,error=>$msg,});
        $self->{NETLOGGER}->debug( $nlmsg );
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.openDB.end", {status=>-1,error=>$msg,});
        $self->{NETLOGGER}->debug( $nlmsg );
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.openDB.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 indexDB($self, { txn, error })

Creates a simple index for the database if one does not exist.  A transaction
element may be passed in from the caller, or this argument can be left blank
for an atomic operation.  The error argument is optional.

=cut

sub indexDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.indexDB.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    eval {
        if ( $self->{DISABLETXN} == 1 ) {
            unless ( $self->{CONTAINER}->getIndexNodes and $self->{INDEX} )
            {
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{INDEX} = $self->{CONTAINER}->addIndex( "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            }
        }
        else {
            unless ( $self->{CONTAINER}->getIndexNodes and $self->{INDEX} )
            {
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{INDEX} = $self->{CONTAINER}->addIndex( $dbTr, "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            }
            if ( $atomic ) {
                $dbTr->commit;
                undef $dbTr;
            }
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.indexDB.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 deIndexDB($self, { txn, error })

Removes a simple index from the database if one does exist.  A transaction
element may be passed in from the caller, or this argument can be left blank
for an atomic operation.  The error argument is optional.

=cut

sub deIndexDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { txn => 0, error => 0 } );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    eval {
        my $dbUC = $self->{MANAGER}->createUpdateContext();
        if ( $self->{DISABLETXN} == 1 ) { 
            if ( $self->{CONTAINER}->getIndexNodes and $self->{INDEX} ) {
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{INDEX} = $self->{CONTAINER}->deleteIndex( "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            }
        }
        else {    
            if ( $self->{CONTAINER}->getIndexNodes and $self->{INDEX} ) {
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{INDEX} = $self->{CONTAINER}->deleteIndex( $dbTr, "http://ggf.org/ns/nmwg/base/2.0/", "store", "node-element-equality-string", $dbUC );
            }
            if ( $atomic ) {
                $dbTr->commit;
                undef $dbTr;
            }
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    return 0;
}

=head2 getTransaction($self, { error })

Creates a new transaction object.  The error argument is optional.

=cut

sub getTransaction {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.getTransaction.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr = q{};
    eval {
        if ( $self->{DISABLETXN} == 0 ) {
            if ( exists $self->{MANAGER} and $self->{MANAGER} )
            {
                $dbTr = $self->{MANAGER}->createTransaction();
            }
        }
        else {
            $self->{LOGGER}->error( "Tranactions have been disabled, returned transaction object will be NULL." );
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.getTransaction.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return $dbTr;
}

=head2 commitTransaction($self, { dbTr, error })

Given a transaction object, commit it.  The error argument is optional.

=cut

sub commitTransaction {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.commitTransaction.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    eval {
        if ( $self->{DISABLETXN} == 0 ) {
            $parameters->{txn}->commit() if exists $parameters->{txn};
            undef $parameters->{txn};
        }
        else {
            $self->{LOGGER}->error( "Tranactions have been disabled, will not commit transaction." );
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.commitTransaction.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 abortTransaction($self, { dbTr, error })

Given a transaction object, abort it.  The error argument is optional.

=cut

sub abortTransaction {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { txn => 0, error => 0 } );

    eval {
        if ( $self->{DISABLETXN} == 0 ) {
            $parameters->{txn}->abort() if exists $parameters->{txn};
            undef $parameters->{txn};
        }
        else {
            $self->{LOGGER}->error( "Tranactions have been disabled, will not abort transaction." );
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    return 0;
}

=head2 checkpoint($self, { error })

Create a logging checkpoint.

=cut

sub checkpoint {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.checkpoint.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    eval {
        if ( $self->{DISABLETXN} == 0 ) {
            $self->{LOGGER}->debug( "Checkpoint started." );
            $self->{ENV}->txn_checkpoint( 0, 0, Db::DB_FORCE ); 
        }
        else {
            $self->{LOGGER}->error( "Tranactions have been disabled, will not create checkpoint." );
        }
    };
    if ( my $e = catch std::exception ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $e = catch DbException ) {
        my $msg = "Error \"" . $e->what() . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    elsif ( $EVAL_ERROR ) {
        my $msg = "Error \"" . $EVAL_ERROR . "\".";
        $msg =~ s/(\n+|\s+)/ /gmx;
        $msg = escapeString( $msg );
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    $self->{LOGGER}->debug( "Checkpoint complete." );
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.checkpoint.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 query($self, { query, txn, error }) 

The string $query must be an XPath expression to be sent to the database.
Examples are:

  //nmwg:metadata
  
    or
    
  //nmwg:parameter[@name="SNMPVersion" and @value="1"]
  
Results are returned as an array of strings or error status.  This function
should be used for XPath statements.  The error parameter is optional and is a
reference to a scalar. The function will use it to return the error message if
one occurred, it returns the empty string otherwise.

A transaction element may be passed in from the caller, or this argument can be
left blank for an atomic operation.  The error argument is optional.

=cut

sub query {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, txn => 0, internal => 0, error => 0 } );

    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.query.start");
    $self->{NETLOGGER}->debug( $nlmsg );
    my @resString = ();

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{query} and $parameters->{query} ) {
        my $results   = q{};
        my $value     = q{};
        my $fullQuery = q{};
        eval {
            my $contName = $self->{CONTAINER}->getName();

            unless ( exists $parameters->{internal} and $parameters->{internal} ) {
                # make sure the query is clean
                $parameters->{query} =~ s/&/&amp;/gmx;
                $parameters->{query} =~ s/</&lt;/gmx;
                $parameters->{query} =~ s/>/&gt;/gmx;
            }

            if ( $parameters->{query} =~ m/collection\(/mx ) {
                $parameters->{query} =~ s/CHANGEME/$contName/gmx;
                $fullQuery = $parameters->{query};
            }
            else {
                $fullQuery = "collection('" . $contName . "')$parameters->{query}";
            }

            $self->{LOGGER}->debug( "Query \"" . $fullQuery . "\" received." );

            my $dbQC = $self->{MANAGER}->createQueryContext();
            foreach my $prefix ( keys %{ $self->{NAMESPACES} } ) {
                $dbQC->setNamespace( $prefix, $self->{NAMESPACES}->{$prefix} );
            }

            if ( $self->{DISABLETXN} == 1 ) { 
                $results = $self->{MANAGER}->query( $fullQuery, $dbQC );
                while ( $results->next( $value ) ) {
                    push @resString, $value;
                    undef $value;
                }
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                $results = $self->{MANAGER}->query( $dbTr, $fullQuery, $dbQC );
                while ( $results->next( $value ) ) {
                    push @resString, $value;
                    undef $value;
                }
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( "Missing argument" );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.query.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return @resString;
}

=head2 querySet($self, { query, txn, error }) 

Given a query, return the 'name' of the container.  A transaction element may
be passed in from the caller, or this argument can be left blank for an atomic
operation.  The error argument is optional.

=cut

sub querySet {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, txn => 0, error => 0 } );

    my $res = new XML::LibXML::NodeList;
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.querySet.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{query} and $parameters->{query} ) {
        my $results   = q{};
        my $value     = q{};
        my $fullQuery = q{};
        eval {
            my $contName = $self->{CONTAINER}->getName();

            # make sure the query is clean
            $parameters->{query} =~ s/&/&amp;/gmx;
            $parameters->{query} =~ s/</&lt;/gmx;
            $parameters->{query} =~ s/>/&gt;/gmx;

            if ( $parameters->{query} =~ m/collection\(/mx ) {
                $parameters->{query} =~ s/CHANGEME/$contName/gmx;
                $fullQuery = $parameters->{query};
            }
            else {
                $fullQuery = "collection('" . $contName . "')$parameters->{query}";
            }

            $self->{LOGGER}->debug( "Query \"" . $fullQuery . "\" received." );

            my $dbQC = $self->{MANAGER}->createQueryContext();
            foreach my $prefix ( keys %{ $self->{NAMESPACES} } ) {
                $dbQC->setNamespace( $prefix, $self->{NAMESPACES}->{$prefix} );
            }

            if ( $self->{DISABLETXN} == 1 ) {
                $results = $self->{MANAGER}->query( $fullQuery, $dbQC );
                my $parser = XML::LibXML->new();
                while ( $results->next( $value ) ) {
                    my $node = $parser->parse_string( $value );
                    $res->push( $node->getDocumentElement );
                    undef $value;
                    undef $node;
                }
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                $results = $self->{MANAGER}->query( $dbTr, $fullQuery, $dbQC );
                my $parser = XML::LibXML->new();
                while ( $results->next( $value ) ) {
                    my $node = $parser->parse_string( $value );
                    $res->push( $node->getDocumentElement );
                    undef $value;
                    undef $node;
                }
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( "Missing argument" );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.querySet.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return $res;
}

=head2 queryForName($self, { query, txn, error }) 

Given a query, see if it exists in the container and return the document name.
A transaction element may be passed in from the caller, or this argument can be
left blank for an atomic operation.  The error argument is optional.

=cut

sub queryForName {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.queryForName.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my @resString = ();

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{query} and $parameters->{query} ) {
        my $results   = q{};
        my $doc       = q{};
        my $fullQuery = q{};
        eval {
            my $contName = $self->{CONTAINER}->getName();

            # make sure the query is clean
            $parameters->{query} =~ s/&/&amp;/gmx;
            $parameters->{query} =~ s/</&lt;/gmx;
            $parameters->{query} =~ s/>/&gt;/gmx;

            if ( $parameters->{query} =~ m/collection\(/mx ) {
                $parameters->{query} =~ s/CHANGEME/$contName/gmx;
                $fullQuery = $parameters->{query};
            }
            else {
                $fullQuery = "collection('" . $contName . "')$parameters->{query}";
            }

            $self->{LOGGER}->debug( "Query \"" . $fullQuery . "\" received." );

            my $dbQC = $self->{MANAGER}->createQueryContext();
            foreach my $prefix ( keys %{ $self->{NAMESPACES} } ) {
                $dbQC->setNamespace( $prefix, $self->{NAMESPACES}->{$prefix} );
            }

            if ( $self->{DISABLETXN} == 1 ) { 
                $results = $self->{MANAGER}->query( $fullQuery, $dbQC );
                $doc = $self->{MANAGER}->createDocument();
                while ( $results->next( $doc ) ) {
                    push @resString, $doc->getName;
                }
                undef $doc;
                undef $results;
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                $results = $self->{MANAGER}->query( $dbTr, $fullQuery, $dbQC );
                $doc = $self->{MANAGER}->createDocument();
                while ( $results->next( $doc ) ) {
                    push @resString, $doc->getName;
                }
                undef $doc;
                undef $results;
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( "Missing argument" );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.queryForName.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return @resString;
}

=head2 queryByName($self, { name, txn, error }) 

Given a name, see if it exists in the container.   A transaction element may be
passed in from the caller, or this argument can be left blank for an atomic
operation.  The error argument is optional.

=cut

sub queryByName {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { name => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.queryByName.start", { name => $parameters->{name}, } );
    $self->{NETLOGGER}->debug( $nlmsg );

    my $content = q{};

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( $parameters->{name} ) {
        eval {
            $self->{LOGGER}->debug( "Query for name \"" . $parameters->{name} . "\" received." );            
            if ( $self->{DISABLETXN} == 1 ) { 
                my $document = $self->{CONTAINER}->getDocument( $parameters->{name} );
                $content = $document->getName;
                $self->{LOGGER}->debug( "Document found." );
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                my $document = $self->{CONTAINER}->getDocument( $dbTr, $parameters->{name} );
                $content = $document->getName;
                $self->{LOGGER}->debug( "Document found." );
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            if ( $e->getExceptionCode() == 11 ) {
                $self->{LOGGER}->debug( "Document not found." );
            }
            else {
                my $msg = "Error \"" . $e->what() . "\".";
                $msg =~ s/(\n+|\s+)/ /gmx;
                $msg = escapeString( $msg );
                $self->{LOGGER}->error( $msg );
                ${ $parameters->{error} } = $msg if exists $parameters->{error};
                return;
            }
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.queryByName.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return $content;
}

=head2 getDocumentByName($self, { name, txn, error }) 

Return a document given a it's name.  A transaction element may be passed in
from the caller, or this argument can be left blank for an atomic operation.
The error argument is optional.

=cut

sub getDocumentByName {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { name => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.getDocumentByName.start",  { name => $parameters->{name}, });
    $self->{NETLOGGER}->debug( $nlmsg );

    my $content = q{};

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{name} and $parameters->{name} ) {
        eval {
            if ( $self->{DISABLETXN} == 1 ) { 
                $self->{LOGGER}->debug( "Query for name \"" . $parameters->{name} . "\" received." );
                my $document = $self->{CONTAINER}->getDocument( $parameters->{name} );
                $content = $document->getContent;
                $self->{LOGGER}->debug( "Document found." );
            }
            else {
                $self->{LOGGER}->debug( "Query for name \"" . $parameters->{name} . "\" received." );
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                my $document = $self->{CONTAINER}->getDocument( $dbTr, $parameters->{name} );
                $content = $document->getContent;
                $self->{LOGGER}->debug( "Document found." );
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            if ( $e->getExceptionCode() == 11 ) {
                my $msg = "Document not found";
                $self->{LOGGER}->debug( $msg );
                ${ $parameters->{error} } = $msg if exists $parameters->{error};
                return;
            }
            else {
                my $msg = "Error \"" . $e->what() . "\".";
                $msg =~ s/(\n+|\s+)/ /gmx;
                $msg = escapeString( $msg );
                $self->{LOGGER}->error( $msg );
                ${ $parameters->{error} } = $msg if exists $parameters->{error};
                return;
            }
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
    }
    else {
        my $msg = "Missing argument";
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.getDocumentByName.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return $content;
}

=head2 updateByName($self, { content, name, txn, error })

Update container content by name.  A transaction element may be passed in from
the caller, or this argument can be left blank for an atomic operation.  The
error argument is optional.

=cut

sub updateByName {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { content => 1, name => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.updateByName.start", {name=>$parameters->{name}, content=>$parameters->{content},} );
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{content} and exists $parameters->{name} and $parameters->{content} and $parameters->{name} ) {
        eval {
            $self->{LOGGER}->debug( "Update \"" . $parameters->{content} . "\" for \"" . $parameters->{name} . "\"." );
            my $myXMLDoc = $self->{MANAGER}->createDocument();
            $myXMLDoc->setContent( $parameters->{content} );
            $myXMLDoc->setName( $parameters->{name} );

            my $dbUC = $self->{MANAGER}->createUpdateContext();
            if ( $self->{DISABLETXN} == 1 ) { 
                $self->{CONTAINER}->updateDocument( $myXMLDoc, $dbUC );
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                $self->{CONTAINER}->updateDocument( $dbTr, $myXMLDoc, $dbUC );
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( "Missing argument" );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.updateByName.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 count($self, { query, txn, error }) 

The string $query must also be an XPath expression that is sent to the
database.  The result of this expression is simple the number of elements that
match the query. Returns -1 on error.  A transaction element may be passed in
from the caller, or this argument can be left blank for an atomic operation.  
The error argument is optional.

=cut

sub count {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.count.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $size = -1;

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{query} and $parameters->{query} ) {
        my $results;

        # make sure the query is clean
        $parameters->{query} =~ s/&/&amp;/gmx;
        $parameters->{query} =~ s/</&lt;/gmx;
        $parameters->{query} =~ s/>/&gt;/gmx;

        my $fullQuery = "collection('" . $self->{CONTAINER}->getName() . "')$parameters->{query}";
        eval {
            $self->{LOGGER}->debug( "Query \"" . $fullQuery . "\" received." );
            my $dbQC = $self->{MANAGER}->createQueryContext();
            foreach my $prefix ( keys %{ $self->{NAMESPACES} } ) {
                $dbQC->setNamespace( $prefix, $self->{NAMESPACES}->{$prefix} );
            }

            if ( $self->{DISABLETXN} == 1 ) { 
                $results = $self->{MANAGER}->query( $fullQuery, $dbQC );
                $size = $results->size();
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                $results = $self->{MANAGER}->query( $dbTr, $fullQuery, $dbQC );
                $size = $results->size();
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.count.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return $size;
}

=head2 insertIntoContainer($self, { content, name, txn, error })

Insert the content into the container with the name.   A transaction element
may be passed in from the caller, or this argument can be left blank for an
atomic operation.  The error argument is optional.

=cut

sub insertIntoContainer {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { content => 1, name => 1, txn => 0, error => 0 } );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( $parameters->{content} and $parameters->{name} ) {
        eval {
            $self->{LOGGER}->debug( "Insert \"" . $parameters->{content} . "\" into \"" . $parameters->{name} . "\"." );
            my $myXMLDoc = $self->{MANAGER}->createDocument();
            $myXMLDoc->setContent( $parameters->{content} );
            $myXMLDoc->setName( $parameters->{name} );

            if ( $self->{DISABLETXN} == 1 ) { 
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{CONTAINER}->putDocument( $myXMLDoc, $dbUC, 0 );
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{CONTAINER}->putDocument( $dbTr, $myXMLDoc, $dbUC, 0 );
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            if ( $e->getExceptionCode() == 19 ) {
                $self->{LOGGER}->debug( "Object exists, skipping insertion." );
                ${ $parameters->{error} } = q{} if exists $parameters->{error};
                return -1;
            }
            else {
                my $msg = "Error \"" . $e->what() . "\".";
                $msg =~ s/(\n+|\s+)/ /gmx;
                $msg = escapeString( $msg );
                $self->{LOGGER}->error( $msg );
                ${ $parameters->{error} } = $msg if exists $parameters->{error};
                return -1;
            }
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    return 0;
}

=head2 insertElement($self, { query, content, txn, error })     

Perform a query, and insert the content into this result.  A transaction
element may be passed in from the caller, or this argument can be left blank
for an atomic operation.  The error argument is optional.

=cut

sub insertElement {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { query => 1, content => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.insertElement.start", {content=>$parameters->{content},});
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( exists $parameters->{content} and exists $parameters->{query} and $parameters->{content} and $parameters->{query} ) {
        my $fullQuery = "collection('" . $self->{CONTAINER}->getName() . "')$parameters->{query}";
        eval {
            $self->{LOGGER}->debug( "Query \"" . $fullQuery . "\" and content \"" . $parameters->{content} . "\" received." );
            my $dbQC = $self->{MANAGER}->createQueryContext();
            foreach my $prefix ( keys %{ $self->{NAMESPACES} } ) {
                $dbQC->setNamespace( $prefix, $self->{NAMESPACES}->{$prefix} );
            }
            
            if ( $self->{DISABLETXN} == 1 ) { 
                my $results        = $self->{MANAGER}->query( $fullQuery, $dbQC );
                my $myXMLMod       = $self->{MANAGER}->createModify();
                my $myXMLQueryExpr = $self->{MANAGER}->prepare( $fullQuery, $dbQC );
                $myXMLMod->addAppendStep( $myXMLQueryExpr, $myXMLMod->Element, q{}, $parameters->{content}, -1 );
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $myXMLMod->execute( $results, $dbQC, $dbUC );
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                my $results        = $self->{MANAGER}->query( $dbTr, $fullQuery, $dbQC );
                my $myXMLMod       = $self->{MANAGER}->createModify();
                my $myXMLQueryExpr = $self->{MANAGER}->prepare( $dbTr, $fullQuery, $dbQC );
                $myXMLMod->addAppendStep( $myXMLQueryExpr, $myXMLMod->Element, q{}, $parameters->{content}, -1 );
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $myXMLMod->execute( $dbTr, $results, $dbQC, $dbUC );
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.insertElement.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 remove($self, { name, txn, error })

Remove the container w/ the given name.  A transaction element may be passed in
from the caller, or this argument can be left blank for an atomic operation.
The error argument is optional.

=cut

sub remove {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { name => 1, txn => 0, error => 0 } );
    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.remove.start");
    $self->{NETLOGGER}->debug( $nlmsg );

    my $dbTr   = q{};
    my $atomic = 1;
    if ( $self->{DISABLETXN} == 0 ) {
        if ( exists $parameters->{txn} and $parameters->{txn} ) {
            $dbTr   = $parameters->{txn};
            $atomic = 0;
        }
    }

    if ( $parameters->{name} ) {
        eval {
            $self->{LOGGER}->debug( "Remove \"" . $parameters->{name} . "\" received." );
            if ( $self->{DISABLETXN} == 1 ) { 
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{CONTAINER}->deleteDocument( $parameters->{name}, $dbUC );
            }
            else {
                $dbTr = $self->{MANAGER}->createTransaction() if $atomic;
                my $dbUC = $self->{MANAGER}->createUpdateContext();
                $self->{CONTAINER}->deleteDocument( $dbTr, $parameters->{name}, $dbUC );
                if ( $atomic ) {
                    $dbTr->commit;
                    undef $dbTr;
                }
            }
        };
        if ( my $e = catch std::exception ) {
            if ( $e->getExceptionCode() == 11 ) {
                $self->{LOGGER}->debug( "Document \"" . $parameters->{name} . "\" not found." );
            }
            else {
                my $msg = "Error \"" . $e->what() . "\".";
                $msg =~ s/(\n+|\s+)/ /gmx;
                $msg = escapeString( $msg );
                $self->{LOGGER}->error( $msg );
                ${ $parameters->{error} } = $msg if exists $parameters->{error};
                return -1;
            }
        }
        elsif ( $e = catch DbException ) {
            my $msg = "Error \"" . $e->what() . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
        elsif ( $EVAL_ERROR ) {
            my $msg = "Error \"" . $EVAL_ERROR . "\".";
            $msg =~ s/(\n+|\s+)/ /gmx;
            $msg = escapeString( $msg );
            $self->{LOGGER}->error( $msg );
            ${ $parameters->{error} } = $msg if exists $parameters->{error};
            return -1;
        }
    }
    else {
        my $msg = "Missing argument.";
        $self->{LOGGER}->error( $msg );
        ${ $parameters->{error} } = $msg if exists $parameters->{error};
        return -1;
    }
    ${ $parameters->{error} } = q{} if exists $parameters->{error};
    $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.xmldb.remove.end");
    $self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

=head2 closeDB($self, { error })

Frees local elements for object destruction.  

=cut

sub closeDB {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { error => 0 } );

    foreach my $key ( sort keys %{$self} ) {
        if ( $key ne "ENV" and $key ne "MANAGER" ) {
            undef $self->{$key};
        }
    }
    undef $self->{MANAGER};
    undef $self->{ENV};
    return;
}

=head2 wrapStore( { content, type } )

Adds 'store' tags around some content.  This is to mimic the way eXist deals
with storing XML data.  The 'type' argument is used to type the store file.

=cut

sub wrapStore {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { content => 0, type => 0 } );

    my $store = "<nmwg:store xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\"";
    if ( exists $parameters->{type} and $parameters->{type} ) {
        $store = $store . " type=\"" . $parameters->{type} . "\" ";
    }
    if ( exists $parameters->{content} and $parameters->{content} ) {
        $store = $store . ">\n";
        $store = $store . $parameters->{content};
        $store = $store . "</nmwg:store>\n";
    }
    else {
        $store = $store . "/>\n";
    }
    return $store;
}

1;

__END__

=head1 SYNOPSIS

    use perfSONAR_PS::DB::XMLDB;

    my %ns = (
      nmwg => "http://ggf.org/ns/nmwg/base/2.0/",
      netutil => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
      nmwgt => "http://ggf.org/ns/nmwg/topology/2.0/",
      snmp => "http://ggf.org/ns/nmwg/tools/snmp/2.0/"    
    );
  
    my $db = new perfSONAR_PS::DB::XMLDB( {
        env => "/home/jason/Netradar/MP/SNMP/xmldb",
        cont => "snmpstore.dbxml",
        ns => \%ns,
        disableTxn => 0
      }
    );

    # or also:
    # 
    # my $db = new perfSONAR_PS::DB::XMLDB;
    # $db->setEnvironment( { env => "/home/jason/Netradar/MP/SNMP/xmldb" } );
    # $db->setContainer( { cont => "snmpstore.dbxml" } );
    # $db->setNamespaces( { ns => \%ns } );    
    # $db->setDisableTxn( { disableTxn => 1 } );  
    
    if ($db->openDB == -1) {
      print "Error opening database\n";
    }

    print "There are " , $db->count("//nmwg:metadata") , " elements in the XMLDB.\n\n";

    my @resultsString = $db->query("//nmwg:metadata");   
    if($#resultsString != -1) {    
      for(my $x = 0; $x <= $#resultsString; $x++) {  
        print $x , ": " , $resultsString[$x], "\n";
      }
    }
    else {
      print "Nothing Found.\n";
    }  

    my $xml = "<nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"test\" />";
    if ($db->insertIntoContainer($xml, "test") == -1) {
      print "Couldn't insert node into container\n";
    }

    my $xml2 = "<nmwg:subject xmlns:nmwg='http://ggf.org/ns/nmwg/base/2.0/'/>";
    if ($db->insertElement("/nmwg:metadata[\@id='test']", $xml2) == -1) {
      print "Couldn't insert element\n";
    }

    print "There are " , $db->count("//nmwg:metadata") , " elements in the XMLDB.\n\n";

    my @resultsString = $db->query("//nmwg:metadata");   
    if($#resultsString != -1) {    
      for(my $x = 0; $x <= $#resultsString; $x++) {  
        print $x , ": " , $resultsString[$x], "\n";
      }
    }
    else {
      print "Nothing Found.\n";
    } 

    if ($db->remove("test") == -1) {
      print "Error removing test\n";
    }
  
=head1 SEE ALSO

L<Sleepycat::DbXml>, L<Log::Log4perl>, L<XML::LibXML>, L<English>,
L<Params::Validate>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Utils::ParameterValidation>

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

Jason Zurawski, zurawski@internet2.edu

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

Copyright (c) 2004-2010, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
