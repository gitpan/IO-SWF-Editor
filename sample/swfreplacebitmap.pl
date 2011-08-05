#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Editor;

if (@ARGV != 3 && @ARGV != 4) {
    print "Usage: perl swfreplacebitmap.pl <swf_file> <bitmap_id> <bitmap_file> [<alpha_file>]\n";
    print "ex) perl swfreplacebitmap.pl test.swf 1 test.jpg test.alpha > output.swf\n";
    print "ex) perl swfreplacebitmap.pl test.swf 1 test.png > output.swf\n";
    print "ex) perl swfreplacebitmap.pl test.swf 1 test.git > output.swf\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $bitmap_id = $ARGV[1];

$fh = FileHandle->new("<" . $ARGV[2]);
local $/;
my $bitmap_data = $fh->getline;
$fh->close;

my $jpeg_alphadata;
if ($ARGV[3]) {
    $fh = FileHandle->new("<" . $ARGV[3]);
    local $/;
    $jpeg_alphadata = $fh->getline;
    $fh->close;
}

my $swf = IO::SWF::Editor->new();
$swf->parse($swf_data);

$swf->setCharacterId($swf_data);

my $ret = $swf->replaceBitmapData($bitmap_id, $bitmap_data, $jpeg_alphadata);

print $swf->build();

exit;

