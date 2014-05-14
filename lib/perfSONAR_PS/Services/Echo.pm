package perfSONAR_PS::Services::Echo;

use warnings;
use strict;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::Services::Echo - A simple module that implements perfSONAR echo
functionality.

=head1 DESCRIPTION

This module aims to provide a request handler that is compatible with the
perfSONAR echo specification.

=head1 API

=cut

use base 'perfSONAR_PS::Services::Base';

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);
use perfSONAR_PS::Common;
use perfSONAR_PS::Messages;
use perfSONAR_PS::Utils::ParameterValidation;

=head2 init ($self, $handler)

This function is called by the perfSONAR daemon on startup and registers
handlers for the various forms the echo request can take.

=cut

sub init {
    my ( $self, $handler ) = @_;
    my $logger = get_logger( "perfSONAR_PS::Services::Echo" );

    $handler->registerEventHandler( "EchoRequest", "http://schemas.perfsonar.net/tools/admin/echo/2.0",    $self );
    $handler->registerEventHandler( "EchoRequest", "http://schemas.perfsonar.net/tools/admin/echo/ls/2.0", $self );
    $handler->registerEventHandler( "EchoRequest", "http://schemas.perfsonar.net/tools/admin/echo/ma/2.0", $self );
    $handler->registerEventHandler_Regex( "EchoRequest", "^echo.*", $self );

    $handler->registerEventEquivalence( "EchoRequest", "echo.ma", "http://schemas.perfsonar.net/tools/admin/echo/2.0" );
    $handler->registerEventEquivalence( "EchoRequest", "echo.ma", "http://schemas.perfsonar.net/tools/admin/echo/ma/2.0" );
    $handler->registerEventEquivalence( "EchoRequest", "echo.ma", "http://schemas.perfsonar.net/tools/admin/echo/ls/2.0" );

    return 0;
}

=head2 needLS

The echo service does not need an LS, so it always returns 0.

=cut

sub needLS {
    my ( $self ) = @_;

    return 0;
}

=head2 registerLS

A stub function to return an error if one tries to register the echo service
with an LS

=cut

sub registerLS {
    my ( $self, $ret_sleep_time ) = @_;
    my $logger = get_logger( "perfSONAR_PS::Services::Echo" );

    $logger->warn( "Can't register an echo handler with an LS" );

    return -1;
}

=head2 handleEvent($self, { output, messageId, messageType, messageParameters, eventType, subject, filterChain, data, rawRequest, doOutputMetadata })

This function is called when a metadata/data pair is found with an echo
namespace. It adds the standard echo reply onto the message.

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

    my $output             = $parameters->{"output"};
    my $messageId          = $parameters->{"messageId"};
    my $messageType        = $parameters->{"messageType"};
    my $message_parameters = $parameters->{"messageParameters"};
    my $eventType          = $parameters->{"eventType"};
    my $d                  = $parameters->{"data"};
    my $raw_request        = $parameters->{"rawRequest"};
    my @subjects           = @{ $parameters->{'subject'} };
    my $md                 = $subjects[0];

    my $mdID = "metadata." . genuid();
    my $msg  = "The echo request has passed.";

    getResultCodeMetadata( $output, $mdID, $md->getAttribute( "id" ), "success.echo" );
    getResultCodeData( $output, "data." . genuid(), $mdID, $msg, 1 );

    return;
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Params::Validate>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Messages>, L<perfSONAR_PS::Utils::ParameterValidation>

To join the 'perfSONAR-PS Users' mailing list, please visit:

  https://lists.internet2.edu/sympa/info/perfsonar-ps-users

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu
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
