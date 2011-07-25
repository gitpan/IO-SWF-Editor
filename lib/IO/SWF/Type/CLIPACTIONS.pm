package IO::SWF::Type::CLIPACTIONS;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::SWF::Type::CLIPEVENTFLAGS;
use IO::SWF::Type::CLIPACTIONRECORD;

sub parse {
    my ($reader, $opts_href) = @_;
    my %clipactions = ();
    $clipactions{'Reserved'} = $reader->getUI16LE(); # must be 0
    $clipactions{'AllEventFlags'} = IO::SWF::Type::CLIPEVENTFLAGS::parse($reader, $opts_href);
    my @clipActionRecords = ();
    while (1) {
        if ($opts_href->{'Version'} <= 5) {
            if ($reader->getUI16LE() == 0) {
                last;
            }
            $reader->incrementOffset(-2, 0); # 2 bytes back
        } else {
            if ($reader->getUI32LE() == 0) {
                last;
            }
            $reader->incrementOffset(-4, 0); # 4 bytes back
        }
        push @clipActionRecords, IO::SWF::Type::CLIPACTIONRECORD::parse($reader, $opts_href);
    }
    $clipactions{'ClipActionRecords'} = \@clipActionRecords;
    return \%clipactions;
}

sub build {
    my ($writer, $clipactions_href, $opts_href) = @_;
    my %clipactions = ref($clipactions_href) ? %{$clipactions_href} : ();

    $writer->putUI16LE($clipactions{'Reserved'}); # must be 0
    IO::SWF::Type::CLIPEVENTFLAGS::build($writer, $clipactions{'AllEventFlags'}, $opts_href);
    foreach my $clipActionRecord (@{$clipactions{'ClipActionRecords'}}) {
        IO::SWF::Type::CLIPACTIONRECORD::build($writer, $clipActionRecord, $opts_href);
    }
    if ($opts_href->{'Version'} <= 5) {
        $writer->putUI16LE(0); # ClipActionEndFlag
    } else {
        $writer->putUI32LE(0); # ClipActionEndFlag
    }
}

sub string {
    my ($clipactions_href, $opts_href) = @_;
    my %clipactions = ref($clipactions_href) ? %{$clipactions_href} : ();

    my $text = 'ALLEventFlags: ';
    $text .= IO::SWF::Type::CLIPEVENTFLAGS::string($clipactions{'AllEventFlags'}, $opts_href);
    $text .= "\n";
    $text .= "\tClipActionRecords:\n";
    foreach my $clipActionRecord (@{$clipactions{'ClipActionRecords'}}) {
        $text .= "\t".IO::SWF::Type::CLIPACTIONRECORD::string($clipActionRecord, $opts_href)."\n";
    }
    return $text;
}

1;
