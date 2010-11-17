BEGIN {
    use Config;
    unless ( $Config{d_link} && $Config{d_symlink} )
    {
        print "1..0 # Skip: no link and/or symlink\n";
        exit 0;
    }
}

use inc::Module::Install;

name           ('File-LinkDir');
all_from       ('lib/File/LinkDir.pm');
githubmeta     ();

requires       ('File::Path'   => '2.07');
test_requires  ('Test::More'   => '0');
tests_recursive();

WriteAll();
