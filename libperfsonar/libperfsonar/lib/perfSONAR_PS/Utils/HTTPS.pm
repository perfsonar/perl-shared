package perfSONAR_PS::Utils::HTTPS;

use strict;
use warnings;

our $VERSION = 3.1;

=head1 NAME

perfSONAR_PS::Utils::HTTPS

=head1 DESCRIPTION

A module that provides simple functions for retrieving HTTPS URLs that validate
the certificate.

=head1 API

=cut

use base 'Exporter';
use Params::Validate qw(:all);
use IO::Socket::SSL;
use URI::Split qw(uri_split);
use HTTP::Response;
use Log::Log4perl qw(get_logger);

our @EXPORT_OK = qw( https_get );

my $logger = get_logger(__PACKAGE__);

=head2 https_get()

=cut

sub https_get {
    my $parameters = validate( @_, { url => 1,
                                     verify_hostname => 0,
                                     verify_certificate => 0,
                                     ca_certificate_path  => 0,
                                     ca_certificate_file => 0,
                                     max_redirects => 0,
                                   });
    my $url = $parameters->{url};
    my $verify_certificate = $parameters->{verify_certificate};
    my $verify_hostname = $parameters->{verify_hostname};
    my $ca_certificate_path = $parameters->{ca_certificate_path};
    my $ca_certificate_file = $parameters->{ca_certificate_file};
    my $max_redirects = $parameters->{max_redirects};

    $max_redirects = 3 unless defined $max_redirects;

    my $curr_url = $url;

RETRY:
    my $uri = URI->new($curr_url);

    unless ($uri->scheme) {
        return (-1, "Invalid url: $curr_url");
    }

    my $client;
    if ($uri->scheme eq "https") {

        $logger->debug("Connecting to: ".$uri->host.": ".$uri->port);
        $client = IO::Socket::SSL->new(PeerAddr => $uri->host,
                                          PeerPort => $uri->port,
                                          SSL_ca_file => $ca_certificate_file,
                                          SSL_ca_path => $ca_certificate_path,
                                          SSL_verify_mode => $verify_certificate?0x01:0x00,
                                         );

        if ($client and $verify_hostname) {
            $logger->debug("Verifying hostname");
            my $subject = $client->peer_certificate("owner");
            my @fields = split('/', $subject);

            my $matches = 0;
            my $failed_match;
            foreach my $field (@fields) {
                my ($key, $value) = split("=", $field, 2);

                next unless ($key eq "CN");

                $logger->debug("CN is '$value' looking for '".$uri->host."'");

                if ($value ne $uri->host) {
                    $matches = 0;
                    $failed_match = $value;
                    last;
                }
                else {
                    $matches = 1;
                }
            }

            unless ($matches) {
                my $msg = "Hostname verification failed: ".$failed_match." != ".$uri->host;
                $logger->debug($msg);
                return (-1, $msg);
            }
        }
    }
    elsif ($uri->scheme eq "http") {
        if ($verify_certificate or $verify_hostname) {
            my $msg = "No way to verify $curr_url. Must use HTTPS urls";
            $logger->debug($msg);
            return (-1, $msg);
        }

        $client = IO::Socket::INET->new(PeerAddr => $uri->host,
                                          PeerPort => $uri->port,
                                         );
    }

    unless (defined $client) {
        my $msg = "Problem retrieving $curr_url: ".IO::Socket::SSL::errstr();
        $logger->debug($msg);
        return (-1, $msg);
    }

    print $client "GET ".$uri->path_query." HTTP/1.0\r\nHost: ".$uri->host."\r\n\r\n";
    my $results = "";
    while (<$client>) {
        $results .= $_;
    }
    close $client;

    my $response = HTTP::Response->parse( $results );
    if ($response->is_redirect) {
        if ($max_redirects) {
            $curr_url = $response->header("Location");

            goto RETRY;
        }
        else {
            my $msg = "Problem retrieving $url: Too many redirects";
            $logger->debug($msg);
            return (-1, $msg);
        }
    }
    elsif ($response->is_success) {
        $results = $response->decoded_content?$response->decoded_content:$response->content;

        return (0, $results);
    }
    else {
        my $msg = "Problem retrieving $curr_url: ".$response->status_line;
        $logger->debug($msg);
        return (-1, $msg);
    }
}

1;

__END__

=head1 SEE ALSO

To join the 'perfSONAR Users' mailing list, please visit:

  https://mail.internet2.edu/wws/info/perfsonar-user

The perfSONAR-PS git repository is located at:

  https://code.google.com/p/perfsonar-ps/

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id: Host.pm 5139 2012-06-01 15:48:46Z aaron $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

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

Copyright (c) 2008-2009, Internet2

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
