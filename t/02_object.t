use strict;
use warnings;
use lib 'lib';
use Test::More tests => 2;

use File::LinkDir::OO;

my $fld = File::LinkDir::OO->new(
    source => 't/tests/src',
    dest   => 't/tests/dest',
);

ok( defined $fld );

isa_ok( $fld, 'File::LinkDir::OO' );


