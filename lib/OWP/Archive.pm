package OWP::Archive;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

Archive.pm - utilities for archiving collected measurement data.

=head1 DESCRIPTION

Utilities that manage the archived data from perfSONAR-BUOY.  

=cut

require 5.005;
use OWP;
use OWP::Utils;
use File::Path;
use Math::Int64 qw(uint64);
use DBI;


$Archive::REVISION = '$Id$';
$Archive::VERSION  = '1.0';

sub new {
    my ( $class, @initialize ) = @_;
    my $self = {};

    bless $self, $class;

    $self->init( @initialize );

    return $self;
}

sub init {
    my ( $self, %args ) = @_;
    my ( $datadir );

    #
    # This is bogus at the moment. Need to figure out what vars
    # the arch stuff is going to need.
    #
ARG:
    foreach ( keys %args ) {
        my $name = $_;
        $name =~ tr/a-z/A-Z/;
        if ( $name ne $_ ) {
            $args{$name} = $args{$_};
            delete $args{$_};
        }

        # Add each "init" var here
        /^datadir$/oi and $self->{$name} = $args{$name}, next ARG;
        /^archdir$/oi and $self->{$name} = $args{$name}, next ARG;
        /^suffix$/oi  and $self->{$name} = $args{$name}, next ARG;
    }

    die "DATADIR undefined" if ( !defined $self->{'DATADIR'} );
    die "ARCHDIR undefined" if ( !defined $self->{'ARCHDIR'} );

    return;
}

# basically, this function should add a link to the
# datafile in an archive staging area.
#	my $newfile = "$self->{'ARCHDIR'}/$args{'MESH'}/$args{'RECV'}/$args{'SEND'}/$args{'START'}_$args{'END'}$self->{'SUFFIX'}";

sub add {
    my ( $self, %args ) = @_;
    my ( @argnames ) = qw(DBH DATAFILE TESTID MESH RECV SEND START END);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || return 0;

    my ( $start, $end );
    $start = uint64($args{'START'});
    $end   = uint64($args{'END'});

    my $newfile = "$self->{'ARCHDIR'}/" . owptstampdnum( $start ) . "/$args{'MESH'}_$args{'RECV'}_$args{'SEND'}";

    eval { mkpath( [$newfile], 0, 0775 ) };
    if ( $@ ) {
        warn "Couldn't create dir $newfile:$@:$?";
        return 0;
    }
    $newfile .= "/$args{'START'}_$args{'END'}$self->{'SUFFIX'}";

    my $sql = "
		INSERT INTO pending_files
		VALUES(?,?,?,?)";
    my $sth = $args{'DBH'}->prepare( $sql ) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi( $start ), owptstampi( $end ), $newfile )
        || return 0;

    link $args{'DATAFILE'}, $newfile
        || return 0;

    return 1;
}

sub rm {
    my ( $self, %args ) = @_;
    my ( @argnames ) = qw(DBH DATAFILE TESTID MESH RECV SEND START END);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    %args || return 0;
    my ( $start, $end );
    $start = uint64($args{'START'});
    $end   = uint64($args{'END'});

    my $sql = "
		SELECT filename FROM pending_files
		WHERE
			test_id = ? AND
			si = ? AND
			ei = ?";
    my $sth = $args{'DBH'}->prepare( $sql ) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi( $start ), owptstampi( $end ) )
        || return 0;
    my ( @row, @files );
    while ( @row = $sth->fetchrow_array ) {
        push @files, @row;
    }
    if ( @files != 1 ) {
        warn "OWP::Archive::rm called on non-existant session";
        return 0;
    }

    $sql = "
		DELETE pending_files
		WHERE
			test_id=? AND
			si=? AND
			ei=?";
    $sth = $args{'DBH'}->prepare( $sql ) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi( $start ), owptstampi( $end ) )
        || return 0;

    unlink @files || return 0;

    return 1;
}

sub delete_range {
    my ( $self, %args ) = @_;
    my ( @argnames ) = qw(DBH TESTID FROM TO);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || return 0;

    my $from = uint64($args{'FROM'});
    my $to   = uint64($args{'TO'});
    my $sql  = "
		SELECT filename FROM pending_files
		WHERE
			test_id = ? AND
			si>? AND ei<?";
    my $sth = $args{'DBH'}->prepare( $sql ) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi( $from ), owptstampi( $to ) )
        || return 0;
    my ( @row, @files );
    while ( @row = $sth->fetchrow_array ) {
        push @files, @row;
    }

    if ( @files ) {
        $sql = "
			DELETE FROM pending_files
			WHERE
				test_id = ? AND
				si>? AND ei<?";
        $sth = $args{'DBH'}->prepare( $sql ) || return 0;
        $sth->execute( $args{'TESTID'}, owptstampi( $from ), owptstampi( $to ) )
            || return 0;

        unlink @files || return 0;
    }

    return 1;
}

sub validate {
    my ( $self, %args ) = @_;
    my ( @argnames ) = qw(DBH TESTID TO);
    %args = owpverify_args( \@argnames, \@argnames, %args );
    scalar %args || return 0;

    my $to = uint64($args{'TO'});

    my $sql = "
		DELETE FROM pending_files
		WHERE
			test_id = ? AND
			ei<?";
    my $sth = $args{'DBH'}->prepare( $sql ) || return 0;
    $sth->execute( $args{'TESTID'}, owptstampi( $to ) ) || return 0;

    return 1;
}

__END__

=head1 SEE ALSO

L<OWP>, L<OWP::Utils>, L<File::Path>, L<DBI>

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

Jeff Boote, boote@internet2.edu

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

Copyright (c) 2007-2010, Internet2

All rights reserved.

=cut
