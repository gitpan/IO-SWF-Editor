package IO::SWF::Type::LINESTYLE;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::SWF::Bit;
use IO::SWF::Type::RGB;
use IO::SWF::Type::RGBA;

sub parse {
    my ($reader, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $isMorph = ($tagCode == 46) || ($tagCode == 84) ? 1 : 0;
    my %lineStyle = ();
    if (!$isMorph) {
        $lineStyle{'Width'} = $reader->getUI16LE();
        if ($tagCode < 32 ) { # 32:DefineShape3
            $lineStyle{'Color'} = IO::SWF::Type::RGB::parse($reader);
        } else {
            $lineStyle{'Color'} = IO::SWF::Type::RGBA::parse($reader);
        }
    } else {
        $lineStyle{'StartWidth'} = $reader->getUI16LE();
        $lineStyle{'EndWidth'}   = $reader->getUI16LE();
        $lineStyle{'StartColor'} = IO::SWF::Type::RGBA::parse($reader);
        $lineStyle{'EndColor'}   = IO::SWF::Type::RGBA::parse($reader);
    }
    return \%lineStyle;
}

sub build {
    my ($writer, $lineStyle_href, $opts_href) = @_;
    my %lineStyle = ref($lineStyle_href) ? %{$lineStyle_href} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $isMorph = ($tagCode == 46) || ($tagCode == 84) ? 1 : 0;
    if (!$isMorph) {
        $writer->putUI16LE($lineStyle{'Width'});
        if ($tagCode < 32 ) { # 32:DefineShape3
            IO::SWF::Type::RGB::build($writer, $lineStyle{'Color'});
        } else {
            IO::SWF::Type::RGBA::build($writer, $lineStyle{'Color'});
        }
    } else {
        $writer->putUI16LE($lineStyle{'StartWidth'});
        $writer->putUI16LE($lineStyle{'EndWidth'});
        IO::SWF::Type::RGBA::build($writer, $lineStyle{'StartColor'});
        IO::SWF::Type::RGBA::build($writer, $lineStyle{'EndColor'});
    }
    return 1;
}

sub string {
    my ($lineStyle_href, $opts_href) = @_;
    my %lineStyle = ref($lineStyle_href) ? %{$lineStyle_href} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $isMorph = ($tagCode == 46) || ($tagCode == 84) ? 1 : 0;
    my $text = '';

    if (!$isMorph) {
        my $width = $lineStyle{'Width'};
        my $color_str;
        if ($tagCode < 32 ) { # 32:DefineShape3
            $color_str = IO::SWF::Type::RGB::string($lineStyle{'Color'});
        } else {
            $color_str = IO::SWF::Type::RGBA::string($lineStyle{'Color'});
        }
        $text .= "\tWitdh: $width Color: $color_str\n";
    } else {
        my $startWidth = $lineStyle{'StartWidth'};
        my $endWidth = $lineStyle{'EndWidth'};
        my $startColorStr = IO::SWF::Type::RGBA::string($lineStyle{'StartColor'});
        my $endColorStr = IO::SWF::Type::RGBA::string($lineStyle{'EndColor'});
        $text .= "\tWitdh: $startWidth => $endWidth Color: $startColorStr => $endColorStr\n";
    }
    return $text;
}

1;
