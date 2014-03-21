package perfSONAR_PS::RegularTesting::MeasurementArchives::TracerouteMA;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Data::Validate::Domain qw(is_hostname);
use Data::Validate::IP qw(is_ipv4);
use Net::IP;

use Digest::MD5;

use DBI;

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBase';

my $logger = get_logger(__PACKAGE__);

override 'type' => sub { "traceroute_ma" };

override 'accepts_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { test => 1, target => 1, test_parameters => 1, results => 1});
    my $results = $parameters->{results};

    return ($results->type eq "traceroute");
};

override 'store_results' => sub {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         test            => 1,
                                         target          => 1,
                                         test_parameters => 1,
                                         results         => 1,
                                      });
    my $test    = $parameters->{test};
    my $results = $parameters->{results};

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

        my ($status, $res) = $self->add_data(dbh => $dbh,
                                             testspec_id => $testspec_id,
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

    my %testspec_properties = (
        firstTTL   => $results->packet_first_ttl,
        maxTTL     => $results->packet_max_ttl,
        packetSize => $results->packet_size,
        src        => $results->source->address,
        srcType    => get_addrType($results->source->address),
        dst        => $results->destination->address,
        dstType    => get_addrType($results->destination->address),
    );

    $testspec_properties{subjKey} = $self->build_id(\%testspec_properties);

    my ($status, $res) = $self->add_element(dbh => $dbh,
                                            table => "TESTSPEC",
                                            date => $results->start_time,
                                            properties => \%testspec_properties,
                                            ignore => 1,
                                           );

    unless ($status == 0) {
        my $msg = "Problem adding data";
        $logger->error($msg);
        return (-1, $msg);
    }

    return $testspec_properties{subjKey};
}

sub add_data {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         testspec_id => 1,
                                         results => 1,
                                      });
    my $dbh            = $parameters->{dbh};
    my $testspec_id    = $parameters->{testspec_id};
    my $results        = $parameters->{results};

    my %measurement_properties = (
                testspec_key => $testspec_id,
                timestamp    => $results->start_time->epoch(),
    );

    my ($status, $res) = $self->add_element(dbh => $dbh,
                                            table => "MEASUREMENT",
                                            date => $results->start_time,
                                            properties => \%measurement_properties,
                                           );

    unless ($status == 0) {
        my $msg = "Problem adding data";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $measurement_id;

    ($status, $res) = $self->query_element(dbh => $dbh,
                                              table => "MEASUREMENT",
                                              date => $results->start_time,
                                              properties => \%measurement_properties,
                                             );
    if ($status == 0) {
        foreach my $measurement (@$res) {
            if ($measurement->{id}) {
                $measurement_id = $measurement->{id};
            }
        }
    }

    unless (defined $measurement_id) {
        my $msg = "Problem finding just added measurement";
        $logger->error($msg);
        return (-1, $msg);
    }

    foreach my $hop (@{ $results->hops }) {
        next unless $hop->ttl and $hop->delay and $hop->address;

        my %hop_properties = (
            measurement_id => $measurement_id,
            ttl => $hop->ttl,
            queryNum => $hop->query_number,
            delay => $hop->delay,
            addr => $hop->address,
            addrType => get_addrType($hop->address),
        );

        use Data::Dumper;
        $logger->debug("Hop Properties: ".Dumper(\%hop_properties));

        my ($status, $res) = $self->add_element(dbh => $dbh,
                                                table => "HOPS",
                                                date => $results->start_time,
                                                properties => \%hop_properties,
                                               );
        unless ($status == 0) {
            my $msg = "Problem adding data";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    return (0, "");
}

sub get_addrType {
    my ($address) = @_;

    if ( is_ipv4( $address ) ) {
        return "ipv4";
    }
    elsif ( &Net::IP::ip_is_ipv6( $address ) ) {
        return "ipv6";
    }
    elsif ( is_hostname( $address ) ) {
        return "hostname";
    }

    return "";
}

sub tables {
    return {
        "TESTSPEC" => {
            columns => [
                { name => 'id', type => "INT NOT NULL AUTO_INCREMENT" },
                { name => 'subjKey', type => "TEXT(50) NOT NULL" },
                { name => 'srcType', type => "TEXT(10) NOT NULL" },
                { name => 'src', type => "TEXT(150) NOT NULL" },
                { name => 'dstType', type => "TEXT(10) NOT NULL" },
                { name => 'dst', type => "TEXT(150) NOT NULL" },
                { name => 'firstTTL', type => "INT UNSIGNED" },
                { name => 'maxTTL', type => "INT UNSIGNED" },
                { name => 'waitTime', type => "INT UNSIGNED" },
                { name => 'pause', type => "INT UNSIGNED" },
                { name => 'packetSize', type => "INT UNSIGNED" },
                { name => 'numBytes', type => "INT UNSIGNED" },
                { name => 'arguments', type => "TEXT(20)" },
            ],
            primary_key => "id",
        },
        "MEASUREMENT" => {
            columns => [
                { name => 'id', type => "INT NOT NULL AUTO_INCREMENT" },
                { name => 'testspec_key', type => "TEXT(50) NOT NULL" },
                { name => 'timestamp', type => "INT UNSIGNED NOT NULL" },
            ],
            primary_key => "id",
        },
        "HOPS" => {
            columns => [
                { name => 'id', type => "INT UNSIGNED NOT NULL AUTO_INCREMENT" },
                { name => 'measurement_id', type => "INT NOT NULL" },
                { name => 'ttl', type => "INT NOT NULL" },
                { name => 'addrType', type => "TEXT(10) NOT NULL" },
                { name => 'addr', type => "TEXT(150) NOT NULL" },
                { name => 'queryNum', type => "INT NOT NULL" },
                { name => 'numBytes', type => "INT" },
                { name => 'delay', type => "FLOAT" },
            ],
            primary_key => "id",
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
