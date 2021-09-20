//
//  KeyStateMachine.m
//  EliKeysC1
//
//  Created by Dror Kessler on 20/09/2021.
//

#import <Foundation/Foundation.h>
#import "KeyStateMachine.h"

@interface KeyStateMachine ()
@property (weak, nonatomic) ViewController *viewController;
@property (nonatomic) NSMutableString *acc;

-(void)speakAcc;
-(NSString*)prepForSpeech:(NSString*)text;

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
    }
    return self;
}

- (void)process:(int)buttonIndex With:(int)op {
    NSLog(@"process: %d (%d)", buttonIndex, op);
    if ( op != 1 )
        return;
    
    // keys 1-12 are letters
    if ( buttonIndex >= 1 && buttonIndex <= 12 ) {
        NSString*   letter = [NSString stringWithFormat:@"%C", [letterKeys[letterMode] characterAtIndex:buttonIndex - 1]];
        if ( [letter isEqualToString:@" "] )
            [_viewController speak:@"רווח"];
        if ( [letter isEqualToString:@"."] )
            [_viewController speak:@"נקודה"];
        else
            [_viewController speak:letter];
        [_acc appendString:letter];
        [_viewController display:_acc];
        
    } else if ( buttonIndex == 16 ) {
        [_acc setString:@""];
        [_viewController display:_acc];
        [_viewController beepClear];
    } else if ( buttonIndex == 15 ) {
        if ([_acc length] > 0 ) {
            [_acc deleteCharactersInRange:NSMakeRange([_acc length]-1, 1)];
            [_viewController display:_acc];
        }
        [self speakAcc];
    } else if ( buttonIndex == 14 ) {
        letterMode = (letterMode + 1) % 3;
        [_viewController speak:modeSpeechText[letterMode]];
    } else if ( buttonIndex == 13 ) {
        [self speakAcc];
    }
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

@end

