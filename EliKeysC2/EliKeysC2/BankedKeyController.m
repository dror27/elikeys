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
@property int lastShift;
@property BOOL sliderShift;
@end

#define LETTER_MODE_COUNT       2

@implementation BankedKeyController

NSString        *letterKeys[3] = {
    @"אבגדהוזחטיכ ",
    @"למנסעפצקרשת ",
    @"1234567890. "
};
int             letterMode = 0;
NSString        *modeSpeechText[3] = {
    @"א עד כ",
    @"ל עד ת",
    @"מספרים"
};

// initilize instance
-(BankedKeyController*)initWith:(ViewController*)vc
{
    self = [super init];
    if (self) {
        [self setVc:vc];
        [self setSpeech:[_vc speech]];
        [self setWacc:[_vc wacc]];
    }
    return self;
}

-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag {
    
    KeyFilterExpr*        f1 = [[KeyFilterExpr alloc] initFromUserData:@"banked_keyfilter_1" withDefaultPattern: KEYFILTER_P_IMMEDIATE];
    [f1 setEmits:FALSE];

    /*
    KeyFilterExpr*        f2 = [[KeyFilterExpr alloc] initFromUserData:@"banked_keyfilter_2" withDefaultPattern: KEYFILTER_P_LONG];
     */
    KeyFilterExpr*        f2 = [[KeyFilterExpr alloc] initWithPattern:KEYFILTER_P_EXCLUSIVE_REPEAT];

    // hardcoded for now
    return [NSArray arrayWithObjects: f1, f2, nil];
}

-(void)reset {
    letterMode = 0;
}

-(void)keyPress:(NSUInteger)keyTag keyFilterIndex:(NSUInteger)filterIndex {
    [_speech flushSpeechQueue];
    [self process:keyTag With:filterIndex];
}

- (void)process:(NSUInteger)buttonIndex With:(NSUInteger)op {
    NSLog(@"process: %ld (%ld)", buttonIndex, op);
    if ( op == 0 ) {
        if ( buttonIndex == 0 ) {
            [self complete];
        } else if ( _completionWords == nil || buttonIndex > 12 ) {
            [_speech speak:[self buttonDiscoverySpokenText:buttonIndex]];
        } else {
            [self speakCompletionWordAtKey:buttonIndex];
        }
        return;
    }
    
    // keys 1-12 are letters
    if ( buttonIndex >= 1 && buttonIndex <= 12 ) {
        if ( _completionWords == nil ) {
            NSString*   letter = [NSString stringWithFormat:@"%C", [letterKeys[letterMode] characterAtIndex:buttonIndex - 1]];
            [_wacc append:letter];
            //[_vc beepOK];
            [[_vc tones] multiToneRisingShort];
        } else {
            NSString* word = [self completionWordAtKey:buttonIndex];
            if ( word != nil ) {
                [_wacc completeLastWord:word];
                //[_vc beepOK];
                [[_vc tones] multiToneRisingShort];
            } else {
                [_vc beepError];
            }
            _completionWords = nil;
        }
        
    } else if ( buttonIndex == 16 ) {
        [self shift:-1];
        [_wacc clear];
        _completionWords = nil;
        [_vc beepOK];
    } else if ( buttonIndex == 15 ) {
        if ( [_wacc length] > 0 ) {
            [_wacc backspace:1];
        }
        [self speakAcc];
    } else if ( buttonIndex == 14 ) {
        if ( _completionWords == nil ) {
            if ( _sliderShift ) {
                if ( letterMode != 2 ) {
                    letterMode = 2;
                } else
                    [self shift:-1];
            } else {
                letterMode = (letterMode + 1) % LETTER_MODE_COUNT;
            }
            [_speech speak:modeSpeechText[letterMode]];
        } else {
            _completionWords = nil;
            [_vc beepError];
        }
    } else if ( buttonIndex == 13 ) {
        [self speakAccLetterByLetter];
    }
}

-(void)shift:(int)v {
    if ( v >= 0 ) {
        letterMode = (v > _lastShift) ? 1 : 0;
        _lastShift = v;
    } else {
        letterMode = _lastLetterMode;
    }
}

-(void)resetMode {
    if ( _sliderShift ) {
        [self shift:-1];
    } else {
        letterMode = 0;
    }
    [_speech speak:modeSpeechText[letterMode]];
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
        NSString*   letter = [NSString stringWithFormat:@"%C", [letterKeys[letterMode] characterAtIndex:buttonIndex - 1]];
        if ( [letter isEqualToString:@" "] )
            letter = @"רווח";
        else if ( [letter isEqualToString:@"."] )
            letter = @"נקודה";
        return letter;
    } else if ( buttonIndex == 16 ) {
        return @"ניקוי";
    } else if ( buttonIndex == 15 ) {
        return @"מחיקה";
    } else if ( buttonIndex == 14 ) {
        return @"לוחות";
    } else if ( buttonIndex == 13 ) {
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

-(void)changeSliderShift:(BOOL)v {
    _sliderShift = v;
}


@end
