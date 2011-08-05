package IO::SWF;

use strict;
use warnings;

use base 'Class::Accessor::Fast';
use IO::SWF::Bit;
use IO::SWF::Type::RECT;
use IO::SWF::Tag;
use Compress::Zlib;

__PACKAGE__->mk_accessors( qw(
    _headers
    _header_size
    _tags
    _swfdata
    shape_adjust_mode
));

sub new {
    my ($class, $args) = @_;
    my $self;
    if(ref $args eq 'HASH') {
        return $class->SUPER::new($args);
    }else{
        return $class->SUPER::new;
    }
}

sub _set_headers {
    my ($self, %args) = @_;
    my $header = $self->_headers ? $self->_headers : {};
    foreach my $key (keys %args) {
        $header->{$key} = $args{$key};
    }
    $self->_headers($header);
}

sub _set_tag {
    my ($self, $tag) = @_;
    my @tags = $self->_tags ? @{$self->_tags} : ();
    push @tags, $tag;
    $self->_tags(\@tags);
}

sub parse {
    my ($self, $swfdata) = @_;
    my $reader = IO::SWF::Bit->new();
    $reader->input($swfdata);
    $self->_swfdata($swfdata);
    ## SWF Header ##
    $self->_set_headers(
        'Signature'  => $reader->getData(3),
        'Version'    => $reader->getUI8(),
        'FileLength' => $reader->getUI32LE(),
    );

    if (substr($self->_headers->{'Signature'}, 0, 1) eq 'C') {
        # swf binary compressed by zlib
        my $uncompressed_data = Compress::Zlib::memGunzip(substr($swfdata, 8));
        if (!defined $uncompressed_data) {
            return 0;
        }
        my ($byte_offset, $dummy) = $reader->getOffset();
        $reader->setOffset(0, 0);
        $swfdata = $reader->getData($byte_offset) . $uncompressed_data;
        $reader = IO::SWF::Bit->new();
        $reader->input($swfdata);
        $self->_swfdata($swfdata);
        $reader->setOffset($byte_offset, 0);
    }
    ## SWF Movie Header ##
    my $ret = IO::SWF::Type::RECT::parse($reader);
    $self->_set_headers('FrameSize' => $ret);
    $reader->byteAlign();
    $self->_set_headers(
        'FrameRate'  => $reader->getUI16LE(),
        'FrameCount' => $reader->getUI16LE(),
    );

    my ($header_size, $dummy) = $reader->getOffset();
    $self->_header_size($header_size);

    ## SWF Tags ##
    while (1) {
        my %swfInfo = ('Version' => $self->_headers->{'Version'});
        my $tag = IO::SWF::Tag->new(\%swfInfo);
        $tag->parse($reader);
        $self->_set_tag($tag);
        if ($tag->code == 0) { # END Tag
            last;
        }
    }
    return 1;
}

sub build {
    my $self = shift;
    my $writer_head = IO::SWF::Bit->new();
    my $writer = IO::SWF::Bit->new();

    ## SWF Header ##
    $writer_head->putData($self->_headers->{'Signature'});
    $writer_head->putUI8($self->_headers->{'Version'});
    $writer_head->putUI32LE($self->_headers->{'FileLength'});

    ## SWF Movie Header ##
    IO::SWF::Type::RECT::build($writer, $self->_headers->{'FrameSize'});
    $writer->byteAlign();
    $writer->putUI16LE($self->_headers->{'FrameRate'});
    $writer->putUI16LE($self->_headers->{'FrameCount'});

    ## SWF Tags ##
    my $idx = 0;
    foreach my $tag (@{$self->_tags}) {
        my $tagData = $tag->build();
        if ($tagData) {
            $writer->putData($tagData);
        }
        else {
            die "tag build failed (tag idx=$idx)";
        }
        $idx++;
    }
    my ($fileLength, $bit_offset_dummy) = $writer->getOffset();
    $fileLength += 8; # swf header
    $self->_set_headers('FileLength' => $fileLength);
    $writer_head->setUI32LE($fileLength, 4);
    if (substr($self->_headers->{'Signature'}, 0, 1) eq 'C') {
        return $writer_head->output() . Compress::Zlib::memGzip($writer->output());
    }
    return $writer_head->output().$writer->output();
}

sub dump {
    my ($self, $opts_href) = @_;
    my %opts = ref($opts_href) ? %{$opts_href} : ();
    my $bitio;
    if (defined $opts{'hexdump'}) {
        $bitio = IO::SWF::Bit->new();
        $bitio->input($self->_swfdata);
    }
    ## SWF Header ##
    print 'Signature: '.$self->_headers->{'Signature'}."\n";
    print 'Version: '.$self->_headers->{'Version'}."\n";
    print 'FileLength: '.$self->_headers->{'FileLength'}."\n";
    print 'FrameSize: '. IO::SWF::Type::RECT::string($self->_headers->{'FrameSize'})."\n";
    print 'FrameRate: '.($self->_headers->{'FrameRate'} / 0x100)."\n";
    print 'FrameCount: '.$self->_headers->{'FrameCount'}."\n";

    if ($opts{'hexdump'}) {
        $bitio->hexdump(0, $self->_header_size);
        $opts{'bitio'} = $bitio; # for tag
    }

    ## SWF Tags ##
    
    print 'Tags:'."\n";
    foreach my $tag (@{$self->_tags}) {
        $tag->dump(\%opts);
    }
}

1;
