package perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYOwamp;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Digest::MD5;

use DBI;

use Moose;

use perfSONAR_PS::RegularTesting::Utils qw(datetime2owptstampi datetime2owptime);

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "perfsonarbuoy/owamp" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "latency" and not $results->bidirectional);
};

override 'store_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test            => 1,
                                         target          => 1,
                                         test_parameters => 1,
                                         results         => 1,
                                      });
    my $test            = $parameters->{test};
    my $target          = $parameters->{target};
    my $test_parameters = $parameters->{test_parameters};
    my $results         = $parameters->{results};

    my $bucket_width = 0.0001;

    eval {
        my $dsn = "dbi:mysql:database=".$self->database;
        $dsn .= ";host=".$self->host if $self->host;

        my $dbh = DBI->connect($dsn, $self->username, $self->password, { RaiseError => 0, PrintError => 0 });
        unless ($dbh) {
            die("Problem connecting to database: ".$DBI::errstr);
        }

        $logger->debug("Connected to DB");

        my $testspec_id    = $self->add_testspec(dbh => $dbh, bucket_width => $bucket_width, results => $results);
        unless ($testspec_id) {
            die("Couldn't get test spec");
        }

        $logger->debug("Got test spec: $testspec_id");

        my $source_id      = $self->add_endpoint(dbh => $dbh, date => $results->start_time, endpoint => $results->source);
        unless ($source_id) {
            die("Couldn't get source node");
        }

        $logger->debug("Got source id: $source_id");

        my $destination_id = $self->add_endpoint(dbh => $dbh, date => $results->start_time, endpoint => $results->destination);
        unless ($source_id) {
            die("Couldn't get destination node");
        }

        $logger->debug("Got destination id: $destination_id");

        my ($status, $res) = $self->add_data(dbh => $dbh,
                                             testspec_id => $testspec_id,
                                             source_id   => $source_id,
                                             destination_id => $destination_id,
                                             bucket_width => $bucket_width,
                                             results => $results
                                            );

        if ($status != 0) {
            die("Couldn't save data: $res");
        }
    };
    if ($@) {
        my $msg = "Problem saving results: $@";
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, "");
};

sub add_testspec {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         bucket_width => 1,
                                         results => 1,
                                      });
    my $dbh          = $parameters->{dbh};
    my $bucket_width = $parameters->{bucket_width};
    my $results      = $parameters->{results};

    my %testspec_properties = (
        num_session_packets => $results->packet_count,
        num_sample_packets  => $results->packet_count,
        wait_interval       => $results->inter_packet_time,
        dscp                => 0,
        loss_timeout        => 0,
        packet_padding      => $results->packet_size,
        bucket_width        => $bucket_width,
    );

    my ($status, $res) = $self->query_element(dbh => $dbh,
                                              table => "TESTSPEC",
                                              date => $results->start_time,
                                              properties => \%testspec_properties,
                                             );

    my $testspec_id;
    if ($status == 0) {
        foreach my $result (@$res) {
            $testspec_id = $result->{tspec_id};
        }
    }

    unless ($testspec_id) {
        $testspec_properties{tspec_id} = $self->build_id(\%testspec_properties);

        #$logger->debug("Testspec to add: ".Dumper(\%testspec_properties));

        my ($status, $res) = $self->add_element(dbh => $dbh,
                                                table => "TESTSPEC",
                                                date => $results->start_time,
                                                properties => \%testspec_properties,
                                               );

        unless ($status == 0) {
            my $msg = "Couldn't add new test spec";
            $logger->error($msg);
            return;
        }

        $testspec_id = $testspec_properties{tspec_id};
    }

    return $testspec_id;
}

sub add_endpoint {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         date => 1,
                                         endpoint => 1,
                                      });
    my $dbh      = $parameters->{dbh};
    my $date     = $parameters->{date};
    my $endpoint = $parameters->{endpoint};

    my %node_properties = (
        first => 0,
        last  => 0,
    );

    $node_properties{addr} = $endpoint->address;
    $node_properties{host} = $endpoint->hostname;

    my ($status, $res) = $self->query_element(dbh => $dbh,
                                              table => "NODES",
                                              date => $date,
                                              properties => \%node_properties,
                                             );

    my $node_id;
    if ($status == 0) {
        foreach my $result (@$res) {
            $node_id = $result->{node_id};
        }
    }

    unless ($node_id) {
        $node_properties{node_id} = $self->build_id(\%node_properties);

        my ($status, $res) = $self->add_element(dbh => $dbh,
                                                table => "NODES",
                                                date => $date,
                                                properties => \%node_properties,
                                               );

        unless ($status == 0) {
            my $msg = "Couldn't add new node: $res";
            $logger->error($msg);
            return;
        }

        $node_id = $node_properties{node_id};
    }

    return $node_id;
}

