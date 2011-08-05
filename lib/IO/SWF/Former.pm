package IO::SWF::Former;

use base 'IO::SWF';

sub form {
    my $self = shift;
    foreach my $tag (@{$self->_tags}) {
        if ($tag->{'Code'} == 26) {
            # 26: // PlaceObject2
            $self->_form_26($tag);
            last;
        }
    }
}

sub _form_26 {
    my ($self, $tag) = @_; # $tag : PlaceObject2
    my $reader = IO::SWF::Bit->new();
    $reader->input($tag->{'Content'});
    $tag->placeFlag($reader->getUI8());
    $tag->depth($reader->getUI16LE());
    if ($tag->placeFlag & 0x02) {
        $tag->characterId($reader->getUI16LE());
    }
}

1;
