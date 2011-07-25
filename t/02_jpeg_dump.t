use Test::More tests => 2;
BEGIN {
    use_ok('IO::SWF::JPEG');
}

use FindBin;
use FileHandle;

my $fh;
$fh = FileHandle->new("< $FindBin::Bin/cat.jpg");
local $/;
my $jpeg_data = $fh->getline;
$fh->close;

my $jpeg = IO::SWF::JPEG->new();
$jpeg->input($jpeg_data);

is(length($jpeg->getImageData()), 2245, 'getImageData');

exit();
