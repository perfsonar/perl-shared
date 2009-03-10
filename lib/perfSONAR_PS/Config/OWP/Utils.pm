#
#      $Id$
#
#########################################################################
#									#
#			   Copyright (C)  2002				#
#	     			Internet2				#
#			   All Rights Reserved				#
#									#
#########################################################################
#
#	File:		perfSONAR_PS::Config::OWP::Utils.pm
#
#	Author:		Anatoly Karp
#			Jeff Boote
#			Internet2
#
#	Date:		Wed Oct 2 10:40:10  2002
#
#	Description: Auxiliary subs for large time conversions.
package perfSONAR_PS::Config::OWP::Utils;
require 5.005;
require Exporter;
use strict;
use vars qw(@ISA @EXPORT $VERSION);
use Math::BigInt;
use Math::BigFloat;
use POSIX;

@ISA = qw(Exporter);
@EXPORT = qw(time2owptime owptimeadd owpgmtime owptimegm owpgmstring owplocaltime owplocalstring owptrange owptime2time owptstampi owpi2owp owptstampdnum pldatetime owptstamppldatetime owptime2exacttime owpexactgmstring);

$perfSONAR_PS::Config::OWP::Utils::REVISION = '$Id$';
$VERSION = $perfSONAR_PS::Config::OWP::Utils::VERSION='1.0';

use constant JAN_1970 => 0x83aa7e80; # offset in seconds
my $scale = new Math::BigInt 2**32;

# Convert value return by time() into owamp-style (ASCII form
# of the unsigned 64-bit integer [32.32]
sub time2owptime {
    my $bigtime = new Math::BigInt $_[0];
    $bigtime = ($bigtime + JAN_1970) * $scale;
    $bigtime =~ s/^\+//;
    return $bigtime;
}

sub owptime2time{
	my $bigtime = new Math::BigInt $_[0];
	$bigtime /= $scale;
	return $bigtime - JAN_1970;
}

#
# Add a number of seconds to an owamp-style number.
#
sub owptimeadd{
	my $bigtime = new Math::BigInt shift;

	while($_ = shift){
		my $add = new Math::BigInt $_;
		$bigtime += ($add * $scale);
	}

	$bigtime =~ s/^\+//;
	return $bigtime;
}

sub owptstampi{
	my $bigtime = new Math::BigInt shift;
	return $bigtime>>32;
}

sub owpi2owp{
	my $bigtime = new Math::BigInt shift;

	return $bigtime<<32;
}

sub owpgmtime{
	my $bigtime = new Math::BigInt shift;

	my $unixsecs = ($bigtime/$scale) - JAN_1970;

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
	my($tstamp) = new Math::BigInt shift;
	my($frac) = new Math::BigFloat($tstamp);
	# move fractional part to the right of the radix point.
	$frac /= $scale;
	# Now subtract away the integer portion
	$frac -= ($tstamp/$scale);
	return pldatetime((perfSONAR_PS::Config::OWP::Utils::owpgmtime($tstamp))[0..7],$frac);
}



sub owptstampdnum{
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
		perfSONAR_PS::Config::OWP::Utils::owpgmtime(shift);
	return sprintf "%04d%02d%02d",$year+1900,$mon+1,$mday;
}

my @dnames = qw(Sun Mon Tue Wed Thu Fri Sat);
my @mnames = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);


sub owpgmstring{
	my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
		perfSONAR_PS::Config::OWP::Utils::owpgmtime(shift);
	$year += 1900;
	return sprintf "$dnames[$wday] $mnames[$mon] $mday %02d:%02d:%02d UTC $year", $hour,$min,$sec;
}

sub owplocalstring{
	my $bigtime = new Math::BigInt shift;

	my $unixsecs = ($bigtime/$scale) - JAN_1970;

        return strftime "%a %b %e %H:%M:%S %Z", localtime;
}

sub owplocaltime{
	my $bigtime = new Math::BigInt shift;

	my $unixsecs = ($bigtime/$scale) - JAN_1970;

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
			$first = new Math::BigInt $first;
			$last = new Math::BigInt $last;
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
			$$lref = new Math::BigInt $$tstamp;
		}
	}


	if(!$$tstamp){
		$$lref = new Math::BigInt time2owptime(time());
		$$tstamp='now';
	}

	if(!$$fref){
		$$fref = new Math::BigInt owptimeadd($$lref,-$dur);
	}

	return 1;
}

sub owptime2exacttime{
  my $bigtime = new Math::BigInt $_[0];
  my $mantissa = $bigtime % $scale;
  my $significand = ($bigtime / $scale) - JAN_1970;
  return ( $significand . "." . $mantissa );
}
 

sub owpexactgmstring{
  my $time = perfSONAR_PS::Config::OWP::Utils::owptime2exacttime(shift);
  my @parts = split(/\./mx,$time);
  my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) = gmtime($time);
  $year += 1900;
  return sprintf "$dnames[$wday] $mnames[$mon] $mday %02d:%02d:%02d.%u UTC $year", $hour,$min,$sec, $parts[1];
}

1;
