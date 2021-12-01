//
//  ViewController.m
//  EliKeysC3
//
//  Created by Dror Kessler on 01/12/2021.
//

#import "ViewController.h"
#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#import "EventLogger.h"
#import "SpeechController.h"
#import "ToneGenerator.h"
#import "KeyFilter.h"
#import "KeyController.h"
#import "LetterGameKeyController.h"
#import "WordsAccumulator.h"

@interface ViewController ()
@property EventLogger* eventLogger;
@property SpeechController* speech;
@property ToneGenerator* tones;
@property NSMutableDictionary<NSString*,KeyFilter*>* keyFilters;
@property id<KeyController> keyController;
@property WordsAccumulator* wacc;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setEventLogger:[[EventLogger alloc] init]];
    [self setSpeech:[[SpeechController alloc] init]];
    [self setTones:[[ToneGenerator alloc] init]];
    [self setWacc:[[WordsAccumulator alloc] init]];
    [self setKeyFilters:[NSMutableDictionary dictionary]];
    
    [_speech setEventLogger:_eventLogger];
    [_wacc setEventLogger:_eventLogger];
    
    [self setKeyController:[[LetterGameKeyController alloc] initWith:self]];
    [_keyController enter];
    
    [self rotateLabel:_waccControl];
    
    NSLog(@"viewDidLoad: Done");
}

-(KeyFilter*)filterForKey:(NSString*)key {
    KeyFilter*      filter = [_keyFilters objectForKey:key];
    if ( !filter ) {
        filter = [[KeyFilter alloc] initName:key andExpressions:[self filtersForKey:[key intValue] forKeyController:_keyController]
                                  usingBlock:^(KeyFilter *keyFilter, NSUInteger exprIndex) {
            int     keyIndex = [[keyFilter name] intValue];
            [_eventLogger log:EL_TYPE_FILTER subtype:EL_SUBTYPE_FILTER_FIRE uintValue:keyIndex uintMore:exprIndex];
            [_keyController keyPress:keyIndex keyFilterIndex:exprIndex];
            [self updateWAccDisplay];
        }];
        //[filter setDebug:FALSE];
        [filter setEventLogger:_eventLogger];
        [filter adjust:[_slider3Control value]];
        [_keyFilters setObject:filter forKey:key];
    }
    return filter;
}

-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag forKeyController:(id<KeyController>) keyController {
    
    NSArray<KeyFilterExpr*>*    filters = [keyController filtersForKey:keyTag];
    if ( filters )
        return filters;
    
    // default
    KeyFilterExpr           *f1 = [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_IMMEDIATE];
    [f1 setEmits:FALSE];
    return [NSArray arrayWithObjects:
            f1,
            [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_LONG_ADJUST],
            nil];
}

-(void)updateWAccDisplay {
    NSString*       text = [[_wacc asString] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
    [_waccControl setText:text];
}

-(void)rotateLabel:(UILabel*) label
{
    CGRect orig = label.frame;
    label.transform=CGAffineTransformMakeRotation(M_PI * 3/2);//270º
    label.frame = orig;
}

-(void)key:(NSString*)key pressed:(BOOL)b {
    
    // log
    [_eventLogger log:EL_TYPE_KEY subtype:b ? EL_SUBTYPE_KEY_PRESS : EL_SUBTYPE_KEY_RELEASE value:key more:nil];
    
    // process
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

- (IBAction)controllerSimulatorValueChanged:(UISlider *)sender {
    NSUInteger      value = [sender value];
    if ( sender == _slider3Control )
        [self adjustKeyFilters:value];
    else if ( sender == _slider2Control )
        [self adjustVolume:value];
    else if ( sender == _slider1Control )
        [self adjustSpeed:value];
}



@end
