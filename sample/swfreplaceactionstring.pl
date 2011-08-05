#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use IO::SWF::Editor;

if (@ARGV != 3) {
    print "Usage: perl swfreplaceactionstrings.pl <swf_file> <from_str> <to_str>\n";
    print "ex) perl swfreplaceactionstrings.pl test.swf foo bar\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $ARGV[0]);
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $from_str = $ARGV[1];
my $to_str = $ARGV[2];

my $swf = IO::SWF::Editor->new();

$swf->parse($swf_data);

$swf->replaceActionStrings($from_str, $to_str);

print $swf->build();

exit;
