//
//  KeyStateMachine.m
//  EliKeysC1
//
//  Created by Dror Kessler on 20/09/2021.
//

#import <Foundation/Foundation.h>
#import "KeyStateMachine.h"

@interface KeyStateMachine ()
@property ViewController *viewController;
@property NSMutableString *acc;
@property NSArray<NSString*>* completionWords;
@property int lastLetterMode;
@property int lastShift;
@property BOOL sliderShift;

-(void)speakAcc;
-(NSString*)prepForSpeech:(NSString*)text;
-(NSString*)buttonDiscoverySpokenText:(int)buttonIndex;

@end

@implementation KeyStateMachine
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

- (KeyStateMachine*)initWith:(ViewController*)viewController
{
    self = [super init];
    if (self) {
        _viewController = viewController;
        _acc = [[NSMutableString alloc] init];
        
        _completionWords = nil;
        [_viewController display:_acc];
    }
    return self;
}

- (void)process:(int)buttonIndex With:(int)op {
    NSLog(@"process: %d (%d)", buttonIndex, op);
    if ( op == 0 ) {
        if ( _completionWords == nil || buttonIndex > 12 ) {
            [_viewController speak:[self buttonDiscoverySpokenText:buttonIndex]];
        } else {
            [self speakCompletionWordAtKey:buttonIndex];
        }
        return;
    }
    
    // keys 1-12 are letters
    if ( buttonIndex >= 1 && buttonIndex <= 12 ) {
        if ( _completionWords == nil ) {
            NSString*   letter = [NSString stringWithFormat:@"%C", [letterKeys[letterMode] characterAtIndex:buttonIndex - 1]];
            [_acc appendString:letter];
            [_viewController display:_acc];
            //[self speakAcc];
            [_viewController beepAdded];
        } else {
            NSString* word = [self completionWordAtKey:buttonIndex];
            if ( word != nil ) {
                NSString*   lastWord = [self completeLastWord];
                NSString*   suffix = [word substringFromIndex:[lastWord length]];
                [_acc appendString:suffix];
                [_acc appendString:@" "];
                [_viewController display:_acc];
                [_viewController beepAdded];
            } else {
                [_viewController beep];
            }
            _completionWords = nil;
        }
        
    } else if ( buttonIndex == 16 ) {
        [self shift:-1];
        [_acc setString:@""];
        _completionWords = nil;
        [_viewController display:_acc];
        [_viewController beepClear];
    } else if ( buttonIndex == 15 ) {
        if ([_acc length] > 0 ) {
            [_acc deleteCharactersInRange:NSMakeRange([_acc length]-1, 1)];
            [_viewController display:_acc];
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
                letterMode = (letterMode + 1) % 3;
            }
            [_viewController speak:modeSpeechText[letterMode]];
            [_viewController updateStatus];
        } else {
            _completionWords = nil;
            [_viewController beep];
        }
    } else if ( buttonIndex == 13 ) {
        [self speakAcc];
    }
}

-(void)shift:(int)v {
    if ( v >= 0 ) {
        letterMode = (v > _lastShift) ? 1 : 0;
        _lastShift = v;
    } else {
        letterMode = _lastLetterMode;
    }
    [_viewController updateStatus];
}

-(void)resetMode {
    if ( _sliderShift ) {
        [self shift:-1];
    } else {
        letterMode = 0;
    }
    [_viewController speak:modeSpeechText[letterMode]];
}

-(void)speakAcc {
    if ( [_acc length] == 0 )
        [_viewController beepClear];
    else
        [_viewController speak:[self prepForSpeech:_acc]];
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

-(NSString*)buttonDiscoverySpokenText:(int)buttonIndex {
    
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
        return @"הקראה";
    } else {
        return @"";
    }
}

-(void)complete {
    
    if ( _completionWords == nil ) {
    
        // extract last uncompleted word from accumulator
        NSString*       lastWord = [self completeLastWord];
        if ( lastWord == nil ) {
            [_viewController beep];
            return;
        }
        
        // query words
        _completionWords = [_viewController queryCompletionsFor:lastWord];
        if ( [_completionWords count] == 0 ) {
            _completionWords = nil;
            [_viewController beep];
        }
    } else {
        _completionWords = nil;
        [_viewController beep];
    }
    
    // speak page
    [self speakCompletionPage];
}

-(NSString*)completeLastWord {
    NSString*       lastWord = [[_acc componentsSeparatedByString:@" "] lastObject];
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
    [_viewController speak:text];
}

-(void)speakCompletionWordAtKey:(int)key {
    NSString*       word = [self completionWordAtKey:key];
    if ( word != nil ) {
        [_viewController speak:word];
    } else {
        [_viewController beep];
    }
}

-(NSString*)completionWordAtKey:(int)key {
    int     i = (key - 1);
    if ( i < [_completionWords count] ) {
        return [_completionWords objectAtIndex:i];
    } else {
        return nil;
    }
}

-(NSString*)status {
    return [NSString stringWithFormat:@"P:%d%@", letterMode, _sliderShift ? @"S" : @""];
}

-(void)changeSliderShift:(BOOL)v {
    _sliderShift = v;
}

@end

