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
    [_keyController reset];
    
    NSLog(@"viewDidLoad: Done");
    
}

-(KeyFilter*)filterForKey:(NSString*)key {
    KeyFilter*      filter = [_keyFilters objectForKey:key];
    if ( !filter ) {
        filter = [[KeyFilter alloc] initName:key andExpressions:[_keyController filtersForKey:[key intValue]]
                                  usingBlock:^(KeyFilter *keyFilter, NSUInteger exprIndex) {
            [_keyController keyPress:[[keyFilter name] intValue] keyFilterIndex:exprIndex];
        }];
        [filter setDebug:FALSE];
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
    AudioServicesPlaySystemSound(1003);
}
-(void)beepError {
    AudioServicesPlaySystemSound(1004);
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
    [_keyController reset];
}

- (IBAction)modeValueChanged:(UISegmentedControl *)sender {
    [self switchKeyController:sender.selectedSegmentIndex];
}

@end
