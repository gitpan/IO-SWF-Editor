package IO::SWF::Type::String;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::SWF::Bit;

sub parse {
    my ($reader, $opts_href) = @_;
    my $str = '';
    while ($reader->hasNextData(1)) {
        my $c = $reader->getData(1);
        if ($c eq "\0") {
            last;
        }
        $str .= $c;
    }
    return $str;
}

sub build {
    my ($writer, $str, $opts_ref) = @_;
    my @strs = split('\0', $str);
    $str = $strs[0];
    $writer->putData($str."\0", length($str) + 1);
}

sub string {
    my ($str, $opts_href) = @_;
    return $str;
}

1;
