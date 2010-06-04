package PAF::Util;
use strict;
use warnings;

use base 'Exporter';
use Carp;
use IO::Socket;
use PAF::Log qw( :all );
use PAF::Config qw( :all );

=head1 NAME

PAF::Util - Various utility functions for PAF

=cut

our @EXPORT_OK   = qw( daemonize chuidgid create_socket write_pid );
our %EXPORT_TAGS = (
    all => [
        qw( daemonize chuidgid create_socket
          write_pid )
    ]
);

=head1 FUNCTIONS

=over

=item C<< daemonize >>

Fork the process in background, preventing it from being reacquired from
any terminal

=cut

sub daemonize {
    my ( $pid, $sessid );

    # Fork and exit parent
    if ( $pid = fork ) { exit 0; }

    # Detach from current terminal
    croak "Cannot detach from terminal\n"
      unless $sessid = POSIX::setsid();

    # Prevent possibility of acquiring from a terminal
    $SIG{HUP} = 'IGNORE';
    if ( $pid = fork ) { exit 0; }

    write_pid();

    chdir "/";
    umask 0;

    logmsg("daemon running as pid $$");

    # Close FDs
    close(STDIN);
    close(STDOUT);
    close(STDERR);

    return;
} ## end sub daemonize

=item C<< write_pid >>

Write PID to config('pid_name').

=cut

sub write_pid {
    my $pid     = $$;
    my $p_fname = config('pid_name');
    my $p_dname = $p_fname;
    $p_dname =~ s/\/[^\/]*$//gx;

    croak "Error writing PID: $p_dname is not writable"
      if ( !-w $p_dname );
    croak "Error writing PID: cannot open $p_fname"
      if ( ( -e $p_fname ) && ( !-w $p_fname ) );
    croak "Error writing PID: cannot unlink $p_fname"
      if ( ( -e $p_fname ) && ( !unlink $p_fname ) );

    open my $P, '>', $p_fname
      or croak "Unable to open $p_fname for writing - $!";
    print $P "$pid\n";
    close $P;

    dbg("PID file : $p_fname");

    return;
} ## end sub write_pid

=item C<< chuidgid >>

Change running UID and GID of current process

=cut

sub chuidgid {
    my ( $uid, $gid ) = @_;
    $gid = getgrnam($gid)
      unless ( $gid =~ m/^\d+$/x );

    $uid = getpwnam($uid)
      unless ( $uid =~ m/^\d+$/x );

    croak "Invalid UID" if ( !defined $uid );
    croak "Invalid GID" if ( !defined $gid );

    croak "Cannot run as root"
      if ( ( $uid == 0 ) || ( $gid == 0 ) );

    POSIX::setgid($gid);
    croak "setgid() failed" if $?;
    POSIX::setuid($uid);
    croak "setuid() failed" if $?;

    dbg("running as $uid / $gid");

    return;
} ## end sub chuidgid

=item C<< create_socket( $socket ) >>

Create and return given socket name

=cut

sub create_socket {
    my $s_fname = shift;
    my $s_dname = $s_fname;
    $s_dname =~ s/\/[^\/]*$//gx;

    croak "Error creating socket: $s_dname is not writable"
      if ( !-w $s_dname );
    croak "Error creating socket: cannot open $s_fname"
      if ( ( -e $s_fname ) && ( !-w $s_fname ) );
    croak "Error creating socket: cannot unlink $s_fname"
      if ( ( -e $s_fname ) && ( !unlink $s_fname ) );

    my %SOCK_OPTS = (
        Type   => SOCK_STREAM,
        Listen => 1,
        Local  => $s_fname,
    );

    my $sock = IO::Socket::UNIX->new(%SOCK_OPTS)
      or croak $@;

    dbg("listening on $s_fname");

    return $sock;
} ## end sub create_socket

=back 

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be > >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc PAF::Util

=head1 COPYRIGHT & LICENSE

Copyright 2010 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
