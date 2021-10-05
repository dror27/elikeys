//
//  CompletionGenerator.h
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#ifndef CompletionGenerator_h
#define CompletionGenerator_h

@interface CompletionGenerator : NSObject
-(NSArray<NSString*>*)nextLetterSuggestions:(NSString*)prefix;
-(NSArray<NSString*>*)wordCompletionSuggestions:(NSString*)prefix limitTo:(int)limit;
@end

#endif /* CompletionGenerator_h */
