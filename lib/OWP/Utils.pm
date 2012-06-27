package OWP::Utils;

use strict;
use warnings;

our $VERSION = 3.2;

=head1 NAME

Utils.pm - Auxiliary subs for large time conversions.

=head1 DESCRIPTION

Auxiliary subs for large time conversions.

=cut

require 5.005;
require Exporter;
use vars qw(@ISA @EXPORT $VERSION);
use Math::BigFloat;
use Math::Int64 qw(uint64 uint64_to_number);
use POSIX;

@ISA    = qw(Exporter);
@EXPORT = qw(time2owptime owptimeadd owpgmtime owptimegm owpgmstring owplocaltime owplocalstring owptrange owptime2time owptstampi owpi2owp owptstampdnum pldatetime owptstamppldatetime owptime2exacttime owpexactgmstring);

$Utils::REVISION = '$Id$';
$VERSION = $Utils::VERSION = '1.0';

use constant JAN_1970 => 0x83aa7e80;    # offset in seconds
my $scale = uint64(2)**32;

# Convert value return by time() into owamp-style (ASCII form
# of the unsigned 64-bit integer [32.32]
sub time2owptime {
    my $bigtime = uint64($_[0]);
    $bigtime = ($bigtime + JAN_1970) * $scale;
    $bigtime =~ s/^\+//;
    return $bigtime;
}

sub owptime2time{
	my $bigtime =uint64($_[0]);
	$bigtime /= $scale;
	return uint64_to_number($bigtime - JAN_1970);
}

#
# Add a number of seconds to an owamp-style number.
#
sub owptimeadd{
	my $bigtime = uint64(shift);

	while($_ = shift){
		my $add = uint64($_);
		$bigtime += ($add * $scale);
	}

	$bigtime =~ s/^\+//;
	return $bigtime;
}

sub owptstampi{
	my $bigtime = uint64( shift );
	return uint64_to_number($bigtime>>32);
}

sub owpi2owp{
	my $bigtime = uint64( shift );

	return $bigtime<<32;
}

sub owpgmtime{
	my $bigtime = uint64 shift;

	my $unixsecs = uint64_to_number(($bigtime/$scale) - JAN_1970);

	return gmtime($unixsecs);
}

sub owptimegm{
	$ENV{'TZ'} = 'UTC 0';
	POSIX::tzset();
	my $unixstamp = POSIX::mktime(@_) || return undef;

	return time2owptime($unixstamp);
}

sub pldatetime{
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$frac) = @_;

	$frac = 0 if(!defined($frac));

	return sprintf "%04d-%02d-%02d.%02d:%02d:%06.3f",
			$year+1900,$mon+1,$mday,$hour,$min,$sec+$frac;
}

sub owptstamppldatetime{
	my($tstamp) = uint64( shift );
	my($frac) = new Math::BigFloat($tstamp);
	# move fractional part to the right of the radix point.
	$frac /= $scale;
	# Now subtract away the integer portion
	$frac -= uint64_to_number($tstamp/$scale);
	return pldatetime((owpgmtime($tstamp))[0..7],$frac);
}



sub owptstampdnum{
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
		owpgmtime(shift);
	return sprintf "%04d%02d%02d",$year+1900,$mon+1,$mday;
}

my @dnames = qw(Sun Mon Tue Wed Thu Fri Sat);
my @mnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);


sub owpgmstring{
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
		owpgmtime(shift);
	$year += 1900;
	return sprintf "$dnames[$wday] $mnames[$mon] $mday %02d:%02d:%02d UTC $year", $hour,$min,$sec;
}

sub owplocalstring{
    return strftime "%a %b %e %H:%M:%S %Z", owplocaltime(shift);
}

sub owplocaltime{
	my $bigtime = uint64(shift);

	my $unixsecs = uint64_to_number(($bigtime/$scale) - JAN_1970);

	return localtime($unixsecs);
}


sub owptrange{
	my ($tstamp,$fref,$lref,$dur) = @_;

	my ($first, $last);

	$dur = 900 if(!defined($dur));

	undef $$fref;
	undef $$lref;

	if($$tstamp){
		if($$tstamp =~ /^now$/oi){
			undef $$tstamp;
		}
		elsif(($first,$last) = ($$tstamp =~ m#^(\d*?)_(\d*)#o)){
			$first = uint64($first);
			$last = uint64($last);
			if($first>$last){
				$$fref = $last + 0;
				$$lref = $first + 0;
			}
			else{
				$$fref = $first + 0;
				$$lref = $last + 0;
			}
		}
		else{
			$$lref = uint64($$tstamp);
		}
	}


	if(!$$tstamp){
		$$lref = uint64(time2owptime(time()));
		$$tstamp='now';
	}

	if(!$$fref){
		$$fref = uint64(owptimeadd($$lref,-$dur));
	}

	return 1;
}

sub owptime2exacttime{
  my $bigtime = uint64($_[0]);
  my $mantissa = $bigtime % $scale;
  my $significand = ($bigtime / $scale);
  $significand -= JAN_1970;  
  #calculate decimal value where highest bit is 1/2, next is 1/4, then 1/8, etc
  my $fraction = 0;
  foreach my $bit(1..32){
    $fraction += 1.0/(2**$bit) if(($mantissa & (2**(32-$bit))) > 0 );
  }
  $fraction = sprintf("%.9f", $fraction);
  $fraction =~ s/\d*\.//g;
  
  return ( $significand . "." . $fraction );
}

sub owpexactgmstring{
  my $time = owptime2exacttime(shift);
  my @parts = split(/\./mx,$time);
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($time);
  $year += 1900;
  return sprintf "$dnames[$wday] $mnames[$mon] $mday %02d:%02d:%02d.%u UTC $year", $hour,$min,$sec, $parts[1];
}

1;

__END__

=head1 SEE ALSO

L<Exporter>, L<Math::Int64>, L<Math::BigFloat>, L<POSIX>

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

Jeff Boote, boote@internet2.edu
Anatoly Karp

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
