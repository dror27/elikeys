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
}

-(NSString*)asString {
    return _words;
}

-(void)append:(NSString*)text {
    [_words appendString:text];
}

-(NSString*)lastWord {
    return [[_words componentsSeparatedByString:@" "] lastObject];
}

-(void)completeLastWord:(NSString*)word {
    NSString*   lastWord = [self lastWord];
    NSString*   suffix = [word substringFromIndex:[lastWord length]];
    
    [self append:suffix];
    [self append:@" "];
}

@end
