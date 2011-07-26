package IO::SWF::Editor;

use strict;
use warnings;

our ( $VERSION );
$VERSION = '0.03_01';

use base 'IO::SWF';
use IO::Bit;
use IO::SWF::Tag::Shape;
use IO::SWF::Tag::Action;
use IO::SWF::Tag::Sprite;
use IO::SWF::Bitmap;
use IO::SWF::Lossless;
use Compress::Zlib;

=head1

IO::SWF::Editor - Parse and edit SWF binary by Perl.

=head1 SYNOPSIS

    use IO::SWF::Editor;

    my $swf = IO::SWF::Editor->new();
    $swf->parse($swf_binary);

    print $swf->build();

=head1 VERSION

This document references version 0.03_01 of IO::SWF::Editor, released
to CPAN on July 26, 2011.

head1 DESCRIPTION

IO::SWF::Editor provides to parse and edit SWF binary.

USAGE
    If you want to replace buried image in SWF to another image,
    you can do it easily.

        my $swf = IO::SWF::Editor->new();
        $swf->parse($swf_binary);
        $swf->setCharacterId();
        $swf->replaceBitmapData($character_id, $blob);

        print $swf->build();

    For more details, look at each methods' document.

=cut

=head1 METHODS

=item $swf->setCharacterId()

    Set characterId for specify tag.

=cut

use constant {
    SHAPE_BITMAP_NONE           => 0,
    SHAPE_BITMAP_MATRIX_RESCALE => 1,
    SHAPE_BITMAP_RECT_RESIZE    => 2,
    SHAPE_BITMAP_TYPE_TILED     => 4,
};

sub new {
    my ($class, $args) = @_;
    my $self;
    if(ref $args eq 'HASH') {
        $self = $class->SUPER::new($args);
    }else{
        $self = $class->SUPER::new();
    }
    $self->shape_adjust_mode(SHAPE_BITMAP_NONE);
    return $self;
}

sub rebuild {
    my $self = shift;
    foreach my $tag (@{$self->_tags}) {
        if ($tag->parseTagContent()) {
            $tag->content('');
            $tag->buildTagContent();
        }
    }
}

sub setCharacterId {
    my $self = shift;
    foreach my $tag (@{$self->_tags}) {
        my $content_reader = IO::Bit->new();
        $content_reader->input($tag->content);
        if (
            $tag->code == 6  || # DefineBits
            $tag->code == 21 || # DefineBitsJPEG2
            $tag->code == 35 || # DefineBitsJPEG3
            $tag->code == 20 || # DefineBitsLossless
            $tag->code == 36 || # DefineBitsLossless2
            $tag->code == 46 || # DefineMorphShape
            $tag->code == 2  || # DefineShape (ShapeId)
            $tag->code == 22 || # DefineShape2 (ShapeId)
            $tag->code == 32 || # DefineShape3 (ShapeId)
            $tag->code == 11 || # DefineText
            $tag->code == 33 || # DefineText2
            $tag->code == 37 || # DefineTextEdit
            $tag->code == 39    # DefineSprite
        ) {
            $tag->characterId($content_reader->getUI16LE());
        }
    }
}

sub setReferenceId {
    my $self = shift;
    foreach my $tag (@{$self->_tags}) {
        my $content_reader = IO::Bit->new();
        $content_reader->input($tag->content);
        if ($tag->code == 4 || # 4:  // PlaceObject
            $tag->code == 5    # 5:  // RemoveObject
        ) {
            $tag->referenceId($content_reader->getUI16LE());
        }
        elsif ($tag->code == 26) { # 26: // PlaceObject2 (Shape Reference)
            $tag->placeFlag($content_reader->getUI8());
            if ($tag->placeFlag & 0x02) {
                $tag->referenceId($content_reader->getUI16LE());
            }
        }
        elsif ($tag->code == 2  || # 2:  // DefineShape   (Bitmap ReferenceId)
               $tag->code == 22 || # 22: // DefineShape2　 (Bitmap ReferenceId)
               $tag->code == 32 || # 32: // DefineShape3    (Bitmap ReferenceId)
               $tag->code == 46    # 46: // DefineMorphShape (Bitmap ReferenceId)
        ) {
            die "setReferenceId DefineShape not implemented yet.";
        }

    }
}

=item $swf->replaceTagContent()

    Replace content by tagCode.

