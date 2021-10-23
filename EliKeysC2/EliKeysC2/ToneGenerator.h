//
//  ToneGenerator.h
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#ifndef ToneGenerator_h
#define ToneGenerator_h

@interface ToneGenerator : NSObject
-(void)keyPressed;
-(void)keyLongPressed;

-(void)twoToneRising;
-(void)twoToneFalling;
-(void)chromaticScaleRising:(int)noteCount;

@end

#endif /* ToneGenerator_h */
