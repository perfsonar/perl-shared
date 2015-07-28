package perfSONAR_PS::NPToolkit::WebService::Auth;
use base 'Exporter';

use strict;
our @EXPORT_OK = ( 'is_authenticated'  );

sub is_authenticated {
    my $cgi = shift;
    my $authenticated = 0;
    return if (! defined $cgi);
    if( defined $cgi->auth_type() && $cgi->auth_type ne '' && defined $cgi->remote_user() ){
        $authenticated = 1;
    }
    return $authenticated;
}

1;
