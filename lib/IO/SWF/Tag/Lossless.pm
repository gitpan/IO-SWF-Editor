package IO::SWF::Tag::Lossless;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::SWF::Bit;

__PACKAGE__->mk_accessors( qw(
    _CharacterID
    _BitmapFormat
    _BitmapWidth
    _BitmapHeight
    _BitmapColorTableSize
    _ZlibBitmapFormat
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;

    my $reader = IO::SWF::Bit->new();
    $reader->input($content);
    $self->_CharacterID($reader->getUI16LE());
    my $bitmapFormat = $reader->getUI8();
    $self->_BitmapFormat($bitmapFormat);
    $self->_BitmapWidth($reader->getUI16LE());
    $self->_BitmapHeight($reader->getUI16LE());
    if ($bitmapFormat == 3) {
        $self->_BitmapColorTableSize($reader->getUI8() + 1);
    }
    $self->_ZlibBitmapFormat($reader->getDataUntil());
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $bitmapFormat = $self->_BitmapFormat;
    print "\tCharacterID:{".$self->_CharacterID."} BitmapFormat={$bitmapFormat}\n";
    print "\tBitmapWidth:{".$self->_BitmapWidth."} BitmapHeight:{".$self->_BitmapHeight."}\n";
    if ($bitmapFormat == 3) {
        print "\tBitmapColorTableSize:{".$self->_BitmapColorTableSize."}\n";
    }
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $writer = IO::SWF::Bit->new();
    $writer->putUI16LE($self->_CharacterID);
    my $bitmapFormat = $self->_BitmapFormat;
    $writer->putUI8($bitmapFormat);
    $writer->putUI16LE($self->_BitmapWidth);
    $writer->putUI16LE($self->_BitmapHeight);
    if ($bitmapFormat == 3) {
        $writer->putUI8($self->_BitmapColorTableSize - 1);
    }
    $writer->putData($self->_ZlibBitmapFormat);
    return $writer->output();
}

1;
