package perfSONAR_PS::RegularTesting::MeasurementArchives::PingER;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Statistics::Descriptive;

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "pinger" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "latency" and $results->bidirectional);
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

    eval {
        my $dsn = "dbi:mysql:database=".$self->database;
        $dsn .= ";host=".$self->host if $self->host;

        my $dbh = DBI->connect($dsn, $self->username, $self->password, { RaiseError => 0, PrintError => 0 });
        unless ($dbh) {
            die("Problem connecting to database: $@");
        }

        $logger->debug("Connected to DB");

        my $source_id      = $self->add_host(dbh => $dbh, date => $results->start_time, endpoint => $results->source);
        unless ($source_id) {
            die("Couldn't get source host");
        }

        $logger->debug("Got source id: $source_id");

        my $destination_id = $self->add_host(dbh => $dbh, date => $results->start_time, endpoint => $results->destination);
        unless ($destination_id) {
            die("Couldn't get destination node");
        }

        $logger->debug("Got destination id: $destination_id");

        my $metadata_id    = $self->add_metadata(dbh => $dbh, source_id => $source_id, destination_id => $destination_id, results => $results);
        unless ($metadata_id) {
            die("Couldn't get metadata");
        }

        $logger->debug("Got metadata: $metadata_id");

        my ($status, $res) = $self->add_data(dbh => $dbh,
                                             metadata_id => $metadata_id,
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

sub add_metadata {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         source_id => 1,
                                         destination_id => 1,
                                         results => 1,
                                      });
    my $dbh     = $parameters->{dbh};
    my $source_id = $parameters->{source_id};
    my $destination_id = $parameters->{destination_id};
    my $results = $parameters->{results};

    use Data::Dumper;
    $logger->debug("Results: ".Dumper($results->unparse));

    my %metadata_properties = (
        src_host => $source_id,
        dst_host => $destination_id,
        transport => $results->source->protocol,
        packetSize => $results->packet_size,
        count => $results->packet_count,
	packetInterval => $results->inter_packet_time,
        ttl => $results->packet_ttl,
    );

    my ($status, $res) = $self->query_element(dbh => $dbh,
                                              table => "metaData",
                                              date => $results->start_time,
                                              properties => \%metadata_properties,
                                             );

    my $metadata_id;
    if ($status == 0) {
        foreach my $result (@$res) {
            $metadata_id = $result->{metaID};
        }
    }

    unless ($metadata_id) {
        my ($status, $res) = $self->add_element(dbh => $dbh,
                                                table => "metaData",
                                                date => $results->start_time,
                                                properties => \%metadata_properties,
                                               );

        unless ($status == 0) {
            my $msg = "Couldn't add new test spec";
            $logger->error($msg);
            return;
        }

        ($status, $res) = $self->query_element(dbh => $dbh,
                                               table => "metaData",
                                               date => $results->start_time,
                                               properties => \%metadata_properties,
                                               );

        if ($status == 0) {
            foreach my $result (@$res) {
                $metadata_id = $result->{metaID};
            }
        }
    }

    return $metadata_id;
}

sub add_host {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         date => 1,
                                         endpoint => 1,
                                      });
    my $dbh      = $parameters->{dbh};
    my $date     = $parameters->{date};
    my $endpoint = $parameters->{endpoint};

    my %host_properties = (
        ip_name => $endpoint->hostname,
        ip_number => $endpoint->address,
    );

    $host_properties{ip_name} = "*" unless ($host_properties{ip_name});

    # XXX: set ip_type

    my ($status, $res) = $self->query_element(dbh => $dbh,
                                              table => "host",
                                              date => $date,
                                              properties => \%host_properties,
                                             );

    my $host_id;
    if ($status == 0) {
        foreach my $result (@$res) {
            $host_id = $result->{host};
        }
    }

    unless ($host_id) {
        my ($status, $res) = $self->add_element(dbh => $dbh,
                                                table => "host",
                                                date => $date,
                                                properties => \%host_properties,
                                               );

        unless ($status == 0) {
            my $msg = "Couldn't add new host: $res";
            $logger->error($msg);
            return;
        }

        $host_id = $host_properties{host};
        ($status, $res) = $self->query_element(dbh => $dbh,
                                               table => "host",
                                               date => $date,
                                               properties => \%host_properties,
                                              );

        if ($status == 0) {
            foreach my $result (@$res) {
                $host_id = $result->{host};
            }
        }
    }

    return $host_id;
}

sub add_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         metadata_id => 1,
                                         results => 1,
                                      });
    my $dbh            = $parameters->{dbh};
    my $metadata_id    = $parameters->{metadata_id};
    my $results        = $parameters->{results};

    # Calculate the delay statistics both RTT and Inter-Packet
    my $rtt_stats = Statistics::Descriptive::Full->new();
    my $ipd_stats = Statistics::Descriptive::Full->new();

    my $prev_delay;
    foreach my $datum (@{ $results->pings }) {
        next unless $datum->delay;
        
        $rtt_stats->add_data($datum->delay);

        if ($prev_delay) {
            $ipd_stats->add_data($datum->delay - $prev_delay);
        }

        $prev_delay = $datum->delay;
    }

    my $rtts_string = join(",", map { $_->delay } @{ $results->pings });
    my $seqNums_string = join(",", map { $_->sequence_number } @{ $results->pings });

    my $prev_datum;
    my $consecutive_packet_loss = 0;
    # XXX: Calculate the conditional loss probability
