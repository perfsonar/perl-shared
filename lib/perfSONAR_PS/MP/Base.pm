#!/usr/bin/perl -w

package perfSONAR_PS::MP::Base;

use warnings;
use Exporter;
use Log::Log4perl qw(get_logger);

@ISA = ('Exporter');
@EXPORT = ();


sub new {
  my ($package, $conf, $ns, $store, $directory) = @_; 
  my %hash = ();
  if(defined $conf and $conf ne "") {
    $hash{"CONF"} = \%{$conf};
  }
  if(defined $ns and $ns ne "") {  
    $hash{"NAMESPACES"} = \%{$ns};     
  }    
  if(defined $store and $store ne "") {
    $hash{"STORE"} = $store;
  }
  else {
    $hash{"STORE"} = "";
  }  
  if (defined $directory and $directory ne "") {
    $hash{"DIRECTORY"} = $directory;
  }

  %{$hash{"METADATAMARKS"}} = ();
  %{$hash{"DATAMARKS"}} = ();
  %{$hash{"DATADB"}} = ();
  %{$hash{"LOOKUP"}} = ();
  %{$hash{"AGENT"}} = ();
      
  bless \%hash => $package;
}


sub setConf {
  my ($self, $conf) = @_;  
  my $logger = get_logger("perfSONAR_PS::MP::Base");
  if(defined $conf and $conf ne "") {
    $self->{CONF} = \%{$conf};
  }
  else {
    $logger->error("Missing argument."); 
  }
  return;
}


sub setNamespaces {
  my ($self, $ns) = @_;  
  my $logger = get_logger("perfSONAR_PS::MP::Base");
  if(defined $namespaces and $namespaces ne "") {   
    $self->{NAMESPACES} = \%{$ns};
  }
  else {
    $logger->error("Missing argument.");   
  }
  return;
}


sub setStore {
  my ($self, $store) = @_;  
  my $logger = get_logger("perfSONAR_PS::MP::Base");
  if(defined $store and $store ne "") {
    $self->{STORE} = $store;
  }
  else {
    $logger->error("Missing argument."); 
  }
  return;
}


1;


__END__


=head1 NAME

perfSONAR_PS::MP::Base - A module that provides basic methods for MP services.

=head1 DESCRIPTION

The purpose of this module is to create simple objects that contain all necessary information
to create other MP based objects.  

=head1 SYNOPSIS

    use perfSONAR_PS::MP::Base;
    
    my %conf = ();
    $conf{"METADATA_DB_TYPE"} = "xmldb";
    $conf{"METADATA_DB_NAME"} = "/home/jason/perfSONAR-PS/MP/SNMP/xmldb";
    $conf{"METADATA_DB_FILE"} = "snmpstore.dbxml";
    
    my %ns = (
      nmwg => "http://ggf.org/ns/nmwg/base/2.0/",
      netutil => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
      nmwgt => "http://ggf.org/ns/nmwg/topology/2.0/",
      snmp => "http://ggf.org/ns/nmwg/tools/snmp/2.0/"    
    );
    
    my $mp = new perfSONAR_PS::MP::Base(\%conf, \%ns, "", "");

    # or 
    # my $mp = new perfSONAR_PS::MP::Base;
    # $mp->setConf(\%conf);
    # $mp->setNamespaces(\%ns);
    # $mp->setStore($store);
            
=head1 DETAILS

This API is a work in progress, but is starting to capture the basics of an MP.

=head1 API

The offered API is simple, but offers the key functions we need in a measurement point. 

=head2 new(\%conf, \%ns, $store)

The first argument represents the 'conf' hash from the calling MP.  The second argument
is a hash of namespace values.  The final value is a XML::LibXML::Document that contains 
the values of the store file.

=head2 setConf(\%conf)

(Re-)Sets the value for the 'conf' hash.  

=head2 setNamespaces(\%ns)

(Re-)Sets the value for the 'namespace' hash. 

=head2 setStore($store) 

(Re-)Sets the value for the 'store' object, which is really just a XML::LibXML::Document. 

=head2 error($self, $msg, $line)	

A 'message' argument is used to print error information to the screen and log files 
(if present).  The 'line' argument can be attained through the __LINE__ compiler directive.  
Meant to be used internally.

=head1 SEE ALSO

L<XML::LibXML::Document>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id: Base.pm 524 2007-09-05 17:35:50Z aaron $

=head1 AUTHOR

Jason Zurawski, E<lt>zurawski@internet2.eduE<gt>

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
