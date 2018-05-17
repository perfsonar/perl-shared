package perfSONAR_PS::NPToolkit::Services::ServicesMap;

use strict;
use warnings;

use base 'Exporter';

use Params::Validate qw(:all);

use perfSONAR_PS::NPToolkit::Services::Cassandra;
use perfSONAR_PS::NPToolkit::Services::ConfigDaemon;
use perfSONAR_PS::NPToolkit::Services::esmond;
use perfSONAR_PS::NPToolkit::Services::httpd;
use perfSONAR_PS::NPToolkit::Services::LSCacheDaemon;
use perfSONAR_PS::NPToolkit::Services::LSRegistrationDaemon;
use perfSONAR_PS::NPToolkit::Services::MaDDash;
use perfSONAR_PS::NPToolkit::Services::PSConfigPSchedulerAgent;
use perfSONAR_PS::NPToolkit::Services::PScheduler;
use perfSONAR_PS::NPToolkit::Services::NTP;
use perfSONAR_PS::NPToolkit::Services::OWAMP;
use perfSONAR_PS::NPToolkit::Services::YumCron;
use perfSONAR_PS::NPToolkit::Services::iperf3;

our @EXPORT_OK = qw( get_service_object get_service_name get_all_service_names );

my %name_to_service_map = (
    cassandra => "perfSONAR_PS::NPToolkit::Services::Cassandra",
    config_daemon => "perfSONAR_PS::NPToolkit::Services::ConfigDaemon",
    esmond => "perfSONAR_PS::NPToolkit::Services::esmond",
    httpd => "perfSONAR_PS::NPToolkit::Services::httpd",
    ls_cache_daemon => "perfSONAR_PS::NPToolkit::Services::LSCacheDaemon",
    lsregistration => "perfSONAR_PS::NPToolkit::Services::LSRegistrationDaemon",
    maddash => "perfSONAR_PS::NPToolkit::Services::MaDDash",
    ntp => "perfSONAR_PS::NPToolkit::Services::NTP",
    owamp => "perfSONAR_PS::NPToolkit::Services::OWAMP",
    psconfig => "perfSONAR_PS::NPToolkit::Services::PSConfigPSchedulerAgent",
    pscheduler => "perfSONAR_PS::NPToolkit::Services::PScheduler",
    yum_cron => "perfSONAR_PS::NPToolkit::Services::YumCron",
    iperf3 => "perfSONAR_PS::NPToolkit::Services::iperf3",
);

sub get_service_object {
    my ( $service_name ) = @_;

    my $class = $name_to_service_map{$service_name};

    return unless $class;

    my $object = $class->new();
    $object->init();

    return $object;
}

sub get_service_name {
    my ( $service_obj ) = @_;

    my $class = ref($service_obj);

    foreach my $name (keys %name_to_service_map) {
        if ($name_to_service_map{$name} eq $class) {
            return $name;
        }
    }

    return;
}

sub get_all_service_names {

    my @names = keys %name_to_service_map;

    return \@names;
}

1;
