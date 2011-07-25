package IO::SWF::Type::MATRIX;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::Bit;
use List::Util;

sub parse {
    my ($reader, $opts_href) = @_;
    my %matrix = ();

    $reader->byteAlign();
    my $hasScale = $reader->getUIBit();
    if ($hasScale) {
        my $nScaleBits = $reader->getUIBits(5);
#          $matrix{'(NScaleBits)'} = $nScaleBits;
        $matrix{'ScaleX'} = $reader->getSIBits($nScaleBits);
        $matrix{'ScaleY'} = $reader->getSIBits($nScaleBits);
    } else {
        $matrix{'ScaleX'} = 0x10000;
        $matrix{'ScaleY'} = 0x10000;
    }
    my $hasRotate = $reader->getUIBit();
    if ($hasRotate) {
        my $nRotateBits = $reader->getUIBits(5);
#          $matrix{'(NRotateBits)'} = $nRotateBits;
        $matrix{'RotateSkew0'} = $reader->getSIBits($nRotateBits);
        $matrix{'RotateSkew1'} = $reader->getSIBits($nRotateBits);
    } else  {
        $matrix{'RotateSkew0'} = 0;
        $matrix{'RotateSkew1'} = 0;
    }
    my $nTranslateBits = $reader->getUIBits(5);
    $matrix{'TranslateX'} = $reader->getSIBits($nTranslateBits);
    $matrix{'TranslateY'} = $reader->getSIBits($nTranslateBits);
    return \%matrix;
}

sub build {
    my ($writer, $matrix_href, $opts_href) = @_;
    my %matrix = ref($matrix_href) ? %{$matrix_href} : ();
    $writer->byteAlign();
    if (($matrix{'ScaleX'} != 0x10000) || ($matrix{'ScaleY'} != 0x10000)) {
        $writer->putUIBit(1); # HasScale;
        my $nScaleBits;
        if ($matrix{'ScaleX'} | $matrix{'ScaleY'}) {
            my $xNBits = $writer->need_bits_signed($matrix{'ScaleX'});
            my $yNBits = $writer->need_bits_signed($matrix{'ScaleY'});
            $nScaleBits = List::Util::max($xNBits, $yNBits);
        } else {
            $nScaleBits = 0;
        }
        $writer->putUIBits($nScaleBits, 5);
        $writer->putSIBits($matrix{'ScaleX'}, $nScaleBits);
        $writer->putSIBits($matrix{'ScaleY'}, $nScaleBits);
    } else {
        $writer->putUIBit(0); # HasScale;
    }
    if ($matrix{'RotateSkew0'} | $matrix{'RotateSkew1'}) {
        $writer->putUIBit(1); # HasRotate
        my $nRotateBits;
        if ($matrix{'RotateSkew0'} | $matrix{'RotateSkew1'}) {
            my $rs0NBits = $writer->need_bits_signed($matrix{'RotateSkew0'});
            my $rs1NBits = $writer->need_bits_signed($matrix{'RotateSkew1'});
            $nRotateBits = List::Util::max($rs0NBits, $rs1NBits);
        } else {
            $nRotateBits = 0;
        }
        $writer->putUIBits($nRotateBits, 5);
        $writer->putSIBits($matrix{'RotateSkew0'}, $nRotateBits);
        $writer->putSIBits($matrix{'RotateSkew1'}, $nRotateBits);
    } else {
        $writer->putUIBit(0); # HasRotate
    }
    my $nTranslateBits;
    if ($matrix{'TranslateX'} | $matrix{'TranslateY'}) {
        my $xNTranslateBits = $writer->need_bits_signed($matrix{'TranslateX'});
        my $yNTranslateBits = $writer->need_bits_signed($matrix{'TranslateY'});
        $nTranslateBits = List::Util::max($xNTranslateBits, $yNTranslateBits);
    } else {
        $nTranslateBits = 0;
    }
    $writer->putUIBits($nTranslateBits, 5);
    $writer->putSIBits($matrix{'TranslateX'}, $nTranslateBits);
    $writer->putSIBits($matrix{'TranslateY'}, $nTranslateBits);
}

sub string {
    my ($matrix_href, $opts_href) = @_;
    my %matrix = ref($matrix_href) ? %{$matrix_href} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $indent = 0;
    if (defined $opts{'indent'}) {
        $indent = $opts{'indent'};
    }
    my $text_fmt = << 'EOS';
%s| %3.3f %3.3f |  %3.2f
%s| %3.3f %3.3f |  %3.2f
EOS
    return  sprintf($text_fmt, 
    "\t" x $indent,
    $matrix{'ScaleX'} / 0x10000,
    $matrix{'RotateSkew0'} / 0x10000,
    $matrix{'TranslateX'} / 20,
    "\t" x $indent,
    $matrix{'RotateSkew1'} / 0x10000,
    $matrix{'ScaleY'} / 0x10000,
    $matrix{'TranslateY'} / 20);
}

1;
