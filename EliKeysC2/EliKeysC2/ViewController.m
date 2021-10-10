//
//  ViewController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 05/10/2021.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MIKMIDI/MIKMIDI.h>
#import "PredictionTypingMachine.h"
#import "DBConnection.h"
#import "ToneGenerator.h"

#define SUGGEST_COUNT       4
#define LONG_PRESS_SECS     1.0

@interface ViewController ()
@property AVSpeechSynthesisVoice* voice;
@property AVSpeechSynthesizer* synth;
@property PredictionTypingMachine* ptm;
@property NSArray<NSString*>* suggestions;
@property ToneGenerator* tones;
@property NSDictionary<NSString*,NSString*>* midiNote2Key;
@property NSMutableSet<NSString*>* midiIgnoreNoteOff;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self setTones:[[ToneGenerator alloc] init]];
    
    [self testDb];
    [self loadVoice];
    [self loadMidi];
    [self setPtm:[[PredictionTypingMachine alloc] initWith:SUGGEST_COUNT]];
    [self reset];
}

- (IBAction)keyTouchDown:(UIButton*)sender {
    NSLog(@"keyTouchDown: %@", sender.titleLabel.text);
    
    [self performSelector:@selector(keyTimer:) withObject:sender afterDelay:LONG_PRESS_SECS];
    sender.tag = 0;
}

- (IBAction)keyTouchUpInside:(UIButton*)sender {
    if ( sender.tag == 0 ) {
        NSLog(@"keyTouchUpInside: %@", sender.titleLabel.text);
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(keyTimer:) object:sender];
        
        [self keyPress:sender.titleLabel.text];
    }
}

- (void)keyTimer:(UIButton*)sender {
    NSLog(@"keyTimer: %@", sender.titleLabel.text);
    sender.tag = 1;
    [self keyLongPress:sender.titleLabel.text];
}

-(void)keyPress:(NSString*)key {
 
    [self flushSpeechQueue];
    if ( [key isEqualToString:@"C"] ) {
        [self backspace];
    } else if ( [key isEqualToString:@"A"] ) {
        [self announce];
    } else if ( [key isEqualToString:@"S"] ) {
        [self space];
    } else if ( [key isEqualToString:@"N"] ) {
        [self next];
    } else if ( [key characterAtIndex:0] == 'B' ) {
        [self bank:[key characterAtIndex:1] - '1'];
    } else {
        [self key:[key intValue] - 1];
    }
}

-(void)keyLongPress:(NSString*)key {
    [self flushSpeechQueue];
    
    if ( [key isEqualToString:@"C"] ) {
        [self reset];
    } else if ( [key characterAtIndex:0] == 'B' ) {
        [self setBank:[key characterAtIndex:1] - '1'];
    } else if ( [key isEqualToString:@"A"] ) {
        [self announceLetterByLetter];
    } else {
        [self keyPress:key];
    }
}

-(void)loadVoice {
    [self setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"he-IL"]];
    [self setSynth:[[AVSpeechSynthesizer alloc] init]];
}

-(void)loadMidi {
    
    // initialize midi note to key mapping
    [self setMidiNote2Key:[NSDictionary dictionaryWithObjectsAndKeys:
                    @"1", @"52", @"2", @"49", @"3", @"53", @"4", @"51",
                    @"N", @"46", @"A", @"41", @"S", @"45", @"C", @"50",
                    @"B1", @"44", @"B2", @"42", @"B3", @"39", @"B4", @"37",
                           @"B5", @"40", @"B6", @"38", @"B7", @"36", @"B8", @"35", nil]];
    [self setMidiIgnoreNoteOff:[NSMutableSet set]];
    
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
}

-(void)beepOK {
    AudioServicesPlaySystemSound(1003);
}
-(void)beepError {
    AudioServicesPlaySystemSound(1004);
}

