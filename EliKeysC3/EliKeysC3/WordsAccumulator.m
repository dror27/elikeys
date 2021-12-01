//
//  WordsAccumulator.m
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#import <Foundation/Foundation.h>
#import "WordsAccumulator.h"

@interface WordsAccumulator ()
@property NSMutableString*     words;
@property (weak) EventLogger* eventLogger;
@end

@implementation WordsAccumulator

-(WordsAccumulator*)init
{
    self = [super init];
    if (self) {
        [self setWords:[[NSMutableString alloc] init]];
    }
    return self;
}

-(void)clear {
    [_words setString:@""];
    [_eventLogger log:EL_TYPE_WACC subtype:EL_SUBTYPE_NONE value:_words more:nil];
}

-(NSString*)asString {
    return _words;
}

-(void)append:(NSString*)text {
    [_words appendString:text];
    [_eventLogger log:EL_TYPE_WACC subtype:EL_SUBTYPE_NONE value:_words more:nil];
}

-(void)backspace:(int)count {
    if ( [_words length] >= count ) {
        [_words deleteCharactersInRange:NSMakeRange([_words length]-count, count)];
    }
    [_eventLogger log:EL_TYPE_WACC subtype:EL_SUBTYPE_NONE value:_words more:nil];
}

-(NSString*)lastWord {
    return [[_words componentsSeparatedByString:@" "] lastObject];
}

-(void)completeLastWord:(NSString*)word {
    NSString*   lastWord = [self lastWord];
    NSString*   suffix = [word substringFromIndex:[lastWord length]];
    
    [self append:suffix];
    [self append:@" "];
    [_eventLogger log:EL_TYPE_WACC subtype:EL_SUBTYPE_NONE value:_words more:nil];
}

-(NSUInteger)length {
    return [_words length];
}

@end
