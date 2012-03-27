package perfSONAR_PS::XML::Document;

use strict;
use warnings;

our $VERSION = 3.2;

use fields 'OPEN_TAGS', 'DEFINED_PREFIXES', 'FH', 'LOGGER', 'NETLOGGER';

=head1 NAME

perfSONAR_PS::XML::Document

=head1 DESCRIPTION

This module is used to provide a more abstract method for constructing XML
documents that can be implemented using file construction, outputting to a file
or even DOM construction without tying the code creating the XML to any
particular construction method..

=cut

use Log::Log4perl qw(get_logger :nowarn);
use Params::Validate qw(:all);
use perfSONAR_PS::Utils::ParameterValidation;
use English qw( -no_match_vars );
use IO::File;
use perfSONAR_PS::Utils::NetLogger;
#use Devel::Size qw(size total_size);

my $pretty_print = 0;

=head2 new ($package)

Allocate a new XML Document

=cut

sub new {
    my ( $package ) = @_;
    my $self = fields::new( $package );

    $self->{LOGGER} = get_logger( "perfSONAR_PS::XML::Document" );
    $self->{NETLOGGER} = get_logger( "NetLogger" );
    $self->{OPEN_TAGS}        = ();
    $self->{DEFINED_PREFIXES} = ();
    $self->{FH}               = ();
    return $self;
}

=head2 getNormalizedURI ($uri)

This function ensures the URI has no whitespace and ends in a '/'.

=cut

sub getNormalizedURI {
    my ( $uri ) = @_;

    # trim whitespace
    $uri =~ s/^\s+//;
    $uri =~ s/\s+$//;

    if ( $uri =~ /[^\/]$/ ) {
        $uri .= "/";
    }
    return $uri;
}

=head2 startElement ($self, { prefix, namespace, tag, attributes, extra_namespaces, content })

This function starts a new element 'tag' with the prefix 'prefix' and
namespace 'namespace'. Those elements are the only ones that are required.
The attributes parameter can point at a hash whose keys will become
attributes of the element with the value of the attribute being the value
corresponding to that key in the hash. The extra_namespaces parameter can
be specified to add namespace declarations to this element. The keys of the
hash will be the new prefixes and the values those keys point to will be
the new namespace URIs. The content parameter can be specified to give the
content of the element in which case more elements can still be added, but
initally the content will be added. Once started, the element must be
closed before the document can be retrieved. This function returns -1 if an
error occurs and 0 if the element was successfully created.

=cut

