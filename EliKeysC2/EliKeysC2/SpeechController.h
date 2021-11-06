//
//  SpeechController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#ifndef SpeechController_h
#define SpeechController_h

#import "EventLogger.h"

@interface SpeechController : NSObject
-(void)speak:(NSString*)text;
-(void)flushSpeechQueue;
-(NSString*)prepareForSpeech:(NSString*)text;

-(void)setRate:(float)rate;
-(void)setVolume:(float)volume;

-(void)setEventLogger:(EventLogger*)eventLogger;

@end


#endif /* SpeechController_h */
