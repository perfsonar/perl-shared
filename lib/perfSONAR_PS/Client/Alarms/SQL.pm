package perfSONAR_PS::Client::Alarms::SQL;

use strict;
use warnings;
use Log::Log4perl qw(get_logger);
use perfSONAR_PS::DB::SQL;
use perfSONAR_PS::Utils::ParameterValidation;
use Params::Validate qw(:all);
use Data::Dumper;

our $VERSION = 0.09;

use fields "READ_ONLY", "DBI_STRING", "DB_USERNAME", "DB_PASSWORD", "DB_TABLE", "DB_OPEN", "DATADB", "LOGGER";

sub new {
	my ($package, $dbi_string, $db_username, $db_password, $table, $read_only) = @_;

	my $self = fields::new($package);

	if ($read_only) {
		$self->{"READ_ONLY"} = 1;
	} else {
		$self->{"READ_ONLY"} = 0;
	}

	if (defined $dbi_string and $dbi_string ne "") { 
		$self->{"DBI_STRING"} = $dbi_string;
	}

	if (defined $db_username and $db_username ne "") { 
		$self->{"DB_USERNAME"} = $db_username;
	}

	if (defined $db_password and $db_password ne "") { 
		$self->{"DB_PASSWORD"} = $db_password;
	}

	if (defined $table and $table ne "") { 
		$self->{"DB_TABLE"} = $table;
	} else {
		$self->{"DB_TABLE"} = "link_status";
	}

	$self->{"DB_OPEN"} = 0;
	$self->{"DATADB"} = "";

	$self->{LOGGER} = get_logger("perfSONAR_PS::Client::Alarms::SQL");

	return $self;
}

sub open {
	my ($self) = @_;

	return (0, "") if ($self->{DB_OPEN} != 0);

	$self->{LOGGER}->debug("Table: ".$self->{DB_TABLE});

	$self->{DATADB} = new perfSONAR_PS::DB::SQL({ name => $self->{DBI_STRING}, user => $self->{DB_USERNAME}, pass => $self->{DB_PASSWORD} });
	if (not defined $self->{DATADB}) {
		my $msg = "Couldn't open specified database";
		$self->{LOGGER}->error($msg);
		return (-1, $msg);
	}

	my $status = $self->{DATADB}->openDB;
	if ($status == -1) {
		my $msg = "Couldn't open status database";
		$self->{LOGGER}->error($msg);
		return (-1, $msg);
	}

	$self->{DB_OPEN} = 1;

	return (0, "");
}

sub close {
	my ($self) = @_;

	return 0 if ($self->{DB_OPEN} == 0);

	$self->{DB_OPEN} = 0;

	return $self->{DATADB}->closeDB;
}

sub setDBIString {
	my ($self, $dbi_string) = @_;

	$self->close();

	$self->{DB_OPEN} = 0;
	$self->{DBI_STRING} = $dbi_string;

    return;
}

sub dbIsOpen {
	my ($self) = @_;
	return $self->{DB_OPEN};
}

sub getDBIString {
	my ($self) = @_;

	return $self->{DBI_STRING};
}

sub getAlarms {
    my ( $self, @args ) = @_;
    my $parameters = validateParams(@args,
            {
                subjects => { type => ARRAYREF, optional => 1 },
                keys => { type => ARRAYREF, optional => 1 },
                timeFilters => { type => HASHREF, optional => 1},
                alarmFilters => { type => HASHREF, optional => 1},
            });

	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);

    my $sqlString = "select metadataId, alarmId, type, facility, severity, serviceAffecting, description, measuredStartTime, machineStartTime, firstObservedTime, lastObservedTime from ".$self->{DB_TABLE};

    my $hasWhere = 0;

    if ($parameters->{timeFilters}) {
        foreach my $filter (keys %{ $parameters->{timeFilters} }) {
            if (not $hasWhere) {
                $sqlString .= " where";
                $hasWhere = 1;
            } else {
                $sqlString .= " and";
            }

            if ($filter eq "startTime") {
                $sqlString .= " lastObservedTime >= '".$parameters->{timeFilters}->{startTime}."'";
            } elsif ($filter eq "endTime") {
                $sqlString .= " measuredStartTime <= '".$parameters->{timeFilters}->{endTime}."'";
            } else {
                my $msg = "Invalid time filter: ".$filter;
                $self->{LOGGER}->error($msg);
                return (-1, $msg);
            }
        }
    }

    if ($parameters->{alarmFilters}) {
        foreach my $filter (keys %{ $parameters->{alarmFilters} }) {
            if (not $hasWhere) {
                $sqlString .= " where";
                $hasWhere = 1;
            } else {
                $sqlString .= " and";
            }

            if ($filter eq "facility") {
                $sqlString .= " facility = '".$parameters->{alarmFilters}->{facility}."'";
            } elsif ($filter eq "severity") {
                $sqlString .= " severity = '".$parameters->{alarmFilters}->{severity}."'";
            } elsif ($filter eq "description") {
                $sqlString .= " description = '".$parameters->{alarmFilters}->{description}."'";
            } elsif ($filter eq "serviceAffecting") {
                # validate 'true' or 'false'
                $sqlString .= " serviceAffecting = '".$parameters->{alarmFilters}->{serviceAffecting}."'";
            } else {
                my $msg = "Invalid alarm filter: ".$filter;
                $self->{LOGGER}->error($msg);
                return (-1, $msg);
            }
        }
    }

    $self->{LOGGER}->debug("SQL string after filter additions: ".$sqlString);
   
    my @results = ();

