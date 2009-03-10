#!/usr/bin/perl -w

package perfSONAR_PS::MP::General;

use warnings;
use Exporter;  
use Log::Log4perl qw(get_logger);

use perfSONAR_PS::Common;
use perfSONAR_PS::MP::Base;

@ISA = ('Exporter');
@EXPORT = ( 'cleanMetadata', 'cleanData', 'removeReferences', 'lookup', 
            'parseXMLDB', 'parseFile', 'parseString');


sub cleanMetadata {
  my($mp) = @_;  
  my $logger = get_logger("perfSONAR_PS::MP::General");

  if(defined $mp and $mp ne "") {
    $mp->{STORE} = chainMetadata($mp->{STORE}, $mp->{NAMESPACES}->{"nmwg"});
    foreach my $md ($mp->{STORE}->getElementsByTagNameNS($mp->{NAMESPACES}->{"nmwg"}, "metadata")) {
      my $count = countRefs($md->getAttribute("id"), $mp->{STORE}, $mp->{NAMESPACES}->{"nmwg"}, "data", "metadataIdRef");
      if($count == 0) {
        $logger->debug("Removing metadata \"".$md->getAttribute("id")."\" from the DOM.");
        $mp->{STORE}->getDocumentElement->removeChild($md);
      } 
      else {
        $mp->{METADATAMARKS}->{$md->getAttribute("id")} = $count;
      }
    }    
  }
  else {
    $logger->error("Missing argument.");
  }
  return;
}


sub cleanData {
  my($mp) = @_;
  my $logger = get_logger("perfSONAR_PS::MP::General");
  
  if(defined $mp and $mp ne "") {
    foreach my $d ($mp->{STORE}->getElementsByTagNameNS($mp->{NAMESPACES}->{"nmwg"}, "data")) {
      my $count = countRefs($d->getAttribute("metadataIdRef"), $mp->{STORE}, $mp->{NAMESPACES}->{"nmwg"}, "metadata", "id");
      if($count == 0) {
        $logger->debug("Removing data \"".$d->getAttribute("id")."\" from the DOM.");
        $mp->{STORE}->getDocumentElement->removeChild($d);
      } 
      else {
        $mp->{DATAMARKS}->{$d->getAttribute("id")} = $count;
      }         
    }
  }
  else {
    $logger->error("Missing argument.");
  }
  return;
}


sub lookup {
  my($mp, $uri, $default) = @_;
  my $logger = get_logger("perfSONAR_PS::MP::General");
  
  if((defined $mp and $mp ne "") and 
     (defined $uri and $uri ne "") and 
     (defined $default and $default ne "")) {
    my $prefix = "";
    foreach my $n (keys %{$mp->{NAMESPACES}}) {
      if($uri eq $mp->{NAMESPACES}->{$n}) {
        $prefix = $n;
        last;
      }
    }
    $prefix = $default if($prefix eq "");
    $logger->debug("Found prefix \"".$prefix."\".");
    return $prefix;
  }
  else {
    $logger->error("Missing argument(s).");  
  }
  return "";
}


sub removeReferences {
  my($mp, $id, $did) = @_;
  my $logger = get_logger("perfSONAR_PS::MP::General");    
    
  if((defined $mp and $mp ne "") and
     (defined $id and $id ne "") and 
     (defined $did and $did ne "")) {
     
    $mp->{DATAMARKS}->{$did}--;
    $mp->{METADATAMARKS}->{$id}--;
    foreach my $dm (sort keys %{$mp->{DATAMARKS}}) {
      if($mp->{DATAMARKS}->{$dm} == 0) {
        delete $mp->{DATAMARKS}->{$dm};
        my $rmD = find($mp->{STORE}, "//nmwg:data[\@id=\"".$dm."\"]", 1);
        $logger->debug("Removing data child \"".$dm."\" from the DOM.");
        $mp->{STORE}->getDocumentElement->removeChild($rmD);   
      }
    }
    
    foreach my $mm (sort keys %{$mp->{METADATAMARKS}}) {
      if($mp->{METADATAMARKS}->{$mm} == 0) {
        delete $mp->{METADATAMARKS}->{$mm};
        my $rmMD = find($mp->{STORE}, "//nmwg:metadata[\@id=\"".$mm."\"]", 1);
        $logger->debug("Removing metadata child \"".$mm."\" from the DOM.");
        $mp->{STORE}->getDocumentElement->removeChild($rmMD);  
      }
    }  
  }
  else {
    $logger->error("Missing argument(s).");
  }
  return;
}


sub parseFile {
  my($mp) = @_; 
  my $logger = get_logger("perfSONAR_PS::MP::General");   
  my $filedb = new perfSONAR_PS::DB::File({
    file => $mp->{CONF}->{"METADATA_DB_FILE"}
  });  
  $filedb->openDB;   
  $logger->debug("Connecting to file database \"".$mp->{CONF}->{"METADATA_DB_FILE"}."\".");
  
  return $filedb->getDOM();
}


