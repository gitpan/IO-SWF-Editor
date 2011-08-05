package IO::SWF::Tag::Shape;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::SWF::Bit;
use IO::SWF::Type::RECT;
use IO::SWF::Type::FILLSTYLEARRAY;
use IO::SWF::Type::LINESTYLEARRAY;
use IO::SWF::Type::SHAPE;

__PACKAGE__->mk_accessors( qw(
    _shapeId
    _shapeBounds
    _fillStyles
    _lineStyles
    _shapeRecords
    _startBounds
    _endBounds
    _offset
    _morphFillStyles
    _morphLineStyles
    _startEdge
    _endEdges
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;

    my $isMorph = ($tagCode == 46 || $tagCode == 84) ? 1 : 0;
    my $reader = IO::SWF::Bit->new();
    $reader->input($content);
    $self->_shapeId($reader->getUI16LE());

    my %opts = ('tagCode' => $tagCode, 'isMorph' => $isMorph);

    if (!$isMorph) {
        # style
        $self->_shapeBounds(IO::SWF::Type::RECT::parse($reader));
        $self->_fillStyles(IO::SWF::Type::FILLSTYLEARRAY::parse($reader, \%opts));
        $self->_lineStyles(IO::SWF::Type::LINESTYLEARRAY::parse($reader, \%opts));
        # shape
        $self->_shapeRecords(IO::SWF::Type::SHAPE::parse($reader, \%opts));
    } else {
        $self->_startBounds(IO::SWF::Type::RECT::parse($reader));
        $self->_endBounds(IO::SWF::Type::RECT::parse($reader));
        $self->_offset($reader->getUI32LE());
        # style
        $self->_morphFillStyles(IO::SWF::Type::FILLSTYLEARRAY::parse($reader, \%opts));
        $self->_morphLineStyles(IO::SWF::Type::LINESTYLEARRAY::parse($reader, \%opts));
        # shape
        $self->_startEdge(IO::SWF::Type::SHAPE::parse($reader, \%opts));
        $self->_endEdge(IO::SWF::Type::SHAPE::parse($reader, \%opts));
    }
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;

    my $isMorph = ($tagCode == 46 || $tagCode == 84) ? 1 : 0;
    if ($self->_shapeId) {
        print "    ShapeId: {" . $self->_shapeId . "}\n";
    }
    my %opts = ('tagCode' => $tagCode, 'isMorph' => $isMorph);

    if (!$isMorph) {
        print "    ShapeBounds: ". IO::SWF::Type::RECT::string($self->_shapeBounds)."\n";
        print "    FillStyles:\n";
        print IO::SWF::Type::FILLSTYLEARRAY::string($self->_fillStyles, \%opts);
        print "    LineStyles:\n";
        print IO::SWF::Type::LINESTYLEARRAY::string($self->_lineStyles, \%opts);

        print "    ShapeRecords:\n";
        print IO::SWF::Type::SHAPE::string($self->_shapeRecords, \%opts);
    } else {
        print "    StartBounds: ". IO::SWF::Type::RECT::string($self->_startBounds)."\n";
        print "    EndBounds: ". IO::SWF::Type::RECT::string($self->_endBounds)."\n";
        print "    FillStyles:\n";
        print IO::SWF::Type::FILLSTYLEARRAY::string($self->_morphFillStyles, \%opts);
        print "    LineStyles:\n";
        print IO::SWF::Type::LINESTYLEARRAY::string($self->_morphLineStyles, \%opts);

        print "    StartEdge:\n";
        print IO::SWF::Type::SHAPE::string($self->_startEdge, \%opts);
        print "    endEdge:\n";
        print IO::SWF::Type::SHAPE::string($self->_endEdge, \%opts);
    }
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();

    my $isMorph = ($tagCode == 46 || $tagCode == 84) ? 1 : 0;
    my $writer = IO::SWF::Bit->new();
    if (!exists($opts{'noShapeId'})) {
        $writer->putUI16LE($self->_shapeId);
    }
    %opts = ('tagCode' => $tagCode);

    if (!$isMorph) {
        IO::SWF::Type::RECT::build($writer, $self->_shapeBounds);
        # style
        IO::SWF::Type::FILLSTYLEARRAY::build($writer, $self->_fillStyles, \%opts);
        IO::SWF::Type::LINESTYLEARRAY::build($writer, $self->_lineStyles, \%opts);
        # shape
        $opts{'fillStyleCount'} = scalar(@{$self->_fillStyles});
        $opts{'lineStyleCount'} = scalar(@{$self->_lineStyles});
        IO::SWF::Type::SHAPE::build($writer, $self->_shapeRecords, \%opts);
    } else {
        IO::SWF::Type::RECT::build($writer, $self->_startBounds);
        IO::SWF::Type::RECT::build($writer, $self->_endBounds);
        # style
        IO::SWF::Type::FILLSTYLEARRAY::build($writer, $self->_morphFillStyles, \%opts);
        IO::SWF::Type::LINESTYLEARRAY::build($writer, $self->_morphLineStyles, \%opts);
        # shape
        $opts{'fillStyleCount'} = scalar(@{$self->_morphFillStyles});
        $opts{'lineStyleCount'} = scalar(@{$self->_morphLineStyles});
        IO::SWF::Type::SHAPE::build($writer, $self->_startEdge, \%opts);
        IO::SWF::Type::SHAPE::build($writer, $self->_endEdge, \%opts);
    }
    return $writer->output();
}

sub deforme {
    my ($self, $threshold) = @_;
    my $startIndex = undef();
    my $endIndex;
    my @shapeRecords = @{$self->_shapeRecords};
    for (my $shapeRecordIndex = 0; $shapeRecordIndex < @shapeRecords; $shapeRecordIndex++) {
        my %shapeRecord = %{$shapeRecords[$shapeRecordIndex]};
        if ($shapeRecord{'TypeFlag'} == 0 && !defined $shapeRecord{'EndOfShape'}) {
            # StyleChangeRecord
            $endIndex = $shapeRecordIndex - 1;
            if ($startIndex) {
                $self->deformeShapeRecordUnit($threshold, $startIndex, $endIndex);
            }
            $startIndex = $shapeRecordIndex;
        }
        if (defined $shapeRecord{'EndOfShape'} && $shapeRecord{'EndOfShape'} == 0) {
            # EndShapeRecord
            $endIndex = $shapeRecordIndex - 1;
            $self->deformeShapeRecordUnit($threshold, $startIndex, $endIndex);
        }
    }
#    my @array_value = map{ $_ } values @{$self->_shapeRecords};
#    $self->_shapeRecords(\@array_value);
}

sub deformeShapeRecordUnit {
    my ($self, $threshold, $startIndex, $endIndex) = @_;
#        return $self->deformeShapeRecordUnit_1($threshold, $startIndex, $endIndex);
    return $self->deformeShapeRecordUnit_2($threshold, $startIndex, $endIndex);
}

sub deformeShapeRecordUnit_1 {
    my ($self, $threshold, $startIndex, $endIndex) = @_;
    my $threshold_2 = $threshold * $threshold;
    my $shapeRecord = @{$self->_shapeRecords}[$startIndex];
    my $prevIndex = undef();
    my $prevDrawingPositionX;
    my $prevDrawingPositionY;
    my $currentDrawingPositionX = $shapeRecord->{'MoveX'};
    my $currentDrawingPositionY = $shapeRecord->{'MoveY'};
    for (my $i = $startIndex + 1 ;$i <= $endIndex; $i++) {
        $shapeRecord = @{$self->_shapeRecords}[$i];
        my ($diff_x, $diff_y, $distance_2, $distance_2_control, $distance_2_anchor);
        if ($shapeRecord->{'StraightFlag'} == 0) {
            # process for curve
            $diff_x = $shapeRecord->{'ControlX'} - $currentDrawingPositionX;
            $diff_y = $shapeRecord->{'ControlY'} - $currentDrawingPositionY;
            $distance_2_control = $diff_x * $diff_x + $diff_y * $diff_y;
            $diff_x = $shapeRecord->{'AnchorX'} - $currentDrawingPositionX;
            $diff_y = $shapeRecord->{'AnchorY'} - $currentDrawingPositionY;
            $distance_2_anchor = $diff_x * $diff_x + $diff_y * $diff_y;
            if (($distance_2_control +  $distance_2_anchor) > $threshold_2) {
                # nothing
                $prevIndex = $i;
                $prevDrawingPositionX = $currentDrawingPositionX;
                $prevDrawingPositionY = $currentDrawingPositionY;
                $currentDrawingPositionX = $shapeRecord->{'AnchorX'};
                $currentDrawingPositionY = $shapeRecord->{'AnchorY'};
                next; # skip
            }
            # convert to straight
            $shapeRecord->{'StraightFlag'} = 1; # to Straight
            $shapeRecord->{'X'} = $shapeRecord->{'AnchorX'};
            $shapeRecord->{'Y'} = $shapeRecord->{'AnchorY'};
            delete $shapeRecord->{'ControlX'};
            delete $shapeRecord->{'ControlY'};
            delete $shapeRecord->{'AnchorX'};
            delete $shapeRecord->{'AnchorY'};
        }
        if (!$prevIndex) {
            # nothing
            $prevIndex = $i;
            $prevDrawingPositionX = $currentDrawingPositionX;
            $prevDrawingPositionY = $currentDrawingPositionY;
            $currentDrawingPositionX = $shapeRecord->{'X'};
            $currentDrawingPositionY = $shapeRecord->{'Y'};
            next; # skip
        }
        $diff_x = $shapeRecord->{'X'} - $prevDrawingPositionX;
        $diff_y = $shapeRecord->{'Y'} - $prevDrawingPositionY;
        $distance_2 = $diff_x * $diff_x + $diff_y * $diff_y;
        if ($distance_2 > $threshold_2) {
            # nothing
            $prevIndex = $i;
            $prevDrawingPositionX = $currentDrawingPositionX;
            $prevDrawingPositionY = $currentDrawingPositionY;
            $currentDrawingPositionX = $shapeRecord->{'X'};
            $currentDrawingPositionY = $shapeRecord->{'Y'};
            next; # skip
        }
        # joint to previous shape
        my $prevShapeRecord = @{$self->_shapeRecords}[$prevIndex];
        $prevShapeRecord->{'X'} = $shapeRecord->{'X'};
        $prevShapeRecord->{'Y'} = $shapeRecord->{'Y'};
        $currentDrawingPositionX = $shapeRecord->{'X'};
        $currentDrawingPositionY = $shapeRecord->{'Y'};
        @{$self->_shapeRecords}[$i] = undef();
    }
}

sub deformeShapeRecordUnit_2 {
    my ($self, $threshold, $startIndex, $endIndex) = @_;
    $self->deformeShapeRecordUnit_2_curve($threshold, $startIndex, $endIndex);
    while ($self->deformeShapeRecordUnit_2_line($threshold, $startIndex, $endIndex)) {};
}

sub deformeShapeRecordUnit_2_curve {
    my ($self, $threshold, $startIndex, $endIndex) = @_;
    my $threshold_2 = $threshold * $threshold;
    my $shapeRecord = @{$self->_shapeRecords}[$startIndex];
    my $currentDrawingPositionX = $shapeRecord->{'MoveX'};
    my $currentDrawingPositionY = $shapeRecord->{'MoveY'};
    for (my $i = $startIndex + 1 ;$i <= $endIndex; $i++) {
        $shapeRecord = @{$self->_shapeRecords}[$i];
        if ($shapeRecord->{'StraightFlag'} == 0) {
            # process for curve
            my $diff_x = $shapeRecord->{'ControlX'} - $currentDrawingPositionX;
            my $diff_y = $shapeRecord->{'ControlY'} - $currentDrawingPositionY;
            my $distance_2_control = $diff_x * $diff_x + $diff_y * $diff_y;
            $diff_x = $shapeRecord->{'AnchorX'} - $currentDrawingPositionX;
            $diff_y = $shapeRecord->{'AnchorY'} - $currentDrawingPositionY;
            my $distance_2_anchor = $diff_x * $diff_x + $diff_y * $diff_y;
            if (($distance_2_control +  $distance_2_anchor) > $threshold_2) {
                # nothing
                $currentDrawingPositionX = $shapeRecord->{'AnchorX'};
                $currentDrawingPositionY = $shapeRecord->{'AnchorY'};
                next; # skip
            }
            # convert to straight
            $shapeRecord->{'StraightFlag'} = 1; # to Straight
            $shapeRecord->{'X'} = $shapeRecord->{'AnchorX'};
            $shapeRecord->{'Y'} = $shapeRecord->{'AnchorY'};
            delete $shapeRecord->{'ControlX'};
            delete $shapeRecord->{'ControlY'};
            delete $shapeRecord->{'AnchorX'};
            delete $shapeRecord->{'AnchorY'};
            $currentDrawingPositionX = $shapeRecord->{'X'};
            $currentDrawingPositionY = $shapeRecord->{'Y'};
        }
    }
}

sub deformeShapeRecordUnit_2_line {
    my ($self, $threshold, $startIndex, $endIndex) = @_;
    my $threshold_2 = $threshold * $threshold;
    my $shapeRecord = @{$self->_shapeRecords}[$startIndex];
    my $prevIndex = undef();
    my $currentDrawingPositionX = $shapeRecord->{'MoveX'};
    my $currentDrawingPositionY = $shapeRecord->{'MoveY'};
    my @distance_list_short = ();
    my @distance_list_all = ();
    my @distance_table_all = ();
    for (my $i = $startIndex + 1 ;$i <= $endIndex; $i++) {
        $shapeRecord = @{$self->_shapeRecords}[$i];
        my ($diff_x, $diff_y, $distance_2, $distance_2_control, $distance_2_anchor);
        if ($shapeRecord->{'StraightFlag'} == 0) {
            $diff_x = $shapeRecord->{'ControlX'} - $currentDrawingPositionX;
            $diff_y = $shapeRecord->{'ControlY'} - $currentDrawingPositionY;
            $distance_2_control = $diff_x * $diff_x + $diff_y * $diff_y;
            $diff_x = $shapeRecord->{'AnchorX'} - $currentDrawingPositionX;
            $diff_y = $shapeRecord->{'AnchorY'} - $currentDrawingPositionY;
            $distance_2_anchor = $diff_x * $diff_x + $diff_y * $diff_y;
#                $distance_list[$i] = $distance_2_control +  $distance_2_anchor;
            $distance_table_all[$i] = $distance_2_control +  $distance_2_anchor;
            $currentDrawingPositionX = $shapeRecord->{'AnchorX'};
            $currentDrawingPositionY = $shapeRecord->{'AnchorY'};
        } else {
            $diff_x = $shapeRecord->{'X'} - $currentDrawingPositionX;
            $diff_y = $shapeRecord->{'Y'} - $currentDrawingPositionY;
        $distance_2 = $diff_x * $diff_x + $diff_y * $diff_y;
        if ($distance_2 < $threshold_2) {
            push @distance_list_short, $i;
        }
        $distance_table_all[$i] = $distance_2;
        $currentDrawingPositionX = $shapeRecord->{'X'};
        $currentDrawingPositionY = $shapeRecord->{'Y'};
        }
    }
    @distance_list_short = sort(@distance_list_short);
    my $deforme_number = 0;
    foreach my $i (@distance_list_short) {
        if ($distance_table_all[$i] > $threshold_2) {
            next;
        }
        if (!defined ($distance_list_all[$i-1]) && !defined ($distance_list_all[$i+1])) {

        }
        my $index_to_merge;
        if (!defined ($distance_list_all[$i-1])) {
            if (!defined ($distance_list_all[$i+1])) {
                next;           
            } else {
                $index_to_merge = $i+1;
            }
        } else {
            if (!defined ($distance_list_all[$i+1])) {
                $index_to_merge = $i-1;
            } else {
                $index_to_merge = $i-1; # XXX
            }
        }
        $shapeRecord = @{$self->_shapeRecords}[$i];
        my $shapeRecord_toMerge = @{$self->_shapeRecords}[$index_to_merge];
        if ($i > $index_to_merge) {
            if ($shapeRecord->{'StraightFlag'}) {
                $shapeRecord_toMerge->{'X'} = $shapeRecord->{'X'};
                $shapeRecord_toMerge->{'Y'} = $shapeRecord->{'Y'};
            } else {
                $shapeRecord_toMerge->{'AnchorX'} = $shapeRecord->{'X'};
                $shapeRecord_toMerge->{'AnchorY'} = $shapeRecord->{'Y'};
            }
        }
        $distance_list_all[$index_to_merge] += $distance_list_all[$i];
#           unset($distance_list_all[$i]);
        @{$self->_shapeRecords}[$i] = undef();
        $deforme_number += 1;
    }
    return $deforme_number;
}

sub countEdges {
    my $self = shift;
    my $edges_count = 0;
    my @shapeRecords;
    if (defined ($self->_shapeRecords) && $self->_shapeRecords) {
        @shapeRecords = @{$self->_shapeRecords};
    }
    elsif (defined ($self->_startEdge) && $self->_startEdge) {
        @shapeRecords = @{$self->_startEdge};
    }
    else {
        @shapeRecords = (); # nothing to do.
    }
    foreach my $shapeRecord (@shapeRecords) {
        if (defined ($shapeRecord->{'StraightFlag'})) { # XXX
            $edges_count++; 
        }
    }
    return ($self->_shapeId, $edges_count);
}

1;
