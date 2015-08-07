package perfSONAR_PS::NPToolkit::DataService::Communities;

use fields qw(LOGGER config_file admin_info_conf config authenticated);

use strict;
use warnings;

use perfSONAR_PS::Client::gLS::Keywords;
use Log::Log4perl qw(get_logger :easy :levels);
use Params::Validate qw(:all);

use Data::Dumper;

use perfSONAR_PS::NPToolkit::Config::AdministrativeInfo;

sub new {
    my ( $class, @params ) = @_;

    my $self = fields::new( $class );

    $self->{LOGGER} = get_logger( $class );
    my $parameters = validate(
        @params,
        {
            config_file => 1
        }
    );
    $self->{config_file} = $parameters->{config_file};
    my $config = Config::General->new( -ConfigFile => $self->{config_file} );
    $self->{config} = { $config->getall() };
    my $administrative_info_conf = perfSONAR_PS::NPToolkit::Config::AdministrativeInfo->new();
    $administrative_info_conf->init( { administrative_info_file => $self->{config}->{administrative_info_file} } );
    $self->{admin_info_conf} = $administrative_info_conf;

    return $self;
}

sub get_host_communities {
    my $self = shift;

    my $communities = $self->{admin_info_conf}->get_keywords();

    return {communities => $communities};

}

sub get_all_communities {
    my $self = shift;

    my $keyword_client = perfSONAR_PS::Client::gLS::Keywords->new( { cache_directory => $self->{config}->{cache_directory} } );
    my ($status, $res) = $keyword_client->get_keywords();
    $self->{LOGGER}->debug("keyword status: $status");
    if ( $status == 0) {
        $self->{LOGGER}->debug("Got keywords: ".Dumper($res));
    }
    return $res;

}


1;

# vim: expandtab shiftwidth=4 tabstop=4