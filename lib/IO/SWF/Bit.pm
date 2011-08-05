package IO::SWF::Bit;

#
# This module is transport from <http://openpear.org/package/IO_Bit>
#

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors( qw(
    _data
    _byte_offset
    _bit_offset
    _hash
));

sub new {
    my ($class, $args) = @_;
    my $self;
    if(ref $args eq 'HASH') {
        $self = $class->SUPER::new($args);
    }else{
        $self = $class->SUPER::new;
        $self->input('');
    }
    return $self;
}

###
#
# data i/o method
#
# ##
sub input {
    my ($self, $data) = @_;
    $self->_data($data);
    $self->_byte_offset(0);
    $self->_bit_offset(0);
}

sub output {
    my ($self, $offset) = @_;
    $offset ||= 0;
    my $output_len = $self->_byte_offset;
    if ($self->_bit_offset > 0) {
        $output_len++;
    }
    if (length($self->_data) == $output_len) {
        return $self->_data;
    }
    return substr($self->_data, $offset, $output_len);
}

###
#
# offset method
# 
###
sub hasNextData {
    my ($self, $length) = @_;
    $length ||= 1;
    if (length($self->_data) < $self->_byte_offset + $length) {
        return 0;
    }
    return 1;
}

sub setOffset {
    my ($self, $byte_offset, $bit_offset) = @_;
    $self->_byte_offset($byte_offset);
    $self->_bit_offset($bit_offset);
    return 1;
}

sub incrementOffset {
    my ($self, $byte_offset, $bit_offset) = @_;
    $self->_byte_offset($self->_byte_offset + $byte_offset);
    $self->_bit_offset($self->_bit_offset + $bit_offset);
    while ($self->_bit_offset >= 8) {
        $self->_byte_offset($self->_byte_offset + 1);
        $self->_bit_offset($self->_bit_offset - 8);
    }
    while ($self->_bit_offset < 0) {
        $self->_byte_offset($self->_byte_offset - 1);
        $self->_bit_offset($self->_bit_offset + 8);
    }
    return 1;
}

sub getOffset {
    my $self = shift;
    return ($self->_byte_offset, $self->_bit_offset);
}

sub byteAlign {
    my $self = shift;
    if ($self->_bit_offset > 0) {
        $self->_byte_offset($self->_byte_offset + 1);
        $self->_bit_offset(0);
    }
}

###
#
# get method
#
###
sub getData {
    my ($self, $length) = @_;

    $self->byteAlign();
    my $data = substr($self->_data, $self->_byte_offset, $length);
    $self->_byte_offset($self->_byte_offset + length($data));
    return $data;
}

sub getDataUntil {
    my ($self, $delimiter) = @_;

    $self->byteAlign();
    my $pos = index($self->_data, $delimiter, $self->_byte_offset);
    my ($length, $delim_len);
    if ($pos < 0) {
        $length = length($self->_data) - $self->_byte_offset;
        $delim_len = 0;
    } else {
        $length = $pos - $self->_byte_offset;
        $delim_len = length($delimiter);
    }
    my $data = $self->getData($length);
    if ($delim_len > 0) {
        $self->_byte_offset($self->_byte_offset + $delim_len);
    }
    return $data;
}

sub getUI8 {
    my $self = shift;
    $self->byteAlign();
    my $value = unpack('C', substr($self->_data, $self->_byte_offset, 1));
    $self->_byte_offset($self->_byte_offset + 1);
    return $value;
}

sub getSI8 {
    my $self = shift;
    my $value = $self->getUI8();
    $value -= (1<<8) if ($value>=(1<<7));
    return $value;
}

sub getUI16BE {
    my $self = shift;
    $self->byteAlign();
    my $ret = unpack('n', substr($self->_data, $self->_byte_offset, 2));
    $self->_byte_offset($self->_byte_offset + 2);
    return $ret;
}

sub getUI32BE {
    my $self = shift;
    $self->byteAlign();
    my $ret = unpack('N', substr($self->_data, $self->_byte_offset, 4));
    $self->_byte_offset($self->_byte_offset + 4);
    return $ret;
}

sub getUI16LE {
    my $self = shift;
    $self->byteAlign();
    my $ret = unpack('v', substr($self->_data, $self->_byte_offset, 2));
    $self->_byte_offset($self->_byte_offset + 2);
    return $ret;
}

sub getSI16LE {
    my $self = shift;
    my $value = $self->getUI16LE();
    $value -= (1<<16) if ($value>=(1<<15));
    return $value;
}

sub getUI32LE {
    my $self = shift;
    $self->byteAlign();
    my $ret = unpack('V', substr($self->_data, $self->_byte_offset, 4));
    $self->_byte_offset($self->_byte_offset + 4);
    return $ret;
}

sub getSI32LE {
    my $self = shift;
    my $value = $self->getUI32LE();
    $value -= (2**32) if ($value>=(2**31));
    return $value;
}

