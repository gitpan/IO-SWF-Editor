package IO::SWF::Type::Action;

use strict;
use warnings;

use base 'IO::SWF::Type';

use IO::Bit;
use IO::SWF::Type::String;
use IO::SWF::Type::Float;
use IO::SWF::Type::Double;

our %action_code_table = (
    #
    # Opecode only
    # 
    0x04 => 'NextFrame',
    0x05 => 'PreviousFrame',
    0x06 => 'Play',
    0x07 => 'Stop',
    0x08 => 'ToggleQuality',
    0x09 => 'StopSounds',
    #
    0x0A => 'Add',
    0x0B => 'Substract',
    0x0C => 'Multiply',
    0x0D => 'Divide',
    0x0E => 'Equals',
    0x0F => 'Less',
    0x10 => 'And',
    0x11 => 'Or',
    0x12 => 'Not',
    0x13 => 'StringEquals',
    0x14 => 'StringLength',
    0x15 => 'StringExtract',
    #
    0x17 => 'Pop',
    0x18 => 'ToInteger',
    #
    0x1C => 'GetVariable',
    0x1D => 'SetVariable',
    #
    0x20 => 'SetTarget2',
    0x21 => 'StringAdd',
    0x22 => 'GetProperty',
    0x23 => 'SetProperty',
    0x24 => 'CloneSprite',
    0x25 => 'RemoveSprite',
    0x26 => 'Trace',
    0x2D => 'FSCommand2', # Flash Lite
    #

    #
    0x27 => 'StartDrag',
    0x28 => 'EndDrag',
    0x29 => 'StringLess',
    #
    0x30 => 'RandomNumber',
    0x31 => 'MBStringLength',
    0x32 => 'CharToAscii',
    0x33 => 'AsciiToChar',
    0x34 => 'GetTime',
    0x35 => 'MBStringExtract',
    0x36 => 'MBCharToAscii',
    0x37 => 'MBAsciiToChar',

    #
    0x3A => 'Delete', # SWF 5
    0x3B => 'Delete2', # SWF 5
    0x3C => 'DefineLocal', # SWF 5
    0x3D => 'CallFunction', # SWF 5
    0x3E => 'Return', # SWF 5
    0x3F => 'Modulo', # SWF 5
    0x40 => 'NewObject', # SWF 5
    0x41 => 'DefineLocal2', # SWF 5
    0x42 => 'InitArray', # SWF 5
    0x43 => 'InitObject', # SWF 5
    0x44 => 'TypeOf', # SWF 5
    0x45 => 'TargetPath', # SWF 5
    0x46 => 'Enumerate', # SWF 5
    0x47 => 'Add2', # SWF 5
    0x48 => 'Less2', # SWF 5
    0x49 => 'Equals2', # SWF 5
    0x4A => 'ToNumber', # SWF 5
    0x4B => 'ToString', # SWF 5
    0x4C => 'PushDuplicate', # SWF 5
    0x4D => 'StackSwap', # SWF 5
    0x4E => 'GetMember', # SWF 5
    0x4F => 'SetMember', # SWF 5
    0x50 => 'Increment', # SWF 5
    0x51 => 'Decrement', # SWF 5
    0x52 => 'CallMethod', # SWF 5
    0x53 => 'NewMethod', # SWF 5
    0x54 => 'InstanceOf', # SWF 6
    0x55 => 'Enumerate2', # SWF 6
    #
    0x60 => 'BitAnd', # SWF 5
    0x61 => 'BitOr', # SWF 5
    0x62 => 'BitXOr', # SWF 5
    0x63 => 'BitShift', # SWF 5
    0x64 => 'BitURShift', # SWF 5
    #
    0x66 => 'StrictEquals', # SWF 6
    0x67 => 'Greater', # SWF 6
    0x68 => 'StringGreater', # SWF 6

    #
    # has Data Payload
    0x81 => 'GotoFrame',
    0x83 => 'GetURL',
    0x87 => 'StoreRegister', # SWF 5
    0x88 => 'ConstantPool', # SWF 5
    0x8A => 'WaitForFrame',
    0x8B => 'SetTarget',
    0x8C => 'GoToLabel',
    0x8D => 'WaitForFrame2',

    #
    0x94 => 'With', # SWF 5
    0x96 => 'Push',
    #
    0x99 => 'Jump',
    0x9A => 'GetURL2',
    0x9B => 'DefineFunction', # SWF 5
    #
    0x9D => 'If',
    0x9E => 'Call', # why it >=0x80 ?
    0x9E => 'GotoFrame2',
);