sub startElement {

    #my ($self, @params) = shift;
    my $self = shift;
    my $args = validateParams(
        @_,
        {
            prefix           => { type => SCALAR,          regex    => qr/^[a-z0-9]/ },
            namespace        => { type => SCALAR,          regex    => qr/^http/ },
            tag              => { type => SCALAR,          regex    => qr/^[a-zA-Z0-9]/ },
            attributes       => { type => HASHREF | UNDEF, optional => 1 },
            extra_namespaces => { type => HASHREF | UNDEF, optional => 1 },
            content          => { type => SCALAR | UNDEF,  optional => 1 }
        }
    );

    my $prefix           = $args->{"prefix"};
    my $namespace        = $args->{"namespace"};
    my $tag              = $args->{"tag"};
    my $attributes       = $args->{"attributes"};
    my $extra_namespaces = $args->{"extra_namespaces"};
    my $content          = $args->{"content"};
	
	
	my $constructedTag = "";
    
    $self->{LOGGER}->debug( "Starting tag: $tag" );
    #my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.XML.startElement.start" );
    #$self->{NETLOGGER}->debug( $nlmsg );
    #my  $nlmsg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.XML.Document.startElement.start");
    #$self->{NETLOGGER}->debug( $nlmsg );

    $namespace = getNormalizedURI( $namespace );

    my %namespaces = ();
    $namespaces{$prefix} = $namespace;

    if ( defined $extra_namespaces and $extra_namespaces ) {
        foreach my $curr_prefix ( keys %{$extra_namespaces} ) {
            my $new_namespace = getNormalizedURI( $extra_namespaces->{$curr_prefix} );
            next if $new_namespace =~ m/http:\/\/schemas\.xmlsoap\.org\/soap\/envelope/;
            if ( defined $namespaces{$curr_prefix} and $namespaces{$curr_prefix} ne $new_namespace ) {
                $self->{LOGGER}->error( "Tried to redefine prefix $curr_prefix from " . $namespaces{$curr_prefix} . " to " . $new_namespace );
                return -1;
            }

            $namespaces{$curr_prefix} = $new_namespace;
        }
    }

    my %node_info = ();
    $node_info{"tag"}              = $tag;
    $node_info{"prefix"}           = $prefix;
    $node_info{"namespace"}        = $namespace;
    $node_info{"defined_prefixes"} = ();

    if ( $pretty_print ) {
        foreach my $node ( @{ $self->{OPEN_TAGS} } ) {
            #print { $self->{FH} } "  ";
            $constructedTag .= "  ";
        }
    }

    #print { $self->{FH} } "<$prefix:$tag";
    $constructedTag .= "<$prefix:$tag";

    foreach my $prefix ( keys %namespaces ) {
        my $require_defintion = 0;

        if ( not defined $self->{DEFINED_PREFIXES}->{$prefix} ) {

            # it's the first time we've seen a prefix like this
            $self->{DEFINED_PREFIXES}->{$prefix} = ();
            push @{ $self->{DEFINED_PREFIXES}->{$prefix} }, $namespaces{$prefix};
            $require_defintion = 1;
        }
        else {
            my @namespaces = @{ $self->{DEFINED_PREFIXES}->{$prefix} };

            # if it's a new namespace for an existing prefix, write the definition (though we should probably complain)
            if ( $#namespaces == -1 or $namespaces[-1] ne $namespace ) {
                push @{ $self->{DEFINED_PREFIXES}->{$prefix} }, $namespaces{$prefix};

                $require_defintion = 1;
            }
        }

        if ( $require_defintion ) {
            push @{ $node_info{"defined_prefixes"} }, $prefix;
            #print { $self->{FH} } " xmlns:$prefix=\"" . $namespaces{$prefix} . "\"";
        	$constructedTag .= " xmlns:$prefix=\"" . $namespaces{$prefix} . "\"";
        }
    }

    if ( defined $attributes ) {
        for my $attr ( keys %{$attributes} ) {
            #print { $self->{FH} } " " . $attr . "=\"" . $attributes->{$attr} . "\"";
            $constructedTag .= " " . $attr . "=\"" . $attributes->{$attr} . "\"";
        }
    }

    #print { $self->{FH} } ">";
    $constructedTag .= ">";

    if ( $pretty_print ) {
        #print { $self->{FH} } "\n";
        $constructedTag .= "\n";
    }

    if ( defined $content and $content ) {
        #print { $self->{FH} } $content;
        #print { $self->{FH} } "\n" if ( $pretty_print );
        $constructedTag .= $content;
        
        if ( $pretty_print ){
        	$constructedTag .= "\n";
        }
        
    }
	
	push @{$self->{FH}}, $constructedTag;
    push @{ $self->{OPEN_TAGS} }, \%node_info;
    
    #$nlmsg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.XML.Document.startElement.end");
    #$self->{NETLOGGER}->debug( $nlmsg );

    return 0;
}

=head2 createElement ($self, { prefix, namespace, tag, attributes, extra_namespaces, content })

This function has identical parameters to the startElement function.
However, it closes the element immediately. This function returns -1 if an
error occurs and 0 if the element was successfully created.

=cut

