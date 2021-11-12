//
//  BankedKeyController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 16/10/2021.
//

#import <Foundation/Foundation.h>
#import "ViewController.h"
#import "BankedKeyController.h"
#import "KeyFilter.h"
#import "WordsAccumulator.h"
#import "DBConnection.h"


@interface BankedKeyController ()
@property (weak) ViewController* vc;
@property SpeechController* speech;
@property WordsAccumulator* wacc;
@property NSArray<NSString*>* completionWords;
@property int lastLetterMode;
@property int letterMode;
@property NSArray<NSString*>* letterKeys;
@property NSArray<NSString*>* modeSpeechText;
@end

#define LETTER_MODE_COUNT       2

#define KEY_ANNOUNCE            13
#define KEY_BANKS               0
#define KEY_BACKSPACE           15
#define KEY_CLEAR               16
#define KEY_SUGGEST             14

@implementation BankedKeyController

// initilize instance
-(BankedKeyController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        
        _letterMode = 0;
        self.letterKeys = @[@"אבגדהוזחטיכ ",@"למנסעפצקרשת ",@"1234567890. "];
        self.modeSpeechText = @[@"א עד כ",@"ל עד ת",@"מספרים"];
        
        [self setVc:vc];
        [self setSpeech:[_vc speech]];
        [self setWacc:[_vc wacc]];
    }
    return self;
}

-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag {
    // default
    return nil;
}

-(void)reset {
    _letterMode = 0;
}

-(void)keyPress:(NSUInteger)keyTag keyFilterIndex:(NSUInteger)filterIndex {
    [_speech flushSpeechQueue];
    [self process:keyTag With:filterIndex];
}

- (void)process:(NSUInteger)buttonIndex With:(NSUInteger)op {
    NSLog(@"process: %ld (%ld)", buttonIndex, op);
    if ( op == 0 ) {
        if ( buttonIndex == KEY_SUGGEST ) {
            [self complete];
        } else if ( buttonIndex == KEY_BANKS ) {
            [self bankKey];
        } else if ( _completionWords == nil || buttonIndex == KEY_ANNOUNCE
                   || buttonIndex == KEY_BACKSPACE || buttonIndex == KEY_CLEAR ) {
            [_speech speak:[self buttonDiscoverySpokenText:buttonIndex]];
        } else {
            [self speakCompletionWordAtKey:buttonIndex];
        }
        return;
    }
    
    // keys 1-12 are letters
    if ( buttonIndex >= 1 && buttonIndex <= 12 ) {
        if ( _completionWords == nil ) {
            NSString*   letter = [NSString stringWithFormat:@"%C", [[_letterKeys objectAtIndex:_letterMode] characterAtIndex:buttonIndex - 1]];
            [_wacc append:letter];
            //[_vc beepOK];
            [[_vc tones] multiToneRisingShort];
            [_speech speak:[_speech prepareForSpeech:[_wacc asString]]];
            if ( [letter isEqualToString:@" "] )
                _letterMode = 0;
        } else {
            NSString* word = [self completionWordAtKey:buttonIndex];
            if ( word != nil ) {
                [_wacc completeLastWord:word];
                //[_vc beepOK];
                [[_vc tones] multiToneRisingShort];
                [_speech speak:[_speech prepareForSpeech:[_wacc asString]]];
                _letterMode = 0;
            } else {
                [_vc beepError];
            }
            _completionWords = nil;
        }
        
    } else if ( buttonIndex == KEY_CLEAR ) {
        _letterMode = 0;
        [_wacc clear];
        _completionWords = nil;
        [_vc beepOK];
    } else if ( buttonIndex == KEY_BACKSPACE ) {
        if ( [_wacc length] > 0 ) {
            [_wacc backspace:1];
        }
        [self speakAcc];
    } else if ( buttonIndex == KEY_BANKS ) {
    } else if ( buttonIndex == KEY_ANNOUNCE ) {
        [self speakAccLetterByLetter];
    }
}

-(void)bankKey {
    if ( _completionWords == nil ) {
        _letterMode = (_letterMode + 1) % LETTER_MODE_COUNT;
        [_speech speak:[_modeSpeechText objectAtIndex: _letterMode]];
    } else {
        _completionWords = nil;
        [_vc beepError];
    }
}

-(void)resetMode {
    _letterMode = 0;
    [_speech speak:[_modeSpeechText objectAtIndex:_letterMode]];
}

-(void)speakAcc {
    if ( [_wacc length] == 0 )
        [_vc beepOK];
    else
        [_speech speak:[_speech prepareForSpeech:[_wacc asString]]];
}
    
-(void)speakAccLetterByLetter {
    NSString*   text = [_wacc asString];
    for ( int i = 0 ; i < [text length] ; i++ ) {
        unichar     c = [text characterAtIndex:i];
        if ( c == ' ' ) {
            [_speech speak:@"רווח"];
        } else {
            [_speech speak:[NSString stringWithFormat:@"%C", c]];
        }
    }
}


