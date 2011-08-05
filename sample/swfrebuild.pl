#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Editor;

if (@ARGV != 1) {
    print "Usage: perl swfrebuild.pl <swf_file>\n";
    print "ex) perl swfrebuild.pl test.swf > output.swf\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $swf = IO::SWF::Editor->new();
$swf->parse($swf_data);

$swf->rebuild();

print $swf->build();

exit;
