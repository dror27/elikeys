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

@end


#endif /* SpeechController_h */
