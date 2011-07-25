package IO::SWF::Type::FILLSTYLEARRAY;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::Bit;
use IO::SWF::Type::FILLSTYLE;

sub parse {
    my ($reader, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();
    my $tagCode = $opts{'tagCode'};
    my @fillStyles = ();

    # FillStyle
    my $fillStyleCount = $reader->getUI8();
    if (($tagCode > 2) && ($fillStyleCount == 0xff)) {
       # DefineShape2 以降は 0xffff サイズまで扱える
       $fillStyleCount = $reader->getUI16LE();
    }
    for (my $i = 0 ; $i < $fillStyleCount ; $i++) {
        my $style = IO::SWF::Type::FILLSTYLE::parse($reader, \%opts);
        push @fillStyles, $style;
    }
    return \@fillStyles;
}

sub build {
    my ($writer, $fillStyles_aref, $opts_href) = @_;
    my @fillStyles = ref($fillStyles_aref) ? @{$fillStyles_aref} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $fillStyleCount = scalar(@fillStyles);
    if ($fillStyleCount < 0xff) {
        $writer->putUI8($fillStyleCount);
    } else {
        $writer->putUI8(0xff);
        if ($tagCode > 2) {
            $writer->putUI16LE($fillStyleCount);
        } else {
            $fillStyleCount = 0xff; # DefineShape(1)
        }
    }
    foreach my $fillStyle (@fillStyles) {
        IO::SWF::Type::FILLSTYLE::build($writer, $fillStyle, \%opts);
    }
    return 1;
}

sub string {
    my ($fillStyles_aref, $opts_href) = @_;
    my @fillStyles = ref($fillStyles_aref) ? @{$fillStyles_aref} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $text = '';
    foreach my $fillStyle (@fillStyles) {
        $text .= IO::SWF::Type::FILLSTYLE::string($fillStyle, \%opts);
    }
    return $text;
}

1;
