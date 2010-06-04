package PAF::Server;
use strict;
use warnings;

use Carp;
use FCGI::Async;
use File::Find;
use IO::Async::Loop::IO_Poll;
use PAF::Config qw( :all );
use PAF::Log qw( :all );
use PAF::Plugin qw( :all );
use PAF::Util qw( :all );

=head1 NAME

PAF::Server - Pluggable Async FastCGI Server

=head1 SYNOPSIS

  $s = PAF::Server->server;
  $s->run;

=cut

our $VERSION = 0.01;
our $DEBUG   = undef;

my $server;

=head1 FUNCTIONS

=over

=item C<< server >>

Create a PAF::Server object.

=cut

sub server {
    my $pkg = shift;
    return $server ||= bless {}, $pkg;
}

=item C<< run >>

Run server.

=cut

sub run {
    my $self = shift;

    PAF::Config->load;

    # Fork to background or just write PID
    daemonize() if ( config('daemonize') );
    write_pid();

    # Get unprivileged rights
    chuidgid( config('runasuid'), config('runasgid') );

    # Load plugins
    $self->init_plugins;

    my $socket = create_socket( config('sock_name') );
    my $loop   = IO::Async::Loop::IO_Poll->new();
    my $fcgi_h = sub { $self->fcgi_dispatch(@_) };
    my $fcgi   = FCGI::Async->new(
        on_request => $fcgi_h,
        handle     => $socket,
        loop       => $loop,
    );
    $loop->loop_forever;

    return;
} ## end sub run

=item C<< init_plugins >>

Initializes each plugin found in PAF/Plugin/

=cut

sub init_plugins {
    my $self = shift;
    my $dir  = 'PAF/Plugin';

    dbg("Looking for plugins...");

    my $path;
    foreach (@INC) {
        $path = $_ . '/' . $dir;
        last if ( ( -e $path ) && ( -d $path ) );
    }

    my @plugins;

    find(
        sub {
            if (/\.pm$/x) {
                s/\.pm$//x;
                s/^\///x;
                push @plugins, $_;
                dbg("Found plugin $_");
            } ## end if (/\.pm$/x)
        },
        $path
    );

    foreach my $p (@plugins) {

        # Force a (re)load of the file
        my $file = 'PAF/Plugin/' . $p . '.pm';
        no warnings 'redefine';
        delete $INC{$file};
        require $file;

        my $m = "PAF::Plugin::$p"->new;

        croak "PAF::Plugin::$p didn't return an object"
          unless ( $m && ref($m) );

        # Save plugin
        $self->{Plugins}->{$p} = $m;
    } ## end foreach my $p (@plugins)

    return;
} ## end sub init_plugins

=item C<< fcgi_dispatch >>

Dispatch a FastCGI request to the corresponding plugin

=cut

sub fcgi_dispatch {
    my ( $self, $fcgi, $req ) = @_;

    foreach ( keys %{ $self->{Plugins} } ) {
        my $p = $self->{Plugins}->{$_};
        my $res = $p->handler( $fcgi, $req );
        if ( defined $res ) {
            dbg("Plugin $p encountered an error")
              unless ($res);
            return;
        }
    } ## end foreach ( keys %{ $self->{Plugins...

    dbg("No plugin found, falling back");
    http_reproxy( $req, 'http://www.cpan.org/' );

    return;
} ## end sub fcgi_dispatch

=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be > >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc PAF::Server

=head1 COPYRIGHT & LICENSE

Copyright 2010 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
