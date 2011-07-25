package IO::SWF::Tag::Action;

use strict;
use warnings;

use base 'IO::SWF::Tag::Base';

use IO::Bit;
use IO::SWF::Type::Action;

__PACKAGE__->mk_accessors( qw(
    _actions
    _spriteId
));

sub parseContent {
    my ($self, $tagCode, $content, $opts_href) = @_;
    my $reader = IO::Bit->new();
    my @actions = ();
    $reader->input($content);
    if ($tagCode == 59) { # DoInitAction
        $self->_spriteId($reader->getUI16LE());
    }
    while ($reader->getUI8() != 0) {
        $reader->incrementOffset(-1, 0); # 1 byte back
        my $action = IO::SWF::Type::Action::parse($reader);
        push @actions, $action;
    }
    $self->_actions(\@actions);
    # ActionEndFlag
}

sub dumpContent {
    my ($self, $tagCode, $opts_href) = @_;
    print "    Actions:";
    if ($tagCode == 59) { # DoInitAction
        print " SpriteID=".$self->_spriteId;
    }
    print "\n";
    foreach my $action (@{$self->_actions}) {
        my $action_str = IO::SWF::Type::Action::string($action);
        print "\t$action_str\n";
    }
}

sub buildContent {
    my ($self, $tagCode, $opts_href) = @_;
    my $writer = IO::Bit->new();
    if ($tagCode == 59) { # DoInitAction
        $writer->putUI16LE($self->_spriteId);
    }
    
    foreach my $action (@{$self->_actions}) {
        IO::SWF::Type::Action::build($writer, $action);
    }
    $writer->putUI8(0); # ActionEndFlag
    return $writer->output();
}

sub replaceActionStrings {
    my ($self, $trans_table_href) = @_;
    my %trans_table = ref($trans_table_href) ? %{$trans_table_href} : ();
    foreach my $action (@{$self->_actions}) {
        if ($action->{'Code'} == 0x83) {
            # 0x83: // ActionGetURL
            if (exists ($trans_table{$action->{'UrlString'}})) {
                $action->{'UrlString'} = $trans_table{$action->{'UrlString'}};
            }
            if (exists ($trans_table{$action->{'TargetString'}})) {
                $action->{'TargetString'} = $trans_table{$action->{'TargetString'}};
            }
        }
        elsif ($action->{'Code'} == 0x88) {
            # 0x88: // ActionConstantPool
            for(my $idx_cp = 0;$idx_cp < @{$action->{'ConstantPool'}};$idx_cp++) {
                my $cp = @{$action->{'ConstantPool'}}[$idx_cp];
                if (exists($trans_table{$cp})) {
                    @{$action->{'ConstantPool'}}[$idx_cp] = $trans_table{$cp};
                }
            }
        }
        elsif ($action->{'Code'} == 0x96) {
            # 0x96: // ActionPush
            foreach my $value (%{$action->{'Values'}}) {
                if ($value->{'Type'} == 0) { # Type String
                    if (exists($trans_table{$value->{'String'}})) {
                        $value->{'String'} = $trans_table{$value->{'String'}};
                    }
                }
            }
        }
    }
    # don't touch $action, danger!
}

1;
