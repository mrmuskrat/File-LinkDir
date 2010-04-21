use strict;
use warnings;
use inc::Module::Install;
use 5.006;

name           ('File-LinkDir-OO');
perl_version   ('5.006');
author         ('Matthew Musgrove <mr.muskrat@gmail.com>');
abstract_from  ('lib/File/LinkDir/OO.pm');
version_from   ('lib/File/LinkDir/OO.pm');
license        ('perl');
githubmeta     ();
requires       ('File::Path'   => '2.07');
test_requires  ('Test::More'   => '0');
tests_recursive();
WriteAll();
