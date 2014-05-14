package perfSONAR_PS::MeshConfig::Generators::MaDDash;
use strict;
use warnings;

our $VERSION = 3.1;

use Params::Validate qw(:all);
use Log::Log4perl qw(get_logger);

use JSON;
use YAML qw(Dump);
use Encode qw(encode);

use base 'Exporter';

our @EXPORT_OK = qw( generate_maddash_config );

=head1 NAME

perfSONAR_PS::MeshConfig::Generators::MaDDash;

=head1 DESCRIPTION

=head1 API

=cut

my $logger = get_logger(__PACKAGE__);

sub generate_maddash_config {
    my $parameters = validate( @_, { meshes => 1, existing_maddash_yaml => 1, maddash_options => 1 } );
    my $meshes                = $parameters->{meshes};
    my $existing_maddash_yaml = $parameters->{existing_maddash_yaml};
    my $maddash_options       = $parameters->{maddash_options};

    # Need to make changes to the YAML parser so that the Java YAML parser will
    # grok the output.
    local $YAML::UseHeader = 0;
    local $YAML::CompressSeries = 0;

    $existing_maddash_yaml->{dashboards} = [] unless $existing_maddash_yaml->{dashboards};
    $existing_maddash_yaml->{grids}      = [] unless $existing_maddash_yaml->{grids};
    $existing_maddash_yaml->{checks}     = {} unless $existing_maddash_yaml->{checks};
    $existing_maddash_yaml->{groups}     = {} unless $existing_maddash_yaml->{groups};
    $existing_maddash_yaml->{groupMembers}  = [] unless $existing_maddash_yaml->{groupMembers};
    
    my @deleted_grids = ();
    my $elements_to_delete = { groups => [], checks => [] };
    
    # Delete the elements that we added
    foreach my $type ("dashboards", "grids", "groupMembers") {
        my @new_value = ();
        foreach my $element (@{ $existing_maddash_yaml->{$type} }) {
            if ($element->{added_by_mesh_agent}) {
                if ($type eq "grids") {
                    push @deleted_grids, $element->{name};
                    push @{ $elements_to_delete->{groups} }, $element->{rows};
                    push @{ $elements_to_delete->{groups} }, $element->{columns};
                    push @{ $elements_to_delete->{checks} }, @{ $element->{checks} };
                }
            }
            else {
                push @new_value, $element 
            }
        }

        $existing_maddash_yaml->{$type} = \@new_value;
    }

    foreach my $type (keys %$elements_to_delete) {
        foreach my $key (@{ $elements_to_delete->{$type} }) {
            delete($existing_maddash_yaml->{$type}->{$key});
        }
    }
    
    # Verify that there are tests to be run
    foreach my $mesh (@$meshes) {
        my $num_tests = 0;

        foreach my $test (@{ $mesh->tests }) {
            unless ($test->parameters->type eq "perfsonarbuoy/bwctl" or $test->parameters->type eq "perfsonarbuoy/owamp") {
                $logger->debug("Skipping: ".$test->parameters->type);
                next;
            }

            if ($test->disabled) {
                $logger->debug("Skipping disabled test: ".$test->description);
                next;
            }
    
            $num_tests++;
        }

        unless ($num_tests) {
            $logger->debug("No bwctl or owamp tests run by this mesh");
             next;
        }

        my $dashboards = $existing_maddash_yaml->{dashboards};
        my $checks     = $existing_maddash_yaml->{checks};
        my $groups     = $existing_maddash_yaml->{groups};
        my $groupMembers     = $existing_maddash_yaml->{groupMembers};
        my $grids      = $existing_maddash_yaml->{grids};

        my $dashboard = {};
        $dashboard->{name}                = $mesh->description?$mesh->description:"Mesh Sites";
        $dashboard->{grids}               = [];
        $dashboard->{added_by_mesh_agent} = 1;
        
        #generate groupMembers. not we could 
        my @all_hosts = ();
        push @all_hosts, @{ $mesh->hosts };

        foreach my $organization (@{ $mesh->organizations }) {
            push @all_hosts, @{ $organization->hosts };

            foreach my $site (@{ $organization->sites }) {
                push @all_hosts, @{ $site->hosts };
            }
        }

        foreach my $host (@all_hosts) {
            next unless $host->addresses;

            foreach my $address (@{ $host->addresses }) {
                $address = __normalize_addr($address);
                my $description = $host->description?$host->description:$address;

                my $member_params = { 
                    "id" => $address, 
                    "label" => $description, 
                    "added_by_mesh_agent" => 'yes' #force a string 
                    };
                push @{$groupMembers}, $member_params;
            }
        }
        
        my $i = 0;
        foreach my $test (@{ $mesh->tests }) {
            unless ($test->parameters->type eq "perfsonarbuoy/bwctl" or $test->parameters->type eq "perfsonarbuoy/owamp") {
                $logger->debug("Skipping: ".$test->parameters->type);
                next;
            }

            if ($test->disabled) {
                $logger->debug("Skipping disabled test: ".$test->description);
                next;
            }
 
            $i++;

            my $grid_name = $dashboard->{name}." - ";
            if ($test->description) {
                $grid_name .= $test->description;
            }
            else {
                $grid_name .= "test".$i;
            }

            # Build the groups
            my $row_id;
            my @row_members = ();

            my $column_id;
            my @column_members = ();
            my $is_full_mesh = 0;
            
            my $columnAlgorithm = "all";
            if ($test->members->type eq "star") {
                $test->members->center_address = __normalize_addr($test->members->center_address);
                push @row_members, $test->members->center_address;
                foreach my $member (@{__normalize_addrs($test->members->members)}) {
                    push @column_members, $member unless $member eq $test->members->center_address;
                }

                $column_id = __generate_yaml_key($grid_name)."-column";
                $row_id = __generate_yaml_key($grid_name)."-row";
            }
            elsif ($test->members->type eq "disjoint") {
                foreach my $a_member (@{__normalize_addrs($test->members->a_members)}) {
                    push @row_members, $a_member;
                }
                foreach my $b_member (@{__normalize_addrs($test->members->b_members)}) {
                    push @column_members, $b_member;
                }
                $column_id = __generate_yaml_key($grid_name)."-column";
                $row_id = __generate_yaml_key($grid_name)."-row";
            
            }
            elsif ($test->members->type eq "ordered_mesh") {
                foreach my $member (@{__normalize_addrs($test->members->members)}) {
                    push @row_members, $member;
                    push @column_members, $member;
                }
                $row_id = $column_id = __generate_yaml_key($grid_name);
                $columnAlgorithm = "afterSelf";
            }
            else {
                # try to do it in a generic fashion. i.e. go through all the
                # source/dest pairs and add each source/dest to both the column and
                # the row. This should be, more or less, a mesh configuration.
                
                $is_full_mesh= 1;
                my %tmp_members = ();

                foreach my $pair (@{ $test->members->source_destination_pairs }) {
                    $tmp_members{$pair->{source}->{address}} = 1;
                    $tmp_members{$pair->{destination}->{address}} = 1;
                }

                @row_members = @column_members = keys %tmp_members;
                $row_id = $column_id = __generate_yaml_key($grid_name);
            }

            # build the 'exclude' maps to remove any pairs in the above that don't
            # actually form a test.
            my %forward_exclude_checks = ();
            my %reverse_exclude_checks = ();

            foreach my $row (@row_members) {
                $forward_exclude_checks{$row} = {};
                $reverse_exclude_checks{$row} = {};
                foreach my $column (@column_members) {
                    $forward_exclude_checks{$row}->{$column} = 1;
                    $reverse_exclude_checks{$row}->{$column} = 1;
                }
            }
            
            #remove port specifications from pairs
             foreach my $pair( @{ $test->members->source_destination_pairs }) {
                $pair->{source}->{address} = __normalize_addr($pair->{source}->{address});
                $pair->{destination}->{address} = __normalize_addr($pair->{destination}->{address});
            }
            
            foreach my $pair (@{ $test->members->source_destination_pairs }) {
                next if ($pair->{source}->{no_agent} and $pair->{destination}->{no_agent});
    
                delete($forward_exclude_checks{$pair->{source}->{address}}->{$pair->{destination}->{address}});
                if (scalar(keys %{ $forward_exclude_checks{$pair->{source}->{address}} }) == 0) {
                    delete($forward_exclude_checks{$pair->{source}->{address}});
                }

                delete($reverse_exclude_checks{$pair->{destination}->{address}}->{$pair->{source}->{address}});
                if (scalar(keys %{ $reverse_exclude_checks{$pair->{destination}->{address}} }) == 0) {
                    delete($reverse_exclude_checks{$pair->{destination}->{address}});
                }
            }

            # Convert the exclude check lists into the appropriate syntax
            foreach my $check_hash (\%forward_exclude_checks, \%reverse_exclude_checks) {
                foreach my $key (keys %$check_hash) {
                    my @values = keys %{ $check_hash->{$key} };
                    $check_hash->{$key} = \@values;
                }
            }

            # build the MA maps
            my %forward_ma_map = ();
            my %reverse_ma_map = ();

            my %row_hosts = map { $_ => 1 } @row_members;
            my %column_hosts = map { $_ => 1 } @column_members;

            foreach my $pair (@{ $test->members->source_destination_pairs }) {
                next if ($pair->{source}->{no_agent} and $pair->{destination}->{no_agent});

                my $tester = $pair->{source}->{no_agent}?$pair->{destination}->{address}:$pair->{source}->{address};

                my $hosts = $test->lookup_hosts({ addresses => [ $tester ] });
                my $ma;

                foreach my $host (@$hosts) {
                    $ma = $host->lookup_measurement_archive({ type => $test->parameters->type, recursive => 1 });
                    last if $ma;
                }

                unless ($ma) {
                    die("Couldn't find ma for host: ".$tester);
                }

                my $src_addr = $pair->{source}->{address};
                my $dst_addr = $pair->{destination}->{address};

                if ($row_hosts{$src_addr}) {
                    my $ma_url = $ma->read_url;

                    if ($tester eq $src_addr) {
                        $ma_url =~ s/$tester/\%row/g;
                    }
                    else {
                        $ma_url =~ s/$tester/\%col/g;
                    }

                    $forward_ma_map{$src_addr}->{$dst_addr} = $ma_url;
                }

                if ($column_hosts{$src_addr} and $row_hosts{$dst_addr}) {
                    my $ma_url = $ma->read_url;

                    if ($tester eq $src_addr) {
                        $ma_url =~ s/$tester/\%col/g;
                    }
                    else {
                        $ma_url =~ s/$tester/\%row/g;
                    }

                    $reverse_ma_map{$dst_addr}->{$src_addr} = $ma_url;
                }
            }

            # simplify the maps
            foreach my $map (\%forward_ma_map, \%reverse_ma_map) {
                __simplify_map($map);
            }


            # Add the groups
            if ($groups->{$row_id}) {
                die("Check ".$row_id." has been redefined");
            }
            elsif ($groups->{$column_id}) {
                die("Check ".$column_id." has been redefined");
            }

            $groups->{$row_id}    = \@row_members;
            $groups->{$column_id} = \@column_members;

            # Build the checks
            my $check = __build_check(grid_name => $grid_name, type => $test->parameters->type, ma_map => \%forward_ma_map, exclude_checks => \%forward_exclude_checks, direction => "forward", maddash_options => $maddash_options, is_full_mesh => $is_full_mesh);
            my $rev_check = __build_check(grid_name => $grid_name, type => $test->parameters->type, ma_map => \%reverse_ma_map, exclude_checks => \%reverse_exclude_checks, direction => "reverse", maddash_options => $maddash_options, is_full_mesh => $is_full_mesh);

            # Add the checks
            if ($checks->{$check->{id}}) {
                die("Check ".$check->{id}." has been redefined");
            }

            if ($checks->{$rev_check->{id}}) {
                die("Check ".$rev_check->{id}." has been redefined");
            }

            $checks->{$check->{id}}     = $check;
            $checks->{$rev_check->{id}} = $rev_check;

            # Build the grid
            my $grid = {};
            $grid->{name}            = $grid_name;
            $grid->{rows}            = $row_id;
            $grid->{columns}         = $column_id;
            $grid->{rowOrder}        = "alphabetical";
            $grid->{colOrder}        = "alphabetical";
            $grid->{excludeSelf}     = 1;
            $grid->{columnAlgorithm} = $columnAlgorithm;
            $grid->{checks}          = [ $check->{id}, $rev_check->{id} ];
            $grid->{statusLabels}    = {
                ok => $check->{ok_description},
                warning  => $check->{warning_description},
                critical => $check->{critical_description},
                unknown => "Unable to retrieve data",
                notrun => "Check has not yet run",
            };
            $grid->{added_by_mesh_agent} = 1;

            # Add the new grid
            foreach my $existing_grid (@$grids) {
                die("Grid ".$grid->{name}." has been redefined") if ($existing_grid->{name} eq $grid->{name});
            }

            push @$grids, $grid;
            push @{ $dashboard->{grids} }, { name => $grid->{name} };
        }

        # Add the new dashboard
        foreach my $existing_dashboard (@$dashboards) {
            die("Mesh ".$dashboard->{name}." has been redefined") if ($existing_dashboard->{name} eq $dashboard->{name});
        }

        push @$dashboards, $dashboard;
    }

    my $ret = Dump($existing_maddash_yaml);
    $ret = __quote_ipv6_address(maddash_yaml => $ret);
    return encode('ascii', $ret);
}

