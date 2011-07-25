package IO::SWF::Type::Double;

use strict;
use warnings;

sub parse {
    my ($reader, $opts_href) = @_;
    my $data = $reader->getData(8);
    my @unpacked_data = unpack('d', $data);
    return $unpacked_data[0];
}

sub build {
    my ($writer, $value, $opts_href) = @_;
    my $data = pack('d', $value);
    $writer->putData($data, 8);
}

sub string {
    my ($value, $opts_href) = @_;
    return sprintf("(Double)%d", $value);
}

1;
