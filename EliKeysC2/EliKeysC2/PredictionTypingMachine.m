//
//  PredictionTypingMachine.m
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#import <Foundation/Foundation.h>
#import "PredictionTypingMachine.h"
#import "WordsAccumulator.h"
#import "CompletionGenerator.h"

@interface PredictionTypingMachine ()
@property int                   blockSize;
@property WordsAccumulator*       accumulator;
@property CompletionGenerator*     generator;
@property NSMutableArray<NSString*>* suggestions;
@property int                   nextSuggestionIndex;

-(void)updateSuggestions;
@end

@implementation PredictionTypingMachine

-(PredictionTypingMachine*)initWithWAcc:(WordsAccumulator*)wacc andBlockSize:(int)blockSize {
    self = [super init];
    if (self) {
        _blockSize = blockSize;
        [self setAccumulator:wacc];
        [self setGenerator:[[CompletionGenerator alloc] init]];
        [self setSuggestions:[[NSMutableArray alloc] init]];
    }
    return self;
}

-(int)wordSuggestionThreshold {
    NSString*         v = [[NSUserDefaults standardUserDefaults] stringForKey:@"word_suggestion_threshold"];
    return ([v length] > 0) ? [v intValue] : 2;
}

-(int)wordSuggestionCount {
    NSString*         v = [[NSUserDefaults standardUserDefaults] stringForKey:@"word_suggestion_count"];
    return ([v length] > 0) ? [v intValue] : 4;
}

-(void)updateSuggestions {
    
    // clear
    [_suggestions removeAllObjects];
    _nextSuggestionIndex = 0;
    
    // get last word
    NSString*       lastWord = [_accumulator lastWord];
    
    // suggest words?
    int     threshold = [self wordSuggestionThreshold];
    if ( threshold && ([lastWord length] >= threshold) ) {
        [_suggestions addObjectsFromArray:[_generator wordCompletionSuggestions:lastWord limitTo:[self wordSuggestionCount]]];
    }
    
    // suggest letters
    [_suggestions addObjectsFromArray:[_generator nextLetterSuggestions:lastWord]];
}

-(NSArray<NSString*>*)clear {
    [_accumulator clear];
    [_suggestions removeAllObjects];
    [self updateSuggestions];
    return [self next];
}

-(NSString*)text {
    return [_accumulator asString];
}

-(NSArray<NSString*>*)next {
    
    // check & reset as needed
    if ( ![_suggestions count] )
        return nil;
    
    // get block, loop twice to make sure we fill the block (wrap)
    NSMutableArray<NSString*>*  block = [[NSMutableArray alloc] init];
    for ( int n = 0 ; n < 2 ; n++ ) {
        if ( [block count] >= _blockSize ) {
            break;
        }
        if ( _nextSuggestionIndex >= [_suggestions count] )
            _nextSuggestionIndex = 0;
        for ( ; _nextSuggestionIndex < [_suggestions count] ; ) {
            [block addObject:[_suggestions objectAtIndex:_nextSuggestionIndex++]];
            if ( [block count] >= _blockSize ) {
                break;
            }
        }
    }
    
    return block;
}

-(NSArray<NSString*>*)append:(NSString*)text {
    if ( [text length] <= 1 ) {
        [_accumulator append:text];
    } else {
        [_accumulator completeLastWord:text];
    }
    
    [self updateSuggestions];
    return [self next];
}

-(NSArray<NSString*>*)backspace:(int)count {
    [_accumulator backspace:count];
    
    [self updateSuggestions];
    return [self next];
}

@end
