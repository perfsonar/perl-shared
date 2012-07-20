package perfSONAR_PS::Utils::TCP_Info;

use Moose;
use Socket qw(:all);
use Log::Log4perl qw(get_logger);

=head1 NAME

perfSONAR_PS::Utils::TCP_Info;

=head1 DESCRIPTION

A module that eases the calling of the TCP_INFO getsockopt method on IO::Socket
sockets. This module currently only works on Linux.

struct tcp_info
{
	__u8	tcpi_state;
	__u8	tcpi_ca_state;
	__u8	tcpi_retransmits;
	__u8	tcpi_probes;
	__u8	tcpi_backoff;
	__u8	tcpi_options;
	__u8	tcpi_snd_wscale : 4, tcpi_rcv_wscale : 4;

	__u32	tcpi_rto;
	__u32	tcpi_ato;
	__u32	tcpi_snd_mss;
	__u32	tcpi_rcv_mss;

	__u32	tcpi_unacked;
	__u32	tcpi_sacked;
	__u32	tcpi_lost;
	__u32	tcpi_retrans;
	__u32	tcpi_fackets;

	/* Times. */
	__u32	tcpi_last_data_sent;
	__u32	tcpi_last_ack_sent;     /* Not remembered, sorry. */
	__u32	tcpi_last_data_recv;
	__u32	tcpi_last_ack_recv;

	/* Metrics. */
	__u32	tcpi_pmtu;
	__u32	tcpi_rcv_ssthresh;
	__u32	tcpi_rtt;
	__u32	tcpi_rttvar;
	__u32	tcpi_snd_ssthresh;
	__u32	tcpi_snd_cwnd;
	__u32	tcpi_advmss;
	__u32	tcpi_reordering;

	__u32	tcpi_rcv_rtt;
	__u32	tcpi_rcv_space;

	__u32	tcpi_total_retrans;
};

=head1 API

=cut

our $logger = get_logger( __PACKAGE__ );

=head2 perfSONAR_PS::Utils::TCP_INFO->get_tcp_info ($socket)

Calls the getsockopt TCP_INFO, and returns an object containing all the fields
in the above struct.

=cut
sub get_tcp_info {
    my ($class, $socket) = @_;

    my $TCP_INFO = 11;

    my $packed = $socket->getsockopt(IPPROTO_TCP, $TCP_INFO);

    return unless $packed;

    my $object = $class->new();
    $object->parse($packed);

    return $object;
}

has 'tcpi_state' => (is => 'rw', isa => 'Int');
has 'tcpi_ca_state' => (is => 'rw', isa => 'Int');
has 'tcpi_retransmits' => (is => 'rw', isa => 'Int');
has 'tcpi_probes' => (is => 'rw', isa => 'Int');
has 'tcpi_backoff' => (is => 'rw', isa => 'Int');
has 'tcpi_options' => (is => 'rw', isa => 'Int');
has 'tcpi_snd_wscale' => (is => 'rw', isa => 'Int');
has 'tcpi_rcv_wscale' => (is => 'rw', isa => 'Int');

has 'tcpi_rto' => (is => 'rw', isa => 'Int');
has 'tcpi_ato' => (is => 'rw', isa => 'Int');
has 'tcpi_snd_mss' => (is => 'rw', isa => 'Int');
has 'tcpi_rcv_mss' => (is => 'rw', isa => 'Int');

has 'tcpi_unacked' => (is => 'rw', isa => 'Int');
has 'tcpi_sacked' => (is => 'rw', isa => 'Int');
has 'tcpi_lost' => (is => 'rw', isa => 'Int');
has 'tcpi_retrans' => (is => 'rw', isa => 'Int');
has 'tcpi_fackets' => (is => 'rw', isa => 'Int');

has 'tcpi_last_data_sent' => (is => 'rw', isa => 'Int');
has 'tcpi_last_ack_sent' => (is => 'rw', isa => 'Int');
has 'tcpi_last_data_recv' => (is => 'rw', isa => 'Int');
has 'tcpi_last_ack_recv' => (is => 'rw', isa => 'Int');

has 'tcpi_pmtu' => (is => 'rw', isa => 'Int');
has 'tcpi_rcv_ssthresh' => (is => 'rw', isa => 'Int');
has 'tcpi_rtt' => (is => 'rw', isa => 'Int');
has 'tcpi_rttvar' => (is => 'rw', isa => 'Int');
has 'tcpi_snd_ssthresh' => (is => 'rw', isa => 'Int');
has 'tcpi_snd_cwnd' => (is => 'rw', isa => 'Int');
has 'tcpi_advmss' => (is => 'rw', isa => 'Int');
has 'tcpi_reordering' => (is => 'rw', isa => 'Int');

has 'tcpi_rcv_rtt' => (is => 'rw', isa => 'Int');
has 'tcpi_rcv_space' => (is => 'rw', isa => 'Int');

has 'tcpi_total_retrans' => (is => 'rw', isa => 'Int');

