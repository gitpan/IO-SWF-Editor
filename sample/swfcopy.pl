#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF;

if (@ARGV != 1) {
    print "Usage: perl swfcopy.pl <swf_file>\n";
    print "ex) perl swfcopy.pl test.swf > output.swf\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $swf = IO::SWF->new();
$swf->parse($swf_data);
print $swf->build();

exit;