#    if ($parameters->{keys}) {
#        foreach my $key (@{ $parameters->{keys} }) {
#	        my $alarms = $self->{DATADB}->query({ query => $sqlString . " and metadataId = '".$key."'" });
#
#            if ($alarms == -1) {
#                my $msg = "Couldn't grab information on key ".$key;
#                $self->{LOGGER}->error($msg);
#                return (-1, $msg);
#            }
#
#            my %metadata = ();
#            $metadata{"name"} = $key;
#
#            my @data = ();
#            foreach my $alarm_ref (@$alarms) {
#                my %alarm_hash = ();
#                $alarm_hash{"alarmId"} = $alarm_ref->[1];
#                $alarm_hash{"facility"} = $alarm_ref->[2];
#                $alarm_hash{"severity"} = $alarm_ref->[3];
#                $alarm_hash{"serviceAffecting"} = $alarm_ref->[4];
#                $alarm_hash{"description"} = $alarm_ref->[5];
#                $alarm_hash{"startTime"} = $alarm_ref->[6];
#                $alarm_hash{"machineStartTime"} = $alarm_ref->[7];
#
#    			push @data, \%alarm_hash;
#            }
#
#            my %pair = ();
#            $pair{"metadata"} = \%metadata;
#            $pair{"data"} = \@data;
#
#            push @results, \%pair;
#        }
#    } else {
        my $alarms = $self->{DATADB}->query({ query => $sqlString });

        if ($alarms == -1) {
            my $msg = "Couldn't grab alarms from database";
            $self->{LOGGER}->error($msg);
            return (-1, $msg);
        }

        my %all_metadata = ();

        foreach my $alarm_ref (@$alarms) {
            my $key = $alarm_ref->[0];

            my $pair_hash = $all_metadata{$key};

            if (not $pair_hash) {
                my %pair = ();
                my %metadata = ();
                $metadata{"name"} = $key;
                my @data = ();

                $pair{"metadata"} = \%metadata;
                $pair{"data"} = \@data;

                $all_metadata{$key} = \%pair;

                $pair_hash = $all_metadata{$key};
            }

            my $data_arr = $pair_hash->{data};

            my %alarm_hash = ();
            $alarm_hash{"alarmId"} = $alarm_ref->[1];
            $alarm_hash{"type"} = $alarm_ref->[2];
            $alarm_hash{"facility"} = $alarm_ref->[3];
            $alarm_hash{"severity"} = $alarm_ref->[4];
            $alarm_hash{"serviceAffecting"} = $alarm_ref->[5];
            $alarm_hash{"description"} = $alarm_ref->[6];
            $alarm_hash{"startTime"} = $alarm_ref->[7];
            $alarm_hash{"machineStartTime"} = $alarm_ref->[8];
            $alarm_hash{"lastObservedTime"} = $alarm_ref->[10];

			push @$data_arr, \%alarm_hash;
        }

        foreach my $key (keys %all_metadata) {
            $self->{LOGGER}->debug("Found: $key -- ".Dumper($all_metadata{$key}));
            push @results, $all_metadata{$key};
        }
#    }

	return (0, \@results);
}

#sub getKeys {
#	my ($self) = @_;
#
#	return (-1, "Database is not open") if ($self->{DB_OPEN} == 0);
#
#	my $keys = $self->{DATADB}->query({ query => "select distinct metadataId from ".$self->{DB_TABLE} });
#	if ($keys == -1) {
#		$self->{LOGGER}->error("Couldn't grab list of keys");
#		return (-1, "Couldn't grab list of keys");
#	}
#
#	my @keys = ();
#	foreach my $key_ref (@{ $keys }) {
#		my @key = @{ $key_ref };
#
#		push @keys, $key[0];
#	}
#
#	return (0, \@keys);
#}

1;

__END__

=head1 NAME

perfSONAR_PS::Client::Alarms::SQL - A module that provides methods for
interacting with a Alarms MA database directly.

=head1 DESCRIPTION

This module allows one to interact with the Alarms MA SQL Backend directly
using a standard set of methods. The API provided is identical to the API for
interacting with the MAs via its Web Services interface. Thus, a client written
to read from or update a Alarms MA can be easily modified to interact directly
with its underlying database allowing more efficient interactions if required.

The module is to be treated as an object, where each instance of the object
represents a connection to a single database. Each method may then be invoked
on the object for the specific database.  