sub parse {
    my ($self, $getsockopt_output) = @_;

    my $format = "CCCCCCCCLLLLLLLLLLLLLLLLLLLLLLLL";

    my ($tcpi_state, $tcpi_ca_state, $tcpi_retransmits, $tcpi_probes, $tcpi_backoff,
    $tcpi_options, $tcpi_snd_wscale, $tcpi_rcv_wscale, $tcpi_rto, $tcpi_ato,
    $tcpi_snd_mss, $tcpi_rcv_mss, $tcpi_unacked, $tcpi_sacked, $tcpi_lost,
    $tcpi_retrans, $tcpi_fackets, $tcpi_last_data_sent, $tcpi_last_ack_sent,
    $tcpi_last_data_recv, $tcpi_last_ack_recv, $tcpi_pmtu, $tcpi_rcv_ssthresh,
    $tcpi_rtt, $tcpi_rttvar, $tcpi_snd_ssthresh, $tcpi_snd_cwnd, $tcpi_advmss,
    $tcpi_reordering, $tcpi_rcv_rtt, $tcpi_rcv_space, $tcpi_total_retrans) = unpack($format, $getsockopt_output);
   
    $logger->debug("tcpi_state: ".$tcpi_state);
    $logger->debug("tcpi_ca_state: ".$tcpi_ca_state);
    $logger->debug("tcpi_retransmits: ".$tcpi_retransmits);
    $logger->debug("tcpi_probes: ".$tcpi_probes);
    $logger->debug("tcpi_backoff: ".$tcpi_backoff);
    $logger->debug("tcpi_options: ".$tcpi_options);

    $logger->debug("tcpi_rto: ".$tcpi_rto);
    $logger->debug("tcpi_ato: ".$tcpi_ato);
    $logger->debug("tcpi_snd_mss: ".$tcpi_snd_mss);
    $logger->debug("tcpi_rcv_mss: ".$tcpi_rcv_mss);

    $logger->debug("tcpi_unacked: ".$tcpi_unacked);
    $logger->debug("tcpi_sacked: ".$tcpi_sacked);
    $logger->debug("tcpi_lost: ".$tcpi_lost);
    $logger->debug("tcpi_retrans: ".$tcpi_retrans);
    $logger->debug("tcpi_fackets: ".$tcpi_fackets);

    $logger->debug("tcpi_last_data_sent: ".$tcpi_last_data_sent);
    $logger->debug("tcpi_last_ack_sent: ".$tcpi_last_ack_sent);
    $logger->debug("tcpi_last_data_recv: ".$tcpi_last_data_recv);
    $logger->debug("tcpi_last_ack_recv: ".$tcpi_last_ack_recv);

    $logger->debug("tcpi_pmtu: ".$tcpi_pmtu);
    $logger->debug("tcpi_rcv_ssthresh: ".$tcpi_rcv_ssthresh);
    $logger->debug("tcpi_rtt: ".$tcpi_rtt);
    $logger->debug("tcpi_rttvar: ".$tcpi_rttvar);
    $logger->debug("tcpi_snd_ssthresh: ".$tcpi_snd_ssthresh);
    $logger->debug("tcpi_snd_cwnd: ".$tcpi_snd_cwnd);
    $logger->debug("tcpi_advmss: ".$tcpi_advmss);
    $logger->debug("tcpi_reordering: ".$tcpi_reordering);

    $logger->debug("tcpi_rcv_rtt: ".$tcpi_rcv_rtt);
    $logger->debug("tcpi_rcv_space: ".$tcpi_rcv_space);

    $logger->debug("tcpi_total_retrans: ".$tcpi_total_retrans);

    $self->tcpi_state($tcpi_state);
    $self->tcpi_ca_state($tcpi_ca_state);
    $self->tcpi_retransmits($tcpi_retransmits);
    $self->tcpi_probes($tcpi_probes);
    $self->tcpi_backoff($tcpi_backoff);
    $self->tcpi_options($tcpi_options);
    $self->tcpi_snd_wscale($tcpi_snd_wscale);
    $self->tcpi_rcv_wscale($tcpi_rcv_wscale);

    $self->tcpi_rto($tcpi_rto);
    $self->tcpi_ato($tcpi_ato);
    $self->tcpi_snd_mss($tcpi_snd_mss);
    $self->tcpi_rcv_mss($tcpi_rcv_mss);

    $self->tcpi_unacked($tcpi_unacked);
    $self->tcpi_sacked($tcpi_sacked);
    $self->tcpi_lost($tcpi_lost);
    $self->tcpi_retrans($tcpi_retrans);
    $self->tcpi_fackets($tcpi_fackets);

    $self->tcpi_last_data_sent($tcpi_last_data_sent);
    $self->tcpi_last_ack_sent($tcpi_last_ack_sent);
    $self->tcpi_last_data_recv($tcpi_last_data_recv);
    $self->tcpi_last_ack_recv($tcpi_last_ack_recv);

    $self->tcpi_pmtu($tcpi_pmtu);
    $self->tcpi_rcv_ssthresh($tcpi_rcv_ssthresh);
    $self->tcpi_rtt($tcpi_rtt);
    $self->tcpi_rttvar($tcpi_rttvar);
    $self->tcpi_snd_ssthresh($tcpi_snd_ssthresh);
    $self->tcpi_snd_cwnd($tcpi_snd_cwnd);
    $self->tcpi_advmss($tcpi_advmss);
    $self->tcpi_reordering($tcpi_reordering);

    $self->tcpi_rcv_rtt($tcpi_rcv_rtt);
    $self->tcpi_rcv_space($tcpi_rcv_space);

    $self->tcpi_total_retrans($tcpi_total_retrans);

    return $self;
}

1;
