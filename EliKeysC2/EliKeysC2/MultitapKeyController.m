//
//  MultitapKeyController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 08/11/2021.
//

#import <Foundation/Foundation.h>
#import "MultitapKeyController.h"

@interface MultitapKeyController ()
@property (weak) ViewController* vc;
@property NSString* alphabet;
@property NSArray<NSNumber*>* keyInitialLetterIndex;
@property NSMutableArray<NSNumber*>* keyLetterIndex;
@property NSTimeInterval idleTimeInterval;
@property NSString* expectedLetter;
@property NSString* lastLetter;
@property NSString* gamePrompt;
@end

@implementation MultitapKeyController

// initilize instance
-(MultitapKeyController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        [self setVc:vc];
        self.alphabet = @"אבגדהוזחטיכלמנסעפצקרשת";
        self.keyInitialLetterIndex = @[
            @0,@1,@2,@3,
            @6,@7,@8,@9,
            @12,@13,@14,@15,
            @18,@19,@20,@21
        ];
        self.keyLetterIndex = [NSMutableArray arrayWithArray:_keyInitialLetterIndex];
        _idleTimeInterval = 1.5;
        self.gamePrompt = @"הַקְלִידִי";
    }
    return self;
}

-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag {
    
    return [NSArray arrayWithObjects:
            [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_NORMAL],
            [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_LONG_ADJUST],
            nil];
}

-(void)enter {
    [self reset];
    [[_vc speech] fspeak:@"משהו חדש"];
    [self performSelector:@selector(newRound) withObject:nil afterDelay:1.4];
}

-(void)reset {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(idleTimer:) object:nil];
    self.keyLetterIndex = [NSMutableArray arrayWithArray:_keyInitialLetterIndex];
    self.lastLetter = nil;
    
    srand((unsigned int)time(NULL));
}

-(void)keyPress:(NSUInteger)keyTag keyFilterIndex:(NSUInteger)filterIndex {
    
    if ( keyTag == 0 ) {
        [self newRound];
    } else if ( keyTag > 0 ) {
        
        // establish letter under key
        NSUInteger      keyIndex = keyTag - 1;
        NSUInteger      letterIndex = [[_keyLetterIndex objectAtIndex:keyIndex] intValue];
        NSString*       letter = [_alphabet substringWithRange:NSMakeRange(letterIndex, 1)];

        if ( filterIndex == 0 ) {


            // speak letter
            [[_vc speech] fspeak:letter];
            self.lastLetter = letter;
            
            // advance letter
            letterIndex = (letterIndex + 1) % [_alphabet length];
            [_keyLetterIndex setObject:[NSNumber numberWithUnsignedLong:letterIndex] atIndexedSubscript:keyIndex];
            
            // restart timer
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(idleTimer:) object:nil];
            [self performSelector:@selector(idleTimer:) withObject:nil afterDelay:_idleTimeInterval];
        } else {
            if ( !_lastLetter ) {
                self.lastLetter = letter;
            }
            if ( [_lastLetter isEqualToString:_expectedLetter] ) {
                [[_vc tones] multiToneRisingShort];
                [self performSelector:@selector(newRound) withObject:nil afterDelay:1.4];
            } else {
                [[_vc tones] beepError];
            }
        }
    }
}

-(void)idleTimer:(id)arg {
    
    // reset letter mapping
    [self reset];
}

-(void)newRound {
    
    [self reset];
    
    // pick a letter
    self.expectedLetter = [_alphabet substringWithRange:NSMakeRange(rand() % [_alphabet length], 1)];
    
    // speak challange
    [[_vc speech] fspeak:[NSString stringWithFormat:@"%@ %@", _gamePrompt, _expectedLetter]];
}

@end
