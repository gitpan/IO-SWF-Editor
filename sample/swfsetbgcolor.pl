#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Editor;

if (@ARGV != 4) {
    print "Usage: perl swfsetbgcolor.pl <swf_file> <red> <green> <blue>\n";
    print "ex) perl swfsetbgcolor.pl test.swf 0 0 255\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $swf = IO::SWF::Editor->new();
$swf->parse($swf_data);

my $color = pack('CCC', $ARGV[1], $ARGV[2], $ARGV[3]);
$swf->replaceTagContent(9, $color);

print $swf->build();

exit;

