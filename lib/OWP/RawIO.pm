package OWP::RawIO;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

RawIO.pm - Library to handle IO operations on measurement data.

=head1 DESCRIPTION

Library to handle IO operations on measurement data.

=cut

require 5.005;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
use POSIX;
use FindBin;

#use Errno qw(EINTR EIO :POSIX);

@ISA    = qw(Exporter);
@EXPORT = qw(sys_readline sys_writeline);

$RawIO::REVISION = '$Id$';
$VERSION = $RawIO::VERSION = '1.0';

sub sys_readline {
    my ( %args ) = @_;
    my ( $fh, $tmout ) = ( \*STDIN, 0 );
    my ( $cb ) = sub { return undef };
    my $char;
    my $read;
    my $line = "";
    $tmout = $args{'TIMEOUT'}    if ( defined $args{'TIMEOUT'} );
    $fh    = $args{'FILEHANDLE'} if ( defined $args{'FILEHANDLE'} );
    $cb    = $args{'CALLBACK'}   if ( defined $args{'CALLBACK'} );

    while ( 1 ) {
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            local $SIG{PIPE} = sub { die "pipe\n" };
            alarm $tmout;
            $read = sysread( $fh, $char, 1 );
            alarm 0;
        };
        if ( !defined( $read ) ) {
            if ( ( $! == EINTR ) && ( $@ ne "alarm\n" ) && ( $@ ne "pipe\n" ) ) {
                next;
            }
            return &$cb( undef, $@ );
        }
        if ( $read < 1 ) {
            return &$cb( $read, undef );
        }
        if ( $char eq "\n" ) {

            #warn "RECV: $line\n";
            return $line;
        }
        $line .= $char;
    }
}

sub sys_writeline {
    my ( %args ) = @_;
    my ( $fh, $line, $md5, $tmout ) = ( \*STDOUT, '', undef, 0 );
    my ( $cb ) = sub { return undef };
    $line  = $args{'LINE'}       if ( defined $args{'LINE'} );
    $tmout = $args{'TIMEOUT'}    if ( defined $args{'TIMEOUT'} );
    $fh    = $args{'FILEHANDLE'} if ( defined $args{'FILEHANDLE'} );
    $cb    = $args{'CALLBACK'}   if ( defined $args{'CALLBACK'} );
    $md5   = $args{'MD5'}        if ( defined $args{'MD5'} );

    $md5->add( $line ) if ( ( defined $md5 ) && !( $line =~ /^$/ ) );

    $line .= "\n";
    my $len    = length( $line );
    my $offset = 0;

    while ( $len ) {
        my $written;
        eval {
            local $SIG{ALRM} = sub { die "alarm\n" };
            local $SIG{PIPE} = sub { die "pipe\n" };
            alarm $tmout;
            $written = syswrite $fh, $line, $len, $offset;
            alarm 0;
        };
        if ( !defined( $written ) ) {
            if ( ( $! == EINTR ) && ( $@ ne "alarm\n" ) && ( $@ ne "pipe\n" ) ) {
                next;
            }
            return &$cb( undef, $@ );
        }
        $len -= $written;
        $offset += $written;
    }

    #warn "TXMT: $line";
    return 1;
}

1;

__END__

=head1 SEE ALSO

L<Exporter>, L<POSIX>, L<FindBin>, L<Errno>

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
