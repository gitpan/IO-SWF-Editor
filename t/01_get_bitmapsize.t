use Test::More tests => 2;
BEGIN {
    use_ok('IO::SWF::Bitmap');
}

use FindBin;
use FileHandle;

my $fh;
$fh = FileHandle->new("< $FindBin::Bin/cat.jpg");
local $/;
my $bitmap_data = $fh->getline;
$fh->close;

my %ret = IO::SWF::Bitmap::get_bitmapsize($bitmap_data);

my %expected = (
    width  => 240,
    height => 360,
);

is_deeply(\%ret, \%expected, 'get_bitmapsize');

exit();
