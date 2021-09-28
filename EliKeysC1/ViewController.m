//
//  ViewController.m
//  EliKeysC1
//
//  Created by Dror Kessler on 17/09/2021.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "KeyStateMachine.h"
#import <MIKMIDI/MIKMIDI.h>

#define SHOW_VOICES     1
#define SHOW_MIDI       1

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UILabel *status;

@property (nonatomic) AVSpeechSynthesisVoice* voice;
@property (nonatomic) AVSpeechSynthesizer* synth;
@property (nonatomic) KeyStateMachine* ksm;

@property int midiCommandCounter;
@property int noteOnKey;
@property int topNoteVelocity;
@property int velocityThreshold;
@property double secondsThreshold;
@property (nonatomic) NSDate* noteOnTimestamp;
@property BOOL addByTimestamp;
@property BOOL ignoreNextNoteOff;


- (void)midiCommands:(NSArray<MIKMIDICommand *> *)commands;
- (int)midiNoteToKeyInedex:(int)note;
- (void)timerMethod;

@end

@implementation ViewController


- (IBAction)buttonDown:(UIButton *)sender {
    [_ksm process:[sender.titleLabel.text intValue] With:0];
}
- (IBAction)buttonUpInside:(UIButton *)sender {
    [_ksm process:[sender.titleLabel.text intValue] With:1];
}

- (void)midiCommands:(NSArray<MIKMIDICommand *> *)commands {
    _midiCommandCounter += [commands count];
    //_status.text = [NSString stringWithFormat:@"midi commands: %d",_midiCommandCounter];
    
    for ( MIKMIDICommand* cmd in commands ) {
        MIKMIDICommandType ct = [cmd commandType];
        if ( ct == MIKMIDICommandTypeNoteOn || ct == MIKMIDICommandTypeNoteOff ) {
            MIKMIDINoteCommand*         c = (MIKMIDINoteCommand*)cmd;
            int                         note = (int)[c note];
            int                         velocity = (int)[c velocity];
            NSLog(@"%@, note:%d, velocity:%d", [c isNoteOn] ? @"NoteOn" : @"NoteOff", note, velocity);
            int                         key = [self midiNoteToKeyInedex:note];
            if ( key > 0 ) {
                if ( [c isNoteOn] ) {
                    _noteOnKey = key;
                    _ignoreNextNoteOff = FALSE;
                    [_ksm process:key With:0];
                    _topNoteVelocity = velocity;
                    _noteOnTimestamp = [c timestamp];
                } else if ( !_ignoreNextNoteOff ) {
                    _ignoreNextNoteOff = TRUE;
                    _topNoteVelocity = MAX(_topNoteVelocity, velocity);
                    if ( _addByTimestamp ) {
                        NSTimeInterval      interval = [[c timestamp] timeIntervalSinceDate:_noteOnTimestamp];
                        if ( interval > _secondsThreshold ) {
                            [_ksm process:key With:1];
                        }
                    } else {
                        if ( _topNoteVelocity > _velocityThreshold ) {
                            [_ksm process:key With:1];
                        }
                    }
                }
            }
        } else if ( ct == MIKMIDICommandTypeChannelPressure ) {
            MIKMIDIChannelPressureCommand* c = (MIKMIDIChannelPressureCommand*)cmd;
            int                         pressure = (int)[c pressure];
            NSLog(@"ChannelPressure, velocity:%d", pressure);
            _topNoteVelocity = MAX(_topNoteVelocity, pressure );
            if ( _addByTimestamp && !_ignoreNextNoteOff ) {
                NSTimeInterval      interval = [[c timestamp] timeIntervalSinceDate:_noteOnTimestamp];
                if ( interval > _secondsThreshold ) {
                    _ignoreNextNoteOff = TRUE;
                    [_ksm process:_noteOnKey With:1];
                }
            }
        } else if ( ct == MIKMIDICommandTypeControlChange ) {
            MIKMIDIControlChangeCommand* c = (MIKMIDIControlChangeCommand*)cmd;
            NSLog(@"ControlChange: %ld, %ld", [c controllerNumber], [c controllerValue]);
            if ( [c controllerNumber] == 11 ) {
                _velocityThreshold = (int)[c controllerValue];
                _status.text = [NSString stringWithFormat:@"%d, mode: %@", _velocityThreshold, _addByTimestamp ? @"Time" : @"Pressure"];
            } else if ( [c controllerNumber] == 10 ) {
                _secondsThreshold = (int)[c controllerValue] / (double)127 * 2;
                _addByTimestamp = [c controllerValue] != 127;
                _status.text = [NSString stringWithFormat:@"%f, mode: %@", _secondsThreshold, _addByTimestamp ? @"Time" : @"Pressure"];
            } else if ( [c controllerNumber] == 22 ) {
                if ( [c controllerValue] == 127 ) {
                    [_ksm resetMode];
                }
            }
        } else {
            NSLog(@"0x%lx", (unsigned long)ct);
        }
    }
}

