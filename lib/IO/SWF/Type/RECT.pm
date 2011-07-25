package IO::SWF::Type::RECT;

use strict;
use warnings;

use IO::Bit;
use IO::SWF::Type;
use List::Util;

sub parse {
    my ($reader, $opts_href) = @_;
    my %frameSize = ();
    $reader->byteAlign();
    my $nBits = $reader->getUIBits(5);
    $frameSize{'Xmin'} = $reader->getSIBits($nBits);
    $frameSize{'Xmax'} = $reader->getSIBits($nBits);
    $frameSize{'Ymin'} = $reader->getSIBits($nBits);
    $frameSize{'Ymax'} = $reader->getSIBits($nBits) ;
    return \%frameSize; 
}

sub build {
    my ($writer, $frameSize_href, $opts_href) = @_;
    my %frameSize = ref($frameSize_href) ? %{$frameSize_href} : ();

    my $nBits = 0;
    foreach my $key (keys %frameSize) {
        my $size = $frameSize{$key} || 0;
        my $bits;
        if ($size == 0){
            $bits = 0;
        } else {
            $bits = $writer->need_bits_signed($size);
        }
        $nBits = List::Util::max($nBits, $bits);
    }
    $writer->byteAlign();
    $writer->putUIBits($nBits, 5);
    $writer->putSIBits($frameSize{'Xmin'}, $nBits);
    $writer->putSIBits($frameSize{'Xmax'}, $nBits);
    $writer->putSIBits($frameSize{'Ymin'}, $nBits);
    $writer->putSIBits($frameSize{'Ymax'}, $nBits);
}

sub string {
    my ($rect_href, $opts_href) = @_;
    my %rect = ref($rect_href) ? %{$rect_href} : ();
    return "Xmin: " .($rect{'Xmin'} / 20).
           " Xmax: ".($rect{'Xmax'} / 20).
           " Ymin: ".($rect{'Ymin'} / 20).
           " Ymax: ".($rect{'Ymax'} / 20);
}

1;