sub getCodeName {
    my $code = shift;
    if (defined $action_code_table{$code}) {
        return $action_code_table{$code};
    } else {
        return "Unknown";
    }
}

sub parse {
    my ($reader, $opts_href) = @_;
    my (%action, $data, @strs);
    my $code = $reader->getUI8();
    $action{'Code'} = $code;
    if ($code >= 0x80) {
        my $length = $reader->getUI16LE();
        $action{'Length'} = $length;
        if ($code == 0x81) {
            # 0x81: // ActionGotoFrame
            $action{'Frame'} = $reader->getUI16LE();
        }
        elsif ($code == 0x83) {
            # 0x83: // ActionGetURL
            $data = $reader->getData($length);
            @strs = split("\0", $data, 2+1);
            $action{'UrlString'} = $strs[0];
            $action{'TargetString'} = $strs[1];
        }
        elsif ($code == 0x88) {
            # 0x88: // ActionConstantPool
            my $count = $reader->getUI16LE();
            $action{'Count'} = $count;
            $data = $reader->getData($length - 2);
            @strs = split("\0", $data, $count+1);
            my @ConstantPool = @strs[0 .. $count-1];
            $action{'ConstantPool'} = \@ConstantPool;
        }
        elsif ($code == 0x8A) {
            # 0x8A: // ActionWaitForFrame
            $action{'Frame'} = $reader->getUI16LE();
            $action{'SkipCount'} = $reader->getUI8();
        }
        elsif ($code == 0x8B) {
            # 0x8B: // ActionSetTarget
            $data = $reader->getData($length);
            @strs = split("\0", $data, 1+1);
            $action{'TargetName'} = $strs[0];
        }
        elsif ($code == 0x8C) {
            # 0x8C: // ActionSetTarget
            $data = $reader->getData($length);
            @strs = split("\0", $data, 1+1);
            $action{'Label'} = $strs[0];
        }
        elsif ($code == 0x8D) {
            # 0x8D: // ActionWaitForFrame2
            $action{'Frame'} = $reader->getUI16LE();
            $action{'SkipCount'} = $reader->getUI8();
        }
        elsif ($code == 0x96) {
            # 0x96: // ActionPush
            my $data = $reader->getData($length);
            my @values = ();
            my $values_reader = IO::Bit->new();
            $values_reader->input($data);
            while ($values_reader->hasNextData()) {
                my %value = ();
                my $type = $values_reader->getUI8();
                $value{'Type'} = $type;
                if ($type == 0) {
                    # 0: // STRING
                    $value{'String'} = IO::SWF::Type::String::parse($values_reader);
                }
                elsif ($type == 1) {
                    # 1: // Float
                    $value{'Float'} = IO::SWF::Type::Float::parse($values_reader);
                }
                elsif ($type == 2) {
                    # 2: // null
                    $value{'null'} = undef();
                }
                elsif ($type == 3) {
                    # 3: // undefined
                    $value{'undefined'} = undef();
                }
                elsif ($type == 4) {
                    # 4: // RegisterNumber
                    $value{'RegisterNumber'} = $values_reader->getUI8();
                }
                elsif ($type == 5) {
                    # 5: // Boolean
                    $value{'Boolean'} = $values_reader->getUI8();
                }
                elsif ($type == 6) {
                    # 6: // Double
                    $value{'Double'} = IO::SWF::Type::Double::parse($values_reader);
                }
                elsif ($type == 7) {
                    # 7: // Integer
                    $value{'Integer'} = $values_reader->getUI32LE();
                }
                elsif ($type == 8) {
                    # 8: // Constant8
                    $value{'Constant8'} = $values_reader->getUI8();
                }
                elsif ($type == 9) {
                    # 9: // Constant16
                    $value{'Constant16'} = $values_reader->getUI16LE();
                }
                else {
                    die "Illegal ActionPush value's type($type)";
                }
                push @values, \%value;
            }
            $action{'Values'} = \@values;
        }
        elsif ($code == 0x99) {
            # 0x99: // ActionJump
            $action{'BranchOffset'} = $reader->getSI16LE();
        }
        elsif ($code == 0x9A) {
            # 0x9A: // ActionGetURL2
            $action{'SendVarsMethod'} = $reader->getUIBits(2);
            $action{'(Reserved)'} = $reader->getUIBits(4);
            $action{'LoadTargetFlag'} = $reader->getUIBit();
            $action{'LoadVariablesFlag'} = $reader->getUIBit();
        }
        elsif ($code == 0x9D) {
            # 0x9D: // ActionIf
            $action{'Offset'} = $reader->getSI16LE();
        }
        elsif ($code == 0x9F) {
            # 0x9F: // ActionGotoFrame2
            $action{'(Reserved)'} = $reader->getUIBits(6);
            my $sceneBlasFlag = $reader->getUIBit();
            $action{'SceneBlasFlag'} = $sceneBlasFlag;
            $action{'PlayFlag'} =  $reader->getUIBit();
            if ($sceneBlasFlag == 1) {
                $action{'SceneBias'} = $reader->getUI16LE();
            }
        }
        else {
            $action{'Data'} =  $reader->getData($length);
        }
    }
    return \%action;
}

