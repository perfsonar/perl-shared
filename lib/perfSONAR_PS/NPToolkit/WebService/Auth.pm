package perfSONAR_PS::NPToolkit::WebService::Auth;
use base 'Exporter';

use strict;
our @EXPORT_OK = ( 'is_authenticated', 'unauthorized_output' );

sub is_authenticated {
    my $cgi = shift;
    my $authenticated = 0;
    return if (! defined $cgi);
    if( defined $cgi->auth_type() && $cgi->auth_type ne '' && defined $cgi->remote_user() ){
        $authenticated = 1;
    }
    return $authenticated;
}

sub unauthorized_output {
    my $cgi = shift;
    my $header = "";
    if ( !is_authenticated($cgi) ) {
        $header = $cgi->header(
            -type => "text/plain",
            -status => "401 Unauthorized",
        );
        $header .= "Unauthorized";
    }
    return $header;
}

1;
