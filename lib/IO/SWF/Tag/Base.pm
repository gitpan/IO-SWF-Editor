package IO::SWF::Tag::Base;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors( qw(
    swfInfo
));

sub new {
    my ($class, $swfInfo) = @_;
    my $self = $class->SUPER::new;
    $self->swfInfo($swfInfo) if $swfInfo;
    return $self;
}

1;
