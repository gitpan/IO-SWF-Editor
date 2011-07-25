package IO::SWF::Type::CXFORM;

use strict;
use warnings;

sub parse {
    my ($reader, $opts_href) = @_;
    my %cxform = ();
    my $hasAddTerms = $reader->getUIBit();
    my $hasMultiTerms = $reader->getUIBit();
    $cxform{'HasAddTerms'} = $hasAddTerms;
    $cxform{'HasMultiTerms'} = $hasMultiTerms;
    my $nbits = $reader->getUIBits(4);
    if ($hasMultiTerms) {
        $cxform{'RedMultiTerm'}   = $reader->getSIBits($nbits);
        $cxform{'GreenMultiTerm'} = $reader->getSIBits($nbits);
        $cxform{'BlueMultiTerm'}  = $reader->getSIBits($nbits);
    }
    if ($hasAddTerms) {
        $cxform{'RedAddTerm'}   = $reader->getSIBits($nbits);
        $cxform{'GreenAddTerm'} = $reader->getSIBits($nbits);
        $cxform{'BlueAddTerm'}  = $reader->getSIBits($nbits);
    }
    return \%cxform;
}

sub build {
    my ($writer, $cxform_href, $opts_href) = @_;
    my %cxform = ref($cxform_href) eq 'HASH' ? %{$cxform_href} : ();
    my $nbits         = 0;
    my $hasAddTerms   = 0;
    my $hasMultiTerms = 0;
    my @multi_term_list = ('RedMultiTerm', 'GreenMultiTerm', 'BlueMultiTerm');
    my $need_bits;
    foreach my $term (@multi_term_list) {
        if (exists ($cxform{$term})) {
            $hasMultiTerms = 1;
            $need_bits = $writer->need_bits_signed($cxform{$term});
            if ($nbits < $need_bits){
                $nbits = $need_bits;
            }
        }
    }
    my @add_term_list = ('RedAddTerm', 'GreenAddTerm', 'BlueAddTerm');
    foreach my $term (@add_term_list) {
        if (exists ($cxform{$term})) {
            $hasAddTerms = 1;
            $need_bits = $writer->need_bits_signed($cxform{$term});
            if ($nbits < $need_bits){
                $nbits = $need_bits;
            }
        }
    }
    $writer->putUIBit($hasAddTerms);
    $writer->putUIBit($hasMultiTerms);
    $writer->putUIBits($nbits, 4);
    if ($hasMultiTerms) {
        $writer->putSIBits($cxform{'RedMultiTerm'},   $nbits);
        $writer->putSIBits($cxform{'GreenMultiTerm'}, $nbits);
        $writer->putSIBits($cxform{'BlueMultiTerm'},  $nbits);
    }
    if ($hasAddTerms) {
        $writer->putSIBits($cxform{'RedAddTerm'},   $nbits);
        $writer->putSIBits($cxform{'GreenAddTerm'}, $nbits);
        $writer->putSIBits($cxform{'BlueAddTerm'},  $nbits);
    }
}

sub string {
    my ($cxform_href, $opts_href) = @_;
    my %cxform = ref($cxform_href) eq 'HASH' ? %{$cxform_href} : ();

    if (($cxform{'HasMultiTerms'} == 0) && ($cxform{'HasAddTerms'} == 0)) {
        return '(No Data: CXFORM)';
    }
    my $text = '';
    if ($cxform{'HasMultiTerms'}) {
        $text .= sprintf("MultiTerms:(%d,%d,%d)", $cxform{'RedMultiTerm'}, $cxform{'GreenMultiTerm'}, $cxform{'BlueMultiTerm'});
    }
    if ($cxform{'HasAddTerms'}) {
        if ($cxform{'HasMultiTerms'}) {
            $text .= ' ';
        }
        $text .= sprintf("AddTerms:(%d,%d,%d)", $cxform{'RedAddTerm'}, $cxform{'GreenAddTerm'}, $cxform{'BlueAddTerm'});
    }
    return $text;
}

1;
