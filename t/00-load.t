#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'File::LinkDir::OO' ) || print "Bail out!
";
}

diag( "Testing File::LinkDir::OO $File::LinkDir::OO::VERSION, Perl $], $^X" );
