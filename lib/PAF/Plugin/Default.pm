package PAF::Plugin::Default;
use base 'PAF::Plugin';
use strict;
use warnings;

sub handler {
    shift if (@_ == 3);
    my ( $fcgi, $req ) = @_;

    # Do something with request here, return something defined.

    return;
}

1;
