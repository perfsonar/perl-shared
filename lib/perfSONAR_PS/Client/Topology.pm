package perfSONAR_PS::Client::Topology;

use strict;
use warnings;

our $VERSION = 3.3;

use fields 'URI_STRING', 'LOGGER', 'TIMEOUT', 'ALARM_DISABLED';

=head1 NAME

perfSONAR_PS::Client::Topology

=head1 DESCRIPTION

A module that provides methods for interacting with Topology Services.  This
modules allows one to interact with the Topology Service via its Web Services
interface. The API provided is identical to the API for interacting with the
topology database directly. Thus, a client written to read from or update a
Topology Service can be easily modified to interact directly with its
underlying database allowing more efficient interactions if required.

The module is to be treated as an object, where each instance of the object
represents a connection to a single database. Each method may then be invoked on
the object for the specific database.  

=cut

use Log::Log4perl qw(get_logger);
use perfSONAR_PS::Common;
use perfSONAR_PS::Transport;

=head2 new($package, $uri_string)

The new function takes a URI connection string as its first argument. This
specifies which TS to interact with.

=cut

my $TIMEOUT = 60; # default timeout

sub new {
    my ( $package, $uri_string, $timeout, $alarm_disabled ) = @_;

    my $self = fields::new( $package );

    $self->{LOGGER} = get_logger( $package );

    if ( defined $uri_string and $uri_string ) {
        $self->{"URI_STRING"} = $uri_string;
    }
    $self->{TIMEOUT} = $TIMEOUT;
    if ( defined $timeout and $timeout ) {
        $self->{"TIMEOUT"} = $timeout;
    }
    $self->{ALARM_DISABLED} = 0;
    if ( defined $alarm_disabled and $alarm_disabled ) {
        $self->{"ALARM_DISABLED"} = $alarm_disabled;
    }
    
    
    return $self;
}

=head2 open($self)

The open function could be used to open a persistent connection to the TS.
However, currently, it is simply a stub function.

=cut

sub open {
    my ( $self ) = @_;
    return ( 0, q{} );
}

=head2 close($self)

The close function could close a persistent connection to the TS. However,
currently, it is simply a stub function.

=cut

sub close {
    my ( $self ) = @_;
    return 0;
}

=head2 setURIString($self, $uri_string)

The setURIString function changes the TS that the instance uses.

=cut

sub setURIString {
    my ( $self, $uri_string ) = @_;
    $self->{URI_STRING} = $uri_string;
    return;
}

=head2 dbIsOpen($self)

This function is a stub function that always returns 1.

=cut

sub dbIsOpen {
    return 1;
}

=head2 getURIString($)

The getURIString function returns the current URI string

=cut

sub getURIString {
    my ( $self ) = @_;
    return $self->{URI_STRING};
}

=head2 buildQueryRequest($xquery)

A function which constructs a query message out of the specified xquery string.

=cut

sub buildQueryRequest {
    my ( $xquery ) = shift;

    my $request = q{};

    $request .= "<nmwg:message type=\"QueryRequest\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= "<nmwg:metadata id=\"meta0\">\n";
    if ( defined $xquery and $xquery ) {
        $request .= "  <xquery:subject id=\"sub1\" xmlns:xquery=\"http://ggf.org/ns/nmwg/tools/org/perfsonar/xquery/1.0/\">\n";
        $request .= $xquery;
        $request .= "  </xquery:subject>\n";
    }
    $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/topology/20070809</nmwg:eventType>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\" />\n";
    $request .= "</nmwg:message>\n";

    return ( q{}, $request );
}

=head2 buildChangeRequest($type, $topology)

A function which constructs a change topology message out of the specified change type and topology.

=cut

sub buildChangeRequest {
    my ( $type, $topology ) = @_;
    my $msgType;

    if ( defined $type and $type eq "add" ) {
        $msgType = "TSAddRequest";
    }
    elsif ( defined $type and $type eq "update" ) {
        $msgType = "TSUpdateRequest";
    }
    elsif ( defined $type and $type eq "replace" ) {
        $msgType = "TSReplaceRequest";
    }

    my $request = q{};

    $request .= "<nmwg:message type=\"$msgType\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= "<nmwg:metadata id=\"meta0\">\n";
    $request .= "  <nmwg:eventType>http://ggf.org/ns/nmwg/topology/20070809</nmwg:eventType>\n";
    $request .= "</nmwg:metadata>\n";
    $request .= "<nmwg:data id=\"data0\" metadataIdRef=\"meta0\">\n";
    my $elm = $topology->cloneNode( 1 );
    $elm->unbindNode();

    $request .= $elm->toString;
    $request .= "</nmwg:data>\n";
    $request .= "</nmwg:message>\n";

    return $request;
}

=head2 xQuery($self, $xquery, $encoded)

The xQuery function performs an xquery on the specified TS. It returns the
results as a string or as a dom object if the $encoded flag is set.

=cut

