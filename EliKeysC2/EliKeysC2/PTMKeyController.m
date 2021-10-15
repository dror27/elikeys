//
//  PTMKeyController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import "PTMKeyController.h"
#import "PredictionTypingMachine.h"
#import "SpeechController.h"

#define SUGGEST_COUNT       4

@interface PTMKeyController ()
@property (weak) ViewController* vc;
@property PredictionTypingMachine* ptm;
@property NSArray<NSString*>* suggestions;
@property SpeechController* speech;
@end

@implementation PTMKeyController

// initilize instance
-(PTMKeyController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        [self setVc:vc];
        [self setSpeech:[_vc speech]];
        [self setPtm:[[PredictionTypingMachine alloc] initWithWAcc:[_vc wacc] andBlockSize:SUGGEST_COUNT]];
    }
    return self;
}

-(void)keyPress:(NSUInteger)tag {
    
    NSString*       key = [self keyNameForTag:tag];
 
    [_speech flushSpeechQueue];
    if ( [key isEqualToString:@"C"] ) {
        [self backspace];
    } else if ( [key isEqualToString:@"A"] ) {
        [self announce];
    } else if ( [key isEqualToString:@"S"] ) {
        [self space];
    } else if ( [key isEqualToString:@"N"] ) {
        [self next];
    } else if ( [key isEqualToString:@"X"] ) {
        [_speech flushSpeechQueue];
        [_speech speak:@"מהתחלה"];
        [self reset];
    } else if ( [key characterAtIndex:0] == 'B' ) {
        [self bank:[key characterAtIndex:1] - '1'];
    } else {
        [self key:[key intValue] - 1];
    }
}

-(void)keyLongPress:(NSUInteger)tag {

    NSString*       key = [self keyNameForTag:tag];

    [_speech flushSpeechQueue];
    
    if ( [key isEqualToString:@"C"] ) {
        [self reset];
    } else if ( [key characterAtIndex:0] == 'B' ) {
        [self setBank:[key characterAtIndex:1] - '1'];
    } else if ( [key isEqualToString:@"A"] ) {
        [self announceLetterByLetter];
    } else {
        [self keyPress:tag];
    }
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
        [_vc beepError];
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
        [_vc beepError];
    }
}

- (void)setBank:(int)bankIndex {
    NSString*    text = [NSString stringWithString:[_ptm text]];
    [[NSUserDefaults standardUserDefaults] setObject:text forKey:[self bankConfKey:bankIndex]];
    [_vc beepOK];
}

- (NSString*)keyNameForTag:(NSUInteger)tag {
    return [[@"X,1,2,3,4,N,A,S,C,B1,B2,B3,B4,B5,N6,B7,B8" componentsSeparatedByString:@","] objectAtIndex:tag];
}

@end

