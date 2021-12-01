//
//  WordsAccumulator.h
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#ifndef WordsAccumulator_h
#define WordsAccumulator_h

#import "EventLogger.h"

@interface WordsAccumulator : NSObject
-(void)clear;
-(NSString*)asString;
-(void)append:(NSString*)text;
-(void)backspace:(int)count;
-(NSString*)lastWord;
-(void)completeLastWord:(NSString*)word;
-(NSUInteger)length;
-(void)setEventLogger:(EventLogger*)eventLogger;
@end

#endif /* WordsAccumulator_h */
