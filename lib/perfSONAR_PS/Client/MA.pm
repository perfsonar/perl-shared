package perfSONAR_PS::Client::MA;

use strict;
use warnings;

our $VERSION = 3.3;

use fields 'INSTANCE', 'LOGGER', 'ALIVE', 'TIMEOUT', 'ALARM_DISABLED', 'data', 'metadata', 'EVENTTYPES', 'PARAMETERS', 'SUBJECT';

=head1 NAME

perfSONAR_PS::Client::MA

=head1 DESCRIPTION

API for calling an MA from a client or another service. Module with a very basic
API to some common MA functions. It supports single and multiple metadata ( md + select md + data per request).

=cut

use Log::Log4perl qw( get_logger );
use Params::Validate qw( :all );
use English qw( -no_match_vars );

use perfSONAR_PS::Common qw( genuid makeEnvelope find extract );
use perfSONAR_PS::Transport;
use perfSONAR_PS::Client::Echo;
use perfSONAR_PS::Utils::ParameterValidation;

=head2 new($package { instance => <instance>, timeout => <timeout>, alarm_disabled => <1|0> })

Constructor for object.  Optional arguments:

=head2   instance

LS instance to be contacted for interaction.  This can also be set via 'setInstance'.

=head2 timeout

timeout value to be used in the low level call

=head2 alarm_disabled

if not set then hard timeout enabled by alarm will be used on the call, if set then timeout
will be set only in the LWP  UserAgent

=cut

my $TIMEOUT = 60; # default timeout


sub new {
    my ( $package, @args ) = @_;
    my $parameters = validateParams( @args, { instance => 0, timeout => 0, alarm_disabled => 0,
                                              parameters =>   0,
					      eventTypes =>  0 ,
					      subject =>   0 } );

    my $self = fields::new( $package );
    $self->{ALIVE}  = 0;
    $self->{LOGGER} = get_logger( "perfSONAR_PS::Client::MA" );
    foreach my $param (qw/instance timeout alarm_disabled parameters subject eventTypes/) {
        if ( exists $parameters->{$param} and $parameters->{$param} ) {
	     my $set_call = $param eq 'alarm_disabled'?'setAlarmDisabled':"set\u$param";
             $self->$set_call({ $param => $parameters->{$param}});
        }
    }
    $self->{TIMEOUT} ||= $TIMEOUT;
    $self->{ALARM_DISABLED} = 0 unless exists $self->{ALARM_DISABLED};
    # for backward compatibility
    $self->{data} = [];
    $self->{metadata} = [];
    return $self;
}

sub getData {
    my ( $self) = @_;
    return  $self->{data};
}

sub getParameters {
    my ( $self) = @_;
    return  $self->{PARAMETERS};
}

sub getEventTypes {
    my ( $self) = @_;
    return  $self->{EVENTTYPES};
}

sub getSubject {
    my ( $self) = @_;
    return  $self->{SUBJECT};
}
sub setParameters {
    my ( $self,  @args ) = @_;
    my $parameters = validateParams( @args, { parameters =>  {required => 1, type => HASHREF} } );
    $self->{PARAMETERS}  =  $parameters->{parameters};
    return  $self->{PARAMETERS};
}

sub setEventTypes {
     my ( $self,  @args ) = @_;
    my $parameters = validateParams( @args, { eventTypes =>   1  } );
    $parameters->{eventTypes} = [$parameters->{eventTypes}]
                 unless ref $parameters->{eventTypes} eq ref [];
    $self->{EVENTTYPES}  =  $parameters->{eventTypes};
    return  $self->{EVENTTYPES};
}

sub setSubject {
    my ( $self,  @args ) = @_;
    my $parameters = validateParams( @args, { subject =>   1 } );
    $parameters->{subject} = [ $parameters->{subject} ]
                 unless ref $parameters->{subject} eq ref [];
    $self->{SUBJECT} =	 $parameters->{subject};
    return  $self->{SUBJECT};
}

sub getMetadata {
    my ( $self) = @_;
    return  $self->{metadata};
}

sub addData {
    my ( $self,  $arg ) = @_;
    push @{$self->{data}}, $arg if $arg;
    return  $self->getData;
}

sub addMetadata {
    my ( $self,  $arg ) = @_;
    push @{$self->{metadata}}, $arg if $arg;
    return  $self->getMetadata;

}

=head2 setAlarmDisabled($self { alarmDisabled})

 Disable alarm codition on LWP call if set 

=cut

sub setAlarmDisabled  {
    my ( $self,  @args ) = @_;
    my $parameters = validateParams( @args, { alarm_disabled => 1 } );
    $self->{ALIVE} = 0;
    $self->{ALARM_DISABLED} =  $parameters->{alarm_disabled};
    return;
}