sub createElement {
    my $self = shift;
    my $args = validateParams(
        @_,
        {
            prefix           => { type => SCALAR,          regex    => qr/^[a-z0-9]/ },
            namespace        => { type => SCALAR,          regex    => qr/^http/ },
            tag              => { type => SCALAR,          regex    => qr/^[a-zA-Z0-9]/ },
            attributes       => { type => HASHREF | UNDEF, optional => 1 },
            extra_namespaces => { type => HASHREF | UNDEF, optional => 1 },
            content          => { type => SCALAR | UNDEF,  optional => 1 }
        }
    );
   #my $nlmsg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.XML.Document.createElement.start");
   #$self->{NETLOGGER}->debug( $nlmsg );


    my $prefix           = $args->{"prefix"};
    my $namespace        = $args->{"namespace"};
    my $tag              = $args->{"tag"};
    my $attributes       = $args->{"attributes"};
    my $extra_namespaces = $args->{"extra_namespaces"};
    my $content          = $args->{"content"};

    #	$namespace = getNormalizedURI($namespace);
    my $constructedTag ="";

    my %namespaces = ();
    $namespaces{$prefix} = $namespace;

    if ( defined $extra_namespaces and $extra_namespaces ) {
        foreach my $curr_prefix ( keys %{$extra_namespaces} ) {
            my $new_namespace = getNormalizedURI( $extra_namespaces->{$curr_prefix} );

            if ( defined $namespaces{$curr_prefix} and $namespaces{$curr_prefix} ne $new_namespace ) {
                $self->{LOGGER}->error( "Tried to redefine prefix $curr_prefix from " . $namespaces{$curr_prefix} . " to " . $new_namespace );
                return -1;
            }

            $namespaces{$curr_prefix} = $new_namespace;
        }
    }

    my $output = q{};

    if ( $pretty_print ) {
        foreach my $node ( @{ $self->{OPEN_TAGS} } ) {
            #print { $self->{FH} } "  ";
            $constructedTag .= "  ";
        }
    }

    #print { $self->{FH} } "<$prefix:$tag";
    $constructedTag .= "<$prefix:$tag";

    foreach my $prefix ( keys %namespaces ) {
        my $require_defintion = 0;

        if ( not defined $self->{DEFINED_PREFIXES}->{$prefix} ) {

            # it's the first time we've seen a prefix like this
            $self->{DEFINED_PREFIXES}->{$prefix} = ();
            $require_defintion = 1;
        }
        else {
            my @namespaces = @{ $self->{DEFINED_PREFIXES}->{$prefix} };

            # if it's a new namespace for an existing prefix, write the definition (though we should probably complain)
            if ( $#namespaces == -1 or $namespaces[-1] ne $namespace ) {
                $require_defintion = 1;
            }
        }

        if ( $require_defintion ) {
            #print { $self->{FH} } " xmlns:$prefix=\"" . $namespaces{$prefix} . "\"";
            $constructedTag .= " xmlns:$prefix=\"" . $namespaces{$prefix} . "\"";
        }
    }

    if ( defined $attributes ) {
        for my $attr ( keys %{$attributes} ) {
            #print { $self->{FH} } " " . $attr . "=\"" . $attributes->{$attr} . "\"";
            $constructedTag .= " " . $attr . "=\"" . $attributes->{$attr} . "\"";
        }
    }

    if ( not defined $content or $content eq q{} ) {
        #print { $self->{FH} } " />";
        $constructedTag .= " />";
    }
    else {
        #print { $self->{FH} } ">";
        $constructedTag .= ">";

        if ( $pretty_print ) {
            #print { $self->{FH} } "\n" if ( $content =~ /\n/ );
            if ( $content =~ /\n/ ){
            	$constructedTag .= "\n";
            }
            
        }

        #print { $self->{FH} } $content;
        $constructedTag .= $content;

        if ( $pretty_print ) {
            if ( $content =~ /\n/ ) {
                #print { $self->{FH} } "\n";
                $constructedTag .= "\n";
                foreach my $node ( @{ $self->{OPEN_TAGS} } ) {
                    #print { $self->{FH} } "  ";
                    $constructedTag .= "  ";
                }
            }
        }

        #print { $self->{FH} } "</" . $prefix . ":" . $tag . ">";
        $constructedTag .= "</" . $prefix . ":" . $tag . ">";
    }

    if ( $pretty_print ) {
        #print { $self->{FH} } "\n";
        $constructedTag .= "\n";
    }

    #print { $self->{FH} } $output if $output;
    
    if($output){
    	$constructedTag .= $output;
    }
    
    push @{$self->{FH}}, $constructedTag;
    #$nlmsg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.XML.Document.createElement.end");
    #$self->{NETLOGGER}->debug( $nlmsg );
    return 0;
}

sub fastCreateElement{
	my $self = shift;
    my $args = validateParams(
        @_,
        {
            prefix           => { type => SCALAR,          regex    => qr/^[a-z0-9]/ },
            tag              => { type => SCALAR,          regex    => qr/^[a-zA-Z0-9]/ },
            attributes       => { type => HASHREF | UNDEF, optional => 1 },
            content          => { type => SCALAR | UNDEF,  optional => 1 }
        }
    );
    
    my $prefix           = $args->{"prefix"};
    my $tag              = $args->{"tag"};
    my $attributes       = $args->{"attributes"};
    my $content          = $args->{"content"};
    
    my $constructedTag="<$prefix:$tag";
    if ( defined $attributes ) {
        for my $attr ( keys %{$attributes} ) {
            #print { $self->{FH} } " " . $attr . "=\"" . $attributes->{$attr} . "\"";
            $constructedTag .= " " . $attr . "=\"" . $attributes->{$attr} . "\"";
        }
    }
    
    if(defined $content){
    	$constructedTag .= ">";
    	$constructedTag .= $content;
    	$constructedTag .= "</" . $prefix . ":" . $tag . ">";
    }else{
    	$constructedTag .= " />";
    }
    push @{$self->{FH}}, $constructedTag;
    return 0;
}

=head2 endElement ($self, $tag)

This function is used to end the most recently opened element. The tag
being closed is specified to sanity check the output. If the element is
properly closed, 0 is returned. -1 otherwise.

=cut

