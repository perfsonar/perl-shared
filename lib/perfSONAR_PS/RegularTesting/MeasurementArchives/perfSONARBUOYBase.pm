package perfSONAR_PS::RegularTesting::MeasurementArchives::perfSONARBUOYBase;

use strict;
use warnings;

our $VERSION = 3.4;

use Log::Log4perl qw(get_logger);
use Params::Validate qw(:all);

use Math::Int64 qw(uint64 uint64_to_number);
use Digest::MD5;

use DBI;

use Moose;

extends 'perfSONAR_PS::RegularTesting::MeasurementArchives::Base';

has 'host' => (is => 'rw', isa => 'Str');
has 'username' => (is => 'rw', isa => 'Str');
has 'password' => (is => 'rw', isa => 'Str');
has 'database' => (is => 'rw', isa => 'Str');

has '_dates_initialized' => (is => 'rw', isa => 'HashRef', default => sub { {} });

my $logger = get_logger(__PACKAGE__);

override 'nonce' => sub {
    my ($self) = @_;

    my $nonce = "";
    $nonce .= ($self->host?$self->host:"localhost");
    $nonce .= "_".$self->database;

    return $nonce;
};

sub time_prefix {
    my ($self, $date) = @_;

    die("'time_prefix' needs to be overridden");
}

sub tables {
    die("'tables' function needs to be overridden");
}

sub get_dbh {
    my ($self) = @_;

    return DBI->connect("dbi:mysql:".$self->database, $self->username, $self->password, { RaiseError => 0, PrintError => 0 });
}

sub build_id {
    my ($self, $properties) = @_;

    my $md5 = Digest::MD5->new();

    foreach my $attr (keys %$properties) {
        $md5->add($attr);
        $md5->add($properties->{$attr}) if defined $properties->{$attr};
    }

    my $hex = $md5->hexdigest;
    $hex = substr($hex, 0, 8);

    return hex($hex);
}

sub add_element {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh        => 1,
                                         table      => 1,
                                         date       => 1,
                                         ignore     => 0,
                                         properties => 1,
                                      });
    my $dbh        = $parameters->{dbh};
    my $table      = $parameters->{table};
    my $date       = $parameters->{date};
    my $ignore     = $parameters->{ignore};
    my $properties = $parameters->{properties};

    unless ($self->tables->{$table}) {
        my $msg = "Unknown table: $table";
        $logger->error($msg);
        return (-1, $msg);
    }

    my ($status, $res) = $self->initialize_tables({ dbh => $dbh, date => $date });
    unless ($status == 0) {
        my $msg = "Couldn't add element: $res";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $table_name = $self->get_table_name({ table => $table, date => $date });

    $logger->debug("Adding to table: $table_name");

    return $self->_add_element({ dbh => $dbh, table => $table_name, ignore => $ignore, properties => $properties });
}

sub _add_element {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         table => 1,
                                         ignore => 0,
                                         properties => 1,
                                      });
    my $dbh = $parameters->{dbh};
    my $table = $parameters->{table};
    my $ignore = $parameters->{ignore};
    my $properties = $parameters->{properties};

    my @keys = keys %$properties;
    my @parameters = map { $properties->{$_} } @keys;
    my @parameter_pointers = map { "?" } @keys;

    my $ignore_parameter = $ignore?"IGNORE":"";

    my $insert_query = "INSERT ".$ignore_parameter." INTO ".$table." (".join(",", @keys).") VALUES (".join(",", @parameter_pointers).")";

    my $sth = $dbh->prepare($insert_query);

    $logger->debug("Insert query: $insert_query");

    unless ($sth->execute(@parameters)) {
        my $msg = "Problem adding element to database: $DBI::errstr";
        $logger->error($msg);
        return (-1, $msg);
    }

    return (0, "");
}

sub query_element {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh        => 1,
                                         table      => 1,
                                         date       => 1,
                                         properties => 1,
                                      });
    my $dbh  = $parameters->{dbh};
    my $table = $parameters->{table};
    my $date = $parameters->{date};
    my $properties = $parameters->{properties};

    unless ($self->tables->{$table}) {
        my $msg = "Unknown table: $table";
        $logger->error($msg);
        return (-1, $msg);
    }

    my ($status, $res) = $self->initialize_tables({ dbh => $dbh, date => $date });
    unless ($status == 0) {
        my $msg = "Couldn't add element: $res";
        $logger->error($msg);
        return (-1, $msg);
    }

    # XXX: verify the parameters before executing

    my $table_name = $self->get_table_name({ table => $table, date => $date });

    return $self->_query_element({ dbh => $dbh, table => $table_name, properties => $properties });
}

