package perfSONAR_PS::Error;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

perfSONAR_PS::Error

=head1 DESCRIPTION

A module that provides the exceptions framework for perfSONAR PS.  This module
provides the base object for all exception types that will be presented.

=cut

use base "Error";

use Error::Simple;

sub new {
    my $self = shift;
    my $text = "" . shift;
    my @args = ();

    local $Error::Depth = $Error::Depth + 1;
    local $Error::Debug = 1;

    $self->SUPER::new( -text => $text, @args );
    return;
}

=head2 toEventType

returns the perfsonar event type for this exception as a string, ensure that you
throw the appropriate inheritied exception object for automatic eventType
creation.

=cut

sub eventType {
    my $self = shift;
    my $ex   = ref $self;

    # form the '.' notation for the exceptions

    # ensure that camel cased words are separated
    my $s = undef;
    ( $s = ref $self ) =~ s/([a-z])([A-Z])/$1_$2/g;

    # remove perfSONAR_PS
    my @str = split /\:\:/, lc $s;
    shift @str;

    return join '.', @str;
}

=head2 errorMessage

returns the error message itself (also the same as casting the object as a
string)

=cut

sub errorMessage {
    my $self = shift;
    return $self->text();
}

1;

__END__

=head1 SYNOPSIS

  # first define the errors somewhere
  package Some::Error;
  use base "Error::Simple";
  1;
  
  use Some::Error;

  # you MUST import this, otherwise the try/catch blocks will fail
  use Error qw(:try);  

  # if an error occurs, perfSONAR_PS objects should throw an error eg
  sub openDB {
    my $handle = undef;
    $handle = DBI->connect( ... )
  	  or throw Some::Error( "Could not connect to database: " . $DBI::errstr . "\n" );
  	return $handle;
  }


  ### script.pl ###
  
  # in the calling code
  my $dbh = undef;
  try {
  
    $dbh = &openDB();
  
  }
  catch Some::Error with {
  
    # print the contents of the error object (the string)
    print "An error occurred $@\n";
  
  }
  otherwise {
  
    # some other error occured!
    print "Some unknown error occurred! $@\n";
  
  }
  finally {
  
    print "Done!\n"'
  
  }; 
  
  # don't forget the trailing ';'
  
=head1 SEE ALSO

L<Exporter>, L<Error::Simple>

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

Yee-Ting Li, ytl@slac.stanford.edu
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
 
