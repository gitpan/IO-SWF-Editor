#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Bitmap;

if (@ARGV != 1) {
    print "Usage: perl get_bitmapsize.pl <bitmap_file>\n";
    print "ex) perl get_bitmapsize.pl test.jpg\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $bitmap_data = $fh->getline;
$fh->close;

my %ret = IO::SWF::Bitmap::get_bitmapsize($bitmap_data);

printf("width:%d height:%d\n", $ret{width}, $ret{height});

exit();