sub parseString {
  my($mp) = @_; 
  my $logger = get_logger("perfSONAR_PS::MP::General");
  my $parser = XML::LibXML->new();
  my $result = $parser->parse_string($mp->{CONF}->{"METADATA_DB_FILE"});
  if(defined $result and $result ne "") {
    return $result;
  }
  else {
    $logger->error("XML parsing error.");
  }
  return "";
}


sub parseXMLDB {
  my($mp) = @_;  
  my $logger = get_logger("perfSONAR_PS::MP::General");   
  
  my $metadatadb = new perfSONAR_PS::DB::XMLDB({
    env => $mp->{CONF}->{"METADATA_DB_NAME"}, 
    cont => $mp->{CONF}->{"METADATA_DB_FILE"},
    ns => \%{$mp->{NAMESPACES}}
  });
  $metadatadb->openDB;
  $logger->debug("Connecting to XMLDB database \"".$mp->{CONF}->{"METADATA_DB_NAME"}."\".");

  my $storeString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<nmwg:store ";
  foreach my $ns (keys %{$mp->{NAMESPACES}}) {
    $storeString = $storeString."xmlns:".$ns."=\"".$mp->{NAMESPACES}->{$ns}."\" ";
  }
  $storeString = $storeString.">";
    
  my @query = ("//nmwg:metadata", "//nmwg:data");  
 
  for(my $y = 0; $y <= 1; $y++) {
    $logger->debug("Query \"".$query[$y]."\" created.");
    my @resultsString = $metadatadb->query({ query => $query[$y] });   
        
    if($#resultsString != -1) {   
      for(my $x = 0; $x <= $#resultsString; $x++) {     	
	      $storeString = $storeString . $resultsString[$x];
      }    
    }
    else {
      $logger->error($mp->{CONF}->{"METADATA_DB_TYPE"}." returned 0 results.");      
    } 
  }
  
  $storeString = $storeString."</nmwg:store>";
  my $parser = XML::LibXML->new();
  
  return $parser->parse_string($storeString); 
}



1;


__END__
=head1 NAME

perfSONAR_PS::MP::General - A module that provides methods for general tasks that MPs need to 
perform, such as creating messages or result code structures.  

=head1 DESCRIPTION

This module is a catch all for common methods (for now) of MPs in the perfSONAR-PS framework.  
As such there is no 'common thread' that each method shares.  This module IS NOT an object, 
and the methods can be invoked directly (and sparingly).  

=head1 SYNOPSIS


    use perfSONAR_PS::MP::General;

    my %ns = (
      nmwg => "http://ggf.org/ns/nmwg/base/2.0/",
      netutil => "http://ggf.org/ns/nmwg/characteristic/utilization/2.0/",
      nmwgt => "http://ggf.org/ns/nmwg/topology/2.0/",
      snmp => "http://ggf.org/ns/nmwg/tools/snmp/2.0/"    
    );
    
    my $mp = perfSONAR_PS::MP::...;
    
    # do mp stuff ...
    
    cleanMetadata(\%{$mp}); 

    cleanData(\%{$mp}); 
    
    my $prefix = lookup(\%{$mp}, "http://ggf.org/ns/nmwg/base/2.0/", "nmwg");
        
    removeReferences(\%{$mp}, $id_value);
    
    
=head1 DETAILS

The API for this module aims to be simple; note that this is not an object and 
each method does not have the 'self knowledge' of variables that may travel 
between functions.  

=head1 API

The offered API is basic for now, until more common features to MPs can be identified
and utilized in this module.

=head2 cleanMetadata($mp)

Chains, and removes unused metadata values from the metadata object located in the 
passed 'MP' object.

=head2 cleanData($mp)

Chains, and removes unused data values from the data object located in the 
passed 'MP' object.

=head2 lookup($mp, $uri, $default)

Lookup the prefix value for a given URI in the NS hash.  If not found, supply a 
simple deafult.

=head2 removeReferences($mp, $id, $did)

Removes a value from the an object (data/metadata) located in the passed 'MP' object 
and only if the value is equal to the supplied id values. 

=head1 SEE ALSO

L<Exporter>, L<perfSONAR_PS::Common>

To join the 'perfSONAR-PS' mailing list, please visit:

  https://mail.internet2.edu/wws/info/i2-perfsonar

The perfSONAR-PS subversion repository is located at:

  https://svn.internet2.edu/svn/perfSONAR-PS 
  
Questions and comments can be directed to the author, or the mailing list. 

=head1 VERSION

$Id: General.pm 524 2007-09-05 17:35:50Z aaron $

=head1 AUTHOR

Jason Zurawski, E<lt>zurawski@internet2.eduE<gt>

=head1 LICENSE
 
You should have received a copy of the Internet2 Intellectual Property Framework along
with this software.  If not, see <http://www.internet2.edu/membership/ip.html>

=head1 COPYRIGHT
 
Copyright (c) 2004-2007, Internet2 and the University of Delaware

All rights reserved.

=cut