=cut
sub replaceTagContent {
    my ($self, $tagCode, $content, $limit) = @_;
    $limit ||= 1;
    my $count = 0;
    foreach my $tag (@{$self->_tags}) {
        if ($tag->code == $tagCode) {
            $tag->content($content);
            $count += 1;
            if ($limit <= $count) {
                last;
            }
        }
    }
    return $count;
}

=item $swf->getTagContent()

    Get content by tagCode.

=cut
sub getTagContent {
    my ($self, $tagCode) = @_;
    foreach my $tag (@{$self->_tags}) {
        if ($tag->code == $tagCode) {
            return $tag->content;
        }
    }
    return '';
}

=item $swf->replaceTagContentByCharacterId()

    Replace content by tagCode and characterId.
    You must call setCharacterId() before call this method.

=cut
sub replaceTagContentByCharacterId {
    my ($self, $tagCode, $characterId, $content_after_character_id) = @_;
    if (ref($tagCode) ne 'ARRAY') {
        $tagCode = [$tagCode];
    }
    my $ret = 0;
    foreach my $tag (@{$self->_tags}) {
        my $code = $tag->code;
        if (grep(/^$code\z/, @{$tagCode}) && $tag->characterId) {
            if ($tag->characterId == $characterId) {
                $tag->content(pack('v', $characterId).$content_after_character_id);
                $ret = 1;
                last;
            }
        }
    }
    return $ret;
}

=item $swf->replaceTagByCharacterId()

    Replace Tag by tagCode and characterId.
    You must call setCharacterId() before call this method.

=cut
sub replaceTagByCharacterId {
    my ($self, $tagCode, $characterId, $replaceTag_href) = @_;
    my %replaceTag = ref($replaceTag_href) ? %{$replaceTag_href} : ();
    if (ref($tagCode) ne 'ARRAY') {
        $tagCode = [$tagCode];
    }
    my $ret = 0;
    foreach my $tag (@{$self->_tags}) {
        my $code = $tag->code;
        if (grep(/^$code\z/, @{$tagCode}) && $tag->characterId) {
            if ($tag->characterId == $characterId) {
                if ($replaceTag{'Code'}) {
                    $tag->code($replaceTag{'Code'});
                }
                $tag->length(length($replaceTag{'Content'}));
                $tag->content($replaceTag{'Content'});
                $ret = 1;
                last;
            }
        }
    }
    return $ret;
}

sub replaceBitmapTagByCharacterId {
    my ($self, $tagCode, $characterId, $replaceTag_href) = @_;
    my %replaceTag = ref($replaceTag_href) ? %{$replaceTag_href} : ();
    if (ref($tagCode) ne 'ARRAY') {
        $tagCode = [$tagCode];
    }
    my $ret = 0;
    foreach my $tag (@{$self->_tags}) {
        my $code = $tag->code;
        if (grep(/^$code\z/, @{$tagCode}) && $tag->characterId) {
            if ($tag->characterId == $characterId) {
                if ($replaceTag{'Code'}) {
                    $tag->code($replaceTag{'Code'});
                }
                $tag->length(length($replaceTag{'Content'}));
                $tag->content($replaceTag{'Content'});
                $ret = 1;
                last;
            }
        }
    }
    return $ret;
}

=item $swf->getTagContentByCharacterId()

    Get content by tagCode and characterId.
    You must call setCharacterId() before call this method.

=cut
sub getTagContentByCharacterId {
    my ($self, $tagCode, $characterId) = @_;
    foreach my $tag (@{$self->_tags}) {
        if (($tag->code == $tagCode) && $tag->characterId) {
            if ($tag->characterId == $characterId) {
                return $tag->content;
                last;
            }
        }
    }
    return '';
}

=item $swf->deformeShape()

    Decrease Shape's edges.

=cut
sub deformeShape {
    my ($self, $threshold) = @_;
    foreach my $tag (@{$self->_tags}) {
        my $code = $tag->code;
        if ($code == 2 || $code == 22 || $code == 32) {
            # 2: // DefineShape
            # 22: // DefineShape2
            # 32: // DefineShape3
            my $shape = IO::SWF::Tag::Shape->new();
            $shape->parseContent($code, $tag->content);
            $shape->deforme($threshold);
            $tag->content($shape->buildContent($code));
        }
    }
}

