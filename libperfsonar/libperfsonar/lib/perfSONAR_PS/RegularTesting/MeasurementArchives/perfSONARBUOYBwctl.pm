package perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBwctl;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Digest::MD5;

use DBI;

use perfSONAR_PS::RegularTesting::Utils qw(datetime2owptstampi datetime2owptime);

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "perfsonarbuoy/bwctl" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "throughput");
};

override 'store_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test    => 1,
                                         target  => 1,
                                         test_parameters => 1,
                                         results => 1,
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

        my $testspec_id    = $self->add_testspec(dbh => $dbh, results => $results);
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
                                         results => 1,
                                      });
    my $dbh     = $parameters->{dbh};
    my $results = $parameters->{results};

    my $is_udp = $results->source->protocol eq "udp"?1:0;

    my %testspec_properties = (
        udp => $is_udp,
        duration => $results->time_duration,
        udp_bandwidth => $results->bandwidth_limit,
        len_buffer => $results->buffer_length,
        window_size => $results->window_size,
        parallel_streams => $results->streams,
        tos => $results->tos_bits,
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

    if ($endpoint->address) {
        $node_properties{addr} = $endpoint->address;
    }
    elsif ($endpoint->hostname) {
        $node_properties{addr} = $endpoint->hostname;
    }

    my ($status, $res) = $self->query_element(dbh => $dbh,
                                              table => "NODES",
                                              date => $date,
                                              properties => \%node_properties,
                                             );

    use Data::Dumper;
    $logger->debug("Results for ".Dumper(\%node_properties).": ".Dumper($res));

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
                                         results => 1,
                                      });
    my $dbh            = $parameters->{dbh};
    my $source_id      = $parameters->{source_id};
    my $testspec_id    = $parameters->{testspec_id};
    my $destination_id = $parameters->{destination_id};
    my $results        = $parameters->{results};

    my %data_properties = (
                send_id => $source_id,
                recv_id => $destination_id,
                tspec_id => $testspec_id,
                ti => datetime2owptstampi($results->start_time),
                timestamp => datetime2owptime($results->start_time),
                throughput => $results->summary_results->summary_results->throughput,
                jitter => $results->summary_results->summary_results->jitter,
                lost => $results->summary_results->summary_results->packets_lost,
                sent => $results->summary_results->summary_results->packets_sent,
    );

    use Data::Dumper;
    $logger->debug("Data Properties: ".Dumper(\%data_properties));

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

    return (0, "");
}

sub tables {
    return {
        "TESTSPEC" => {
            columns => [
                { name => 'tspec_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'description', type => "TEXT(1024)" },
                { name => 'duration', type => "INT UNSIGNED NOT NULL DEFAULT 10" },
                { name => 'len_buffer', type => "INT UNSIGNED" },
                { name => 'window_size', type => "INT UNSIGNED" },
                { name => 'tos', type => "TINYINT UNSIGNED" },
                { name => 'parallel_streams', type => "TINYINT UNSIGNED NOT NULL DEFAULT 1" },
                { name => 'udp', type => "BOOL NOT NULL DEFAULT 0" },
                { name => 'udp_bandwidth', type => "BIGINT UNSIGNED" },
            ],
            primary_key => "tspec_id",
        },
        "NODES" => {
            columns => [
                { name => 'node_id', type => "INT UNSIGNED NOT NULL" },
                { name => 'node_name', type => "TEXT(128)" },
                { name => 'longname', type => "TEXT(1024)" },
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
                { name => 'ti', type => "INT UNSIGNED NOT NULL" },
                { name => 'timestamp', type => "BIGINT UNSIGNED NOT NULL" },
                { name => 'throughput', type => "FLOAT" },
                { name => 'jitter', type => "FLOAT" },
                { name => 'lost', type => "BIGINT UNSIGNED" },
                { name => 'sent', type => "BIGINT UNSIGNED" },
            ],
            primary_key => "ti,send_id,recv_id",
            indexes => [ "send_id", "recv_id", "tspec_id" ],
        },
        "DATES" => {
            columns => [
                { name => 'year', type => "INT" },
                { name => 'month', type => "INT" },
            ],
            primary_key => "year,month",
            static => 1,
        },
    };
}

override 'time_prefix' => sub {
    my ($self, $date) = @_;

    return sprintf( '%4.4d%2.2d', $date->year(), $date->month() );
};

1;
