package IO::SWF::Bitmap;

use strict;
use warnings;

use IO::SWF::Bit;

use constant {
    FORMAT_UNKNOWN => 0,
    FORMAT_JPEG    => 1,
    FORMAT_PNG     => 2,
    FORMAT_GIF     => 4,
};

sub detect_bitmap_format {
    my $bitmap_data = shift;
    if ($bitmap_data =~ /^\xff\xd8\xff/) {
        return FORMAT_JPEG;
    }
    elsif ($bitmap_data =~ /^\x89PNG/) {
        return FORMAT_PNG;
    }
    elsif ($bitmap_data =~ /^GIF/) {
        return FORMAT_GIF;
    }
    return FORMAT_UNKNOWN;
}

sub get_jpegsize {
    my $jpegdata = shift;
    my $chunk_length = 0;
    my $jpegdata_len = length($jpegdata);
    for (my $idx = 0 ; (($idx + 8) < $jpegdata_len) ; $idx += $chunk_length) {
        my $marker1 = ord(substr($jpegdata, $idx, 1));
        if ($marker1 != 0xFF) {
            last;
        }
        my $marker2 = ord(substr($jpegdata, $idx + 1, 1));
        if ($marker2 == 0xD8 || $marker2 == 0xD9) {
            # 0xD8: // SOI (Start of Image)
            # 0xD9: // EOI (End of Image)
            $chunk_length = 2;
        }
        elsif ($marker2 == 0xDA) {
            # 0xDA: // SOS
            return undef; # not found
        }
        elsif ($marker2 == 0xC0 || # 0xC0 // SOF0
               $marker2 == 0xC1 || # 0xC0 // SOF1
               $marker2 == 0xC2 || # 0xC0 // SOF2
               $marker2 == 0xC3 || # 0xC0 // SOF3
               $marker2 == 0xC5 || # 0xC0 // SOF5
               $marker2 == 0xC6 || # 0xC0 // SOF6
               $marker2 == 0xC7 || # 0xC0 // SOF7
               $marker2 == 0xC8 || # 0xC0 // SOF8
               $marker2 == 0xC9 || # 0xC0 // SOF9
               $marker2 == 0xCA || # 0xC0 // SOF10
               $marker2 == 0xCB || # 0xC0 // SOF11
               $marker2 == 0xCD || # 0xC0 // SOF13
               $marker2 == 0xCE || # 0xC0 // SOF14
               $marker2 == 0xCF    # 0xC0 // SOF15
        ) {
            my $width  = 0x100 * ord(substr($jpegdata, $idx + 7, 1)) + ord(substr($jpegdata, $idx + 8, 1));
            my $height = 0x100 * ord(substr($jpegdata, $idx + 5, 1)) + ord(substr($jpegdata, $idx + 6, 1));
            return ('width' => $width, 'height' => $height); # success
        }
        else {
            $chunk_length = 0x100 * ord(substr($jpegdata, $idx + 2, 1)) + ord(substr($jpegdata, $idx + 3, 1)) + 2;
            if ($chunk_length == 0) { # fail safe;
                last;
            }
        }
    }
    return undef();
}

sub get_pngsize {
    my $pngdata = shift;
    my $pngdata_len = length($pngdata);
    if ($pngdata_len < 24) {
        print STDERR sprintf("IO::SWF::Bitmap::get_pngsize: data_len(%d) < 16\n", $pngdata_len);
        return undef();
    }
    my $width = (((ord(substr($pngdata, 16, 1))*0x100) + ord(substr($pngdata, 17, 1)))*0x100 + ord(substr($pngdata, 18, 1)))*0x100 + ord(substr($pngdata, 19, 1));
    my $height =(((ord(substr($pngdata, 20, 1))*0x100) + ord(substr($pngdata, 21, 1)))*0x100 + ord(substr($pngdata, 22, 1)))*0x100 + ord(substr($pngdata, 23, 1));
    return ('width' => $width, 'height' => $height); # success
}

sub get_gifsize {
    my $gifdata = shift;
    my $gifdata_len = length($gifdata);
    if ($gifdata_len < 10) {
        print STDERR sprintf("IO::SWF::Bitmap::get_gifsize: data_len(%d) < 10\n", $gifdata_len);
        return undef();
    }
    my $width  = 0x100 * ord(substr($gifdata, 7, 1)) + ord(substr($gifdata, 6, 1));
    my $height = 0x100 * ord(substr($gifdata, 9, 1)) + ord(substr($gifdata, 8, 1));
    return ('width' => $width, 'height' => $height); # success
}

sub get_bitmapsize {
    my $bitmapdata = shift;
    if ($bitmapdata =~ /^\xff\xd8\xff/i) { # JPEG
        return get_jpegsize($bitmapdata);
    }
    elsif ($bitmapdata =~ /^\x89PNG/) { # PNG
        return get_pngsize($bitmapdata);
    }
    elsif ($bitmapdata =~ /^GIF/) { # GIF
        return get_gifsize($bitmapdata);
    }
    return undef(); # NG
}

1;
