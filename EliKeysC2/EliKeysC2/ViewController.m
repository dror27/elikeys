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
#import "SpeechController.h"
#import "MidiController.h"
#import "KeyFilter.h"

#define SUGGEST_COUNT       4
#define LONG_PRESS_SECS     1.0

@interface ViewController ()
@property SpeechController* speech;
@property PredictionTypingMachine* ptm;
@property NSArray<NSString*>* suggestions;
@property ToneGenerator* tones;
@property MidiController* midi;
@property NSMutableDictionary<NSString*,KeyFilter*>* keyFilters;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];

    [self setSpeech:[[SpeechController alloc] init]];
    [self setTones:[[ToneGenerator alloc] init]];
    [self setMidi:[[MidiController alloc] initWith:self]];
    [self setKeyFilters:[NSMutableDictionary dictionary]];
    
    [self testDb];
    [self setPtm:[[PredictionTypingMachine alloc] initWith:SUGGEST_COUNT]];
    [self reset];
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
                [self keyPress:[keyFilter name]];
            else if ( exprIndex == 1 )
                [self keyLongPress:[keyFilter name]];
        }];
        [_keyFilters setObject:filter forKey:key];
    }
    return filter;
}

- (IBAction)keyTouchDown:(UIButton*)sender {
    NSLog(@"keyTouchDown: %@", sender.titleLabel.text);
    
    KeyFilter*      filter = [self filterForKey:sender.titleLabel.text];
    for ( KeyFilter* f in [_keyFilters allValues] ) {
        if ( f == filter )
            [f keyPressed];
        else
            [f otherPressed];
    }
}

- (IBAction)keyTouchUpInside:(UIButton*)sender {
    NSLog(@"keyTouchUpInside: %@", sender.titleLabel.text);

    KeyFilter*      filter = [self filterForKey:sender.titleLabel.text];
    for ( KeyFilter* f in [_keyFilters allValues] ) {
        if ( f == filter )
            [f keyReleased];
        else
            [f otherReleased];
    }
}


-(void)keyPress:(NSString*)key {
 
    [_speech flushSpeechQueue];
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
    [_speech flushSpeechQueue];
    
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


-(void)beepOK {
    AudioServicesPlaySystemSound(1003);
}
-(void)beepError {
    AudioServicesPlaySystemSound(1004);
}


-(void)reset {
    [self setSuggestions:[_ptm clear]];
    [self announce];
}

-(void)announce {
    [_speech speak:[_speech prepareForSpeech:[_ptm text]]];
    [self announceCommon];
}

-(void)announceLetterByLetter {
    NSString*   text = [_ptm text];
    for ( int i = 0 ; i < [text length] ; i++ ) {
        unichar     c = [text characterAtIndex:i];
        if ( c == ' ' ) {
            [_speech speak:@"רווח"];
        } else {
            [_speech speak:[NSString stringWithFormat:@"%C", c]];
        }
    }
    [self announceCommon];
}

-(void)announceCommon {
    if ( [_suggestions count] ) {
        [_speech speak:@"לבחירה"];
        for ( NSString* text in _suggestions ) {
            [_speech speak:text];
        }
    } else {
        [_speech speak:@"אין מה לבחור"];
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
            [_speech speak:text];
        }
    } else {
        [_speech speak:@"אין מה לבחור"];
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
        [_speech speak:[_speech prepareForSpeech:text]];
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

-(float)longKeyPressSecs {
    return LONG_PRESS_SECS;
}

@end
