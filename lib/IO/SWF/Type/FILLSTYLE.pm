package IO::SWF::Type::FILLSTYLE;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::SWF::Bit;
use IO::SWF::Type::MATRIX;
use IO::SWF::Type::RGB;
use IO::SWF::Type::RGBA;

sub parse {
    my ($reader, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();
    my $tagCode = $opts{'tagCode'};
    my $isMorph = ($tagCode == 46) || ($tagCode == 84) ? 1 : 0;

    my %fillStyle;
    my $fillStyleType = $reader->getUI8();
    $fillStyle{'FillStyleType'} = $fillStyleType;
    if ($fillStyleType == 0x00) {
        # 0x00: // solid fill
        if (!$isMorph) {
            if ($tagCode < 32 ) { # 32:DefineShape3
                $fillStyle{'Color'} = IO::SWF::Type::RGB::parse($reader);
            } else {
                $fillStyle{'Color'} = IO::SWF::Type::RGBA::parse($reader);
            }
        } else {
                $fillStyle{'StartColor'} = IO::SWF::Type::RGBA::parse($reader);
                $fillStyle{'EndColor'} = IO::SWF::Type::RGBA::parse($reader);
        }
    }
    elsif ($fillStyleType == 0x10 || $fillStyleType == 0x12) {
        # 0x10: // linear gradient fill
        # 0x12: // radial gradient fill
        if (!$isMorph) {
            $fillStyle{'GradientMatrix'} = IO::SWF::Type::MATRIX::parse($reader);
        } else {
            $fillStyle{'StartGradientMatrix'} = IO::SWF::Type::MATRIX::parse($reader);
            $fillStyle{'EndGradientMatrix'} = IO::SWF::Type::MATRIX::parse($reader);
        }
        $reader->byteAlign();
        my $numGradients;
        if (!$isMorph) {
            $fillStyle{'SpreadMode'} = $reader->getUIBits(2);
            $fillStyle{'InterpolationMode'} = $reader->getUIBits(2);
            $numGradients = $reader->getUIBits(4);
        } else {
            $numGradients = $reader->getUI8();
        }
        my @GradientRecords = ();
        for (my $j = 0 ; $j < $numGradients ; $j++) {
            my %gradientRecord ;
            if (!$isMorph) {
                $gradientRecord{'Ratio'} = $reader->getUI8();
                if ($tagCode < 32 ) { # 32:DefineShape3
                    $gradientRecord{'Color'} = IO::SWF::Type::RGB::parse($reader);
                } else {
                    $gradientRecord{'Color'} = IO::SWF::Type::RGBA::parse($reader);
                }
            } else { # Morph
                $gradientRecord{'StartRatio'} = $reader->getUI8();
                $gradientRecord{'EndRatio'} = $reader->getUI8();
                $gradientRecord{'StartColor'} = IO::SWF::Type::RGBA::parse($reader);
                $gradientRecord{'EndColor'} = IO::SWF::Type::RGBA::parse($reader);
            }
            push @GradientRecords, \%gradientRecord;
        }
        $fillStyle{'GradientRecords'} = \@GradientRecords;
    }
    # case 0x13: // focal gradient fill // 8 and later
    elsif ($fillStyleType == 0x40 || $fillStyleType == 0x41 || $fillStyleType == 0x42 || $fillStyleType == 0x43) {
        # 0x40: // repeating bitmap fill
        # 0x41: // clipped bitmap fill
        # 0x42: // non-smoothed repeating bitmap fill
        # 0x43: // non-smoothed clipped bitmap fill
        $fillStyle{'BitmapId'} = $reader->getUI16LE();
        if (!$isMorph) {
            $fillStyle{'BitmapMatrix'} = IO::SWF::Type::MATRIX::parse($reader);
        } else {
            $fillStyle{'StartBitmapMatrix'} = IO::SWF::Type::MATRIX::parse($reader);
            $fillStyle{'EndBitmapMatrix'} = IO::SWF::Type::MATRIX::parse($reader);
        }
    }
    else {
        die "Unknown FillStyleType=$fillStyleType tagCode=$tagCode";
    }
    return \%fillStyle;
}

sub build {
    my ($writer, $fillStyle_href, $opts_href) = @_;
    my %fillStyle = ref($fillStyle_href) ? %{$fillStyle_href} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $isMorph = ($tagCode == 46) || ($tagCode == 84) ? 1 : 0;

    my $fillStyleType = $fillStyle{'FillStyleType'};
    $writer->putUI8($fillStyleType);
    if ($fillStyleType == 0x00) {
        # 0x00: // solid fill
        if ($tagCode < 32 ) { # 32:DefineShape3
            IO::SWF::Type::RGB::build($writer, $fillStyle{'Color'});
        } else {
            IO::SWF::Type::RGBA::build($writer, $fillStyle{'Color'});
        }
    }
    elsif ($fillStyleType == 0x10 || $fillStyleType == 0x12) {
        # 0x10: // linear gradient fill
        # 0x12: // radial gradient fill
        IO::SWF::Type::MATRIX::build($writer, $fillStyle{'GradientMatrix'});
        $writer->byteAlign();
        $writer->putUIBits($fillStyle{'SpreadMode'}, 2);
        $writer->putUIBits($fillStyle{'InterpolationMode'}, 2);
        my $numGradients = scalar(@{$fillStyle{'GradientRecords'}});
        $writer->putUIBits($numGradients , 4);
        foreach my $gradientRecord (@{$fillStyle{'GradientRecords'}}) {
            $writer->putUI8($gradientRecord->{'Ratio'});
            if ($tagCode < 32 ) { # 32:DefineShape3
                IO::SWF::Type::RGB::build($writer, $gradientRecord->{'Color'});
            } else {
                IO::SWF::Type::RGBA::build($writer, $gradientRecord->{'Color'});
            }
        }
    }
    # case 0x13: // focal gradient fill // 8 and later
    elsif ($fillStyleType == 0x40 || $fillStyleType == 0x41 || $fillStyleType == 0x42 || $fillStyleType == 0x43) {
        # 0x40: // repeating bitmap fill
        # 0x41: // clipped bitmap fill
        # 0x42: // non-smoothed repeating bitmap fill
        # 0x43: // non-smoothed clipped bitmap fill
        $writer->putUI16LE($fillStyle{'BitmapId'});
        IO::SWF::Type::MATRIX::build($writer, $fillStyle{'BitmapMatrix'});
    }
    else {
    #  default:
    #    throw new IO_SWF_Exception("Unknown FillStyleType=$fillStyleType tagCode=$tagCode");
    }
    return 1;
}

sub string {
    my ($fillStyle_href, $opts_href) = @_;
    my %fillStyle = ref($fillStyle_href) ? %{$fillStyle_href} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $isMorph = ($tagCode == 46) || ($tagCode == 84) ? 1 : 0;

    my $text = '';
    my $fillStyleType = $fillStyle{'FillStyleType'};
    if ($fillStyleType == 0x00) {
        # 0x00: // solid fill
        my $color = $fillStyle{'Color'};
        my $color_str;
        if ($tagCode < 32 ) { # 32:DefineShape3
            $color_str = IO::SWF::Type::RGB::string($color);
        } else {
            $color_str = IO::SWF::Type::RGBA::string($color);
        }
        $text .= "\tsolid fill: $color_str\n";
    }
    elsif ($fillStyleType == 0x10 || $fillStyleType == 0x12) {
        # 0x10: // linear gradient fill
        # 0x12: // radial gradient fill
        if ($fillStyleType == 0x10) {
            $text .= "\tlinear gradient fill\n";
        } else {
            $text .= "\tradial gradient fill\n";
        }
        my %opts = ('indent' => 2);
        if (!$isMorph) {
            my $matrix_str = IO::SWF::Type::MATRIX::string($fillStyle{'GradientMatrix'}, \%opts);
            $text .= $matrix_str . "\n";
            my $spreadMode = $fillStyle{'SpreadMode'};
            my $interpolationMode = $fillStyle{'InterpolationMode'};
        } else {
            # my $matrix_str = IO::SWF::Type::MATRIX::string($fillStyle{'StartGradientMatrix'}, $opts);
            my $matrix_str = IO::SWF::Type::MATRIX::string($fillStyle{'EndGradientMatrix'}, \%opts);
            $text .= $matrix_str . "\n";
        }

        foreach my $gradientRecord (@{$fillStyle{'GradientRecords'}}) {
            if (!$isMorph) {
                my $ratio = $gradientRecord->{'Ratio'};
                my $color = $gradientRecord->{'Color'};
                my $color_str;
                if ($tagCode < 32 ) { # 32:DefineShape3
                    $color_str = IO::SWF::Type::RGB::string($color);
                } else {
                    $color_str = IO::SWF::Type::RGBA::string($color);
                }
                $text .= "\t\tRatio: $ratio Color:$color_str\n";
            } else {
                my $startRatio = $gradientRecord->{'StartRatio'};
                my $endRatio   = $gradientRecord->{'EndRatio'};
                my $startColorStr = IO::SWF::Type::RGBA::string($gradientRecord->{'StartColor'});
                my $endColorStr = IO::SWF::Type::RGBA::string($gradientRecord->{'EndColor'});
                $text .= "\t\tRatio: $startRatio => $endRatio Color:$startColorStr => $endColorStr\n";
            }
        }
    }
    elsif ($fillStyleType == 0x40 || $fillStyleType == 0x41 || $fillStyleType == 0x42 || $fillStyleType == 0x43) {
        # 0x40: // repeating bitmap fill
        # 0x41: // clipped bitmap fill
        # 0x42: // non-smoothed repeating bitmap fill
        # 0x43: // non-smoothed clipped bitmap fill
        $text .= "\tBigmap($fillStyleType): ";
        $text .= "  BitmapId: ".$fillStyle{'BitmapId'}."\n";
        my $matrix_str;
        if (!$isMorph) {
            $text .= "\tBitmapMatrix:\n";
            my %opts = ('indent' => 2);
            $matrix_str = IO::SWF::Type::MATRIX::string($fillStyle{'BitmapMatrix'}, \%opts);
            $text .= $matrix_str . "\n";
        } else {
            my %opts = ('indent' => 2);
            $text .= "\tStartBitmapMatrix:\n";
            $matrix_str = IO::SWF::Type::MATRIX::string($fillStyle{'StartBitmapMatrix'}, \%opts);
            $text .= $matrix_str . "\n";
            $text .= "\tEndBitmapMatrix:\n";
            $matrix_str = IO::SWF::Type::MATRIX::string($fillStyle{'EndBitmapMatrix'}, \%opts);
            $text .= $matrix_str . "\n";
        }
    }
    else {
        # default:
        $text .= "Unknown FillStyleType($fillStyleType)\n";
    }
    return $text;
}

1;