=head2 setTimeout($self { timeout})

Required argument 'timeout' is timeout value for the call

=cut

sub setTimeout {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { timeout => 1 } );
    $self->{ALIVE}    = 0;
    $self->{TIMEOUT} = $parameters->{timeout};
    return;
}

=head2 setInstance($self { instance })

Required argument 'instance' is the LS instance to be contacted for queries.  

=cut

sub setInstance {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { instance => 1 } );
    $self->{ALIVE}    = 0;
    $self->{INSTANCE} = $parameters->{"instance"};
    return;
}

=head2 callMA($self { message })

Calls the MA instance with the sent message and returns the response (if any). 

=cut

sub callMA {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { message => 1, timeout => 0 } );
    $self->setTimeout(timeout =>  $parameters->{timeout}) if $parameters->{timeout};
    unless ( $self->{INSTANCE} ) {
        $self->{LOGGER}->error( "Instance not defined." );
        return;
    }

    unless ( $self->{ALIVE} ) {
        my $echo_service = perfSONAR_PS::Client::Echo->new( $self->{INSTANCE}, q{}, q{}, $self->{ALARM_DISABLED} );
        my ( $status, $res ) = $echo_service->ping();
        if ( $status == -1 ) {
            $self->{LOGGER}->error( "Ping to " . $self->{INSTANCE} . " failed: $res" );
            return;
        }
        $self->{ALIVE} = 1;
    }

    my ( $host, $port, $endpoint ) = perfSONAR_PS::Transport::splitURI( $self->{INSTANCE} );
    unless ( defined $host and defined $port and defined $endpoint ) {
        return;
    }
    
    my $sender = new perfSONAR_PS::Transport( $host, $port, $endpoint, $self->{ALARM_DISABLED});
    unless ( $sender ) {
        $self->{LOGGER}->error( "LS could not be contaced." );
        return;
    }

    my $error = q{};
    my $responseContent = $sender->sendReceive( makeEnvelope( $parameters->{message} ), $self->{TIMEOUT}, \$error );
    if ( $error ) {
        $self->{ALIVE} = 0;
        $self->{LOGGER}->error( "sendReceive failed: $error" );
        return;
    }

    my $msg    = q{};
    my $parser = XML::LibXML->new();
    if ( defined $responseContent and $responseContent and ( not $responseContent =~ m/^\d+/xm ) ) {
        my $doc = q{};
        eval { $doc = $parser->parse_string( $responseContent ); };
        if ( $EVAL_ERROR ) {
            $self->{LOGGER}->error( "Parser failed: " . $EVAL_ERROR );
        }
        else {
            $msg = $doc->getDocumentElement->getElementsByTagNameNS( "http://ggf.org/ns/nmwg/base/2.0/", "message" )->get_node( 1 );
        }
    }
    else {
        $self->{ALIVE} = 0;
    }
    return $msg;
}

=head2 metadataKeyRequest($self, { subject, eventTypes, parameters, start, end, resolution, consolidationFunction })

Perform a MetadataKeyRequest, the results are returned as a data/metadata pair.

=cut