sub getUIBit {
    my $self = shift;
    if (length($self->_data) <= $self->_byte_offset) {
        my $data_len = length($self->_data);
        my $offset = $self->_byte_offset;
        die "getUIBit: $data_len <= $offset";
    }
    my $value = ord(substr($self->_data, $self->_byte_offset, 1));
    $value = 1 & ($value >> (7 - $self->_bit_offset)); # MSB(Bit) first
    $self->_bit_offset($self->_bit_offset + 1);
    if (8 <= $self->_bit_offset) {
        $self->_byte_offset($self->_byte_offset + 1);
        $self->_bit_offset(0);
    }
    return $value;
}

sub getUIBits {
    my ($self, $width) = @_;
    my $value = 0;
    for (my $i = 0 ; $i < $width ; $i++) {
        $value <<= 1;
        $value |= $self->getUIBit();
    }
    return $value;
}

sub getSIBits {
    my ($self, $width) = @_;
    my $value = $self->getUIBits($width);
    my $msb = $value & (1 << ($width - 1));
    if ($msb) {
        my $bitmask = (2 * $msb) - 1;
        $value = - ($value ^ $bitmask) - 1;
    }
    return $value;
}

# start with the LSB(least significant bit)
sub getUIBitLSB {
    my $self = shift;
    if (length($self->_data) <= $self->_byte_offset) {
        my $data_len = length($self->_data);
        my $offset = $self->_byte_offset;
        die "getUIBitLSB: $data_len <= $offset";
    }
    my $value = ord(substr($self->_data, $self->_byte_offset, 1));
    $value = 1 & ($value >> $self->_bit_offset); # LSB(Bit) first
    $self->_bit_offset($self->_bit_offset + 1);
    if (8 <= $self->_bit_offset) {
        $self->_byte_offset($self->_byte_offset + 1);
        $self->_bit_offset(0);
    }
    return $value;
}

sub getUIBitsLSB {
    my ($self, $width) = @_;
    my $value = 0;
    for (my $i = 0 ; $i < $width ; $i++) {
        $value |= $self->getUIBitLSB() << $i; # LSB(Bit) order
    }
    return $value;
}

sub getSIBitsLSB {
    my ($self, $width) = @_;
    my $value = $self->getUIBitsLSB($width);
    my $msb = $value & (1 << ($width - 1));
    if ($msb) {
        my $bitmask = (2 * $msb) - 1;
        $value = - ($value ^ $bitmask) - 1;
    }
    return $value;
}

###
#
# put method
#
###
sub putData {
    my ($self, $data) = @_;
    $self->byteAlign();
    $self->_data($self->_data . $data);
    $self->_byte_offset($self->_byte_offset + length($data));
    return 1;
}

sub putUI8 {
    my ($self, $value) = @_;
    $self->byteAlign();
    $self->_data($self->_data . pack('C', $value));
    $self->_byte_offset($self->_byte_offset + 1);
    return 1;
}

sub putSI8 {
    my ($self, $value) = @_;
    if ($value < 0) {
        $value = $value + 0x100; # 2-negative reverse
    }
    return $self->putUI8($value);
}

sub putUI16BE {
    my ($self, $value) = @_;
    $self->byteAlign();
    $self->_data($self->_data . pack('n', $value));
    $self->_byte_offset($self->_byte_offset + 2);
    return 1;
}

sub putUI32BE {
    my ($self, $value) = @_;
    $self->byteAlign();
    $self->_data($self->_data . pack('N', $value));
    $self->_byte_offset($self->_byte_offset + 4);
    return 1;
}

sub putUI16LE {
    my ($self, $value) = @_;
    $self->byteAlign();
    $self->_data($self->_data . pack('v', $value));
    $self->_byte_offset($self->_byte_offset + 2);
    return 1;
}

sub putSI16LE {
    my ($self, $value) = @_;
    if ($value < 0) {
        $value = $value + 0x10000; # 2-negative reverse
    }
    return $self->putUI16LE($value);
}

sub putUI32LE {
    my ($self, $value) = @_;
    $self->byteAlign();
    $self->_data($self->_data . pack('V', $value));
    $self->_byte_offset($self->_byte_offset + 4);
    return 1;
}

sub putSI32LE {
    my ($self, $value) = @_;
    return $self->putUI32LE($value); # XXX
}

sub _allocData {
    my ($self, $need_data_len) = @_;
    if (!defined $need_data_len) {
        $need_data_len = $self->_byte_offset;
    }
    my $data_len = length($self->_data);
    if ($data_len < $need_data_len) {
        my $buff = '';
        while(length($buff) < $need_data_len - $data_len) { $buff .= chr(0) };
        $self->_data($self->_data . $buff);
    }
    return 1;
}

sub putUIBit {
    my ($self, $bit) = @_;
    $self->_allocData($self->_byte_offset + 1);
    if ($bit > 0) {
        my $value = ord(substr($self->_data, $self->_byte_offset, 1));
        $value |= 1 << (7 - $self->_bit_offset);
        my $new_data = $self->_data;
        substr($new_data, $self->_byte_offset, 1, chr($value));
        $self->_data($new_data);
    }
    $self->_bit_offset($self->_bit_offset + 1);
    if (8 <= $self->_bit_offset) {
        $self->_byte_offset($self->_byte_offset + 1);
        $self->_bit_offset(0);
    }
    return 1;
}

