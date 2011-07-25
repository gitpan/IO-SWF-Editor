package IO::SWF::Lossless;

use strict;
use warnings;

use Compress::Zlib;
use Image::Magick;

sub BitmapData2Lossless {
    my ($bitmap_id, $bitmap_data) = @_;

    my $magick = Image::Magick->new();
    $magick->BlobToImage( $bitmap_data );

    my $colortable_size = $magick->Get('colors');
    my ($width, $height) = $magick->Get( 'width', 'height' );
    my ($format, $transparent_exists);
    my $colortable = '';
    my $pixeldata  = '';
    my $rgb_delimiter = 257;

    if (($magick->Get('type') !~ /^TrueColor/) && ($colortable_size <= 256)) {
        $format = 3; # palette format
        $transparent_exists = 0;
        for (my $i = 0 ; $i < $colortable_size ; $i++) {
            my ($r,$g,$b,$alpha) = split /,/, $magick->Get("colormap[$i]");
            if ($alpha > 0) {
                $transparent_exists = 1;
                last;
            }
        }
        if (!$transparent_exists) {
            for (my $i = 0 ; $i < $colortable_size ; $i++) {
                my ($r,$g,$b,$alpha) = split /,/, $magick->Get("colormap[$i]");
                $colortable .= chr($r/$rgb_delimiter);
                $colortable .= chr($g/$rgb_delimiter);
                $colortable .= chr($b/$rgb_delimiter);
            }
        } else {
            for (my $i = 0 ; $i < $colortable_size ; $i++) {
                my ($r,$g,$b,$alpha) = split /,/, $magick->Get("colormap[$i]");
                $alpha /= $rgb_delimiter;
                $colortable .= chr($r/$rgb_delimiter * $alpha / 255);
                $colortable .= chr($g/$rgb_delimiter * $alpha / 255);
                $colortable .= chr($b/$rgb_delimiter * $alpha / 255);
                $colortable .= chr($alpha);
            }
        }
        my $i = 0;
        
        for (my $y = 0 ; $y < $height ; $y++) {
            for (my $x = 0 ; $x < $width ; $x++) {
                $pixeldata .= chr($magick->Get("index[$x,$y]"));
                $i++;
            }
            while (($i % 4) != 0) {
                $pixeldata .= chr(0);
                $i++;
            }
        }
    } else { # truecolor
        $format = 5; # trurcolor format
        $transparent_exists = 0;
        

        for (my $y = 0 ; $y < $height ; $y++) {
            for (my $x = 0 ; $x < $width ; $x++) {
                my $i                = $magick->Get("index[$x,$y]");
                my ($r,$g,$b,$alpha) = split /,/, $magick->Get("colormap[$i]");

                if ($alpha > 0) {
                    $transparent_exists = 1;
                    last;
                }
            }
        }
        if (!$transparent_exists) {
            for (my $y = 0 ; $y < $height ; $y++) {
                for (my $x = 0 ; $x < $width ; $x++) {
                    my $i                = $magick->Get("index[$x,$y]");
                    my ($r,$g,$b,$alpha) = split /,/, $magick->Get("colormap[$i]");
                    $pixeldata .= 0; # Always 0
                    $pixeldata .= chr($r/$rgb_delimiter);
                    $pixeldata .= chr($g/$rgb_delimiter);
                    $pixeldata .= chr($b/$rgb_delimiter);
                }
            }
        } else {
            for (my $y = 0 ; $y < $height ; $y++) {
                for (my $x = 0 ; $x < $width ; $x++) {
                    my $i                = $magick->Get("index[$x,$y]");
                    my ($r,$g,$b,$alpha) = split /,/, $magick->Get("colormap[$i]");
                    $alpha /= $rgb_delimiter;
                    $pixeldata .= chr($alpha);
                    $pixeldata .= chr($r/$rgb_delimiter * $alpha / 255);
                    $pixeldata .= chr($g/$rgb_delimiter * $alpha / 255);
                    $pixeldata .= chr($b/$rgb_delimiter * $alpha / 255);
                }
            }
        }
    }

    my $tagCode;
    my $content = pack('v', $bitmap_id).chr($format).pack('v', $width).pack('v', $height);
    if ($format == 3) {
        $content .= chr($colortable_size - 1).Compress::Zlib::memGzip($colortable.$pixeldata);
    } else {
        $content .= Compress::Zlib::memGzip($pixeldata);
    }
    
    if (!$transparent_exists) {
        $tagCode = 20; # DefineBitsLossless
    } else {
        $tagCode = 36; # DefineBitsLossless2
    }
    my %tag = ('Code'   => 21,#$tagCode,
               'width'  => $width,
               'height' => $height,
               'Content' => $content);
    return %tag;
}

1;
