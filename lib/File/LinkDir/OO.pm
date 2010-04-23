package File::LinkDir::OO;

use strict;
use warnings;

use Cwd qw<abs_path getcwd>;
use File::Find;
use File::Path qw<remove_tree make_path>;
use File::Spec::Functions qw<catpath splitpath>;

our $VERSION = '0.05a';

sub new
{
    my $class = shift;

    my $self = {};
    bless $self, $class;

    $self->init( @_ );

    return $self;
}

sub init
{
    my $self = shift;
    my %opt;
    my @opts = @_;

    $self->{addignore} = [];
    $self->{ignore} = '(?:.*/)?.(?:git|svn)(?:/.*)?$';
    $self->{force} = 0;
    $self->{hard} = 0;

    my ( $opt, $value );
    for my $tmp ( @opts )
    {
        if ( ! defined $opt || ( defined $opt && defined $value ) )
        {
            $opt = $tmp;
            undef $value;
            if ( $opt eq 'force' || $opt eq 'hard' )
            {
                $self->{$opt} = 1;
                undef $opt;
            }
        }
        elsif ( ! defined $value )
        {
            $value = $tmp;
            if ( $opt eq 'addignore' )
            {
                push @{ $self->{ $opt } }, $value;
            }
            else
            {
                $self->{$opt} = $value;
            }
        }
    }

    {
        local $@;
        eval { $self->{ignore} = qr/$self->{ignore}/ };
        die "Invalid regex passed to ignore: $@\n" if $@;
    }

    for my $rx ( @{ $self->{addignore} } )
    {
        local $@;
        eval { $rx = qr/$rx/ };
        die "Invalid regex passed to addignore: $@\n" if $@;
    }
    
    $self->{source} = abs_path( $self->{source} );
    die "You must supply a source directory\n" unless ( defined $self->{source} && -d $self->{source} );
    die "You must supply a dest directory\n" unless ( defined $self->{dest} && -d $self->{dest} );

}

sub run
{
    my $self = shift;

    chdir $self->{source} or die "Couldn't chdir to '$self->{source}'\n";

    $self->{recursive}
        ? find( { wanted => sub { $self->recursive() }, no_chdir => 1 }, $self->{source} )
        : $self->normal();
}

sub recursive
{
    my $self = shift;

    my $source = $self->{source};
    my $dest = $self->{dest};

    my $file = $File::Find::name;
    $file =~ s{^$source/}{};

    return if $file =~ $self->{ignore};
    return if grep { $file =~ /$_/ } @{ $self->{addignore} };
    return unless -f $file || -l $file;

    if ( -l $file && -l "$dest/$file")
    {
        # skip if it's a link which is already in place
        return if readlink( $file ) eq readlink( "$dest/$file" );
    }

    if ( ! -l $file && -l "$dest/$file" && stat "$dest/$file" )
    {
        # skip if it's file that has already been linked
        return if ( stat "$dest/$file" )[1] == ( stat $file )[1];
    }
    
    if ( -e "$dest/$file" || -l "$dest/$file" )
    {
        if ( ! -l "$dest/$file" && -d "$dest/$file" )
        {
            warn "Won't replace dir '$dest/$file' with a link\n";
            return;
        }

        if ( ! $self->{force} )
        {
            warn "force is off, not overwriting '$dest/$file'\n";
            return;
        }
        
        warn "Overwriting '$dest/$file' -> '$source/$file'\n" if $self->{verbose};
        if ( ! unlink "$dest/$file" )
        {
            warn "Can't remove '$dest/$file': $!\n";
            return;
        }
    }
    else
    {
        warn "Creating '$dest/$file -> '$source/$file''\n" if $self->{verbose};
    }
    
    my $path = catpath( ( splitpath( "$dest/$file" ) )[0,1] );
    if ( ! -d $path )
    {
        local $@;
        eval { make_path($path) };
        if ( $@ )
        {
            warn "Failed to create dir '$path': $@\n";
            return;
        }
    }

    my $success = -l $file
        ? symlink readlink($file), "$dest/$file"
        : $self->{hard}
            ? link "$source/$file", "$dest/$file"
            : symlink "$source/$file", "$dest/$file";

    warn "Can't create '$dest/$file': $!\n" unless $success;
}