sub metadataKeyRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { parameters =>  0,
					      eventTypes =>   0,
					      subject =>  0,
                                              start => 0, end => 0, resolution => 0, consolidationFunction => 0 } );
    { 
       no strict 'refs';
       map { ("perfSONAR_PS::Client::MA::set\u$_")->($self, { $_ => $parameters->{$_}}) 
                if   $parameters->{$_} }  qw/subject eventTypes parameters/;  
    }
    my $pass_params = {};
    map { $pass_params->{$_} = $parameters->{$_} if  $parameters->{$_} } qw/start end resolution consolidationFunction/;
    my $content = ''; 
    my $data_content = '';
    my $eventtype_content = '';
    $eventtype_content= join (' ', ( map { "<nmwg:eventType>$_</nmwg:eventType>" } @{$self->getEventTypes} ))
        if $self->getEventTypes && @{$self->getEventTypes};
    my $parameterblock_content = '';
    if ( $self->getParameters && %{$self->getParameters} ) {
        $parameterblock_content  = "    <nmwg:parameters id=\"parameters." . genuid() . "\">\n";
        foreach my $p ( keys %{ $self->getParameters } ) {
            $parameterblock_content  .= "      <nmwg:parameter name=\"" . $p . "\">" . $self->getParameters->{$p} . "</nmwg:parameter>\n";
        }
        $parameterblock_content .= "    </nmwg:parameters>\n";
    } 
    my $request_content = $self->_add_content($content, $pass_params, $data_content, $parameterblock_content, $eventtype_content );
    my $msg = $self->callMA( {  message => $self->createMAMessage( { type => "MetadataKeyRequest", content => $request_content  } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
	return  {data => [], metadata => []};
    }
    my $list   = find( $msg, "./nmwg:metadata", 0 );
    foreach my $md ( $list->get_nodelist ) {
        $md->setNamespace( "http://ggf.org/ns/nmwg/base/2.0/", "nmwg", 0 );
        $self->addMetadata($md->toString);
    }
    $list = find( $msg, "./nmwg:data", 0 );
    foreach my $d ( $list->get_nodelist ) {
        $d->setNamespace( "http://ggf.org/ns/nmwg/base/2.0/", "nmwg", 0 );
        $self->addData( $d->toString );
    }
    return {data =>  $self->{data} , metadata => $self->{metadata}};
}

=head2 dataInfoRequest($self, { subject, eventTypes, parameters })

Perform a DataInfoRequest, the results are returned as a data/metadata pair.

=cut

sub dataInfoRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { parameters => 0,
					      eventTypes =>   0,
					      subject =>  0 } );
    { 
       no strict 'refs';
       map {("perfSONAR_PS::Client::MA::set\u$_")->($self,  { $_ => $parameters->{$_}}) 
           if $parameters->{$_} }  qw/subject eventTypes parameters/;
    }
    my $content = '';
    my $data_content = '';
    my $eventtype_content = '';
    $eventtype_content = join (' ', ( map { "<nmwg:eventType>$_</nmwg:eventType>" } @{$self->getEventTypes} ))
        if $self->getEventTypes && @{$self->getEventTypes};
    my $parameterblock_content = '';
    if ( $self->getParameters && %{$self->getParameters} ) {
        $parameterblock_content  = "    <nmwg:parameters id=\"parameters." . genuid() . "\">\n";
        foreach my $p ( keys %{ $self->getParameters } ) {
            $parameterblock_content  .= "      <nmwg:parameter name=\"" . $p . "\">" . $self->getParameters->{$p} . "</nmwg:parameter>\n";
        }
        $parameterblock_content .= "    </nmwg:parameters>\n";
    }
    my $request_content = $self->_add_content($content, undef,  $data_content, $parameterblock_content, $eventtype_content);
    my $msg = $self->callMA( { message => $self->createMAMessage( { type => "DataInfoRequest", content => $request_content } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }
    my $list   = find( $msg, "./nmwg:metadata", 0 );
    foreach my $md ( $list->get_nodelist ) {
        $md->setNamespace( "http://ggf.org/ns/nmwg/base/2.0/", "nmwg", 0 );
        $self->addMetadata($md->toString);
    }
    $list = find( $msg, "./nmwg:data", 0 );
    foreach my $d ( $list->get_nodelist ) {
        $d->setNamespace( "http://ggf.org/ns/nmwg/base/2.0/", "nmwg", 0 );
        $self->addData( $d->toString );
    }
    return {data =>  $self->{data} , metadata => $self->{metadata}};
}
#
# add chained md if there parameters were provided
#

sub _addChainedMd {
    my ($self, $pass_params, $chain_content) = @_;
        $chain_content .= "    <select:parameters id=\"parameters." . genuid() . 
	            "\" xmlns:select=\"http://ggf.org/ns/nmwg/ops/select/2.0/\">\n";
    if( $pass_params ) {
	if ( exists  $pass_params->{start} and $pass_params->{start} ) {
	    $chain_content .= "	<nmwg:parameter name=\"startTime\">" . $pass_params->{start} . "</nmwg:parameter>\n";
	}
	if ( exists $pass_params->{end} and  $pass_params->{end} ) {
	    $chain_content .= "	<nmwg:parameter name=\"endTime\">" . $pass_params->{end} . "</nmwg:parameter>\n";
	}
	if ( exists $pass_params->{resolution} and $pass_params->{resolution} ) {
	    $chain_content .= "	<nmwg:parameter name=\"resolution\">" . $pass_params->{resolution} . "</nmwg:parameter>\n";
	}
	if ( exists $pass_params->{consolidationFunction} and $pass_params->{consolidationFunction} ) {
	    $chain_content .= "	<nmwg:parameter name=\"consolidationFunction\">" . $pass_params->{consolidationFunction} . "</nmwg:parameter>\n";
	}
	$chain_content .= "    </select:parameters>\n";
	$chain_content .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/ops/select/2.0</nmwg:eventType> \n";
	$chain_content .= "  </nmwg:metadata>\n";
    }
    return $chain_content;
}

sub _get_chain_start {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { start => 0, end => 0, resolution => 0, consolidationFunction => 0 } );
    my $chain_content = '';
    my $mdId_ch  = '';
    if (   ( exists $parameters->{"start"} and $parameters->{"start"} )
        or ( exists $parameters->{"end"}                   and $parameters->{"end"} )
        or ( exists $parameters->{"resolution"}            and $parameters->{"resolution"} )
        or ( exists $parameters->{"consolidationFunction"} and $parameters->{"consolidationFunction"} ) )
    {
        $mdId_ch    = "metadata." . genuid(); 
        $chain_content = "  <nmwg:metadata id=\"$mdId_ch.chain\" xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";   
    }
    return { id => $mdId_ch, content => $chain_content};
}

