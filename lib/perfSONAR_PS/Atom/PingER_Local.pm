package perfSONAR_PS::Atom::PingER_Local;

use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::Const -compile => qw(OK);
use XML::Atom::SimpleFeed;
use Data::UUID;
use DBI;
use POSIX qw(strftime);
 
our $dbh  = DBI->connect(
                     "DBI:mysql:pingerMA:localhost",
                     'www',
                     '',
                     {
                        RaiseError => 0,
                        PrintError => 0
                     }
    );

sub handler {
    my $req = shift;
    $req->content_type('application/atom+xml');
    printFeed($req);  
    return Apache2::Const::OK; 
} 


sub printFeed {
 my $req = shift;
 my $uuid_obj = Data::UUID->new();
 my $uuid =  $uuid_obj->create_from_name('http://ggf.org/ns/nmwg/base/2.0/', 'pinger'); 
 my $now = strftime '%Y-%m-%dT%H:%M:%SZ', gmtime;
 my $feed = XML::Atom::SimpleFeed->new(
     title   => 'Fermilab T1 Pinger MA metadata updated in the past 24 hours',
     link    => 'http://lhcopnmon1-mgm.fnal.gov:8075/perfSONAR_PS/services/pinger/ma',
   #  link    => { rel => 'self', href => 'http://lhcopnmon1-mgm.fnal.gov:9090/atom', },
     updated =>  $now,
     author  => 'Maxim Grigoriev',
     id      => "urn:uuid:" . $uuid_obj->to_string($uuid),
 );
 my $error = setMetaFeed($feed, $uuid_obj, $now);
 if($error) { 
     $req->print(" No data available or error <b>$error</b> ");
 } else {
    $feed->print;
 }
}

sub  setMetaFeed {
   my ($feed, $uuid_obj, $now) = @_;
   my     $time_start =   time() -  86400;
   my     $time_end   =   time();
   my $date_fmt = POSIX::strftime( "%Y%m",  gmtime( $time_end ) ); 
   my $table = "data_$date_fmt";
 
   return " The table for this month does not exists, No data " unless tableExists($table);      
   my $sth  = $dbh->prepare(
        "select  distinct(m.metaID), m.ip_name_src,  m.ip_name_dst,  m.packetSize  from metaData m join $table d using (metaID) where  d.meanRtt > 0 group by m.metaID"
        );
    $sth->execute()   or return  " OOops , cant query MySQl DB: " . $DBI::errstr;
    my $last_id = undef;
   
    while ( my ( $metaID, $src, $dst, $pkgsz ) = $sth->fetchrow_array() ) {
        my $id = "$src:$dst:$pkgsz";
        if ( !$last_id || $id ne $last_id ) {
            $last_id = $id;
	   my $uuid = $uuid_obj->create_from_name('http://ggf.org/ns/nmwg/base/2.0/',  $metaID);     
          $feed->add_entry(
              title     =>"Link: ( $src - $dst ) and  PacketSize = $pkgsz bytes",
              link      => "http://lhcopnmon1-mgm.fnal.gov:9090/pinger/gui?src_regexp=$src\&dest_regexp=$dst\&packetsize=$pkgsz",
              id        => "urn:uuid:". $uuid_obj->to_string($uuid),
              summary   => "Metadata ID:$metaID is active",
              updated   => $now ,
              category  => 'perfSONAR-PS',
           
          );
      }      
    }
    $sth->finish();
    return;
}
 

sub tableExists {
    my ($table) = @_;
    my $result = undef;
    eval {

        # next line will fail if table does not exist
        ($result) = $dbh->selectrow_array("select * from  $table where 1=0 ");
    };
    $@ ? return 0 : return 1;
}



1;
