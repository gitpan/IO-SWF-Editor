#!/usr/bin/perl

use strict;
use warnings;

use lib qw{../lib};
use FileHandle;
use Getopt::Long;
use IO::SWF;

our %opt = (
    'f' => undef, # file name
    'h' => undef, # hexdump
);
GetOptions(
    'f=s' => \$opt{f},
    'h'     => \$opt{h},
);

if (!$opt{f} || !-e $opt{f}) {
    print "Usage: perl swfdump.pl -f=<swf_file> [-h]\n";
    print "ex) perl swfdump.pl -f=test.swf -h\n";
    exit();
}

my $fh;
$fh = FileHandle->new("<" . $opt{f});
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $swf = IO::SWF->new();
$swf->parse($swf_data);

my %opts = ();
$opts{'hexdump'} = 1 if $opt{h};

$swf->dump(\%opts);

exit;
