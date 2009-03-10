package perfSONAR_PS::DB::MA;

use strict;
use warnings;

use XML::LibXML;
use perfSONAR_PS::Transport;
use Log::Log4perl qw(get_logger);

my $logger = get_logger("perfSONAR_PS::DB::MA");

sub new {
  my ($package, $host, $port, $endpoint ) = @_; 
  my %hash = ();
   if(defined $host and $host ne "") {
    $hash{"HOST"} = $host;
  } 
  if(defined $port and $port ne "") {
    $hash{"PORT"} = $port;
  }
  if(defined $endpoint and $endpoint ne "") {
    $hash{"ENDPOINT"} = $endpoint;
  }
  
  bless \%hash => $package;
}


sub setFile {
  my ($self, $file) = @_;  

  if(defined $file and $file ne "") {
    $self->{FILE} = $file;
  }
  else {
    $logger->error("Missing argument.");  
  }
  return;
}



sub setHost {
  my ($self, $host) = @_;  

  if(defined $host and $host ne "") {
    $self->{HOST} = $host;
  }
  else {
    $logger->error("Missing argument.");  
  }
  return;
}


sub setPort {
  my ($self, $port) = @_;  

  if(defined $port and $port ne "") {
    $self->{PORT} = $port;
  }
  else {
    $logger->error("Missing argument.");  
  }
  return;
}

sub setEndpoint {
  my ($self, $endpoint) = @_;  

  if(defined $endpoint and $endpoint ne "") {
    $self->{ENDPOINT} = $endpoint;
  }
  else {
    $logger->error("Missing argument.");  
  }
  return;
}



###
# opens a connection to the remote ma
###
sub openDB {
  my ($self) = @_;
  if(defined $self->{HOST} && defined $self->{PORT} && defined $self->{ENDPOINT}) {
  
    eval {
	    $self->{"TRANSACTION"} = new perfSONAR_PS::Transport($self->{HOST}, $self->{PORT}, $self->{ENDPOINT});
   		#$logger->debug( "SETUP: "  . $self->{"TRANSACTION"});
    };
    # mor specific error?
    if ( $@ ) {
	    $logger->error("Cannot open connection to " . $self->{HOST} . ':' . $self->{PORT} . '/' . $self->{ENDPOINT} . "." );      
    }
  }
  else {
  	$logger->error( "Connection settings missing: ". $self->{HOST} . ':' . $self->{PORT} . '/' . $self->{ENDPOINT} . "."  );
  }                  
  return;
}


sub closeDB {
  my ($self) = @_;

  if(defined $self->{TRANSACTION} and $self->{TRANSACTION} ne "") {
	# no state, so nothing to close
  }
  else {
    $logger->error("No connection to remote MA defined.");  
  }
  return;
}



sub getDOM {
  my ($self) = @_;
  my $logger = get_logger("perfSONAR_PS::DB::File");
  if(defined $self->{XML} and $self->{XML} ne "") {
    return $self->{XML};  
  }
  else {
    $logger->error("LibXML DOM structure not defined."); 
  }
  return ""; 
}


sub setDOM {
  my($self, $dom) = @_;
  if(defined $dom and $dom ne "") {    
    $self->{XML} = $dom;
  }
  else {
    $logger->error("Missing argument.");
  }   
  return;
}


sub insert
{
	my $self = shift;
	my $dom = shift;
	
	if ( defined $dom ) {
		$self->setDOM( $dom );
	}
	
	if( defined $self->{"TRANSACTION"} ) {
	if ( defined $self->{XML} ) {
		# Make a SOAP envelope, use the XML file as the body.
		#$logger->debug( "TRANSACTION: " . $self->{"TRANSACTION"} );
		my $envelope = $self->{"TRANSACTION"}->makeEnvelope($self->{XML});
		# Send/receive to the server, store the response for later processing
		my $responseContent = $self->{"TRANSACTION"}->sendReceive($envelope);
		
		# TODO: should a remote ma respond with anything? like a confirmation?
		#$logger->debug( "RESPONSE: $responseContent");
	}
	else {
		$logger->error("Could not insert blank document.")
	}

	} else {
		$logger->error("Transaction has not been setup.")
	}
	return;
}

1;

__END__
=head1 NAME

perfSONAR_PS::DB::MA - simple database accessor class for the remote storage of local dom (LibXML) 
from say MP's.  Could potentially be used as a proxy class in future to redirect storage calls.

=head1 DESCRIPTION

N/A   

=head1 SYNOPSIS

    use perfSONAR_PS::DB::MA;

    # fill in
    
=head1 DETAILS

N/A 

=head1 API

N/A 

=head2 XXX

XXX

=head1 SEE ALSO

L<XML::LibXML>, L<perfSONAR_PS::Transport>, L<Log::Log4perl>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list.  Bugs,
feature requests, and improvements can be directed here:

https://bugs.internet2.edu/jira/browse/PSPS

=head1 VERSION

$Id$

=head1 AUTHOR

Yee-Ting Li, ytl@slac.stanford.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework along 
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