-(void)speak:(NSString*)text {
    
    text = [text stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    
    AVSpeechUtterance*   utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    
    utterance.voice = _voice;
    utterance.rate = 0.5;
    utterance.pitchMultiplier = 0.8;
    utterance.postUtteranceDelay = 0.1;
    utterance.volume = 0.6;
    
    
    [_synth speakUtterance:utterance];
}

-(void)flushSpeechQueue {
    [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self loadVoice];
}

-(void)reset {
    [self setSuggestions:[_ptm clear]];
    [self announce];
}

-(void)announce {
    [self speak:[self prepareForSpeech:[_ptm text]]];
    [self announceCommon];
}

-(void)announceLetterByLetter {
    NSString*   text = [_ptm text];
    for ( int i = 0 ; i < [text length] ; i++ ) {
        unichar     c = [text characterAtIndex:i];
        if ( c == ' ' ) {
            [self speak:@"רווח"];
        } else {
            [self speak:[NSString stringWithFormat:@"%C", c]];
        }
    }
    [self announceCommon];
}

-(void)announceCommon {
    if ( [_suggestions count] ) {
        [self speak:@"לבחירה"];
        for ( NSString* text in _suggestions ) {
            [self speak:text];
        }
    } else {
        [self speak:@"אין מה לבחור"];
    }
}

-(void)space {
    [self setSuggestions:[_ptm append:@" "]];
    [self announce];
}

-(void)backspace {
    [self setSuggestions:[_ptm backspace:1]];
    [self announce];
}

-(void)next {
    [self setSuggestions:[_ptm next]];
    if ( [_suggestions count] ) {
        for ( NSString* text in _suggestions ) {
            [self speak:text];
        }
    } else {
        [self speak:@"אין מה לבחור"];
    }
}

-(void)key:(int)keyIndex {
    if ( keyIndex < [_suggestions count] ) {;
        NSString*       s = [_suggestions objectAtIndex:keyIndex];
        [self setSuggestions:[_ptm append:s]];
        [self announce];
    } else {
        [self beepError];
    }
}

- (NSString*)bankConfKey:(int)bankIndex {
    return [NSString stringWithFormat:@"bank_%d", bankIndex + 1];
}

- (void)bank:(int)bankIndex {
    NSString*   text = [[NSUserDefaults standardUserDefaults] stringForKey:[self bankConfKey:bankIndex]];
    
    if ( [text length] ) {
        [self speak:[self prepareForSpeech:text]];
    } else {
        [self beepError];
    }
}

- (void)setBank:(int)bankIndex {
    NSString*    text = [NSString stringWithString:[_ptm text]];
    [[NSUserDefaults standardUserDefaults] setObject:text forKey:[self bankConfKey:bankIndex]];
    [self beepOK];
}



- (void)testDb {
    NSMutableArray*    results = [DBConnection fetchResults:@"select word,freq from words limit 1"];
    for ( NSDictionary* obj in results ) {
        NSLog(@"obj: %@", obj);
    }
}

-(NSString*)prepareForSpeech:(NSString*)text {
    
    NSMutableString*    result = [[NSMutableString alloc] init];
    NSUInteger          length = [text length];
    NSCharacterSet*     letters = [NSCharacterSet letterCharacterSet];
    NSString*           l1 = @"כמנפצ";
    NSString*           l2 = @"ךםןףץ";
 
    for ( NSUInteger n = 0 ; n < length ; n++ ) {
        unichar ch0 = (n > 0) ? [text characterAtIndex:n-1] : '\0';
        unichar ch1 = [text characterAtIndex:n];
        unichar ch2 = (n+1<length) ? [text characterAtIndex:n+1] : '\0';

        if ( [letters characterIsMember:ch0] && [letters characterIsMember:ch1] && ![letters characterIsMember:ch2] ) {
            for ( NSInteger m = 0 ; m < [l1 length] ; m++ ) {
                if ( ch1 == [l1 characterAtIndex:m] ) {
                    ch1 = [l2 characterAtIndex:m];
                    break;
                }
            }
        }
        
        [result appendFormat:@"%C", ch1];
    }
    
    NSLog(@"%@ -> %@", text, result);
    
    return result;
}

- (void)midiCommands:(NSArray<MIKMIDICommand *> *)commands {
    
    for ( MIKMIDICommand* cmd in commands ) {
        MIKMIDICommandType ct = [cmd commandType];
        if ( ct == MIKMIDICommandTypeNoteOn ) {
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];

            [_tones keyPressed];
            [_midiIgnoreNoteOff removeObject:key];
            [self performSelector:@selector(midiTimer:) withObject:key afterDelay:LONG_PRESS_SECS];
        }
        else if ( ct == MIKMIDICommandTypeNoteOff ) {
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(midiTimer:) object:key];
            if ( ![_midiIgnoreNoteOff containsObject:key] ) {
                [self keyPress:key];
            }
        } else if ( ct == MIKMIDICommandTypeControlChange ) {
            MIKMIDIControlChangeCommand* c = (MIKMIDIControlChangeCommand*)cmd;
            NSLog(@"ControlChange: %ld, %ld", [c controllerNumber], [c controllerValue]);
            if ( [c controllerNumber] == 22 ) {
                if ( [c controllerValue] == 127 ) {
                    [_tones keyPressed];
                    [self flushSpeechQueue];
                    [self speak:@"מהתחלה"];
                    [self reset];
                }
            }
        }
    }
}

- (void)midiTimer:(NSString*)key {
    [_midiIgnoreNoteOff addObject:key];
    [_tones keyLongPressed];
    [self keyLongPress:key];
}

- (NSString*)midiNoteToKey:(int)note {
    
    return [_midiNote2Key objectForKey:[NSString stringWithFormat:@"%d", note]];
}


@end
