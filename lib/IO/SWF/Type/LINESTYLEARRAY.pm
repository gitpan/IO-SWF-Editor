package IO::SWF::Type::LINESTYLEARRAY;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::Bit;
use IO::SWF::Type::LINESTYLE;

sub parse {
    my ($reader, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my @lineStyles = ();
    # LineStyle
    my $lineStyleCount = $reader->getUI8();
    if (($tagCode > 2) && ($lineStyleCount == 0xff)) {
        # DefineShape2 以降は 0xffff サイズまで扱える
        $lineStyleCount = $reader->getUI16LE();
    }
    for (my $i = 0 ; $i < $lineStyleCount ; $i++) {
        my $lineStyle = IO::SWF::Type::LINESTYLE::parse($reader, \%opts);
        push @lineStyles, $lineStyle;
    }
    return \@lineStyles;
}

sub build {
    my ($writer, $lineStyles_aref, $opts_href) = @_;
    my @lineStyles = ref($lineStyles_aref) ? @{$lineStyles_aref} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $lineStyleCount = scalar(@lineStyles);
    if ($lineStyleCount < 0xff) {
        $writer->putUI8($lineStyleCount);
    } else {
        $writer->putUI8(0xff);
        if ($tagCode > 2) {
            $writer->putUI16LE($lineStyleCount);
        } else {
            $lineStyleCount = 0xff; # DefineShape(1)
        }
    }
    foreach my $lineStyle (@lineStyles) {
        IO::SWF::Type::LINESTYLE::build($writer, $lineStyle, \%opts);
    }
    return 1;
}

sub string {
    my ($lineStyles_aref, $opts_href) = @_;
    my @lineStyles = ref($lineStyles_aref) ? @{$lineStyles_aref} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $text = '';
    foreach my $lineStyle (@lineStyles) {
        $text .= IO::SWF::Type::LINESTYLE::string($lineStyle, \%opts);
    }
    return $text;
}

1;
