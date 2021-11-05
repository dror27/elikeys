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
#import "PTMKeyController.h"
#import "BankedKeyController.h"
#import "MemoryKeyController.h"
#import "DBConnection.h"
#import "ToneGenerator.h"
#import "SpeechController.h"
#import "MidiController.h"
#import "WordsAccumulator.h"
#import "KeyFilter.h"

@interface ViewController ()
@property WordsAccumulator* wacc;
@property SpeechController* speech;
@property NSArray<id<KeyController>>* allKeyControllers;
@property id<KeyController> keyController;
@property ToneGenerator* tones;
@property MidiController* midi;
@property NSMutableDictionary<NSString*,KeyFilter*>* keyFilters;
@property (weak, nonatomic) IBOutlet UIMenu *modeMenu;
@property (weak, nonatomic) IBOutlet UICommand *modePredictor;
@property (weak, nonatomic) IBOutlet UISegmentedControl *modeControl;
@property (weak, nonatomic) IBOutlet UILabel *waccControl;
@property (weak, nonatomic) IBOutlet UISlider *upperPotSimulator;
@property (weak, nonatomic) IBOutlet UISlider *lowerPotSimulator;
@property (weak, nonatomic) IBOutlet UISlider *sliderSimulator;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    [self setWacc:[[WordsAccumulator alloc] init]];
    [self setSpeech:[[SpeechController alloc] init]];
    [self setTones:[[ToneGenerator alloc] init]];
    [self setMidi:[[MidiController alloc] initWith:self]];
    [self setKeyFilters:[NSMutableDictionary dictionary]];
    
    //[self testDb];

    [self setAllKeyControllers:[NSArray arrayWithObjects:
                                [[BankedKeyController alloc] initWith:self],
                                [[PTMKeyController alloc] initWith:self],
                                [[MemoryKeyController alloc] initWith:self],
                                nil]];
    [self setKeyController:[_allKeyControllers objectAtIndex:0]];
    [_keyController enter];
    [self updateWAccDisplay];
    
    NSLog(@"viewDidLoad: Done");
    //[_tones chromaticScaleRising:6];
    
}

-(KeyFilter*)filterForKey:(NSString*)key {
    KeyFilter*      filter = [_keyFilters objectForKey:key];
    if ( !filter ) {
        filter = [[KeyFilter alloc] initName:key andExpressions:[_keyController filtersForKey:[key intValue]]
                                  usingBlock:^(KeyFilter *keyFilter, NSUInteger exprIndex) {
            [_keyController keyPress:[[keyFilter name] intValue] keyFilterIndex:exprIndex];
            [self updateWAccDisplay];
        }];
        //[filter setDebug:FALSE];
        [filter adjust:[_upperPotSimulator value]];
        [_keyFilters setObject:filter forKey:key];
    }
    return filter;
}

-(void)key:(NSString*)key pressed:(BOOL)b {
    KeyFilter*      filter = [self filterForKey:key];
    for ( KeyFilter* f in [_keyFilters allValues] ) {
        if ( f == filter ) {
            if (b) [f keyPressed]; else [f keyReleased];
        } else {
            if (b) [f otherPressed]; else [f otherReleased];
        }
    }
    [self updateWAccDisplay];
}

-(void)controller:(NSUInteger)ctrl changedTo:(NSUInteger)value {
    
    if ( ctrl == MIDI_CTRL_SLIDER ) {
        [self adjustSpeed:value];
        [_sliderSimulator setValue:value];
    } else if ( ctrl == MIDI_CTRL_POT_LOWER ) {
        [self adjustVolume:value];
        [_lowerPotSimulator setValue:value];
    } else if ( ctrl == MIDI_CTRL_POT_UPPER ) {
        [self adjustKeyFilters:value];
        [_upperPotSimulator setValue:value];
    } else if ( ctrl == MIDI_CTRL_SW_A ) {
        [self nextMode];
    }
    
    [self updateWAccDisplay];
}

-(void)adjustSpeed:(NSUInteger)value {
    /* 0.25 - 0.75 */
    [_speech setRate:0.25 + value / 127.0 * (0.75 - 0.25)];
}

-(void)adjustVolume:(NSUInteger)value {
    [_speech setVolume:value / 127.0];
    [_tones setVolume:1.0 - value / 127.0];
}

-(void)adjustKeyFilters:(NSUInteger)value {
    for ( KeyFilter* keyFilter in [_keyFilters allValues] ) {
        [keyFilter adjust:value];
    }
}

- (IBAction)keyTouchDown:(UIButton*)sender {
    NSLog(@"keyTouchDown: %@", sender.titleLabel.text);
    [_tones keyPressed];
    [self key:[NSString stringWithFormat:@"%ld", sender.tag] pressed:TRUE];
}

- (IBAction)keyTouchUpInside:(UIButton*)sender {
    NSLog(@"keyTouchUpInside: %@", sender.titleLabel.text);
    [self key:[NSString stringWithFormat:@"%ld", sender.tag] pressed:FALSE];
}

-(void)beepOK {
    [_tones beepOK];
}
-(void)beepError {
    [_tones beepError];
}

- (void)testDb {
    NSMutableArray*    results = [DBConnection fetchResults:@"select word,freq from words limit 1"];
    for ( NSDictionary* obj in results ) {
        NSLog(@"obj: %@", obj);
    }
}

-(void)switchKeyController:(NSUInteger)index {

    [_speech flushSpeechQueue];
    [_keyFilters removeAllObjects];
    [self setKeyController:[_allKeyControllers objectAtIndex:index]];
    [_keyController enter];
    [self updateWAccDisplay];
}

- (IBAction)modeValueChanged:(UISegmentedControl *)sender {
    [self switchKeyController:sender.selectedSegmentIndex];
}

-(void)nextMode {
    NSUInteger      mode = (_modeControl.selectedSegmentIndex + 1) % _modeControl.numberOfSegments;
    _modeControl.selectedSegmentIndex = mode;
    [self modeValueChanged:_modeControl];
}

-(void)updateWAccDisplay {
    NSString*       text = [[_wacc asString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    [_waccControl setText:text];
}
- (IBAction)upperPotSimulatorValueChanged:(UISlider *)sender {
    [self adjustKeyFilters:[sender value]];
}
- (IBAction)controllerSimulatorValueChanged:(UISlider *)sender {
    NSUInteger      value = [sender value];
    if ( sender == _upperPotSimulator )
        [self adjustKeyFilters:value];
    else if ( sender == _lowerPotSimulator )
        [self adjustVolume:value];
    else if ( sender == _sliderSimulator )
        [self adjustSpeed:value];
}
@end
