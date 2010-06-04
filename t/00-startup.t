# -*-perl-*-

use strict;
use warnings;

use Test::More tests => 1;
use PAF::Server; 

ok( my $s = PAF::Server->server );
