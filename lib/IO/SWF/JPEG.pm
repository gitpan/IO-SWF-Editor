package IO::SWF::JPEG;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

use IO::SWF::Bit;
use Digest::MD5;

__PACKAGE__->mk_accessors( qw(
    _jpegdata
    _jpegChunk
));

our %marker_name_table = (
    0xD8 => 'SOI',
    0xE0 => 'APP0',  0xE1 => 'APP1',  0xE2 => 'APP2',  0xE3 => 'APP3',
    0xE4 => 'APP4',  0xE5 => 'APP5',  0xE6 => 'APP6',  0xE7 => 'APP7',
    0xE8 => 'APP8',  0xE9 => 'APP9',  0xEA => 'APP10', 0xEB => 'APP11',
    0xEC => 'APP12', 0xED => 'APP13', 0xEE => 'APP14', 0xEF => 'APP15',
    0xFE => 'COM',
    0xDB => 'DQT',
    0xC0 => 'SOF0', 0xC1 => 'SOF1',  0xC2 => 'SOF2',  0xC3 => 'SOF3',
    0xC5 => 'SOF5', 0xC6 => 'SOF6',  0xC7 => 'SOF7',
    0xC8 => 'JPG',  0xC9 => 'SOF9',  0xCA => 'SOF10', 0xCB => 'SOF11',
    0xCC => 'DAC',  0xCD => 'SOF13', 0xCE => 'SOF14', 0xCF => 'SOF15',
    0xC4 => 'DHT',
    0xDA => 'SOS',
    0xD0 => 'RST0', 0xD1 => 'RST1', 0xD2 => 'RST2', 0xD3 => 'RST3',
    0xD4 => 'RST4', 0xD5 => 'RST5', 0xD6 => 'RST6', 0xD7 => 'RST7',
    0xDD => 'DRI',
    0xD9 => 'EOI',
    0xDC => 'DNL',   0xDE => 'DHP',  0xDF => 'EXP',
    0xF0 => 'JPG0',  0xF1 => 'JPG1', 0xF2 => 'JPG2',  0xF3 => 'JPG3',
    0xF4 => 'JPG4',  0xF5 => 'JPG5', 0xF6 => 'JPG6',  0xF7 => 'JPG7',
    0xF8 => 'JPG8',  0xF9 => 'JPG9', 0xFA => 'JPG10', 0xFB => 'JPG11',
    0xFC => 'JPG12', 0xFD => 'JPG13'
);

sub new {
    my ($class, $args) = @_;
    my $self;
    if(ref $args eq 'HASH') {
        $self = $class->SUPER::new($args);
    }else{
        $self = $class->SUPER::new;
    }
    return $self;
}

sub input {
    my ($self, $jpegdata) = @_;
    $self->_jpegdata($jpegdata);
}

