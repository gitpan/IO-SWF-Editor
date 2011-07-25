package IO::SWF::Type::Float;

use strict;
use warnings;

sub parse {
    my ($reader, $opts_href) = @_;
    my $data = $reader->getData(4);
    my @unpacked_data = unpack('f', $data);
    return $unpacked_data[0];
}

sub build {
    my ($writer, $value, $opts_href) = @_;
    my $data = pack('f', $value);
    $writer->putData($data, 4);
}

sub string {
    my ($value, $opts_href) = @_;
    return sprintf("(Float)%f", $value);
}

1;
