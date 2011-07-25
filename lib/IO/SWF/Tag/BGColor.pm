package IO::SWF::Tag::BGColor;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::Bit;
use IO::SWF::Type::RGB;

__PACKAGE__->mk_accessors( qw(
    _color
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;
    my $reader = IO::Bit->new();
    $reader->input($content);
    $self->_color(IO::SWF::Type::RGB::parse($reader));
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $color_str = IO::SWF::Type::RGB::string($self->_color);
    print "\tColor: $color_str\n";
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $writer = IO::Bit->new();
    IO::SWF::Type::RGB::build($writer, $self->_color);
    return $writer->output();
}

1;
