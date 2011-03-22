package perfSONAR_PS::Services::MP::Agent::CommandLine;

use strict;
use warnings;

use version;
our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::Services::MP::Agent::CommandLine 

=head1 DESCRIPTION

A module that will run a command and return it's output.  Inherited
perfSONAR_PS::MP::Agent::Base class that allows a command to be executed.
Specific tools should inherit from this class and override parse() in order to
be able to format the command line output in a well understood data structure.

=cut


# derive from teh base agent class
use perfSONAR_PS::Services::MP::Agent::Base;
use base qw(perfSONAR_PS::Services::MP::Agent::Base);

use Log::Log4perl qw(get_logger);
our $logger = Log::Log4perl::get_logger( 'perfSONAR_PS::Services::MP::Agent::CommandLine' );

=head2 new( $command, $options, $namespace)

Creates a new agent class

  $command = complete path to command line tool to run, eg /bin/ping
  $options = special parsed string of arguments for the tool; this string will have variables replaced at run time
  $namespace = perfSONAR_PS::XML::Namespace object

=cut

sub new {
    my ( $package, $command, $options ) = @_;
    my %hash = ();
    if ( defined $command and $command ne "" ) {
        $hash{"CMD"} = $command;
    }
    if ( defined $options and $options ne "" ) {
        $hash{"OPTIONS"} = $options;
    }
    %{ $hash{"RESULTS"} } = ();

    bless \%hash => $package;
}

=head2 command( $string )

accessor/mutator function for the generic command to run (normally set in the
constructor). This command should have variable fields marked up between '%'s.
For example for a ping we would have something like:

  '/bin/ping -c %count% %destination%';
  
This would then have the values to these variables substituted in at runtime.

=cut

sub command {
    my $self = shift;
    if ( @_ ) {
        $self->{"CMD"} = shift;
    }
    return $self->{"CMD"};
}

=head2 commandString( $string )

accessor/mutator function for the actual command line to run; this would be 
the run time command after $self->command() has had the relevant variables 
substituted.

=cut

sub commandString {
    my $self = shift;
    if ( @_ ) {
        $self->{"CMD2RUN"} = shift;
    }
    return $self->{"CMD2RUN"};
}

=head2 options( \%hash )

accessor/mutator function for the variable=value set to substitute the 
$self->command() line with. ie for the ping example with command(), we would have:

  $self->command( '/bin/ping -c %count% %destination%' );
  $self->options( {
      'count' => 10,
      'destination' => 'localhost',
  	};

which would result in
  /bin/ping -c 10 localhost
  
=cut

sub options {
    my $self = shift;
    if ( @_ ) {
        $self->{"OPTIONS"} = shift;
    }
    return $self->{"OPTIONS"};
}

=head2 init( )

does anything necessary before running the collect() such as modifying the 
options etc.
Check to see that the command exists

=cut

sub init {
    my $self = shift;
   
    return 0;
}

=head2 collectMeasurements( )

Runs the command with the options specified in constructor. 
The return of this method should be

 -1 = something failed
  0 = command ran okay

on success, this method should call the parse() method to determine 
the relevant performance output from the tool.

=cut

sub collectMeasurements {
    my ( $self ) = @_;

    # parse the options into a command line
    my $cmd = $self->command();
    while ( my ( $k, $v ) = each %{ $self->options() } ) {
        $cmd =~ s/\%$k\%/$v/g;
    }

    $self->commandString( $cmd );

    $logger->debug( "Reformatted command line '" . $self->command() . "' to '" . $self->commandString() . "'" );

    if ( defined $self->commandString() ) {

        # clear the results
        $self->{RESULTS} = {};

        # get the time of test
        my ( $sec, $frac ) = Time::HiRes::gettimeofday;
        my $time = eval( $sec . "." . $frac );

        #$logger->fatal( "TIMEOUT: " . $self->timeout() );

        # run the command, piping into @results
        # setup timeouts
        my @results = ();
	my $CMD;
        eval {
            local $SIG{ALRM} = sub { die "timeout" };

            alarm( $self->timeout() );

            # setup pipe
            my $err = undef;
            open( $CMD, $self->commandString() . " 2>&1 |" )
                or $err = "Cannot open '" . $self->commandString() . "'";

            # failed!
            if ( $err ) {
                $logger->error( $self->error( $err ) );
                return -1;
            }

            $logger->debug( "Running '" . $self->commandString() . "'... " );
            @results = <$CMD>;
            $logger->debug( "Got result from '" . $self->commandString() . "'" );
            close( $CMD );
            $logger->debug( "Closed CMD for '" . $self->commandString() . "'" );
            alarm( 0 );
            $logger->debug( "Unset alarm for '" . $self->commandString() . "'" );
        };
        if ( $@ =~ /timeout/ ) {
	    close($CMD) if $CMD;
            $self->error( "Agent timed out (" . $self->timeout() . " seconds) running '" . $self->commandString() . "'" );
            $logger->fatal( $self->error );
            return -1;
        }

        ( $sec, $frac ) = Time::HiRes::gettimeofday;
        my $endtime = eval( $sec . "." . $frac );

        # parse through the data; this method should be adapted for parsing of each tool
        # do i really want to do this here?
        return $self->parse( \@results, $time, $endtime, $self->commandString() );

    }
    else {
        my $err = "Missing command string.";
        $logger->error( $self->error( $err ) );
        return -1;
    }
    return 0;
}

=head2 parse( )

Given the output of the command as a ref to an array of strings (\@array), 
and the original command line that generated those strings ($commandLine) 
at time $time (epoch secs),

do something with that output and store in into $self->{RESULTS}.

Return:

  -1 = could not parse output
   0 = everything parsed okay
   
The data structure is completely arbitary, but should be understood by the 
inherited class.

=cut

sub parse {
    my $self        = shift;
    my $array       = shift;
    my $time        = shift;
    my $endtime     = shift;
    my $commandLine = shift;

    # don't do anything too intelligent, just concat the string
    $self->{'RESULTS'} = "At '$time', command '$commandLine' resulted in ouput (ended at '$endtime'):\n @$array";
    return 0;
}

1;

__END__

=head1 SYNOPSIS

  # command line to run, variables are indicated with the '%...%' notation
  my $command = '/bin/ping -c %count% %destination%';
  
  # options to use, the above keys defined in $command will be 
  # substituted with the following values
  my %options = (
       'count' => 10,
      'destination' => 'localhost',
  );
  
  # create and setup a new Agent  
  my $agent = perfSONAR_PS::Services::MP::Agent::CommandLine( $command, $options );
  $agent->init();
  
  # collect the results (i.e. run the command)
  if( $mp->collectMeasurements() == 0 )
  {
  	
  	# get the raw datastructure for the measurement
  	print "Results:\n" . $self->results() . "\n";

  }
  # opps! something went wrong! :(
  else {
    
    print STDERR "Command: '" . $self->commandString() . "' failed with result '" . $self->results() . "': " . $agent->error() . "\n"; 
    
  }

=head1 SEE ALSO

L<Net::Domain>, L<Socket>, L<IO::Socket>, L<IO::Interface>,
L<perfSONAR_PS::Services::MP::Agent::Base>, L<Log::Log4perl>

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

Yee-Ting Li <ytl@slac.stanford.edu>
Maxim Grigoriev maxim_fnal_gov - redone the whole ip addresses identification

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>



=head1 COPYRIGHT

Copyright (c) 2007-2009, Internet2 and SLAC National Accelerator Laboratory

All rights reserved.

=cut