sub build {
    my ($writer, $action_href, $opts_href) = @_;
    my %action = ref($action_href) ? %{$action_href} : ();
    my ($data, $count);

    my $code = $action{'Code'};
    $writer->putUI8($code);
    if (0x80 <= $code) {
        if ($code == 0x81) {
            # 0x81: // ActionGotoFrame
            $writer->putUI16LE(2);
            $writer->putUI16LE($action{'Frame'});
        }
        elsif ($code == 0x83) {
            # 0x83: // ActionGetURL
            $data = $action{'UrlString'}."\0".$action{'TargetString'}."\0";
            $writer->putUI16LE(length($data));
            $writer->putData($data);
        }
        elsif ($code == 0x88) {
            # 0x88: // ActionConstantPool
            my @ConstantPool = @{$action{'ConstantPool'}};
            $count = scalar(@ConstantPool);
            $data = join("\0", @ConstantPool) . "\0";
            $writer->putUI16LE(length($data) + 2);
            $writer->putUI16LE($count);
            $writer->putData($data);
        }
        elsif ($code == 0x8A) {
            # 0x8A: // ActionWaitForFrame
            $writer->putUI16LE($action{'Frame'});
            $writer->putUI8($action{'SkipCount'});
        }
        elsif ($code == 0x8B) {
            # 0x8B: // ActionSetTarget
            $data = $action{'TargetName'}."\0";
            $writer->putUI16LE(length($data));
            $writer->putData($data);
        }
        elsif ($code == 0x8C) {
            # 0x8C: // ActionGoToLabel
            $data = $action{'Label'}."\0";
            $writer->putUI16LE(length($data));
            $writer->putData($data);
        }
        elsif ($code == 0x8D) {
            # 0x8D: // ActionWaitForFrame2
            $writer->putUI16LE($action{'Frame'});
            $writer->putUI8($action{'SkipCount'});
        }
        elsif ($code == 0x96) {
            # 0x96: // ActionPush
            my $values_writer = IO::Bit->new();
            foreach my $value (@{$action{'Values'}}) {
                my $type = $value->{'Type'};
                $values_writer->putUI8($type);
                if ($type == 0) {
                    # 0: // STRING
                    my $str = $value->{'String'};
                    my $pos = index($str, "\0");
                    if ($pos < 0) {
                        $str .= "\0";
                    } else {
                        $str = substr($str, 0, $pos + 1);
                    }
                    $values_writer->putData($str);
                }
                elsif ($type == 1) {
                    # 1: // Float
                    IO::SWF::Type::Float::build($values_writer, $value->{'Float'});
                }
                elsif ($type == 2) {
                    # 2: // null
                    # nothing to do.
                }
                elsif ($type == 3) {
                    # 3: // undefined
                    # nothing to do.
                }
                elsif ($type == 4) {
                    # 4: // RegisterNumber
                    $values_writer->putUI8($value->{'RegisterNumber'});
                }
                elsif ($type == 5) {
                    # 5: // Boolean
                    $values_writer->putUI8($value->{'Boolean'});
                }
                elsif ($type == 6) {
                    # 6: // Double
                    IO::SWF::Type::Double::build($values_writer, $value->{'Double'});
                }
                elsif ($type == 7) {
                    # 7: // Integer
                    $values_writer->putUI32LE($value->{'Integer'});
                }
                elsif ($type == 8) {
                    # 8: // Constant8
                    $values_writer->putUI8($value->{'Constant8'});
                }
                elsif ($type == 9) {
                    # 9: // Constant16
                    $values_writer->putUI16LE($value->{'Constant16'});
                }
                else {
                    die "Illegal ActionPush value's type($type)";
                }
            }
            my $values_data = $values_writer->output();
            $writer->putUI16LE(length($values_data));
            $writer->putData($values_data);
        }
        elsif ($code == 0x99) {
            # 0x99: // ActionJump
            $writer->putUI16LE(2);
            $writer->putSI16LE($action{'BranchOffset'});
        }
        elsif ($code == 0x9A) {
            # 0x9A: // ActionGetURL2
            $writer->putUI16LE(1);
            $writer->putUIBits($action{'SendVarsMethod'}, 2);
            $writer->putUIBits(0, 4); # Reserved
            $writer->putUIBit($action{'LoadTargetFlag'});
            $writer->putUIBit($action{'LoadVariablesFlag'});
        }
        elsif ($code == 0x9D) {
            # 0x9D: // ActionIf
            $writer->putUI16LE(2);
            $writer->putSI16LE($action{'Offset'});
        }
        elsif ($code == 0x9F) {
            # 0x9F: // ActionGotoFrame2
            my $sceneBlasFlag;
            if (defined ($action{'SceneBias'})) {
                $sceneBlasFlag = 1;
                $writer->putUI16LE(3);
            } else {
                $sceneBlasFlag = 0;
                $writer->putUI16LE(1);
            }
            $writer->putUIBits(0, 6); # Reserved
            $writer->putUIBit($sceneBlasFlag);
            $writer->putUIBit($action{'PlayFlag'});
            if ($sceneBlasFlag) {
                $writer->putUI16LE($action{'SceneBias'});
            }
        }
        else {
            $data = $action{'Data'};
            $writer->putUI16LE(length($data));
            $writer->putData($data);
        }
    }
}

