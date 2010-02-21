#!/usr/bin/env perl

use warnings;
use strict;
use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use File::Copy;

$Data::Dumper::Sortkeys = 1;

#########################################################################
# parse and check cmd line arguments
my ($opt_h, $opt_v);
Getopt::Long::Configure('no_ignore_case');
if(!GetOptions (
   "h"              => \$opt_h,
   "<>"             => \&add_file,
)) {
    pod2usage( { -verbose => 1, -message => 'error in options' } );
    exit 3;
}

if(defined $opt_h) {
    pod2usage( { -verbose => 1 } );
    exit 3;
};

#########################################################################
unless(-d './script/') {
    print "please run only from the project root\n";
}

#########################################################################
# create source package
unlink(glob("*.gz"));
cmd("rm -rf local-lib > /dev/null");
cmd("perl Makefile.PL");
cmd("make distclean");
cmd("perl Makefile.PL");
cmd("make");
cmd("make dist");
cmd('rsync -av $HOME/perl5 local-lib');

#########################################################################
# fix name of source tarball
my @gzips = glob("*.gz");
if(scalar @gzips != 1) { die("found != 1 .gz files: ".Dumper(\@gzips)); }
my $archive = $gzips[0];

$archive =~ m/Thruk\-(.*?)\.tar\.gz/mx;
my $version = $1;
unless(defined $version) {
    die("archive name does not match");
}
my $newarchive = "Thruk-".$version."-src.tar.gz";
# replace with src name
move($archive, $newarchive);
print "moved $archive to $newarchive\n";
$archive = $newarchive;

#########################################################################
# add local lib dir
chomp(my $arch = `uname -m`);
cmd("tar zxvf $archive");
cmd("rsync -a local-lib Thruk-".$version."/");
cmd("tar cvf Thruk-".$version."-".$arch.".tar Thruk-".$version);
cmd("gzip -9 Thruk-".$version."-".$arch.".tar");
cmd("rm -rf Thruk-".$version);
cmd("rm -rf local-lib");
print "created Thruk-".$version."-".$arch.".tar.gz\n";

#########################################################################
# finished
exit;
#########################################################################

#########################################################################
# SUBS
#########################################################################
sub cmd {
    my $cmd = shift;
    open(my $ph, '|-', $cmd." 2>&1") or die("cannot execute cmd: $cmd");
    while(my $line = <$ph>) {
        print $line;
    }
    close($ph) or die("cmd failed (rc:$?): $!");
    return 1;
}

#########################################################################

=head1 NAME

thruk_create_package.pl - Creates a source and arch package

=head1 SYNOPSIS

thruk_create_package.pl [ -h ]

=head1 DESCRIPTION

Creates a source and arch package

=head1 AUTHORS

Sven Nierlein, 2010, <nierlein@cpan.org>

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut