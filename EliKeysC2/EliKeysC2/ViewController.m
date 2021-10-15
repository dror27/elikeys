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
#import "DBConnection.h"
#import "ToneGenerator.h"
#import "SpeechController.h"
#import "MidiController.h"
#import "WordsAccumulator.h"
#import "KeyFilter.h"

@interface ViewController ()
@property WordsAccumulator* wacc;
@property SpeechController* speech;
@property id<KeyController> keyController;
@property ToneGenerator* tones;
@property MidiController* midi;
@property NSMutableDictionary<NSString*,KeyFilter*>* keyFilters;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    [self setWacc:[[WordsAccumulator alloc] init]];
    [self setSpeech:[[SpeechController alloc] init]];
    [self setTones:[[ToneGenerator alloc] init]];
    [self setMidi:[[MidiController alloc] initWith:self]];
    [self setKeyFilters:[NSMutableDictionary dictionary]];
    
    [self testDb];
    [self setKeyController:[[PTMKeyController alloc] initWith:self]];
    [_keyController reset];
}

-(NSArray<NSRegularExpression*>*)expressionsForKey:(NSString*)key {
    
    // hardcoded for now
    return [NSArray arrayWithObjects:
            [NSRegularExpression regularExpressionWithPattern:KEYFILTER_P_NORMAL options:0 error:nil],
            [NSRegularExpression regularExpressionWithPattern:KEYFILTER_P_LONG options:0 error:nil],
            nil];
}

-(KeyFilter*)filterForKey:(NSString*)key {
    KeyFilter*      filter = [_keyFilters objectForKey:key];
    if ( !filter ) {
        filter = [[KeyFilter alloc] initName:key andExpressions:[self expressionsForKey:key]
                                  usingBlock:^(KeyFilter *keyFilter, NSUInteger exprIndex) {
            if ( exprIndex == 0 )
                [_keyController keyPress:[[keyFilter name] intValue]];
            else if ( exprIndex == 1 ) {
                [_tones keyLongPressed];
                [_keyController keyLongPress:[[keyFilter name] intValue]];
            }
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

@end
