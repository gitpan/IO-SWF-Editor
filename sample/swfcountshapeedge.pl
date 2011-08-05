#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Editor;

if (@ARGV != 1) {
    print "Usage: perl swfcountshapeedges.pl <swf_file>\n";
    print "ex) perl swfcountshapeedges.pl test.swf\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $swf = IO::SWF::Editor->new();
$swf->parse($swf_data);
my %count_table = $swf->countShapeEdges();
if (!%count_table) {
    print "countShapeEdges return false\n";
    exit;
}

foreach my $shape_id (keys %count_table) {
    print "shape_id: $shape_id => edges_count:" . $count_table{$shape_id} . "\n";
}

exit;