sub _query_element {
    my ($self, @args) = @_;
    my $parameters = validate( @args, {
                                         dbh => 1,
                                         table => 1,
                                         properties => 1,
                                      });
    my $dbh = $parameters->{dbh};
    my $table = $parameters->{table};
    my $properties = $parameters->{properties};

    my $query = "SELECT * FROM $table";
    my $query_concat = "WHERE";
    my @query_parameters = ();
    foreach my $property (keys %{ $properties }) {
        if (defined $properties->{$property}) {
            $query .= " ".$query_concat." ".$property."=?";
            push @query_parameters, $properties->{$property};
        }
        else {
            $query .= " ".$query_concat." ".$property." IS NULL";
        }
        $query_concat = "AND";
    }

    $logger->debug("Query: $query");
    use Data::Dumper;
    $logger->debug("Query Parameters: ".Dumper(\@query_parameters));

    my $sth = $dbh->prepare($query);
    unless ($sth) {
        my $msg = "Problem preparing query";
        $logger->error($msg);
        return (-1, $msg);
    }

    unless ($sth->execute(@query_parameters)) {
        my $msg = "Problem executing query";
        $logger->error($msg);
        return (-1, $msg);
    }

    my $results = $sth->fetchall_arrayref({});
    unless ($results) {
        my $msg = "Problem with query";
        $logger->error($msg);
        return (-1, $msg);
    }

    use Data::Dumper;
    $logger->debug("Query Results: ".Dumper($results));

    return (0, $results);
}

sub get_table_name {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { table => 1, date => 1 });
    my $table = $parameters->{table};
    my $date  = $parameters->{date};

    my $table_name;
    if ($self->tables->{$table}->{static}) {
        $logger->debug("Static table: $table");
        $table_name = $table;
    }
    else {
        $logger->debug("Dynamic table: $table");
        my $table_prefix = $self->time_prefix($date);

        if ($self->tables->{$table}->{table_format}) {
            $logger->debug("Format table: $table");
            $table_name = $self->tables->{$table}->{table_format};
            $table_name =~ s/DATE/$table_prefix/;
            $table_name =~ s/TABLENAME/$table/;
            $logger->debug("Format table name: $table_name");
        }
        else {
            $table_name = $table_prefix."_".$table;
        }
    }

    return $table_name;
}

sub initialize_tables {
    my ($self, @args) = @_;
    my $parameters = validate( @args, { dbh => 1, date => 1 });
    my $dbh     = $parameters->{dbh};
    my $date    = $parameters->{date};

    my $table_prefix = $self->time_prefix($date);

    return (0, "") if $self->_dates_initialized->{$table_prefix};

    foreach my $table_type (keys %{ $self->tables }) {
        my $table_name = $self->get_table_name({ table => $table_type, date => $date });

        my $columns = $self->tables->{$table_type}->{columns};

        my $table_description = join(",", map { $_->{name}." ".$_->{type} } @$columns);

        $logger->debug("Table Description: $table_description");

        if ($self->tables->{$table_type}->{primary_key}) {
            $table_description .= ", PRIMARY KEY(".$self->tables->{$table_type}->{primary_key}.")";
        }

        if ($self->tables->{$table_type}->{indexes}) {
            foreach my $index (@{ $self->tables->{$table_type}->{indexes} }) {
                $table_description .= ", INDEX(".$index.")";
            }
        }

        my $sql = "CREATE TABLE IF NOT EXISTS $table_name ($table_description)";
        $logger->debug("SQL: $sql");

        unless ($dbh->do($sql)) {
            my $msg = "Couldn't create $table_name: $DBI::errstr";
            $logger->error($msg);
            return (-1, $msg);
        }

	# To aid in the upgrade procedure, convert any existing decimal tables
	# (i.e. 'float' tables) into decimal tables.
        foreach my $column (@$columns) {
            next unless (lc($column->{type}) =~ /decimal/);

            $sql = "ALTER TABLE $table_name MODIFY ".$column->{name}." ".$column->{type};
            $logger->debug("SQL: $sql");
            unless ($dbh->do($sql)) {
                $logger->warn("Problem setting column type: ".$DBI::errstr);
            }
        }
    }

    # Add the dates to the table if there is a dates table (i.e. it's a
    # perfSONARBUOY-esque database).

    if ($self->tables->{DATES}) {
        my %date_properties = (
            year => $date->year(),
            month => $date->month(),
        );

        foreach my $column (@{ $self->tables->{DATES}->{columns} }) {
            if ($column->{name} eq "day") {
                $date_properties{day} = $date->day();
            }
        }

        my ($status, $res) = $self->_add_element({ dbh => $dbh, table => "DATES", ignore => 1, properties => \%date_properties });
        if ($status != 0) {
            my $msg = "Problem adding dates to DATES table";
            $logger->error($msg);
            return (-1, $msg);
        }
    }

    $self->_dates_initialized->{$table_prefix} = 1;

    return (0, "");
}

1;
