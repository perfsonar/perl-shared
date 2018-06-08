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
use IPC::Run3;

our @EXPORT_OK = qw( jq );

=item jq()

Executes a jq query against the given HashRef and then returns the resulting JSON. The 
resulting JSON can optionally be formatted using the given formatting parameters.

=cut

sub jq {
    my ($jq, $json_obj, $formatting_params, $timeout) = @_;
    
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
    #init timeout
    $timeout = 10 unless(defined $timeout);
    
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
        ##
        # Init timeout handling
        local $SIG{ALRM} = sub { die "Timeout executing jq command\n" }; # NB: \n required
        ###
        #Run first command to validate jq script. If try to run this and invalid jq, will
        #get a broken pipe error via a SIGPIPE when try to write to STDIN. The SIGPIPE will 
        #kill the parent. If SIGPIPE handled/ignored the parent will survive but useful 
        #error messages destroyed.
        alarm $timeout;
        ## Note: Using run3 from IPC::Run3 because IPC::Run has memory leak
        run3 \@cmd, \$stdin, \$stdout, \$stderr or $status=$?;
        alarm 0;
        unless($?){
            ##
            #if first command worked, then jq is valid, so run again but give it JSON
            #string to transform.
            alarm $timeout;
            run3 \@cmd, \$json_str, \$stdout, \$stderr or $status=$?;
            alarm 0;
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


