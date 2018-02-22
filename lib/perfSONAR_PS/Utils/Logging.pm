package perfSONAR_PS::Utils::Logging;

=head1 NAME

perfSONAR_PS::Utils::Logging - Utility to help with formatting log messages

=head1 DESCRIPTION

A client for reading in JQTransform files

=cut

use Mouse;
use Data::UUID;
use JSON qw( to_json );

our $VERSION = 4.1;

has 'log4perl_format' => (is => 'ro', isa => 'Str', default => sub{ { '%d %p pid=%P prog=%M line=%L %m%n' } });
has 'global_context' => (is => 'rw', isa => 'HashRef', default => sub{ {} });
has 'guid' => (is => 'rw', isa => 'Str');
has 'guid_label' => (is => 'rw', isa => 'Str', default => sub{ { 'guid' } });

sub format {
    my($self, $msg, $local_context) = @_;
    
    #init with guid
    my $m = $self->_append_guid();
    
    #set contexts
    $m .= $self->_append_contexts($local_context, $m);
    
    #add message
    chomp($msg);
    $m .= $self->_append_msg('msg', $msg, $m);
    
    return $m;
}

sub format_task {
    my($self, $task, $local_context) = @_;
    
    #init with guid
    my $m = $self->_append_guid();
    
    #set contexts
    $m .= $self->_append_contexts($local_context, $m);
    
    #add message
    $m .= $self->_append_msg('task', $task->json(), $m);
    
    return $m;
}

sub generate_guid {
    my($self) = @_;
    my $uuid = new Data::UUID;
    $self->guid($uuid->create_str());
}

sub _append_guid {
    my($self) = @_;
    
    my $m = "";
    $m .= $self->guid_label() . "=" . $self->guid() if($self->guid());
    
    return $m;
}

sub _append_contexts {
    my($self, $local_context, $msg) = @_;
    
    my $m = "";
    
    #add global context variables
    foreach my $ctx(keys %{$self->global_context()}){
        $m .= $self->_append_msg($ctx, $self->global_context()->{$ctx}, $m);
    }
    
    #add local context variables
    if($local_context){
        foreach my $ctx(keys %{$local_context}){
            $m .= $self->_append_msg($ctx, $local_context->{$ctx}, $m);
        }
    }
    
    #make sure there is a space if needed
    $m = " $m" if($m && $msg);
    
    return $m;
}
    
sub _append_msg {
    my($self, $k, $v, $msg) = @_;
    
    my $m;
    $m .= ' ' if($msg);
    my $val = $v;
    if(ref $val eq 'HASH' || ref $val eq 'ARRAY'){
        $val = to_json($val);
    }
    $m .= "$k=$val";
    
    return $m;
}


__PACKAGE__->meta->make_immutable;

1;