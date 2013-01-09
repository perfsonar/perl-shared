package SimpleLookupService::Client::Bootstrap;

=head1 NAME

SimpleLookupService::Client::Bootstrap - Returns the lookup service to use for the client

=head1 DESCRIPTION

A class for determining the lookup service to use when registering. Looks in a local file
and get this url to use

=cut

use strict;
use warnings;

use Params::Validate qw( :all );

our $VERSION = 3.2;

use fields 'URL';


sub new {
    my $package = shift;
   
    my $self = fields::new( $package );
   
    return $self;
}

sub init  {
    my ( $self, @args ) = @_;
    my %parameters = validate( @args, { file => 0} );
    
    my $file = $parameters{file};
    if(!$file){
        #set default
        $file = '/opt/SimpleLS/bootstrap/etc/service_url';
    }
    
    $self->{URL} = '';
    if(open FILE, "< $file"){
        while(<FILE>){
            chomp $_;
            if($_){
                $self->{URL} = $_;
                last;
            }
        }
        close FILE;
    }
    
    return 0;
}

sub register_url {
     my ( $self ) = @_;
     
     return $self->{URL};
}