sub _splitChunk {
    my $self = shift;
    my $bitin = IO::SWF::Bit->new();
    $bitin->input($self->_jpegdata);
    my $marker1;
    my @jpegChunk = ();
    while ($marker1 = $bitin->getUI8()) {
        if ($marker1 != 0xFF) {
            printf STDERR "dumpChunk: marker1=0x%02X", $marker1;
            return;
        }
        my $marker2 = $bitin->getUI8();
        if ($marker2 == 0xD8) {
            # 0xD8: // SOI (Start of Image)
            push @jpegChunk, {'marker' => $marker2, 'data' => undef(), 'length' => undef()};
        }
        elsif ($marker2 == 0xD9) {
            # 0xD9: // EOE (End of Image)
            push @jpegChunk, {'marker' => $marker2, 'data' => undef(), 'length' => undef()};
            last; # while break;
        }
        elsif ($marker2 == 0xDA || # SOS
               $marker2 == 0xD0 || $marker2 == 0xD1 || $marker2 == 0xD2 || $marker2 == 0xD3 || # RST
               $marker2 == 0xD4 || $marker2 == 0xD5 || $marker2 == 0xD6 || $marker2 == 0xD7    # RST
        ) {
            my ($chunk_data_offset, $dummy) = $bitin->getOffset();
            while (1) {
                my $next_marker1 = $bitin->getUI8();
                if ($next_marker1 != 0xFF) {
                    next;
                }
                my $next_marker2 = $bitin->getUI8();
                if ($next_marker2 == 0x00) {
                    next;
                }
                
                $bitin->incrementOffset(-2, 0); # back from next marker
                my ($next_chunk_offset, $dummy) = $bitin->getOffset();
                my $length = $next_chunk_offset - $chunk_data_offset;
                $bitin->setOffset($chunk_data_offset, 0);
                push @jpegChunk, {'marker' => $marker2, 'data' => $bitin->getData($length), 'length' => undef()};
                last;
            }
        }
        else {
            my $length = $bitin->getUI16BE();
            push @jpegChunk, {'marker' => $marker2, 'data' => $bitin->getData($length - 2), 'length' => $length};
        }
    }
    $self->_jpegChunk(\@jpegChunk);
}

# from: SOI APP* DQT SOF* DHT SOS EOI
# to:  SOI APP* SOF* SOS EOI
sub getImageData {
    my $self = shift;    
    if (!$self->_jpegChunk || scalar(@{$self->_jpegChunk}) == 0) {
        $self->_splitChunk();
    }
    my $bitout = IO::SWF::Bit->new();
    foreach my $chunk (@{$self->_jpegChunk}) {
        my $marker = $chunk->{'marker'};
        if (($marker == 0xDB) || ($marker == 0xC4)) {
            next;  # skip DQT(0xDB) or DHT(0xC4)
        }
        $bitout->putUI8(0xFF);
        $bitout->putUI8($marker);
        if (!defined ($chunk->{'data'})) { # SOI or EOI
            # nothing to do
        } else {
            if (defined ($chunk->{'length'})) {
                $bitout->putUI16BE($chunk->{'length'});
            }
            $bitout->putData($chunk->{'data'});
        }
    }
    return $bitout->output();
}

# from: SOI APP* DQT SOF* DHT SOS EOI
# to:   SOI DQT DHT EOI
sub getEncodingTables {
    my $self = shift;
    if (!$self->_jpegChunk || scalar(@{$self->_jpegChunk}) == 0) {
        $self->_splitChunk();
    }
    my $bitout = IO::SWF::Bit->new();
    $bitout->putUI8(0xFF);
    $bitout->putUI8(0xD8); # SOI;
    foreach my $chunk (@{$self->_jpegChunk}) {
        my $marker = $chunk->{'marker'};
        if (($marker != 0xDB) && ($marker != 0xC4)) {
            next;  # skip not ( DQT(0xDB) or DHT(0xC4) )
        }
        $bitout->putUI8(0xFF);
        $bitout->putUI8($marker);
        $bitout->putUI16BE($chunk->{'length'});
        $bitout->putData($chunk->{'data'});
    }
    $bitout->putUI8(0xFF);
    $bitout->putUI8(0xD9); # EOI;
    return $bitout->output();
}

sub dumpChunk { # for debug
    my $self = shift;
    if (!$self->_jpegChunk || scalar(@{$self->_jpegChunk}) == 0) {
        $self->_splitChunk();
    }
    foreach my $chunk (@{$self->_jpegChunk}) {
        my $marker = $chunk->{'marker'};
        my $marker_name = $marker_name_table{$marker};
        if (!defined ($chunk->{'data'})) {
            print "$marker_name:\n";
        } else {
            my $length = length($chunk->{'data'});
            my $md5  = Digest::MD5->new();
            $md5->add($chunk->{'data'});
            my $hash = $md5->hexdigest();
            print "$marker_name: length=$length md5=$hash\n";
        }
    }
}

1;
