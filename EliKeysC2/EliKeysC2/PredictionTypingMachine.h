//
//  PredictionTypingMachine.h
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#ifndef PredictionTypingMachine_h
#define PredictionTypingMachine_h

@interface PredictionTypingMachine : NSObject
-(void)clear;
-(NSString*)accumulatorAsString;
-(void)updateSuggestions;
-(NSArray<NSString*>*)nextSuggestionBlock:(int)blockSize;
-(void)appendSuggestion:(NSString*)text;
@end

#endif /* PredictionTypingMachine_h */
