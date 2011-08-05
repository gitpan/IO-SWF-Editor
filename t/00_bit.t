use Test::More tests => 45;
BEGIN {
    use_ok('IO::SWF::Bit');
}

my $data_length = 10;
my $data = '';
while(length($data) < 10) {
    $data .= chr(int(rand(255)));
}

my $bit = IO::SWF::Bit->new();

$bit->input($data);

# setOffset
$bit->setOffset(length($data), 0);
is($bit->_byte_offset, length($data), 'setOffset - byte_offset');

$bit->setOffset(0, 1);
is($bit->_bit_offset, 1, 'setOffset - bit_offset');

# getOffset
$bit->setOffset(0, 0);
my @offset;
@offset = $bit->getOffset();
is_deeply(\@offset, [0, 0], 'getOffset - zero');

$bit->setOffset(2, 8);
@offset = $bit->getOffset();
is_deeply(\@offset, [2, 8], 'getOffset - among');

$bit->setOffset(length($data), 0);
@offset = $bit->getOffset();
is_deeply(\@offset, [length($data), 0], 'getOffset - last');

# incrementOffset
$bit->setOffset(0, 0);
$bit->incrementOffset(0, 12);
@offset = $bit->getOffset();
is_deeply(\@offset, [1, 4], 'incrementOffset - increment bit_offset');

$bit->setOffset(0, 0);
$bit->incrementOffset(4, -12);
@offset = $bit->getOffset();
is_deeply(\@offset, [2, 4], 'incrementOffset - decrement bit_offset');

# hasNextData
$bit->setOffset(0, 0);
is($bit->hasNextData, 1, 'hasNextData - zero');

$bit->setOffset(length($data), 0);
is($bit->hasNextData, 0, 'hasNextData - last');

# byteAlign
$bit->setOffset(2, 0);
$bit->byteAlign();
@offset = $bit->getOffset();
is_deeply(\@offset, [2, 0], 'byteAlign - no align');

$bit->setOffset(2, 8);
$bit->byteAlign();
@offset = $bit->getOffset();
is_deeply(\@offset, [3, 0], 'byteAlign - align');

# put and get

# putData
$bit->input('');
$bit->putData($data);
@offset = $bit->getOffset();
is_deeply(\@offset, [length($data), 0], 'putData - check offset');

# getData
$bit->setOffset(0, 0);
is($bit->getData(0), '', 'getData - no length');
is($bit->getData(length($data)), $data, 'getData - full length');

# putUI8 getUI8
$bit->putUI8(0);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getUI8(), '0', 'putUI8 getUI8 - min');

$bit->putUI8(128);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getUI8(), '128', 'putUI8 getUI8 - among');

$bit->putUI8(255);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getUI8(), '255', 'putUI8 getUI8 - max');

# putSI8 getSI8
$bit->putSI8(0);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getSI8(), '0', 'putSI8 getSI8 - min');

$bit->putSI8(64);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getSI8(), '64', 'putSI8 getSI8 - among');

$bit->putSI8(127);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getSI8(), '127', 'putSI8 getSI8 - max');

$bit->putSI8(128);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getSI8(), '-128', 'putSI8 getSI8 - negative 1');

$bit->putSI8(-1);
$bit->setOffset($bit->_byte_offset - 1, 0);
is($bit->getSI8(), '-1', 'putSI8 getSI8 - negative 2');

# putUI16BE getUI16BE
$bit->putUI16BE(0);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getUI16BE(), '0', 'putUI16BE getUI16BE - min');

$bit->putUI16BE(256);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getUI16BE(), '256', 'putUI16BE getUI16BE - among');

$bit->putUI16BE(65535);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getUI16BE(), '65535', 'putUI16BE getUI16BE - max');

# putUI32BE getUI32BE
$bit->putUI32BE(0);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getUI32BE(), '0', 'putUI32BE getUI32BE - min');

$bit->putUI32BE(65536);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getUI32BE(), '65536', 'putUI32BE getUI32BE - among');

$bit->putUI32BE(4294967295);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getUI32BE(), '4294967295', 'putUI32BE getUI32BE - max');

# putUI16LE getUI16LE
$bit->putUI16LE(0);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getUI16LE(), '0', 'putUI16LE getUI16LE - min');

$bit->putUI16LE(256);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getUI16LE(), '256', 'putUI16LE getUI16LE - among');

$bit->putUI16LE(65535);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getUI16LE(), '65535', 'putUI16LE getUI16LE - max');

# putSI16LE getSI16LE
$bit->putSI16LE(0);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getSI16LE(), '0', 'putSI16LE getSI16LE - min');

$bit->putSI16LE(256);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getSI16LE(), '256', 'putSI16LE getSI16LE - among');

$bit->putSI16LE(32767);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getSI16LE(), '32767', 'putSI16LE getSI16LE - max');

$bit->putSI16LE(32768);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getSI16LE(), '-32768', 'putSI16LE getSI16LE - negative 1');

$bit->putSI16LE(-1);
$bit->setOffset($bit->_byte_offset - 2, 0);
is($bit->getSI16LE(), '-1', 'putSI16LE getSI16LE - negative 2');

# putUI32LE getUI32LE
$bit->putUI32LE(0);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getUI32LE(), '0', 'putUI32LE getUI32LE - min');

$bit->putUI32LE(65536);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getUI32LE(), '65536', 'putUI32LE getUI32LE - among');

$bit->putUI32LE(4294967295);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getUI32LE(), '4294967295', 'putUI32LE getUI32LE - max');

# putSI32LE getSI32LE
$bit->putSI32LE(0);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getSI32LE(), '0', 'putSI32LE getSI32LE - min');

$bit->putSI32LE(65536);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getSI32LE(), '65536', 'putSI32LE getSI32LE - among');

$bit->putSI32LE(2147483647);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getSI32LE(), '2147483647', 'putSI32LE getSI32LE - max');

$bit->putSI32LE(2147483648);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getSI32LE(), '-2147483648', 'putSI32LE getSI32LE - negative 1');

$bit->putSI32LE(-1);
$bit->setOffset($bit->_byte_offset - 4, 0);
is($bit->getSI32LE(), '-1', 'putSI32LE getSI32LE - negative 2');