-(NSString*)prepForSpeech:(NSString*)text {
    
    NSMutableString*    result = [[NSMutableString alloc] init];
    NSUInteger          length = [text length];
    NSCharacterSet*     letters = [NSCharacterSet letterCharacterSet];
    NSString*           l1 = @"כמנפצ";
    NSString*           l2 = @"ךםןףץ";
 
    for ( NSUInteger n = 0 ; n < length ; n++ ) {
        unichar ch1 = [text characterAtIndex:n];
        unichar ch2 = (n+1<length) ? [text characterAtIndex:n+1] : '\0';
        
        if ( [letters characterIsMember:ch1] && ![letters characterIsMember:ch2] ) {
            for ( NSInteger m = 0 ; m < [l1 length] ; m++ ) {
                if ( ch1 == [l1 characterAtIndex:m] ) {
                    ch1 = [l2 characterAtIndex:m];
                    break;
                }
            }
        }
        
        [result appendFormat:@"%C", ch1];
    }
    
    NSLog(@"%@ -> %@", text, result);
    
    return result;
}

-(NSString*)buttonDiscoverySpokenText:(NSUInteger)buttonIndex {
    
    // keys 1-12 are letters
    if ( buttonIndex >= 1 && buttonIndex <= 12 ) {
        NSString*   letter = [NSString stringWithFormat:@"%C", [[_letterKeys objectAtIndex:_letterMode] characterAtIndex:buttonIndex - 1]];
        if ( [letter isEqualToString:@" "] )
            letter = @"רווח";
        else if ( [letter isEqualToString:@"."] )
            letter = @"נקודה";
        return letter;
    } else if ( buttonIndex == KEY_CLEAR ) {
        return @"ניקוי";
    } else if ( buttonIndex == KEY_BACKSPACE ) {
        return @"מחיקה";
    } else if ( buttonIndex == KEY_BANKS ) {
        return @"לוחות";
    } else if ( buttonIndex == KEY_ANNOUNCE ) {
        if ( [_wacc length] )
            return [_speech prepareForSpeech:[_wacc asString]];
        else
            return @"הקראה";
    } else {
        return @"";
    }
}

- (NSArray<NSString*>*)queryCompletionsFor:(NSString*)prefix {
    
    NSString*           query = [NSString stringWithFormat:@"select word,freq from words where word like '%@%%' and word != '%@' order by freq desc limit 12", prefix, prefix];
    NSLog(@"query: %@", query);
    NSMutableArray*    results = [DBConnection fetchResults:query];
    NSMutableArray*    words = [[NSMutableArray alloc] init];
    for ( NSDictionary* obj in results ) {
        NSString*       word = [obj objectForKey:@"word"];
        NSLog(@"word: %@", word);
        [words addObject:word];
    }
    return words;
}


-(void)complete {
    
    if ( _completionWords == nil ) {
    
        // extract last uncompleted word from accumulator
        NSString*       lastWord = [self completeLastWord];
        if ( lastWord == nil ) {
            [_vc beepError];
            return;
        }
        
        // query words
        _completionWords = [self queryCompletionsFor:lastWord];
        if ( [_completionWords count] == 0 ) {
            _completionWords = nil;
            [_vc beepError];
        }
    } else {
        _completionWords = nil;
        [_vc beepError];
    }
    
    // speak page
    [self speakCompletionPage];
}

-(NSString*)completeLastWord {
    NSString*       lastWord = [[[_wacc asString] componentsSeparatedByString:@" "] lastObject];
    if ( lastWord == nil || [lastWord isEqualToString:@""] ) {
        return nil;
    } else {
        return lastWord;
    }
}

-(void)speakCompletionPage {
    
    // get words to speak
    NSMutableString*    text = [NSMutableString stringWithFormat:@""];
    for ( int i = 0 ; i <  4 ; i++ ) {
        if ( i < [_completionWords count] ) {
            [text appendFormat:@"%@. ", [_completionWords objectAtIndex:i]];
        }
    }
    [_speech speak:text];
}

-(void)speakCompletionWordAtKey:(NSUInteger)key {
    NSString*       word = [self completionWordAtKey:key];
    if ( word != nil ) {
        [_speech speak:word];
    } else {
        [_vc beepError];
    }
}

-(NSString*)completionWordAtKey:(NSUInteger)key {
    NSUInteger     i = (key - 1);
    if ( i < [_completionWords count] ) {
        return [_completionWords objectAtIndex:i];
    } else {
        return nil;
    }
}

-(void)enter {
    [_speech flushSpeechQueue];
    [_speech speak:@"מקלדת"];
    [self reset];
}

@end