sub putUIBits {
    my ($self, $value, $width) = @_;
    for (my $i = $width - 1 ; $i >= 0 ; $i--) {
        my $bit = ($value >> $i) & 1;
        my $ret = $self->putUIBit($bit);
        if (!$ret) {
            return $ret;
        }
    }
    return 1;
}

sub putSIBits {
    my ($self, $value, $width) = @_;
    if ($value < 0) {
        my $msb = 1 << ($width - 1);
        my $bitmask = (2 * $msb) - 1;
        $value = (-$value  - 1) ^ $bitmask;
    }
    return $self->putUIBits($value, $width);
}

# start with the LSB(least significant bit)
sub putUIBitLSB {
    my ($self, $bit) = @_;
    $self->_allocData($self->_byte_offset + 1);
    if ($bit > 0) {
        my $value = ord(substr($self->_data, $self->_byte_offset, 1));
        $value |= 1 << $self->_bit_offset;  # LSB(Bit) first
        my $new_data = $self->_data;
        substr($new_data, $self->_byte_offset, length($value), chr($value));
        $self->_data($new_data);
    }
    $self->_bit_offset($self->_bit_offset + 1);
    if (8 <= $self->_bit_offset) {
        $self->_byte_offset($self->_byte_offset + 1);
        $self->_bit_offset(0);
    }
    return 1;
}

sub putUIBitsLSB {
    my ($self, $value, $width) = @_;
    for (my $i = 0 ;  $i < $width ; $i--) { # LSB(Bit) order
        my $bit = ($value >> $i) & 1;
        my $ret = $self->putUIBit($bit);
        if (!$ret) {
            return $ret;
        }
    }
    return 1;
}

sub putSIBitsLSB {
    my ($self, $value, $width) = @_;
    if ($value < 0) {
        my $msb = 1 << ($width - 1);
        my $bitmask = (2 * $msb) - 1;
        $value = (-$value  - 1) ^ $bitmask;
    }
    return $self->putUIBits($value, $width);
}

###
#
# set method
#
###
sub setUI32LE {
    my ($self, $value, $byte_offset) = @_;
    my $data = pack('V', $value);
    my $new_data = $self->_data;
    substr($new_data, $byte_offset, length($data), $data);
    $self->_data($new_data);
    return 1;
}

###
#
# need bits
#
###
sub need_bits_unsigned {
    my ($self, $n) = @_;
    my $i;
    for ($i = 0 ; $n ; $i++) {
        $n >>= 1;
    }
    return $i;
}

sub need_bits_signed {
    my ($self, $n) = @_;
    my $ret;
    if ($n < -1) {
        $n = -1 - $n;
    }
    if ($n >= 0) {
        my $i;
        for ($i = 0 ; $n ; $i++) {
            $n >>= 1;
        }
        $ret = 1 + $i;
    } else { # $n == -1
        $ret = 1;
    }
    return $ret;
}

#
# general purpose hexdump routine
#
sub hexdump {
    my ($self, $offset, $length, $limit) = @_;
    print("             0  1  2  3  4  5  6  7   8  9  a  b  c  d  e  f  0123456789abcdef\n");
    my $dump_str = '';
    my $i;
    if ($offset % 0x10) {
        printf("0x%08x ", $offset - ($offset % 0x10));
        $dump_str = " " x ($offset % 0x10);
    }
    for ($i = 0; $i < $offset % 0x10; $i++) {
        if ($i == 0) {
            print ' ';
        }
        if ($i == 8) {
            print ' ';
        }
        print '   ';
    }
    for ($i = $offset ; $i < $offset + $length; $i++) {
        if ((defined($limit)) && ($i >= $offset + $limit)) {
            last;
        }
        if (($i % 0x10) == 0) {
            printf("0x%08x  ", $i);
        }
        if ($i%0x10 == 8) {
            print ' ';
        }
        if ($i < length($self->_data)) {
            my $chr = substr($self->_data, $i, 1);
            my $value = ord($chr);
            if ((0x20 < $value) && ($value < 0x7f)) { # XXX: printable
                $dump_str .= $chr;
            } else {
                $dump_str .= ' ';
            }
            printf("%02x ", $value);
        } else {
            $dump_str .= ' ';
            print '   ';
        }
        if (($i % 0x10) == 0x0f) {
            print " ";
            print $dump_str;
            print "\n";
            $dump_str = '';
        }
    }
    if (($i % 0x10) != 0) {
        print ' ' x (3 * (0x10 - ($i % 0x10)));
        if ($i < 8) {
            print ' ';
        }
        print " ";
        print $dump_str;
        print "\n";
    }
    if ((defined($limit)) && ($i >= $offset + $limit)) {
        print "...(truncated)...\n";
    }
}

1;

__END__
