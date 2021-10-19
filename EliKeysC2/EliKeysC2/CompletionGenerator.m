//
//  CompletionGenerator.m
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#import <Foundation/Foundation.h>
#import "CompletionGenerator.h"
#import "DBConnection.h"

@interface CompletionGenerator ()
@property NSArray<NSString*>* allLetters;
@end

@implementation CompletionGenerator

-(CompletionGenerator*)init
{
    self = [super init];
    if (self) {
        [self setAllLetters:[self nextLetterSuggestions:@""]];
        //NSLog(@"allLetters: %@", _allLetters);
    }
    return self;
}

-(NSArray<NSString*>*)nextLetterSuggestions:(NSString*)prefix {
    
    NSString*   query = [NSString stringWithFormat:@"select substr(word, %lu, 1) as w,sum(freq) as f \
                                from words \
                                where word like '%@%%' \
                                group by w order by f desc",
                            [prefix length] + 1, prefix];
    //NSLog(@"query: %@", query);
    NSMutableArray*    results = [DBConnection fetchResults:query];
    NSMutableArray*    suggestions = [[NSMutableArray alloc] init];
    NSCharacterSet*    letters = [NSCharacterSet letterCharacterSet];
    for ( NSDictionary* obj in results ) {
        NSString*       w = [self letterToNonFinal:[obj objectForKey:@"w"]];
        if ( ([w length] > 0) && [letters characterIsMember:[w characterAtIndex:0]] ) {
            if ( ![suggestions containsObject:w] ) {
                [suggestions addObject:w];
            }
        }
    }
    
    // make sure all letters are in the response
    for ( NSString* letter in _allLetters ) {
        if ( ![suggestions containsObject:letter] ) {
            [suggestions addObject:letter];
        }
    }
    return suggestions;
}

-(NSArray<NSString*>*)wordCompletionSuggestions:(NSString*)prefix limitTo:(int)limit {
    NSString*           query = [NSString stringWithFormat:@"select word,freq from words where word like '%@%%' and word != '%@' order by freq desc limit 12", prefix, prefix];
    NSLog(@"query: %@", query);
    NSMutableArray*    results = [DBConnection fetchResults:query];
    NSMutableArray*    words = [[NSMutableArray alloc] init];
    for ( NSDictionary* obj in results ) {
        NSString*       word = [obj objectForKey:@"word"];
        NSLog(@"word: %@", word);
        [words addObject:word];
        if ([words count] >= limit ) {
            break;
        }
    }
    return words;
}

-(NSString*)letterToNonFinal:(NSString*)letter {
    if ( [letter length] != 1 ) {
        return letter;
    }
    NSString*           l1 = @"כמנפצ";
    NSString*           l2 = @"ךםןףץ";
    unichar ch1 = [letter characterAtIndex:0];
    for ( int m = 0 ; m < [l1 length] ; m++ ) {
        if ( ch1 == [l2 characterAtIndex:m] ) {
            return [NSString stringWithFormat:@"%C", [l1 characterAtIndex:m]];
        }
    }
    
    return letter;

    

}
@end

