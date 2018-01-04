package perfSONAR_PS::Utils::JQ;

use strict;
use warnings;

our $VERSION = 4.1;

=head1 NAME

perfSONAR_PS::Utils::JQ

=head1 DESCRIPTION

Utilities for running JQ. Currently just execs JQ command-line client

Much of code adapted from https://github.com/perlancar/perl-DateTime-Format-Duration-ISO8601

=head1 API

=cut

use base 'Exporter';
use JSON qw(from_json to_json);
use IPC::Run qw(run timeout start pump);

our @EXPORT_OK = qw( jq );

sub jq {
    my ($jq, $json_obj, $formatting_params) = @_;
    
    #initialize formatting params
    $formatting_params = {} unless $formatting_params;
    unless(exists $formatting_params->{'utf8'} && defined $formatting_params->{'utf8'}){
        $formatting_params->{'utf8'} = 1;
    }
    unless(exists $formatting_params->{'canonical'} && defined $formatting_params->{'canonical'}){
        #makes JSON loading faster
        $formatting_params->{'canonical'} = 0;
    }
    unless(exists $formatting_params->{'allow_nonref'} && defined $formatting_params->{'allow_nonref'}){
        #a lot of JQ is not grabbing objects, so use this as default
        $formatting_params->{'allow_nonref'} = 1;
    }
    
    #join jq script
    if(ref($jq) eq 'ARRAY'){
        $jq = join ' ', @{$jq};
    }
    
    #initialize command  variables
    my @cmd = ('jq', "$jq");
    my $cmd_string = join ' ', @cmd;
    my($stdin, $stdout, $stderr, $status);
    
    #convert to json
    my $json_str;
    eval{ $json_str = to_json($json_obj); };
    if($@){
        die "Invalid JSON given to jq: " . $@;
    }
    
    ##
    #run command. Actually execute JQ twice to aboid broken pipes.
    eval{ 
        ###
        #Run first command to validate jq script. If try to run this and invalid jq, will
        #get a broken pipe error via a SIGPIPE when try to write to STDIN. The SIGPIPE will 
        #kill the parent. If SIGPIPE handled/ignored the parent will survive but useful 
        #error messages destroyed. 
        run \@cmd, \$stdin, \$stdout, \$stderr, timeout(10) or $status=$?;
        unless($?){
            ##
            #if first command worked, then jq is valid, so run again but give it JSON
            #string to transform.
            run \@cmd, \$json_str, \$stdout, \$stderr, timeout(10) or $status=$?;
        }
    };
    if($@){
        die "Unable to run jq command($cmd_string): " . $@;
    }elsif($status){
        die "jq returned error($status): " . $stderr;
    }
    
    #convert back to object
    my $new_json_obj;
    eval{ 
        $new_json_obj = from_json($stdout, $formatting_params); 
    };
    if($@){
        die "jq returned invalid JSON: " . $@;
    }

    return $new_json_obj;
}


