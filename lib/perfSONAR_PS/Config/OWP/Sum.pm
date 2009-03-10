#
#      $Id$
#
#########################################################################
#									#
#			   Copyright (C)  2006				#
#	     			Internet2				#
#			   All Rights Reserved				#
#									#
#########################################################################
#
#	File:		perfSONAR_PS::Config::OWP::Sum.pm
#
#	Author:		Jeff Boote
#			Internet2
#
#	Date:		Thu Feb 16 21:36:28 MST 2006
#
#	Description:	
#
#	Usage:
#
#	Environment:
#
#	Files:
#
#	Options:
package perfSONAR_PS::Config::OWP::Sum;
require 5.005;
require Exporter;
use strict;
use vars qw(@ISA @EXPORT $VERSION);

@ISA = qw(Exporter);
@EXPORT = qw(parsesum);

$perfSONAR_PS::Config::OWP::Sum::REVISION = '$Id$';
$VERSION = $perfSONAR_PS::Config::OWP::Sum::VERSION='1.0';

sub parsesum{
    my($sfref,$rref) = @_;

    while(<$sfref>){
        my ($key,$val);
        next if(/^\s*#/); # comments
        next if(/^\s*$/); # blank lines

        if((($key,$val) = /^(\w+)\s+(.*?)\s*$/o)){
            $key =~ tr/a-z/A-Z/;
            $$rref{$key} = $val;
            next;
        }

        if(/^<BUCKETS>\s*/){
            my @buckets;
            my ($bi,$bn);
            BUCKETS:
            while(<$sfref>){
                last BUCKETS if(/^<\/BUCKETS>\s*/);
                if((($bi,$bn) =
                        /^\s*(-{0,1}\d+)\s+(\d+)\s*$/o)){
                    push @buckets,$bi,$bn;
                }
                else{
                    warn "SUM Syntax Error[line:$.]: $_";
                    return undef;
                }
            }
            if(@buckets > 0){
                $$rref{'BUCKETS'} = join '_',@buckets;
            }
            next;
        }

        if(/^<TTLBUCKETS>\s*/){
            my @buckets;
            my ($bi,$bn);
            TTLBUCKETS:
            while(<$sfref>){
                last TTLBUCKETS if(/^<\/TTLBUCKETS>\s*/);
                if((($bi,$bn) =
                        /^\s*(-{0,1}\d+)\s+(\d+)\s*$/o)){
                    push @buckets,$bi,$bn;
                }
                else{
                    warn "SUM Syntax Error[line:$.]: $_";
                    return undef;
                }
            }
            if(@buckets > 0){
                $$rref{'TTLBUCKETS'} = join '_',@buckets;
            }
            next;
        }

        warn "SUM Syntax Error[line:$.]: $_";
        return undef;
    }

    if(!defined($$rref{'SUMMARY'})){
        warn "perfSONAR_PS::Config::OWP::Sum::parsesum(): Invalid Summary";
        return undef;
    }

    return 1;
}

1;
