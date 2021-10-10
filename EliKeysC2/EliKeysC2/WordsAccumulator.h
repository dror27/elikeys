//
//  WordsAccumulator.h
//  EliKeysC1
//
//  Created by Dror Kessler on 05/10/2021.
//

#ifndef WordsAccumulator_h
#define WordsAccumulator_h

@interface WordsAccumulator : NSObject
-(void)clear;
-(NSString*)asString;
-(void)append:(NSString*)text;
-(void)backspace:(int)count;
-(NSString*)lastWord;
-(void)completeLastWord:(NSString*)word;
@end

#endif /* WordsAccumulator_h */
