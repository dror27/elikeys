//
//  MultitapKeyController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 08/11/2021.
//

#import <Foundation/Foundation.h>
#import "LetterGameKeyController.h"

@interface LetterGameKeyController ()
@property (weak) ViewController* vc;
@property NSString* alphabet;
@property NSString* expectedLetter;
@property NSString* gamePrompt;
@property NSString* abandonPrompt;
@property int turnDiscoveryCount;
@property int turnWrongTypingCount;
@property int turnWrongTypingLimit;
@property NSDate* turnStartedOn;
@property double newTurnDelay;
@end

@implementation LetterGameKeyController

// initilize instance
-(LetterGameKeyController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        [self setVc:vc];
        self.alphabet = @"אבגדהוזחטיכלמנסעפצקרשת";
        self.gamePrompt = @"הַקְלִידִי";
        self.abandonPrompt = @"ננסה אות אחרת";
        _turnWrongTypingLimit = 3;
        _newTurnDelay = 1.4;
    }
    return self;
}

-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag {
    
    return nil;
}

-(void)enter {
    srand((unsigned int)time(NULL));
    [self reset];
    [[_vc speech] fspeak:@"משהו חדש"];
    [self performSelector:@selector(newTurn) withObject:nil afterDelay:_newTurnDelay * 2];
}

-(void)reset {
}

-(void)keyPress:(NSUInteger)keyTag keyFilterIndex:(NSUInteger)filterIndex {
    
    if ( keyTag > 0 ) {
        
        // establish letter under key
        NSUInteger      keyIndex = keyTag - 1;
        NSUInteger      letterIndex = keyIndex;
        if ( letterIndex >= [_alphabet length] )
            return;
        NSString*       letter = [_alphabet substringWithRange:NSMakeRange(letterIndex, 1)];

        if ( filterIndex == 0 ) {

            // speak letter
            [[_vc speech] fspeak:letter];
            _turnDiscoveryCount++;
                        
        } else {
            if ( [letter isEqualToString:_expectedLetter] ) {
                [[_vc tones] multiToneRisingShort];
                [self performSelector:@selector(newTurn) withObject:nil afterDelay:_newTurnDelay];
                
                [self log:@"Correct" value:letter more:[NSString stringWithFormat:@"D:%d W:%d T:%f",
                            _turnDiscoveryCount, _turnWrongTypingCount, -[_turnStartedOn timeIntervalSinceNow]]];
            } else {
                [[_vc tones] beepError];
                _turnWrongTypingCount++;
                [self log:@"Wrong" value:letter more:[NSString stringWithFormat:@"D:%d W:%d T:%f",
                            _turnDiscoveryCount, _turnWrongTypingCount, -[_turnStartedOn timeIntervalSinceNow]]];
                if ( _turnWrongTypingCount < _turnWrongTypingLimit )
                    [self speakChallange];
                else {
                    [self log:@"Abandon" value:letter more:[NSString stringWithFormat:@"D:%d W:%d T:%f",
                                _turnDiscoveryCount, _turnWrongTypingCount, -[_turnStartedOn timeIntervalSinceNow]]];
                    [[_vc speech] fspeak:_abandonPrompt];
                    [self performSelector:@selector(newTurn) withObject:nil afterDelay:_newTurnDelay * 1.5];

                }
            }
        }
    }
}

-(void)newTurn {
    
    [self reset];
    _turnDiscoveryCount = 0;
    _turnWrongTypingCount = 0;
    self.turnStartedOn = [NSDate now];
    
    // pick a letter
    self.expectedLetter = [_alphabet substringWithRange:NSMakeRange(rand() % [_alphabet length], 1)];
    
    // speak challange
    [self speakChallange];
    
    [self log:@"NewTurn" value:_expectedLetter more:nil];
}

-(void)speakChallange {
    [[_vc speech] fspeak:[NSString stringWithFormat:@"%@ %@", _gamePrompt, _expectedLetter]];
}

-(void)log:(NSString*)msg value:(NSString*)value more:(NSString*)more {
    [[_vc eventLogger] log:@"LetterGame" subtype:msg value:value more:more];
}

@end