sub _add_content {
    my ($self, $content, $pass_params, $data_content, $parameterblock_content, $eventtype_content) = @_;
    my $chain_content = '';
    foreach my $subj (@{$self->getSubject}) {
	my $mdId    = "metadata." . genuid();
	my $dId     = "data." . genuid();
	my $chain_md = ($pass_params && %{$pass_params})?$self->_get_chain_start($pass_params):'';
	$content .= "  <nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"$mdId\">\n";
        $content .= $subj if $subj;
        $content .=  $eventtype_content if $eventtype_content;
	$content .= $parameterblock_content if $parameterblock_content;
	$content .= "  </nmwg:metadata>\n";
        my $data_idref = $mdId;
	if($chain_md) {
	    $chain_md->{content} .= "    <select:subject id=\"subject." . genuid() . 
	                                   "\" metadataIdRef=\"$mdId\" xmlns:select=\"http://ggf.org/ns/nmwg/ops/select/2.0/\"/> ";
	    $data_idref =  $chain_md->{id} . '.chain';
 	    $data_content .= "  <nmwg:data id=\"$dId\" metadataIdRef=\"$data_idref\"/> ";
            $chain_md->{content}  = $self->_addChainedMd($pass_params, $chain_md->{content});
	    $chain_content .= $chain_md->{content};
	} 
	else {
	    $data_content .= " <nmwg:data id=\"$dId\" metadataIdRef=\"$data_idref\"/> ";
	}
    }
    return $content . $chain_content  . $data_content;
    
}
=head2 setupDataRequest($self, { subject, eventTypes, parameters, start, end, resolution, consolidationFunction })

Perform a SetupDataRequest, the results are returned as a data/metadata pair.

=cut

sub setupDataRequest {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { parameters =>   0,
					      eventTypes =>   0 ,
					      subject =>   0 ,
					      parameterblock => 0, start => 0, end => 0,
					      resolution => 0, consolidationFunction => 0 } );
    
    {
       no strict 'refs';
       map {("perfSONAR_PS::Client::MA::set\u$_")->($self, { $_ => $parameters->{$_}}) 
           if  $parameters->{$_} }  qw/subject eventTypes parameters/;
    } 
    my $pass_params = {};
    map { $pass_params->{$_} = $parameters->{$_} if  $parameters->{$_} } qw/start end resolution consolidationFunction/;
    my $content = '';
    my $data_content = '';
    my $eventtype_content = '';
    $eventtype_content = join (' ', ( map { "<nmwg:eventType>$_</nmwg:eventType>" } @{$self->getEventTypes} ))
        if $self->getEventTypes && @{$self->getEventTypes};
    my $parameterblock_content = '';
    if ( exists $parameters->{"parameterblock"} and $parameters->{"parameterblock"} ) {
           $parameterblock_content = $parameters->{"parameterblock"}; 
    } 
    elsif ( $self->getParameters && %{$self->getParameters} ) {
        $parameterblock_content  = "    <nmwg:parameters id=\"parameters." . genuid() . "\">\n";
        foreach my $p ( keys %{ $self->getParameters } ) {
            $parameterblock_content  .= "      <nmwg:parameter name=\"" . $p . "\">" . $self->getParameters->{$p} . "</nmwg:parameter>\n";
        }
        $parameterblock_content .= "    </nmwg:parameters>\n";
    }
    my $request_content = $self->_add_content($content, $pass_params, $data_content, $parameterblock_content, $eventtype_content);
    my $msg = $self->callMA( { message => $self->createMAMessage( { type => "SetupDataRequest", content => $request_content } ) } );
    unless ( $msg ) {
        $self->{LOGGER}->error( "Message element not found in return." );
        return;
    }
    my $list   = find( $msg, "./nmwg:metadata", 0 );
    foreach my $md ( $list->get_nodelist ) {
        $md->setNamespace( "http://ggf.org/ns/nmwg/base/2.0/", "nmwg", 0 );
        $self->addMetadata($md->toString);
    }
    $list = find( $msg, "./nmwg:data", 0 );
    foreach my $d ( $list->get_nodelist ) {
        $d->setNamespace( "http://ggf.org/ns/nmwg/base/2.0/", "nmwg", 0 );
        $self->addData( $d->toString );
    }
    return {data =>  $self->{data} , metadata => $self->{metadata}};
}