sub normal
{
    my $self = shift;

    my $source = $self->{source};
    my $dest = $self->{dest};

    opendir my $dir_handle, $source or die "Can't open the dir $source: $!; aborted";

    while ( defined ( my $file = readdir $dir_handle ) )
    {
        next if $file =~ /^\.{1,2}$/;
        next if $file =~ $self->{ignore};
        next if grep { $file =~ /$_/ } @{ $self->{addignore} };

        if ( -l "$dest/$file" && stat "$dest/$file" )
        {
            next if ( stat "$dest/$file" )[1] == ( stat $file )[1];
        }
        
        if ( -e "$dest/$file" || -l "$dest/$file" )
        {
            if ( ! $self->{force} )
            {
                warn "force is off, not overwriting '$dest/$file'\n";
                next;
            }
            
            warn "Overwriting '$dest/$file' -> '$source/$file'\n" if $self->{verbose};

            if ( -d "$dest/$file" )
            {
                local $@;
                eval { remove_tree("$dest/$file") };
                if ( $@ )
                {
                    warn "Failed to remove directory '$dest/$file': $@\n";
                    next;
                }
            }
            elsif ( ! unlink( "$dest/$file" ) )
            {
                warn "Failed to remove file '$dest/$file': $!\n";
                next;
            }
        }
        else
        {
            warn "Creating '$dest/$file' -> '$source/$file'\n" if $self->{verbose};
        }
        
        if ( $self->{hard} )
        {
            link "$source/$file", "$dest/$file" or warn "Can't create '$dest/$file': $!\n";
        }
        else
        {
            symlink "$source/$file", "$dest/$file" or warn "Can't create '$dest/$file': $!\n";
        }
    }
}

=encoding UTF-8

=head1 NAME

File::LinkDir::OO - Create links in one directory for files in another

=head1 SYNOPSIS

  use File::LinkDir::OO;
  my $linkdir = File::LinkDir->new( 'source' => '/path/to/dir', 'dest' => '/dest/path', 'hard', 'recursive' );
  $linkdir->run();
  $linkdir->init( 'source' => '/new/path', 'dest' => '/new/dest', );
  $linkdir->run();

=head1 DESCRIPTION

By default, File::LinkDir::OO will create symlinks in the destination directory for all top-level files, directories or symlinks found in the source directory. This is very useful for keeping the dot files in your C<$HOME> under version control. A typical use case:

  use File::LinkDir::OO;
  my $linkdir = File::LinkDir->new( 'source' => '.', 'dest' => '~' );
  $linkdir->run();

=head1 OPTIONS

=head2 dry-run

  C<dry-run =&gt; 1>

Prints what would have been done without actually doing it.

=head2 source

  C<source  =&gt; DIR>

The source directory.
  
=head2 dest

  C<dest    =&gt; DIR>

The destination directory.

=head2 recursive

  C<recursive =&gt; 1>

With C<recursive =&gt; 1>, it will not create symlinks to subdirectories
found in the source directory. It will instead recurse into them and create
symlinks for any files or symlinks it finds. Any subdirectories not found in
the destination directory will be created. This approach is useful for
destination directories where programs or users other than yourself might add
things to subdirectories which you don't want ending up in your working tree
implicitly. F</etc> is a good example.

In both cases, symlinks from the source directory will be copied as-is. This
makes sense because the symlinks might be relative.

=head2 ignore

  C<ignore   =&gt; RX>

RX is a regex matching files to ignore. If C<ignore   =&gt; 1> is not
specified, it defaults to ignoring F<.git> and F<.svn> directories and their
contents.

=head2 add-ignore

  C<add-ignore =&gt; RX>

Like C<ignore   =&gt; RX> but doesn't replace the default.

=head2 force

  C<force      =&gt; 1>

Remove and/or overwrite existing files/dirs.

=head2 hard

  C<hard       =&gt; 1>

Creates hard links instead of symlinks.

=head1 AUTHORS

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

Matthew Musgrove, mr.muskrat@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2009 - 2010 Hinrik E<Ouml>rn SigurE<eth>sson, Matthew Musgrove

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

