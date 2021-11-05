//
//  MidiController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#ifndef MidiController_h
#define MidiController_h
#import "ViewController.h"

#define MIDI_CTRL_SLIDER        0
#define MIDI_CTRL_POT_UPPER     1
#define MIDI_CTRL_POT_LOWER     2
#define MIDI_CTRL_SW_A          3
#define MIDI_CTRL_SW_B          4


@interface MidiController : NSObject
-(MidiController*)initWith:(ViewController*)vc;
@end

#endif /* MidiController_h */