sub xQuery {
    my ( $self, $xquery, $encoded ) = @_;
    my $localContent = q{};
    my $error;
    my ( $status, $res, $request );

    ( $status, $request ) = buildQueryRequest( $xquery );

    my ( $host, $port, $endpoint ) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if ( not defined $host and not defined $port and not defined $endpoint ) {
        my $msg = "Specified argument is not a URI";
        $self->{LOGGER}->error( $msg );
        return ( -1, $msg );
    }

    ( $status, $res ) = consultArchive( $host, $port, $endpoint, $request, $self->{"TIMEOUT"}, $self->{"ALARM_DISABLED"} );
    if ( $status != 0 ) {
        my $msg = "Error consulting archive: $res";
        $self->{LOGGER}->error( $msg );
        return ( -1, $msg );
    }

    my $topo_msg = $res;

    my $data_elms = find( $topo_msg, './*[local-name()="data"]', 0 );
    if ( $data_elms ) {
        foreach my $data ( $data_elms->get_nodelist ) {
            my $metadata_elms = find( $topo_msg, './*[local-name()="metadata"]', 0 );
            if ( $metadata_elms ) {
                foreach my $metadata ( $metadata_elms->get_nodelist ) {
                    if ( $data->getAttribute( "metadataIdRef" ) eq $metadata->getAttribute( "id" ) ) {
                        my $topology = find( $data, './*[local-name()="topology"]', 1 );
                        if ( $topology ) {
                            unless ($encoded) {
                                return ( 0, $topology->toString );
                            }
                            else {
                                return ( 0, $topology );
                            }
                        }
                    }
                }
            }
        }
    }

    my $msg = "Response does not contain a topology";
    $self->{LOGGER}->error( $msg );
    return ( -1, $msg );
}

=head2 getAll($self)

The getAll function gets the full contents of the TS. It returns the results as
a ref to a LibXML element pointing to the <nmtopo:topology> structure containing
the contents of the TS's database. 

=cut

sub getAll {
    my ( $self ) = @_;
    my @results;
    my $error;
    my ( $status, $res );

    my $request = buildQueryRequest( q{} );

    my ( $host, $port, $endpoint ) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if ( not defined $host and not defined $port and not defined $endpoint ) {
        my $msg = "Specified argument is not a URI";
        $self->{LOGGER}->error( $msg );
        return ( -1, $msg );
    }

    ( $status, $res ) = consultArchive( $host, $port, $endpoint, $request, $self->{"TIMEOUT"}, $self->{"ALARM_DISABLED"} );
    if ( $status != 0 ) {
        my $msg = "Error consulting archive: $res";
        $self->{LOGGER}->error( $msg );
        return ( -1, $msg );
    }

    my $topo_msg = $res;

    my $data_elms = find( $topo_msg, './*[local-name()="data"]', 0 );
    if ( $data_elms ) {
        foreach my $data ( $data_elms->get_nodelist ) {

            my $metadata_elms = find( $topo_msg, './*[local-name()="metadata"]', 0 );
            if ( $metadata_elms ) {
                foreach my $metadata ( $metadata_elms->get_nodelist ) {
                    if ( $data->getAttribute( "metadataIdRef" ) eq $metadata->getAttribute( "id" ) ) {
                        my $topology = find( $data, './nmtopo:topology', 1 );
                        if ( $topology ) {
                            return ( 0, $topology );
                        }
                    }
                }
            }
        }
    }

    my $msg = "Response does not contain a topology";
    $self->{LOGGER}->error( $msg );
    return ( -1, $msg );
}

=head2 changeTopology($self, $type, $topology)

A function which takes the specified type and topology and updates the remote
Topology Service. Returns an array whose first element is 0 on success and -1
on failure. On failure, the second element will contain an error message.

=cut

sub changeTopology {
    my ( $self, $type, $topology ) = @_;
    my @results;
    my $error;
    my ( $status, $res );

    my $request = buildChangeRequest( $type, $topology );

    $self->{LOGGER}->debug( "Change Request: " . $request );

    my ( $host, $port, $endpoint ) = &perfSONAR_PS::Transport::splitURI( $self->{URI_STRING} );
    if ( not defined $host and not defined $port and not defined $endpoint ) {
        my $msg = "Specified argument is not a URI";
        $self->{LOGGER}->error( $msg );
        return ( -1, $msg );
    }

    ( $status, $res ) = consultArchive( $host, $port, $endpoint, $request, $self->{"TIMEOUT"}, $self->{"ALARM_DISABLED"} );
    if ( $status != 0 ) {
        my $msg = "Error consulting archive: $res";
        $self->{LOGGER}->error( $msg );
        return ( -1, $msg );
    }

    my $topo_msg = $res;

    $self->{LOGGER}->debug( "Change Response: " . $topo_msg->toString );

    my $find_res;

    $find_res = find( $res, "./nmwg:data", 0 );
    if ( $find_res ) {
        foreach my $data ( $find_res->get_nodelist ) {
            my $metadata = find( $res, "./nmwg:metadata[\@id='" . $data->getAttribute( "metadataIdRef" ) . "']", 1 );
            unless ( $metadata ) {
                return ( -1, "No metadata in response" );
            }

            my $eventType = findvalue( $metadata, "nmwg:eventType" );
            if ( $eventType and $eventType =~ /^error\./x ) {
                my $error_msg = findvalue( $data, "./nmwgr:datum" );
                $error_msg = "Unknown error" if ( not defined $error_msg or $error_msg eq q{} );
                return ( -1, $error_msg );
            }
            elsif ( $eventType and $eventType =~ /^success\./x ) {
                return ( 0, "Success" );
            }
        }
    }

    my $msg = "Response does not contain status";
    $self->{LOGGER}->error( $msg );
    return ( -1, $msg );
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<perfSONAR_PS::Common>, L<perfSONAR_PS::Transport>, 

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

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
