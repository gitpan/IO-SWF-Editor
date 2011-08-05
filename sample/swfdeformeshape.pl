#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Editor;

if (@ARGV != 2) {
    print "Usage: perl swfdeformeshape.pl <swf_file> <threshold>\n";
    print "ex) perl swfdeformeshape.pl test.swf 10 > output.swf\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $threshold = $ARGV[1];

my $swf = IO::SWF::Editor->new();
$swf->parse($swf_data);

$swf->deformeShape($threshold);

print $swf->build();

exit;