=head1 SYNOPSIS

	use perfSONAR_PS::Client::Alarms::SQL;

	my $status_client = new perfSONAR_PS::Client::Alarms::SQL("DBI:SQLite:dbname=status.db");
	if (not defined $status_client) {
		print "Problem creating client for status MA\n";
		exit(-1);
	}

	my ($status, $res) = $status_client->open;
	if ($status != 0) {
		print "Problem opening status MA: $res\n";
		exit(-1);
	}

	($status, $res) = $status_client->getAll();
	if ($status != 0) {
		print "Problem getting complete database: $res\n";
		exit(-1);
	}

	my @links = (); 

	foreach my $id (keys %{ $res }) {
		print "Link ID: $id\n";

		foreach my $link ( @{ $res->{$id} }) {
			print "\t" . $link->getStartTime . " - " . $link->getEndTime . "\n";
			print "\t-Knowledge Level: " . $link->getKnowledge . "\n";
			print "\t-operAlarms: " . $link->getOperAlarms . "\n";
			print "\t-adminAlarms: " . $link->getAdminAlarms . "\n";
		}
	
		push @links, $id;
	}

	($status, $res) = $status_client->getLinkAlarms(\@links, "");
	if ($status != 0) {
		print "Problem obtaining most recent link status: $res\n";
		exit(-1);
	}

	foreach my $id (keys %{ $res }) {
		print "Link ID: $id\n";

		foreach my $link ( @{ $res->{$id} }) {
			print "-operAlarms: " . $link->getOperAlarms . "\n";
			print "-adminAlarms: " . $link->getAdminAlarms . "\n";
		}
	}

	($status, $res) = $status_client->getLinkHistory(\@links);
	if ($status != 0) {
		print "Problem obtaining link history: $res\n";
		exit(-1);
	}

	foreach my $id (keys %{ $res }) {
		print "Link ID: $id\n";
	
		foreach my $link ( @{ $res->{$id} }) {
			print "-operAlarms: " . $link->getOperAlarms . "\n";
			print "-adminAlarms: " . $link->getAdminAlarms . "\n";
		}
	}

=head1 DETAILS

=head1 API

The API os perfSONAR_PS::Client::Alarms::SQL is rather simple and greatly
resembles the messages types received by the server. It is also identical to
the perfSONAR_PS::Client::Alarms::MA API allowing easy construction of
programs that can interface via the MA server or directly with the database.

=head2 new($package, $dbi_string)

The new function takes a DBI connection string as its first argument. This
specifies which DB to read from/write to.

=head2 open($self)

The open function opens the database to read from/write to. The function
returns an array containing two items. The first is the return status of the
function, 0 on success and non-zero on failure. The second is the error message
generated if applicable.

=head2 close($self)

The close function closes the associated database. It returns 0 on success and
-1 on failure.

=head2 setDBIString($self, $dbi_string)

The setDBIString function changes the database that the instance uses. If open,
it closes the current database.

=head2 dbIsOpen($self)

The dbIsOpen function checks whether the database backend is currently open. If so, it returns 1, if not, 0.

=head2 getDBIString($self)

The getDBIString function returns the current DBI string

=head2 getAll($self)

The getAll function gets the full contents of the database. It returns the
results as a hash with the key being the link id. Each element of the hash is
an array of perfSONAR_PS::Alarms::Link structures containing a the status
of the specified link at a certain point in time.

=head2 getLinkHistory($self, $link_ids)

The getLinkHistory function returns the complete history of a set of links. The
$link_ids parameter is a reference to an array of link ids. It returns the
results as a hash with the key being the link id. Each element of the hash is
an array of perfSONAR_PS::Alarms::Link structures containing a the status
of the specified link at a certain point in time.

=head2 getLinkAlarms($self, $link_ids, $time)

The getLinkAlarms function returns the link status at the specified time. The
$link_ids parameter is a reference to an array of link ids. $time is the time
at which you'd like to know each link's status. $time is a perfSONAR_PS::Time
element. If $time is an undefined, it returns the most recent information it
has about each link. It returns the results as a hash with the key being the
link id. Each element of the hash is an array of perfSONAR_PS::Alarms::Link
structures containing a the status of the specified link at a certain point in
time.

=head2 updateLinkAlarms($self, $time, $link_id, $knowledge_level, $oper_value, $admin_value, $do_update) 

The updateLinkAlarms function adds a new data point for the specified link.
$time is a unix timestamp corresponding to when the measurement occured.
$link_id is the link to update. $knowledge_level says whether or not this
measurement can tell us everything about a given link ("full") or whether the
information only corresponds to one side of the link("partial"). $oper_value is
the current operational status and $admin_value is the current administrative
status.  $do_update tells whether or not we should try to update the a given
range of information(e.g. if you were polling the link and knew that nothing
had changed from the previous iteration, you could set $do_update to 1 and the
server would elongate the previous range instead of creating a new one).

=head2 getUniqueIDs($self)

This function is ONLY available in the SQL client as the functionality it is
not exposed by the MA. It does more or less what it sounds like, it returns a
list of unique link ids that appear in the database. This is used by the MA to
get the list of IDs to register with the LS.

=head1 SEE ALSO

L<perfSONAR_PS::DB::SQL>, L<perfSONAR_PS::Alarms::Link>,L<perfSONAR_PS::Client::Alarms::MA>, L<Log::Log4perl>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
# vim: expandtab shiftwidth=4 tabstop=4