sub add_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         source_id => 1,
                                         destination_id => 1,
                                         testspec_id => 1,
                                         bucket_width => 1,
                                         results => 1,
                                      });
    my $dbh            = $parameters->{dbh};
    my $source_id      = $parameters->{source_id};
    my $testspec_id    = $parameters->{testspec_id};
    my $destination_id = $parameters->{destination_id};
    my $bucket_width    = $parameters->{bucket_width};
    my $results        = $parameters->{results};

    my ($min, $max, $minttl, $maxttl, $sent, $lost, $dups, $maxerr, $finished);

    my %buckets = ();

    # Calculate the stats from the raw pings
    if (scalar(@{ $results->pings }) > 0) {
        $dups = 0;

        my $recv = 0;
        $sent = 0;
        my %packets_seen = ();
        foreach my $ping (@{ $results->pings }) {
            if ($packets_seen{$ping->sequence_number}) {
                $dups++;
                next;
            }

            $sent++;

            unless ($ping->delay) {
                # Skip lost packets
                next;
            }

            $packets_seen{$ping->sequence_number} = 1;

            $recv++;

            if ($ping->ttl) {
                $minttl = $ping->ttl if (not $minttl or $ping->ttl < $minttl);
                $maxttl = $ping->ttl if (not $maxttl or $ping->ttl > $maxttl);
            }

            if ($ping->delay) {
                my $delay = $ping->delay / 1000.0;

                $min = $delay if (not $min or $delay < $min);
                $max = $delay if (not $max or $delay > $max);

                my $bucket = int($delay / $bucket_width);
                $buckets{$bucket} = 0 unless $buckets{$bucket};
                $buckets{$bucket}++;
            }
        }

        $lost = $sent - $recv;
    }
    else {
        $sent = $results->packets_sent;
        if ($results->packets_sent) {
            $lost = $results->packets_sent - $results->packets_received;
        }
        else {
            $lost = 0;
        }
        $dups = $results->duplicate_packets;

        my @sorted_buckets = sort { $a <=> $b} keys %{ $results->delay_histogram };
        $min = $sorted_buckets[0]/1000;
        $max = $sorted_buckets[$#sorted_buckets]/1000;

        my @sorted_ttls    = sort { $a <=> $b} keys %{ $results->ttl_histogram };
        $minttl = $sorted_ttls[0];
        $maxttl = $sorted_ttls[$#sorted_ttls];

        # Convert buckets to milliseconds from seconds.
        foreach my $bucket (keys %{ $results->delay_histogram }) {
            $buckets{int($bucket / (1000*$results->histogram_bucket_size))} = $results->delay_histogram->{$bucket};
        }
    }

    my %data_properties = (
        send_id => $source_id,
        recv_id => $destination_id,
        tspec_id => $testspec_id,
        si => datetime2owptstampi($results->start_time),
        ei => datetime2owptstampi($results->end_time),
        stimestamp => datetime2owptime($results->start_time),
        etimestamp => datetime2owptime($results->end_time),
        start_time => $results->start_time->iso8601(),
        end_time   => $results->end_time->iso8601(),
        min => $min,
        max => $max,
        minttl => $minttl,
        maxttl => $maxttl,
        sent => $sent,
        lost => $lost,
        dups => $dups,
        maxerr => 0,
        finished => 1,
    );

    #use Data::Dumper;
    #$logger->debug("Data Properties: ".Dumper(\%data_properties));

    my ($status, $res) = $self->add_element(dbh => $dbh,
                                            table => "DATA",
                                            date => $results->start_time,
                                            properties => \%data_properties,
                                           );

    unless ($status == 0) {
        my $msg = "Problem adding data";
        $logger->error($msg);
        #return (-1, $msg);
    }

    foreach my $bucket (keys %buckets) {
        my %delay_properties = (
            send_id => $source_id,
            recv_id => $destination_id,
            tspec_id => $testspec_id,
            si => datetime2owptstampi($results->start_time),
            ei => datetime2owptstampi($results->end_time),
            #stimestamp => datetime2owptime($results->start_time),
            #etimestamp => datetime2owptime($results->end_time),
            #start_time => $results->start_time->iso8601(),
            #end_time   => $results->end_time->iso8601(),
            bucket_width => $bucket_width,
            basei => 0,
            i => $bucket,
            n => $buckets{$bucket},
            finished => 1,
        );

        my ($status, $res) = $self->add_element(dbh => $dbh,
                                                table => "DELAY",
                                                date => $results->start_time,
                                                properties => \%delay_properties,
                                               );

        unless ($status == 0) {
            my $msg = "Problem adding data";
            $logger->error($msg);
            #return (-1, $msg);
        }
    }


    return (0, "");
}

sub tables {
    return {
        "TESTSPEC" => {
            columns => [
                { name => 'tspec_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'description', type => "TEXT(1024)" },
                { name => 'num_session_packets', type => "INT UNSIGNED NOT NULL" },
                { name => 'num_sample_packets', type => "INT UNSIGNED NOT NULL" },
                { name => 'wait_interval', type => "DECIMAL(5,4) NOT NULL" },
                { name => 'dscp', type => "INT UNSIGNED NOT NULL" },
                { name => 'loss_timeout', type => "FLOAT NOT NULL" },
                { name => 'packet_padding', type => "INT UNSIGNED NOT NULL" },
                { name => 'bucket_width', type => "DECIMAL(5,4) NOT NULL" },
            ],
            primary_key => "tspec_id",
        },
        "NODES" => {
            columns => [
                { name => 'node_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'node_name', type => "TEXT(128)" },
                { name => 'longname', type => "TEXT(1024)" },
                { name => 'host', type => "TEXT(128)" },
                { name => 'addr', type => "TEXT(128)" },
                { name => 'first', type => "INT UNSIGNED NOT NULL" },
                { name => 'last', type => "INT UNSIGNED NOT NULL" },
            ],
            primary_key => "node_id",
        },
        "DATA" => {
            columns => [
                { name => 'send_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'recv_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'tspec_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'si', type => "INT UNSIGNED NOT NULL" },
                { name => 'ei', type => "INT UNSIGNED NOT NULL" },
                { name => 'stimestamp', type => "BIGINT UNSIGNED NOT NULL" },
                { name => 'etimestamp', type => "BIGINT UNSIGNED NOT NULL" },
                { name => 'start_time', type => "TINYTEXT" },
                { name => 'end_time', type => "TINYTEXT" },
                { name => 'min', type => "FLOAT" },
                { name => 'max', type => "FLOAT" },
                { name => 'minttl', type => "TINYINT" },
                { name => 'maxttl', type => "TINYINT" },
                { name => 'sent', type => "INT UNSIGNED" },
                { name => 'lost', type => "INT UNSIGNED" },
                { name => 'dups', type => "INT UNSIGNED" },
                { name => 'maxerr', type => "FLOAT" },
                { name => 'finished', type => "TINYINT UNSIGNED DEFAULT 0" },
            ],
            primary_key => "si,ei,send_id,recv_id,tspec_id",
            indexes => [ "send_id", "recv_id", "tspec_id" ],
        },
        "DELAY" => {
            columns => [
                { name => 'send_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'recv_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'tspec_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'si', type => "INT UNSIGNED NOT NULL" },
                { name => 'ei', type => "INT UNSIGNED NOT NULL" },
                { name => 'stimestamp', type => "BIGINT UNSIGNED NOT NULL" },
                { name => 'etimestamp', type => "BIGINT UNSIGNED NOT NULL" },
                { name => 'start_time', type => "TINYTEXT" },
                { name => 'end_time', type => "TINYTEXT" },
                { name => 'bucket_width', type => "FLOAT" },
                { name => 'basei', type => "INT UNSIGNED" },
                { name => 'i', type => "INT UNSIGNED" },
                { name => 'n', type => "INT UNSIGNED" },
                { name => 'finished', type => "TINYINT UNSIGNED DEFAULT 0" },
            ],
            primary_key => "i,si,ei,send_id,recv_id,tspec_id",
            indexes => [ "send_id", "recv_id", "tspec_id" ],
        },
        "DATES" => {
            columns => [
                { name => 'year', type => "INT" },
                { name => 'month', type => "INT" },
                { name => 'day', type => "INT" },
            ],
            primary_key => "year,month,day",
            static => 1,
        },
    };
}

override 'time_prefix' => sub {
    my ($self, $date) = @_;

    return sprintf( '%4.4d%2.2d%2.2d', $date->year(), $date->month(), $date->day() );
};

1;
