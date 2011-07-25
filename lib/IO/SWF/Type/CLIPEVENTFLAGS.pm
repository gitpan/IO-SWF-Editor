package IO::SWF::Type::CLIPEVENTFLAGS;

use strict;
use warnings;

use base 'IO::SWF::Type';

our @clipevent_list =  (
    'KeyUp', 'KeyDown', 'MouseUp', 'MouseDown', 'MouseMove',
    'Unload', 'EnterFrame', 'Load', 'DragOver',
    'RollOut', 'RollOver',
    'ReleaseOutside', 'Release', 'Press', 'Initialize', 'Data');

sub parse {
    my ($reader, $opts_href) = @_;
    my %clipeventflags = ();
    foreach my $key (@clipevent_list) {
        $clipeventflags{'ClipEvent'.$key} = $reader->getUIBit();
    }
    if ($opts_href->{'Version'} >= 6) {
        $clipeventflags{'Reserved'} = $reader->getUIBits(5);
        $clipeventflags{'ClipEventKeyConstruct'} = $reader->getUIBit();
        $clipeventflags{'ClipEventKeyPress'} = $reader->getUIBit();
        $clipeventflags{'ClipEventDragOut'} = $reader->getUIBit();
        $clipeventflags{'Reserved2'} = $reader->getUIBits(8);
    }
    return \%clipeventflags;
}

sub build {
    my ($writer, $clipeventflags_href, $opts_href) = @_;
    my %clipeventflags = ref($clipeventflags_href) ? %{$clipeventflags_href} : ();

    foreach my $key (@clipevent_list) {
        $writer->putUIBit($clipeventflags{'ClipEvent'.$key});
    }
    if ($opts_href->{'Version'} >= 6) {
        $writer->putUIBits($clipeventflags{'Reserved'}, 6);
        $writer->putUIBit($clipeventflags{'ClipEventConstruct'});
        $writer->putUIBit($clipeventflags{'ClipEventKeyPress'});
        $writer->putUIBit($clipeventflags{'ClipEventDragOut'});
        $writer->putUIBits($clipeventflags{'Reserved2'}, 8);
    }
}

sub string {
    my ($clipeventflags_href, $opts_href) = @_;
    my %clipeventflags = ref($clipeventflags_href) ? %{$clipeventflags_href} : ();
    my $text = "ClipEvent: ";
    my @clipevent_list_local = @clipevent_list;
    if ($opts_href->{'Version'} <= 5) {
        #
    } else {
        push @clipevent_list_local, ('Construct', 'KeyPress', 'DragOut');
    }
    foreach my $key (@clipevent_list_local) {
        if ($clipeventflags{'ClipEvent'.$key} == 1) {
            $text .= $key.' ';
        }
    }
    return $text;
}

1;