sub setActionVariables {
    my ($self, $trans_table_or_key_str, $value_str) = @_;
    my (%trans_table, $action, $tag, $code);
    if (ref($trans_table_or_key_str) eq 'HASH') {
        %trans_table = %{$trans_table_or_key_str};
    }
    else {
        %trans_table = ( $trans_table_or_key_str => $value_str );
    }

    my $tagidx = 0;
    foreach my $tag_local (@{$self->_tags}) {
        $code = $tag_local->code;
        if ($code == 12 || # 12: // DoAction
            $code == 59    # 59: // DoInitAction
        ) {
            $action = IO::SWF::Tag::Action->new();
            $action->parseContent($code, $tag_local->content);
            $tag = $tag_local;
            last;
        }
        if ($code == 1) {
            $tag = $tag_local;
            last;
        }
        $tagidx++;
    }
    if (!$action) {
        # create new ActionTag at first frame
        my $bytecode = '';
        foreach my $key_str (keys %trans_table) {
            my $value_str  = $trans_table{$key_str};
            my @key_strs   = split("\0", $key_str);   # delete \0
            my @value_strs = split("\0", $value_str); # delete \0
            my $key_data   = chr(0).$key_strs[0]."\0";
            my $value_data = chr(0).$value_strs[0]."\0";
            # Push
            $bytecode .= chr(0x96).pack('v', length($key_data)).$key_data;
            # Push
            $bytecode .= chr(0x96).pack('v', length($value_data)).$value_data;
            # SetVarables
            $bytecode .= chr(0x1d);
            # End
            $bytecode .= chr(0);
        }
        my $tag_action = IO::SWF::Tag->new();
        $tag_action->code(12); # DoAction
        $tag_action->content($bytecode);
        # insert new ActionTag
        my @tags     = @{$self->_tags};
        my @new_tags = @tags[0 .. $tagidx];
        my @sufix    = @tags[$tagidx+1 .. $#tags];
        push @new_tags, $tag_action;
        push @new_tags, @sufix;
        $self->_tags(\@new_tags);
    }
    else {
        # create new_tag
        my @let_action;
        foreach my $key_str (keys %trans_table) {
            my $value_str = $trans_table{$key_str};
            push @let_action, {'Code' => 0x96, # Push
                               'Values' => [
                                    { 'Type' => 0, 'String' => $key_str },
                                ],
                            };
            push @let_action, {'Code' => 0x96, # Push
                               'Values' => [
                                    { 'Type' => 0, 'String' => $value_str },
                                ],
                            };
            push @let_action, {'Code' => 0x1d }; # SetVariable
        }
        push @let_action, @{$action->_actions};
        $action->_actions(\@let_action);

        $tag->content($action->buildContent($code));
    }
}

=item $swf->replaceActionStrings()

=cut
sub replaceActionStrings {
    my ($self, $trans_table_or_from_str, $value_str) = @_;
    my %trans_table;
    if (ref($trans_table_or_from_str) eq 'HASH') {
        %trans_table = %{$trans_table_or_from_str};
    }
    else {
        %trans_table = ( $trans_table_or_from_str => $value_str );
    }
    foreach my $tag (@{$self->_tags}) {
        my $code = $tag->code;
        if ($code == 12) {
            # 12: // DoInitAction
            my $action = IO::SWF::Tag::Action->new();
            $action->parseContent($code, $tag->content);
            $action->replaceActionStrings(\%trans_table);
            $tag->content($action->buildContent($code));
        }
        elsif ($code == 39) {
            # 39: // Sprite
            my $sprite = IO::SWF::Tag::Sprite->new();
            $sprite->parseContent($code, $tag->content);
            foreach my $tag_in_sprite (@{$sprite->_controlTags}) {
                my $code_in_sprite = $tag_in_sprite->code;
                if ($code_in_sprite == 12) {
                    # 12: // DoInitAction
                    my $action_in_sprite = IO::SWF::Tag::Action->new();
                    $action_in_sprite->parseContent($code_in_sprite, $tag_in_sprite->content);
                    $action_in_sprite->replaceActionStrings(\%trans_table);
                    $tag_in_sprite->content($action_in_sprite->buildContent($code_in_sprite));
                }
            }
            $tag->content($sprite->buildContent($code));
        }
    }
}

=item $swf->replaceBitmapData()

=cut
sub replaceBitmapData {
    my ($self, $bitmap_id, $bitmap_data, $jpeg_alphadata) = @_;
    my (%tag, $new_width, $new_height, $ret);
    if ($bitmap_data =~ /^GIF/ ||
        $bitmap_data =~ /^\x89PNG/) {
        %tag = IO::SWF::Lossless::BitmapData2Lossless($bitmap_id, $bitmap_data);
        $new_width  = $tag{width};
        $new_height = $tag{height};
    } elsif ($bitmap_data =~ /\xff\xd8\xff/) {
        my $erroneous_header = pack('CCCC', 0xFF, 0xD9, 0xFF, 0xD8);
        if (!defined $jpeg_alphadata) {
            # 21: DefineBitsJPEG2
            my $content = pack('v', $bitmap_id).$erroneous_header.$bitmap_data;
            %tag = ('Code'    => 21,
                    'Content' => $content);
        }
        else {
            # 35: DefineBitsJPEG3
            my $jpeg_data = $erroneous_header.$bitmap_data;
            my $compressed_alphadata = Compress::Zlib::memGzip($jpeg_alphadata);
            my $content = pack('v', $bitmap_id).pack('V', length($jpeg_data)).$jpeg_data.$compressed_alphadata;
            %tag = ('Code'    => 35,
                    'Content' => $content);
        }
        ($new_width, $new_height) = IO::SWF::Bitmap::get_jpegsize($bitmap_data);
    }
    else {
        # Unknown Bitmap Format
        die "Unknown Bitmap Format: ".(pack('h', substr($bitmap_data, 0, 4)));
    }
    if ($self->shape_adjust_mode > 0) {
        $ret = $self->applyShapeAdjustModeByRefId($bitmap_id, $new_width, $new_height);
    }
    # DefineBits,DefineBitsJPEG2,3, DefineBitsLossless,DefineBitsLossless2
    my @tag_code = (6, 21, 35, 20, 36);
    if ($self->shape_adjust_mode > 0) {
        $tag{'shape_adjust_mode'} = $self->shape_adjust_mode;
    }
    $ret = $self->replaceBitmapTagByCharacterId(\@tag_code, $bitmap_id, \%tag);
#    $ret = $self->replaceTagByCharacterId(\@tag_code, $bitmap_id, \%tag);
    return $ret;
}

sub applyShapeAdjustModeByRefId {
    my ($self, $bitmap_id, $new_height, $old_height) = @_;
    my $shape_adjust_mode = $self->shape_adjust_mode;
    if ($shape_adjust_mode == SHAPE_BITMAP_NONE) {
        return 0;
    }
    elsif ($shape_adjust_mode == SHAPE_BITMAP_MATRIX_RESCALE ||
           $shape_adjust_mode == SHAPE_BITMAP_RECT_RESIZE    ||
           $shape_adjust_mode == SHAPE_BITMAP_TYPE_TILED
    ) {
        #
    }
    else {
        # "Illegal shape_adjust_mode($shape_adjust_mode)"
        return 0;
    }

    if ($shape_adjust_mode == SHAPE_BITMAP_MATRIX_RESCALE) {
    }
    elsif ($shape_adjust_mode == SHAPE_BITMAP_RECT_RESIZE) {
    }
    elsif ($shape_adjust_mode == SHAPE_BITMAP_TYPE_TILED) {
    }
    else {
         # "Illegal shape_adjust_mode($shape_adjust_mode)"
         return 0;
    }
    return 1;
}

=item $swf->countShapeEdges()
    
=cut
sub countShapeEdges {
    my ($self, $opts_href) = @_;
    my %count_table = ();
    foreach my $tag (@{$self->_tags}) {
        my $code = $tag->code;
        if ($code == 2 || $code == 22 || $code == 32 || $code == 46) {
            # 2: // DefineShape
            # 22: // DefineShape2
            # 32: // DefineShape3
            # 46: // DefineMorphShape
            my $shape = IO::SWF::Tag::Shape->new();
            $shape->parseContent($code, $tag->content);
            my ($shape_id, $edges_count) = $shape->countEdges();
            $count_table{$shape_id} = $edges_count;
        }
    }
    return %count_table;
}

sub setShapeAdjustMode {
    my ($self, $mode) = @_;
    $self->shape_adjust_mode($mode);
}

1;
