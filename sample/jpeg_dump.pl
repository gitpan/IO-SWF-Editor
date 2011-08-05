#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::JPEG;

sub usage() {
    print "Usage: perl jpeg_dump.pl <dump|jpegtables|imagedata>\n";
    print "ex) perl jpeg_dump.pl dump test.jpg\n";
}

if (@ARGV != 2) {
    usage();
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[1]);
local $/;
my $jpeg_data = $fh->getline;
$fh->close;

my $jpeg = IO::SWF::JPEG->new();
$jpeg->input($jpeg_data);

my $mode = $ARGV[0];
if ($mode eq 'dump') {
    $jpeg->dumpChunk();
}
elsif ($mode eq 'jpegtables') {
    print $jpeg->getEncodingTables();
}
elsif ($mode eq 'imagedata') {
    print $jpeg->getImageData();
}
else {
    usage();
    exit();
}

exit();