sub __quote_ipv6_address {
    my $parameters = validate( @_, { maddash_yaml => 1 } );
    my $yaml = $parameters->{maddash_yaml};

    my $IPv4 = "((25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2})[.](25[0-5]|2[0-4][0-9]|[0-1]?[0-9]{1,2}))";
    my $G = "[0-9a-fA-F]{1,4}";

    my @tail = ( ":",
	     "(:($G)?|$IPv4)",
             ":($IPv4|$G(:$G)?|)",
             "(:$IPv4|:$G(:$IPv4|(:$G){0,2})|:)",
	     "((:$G){0,2}(:$IPv4|(:$G){1,2})|:)",
	     "((:$G){0,3}(:$IPv4|(:$G){1,2})|:)",
	     "((:$G){0,4}(:$IPv4|(:$G){1,2})|:)" );


    my $IPv6_re = $G;
    $IPv6_re = "$G:($IPv6_re|$_)" for @tail;
    $IPv6_re = qq/:(:$G){0,5}((:$G){1,2}|:$IPv4)|$IPv6_re/;
    $IPv6_re =~ s/\(/(?:/g;
    $IPv6_re = qr/$IPv6_re/;

    $yaml =~ s/($IPv6_re)/\'$1\'/gm;
    $yaml =~ s/\'\'/\'/gm;
    return $yaml; 
}

my %maddash_default_check_options = (
    "perfsonarbuoy/owamp" => {
        check_command => "/opt/perfsonar_ps/nagios/bin/check_owdelay.pl",
        check_interval => 1800,
        check_time_range => 900,
        acceptable_loss_rate => 0,
        critical_loss_rate => 0.01,
    },
    "perfsonarbuoy/bwctl" => {
        check_command => "/opt/perfsonar_ps/nagios/bin/check_throughput.pl",
        check_interval => 28800,
        check_time_range => 86400,
        acceptable_throughput => 900,
        critical_throughput => 500,
    },
);

sub __build_check {
    my $parameters = validate( @_, { grid_name => 1, type => 1, ma_map => 1, exclude_checks => 1, direction => 1, maddash_options => 1, is_full_mesh => 1 } );
    my $grid_name = $parameters->{grid_name};
    my $type  = $parameters->{type};
    my $ma_map = $parameters->{ma_map};
    my $exclude_checks = $parameters->{exclude_checks};
    my $direction = $parameters->{direction};
    my $maddash_options = $parameters->{maddash_options};
    my $is_full_mesh = $parameters->{is_full_mesh};
    
    my $check = {};
    $check->{type} = "net.es.maddash.checks.PSNagiosCheck";
    $check->{retryInterval}   = 600;
    $check->{retryAttempts}   = 3;
    $check->{timeout}         = 60;
    $check->{excludeChecks}   = $exclude_checks;
    $check->{params}          = {};
    $check->{params}->{maUrl} = $ma_map;
    $check->{checkInterval}   = __get_check_option({ option => "check_interval", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });

    my $nagios_cmd    = __get_check_option({ option => "check_command", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });
    my $check_time_range = __get_check_option({ option => "check_time_range", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });

    my $host = $maddash_options->{external_address};
    $host = "localhost" unless $host;

    if ($type eq "perfsonarbuoy/bwctl") {
        my $ok_throughput = __get_check_option({ option => "acceptable_throughput", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });
        my $critical_throughput = __get_check_option({ option => "critical_throughput", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });
        $check->{ok_description} = "Throughput >= ".$ok_throughput."Mbps";
        $check->{warning_description} = "Throughput < ".$ok_throughput."Mbps";
        $check->{critical_description} = "Throughput <= ".$critical_throughput."Mbps";
        $check->{params}->{graphUrl} = 'http://'.$host.'/serviceTest/bandwidthGraph.cgi?url=%maUrl&dst=%col&src=%row&length=2592000';

        # convert to Gbps used in the nagios plugin
        $ok_throughput       /= 1000;
        $critical_throughput /= 1000; 

        if($is_full_mesh && $direction eq "reverse") {
            $check->{name} = 'Throughput Alternate MA';
            $check->{description} = 'Throughput from %row to %col';
            $check->{params}->{command} =  $nagios_cmd.' -u %maUrl -w '.$ok_throughput.': -c '.$critical_throughput.': -r '.$check_time_range.' -s %row -d %col';
        }
        elsif ($direction eq "reverse") {
            $check->{name} = 'Throughput Reverse';
            $check->{description} = 'Throughput from %col to %row';
            $check->{params}->{command} =  $nagios_cmd.' -u %maUrl -w '.$ok_throughput.': -c '.$critical_throughput.': -r '.$check_time_range.' -s %col -d %row';
        }
        else {
            $check->{name} = 'Throughput';
            $check->{description} = 'Throughput from %row to %col';
            $check->{params}->{command} =  $nagios_cmd.' -u %maUrl -w '.$ok_throughput.': -c '.$critical_throughput.': -r '.$check_time_range.' -s %row -d %col';
        }
    }
    else {
        my $ok_loss = __get_check_option({ option => "acceptable_loss_rate", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });
        my $critical_loss = __get_check_option({ option => "critical_loss_rate", test_type => $type, grid_name => $grid_name, maddash_options => $maddash_options });

        $check->{ok_description}  = "Loss rate is <= ".$ok_loss;
        $check->{warning_description}  = "Loss rate is >= ".$ok_loss;
        $check->{critical_description}  = "Loss rate is >= ".$critical_loss;

        $check->{params}->{graphUrl} = 'http://'.$host.'/serviceTest/delayGraph.cgi?url=%maUrl&dst=%col&src=%row&length=14400';
        if ($is_full_mesh && $direction eq "reverse") {
           $check->{name} = 'Loss Alternate MA';
           $check->{description} = 'Loss from %row to %col';
           $check->{params}->{command} =  $nagios_cmd.' -u %maUrl -w '.$ok_loss.' -c '.$critical_loss.' -r '.$check_time_range.' -l -p -s %row -d %col';
        }
        elsif ($direction eq "reverse") {
            $check->{name} = 'Loss Reverse';
            $check->{description} = 'Loss from %col to %row';
            $check->{params}->{command} =  $nagios_cmd.' -u %maUrl -w '.$ok_loss.' -c '.$critical_loss.' -r '.$check_time_range.' -l -p -s %col -d %row';
        }
        else {
            $check->{name} = 'Loss';
            $check->{description} = 'Loss from %row to %col';
            $check->{params}->{command} =  $nagios_cmd.' -u %maUrl -w '.$ok_loss.' -c '.$critical_loss.' -r '.$check_time_range.' -l -p -s %row -d %col';
        }
    }

    $check->{id} = __generate_yaml_key($grid_name." - ".$check->{name});

    return $check;
}

sub __get_check_option {
    my $parameters = validate( @_, { option => 1, test_type => 1, grid_name => 1, maddash_options => 1 } );
    my $option = $parameters->{option};
    my $test_type  = $parameters->{test_type};
    my $maddash_options = $parameters->{maddash_options};
    my $grid_name = $parameters->{grid_name};
    
    #find check parameters that match grid
    my $check_description = {};
    if (ref $maddash_options->{$test_type} eq 'ARRAY' ){
        foreach my $maddash_opt_check(@{$maddash_options->{$test_type}}){
            my %grid_name_map = ();
            if(!$maddash_opt_check->{grid_name}){
                #default definition if no grid_name
                $check_description = $maddash_opt_check;
                next;
            }elsif(ref $maddash_opt_check->{grid_name} eq 'ARRAY'){
                #grid_name list provided
                %grid_name_map = map { $_ => 1 } @{ $maddash_opt_check->{grid_name} };
            }else{
                #just one grid_name provided
                $grid_name_map{$maddash_opt_check->{grid_name}} = 1;
            }
            
            #we have a list of grids, check if any match
            if($grid_name_map{$grid_name}){
                $check_description = $maddash_opt_check;
                last;
            }
        }
    }else{
        $check_description = $maddash_options->{$test_type};
    }
    
    if (defined  $check_description->{$option}) {
        return $check_description->{$option};
    }

    return $maddash_default_check_options{$test_type}->{$option};
}
 
sub __generate_yaml_key {
  my ($name) = @_;

  $name =~ s/[^a-zA-Z0-9_\-.]/_/g;

  return $name;
}

sub __simplify_map {
    my ($map) = @_;

    my %all_ma_url_counts = ();

    foreach my $row (keys %$map) {
        my %row_ma_url_counts = ();

        foreach my $column (keys %{ $map->{$row} }) {
            my $ma_url = $map->{$row}->{$column};

            $row_ma_url_counts{$ma_url} = 0 unless $row_ma_url_counts{$ma_url};
            $row_ma_url_counts{$ma_url}++;

            $all_ma_url_counts{$ma_url} = 0 unless $all_ma_url_counts{$ma_url};
            $all_ma_url_counts{$ma_url}++;
        }

        my $maximum_url;
        my $maximum_count = 0;

        foreach my $url (keys %row_ma_url_counts) {
            if ($row_ma_url_counts{$url} > $maximum_count) {
                $maximum_url   = $url;
                $maximum_count = $row_ma_url_counts{$url};
            }
        }

        foreach my $column (keys %{ $map->{$row} }) {
            if ($map->{$row}->{$column} eq $maximum_url) {
                delete($map->{$row}->{$column});
            }
        }

        $map->{$row}->{default} = $maximum_url;
    }

    return;
}

sub __normalize_addr {
    my ($address) = @_;
    
    #strip port specification
    $address =~ s/\[//g; #remove starting square bracket
    $address =~ s/\](:\d+)?//g; #remove closing square bracket and optional port
    $address =~ s/^([^:]+):\d+$/$1/g; #remove port if no brackets and not IPv6
    
    return $address;            
}

sub __normalize_addrs {
    my ($addresses) = @_;
    
    for(my $i = 0; $i < @{$addresses}; $i++){
        $addresses->[$i] = __normalize_addr($addresses->[$i]);
    }
    
    return $addresses;            
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

$Id: Base.pm 3658 2009-08-28 11:40:19Z aaron $

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu

=head1 LICENSE

You should have received a copy of the Internet2 Intellectual Property Framework
along with this software.  If not, see
<http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT

Copyright (c) 2004-2009, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
