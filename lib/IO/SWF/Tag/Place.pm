package IO::SWF::Tag::Place;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::SWF::Bit;
use IO::SWF::Tag;
use IO::SWF::Type::CXFORM;
use IO::SWF::Type::String;
use IO::SWF::Type::CXFORMWITHALPHA;
use IO::SWF::Type::CLIPACTIONS;

__PACKAGE__->mk_accessors( qw(
    _characterId
    _depth
    _matrix
    _colorTransform
    _ratio
    _name
    _clipDepth
    _clipActions
    _placeFlagHasClipActions
    _placeFlagHasClipDepth
    _placeFlagHasName
    _placeFlagHasRatio
    _placeFlagHasColorTransform
    _placeFlagHasMatrix
    _placeFlagHasCharacter
    _placeFlagMove
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;
    my $reader = IO::SWF::Bit->new();
    $reader->input($content);

    if ($tagCode == 4) {
        #4: // PlaceObject
        $self->_characterId($reader->getUI16LE());
        $self->_depth($reader->getUI16LE());
        $self->_matrix(IO::SWF::Type::MATRIX::parse($reader));
        if ($reader->hasNextData()) { # optional
            $self->_colorTransform(IO::SWF::Type::CXFORM::parse($reader));
        }
    }
    elsif ($tagCode == 26) {
        # 26: // PlaceObject2
        # placeFlag
        $self->_placeFlagHasClipActions($reader->getUIBit());
        $self->_placeFlagHasClipDepth($reader->getUIBit());
        $self->_placeFlagHasName($reader->getUIBit());
        $self->_placeFlagHasRatio($reader->getUIBit());
        $self->_placeFlagHasColorTransform($reader->getUIBit());
        $self->_placeFlagHasMatrix($reader->getUIBit());
        $self->_placeFlagHasCharacter($reader->getUIBit());
        $self->_placeFlagMove($reader->getUIBit());
        #
        $self->_depth($reader->getUI16LE());
        if ($self->_placeFlagHasCharacter) {
            $self->_characterId($reader->getUI16LE());
        }
        if ($self->_placeFlagHasMatrix) {
            $self->_matrix(IO::SWF::Type::MATRIX::parse($reader));
        }
        if ($self->_placeFlagHasColorTransform) {
            $self->_colorTransform(IO::SWF::Type::CXFORMWITHALPHA::parse($reader));
        }
        if ($self->_placeFlagHasRatio) {
            $self->_ratio($reader->getUI16LE());
        }
        if ($self->_placeFlagHasName) {
            $self->_name(IO::SWF::Type::String::parse($reader));
        }
        if ($self->_placeFlagHasClipDepth) {
            $self->_clipDepth($reader->getUI16LE());
        }
        if ($self->_placeFlagHasClipActions) {
            $self->_clipActions(IO::SWF::Type::CLIPACTIONS::parse($reader, $opts_href));
        }
    }
    return 1;
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;

    if (defined $self->_characterId) {
        print "\tCharacterId: ".$self->_characterId."\n";
    }
    if (defined $self->_depth) {
        print "\tDepth: ".$self->_depth."\n";
    }
    if (defined $self->_matrix) {
        $opts_href->{'indent'} = 2;
        print "\tMatrix:\n".IO::SWF::Type::MATRIX::string($self->_matrix, $opts_href)."\n";
    }
    if (defined $self->_colorTransform) {
        if ($tagCode == 4) { # PlaceObject
            print "\tColorTransform: ".IO::SWF::Type::CXFORM::string($self->_colorTransform)."\n";
        } else {
            print "\tColorTransform: ".IO::SWF::Type::CXFORMWITHALPHA::string($self->_colorTransform)."\n";
        }
    }
    if (defined $self->_ratio) {
        print "\tRatio: ".$self->_ratio."\n";
    }
    if (defined $self->_name) {
        print "\tName:".$self->_name."\n";
    }
    if (defined $self->_clipDepth) {
        print "\tClipDepth:".$self->_clipDepth."\n";
    }
    if (defined $self->_clipActions) {
        print "\tClipActions:\n";
        print "\t".IO::SWF::Type::CLIPACTIONS::string($self->_clipActions, $opts_href)."\n";
    }
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $writer = IO::SWF::Bit->new();

    if ($tagCode == 4) {
        # 4: // PlaceObject
        $self->_characterId($writer->getUI16LE());
        $self->_depth($writer->getUI16LE());
        $self->_matrix(IO::SWF::Type::MATRIX::parse($writer));
        if ($writer->hasNextData()) { # optional
            $self->_colorTransform(IO::SWF::Type::CXFORM::parse($writer));
        }
    }
    elsif ($tagCode == 26) {
        # 26: // PlaceObject2
        #
        if (defined $self->_characterId) {
            $self->_placeFlagHasCharacter(1);
        } else {
            $self->_placeFlagHasCharacter(0);
        }
        if (defined $self->_matrix)  {
            $self->_placeFlagHasMatrix(1);
        } else {
            $self->_placeFlagHasMatrix(0);
        }
        if (defined $self->_colorTransform) {
            $self->_placeFlagHasColorTransform(1);
        } else {
            $self->_placeFlagHasColorTransform(0);
        }
        if (defined $self->_ratio) {
            $self->_placeFlagHasRatio(1);
        } else {
            $self->_placeFlagHasRatio(0);
        }
        if (defined $self->_name) {
            $self->_placeFlagHasName(1);
        } else {
            $self->_placeFlagHasName(0);
        }
        if (defined $self->_clipDepth) {
            $self->_placeFlagHasClipDepth(1);
        } else {
            $self->_placeFlagHasClipDepth(0);
        }
        if (defined $self->_clipActions) {
            $self->_placeFlagHasClipActions(1);
        } else {
            $self->_placeFlagHasClipActions(0);
        }
        # placeFlag
        $writer->putUIBit($self->_placeFlagHasClipActions);
        $writer->putUIBit($self->_placeFlagHasClipDepth);
        $writer->putUIBit($self->_placeFlagHasName);
        $writer->putUIBit($self->_placeFlagHasRatio);
        $writer->putUIBit($self->_placeFlagHasColorTransform);
        $writer->putUIBit($self->_placeFlagHasMatrix);
        $writer->putUIBit($self->_placeFlagHasCharacter);
        $writer->putUIBit($self->_placeFlagMove);
        #
        $writer->putUI16LE($self->_depth);
        if ($self->_placeFlagHasCharacter) {
            $writer->putUI16LE($self->_characterId);
        }
        if ($self->_placeFlagHasMatrix) {
            IO::SWF::Type::MATRIX::build($writer, $self->_matrix);
        }
        if ($self->_placeFlagHasColorTransform) {
            IO::SWF::Type::CXFORMWITHALPHA::build($writer, $self->_colorTransform);
        }
        if ($self->_placeFlagHasRatio) {
            $writer->putUI16LE($self->_ratio);
        }
        if ($self->_placeFlagHasName) {
            IO::SWF::Type::String::build($writer, $self->_name);
        }
        if ($self->_placeFlagHasClipDepth) {
            $writer->putUI16LE($self->_clipDepth);
        }
        if ($self->_placeFlagHasClipActions) {
            IO::SWF::Type::CLIPACTIONS::build($writer, $self->_clipActions, $opts_href);
        }
    }
    return $writer->output();
}

1;
