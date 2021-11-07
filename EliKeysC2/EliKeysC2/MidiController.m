//
//  MidiController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#import <Foundation/Foundation.h>
#import <MIKMIDI/MIKMIDI.h>
#import "MidiController.h"
#import "ViewController.h"

@interface MidiController ()
@property (weak) ViewController* vc;
@property NSDictionary<NSString*,NSString*>* midiNote2Key;
@end

@implementation MidiController

-(MidiController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        [self setVc:vc];
        [self loadMidi];
    }
    return self;
}

-(void)loadMidi {
    
    // initialize midi note to key mapping
    [self setMidiNote2Key:[NSDictionary dictionaryWithObjectsAndKeys:
                    @"1", @"52", @"2", @"49", @"3", @"53", @"4", @"51",
                    @"5", @"46", @"6", @"41", @"7", @"45", @"8", @"50",
                    @"9", @"44", @"10", @"42", @"11", @"39", @"12", @"37",
                    @"13", @"40", @"14", @"38", @"15", @"36", @"16", @"35", nil]];
    
    // list midi devices
    MIDINetworkSession* session = [MIDINetworkSession defaultSession];
    session.enabled = YES;
    session.connectionPolicy = MIDINetworkConnectionPolicy_Anyone;
    [MIDINetworkSession defaultSession].enabled = YES;
    MIKMIDIDeviceManager* dm = [MIKMIDIDeviceManager sharedDeviceManager];
    NSArray<MIKMIDIDevice*>*    devs = [dm availableDevices];
    NSError                    *error;
    //NSLog(@"devs: %@", devs);
    for ( MIKMIDIDevice* dev in devs ) {
        for ( MIKMIDIEntity* ent in [dev entities] ) {
            //NSLog(@"ent: %@", ent);
            for ( MIKMIDIEndpoint* ep in [ent sources] ) {
                id tok1 = [dm connectInput:ep error:&error eventHandler:^(MIKMIDISourceEndpoint * _Nonnull source, NSArray<MIKMIDICommand *> * _Nonnull commands) {
                    //NSLog(@"source: %@, commands: %@", source,  commands);
                    [self performSelectorOnMainThread:@selector(midiCommands:) withObject:commands waitUntilDone:FALSE];
                }];
                if ( error ) {
                    NSLog(@"error: %@", error);
                }
                //NSLog(@"tok: %@", tok1);
            }
        }
    }
}

- (void)midiCommands:(NSArray<MIKMIDICommand *> *)commands {
    
    for ( MIKMIDICommand* cmd in commands ) {
        MIKMIDICommandType ct = [cmd commandType];
        if ( ct == MIKMIDICommandTypeNoteOn ) {
            [[_vc eventLogger] log:EL_TYPE_MIDI subtype:EL_SUBTYPE_MIDI_NOTE_ON
                          uintValue:[(MIKMIDINoteCommand*)cmd note] uintMore:[(MIKMIDINoteCommand*)cmd velocity]];
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];
            //[[_vc tones] keyPressed];
            [_vc key:key pressed:TRUE];
        } else if ( ct == MIKMIDICommandTypeNoteOff ) {
            [[_vc eventLogger] log:EL_TYPE_MIDI subtype:EL_SUBTYPE_MIDI_NOTE_OFF
                          uintValue:[(MIKMIDINoteCommand*)cmd note] uintMore:[(MIKMIDINoteCommand*)cmd velocity]];
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];
            [_vc key:key pressed:FALSE];
        } else if ( ct == MIKMIDICommandTypePolyphonicKeyPressure ) {
            [[_vc eventLogger] log:EL_TYPE_MIDI subtype:EL_SUBTYPE_MIDI_PRESSURE
                         uintValue:[(MIKMIDIPolyphonicKeyPressureCommand*)cmd note] uintMore:[(MIKMIDIPolyphonicKeyPressureCommand*)cmd pressure]];
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];
            [_vc key:key pressed:FALSE];
        } else if ( ct == MIKMIDICommandTypeControlChange ) {
            MIKMIDIControlChangeCommand* c = (MIKMIDIControlChangeCommand*)cmd;
            [[_vc eventLogger] log:EL_TYPE_MIDI subtype:EL_SUBTYPE_MIDI_CTRL
                          uintValue:[c controllerNumber] uintMore:[c controllerValue]];
            NSLog(@"ControlChange: %ld, %ld", [c controllerNumber], [c controllerValue]);
            NSUInteger      ctrl = [c controllerNumber];
            NSUInteger      value = [c controllerValue];
            if ( ctrl == 22 ) {
                if ( value == 127 ) {
                    //[[_vc tones] keyPressed];
                    [_vc key:@"X" pressed:TRUE];
                } else {
                    [_vc key:@"X" pressed:FALSE];
                }
            } else if ( ctrl == 1 ) {
                [_vc controller:MIDI_CTRL_SLIDER changedTo:value];
            } else if ( ctrl == 10 ) {
                [_vc controller:MIDI_CTRL_POT_UPPER changedTo:value];
            } else if ( ctrl == 11 ) {
                [_vc controller:MIDI_CTRL_POT_LOWER changedTo:value];
            } else if ( ctrl == 20 ) {
                [_vc controller:MIDI_CTRL_SW_A changedTo:value];
            } else if ( ctrl == 21 ) {
                [_vc controller:MIDI_CTRL_SW_B changedTo:value];
            }
        }
    }
}

- (NSString*)midiNoteToKey:(int)note {
    
    return [_midiNote2Key objectForKey:[NSString stringWithFormat:@"%d", note]];
}

@end
