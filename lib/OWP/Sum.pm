package OWP::Sum;

use strict;
use warnings;

our $VERSION = 3.3;

=head1 NAME

Sum.pm - Module to read summarized data.

=head1 DESCRIPTION

Module to read summarized data.

=cut

require 5.005;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);

@ISA    = qw(Exporter);
@EXPORT = qw(parsesum);

$Sum::REVISION = '$Id$';
$VERSION = $Sum::VERSION = '1.0';

sub parsesum {
    my ( $sfref, $rref ) = @_;

    while ( <$sfref> ) {
        my ( $key, $val );
        next if ( /^\s*#/ );    # comments
        next if ( /^\s*$/ );    # blank lines

        if ( ( ( $key, $val ) = /^(\w+)\s+(.*?)\s*$/o ) ) {
            $key =~ tr/a-z/A-Z/;
            $$rref{$key} = $val;
            next;
        }

        if ( /^<BUCKETS>\s*/ ) {
            my @buckets;
            my ( $bi, $bn );
        BUCKETS:
            while ( <$sfref> ) {
                last BUCKETS if ( /^<\/BUCKETS>\s*/ );
                if ( ( ( $bi, $bn ) = /^\s*(-{0,1}\d+)\s+(\d+)\s*$/o ) ) {
                    push @buckets, $bi, $bn;
                }
                else {
                    warn "SUM Syntax Error[line:$.]: $_";
                    return undef;
                }
            }
            if ( @buckets > 0 ) {
                $$rref{'BUCKETS'} = join '_', @buckets;
            }
            next;
        }

        if ( /^<TTLBUCKETS>\s*/ ) {
            my @buckets;
            my ( $bi, $bn );
        TTLBUCKETS:
            while ( <$sfref> ) {
                last TTLBUCKETS if ( /^<\/TTLBUCKETS>\s*/ );
                if ( ( ( $bi, $bn ) = /^\s*(-{0,1}\d+)\s+(\d+)\s*$/o ) ) {
                    push @buckets, $bi, $bn;
                }
                else {
                    warn "SUM Syntax Error[line:$.]: $_";
                    return undef;
                }
            }
            if ( @buckets > 0 ) {
                $$rref{'TTLBUCKETS'} = join '_', @buckets;
            }
            next;
        }

        if ( /^MINTTL\s*/ or /^MAXTTL\s*/ ) {

            # do nothing for now
        }

        if ( /^<NREORDERING>\s*/ ) {

            # do nothing for now

        NREORDERING:
            while ( <$sfref> ) {
                last NREORDERING if ( /^<\/NREORDERING>\s*/ );
            }
            next;
        }

        warn "SUM Syntax Error[line:$.]: $_";
        return undef;
    }

    if ( !defined( $$rref{'SUMMARY'} ) ) {
        warn "OWP::Sum::parsesum(): Invalid Summary";
        return undef;
    }

    return 1;
}

1;

__END__

=head1 SEE ALSO

L<Exporter>

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
