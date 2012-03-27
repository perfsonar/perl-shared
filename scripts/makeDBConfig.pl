#!/usr/bin/perl -w

use strict;
use warnings;

our $VERSION = 3.2;

=head1 NAME

makeDBConfig.pl

=head1 DESCRIPTION

The DB_CONFIG file is used by the XMLDB to control environmental
items like number of locks and the size of the cache.  This file is
very valuable to dynamic services such as the LS.

=head1 SYNOPSIS

./makeDBConfig.pl

=cut

use File::Temp qw(tempfile);

my ( $fileHandle, $fileName ) = tempfile();

print $fileHandle "set_lock_timeout 5000\n";
print $fileHandle "set_txn_timeout 5000\n";
print $fileHandle "set_lk_max_lockers 500000\n";
print $fileHandle "set_lk_max_locks 500000\n";
print $fileHandle "set_lk_max_objects 500000\n";
print $fileHandle "set_lk_detect DB_LOCK_MINLOCKS\n";
print $fileHandle "set_cachesize 0 33554432 0\n";
print $fileHandle "set_flags DB_LOG_AUTOREMOVE\n";
print $fileHandle "set_lg_regionmax 2097152\n";

close( $fileHandle );

print $fileName;

__END__

=head1 SEE ALSO

L<File::Temp>

To join the 'perfSONAR Users' mailing list, please visit:

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

Copyright (c) 2004-2010, Internet2

All rights reserved.

=cut
