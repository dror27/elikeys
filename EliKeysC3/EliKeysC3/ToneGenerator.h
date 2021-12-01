//
//  ToneGenerator.h
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#ifndef ToneGenerator_h
#define ToneGenerator_h

@interface ToneGenerator : NSObject
-(void)beepOK;
-(void)beepError;

-(void)keyPressed;
-(void)keyLongPressed;

-(void)multiToneRisingShort;
-(void)twoToneFalling;
-(void)chromaticScaleRising:(int)noteCount;

-(void)setVolume:(float)volume;

@end

#endif /* ToneGenerator_h */
