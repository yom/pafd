package PAF::Config;
use strict;
use warnings;

use base 'Exporter';
use Carp;
use Config::Std;
use Getopt::Long;
use Pod::Usage;

our @EXPORT_OK = ('config');
our %EXPORT_TAGS = ( all => [qw(config)] );

=head1 NAME

PAF::Config - Configuration handlers for PAF

=cut

my ( %cfgfile, %cmdline, %conf, $config, $help, $man );

=head1 SYNOPSIS

  use PAF::Config qw( config );

  PAF::Config->load;
  my $opt = config('someopt');

=head1 EXPORT

The C<config> function can be exported.

=head1 FUNCTIONS

=over  

=item C<< load >>

Load config defaults from (in order of precedence) :
1 - Command line
2 - Configuration file
3 - Hardcoded values

=cut

sub load {
    GetOptions(
        'c|config=s'  => \$cmdline{config},
        's|socket=s'  => \$cmdline{sock_name},
        'p|pid=s'     => \$cmdline{pid_name},
        'u|user=s'    => \$cmdline{runasuid},
        'g|group=s'   => \$cmdline{runasgid},
        'd|daemonize' => \$cmdline{daemonize},
        'v|verbose'   => \$cmdline{verbose},
        'h|help'      => \$help,
        'm|man'       => \$man,
    ) or pod2usage(2);

    pod2usage(1) if $help;
    pod2usage( -exitval => 0, -verbose => 2 ) if $man;

    $config = choose( 'config', '/etc/pafd/pafd.conf' );

    my %c;
    read_config $config => %c
      if ( -e $config && -r $config );
    %cfgfile = %c;

    choose( 'sock_name', '/var/run/pafd/pafd.sock' );
    choose( 'pid_name',  '/var/run/pafd/pafd.pid' );
    choose( 'runasuid',  'nobody' );
    choose( 'runasgid',  'nogroup' );
    choose( 'daemonize', 0 );
    choose( 'verbose',   0 );
    choose( 'help',      0 );
    choose( 'man',       0 );

    return;
} ## end sub load

=item C<< choose( $name, $default ) >>

Set config value from command line or config file or supplied default
(in that order).

=cut

sub choose {
    my ( $name, $default ) = @_;
    return config( $name, $cmdline{$name} ) if defined $cmdline{$name};
    return config( $name, $cfgfile{$name} ) if defined $cfgfile{$name};
    return config( $name, $default );
} ## end sub choose

=item C<< config( $key[, $value] ) >>

Get/set config value.

=cut

sub config {
    my ( $k, $v ) = @_;
    return $conf{$k} = $v if ( defined $v );
    croak "No config variable '$k'" unless ( defined $conf{$k} );
    return $conf{$k};
} ## end sub config

=back

=head1 AUTHOR

Guillaume Blairon, C<< <g at yom.be > >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

  perldoc PAF::Config

=head1 COPYRIGHT & LICENSE

Copyright 2010 Guillaume Blairon, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
