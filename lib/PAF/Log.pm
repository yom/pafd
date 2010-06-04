package PAF::Log;

use strict;
use warnings;
use base 'Exporter';
use PAF::Config qw( config );
use Sys::Syslog qw( :standard :macros );

our @EXPORT_OK = ( 'logmsg', 'dbg' );
our %EXPORT_TAGS = ( all => [qw( logmsg dbg )] );

sub logmsg {
    my $level = ( @_ == 2 ) ? shift : LOG_INFO;
    my $msg = shift;

    if ( config('daemonize') ) {
        my $ident    = $0;
        my $opts     = 'ndelay,pid';
        my $facility = LOG_DAEMON;

        openlog( $ident, $opts, $facility );
        syslog( $level, $msg );
        return closelog();
    } else {
        print "* $msg\n";
        return;
    }
} ## end sub logmsg

sub dbg {
    my $msg = shift;
    return logmsg( LOG_DEBUG, $msg ) if config('verbose');
    return;
}

1;
