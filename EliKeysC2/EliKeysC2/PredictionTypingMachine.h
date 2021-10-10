//
//  PredictionTypingMachine.h
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#ifndef PredictionTypingMachine_h
#define PredictionTypingMachine_h

@interface PredictionTypingMachine : NSObject
// initialize
-(PredictionTypingMachine*)initWith:(int)blockSize;

// get text representation of the accumulator
-(NSString*)text;

// clear and get initial suggestions
-(NSArray<NSString*>*)clear;

// append text and get new suggestions
-(NSArray<NSString*>*)append:(NSString*)text;

// backspace N characters (from end)
-(NSArray<NSString*>*)backspace:(int)count;

// get next set of suggestions
-(NSArray<NSString*>*)next;
@end

#endif /* PredictionTypingMachine_h */
