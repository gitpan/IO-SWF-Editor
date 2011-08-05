package IO::SWF::Type::RGBA;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::SWF::Bit;

sub parse {
    my ($reader, $opts_href) = @_;
    my %rgba = ();
    $rgba{'Red'} = $reader->getUI8();
    $rgba{'Green'} = $reader->getUI8();
    $rgba{'Blue'} = $reader->getUI8();
    $rgba{'Alpha'} = $reader->getUI8();
    return \%rgba;
}

sub build {
    my ($writer, $rgba_href, $opts_href) = @_;
    my %rgba = ref($rgba_href) ? %{$rgba_href} : ();
    $writer->putUI8($rgba{'Red'});
    $writer->putUI8($rgba{'Green'});
    $writer->putUI8($rgba{'Blue'});
    $writer->putUI8($rgba{'Alpha'});
}

sub string {
    my ($color_href, $opts_href) = @_;
    my %color = ref($color_href) ? %{$color_href} : ();
    return sprintf("#%02x%02x%02x(%02x)", $color{'Red'}, $color{'Green'}, $color{'Blue'}, $color{'Alpha'});
}

1;