#    foreach my $datum (sort { $a->sequence_number <=> $b->sequence_number } @{ $results->pings }) {
#        $consecutive_packet_loss += 
#
#        $prev_datum = $datum;
#    }

    # Calculate out-of-order packets and duplicates
    my ($oop, $dups) = (0, 0);
    my %seen = ();
    $prev_datum = undef;
    foreach my $datum (@{ $results->pings }) {
        next unless $datum->delay;

        if ($seen{$datum->sequence_number}) {
            $dups++;
        }

        if ($prev_datum and $datum->sequence_number < $prev_datum->sequence_number) {
            $oop++;
        }

        $prev_datum = $datum;
    }

    my %data_properties = (
        metaID => $metadata_id,
        timestamp => $results->start_time->epoch(),
        minRtt => $rtt_stats->min(),
        meanRtt => $rtt_stats->mean(),
        medianRtt => $results->packets_received?scalar($rtt_stats->percentile(50)):undef,
        maxRtt => $rtt_stats->max(),
        minIpd => $ipd_stats->min(),
        meanIpd => $ipd_stats->mean(),
        maxIpd => $ipd_stats->max(),
        iqrIpd => $results->packets_received?scalar($ipd_stats->percentile(75)) - scalar($ipd_stats->percentile(50)):undef,
        duplicates => $dups,
        outOfOrder => $oop,
        clp  => 0, # XXX
        lossPercent => ($results->packets_sent - $results->packets_received)/$results->packets_sent,
        rtts => $rtts_string,
        seqNums => $seqNums_string
    );

    use Data::Dumper;
    $logger->debug("DATA: ".Dumper(\%data_properties));

    my ($status, $res) = $self->add_element(dbh => $dbh,
                                            table => "data",
                                            date => $results->start_time,
                                            properties => \%data_properties,
                                           );

    $logger->debug("Finished adding data");

    unless ($status == 0) {
        my $msg = "Problem adding data";
        $logger->error($msg);
        #return (-1, $msg);
    }

    return (0, "");
};

sub tables {
    return {
        "host" => {
            columns => [
                 { name => 'host', type => 'BIGINT NOT NULL AUTO_INCREMENT' },
                 { name => 'ip_name', type => 'varchar(52) NOT NULL' },
                 { name => 'ip_number', type => 'varchar(64) NOT NULL' },
                 { name => 'ip_type', type => "enum('ipv4','ipv6')  NOT NULL default 'ipv4'" },
            ],
            static => 1,
            primary_key => "host",
            indexes => [ "ip_name", "ip_number" ],
        },
        "metaData" => {
            columns => [
                 { name => 'metaID', type => 'BIGINT NOT NULL AUTO_INCREMENT' },
                 { name => 'src_host', type => 'BIGINT NOT NULL' },
                 { name => 'dst_host', type => 'BIGINT NOT NULL' },
                 { name => 'transport', type => "enum('icmp','tcp','udp')   NOT NULL DEFAULT 'icmp'" },
                 { name => 'packetSize', type => 'smallint   NOT NULL' },
                 { name => 'count', type => 'smallint   NOT NULL' },
                 { name => 'packetInterval', type => 'smallint' },
                 { name => 'ttl', type => 'smallint' },
            ],
            static => 1,
            primary_key => "metaID",
            indexes => [ "src_host", "dst_host", "packetSize", "count" ],
        },
        "data" => {
            columns => [
                 { name => 'metaID', type => 'BIGINT   NOT NULL' },
                 { name => 'minRtt', type => 'float' },
                 { name => 'meanRtt', type => 'float' },
                 { name => 'medianRtt', type => 'float' },
                 { name => 'maxRtt', type => 'float' },
                 { name => 'timestamp', type => 'bigint(12) NOT NULL' },
                 { name => 'minIpd', type => 'float' },
                 { name => 'meanIpd', type => 'float' },
                 { name => 'maxIpd', type => 'float' },
                 { name => 'duplicates', type => 'tinyint(1)' },
                 { name => 'outOfOrder', type => ' tinyint(1)' },
                 { name => 'clp', type => 'float' },
                 { name => 'iqrIpd', type => 'float' },
                 { name => 'lossPercent', type => 'float' },
                 { name => 'rtts', type => 'varchar(1024)' },
                 { name => 'seqNums', type => 'varchar(1024)' }
            ],
            primary_key => "metaID,timestamp",
            indexes => [ "meanRtt", "medianRtt", "lossPercent", "meanIpd", "clp" ],
            table_format => "data_DATE",
        },
    };
}

override 'time_prefix' => sub {
    my ($self, $date) = @_;

    return sprintf( '%4.4d%2.2d', $date->year(), $date->month() );
};

1;
