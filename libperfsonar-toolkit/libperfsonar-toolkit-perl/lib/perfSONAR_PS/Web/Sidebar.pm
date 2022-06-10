package perfSONAR_PS::Web::Sidebar;

#our $VERSION = 3.4; # what to do here?

use strict;
use warnings;

use Time::HiRes qw( time );
use Params::Validate;
use Data::Dumper;

use RPM2;

use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;

use perfSONAR_PS::NPToolkit::Services::ServicesMap qw(get_service_object);

use Exporter qw(import);
our @EXPORT_OK = qw(set_sidebar_vars);

our ( $administrative_info_conf, $ntpinfo );

$administrative_info_conf = perfSONAR_PS::NPToolkit::Config::AdministrativeInfo->new();
$administrative_info_conf->init();
$ntpinfo = get_service_object("ntp");

sub set_sidebar_vars {

    my $parameters = validate( @_, { vars => 1 } );
    my $vars = $parameters->{vars};

    $vars->{remote_login} = $ENV{'REMOTE_USER'};

    $vars->{admin_info_nav_class} = "warning" unless $administrative_info_conf->is_complete();

    $vars->{ntp_nav_class} = "warning" unless $ntpinfo->is_synced();

    my $cacti_available;
    # TODO-debian: this will need a patch
    if (my $db = RPM2->open_rpm_db()) {
       my @packages = $db->find_by_name("cacti");
 
       $cacti_available = 1 if scalar(@packages) > 0;
    }

    $vars->{cacti_available} = $cacti_available;
  
    return $vars;

}

1;
