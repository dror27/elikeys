//
//  SpeechController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#ifndef SpeechController_h
#define SpeechController_h

@interface SpeechController : NSObject
-(void)speak:(NSString*)text;
-(void)flushSpeechQueue;
-(NSString*)prepareForSpeech:(NSString*)text;

-(void)setRate:(float)rate;
-(void)setVolume:(float)volume;

@end


#endif /* SpeechController_h */
