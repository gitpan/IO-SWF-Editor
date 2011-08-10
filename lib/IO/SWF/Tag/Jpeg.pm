package IO::SWF::Tag::Jpeg;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::SWF::Bit;

__PACKAGE__->mk_accessors( qw(
    _CharacterID
    _AlphaDataOffset
    _JPEGData
    _ZlibBitmapAlphaData
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;

    my $reader = IO::SWF::Bit->new();
    $reader->input($content);
    my $alphaDataOffset;
    if ($tagCode != 8) { # ! JPEGTablesa
        $self->_CharacterID($reader->getUI16LE());
    }
    if ($tagCode == 35) { # DefgineBitsJPEG3
        $alphaDataOffset = $reader->getUI32LE();
        $self->_AlphaDataOffset($alphaDataOffset);
    }
    if ($tagCode != 35) { # ! DefgineBitsJPEG3
        $self->_JPEGData($reader->getDataUntil());
    } else {
        $self->_JPEGData($reader->getData($alphaDataOffset));
        $self->_ZlibBitmapAlphaData($reader->getDataUntil());
    }
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;

    if ($tagCode != 8) { # ! JPEGTables
        print "\tCharacterID:{".$self->_CharacterID."}\n";
    }
    if ($tagCode == 35) { # DefineBitsJPEG3
        print "\tAlphaDataOffset:{".$self->_AlphaDataOffset."}\n";
    }
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $writer = IO::SWF::Bit->new();
    if ($tagCode != 8) { # ! JPEGTablesa
        $writer->putUI16LE($self->_CharacterID);
    }
    if ($tagCode == 35) { # DefgineBitsJPEG3
        $self->_AlphaDataOffset(length($self->_JPEGData));
        $writer->putUI32LE($self->_AlphaDataOffset);
    }
    if ($tagCode != 35) { # ! DefgineBitsJPEG3
        $writer->putData($self->_JPEGData);
    } else {
        $writer->putData($self->_JPEGData);
        $writer->putData($self->_ZlibBitmapAlphaData);
    }
    return $writer->output();
}

1;
