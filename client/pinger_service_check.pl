#!/bin/env perl

use strict;
use warnings;

our $VERSION = 3.1.1;

use FindBin qw($Bin);
use lib "$Bin/../lib";
use perfSONAR_PS::Client::PingER;
use Data::Dumper;
use Getopt::Long;
use English '-no_match_vars';
use POSIX qw(strftime);
use JSON::XS;
use Mail::Sender;
use Sys::Hostname;
use Pod::Usage;
use Sys::Syslog qw(:DEFAULT);



=head1 NAME

pinger_service_check.pl -  PingER MA service checker

=head1 DESCRIPTION

Connects to the PingER MA and check healths and either returns JSON encoded string with status or send email with notification if configured.
Also, it logs any message into the syslog facility.

=head1 SYNOPSIS

  #   check health of the PingER service at xenmon.fnal.gov:8075 and send notification to maxim@fnal.gov over smtp.fnal.gov if check failed
  #
 ./pinger_service_check.pl --url='http://xenmon.fnal.gov:8075/perfSONAR_PS/services/pinger/ma'--mail='maxim@fnal.gov' --smtp='smtp.fnal.gov'
  
  #
  #    check health of the PingER service at xenmon.fnal.gov:8075 and print/return JSON encoded string
  #
  ./pinger_service_check.pl --url='http://xenmon.fnal.gov:8075/perfSONAR_PS/services/pinger/ma'
 
=head1 OPTIONS

=head2 C<--help|-h>  Usage Info

=head2 C<--url|-u>  URL

URL of the PIngER MA to test, defaults to B<http://localhost:8075/perfSONAR_PS/services/pinger/ma>

=head2 C<--mail|-m> EMAIL address

EMAIL address to send notification to, defaults to B<undef>

=head2 C<--smtp|-s> SMTP server address

SMTP address of the server to relay email via, defaults to default value on the host
This option B<ONLY> processed when I<--mail|-m> is set.

=head2 C<--log|l> LOG file full filename

specify full filename for the pinger log file to send with email 

=cut

my $url = 'http://localhost:8075/perfSONAR_PS/services/pinger/ma';
our ($MAIL, $email, $help, $smtp, $logfile);
my $ok = GetOptions (
                'url|u=s'  => \$url,
		'mail|m=s' => \$email,
		'smtp|s=s' =>  \$smtp,
		'log|l=s'  => \$logfile,
                'help|?|h' => \$help
        ) or pod2usage(-verbose => 1);
if($help || ($logfile && !(-e $logfile)) || ($email  && $email !~ /^[\w\.]+\@[\w\-\.]+$/)) {
    pod2usage(-verbose => 2);
}
if($email) {
   
    $smtp ||= 'localhost';
    $MAIL = Mail::Sender->new({smtp => $smtp, 
                               from => 'pinger_ma@' . hostname()
	  		     });
    die $Mail::Sender::Error unless ref $MAIL;
    $logfile ||= '/var/log/perfsonar/pinger.log';
}

my ($result, $metaids);
my $ma = new perfSONAR_PS::Client::PingER( { instance => $url } );
eval {
    $result = $ma->metadataKeyRequest();
};
if($EVAL_ERROR) {
    health_failed({MDKrequest => $EVAL_ERROR});
} 
unless($result) {
    health_failed({MDKrequest => 'No response from the service, its not running ?'});
}
eval {
    $metaids = $ma->getMetaData($result);
};
if($EVAL_ERROR ) {
    health_failed({metadata => $EVAL_ERROR});
}
my @metaids_arr = keys %$metaids;
unless(@metaids_arr) {
    health_failed({metadata =>  'No METADATA, check if landmarks file is empty'});
}
my $time_start =  time() -  1800;
my $time_end   =  time();
my $ptime = sub {strftime " %Y-%m-%d %H:%M", localtime(shift)};
my %keys =();

foreach  my $meta  (@metaids_arr) {
    map {$keys{$_}++} @{$metaids->{$meta}{keys}};
}
unless(%keys) {
    health_failed({metadata =>  'No METADATA, check if landmarks file is empty'});
}

$ma = new perfSONAR_PS::Client::PingER( { instance => $url } );
my ($dresult, $data_md);
eval {
    $dresult= $ma->setupDataRequest( { 
    	 start => $time_start, 
    	 end =>   $time_end,  
    	 keys =>  [keys %keys],
    	 cf => 'AVERAGE',
    	 resolution => 5,
    }); 
};
if($EVAL_ERROR) {
    health_failed({SDrequest => $EVAL_ERROR});
}
eval {
    $data_md = $ma->getData($dresult);
};
if($EVAL_ERROR) {
    health_failed({data => $EVAL_ERROR});
}
my @data_arr = keys %{$data_md};
unless( @data_arr ) {
    health_failed({data => 'No data in the past 30 minutes, check if MP is running'});
}
unless(@data_arr == @metaids_arr) {
    foreach my $meta (@data_arr) {
      delete $metaids->{$meta};
    }
    health_failed({data => 'data incomplete, these E2E pairs recorded as metadata but are not returning any data:' . join(', ', keys %$metaids)});
}
syslog('info', "PingER MA is OK !") unless $MAIL;
exit 0;

sub health_failed {
    my $health = shift;
    $health->{service} = 'NOT OK';
    $Data::Dumper::Terse = 1;
    if($MAIL && ref $MAIL eq 'Mail::Sender') {  
          $MAIL->MailFile({to => $email,
	                   subject => "PingER check FAILED on ". hostname(), 
		           msg => "Health Monitor found a problem with PingER MA at $url - " . Dumper($health) . 
			          "\n logfile is attached ",
		           file => $logfile,
			   on_errors => 'die'
			 });
    } else {
        print  encode_json $health; 
    }
    syslog('err', "PingER MA is  NOT OK !:" .  encode_json $health);
    exit 1;
}
 
__END__


=head1 SEE ALSO

L<use Getopt::Long>

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: $

=head1 AUTHOR

Maxim Grigoriev, maxim_at_fnal_dot_gov

=head1 LICENSE

You should have received a copy of the Fermitools  license
along with this software.   

=head1 COPYRIGHT

Copyright (c)  2009, Fermitools

All rights reserved.

=cut
