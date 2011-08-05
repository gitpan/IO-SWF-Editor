package IO::SWF::Tag;

use strict;
use warnings;

use base 'Class::Accessor::Fast';

use UNIVERSAL::require;

__PACKAGE__->mk_accessors( qw(
    code
    content
    tag
    byte_offset
    byte_size
    length
    swfInfo

    characterId
    referenceId
    placeFlag
    depth
));

sub new {
    my ($class, $swfInfo) = @_;
    my $self = $class->SUPER::new;
    $self->swfInfo($swfInfo) if $swfInfo;
    return $self;
}

sub getTagInfo {
    my ($self, $tagCode, $label) = @_;
    my %tagMap = (
    #  code => { name , klass )
         0 => {'name' => 'End'},
         1 => {'name' => 'ShowFrame'},
         2 => {'name' => 'DefineShape',  'klass' => 'Shape'},
#         3 => {'name' => 'FreeCharacter'}, # ???
         4 => {'name' => 'PlaceObject', 'klass' => 'Place'},
         5 => {'name' => 'RemoveObject'},
         6 => {'name' => 'DefineBitsJPEG'},
         7 => {'name' => 'DefineButton'},
         8 => {'name' => 'JPEGTables'},
         9 => {'name' => 'SetBackgroundColor', 'klass' => 'BGColor'},
        10 => {'name' => 'DefineFont'},
        11 => {'name' => 'DefineText'},
        12 => {'name' => 'DoAction', 'klass' => 'Action'},
        13 => {'name' => 'DefineFontInfo'},
        14 => {'name' => 'DefineSound'},
        15 => {'name' => 'StartSound'},
        # 16 missing
        17 => {'name' => 'DefineButtonSound'},
        18 => {'name' => 'SoundStreamHead'},
        19 => {'name' => 'SoundStreamBlock'},
        20 => {'name' => 'DefineBitsLossless'},
        21 => {'name' => 'DefineBitsJPEG2'},
        22 => {'name' => 'DefineShape2', 'klass' => 'Shape'},
        24 => {'name' => 'Protect'},
        # 25 missing
        26 => {'name' => 'PlaceObject2', 'klass' => 'Place'},
        # 27 missing
        28 => {'name' => 'RemoveObject2'},
        # 29,30,31 missing
        32 => {'name' => 'DefineShape3', 'klass' => 'Shape'},
        33 => {'name' => 'DefineText2'},
        34 => {'name' => 'DefineButton2'},
        35 => {'name' => 'DefineBitsJPEG3'},
        36 => {'name' => 'DefineBitsLossless2'},
        37 => {'name' => 'DefineEditText'},
        # 38 missing
        39 => {'name' => 'DefineSprite', 'klass' => 'Sprite'},
        # 40,41,42 missing
        43 => {'name' => 'FrameLabel'},
        # 44 missing
        45 => {'name' => 'SoundStreamHead2'},
        46 => {'name' => 'DefineMorphShape', 'klass' => 'Shape'},
        48 => {'name' => 'DefineFont2'},
        56 => {'name' => 'Export'},
        57 => {'name' => ''},
        58 => {'name' => ''},
        59 => {'name' => 'DoInitAction', 'klass' => 'Action'},
        60 => {'name' => 'DefineVideoStream'},
        61 => {'name' => 'videoFrame'},
        62 => {'name' => 'DefineFontInfo2'},
        # 63 missing
        64 => {'name' => 'EnableDebugger2'},
        65 => {'name' => 'ScriptLimits'},
        66 => {'name' => 'SetTabIndex'},
        # 67,68 missing 
        69 => {'name' => 'FileAttributes'},
        70 => {'name' => 'PlaceObject3'},
        71 => {'name' => 'ImportAssets2'},
        # 72 missing
        73 => {'name' => 'DefineFontAlignZones'},
        74 => {'name' => 'CSMTextSettings'},
        75 => {'name' => 'DefineFont3'},
        76 => {'name' => 'SymbolClass'},
        77 => {'name' => 'MetaData'},
        78 => {'name' => 'DefineScalingGrid'},
        # 79,80,81 missing
        82 => {'name' => 'DoABC'},
        83 => {'name' => 'DefineShape4'},
        84 => {'name' => 'DefineMorphShape2'},
        # 85 missing
        86 => {'name' => 'DefineSceneAndFrameLabelData'},
        87 => {'name' => 'DefineBinaryData'},
        88 => {'name' => 'DefineFontName'},
        89 => {'name' => 'StartSound2'},
        90 => {'name' => 'DefineBitsJPEG4'},
        91 => {'name' => 'DefineFont4'},
        777 => {'name' => 'Reflex'}, # swftools ?
    );
    if (defined $tagMap{$tagCode}{$label}) {
       return $tagMap{$tagCode}{$label};
    }
    return undef();
}