- (void)timerMethod {
    if ( _addByTimestamp && !_ignoreNextNoteOff ) {
        NSTimeInterval      interval = [[NSDate now] timeIntervalSinceDate:_noteOnTimestamp];
        if ( interval > _secondsThreshold ) {
            _ignoreNextNoteOff = TRUE;
            [_ksm process:_noteOnKey With:1];
        }
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // inits
    _velocityThreshold = 50;
    _secondsThreshold = 0.75;
    _addByTimestamp = TRUE;
    _ignoreNextNoteOff = TRUE;

    // create key machine
    _ksm = [[KeyStateMachine alloc] initWith:self];
    
    // create speaking synth
    if ( SHOW_VOICES ) {
        NSArray<AVSpeechSynthesisVoice *> * voices = [AVSpeechSynthesisVoice speechVoices];
        for (AVSpeechSynthesisVoice* voice in voices) {
            NSLog(@"voice: %@: %@", [voice name], [voice language]);
        }
    }
    _voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"he-IL"];
    _synth = [[AVSpeechSynthesizer alloc] init];
    
    // list midi devices
    MIDINetworkSession* session = [MIDINetworkSession defaultSession];
    session.enabled = YES;
    session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
    [MIDINetworkSession defaultSession].enabled = YES;
    MIKMIDIDeviceManager* dm = [MIKMIDIDeviceManager sharedDeviceManager];
    NSArray<MIKMIDIDevice*>*    devs = [dm availableDevices];
    NSError                    *error;
    NSLog(@"devs: %@", devs);
    for ( MIKMIDIDevice* dev in devs ) {
        for ( MIKMIDIEntity* ent in [dev entities] ) {
            NSLog(@"ent: %@", ent);
            for ( MIKMIDIEndpoint* ep in [ent sources] ) {
                id tok1 = [dm connectInput:ep error:&error eventHandler:^(MIKMIDISourceEndpoint * _Nonnull source, NSArray<MIKMIDICommand *> * _Nonnull commands) {
                    //NSLog(@"source: %@, commands: %@", source,  commands);
                    [self performSelectorOnMainThread:@selector(midiCommands:) withObject:commands waitUntilDone:FALSE];
                }];
                NSLog(@"error: %@", error);
                NSLog(@"tok: %@", tok1);
            }
        }
    }
    
    // start timer
    NSTimer*     timer = [NSTimer timerWithTimeInterval:0.2 target:self selector:@selector(timerMethod) userInfo:nil repeats:TRUE];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)display:(NSString*)text {
    NSLog(@"display: %@", text);
    [_label setText:text];
}

- (void)beep {
    AudioServicesPlaySystemSound(1003);
}

- (void)beepClear {
    AudioServicesPlaySystemSound(1003);
}
- (void)beepAdded {
    AudioServicesPlaySystemSound(1004);
}
- (void)beepMode:(int)mode {
    AudioServicesPlaySystemSound(1007 + mode);
}

- (void)speak:(NSString*)text {
    
    AVSpeechUtterance*   utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    
    utterance.voice = _voice;
    utterance.rate = 0.37;
    utterance.pitchMultiplier = 0.8;
    utterance.postUtteranceDelay = 0.4;
    utterance.volume = 0.8;
    
    
    [_synth speakUtterance:utterance];
}

- (int)midiNoteToKeyInedex:(int)note {
    
    int     i = 1;
    for ( NSString* tok in [@"52,49,53,51,46,41,45,50,44,42,39,37,40,38,36,35" componentsSeparatedByString:@","] ) {
        if ( [tok intValue] == note )
            return i;
        i++;
    }
    return 0;
}


@end
