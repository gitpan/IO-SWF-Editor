package IO::SWF::Type::RGB;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::Bit;

sub parse {
    my ($reader, $opts_href) = @_;
    my %rgb = ();
    $rgb{'Red'} = $reader->getUI8();
    $rgb{'Green'} = $reader->getUI8();
    $rgb{'Blue'} = $reader->getUI8();
    return \%rgb;
}

sub build {
    my ($writer, $rgb_href, $opts_href) = @_;
    my %rgb = ref($rgb_href) ? %{$rgb_href} : ();
    $writer->putUI8($rgb{'Red'});
    $writer->putUI8($rgb{'Green'});
    $writer->putUI8($rgb{'Blue'});
}

sub string {
    my ($color_href, $opts_href) = @_;
    my %color = ref($color_href) ? %{$color_href} : ();
    return sprintf("#%02x%02x%02x", $color{'Red'}, $color{'Green'}, $color{'Blue'});
}

1;
