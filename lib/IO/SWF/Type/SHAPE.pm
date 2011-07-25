package IO::SWF::Type::SHAPE;

use strict;
use warnings;

use base 'IO::SWF::Type';

use List::Util;
use IO::Bit;
use IO::SWF::Type::FILLSTYLEARRAY;
use IO::SWF::Type::LINESTYLEARRAY;

sub parse {
    my ($reader, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();
    my $tagCode = $opts{'tagCode'};
    my @shapeRecords = ();

    $reader->byteAlign();
    # 描画スタイルを参照するインデックスのビット幅
    my $numFillBits = $reader->getUIBits(4);
    my $numLineBits = $reader->getUIBits(4);

    my $currentDrawingPositionX = 0;
    my $currentDrawingPositionY = 0;
    my $currentFillStyle0 = 0;
    my $currentFillStyle1 = 0;
    my $currentLineStyle = 0;
    my $done = 0;

    # ShapeRecords
    while (!$done) {
        my %shapeRecord = ();
        my $typeFlag = $reader->getUIBit();
        $shapeRecord{'TypeFlag'} = $typeFlag;
        if ($typeFlag == 0) {
            my $endOfShape = $reader->getUIBits(5);
            if ($endOfShape == 0) {
                # EndShapeRecord
                $shapeRecord{'EndOfShape'} = $endOfShape;
                $done = 1;
            } else {
                # StyleChangeRecord
                $reader->incrementOffset(0, -5);
                my $stateNewStyles = $reader->getUIBit();
                my $stateLineStyle = $reader->getUIBit();
                my $stateFillStyle1 = $reader->getUIBit();
                my $stateFillStyle0 = $reader->getUIBit();

                my $stateMoveTo = $reader->getUIBit();
                if ($stateMoveTo) {
                    my $moveBits = $reader->getUIBits(5);
#                        $shapeRecord{'(MoveBits)'} = $moveBits;
                    my $moveDeltaX = $reader->getSIBits($moveBits);
                    my $moveDeltaY = $reader->getSIBits($moveBits);
#                        $currentDrawingPositionX += $moveDeltaX;
#                        $currentDrawingPositionY += $moveDeltaY;
                    $currentDrawingPositionX = $moveDeltaX;
                    $currentDrawingPositionY = $moveDeltaY;
                    $shapeRecord{'MoveX'} = $currentDrawingPositionX;
                    $shapeRecord{'MoveY'} = $currentDrawingPositionY;
                }
                $shapeRecord{'MoveX'} = $currentDrawingPositionX;
                $shapeRecord{'MoveY'} = $currentDrawingPositionY;

                if ($stateFillStyle0) {
                    $currentFillStyle0 = $reader->getUIBits($numFillBits);
                }
                if ($stateFillStyle1) {
                    $currentFillStyle1 = $reader->getUIBits($numFillBits);
                }
                if ($stateLineStyle) {
                    $currentLineStyle = $reader->getUIBits($numLineBits);
                }
                $shapeRecord{'FillStyle0'} = $currentFillStyle0;
                $shapeRecord{'FillStyle1'} = $currentFillStyle1;
                $shapeRecord{'LineStyle'}  = $currentLineStyle;
                if ($stateNewStyles) {
                    my %opts = ('tagCode' => $tagCode);
                    $shapeRecord{'FillStyles'} = IO::SWF::Type::FILLSTYLEARRAY::parse($reader, \%opts);
                    $shapeRecord{'LineStyles'} = IO::SWF::Type::LINESTYLEARRAY::parse($reader, \%opts);
                    $reader->byteAlign();
                    $numFillBits = $reader->getUIBits(4);
                    $numLineBits = $reader->getUIBits(4);
                }
            }
        } else { # Edge records
            $shapeRecord{'StraightFlag'} = $reader->getUIBit();
            if ($shapeRecord{'StraightFlag'}) {
                # StraightEdgeRecord
                my $numBits = $reader->getUIBits(4);
#                    $shapeRecord{'(NumBits)'} = $numBits;
                my $generalLineFlag = $reader->getUIBit();
                my $vertLineFlag = 0;
                if ($generalLineFlag == 0) {
                    $vertLineFlag = $reader->getUIBit();
                }
                if ($generalLineFlag || ($vertLineFlag == 0)) {
                    my $deltaX = $reader->getSIBits($numBits + 2);
                    $currentDrawingPositionX += $deltaX;
                }
                if ($generalLineFlag || $vertLineFlag) {
                    my $deltaY = $reader->getSIBits($numBits + 2);
                    $currentDrawingPositionY += $deltaY;
                }
                $shapeRecord{'X'} = $currentDrawingPositionX;
                $shapeRecord{'Y'} = $currentDrawingPositionY;
            } else {
                # CurvedEdgeRecord
                my $numBits = $reader->getUIBits(4);
#                    $shapeRecord{'(NumBits)'} = $numBits;

                my $controlDeltaX = $reader->getSIBits($numBits + 2);
                my $controlDeltaY = $reader->getSIBits($numBits + 2);
                my $anchorDeltaX = $reader->getSIBits($numBits + 2);
                my $anchorDeltaY = $reader->getSIBits($numBits + 2);

                $currentDrawingPositionX += $controlDeltaX;
                $currentDrawingPositionY += $controlDeltaY;
                $shapeRecord{'ControlX'} = $currentDrawingPositionX;
                $shapeRecord{'ControlY'} = $currentDrawingPositionY;

                $currentDrawingPositionX += $anchorDeltaX;
                $currentDrawingPositionY += $anchorDeltaY;
                $shapeRecord{'AnchorX'} = $currentDrawingPositionX;
                $shapeRecord{'AnchorY'} = $currentDrawingPositionY;
            }
        }
        push @shapeRecords, \%shapeRecord;
    }
    return \@shapeRecords;
}

sub build {
    my ($writer, $shapeRecords_aref, $opts_href) = @_;
    my @shapeRecords = ref($shapeRecords_aref) ? @{$shapeRecords_aref} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    my $fillStyleCount = $opts{'fillStyleCount'};
    my $lineStyleCount = $opts{'lineStyleCount'};
    my ($numFillBits, $numLineBits);
    if ($fillStyleCount == 0) {
        $numFillBits = 0;
    } else {
        # $fillStyleCount == fillStyle MaxValue because 'undefined' use 0
        $numFillBits = $writer->need_bits_unsigned($fillStyleCount);
    }
    if ($lineStyleCount == 0) {
        $numLineBits = 0;
    } else {
        # $lineStyleCount == lineStyle MaxValue because 'undefined' use 0
        $numLineBits = $writer->need_bits_unsigned($lineStyleCount);
    }

    $writer->byteAlign();
    $writer->putUIBits($numFillBits, 4);
    $writer->putUIBits($numLineBits, 4);
    my $currentDrawingPositionX = 0;
    my $currentDrawingPositionY = 0;
    my $currentFillStyle0 = 0;
    my $currentFillStyle1 = 0;
    my $currentLineStyle = 0;
my $counter = 0;
    foreach my $shapeRecord (@shapeRecords) {
        $counter++;
        my $typeFlag = $shapeRecord->{'TypeFlag'};
        $writer->putUIBit($typeFlag);
        if($typeFlag == 0) {
            if (defined ($shapeRecord->{'EndOfShape'}) && ($shapeRecord->{'EndOfShape'}) == 0) {
                # EndShapeRecord
                $writer->putUIBits(0, 5);
            } else {
                # StyleChangeRecord
                my $stateNewStyles  = defined $shapeRecord->{'FillStyles'} ? 1 : 0;
                my $stateLineStyle  = ($shapeRecord->{'LineStyle'}  != $currentLineStyle)  ? 1 : 0;
                my $stateFillStyle1 = ($shapeRecord->{'FillStyle1'} != $currentFillStyle1) ? 1 : 0;
                my $stateFillStyle0 = ($shapeRecord->{'FillStyle0'} != $currentFillStyle0) ? 1 : 0;

                $writer->putUIBit($stateNewStyles);
                $writer->putUIBit($stateLineStyle);
                $writer->putUIBit($stateFillStyle1);
                $writer->putUIBit($stateFillStyle0);

                my $stateMoveTo;
                if (($shapeRecord->{'MoveX'} != $currentDrawingPositionX) || ($shapeRecord->{'MoveY'} != $currentDrawingPositionY)) {
                    $stateMoveTo = 1;
                } else {
                    $stateMoveTo = 0;
                }
                $writer->putUIBit($stateMoveTo);
                if ($stateMoveTo) {
                    my $moveX = $shapeRecord->{'MoveX'};
                    my $moveY = $shapeRecord->{'MoveY'};
                    $currentDrawingPositionX = $moveX;
                    $currentDrawingPositionY = $moveY;
                    my $moveBits;
                    if ($moveX | $moveY) { 
                        my $XmoveBits = $writer->need_bits_signed($moveX);
                        my $YmoveBits = $writer->need_bits_signed($moveY);
                        $moveBits = List::Util::max($XmoveBits, $YmoveBits);
                    } else {
                        $moveBits = 0;
                    }
                    $writer->putUIBits($moveBits, 5);
                    $writer->putSIBits($moveX, $moveBits);
                    $writer->putSIBits($moveY, $moveBits);
                }
                if ($stateFillStyle0) {
                    $currentFillStyle0 = $shapeRecord->{'FillStyle0'};
                    $writer->putUIBits($currentFillStyle0, $numFillBits);
                }
                if ($stateFillStyle1) {
                    $currentFillStyle1 = $shapeRecord->{'FillStyle1'};
                    $writer->putUIBits($currentFillStyle1, $numFillBits);
                }
                if ($stateLineStyle) {
                    $currentLineStyle = $shapeRecord->{'LineStyle'};
                    $writer->putUIBits($currentLineStyle, $numLineBits);
                }
                if ($stateNewStyles) {
                    my %opts = ('tagCode' => $tagCode);
                    IO::SWF::Type::FILLSTYLEARRAY::build($writer, $shapeRecord->{'FillStyles'}, \%opts);
                    IO::SWF::Type::LINESTYLEARRAY::build($writer, $shapeRecord->{'LineStyles'}, \%opts);
                    $fillStyleCount = scalar(@{$shapeRecord->{'FillStyles'}});
                    if ($fillStyleCount == 0) {
                        $numFillBits = 0;
                    } else {
                        # $fillStyleCount == fillStyle MaxValue because 'undefined' use 0
                        $numFillBits = $writer->need_bits_unsigned($fillStyleCount);
                    }
                    if ($lineStyleCount == 0) {
                        $numLineBits = 0;
                    } else {
                        # $lineStyleCount == lineStyle MaxValue because 'undefined' use 0
                        $numLineBits = $writer->need_bits_unsigned($lineStyleCount);
                    }
                    $writer->byteAlign();
                    $writer->putUIBits($numFillBits, 4);
                    $writer->putUIBits($numLineBits, 4);
                }
            }
        } else {
            my $straightFlag = $shapeRecord->{'StraightFlag'};
            $writer->putUIBit($straightFlag);
            if ($straightFlag) {
                my $deltaX = $shapeRecord->{'X'} - $currentDrawingPositionX;
                my $deltaY = $shapeRecord->{'Y'} - $currentDrawingPositionY;
                my $numBits;
                if ($deltaX | $deltaY) {
                   my $XNumBits = $writer->need_bits_signed($deltaX);
                   my $YNumBits = $writer->need_bits_signed($deltaY);
                   $numBits = List::Util::max($XNumBits, $YNumBits);
                } else {
                    $numBits = 0;
                }
                if ($numBits < 2) {
                    $numBits = 2;
                }
                $writer->putUIBits($numBits - 2, 4);
                if ($deltaX && $deltaY) {
                    $writer->putUIBit(1); # GeneralLineFlag
                    $writer->putSIBits($deltaX, $numBits);
                    $writer->putSIBits($deltaY, $numBits);
                } else {
                    $writer->putUIBit(0); # GeneralLineFlag
                    if ($deltaX) {
                       $writer->putUIBit(0); # VertLineFlag
                       $writer->putSIBits($deltaX, $numBits);
                    } else {
                       $writer->putUIBit(1); # VertLineFlag
                       $writer->putSIBits($deltaY, $numBits);
                    }
                }
                $currentDrawingPositionX = $shapeRecord->{'X'};
                $currentDrawingPositionY = $shapeRecord->{'Y'};
            } else {
                my $controlDeltaX = $shapeRecord->{'ControlX'} - $currentDrawingPositionX;
                my $controlDeltaY = $shapeRecord->{'ControlY'} - $currentDrawingPositionY;
                $currentDrawingPositionX = $shapeRecord->{'ControlX'};
                $currentDrawingPositionY = $shapeRecord->{'ControlY'};
                my $anchorDeltaX = $shapeRecord->{'AnchorX'} - $currentDrawingPositionX;
                my $anchorDeltaY = $shapeRecord->{'AnchorY'} - $currentDrawingPositionY;
                $currentDrawingPositionX = $shapeRecord->{'AnchorX'};
                $currentDrawingPositionY = $shapeRecord->{'AnchorY'};

                my $numBitsControlDeltaX = $writer->need_bits_signed($controlDeltaX);
                my $numBitsControlDeltaY = $writer->need_bits_signed($controlDeltaY);
                my $numBitsAnchorDeltaX = $writer->need_bits_signed($anchorDeltaX);
                my $numBitsAnchorDeltaY = $writer->need_bits_signed($anchorDeltaY);
                my $numBits = List::Util::max($numBitsControlDeltaX, $numBitsControlDeltaY, $numBitsAnchorDeltaX, $numBitsAnchorDeltaY);
                if ($numBits < 2) {
                   $numBits = 2;
                }
                $writer->putUIBits($numBits - 2, 4);
                $writer->putSIBits($controlDeltaX, $numBits);
                $writer->putSIBits($controlDeltaY, $numBits);
                $writer->putSIBits($anchorDeltaX, $numBits);
                $writer->putSIBits($anchorDeltaY, $numBits);
            }
        }
    }
    return 1;
}

sub string {
    my ($shapeRecords_aref, $opts_href) = @_;
    my @shapeRecords = ref($shapeRecords_aref) ? @{$shapeRecords_aref} : ();
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $tagCode = $opts{'tagCode'};
    foreach my $row (@shapeRecords) {
        my %shapeRecord = %{$row};
        my $typeFlag = $shapeRecord{'TypeFlag'};
        if ($typeFlag == 0) {
           if (defined ($shapeRecord{'EndOfShape'})) {
               last;
           } else {
               my $moveX = $shapeRecord{'MoveX'} / 20;
               my $moveY = $shapeRecord{'MoveY'} / 20;
               print "\tChangeStyle: MoveTo: ($moveX, $moveY)";
               my @style_list = ('FillStyle0', 'FillStyle1', 'LineStyle');
               print "  FillStyle: ".$shapeRecord{'FillStyle0'}."|".$shapeRecord{'FillStyle1'};
               print "  LineStyle: ".$shapeRecord{'LineStyle'}."\n";
               if (defined ($shapeRecord{'FillStyles'})) {
                   print "    FillStyles:\n";
                   print IO::SWF::Type::FILLSTYLEARRAY::string($shapeRecord{'FillStyles'}, \%opts);
               }
               if (defined ($shapeRecord{'LineStyles'})) {
                    print "    LineStyles:\n";
                    print IO::SWF::Type::LINESTYLEARRAY::string($shapeRecord{'LineStyles'}, \%opts);
               }
           }
        } else {
            my $straightFlag = $shapeRecord{'StraightFlag'};
            if ($straightFlag) {
                my $x = $shapeRecord{'X'} / 20;
                my $y = $shapeRecord{'Y'} / 20;
                print "\tStraightEdge: MoveTo: ($x, $y)\n";
            } else {
                my $controlX = $shapeRecord{'ControlX'} / 20;
                my $controlY = $shapeRecord{'ControlY'} / 20;
                my $anchorX = $shapeRecord{'AnchorX'} / 20;
                my $anchorY = $shapeRecord{'AnchorY'} / 20;
                print "\tCurvedEdge: MoveTo: Control($controlX, $controlY) Anchor($anchorX, $anchorY)\n";
            }
        }
    }
}

1;
