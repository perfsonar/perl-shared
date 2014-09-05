package perfSONAR_PS::Client::Esmond::Paginator;

use Mouse;
use POSIX;

has 'metadata' => (is => 'rw', isa => 'ArrayRef', default => sub { [] });
has 'filters' => (is => 'rw', isa => 'perfSONAR_PS::Client::Esmond::ApiFilters', default => sub { new perfSONAR_PS::Client::Esmond::ApiFilters(); });

sub last_page {
    my ($self) = @_;
     
    #if empty return nothing
    return undef if(@{$self->metadata} == 0);
    
    #get the total
    my $total = $self->metadata->[0]->metadata_count_total();
    return undef unless $total;
    
    #get the limit
    my $limit = $self->filters->limit();
    return undef unless $limit;
     
    return ceil($total/($limit+0.0));
}

sub current_page {
    my ($self) = @_;
    
    #get the limit
    my $limit = $self->filters->limit();
    return undef unless $limit;
     
    #get the offset
    my $offset = $self->filters->offset();
    return 1 unless defined $offset;
    
    return ceil(($offset+1)/$limit);
}

sub next_offset {
    my ($self) = @_;
    
    #get the total
    my $total = $self->metadata->[0]->metadata_count_total();
    return undef unless $total;
    
    #get the limit
    my $limit = $self->filters->limit();
    return undef unless $limit;
     
    #get the offset
    my $offset = $self->filters->offset() ? $self->filters->offset() : 0;
    
    #make sure there is a next page
    my $next = $offset+$limit;
    if($next > $total){
        return undef;
    }
    
    return $next;
}

sub prev_offset {
    my ($self) = @_;
    
    #get the limit
    my $limit = $self->filters->limit();
    return undef unless $limit;
     
    #get the offset
    my $offset = $self->filters->offset() ? $self->filters->offset() : 0;
    
    #make sure there is a next page
    my $prev = $offset-$limit;
    if($prev < 0){
        return undef;
    }
    
    return $prev;
}

sub page_offset {
    my ($self, $page) = @_;
    
    #get the total
    my $total = $self->metadata->[0]->metadata_count_total();
    return undef unless $total;
    
    #get the limit
    my $limit = $self->filters->limit();
    return undef unless $limit;
    
    my $offset = $limit  * ($page-1);
    if($offset >= $total){
        return undef;
    }
    
    return $offset;
}

__PACKAGE__->meta->make_immutable;

1;