=head2 createMAMessage($self, { type, metadata, ns, data })

Create a message to send to an MA instance.

=cut

sub createMAMessage {
    my ( $self, @args ) = @_;
    my $parameters = validateParams( @args, { type => 1, content => 1 } );
    my $request = q{};
    $request .= "<nmwg:message type=\"" . $parameters->{type} . "\" id=\"message." . genuid() . "\"";
    $request .= " xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\">\n";
    $request .= $parameters->{content};
    $request .= "</nmwg:message>\n";

    return $request;
}

1;

__END__

=head1 SYNOPSIS

    #!/usr/bin/perl -w

    use strict;
    use warnings;
    use perfSONAR_PS::Client::MA;

    my $metadata .= "  <nmwg:metadata xmlns:nmwg=\"http://ggf.org/ns/nmwg/base/2.0/\" id=\"m1\">\n";
    $metadata .= "    <netutil:subject xmlns:netutil=\"http://ggf.org/ns/nmwg/characteristic/utilization/2.0/\" id=\"s-in-16\">\n";
    $metadata .= "      <nmwgt:interface xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";
    $metadata .= "        <nmwgt:hostName>nms-rexp.salt.net.internet2.edu</nmwgt:hostName>\n";
    $metadata .= "        <nmwgt:ifName>eth0</nmwgt:ifName>\n";
    $metadata .= "        <nmwgt:direction>in</nmwgt:direction>\n";
    $metadata .= "      </nmwgt:interface>\n";
    $metadata .= "    </netutil:subject>\n";
    $metadata .= "    <nmwg:eventType>http://ggf.org/ns/nmwg/characteristic/utilization/2.0</nmwg:eventType>\n";
    $metadata .= "  </nmwg:metadata>\n";
    $metadata .= "  <nmwg:data id=\"d1\" metadataIdRef=\"m1\"/>\n";

    my $ma = new perfSONAR_PS::Client::MA(
      { instance => "http://packrat.internet2.edu:8082/perfSONAR_PS/services/snmpMA", timeout => 100}
    );

    my $subject = "    <netutil:subject xmlns:netutil=\"http://ggf.org/ns/nmwg/characteristic/utilization/2.0/\" id=\"s-in-16\">\n";
    $subject .= "      <nmwgt:interface xmlns:nmwgt=\"http://ggf.org/ns/nmwg/topology/2.0/\">\n";
    $subject .= "        <nmwgt:hostName>nms-rexp.salt.net.internet2.edu</nmwgt:hostName>\n";
    $subject .= "        <nmwgt:ifName>eth0</nmwgt:ifName>\n";
    $subject .= "        <nmwgt:direction>in</nmwgt:direction>\n";
    $subject .= "      </nmwgt:interface>\n";
    $subject .= "    </netutil:subject>\n";

    my @eventTypes = ("http://ggf.org/ns/nmwg/characteristic/utilization/2.0");
    my %parameters = ();
    $parameters{"supportedEventType"} = "http://ggf.org/ns/nmwg/characteristic/utilization/2.0";

    my ( $sec, $frac ) = Time::HiRes::gettimeofday;

    my $result = $ma->metadataKeyRequest( { 
      consolidationFunction => "AVERAGE",
      resolution => 30,
      start => ($sec-300), 
      end => $sec, 
      subject => $subject, 
      eventTypes => \@eventTypes, 
      parameters => \%parameters } );

    $result = $ma->setupDataRequest( { 
      consolidationFunction => "AVERAGE", 
      resolution => 30,
      start => ($sec-300), 
      end => $sec, 
      subject => $subject, 
      eventTypes => \@eventTypes, 
      parameters => \%parameters } );

=head1 SEE ALSO

L<Log::Log4perl>, L<Params::Validate>, L<English>, L<perfSONAR_PS::Common>,
L<perfSONAR_PS::Transport>, L<perfSONAR_PS::Client::Echo>,
L<perfSONAR_PS::Utils::ParameterValidation>

To join the 'perfSONAR-PS Users' mailing list, please visit:

  https://lists.internet2.edu/sympa/info/perfsonar-ps-users

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Jason Zurawski, zurawski@internet2.edu
Maxim Grigoriev, maxim_at_fnal_dot_gov

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
