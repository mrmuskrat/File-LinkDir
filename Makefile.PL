use strict;
use warnings;
use inc::Module::Install;
use 5.008;

name           ('File-LinkDir-OO');
all_from       ('lib/File/LinkDir/OO.pm');
githubmeta     ();
requires       ('File::Path'   => '2.07');
test_requires  ('Test::More'   => '0');
tests_recursive();
WriteAll();
