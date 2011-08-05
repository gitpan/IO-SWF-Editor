package IO::SWF::Tag::Sprite;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::SWF::Bit;
use IO::SWF::Tag;

__PACKAGE__->mk_accessors( qw(
    _spriteId
    _frameCount
    _controlTags
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;
    my $reader = IO::SWF::Bit->new();
    $reader->input($content);
    
    $self->_spriteId($reader->getUI16LE());
    $self->_frameCount($reader->getUI16LE());

    my @controlTags = ();
    # SWF Tags
    while (1) {
        my $tag = IO::SWF::Tag->new($self->swfInfo);
        $tag->parse($reader);
        push @controlTags, $tag;
        if ($tag->code == 0) { # END Tag
            last;
        }
    }
    $self->_controlTags(\@controlTags);
    return 1;
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;
    print "\tSprite: SpriteID={" . $self->_spriteId . "} FrameCount={" . $self->_frameCount . "}\n";
    foreach my $tag (@{$self->_controlTags}) {
        print "  ";
        $tag->dump($opts_href);
    }
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $writer = IO::SWF::Bit->new();
    $writer->putUI16LE($self->_spriteId);
    $writer->putUI16LE($self->_frameCount);
    foreach my $tag (@{$self->_controlTags}) {
        my $tagData = $tag->build();
        if ($tagData) {
            $writer->putData($tag->build());
        }
    }
    return $writer->output();
}

1;
