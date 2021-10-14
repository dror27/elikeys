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
                    @"N", @"46", @"A", @"41", @"S", @"45", @"C", @"50",
                    @"B1", @"44", @"B2", @"42", @"B3", @"39", @"B4", @"37",
                           @"B5", @"40", @"B6", @"38", @"B7", @"36", @"B8", @"35", nil]];
    
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

- (void)midiCommands:(NSArray<MIKMIDICommand *> *)commands {
    
    for ( MIKMIDICommand* cmd in commands ) {
        MIKMIDICommandType ct = [cmd commandType];
        if ( ct == MIKMIDICommandTypeNoteOn ) {
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];
            [[_vc tones] keyPressed];
            [_vc key:key pressed:TRUE];
        }
        else if ( ct == MIKMIDICommandTypeNoteOff ) {
            NSString*                    key = [self midiNoteToKey:(int)[(MIKMIDINoteCommand*)cmd note]];
            [_vc key:key pressed:FALSE];
        } else if ( ct == MIKMIDICommandTypeControlChange ) {
            MIKMIDIControlChangeCommand* c = (MIKMIDIControlChangeCommand*)cmd;
            NSLog(@"ControlChange: %ld, %ld", [c controllerNumber], [c controllerValue]);
            if ( [c controllerNumber] == 22 ) {
                if ( [c controllerValue] == 127 ) {
                    [[_vc tones] keyPressed];
                    [_vc key:@"X" pressed:TRUE];
                } else {
                    [_vc key:@"X" pressed:FALSE];
                }
            }
        }
    }
}

- (NSString*)midiNoteToKey:(int)note {
    
    return [_midiNote2Key objectForKey:[NSString stringWithFormat:@"%d", note]];
}

@end
