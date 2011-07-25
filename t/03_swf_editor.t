use Test::More tests => 5;
BEGIN {
    use_ok('IO::SWF::Editor');
}

use FindBin;
use FileHandle;

my $fh;
$fh = FileHandle->new("< $FindBin::Bin/base.swf");
local $/;
my $swf_data = $fh->getline;
$fh->close;

my $swf = IO::SWF::Editor->new();
$swf->parse($swf_data);

my $copy_output = $swf->build();

is(length($copy_output), 6012, 'copy');

$swf->rebuild();

my $rebuild_output = $swf->build();

is(length($copy_output), 6012, 'rebuild');

my %count_table = $swf->countShapeEdges();
my %count_table_expected = (
    2 => 4,
    4 => 8,
);

is_deeply(\%count_table, \%count_table_expected, 'countShapeEdges');

$swf->setCharacterId($swf_data);

$fh = FileHandle->new("< $FindBin::Bin/wake.jpg");
local $/;
my $bitmap_data = $fh->getline;
$fh->close;

my $ret = $swf->replaceBitmapData(1, $bitmap_data);

my $replace_output = $swf->build();

is (length($replace_output), 5821, 'replaceBitmapData');

exit();