sub parse {
    my ($self, $reader, $opts_href) = @_;
    my ($byte_offset, $dummy) = $reader->getOffset();
    $self->byte_offset($byte_offset);
    my $tagAndLength = $reader->getUI16LE();
    $self->code($tagAndLength >> 6);
    my $length = $tagAndLength & 0x3f;
    if ($length == 0x3f) { # long format
        $length = $reader->getUI32LE();
    }
    $self->content($reader->getData($length));
    ($byte_offset, $dummy) = $reader->getOffset();
    $self->byte_size($byte_offset - $self->byte_offset);
}

sub dump {
    my ($self, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();
    my $code = $self->code;
    my $name = $self->getTagInfo($code, 'name');
    if (!$name) {
       $name = 'unknown';
    }
    my $length = length($self->content);
    print "Code: $code($name)  Length: $length\n";
    $opts{'Version'} = $self->swfInfo->{'Version'};
    if ($self->parseTagContent(\%opts)) {
        $self->tag->dumpContent($code, \%opts);
    }
    if (defined($opts{'hexdump'})) {
       my $bitio = $opts{'bitio'};
       $bitio->hexdump($self->byte_offset, $self->byte_size);
    }
}

sub build {
    my ($self, $opts_href) = @_;
    my $code = $self->code;
    my $content = $self->content;
    my $length = length($self->content);
    my $writer = IO::SWF::Bit->new();
    my $longFormat = 0;
    if ($code == 6  || # DefineBitsJPEG
        $code == 21 || # DefineBitsJPEG2
        $code == 35 || # DefineBitsJPEG3
        $code == 20 || # DefineBitsLossless
        $code == 36 || # DefineBitsLossless2
        $code == 19    # SoundStreamBlock
    ) {
        $longFormat = 1;
    }
    if (!$longFormat && ($length < 0x3f)) {
        my $tagAndLength = ($code << 6) | $length;
        $writer->putUI16LE($tagAndLength);
    } else {
        my $tagAndLength = ($code << 6) | 0x3f;
        $writer->putUI16LE($tagAndLength);
        $writer->putUI32LE($length);
    }
    return $writer->output() . $self->buildTagContent();
}

sub parseTagContent {
    my ($self, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();
    if ($self->tag) {
        return 1;
    }
    my $code = $self->code;
    my $klass = $self->getTagInfo($code, 'klass');
    if (!defined $klass) {
        return 0; # no parse
    }

    my $module = "IO::SWF::Tag::$klass";
    $module->require or die $@;
    my $obj = $module->new($self->swfInfo);

    $opts{'Version'} = $self->swfInfo->{'Version'};
    $obj->parseContent($code, $self->content, \%opts);
    $self->tag($obj);
    return 1;
}

sub buildTagContent {
    my $self = shift;
    if (length($self->content)) {
        return $self->content;
    }
    if (!$self->tag) {
        return '';
    }
    my $code = $self->code;
    my %opts = ( 'Version' => $self->swfInfo->{'Version'} );
    $self->content($self->tag->buildContent($code, \%opts));
    return $self->content;
}

sub bitmapSize {
    my $self = shift;
    my $code = $self->code;
    if (!$self->parseTagContent()) {
        die "failed to parseTagContent";
    }
    if ($code == 6  || # 21: // DefineBitsJPEG2
        $code == 35    # 35: // DefineBitsJPEG3
    ) {
        # dummy
    }
    elsif ($code == 20 || # 20: // DefineBitsLossless
           $code == 36    # 36: // DefineBitsLossless2
    ) {
        # dummy
    }
    else {
        # dummy
    }
}

1;
