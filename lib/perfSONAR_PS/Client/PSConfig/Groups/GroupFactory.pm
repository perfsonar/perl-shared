package perfSONAR_PS::Client::PSConfig::Groups::GroupFactory;

use Mouse;

use perfSONAR_PS::Client::PSConfig::Groups::Disjoint;
use perfSONAR_PS::Client::PSConfig::Groups::Mesh;
use perfSONAR_PS::Client::PSConfig::Groups::List;

extends 'perfSONAR_PS::Client::PSConfig::BaseNode';

=item build()

Creates a group based on the 'type' field of the given HashRef

=cut

sub build {
    my ($self, $data) = @_;
    
    if($data && exists $data->{'type'}){
        if($data->{'type'} eq 'disjoint'){
            return new perfSONAR_PS::Client::PSConfig::Groups::Disjoint(data => $data);
        }elsif($data->{'type'} eq 'mesh'){
            return new perfSONAR_PS::Client::PSConfig::Groups::Mesh(data => $data);
        }elsif($data->{'type'} eq 'list'){
            return new perfSONAR_PS::Client::PSConfig::Groups::List(data => $data);
        }
    }
        
    return undef;
    
}

__PACKAGE__->meta->make_immutable;

1;