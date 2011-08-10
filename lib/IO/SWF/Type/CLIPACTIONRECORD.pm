package IO::SWF::Type::CLIPACTIONRECORD;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::SWF::Type::CLIPEVENTFLAGS;
use IO::SWF::Type::Action;

sub parse {
    my ($reader, $opts_href) = @_;
    my %clipactionrecord = ();
    $clipactionrecord{'EventFlags'} = IO::SWF::Type::CLIPEVENTFLAGS::parse($reader, $opts_href);
    $clipactionrecord{'ActionRecordSize'} = $reader->getUI32LE();
    if ($clipactionrecord{'EventFlags'}->{'ClipEventKeyPress'} == 1) {
        $clipactionrecord{'KeyCode'} = $reader->getUI8();
    }
    my @actions = ();
    while ($reader->getUI8() != 0) {
        $reader->incrementOffset(-1, 0); # 1 byte back
        my $action = IO::SWF::Type::Action::parse($reader);
        push @actions, $action;
    }
    $clipactionrecord{'Actions'} = \@actions;
    return \%clipactionrecord;
}

sub build {
    my ($writer, $clipactionrecord_href, $opts_href) = @_;
    my %clipactionrecord = ref($clipactionrecord_href) ? %{$clipactionrecord_href} : ();

    IO::SWF::Type::CLIPEVENTFLAGS::build($writer, $clipactionrecord{'EventFlags'}, $opts_href);
    my $actionRecordSize = $clipactionrecord{'ActionRecordSize'}; # XXX
    $writer->putUI32LE($actionRecordSize);
    if ($clipactionrecord{'EventFlags'}->{'ClipEventKeyPress'} == 1) {
        $writer->putUI8($clipactionrecord{'KeyCode'});
    }
    my @actions = ();
    foreach my $action (@{$clipactionrecord{'Actions'}}) {
        IO::SWF::Type::Action::build($writer, $action);
    }
    $writer->putUI8(0); # ActionEndFlag
}

sub string {
    my ($clipactionrecord_href, $opts_href) = @_;
    my %clipactionrecord = ref($clipactionrecord_href) ? %{$clipactionrecord_href} : ();

    my $text = '';
    $text .= IO::SWF::Type::CLIPEVENTFLAGS::string($clipactionrecord{'EventFlags'}, $opts_href);
    $text .= "\n";
    $text .= "\tActions:\n";
    foreach my $action (@{$clipactionrecord{'Actions'}}) {
        $text .= "\t";
        $text .= IO::SWF::Type::Action::string($action, $opts_href);
        $text .= "\n";
    }
    return $text;
}

1;