sub endElement {
    my ( $self, $tag ) = @_;

    $self->{LOGGER}->debug( "Ending tag: $tag" );
     #my $nlmsg = perfSONAR_PS::Utils::NetLogger::format( "org.perfSONAR.XML.Document.endElement.start");
    #$self->{NETLOGGER}->debug( $nlmsg );

    my @tags = @{ $self->{OPEN_TAGS} };
    
    my $constructedTag ="";

    if ( $#tags == -1 ) {
        $self->{LOGGER}->error( "Tried to close tag $tag but no current open tags" );
        return -1;
    }
    elsif ( $tags[-1]->{"tag"} ne $tag ) {
        $self->{LOGGER}->error( "Tried to close tag $tag, but current open tag is \"" . $tags[-1]->{"tag"} . "\n" );
        return -1;
    }

    foreach my $prefix ( @{ $tags[-1]->{"defined_prefixes"} } ) {
        pop @{ $self->{DEFINED_PREFIXES}->{$prefix} };
    }

    pop @{ $self->{OPEN_TAGS} };

    if ( $pretty_print ) {
        foreach my $node ( @{ $self->{OPEN_TAGS} } ) {
            #print { $self->{FH} } "  ";
            $constructedTag .= "  ";
        }
    }

    #print { $self->{FH} } "</" . $tags[-1]->{"prefix"} . ":" . $tag . ">";
    $constructedTag .= "</" . $tags[-1]->{"prefix"} . ":" . $tag . ">";

    if ( $pretty_print ) {
        #print { $self->{FH} } "\n";
        $constructedTag .= "\n";
    }
    
    push @{$self->{FH}}, $constructedTag;


    #$nlmsg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.XML.Document.endElement.end");
    #$self->{NETLOGGER}->debug( $nlmsg );

    
    return 0;
}

=head2 addExistingXMLElement ($self, $element)

This function adds a LibXML element to the current document.

=cut

sub addExistingXMLElement {
    my ( $self, $element ) = @_;

    my $elm = $element->cloneNode( 1 );
    $elm->unbindNode();
	
	
    #print { $self->{FH} } $elm->toString();

	push @{$self->{FH}}, $elm->toString();;
    return 0;
}

=head2 addOpaque ($self, $element)

This function adds arbitrary data to the current document.

=cut

sub addOpaque {
    my ( $self, $data ) = @_;

    #print { $self->{FH} } $data;
    
    push @{$self->{FH}}, $data;

    return 0;
}

=head2 getValue ($self)

This function returns the current state of the document. It will warn if there
are open tags still.

=cut

sub getValue {
    my ( $self ) = @_;

    if ( defined $self->{OPEN_TAGS} ) {
        my @open_tags = @{ $self->{OPEN_TAGS} };

        if ( scalar( @open_tags ) != 0 ) {
            my $msg = "Open tags still exist: ";

            for ( my $x = $#open_tags; $x >= 0; $x-- ) {
                $msg .= " -> " . $open_tags[$x];
            }

            $self->{LOGGER}->warn( $msg );
        }
    }

    my $value;
    #seek( $self->{FH}, 0, 0 );
    #$value = do { local ( $INPUT_RECORD_SEPARATOR ); my $file = $self->{FH}; <$file> };
    #seek( $self->{FH}, 0, 2 );
    $value = join("", @{$self->{FH}});
    $self->{LOGGER}->debug( "Construction Results: " . $value ) if $value;
#    my $xmlbytes = total_size($value); 
#    my $xmlsize = scalar @{$self->{FH}};
#    my $nlmsg = perfSONAR_PS::Utils::NetLogger::format("org.perfSONAR.XML.Document.getValue.start Tags=$xmlsize, Bytes=$xmlbytes");
#    $self->{NETLOGGER}->debug( $nlmsg );
    return $value;
}

1;

__END__

=head1 SEE ALSO

L<Log::Log4perl>, L<Params::Validate>, L<perfSONAR_PS::Utils::ParameterValidation>,
L<English>, L<IO::File>

To join the 'perfSONAR-PS Users' mailing list, please visit:

  https://lists.internet2.edu/sympa/info/perfsonar-ps-users

The perfSONAR-PS subversion repository is located at:

  http://anonsvn.internet2.edu/svn/perfSONAR-PS/trunk

Questions and comments can be directed to the author, or the mailing list.
Bugs, feature requests, and improvements can be directed here:

  http://code.google.com/p/perfsonar-ps/issues/list

=head1 VERSION

$Id$

=head1 AUTHOR

Aaron Brown, aaron@internet2.edu
Jason Zurawski, zurawski@internet2.edu

=head1 LICENSE

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=head1 COPYRIGHT

Copyright (c) 2004-2010, Internet2 and the University of Delaware

All rights reserved.

=cut

# vim: expandtab shiftwidth=4 tabstop=4