sub string {
    my ($action_href, $opts_href) = @_;
    my %action = ref($action_href) ? %{$action_href} : ();

    my $code = $action{'Code'};
    my $str = sprintf('%s(Code=0x%02X)', getCodeName($code), $code);
    if (defined ($action{'Length'})) {
        $str .= sprintf(" (Length=%d):", $action{'Length'});
        $str .= "\n\t";
        if ($code == 0x88) {
            # 0x88: // ActonConstantPool
            $str .= " Count=".$action{'Count'}."\n";
            my @ConstantPool = @{$action{'ConstantPool'}};
            for(my $idx = 0; $idx < @ConstantPool;$idx++) {
                $str .= "\t[$idx] " . $ConstantPool[$idx] . "\n";
            }
        }
        elsif ($code == 0x96) {
            $str .= "   ";
            foreach my $value (@{$action{'Values'}}) {
                foreach my $key (keys %{$value}) {
                    $str .= " ($key)".$value->{$key} if $key ne 'Type';
                }
            }
        }
        else {
            my @data_keys = keys %action;
            foreach my $key (keys %action) {
                next if ($key eq 'Code' || $key eq 'Length');
                my $value = $action{$key};
                if (ref($value) eq 'HASH') {
                    my @new_value = ();
                    foreach my $l_key (keys %{$value}) {
                        push @new_value, $l_key . ":" . $value->{$l_key};
                    }
                    $value = join(' ', @new_value);
                }
                $str .= "   " ."$key=$value";
            }
        }
    }
    return $str;
}

1;
