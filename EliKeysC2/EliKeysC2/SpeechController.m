//
//  SpeechController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "SpeechController.h"

@interface SpeechController ()
@property AVSpeechSynthesisVoice* voice;
@property AVSpeechSynthesizer* synth;
@end

@implementation SpeechController

-(SpeechController*)init
{
    self = [super init];
    if (self) {
        [self loadVoice];
    }
    return self;
}

-(void)loadVoice {
    [self setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"he-IL"]];
    [self setSynth:[[AVSpeechSynthesizer alloc] init]];
}

-(void)speak:(NSString*)text {
    
    text = [text stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    
    AVSpeechUtterance*   utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    
    utterance.voice = _voice;
    utterance.rate = 0.5;
    utterance.pitchMultiplier = 0.8;
    utterance.postUtteranceDelay = 0.1;
    utterance.volume = 0.6;
    
    
    [_synth speakUtterance:utterance];
}

-(void)flushSpeechQueue {
    [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self loadVoice];
}

-(NSString*)prepareForSpeech:(NSString*)text {
    
    NSMutableString*    result = [[NSMutableString alloc] init];
    NSUInteger          length = [text length];
    NSCharacterSet*     letters = [NSCharacterSet letterCharacterSet];
    NSString*           l1 = @"כמנפצ";
    NSString*           l2 = @"ךםןףץ";
 
    for ( NSUInteger n = 0 ; n < length ; n++ ) {
        unichar ch0 = (n > 0) ? [text characterAtIndex:n-1] : '\0';
        unichar ch1 = [text characterAtIndex:n];
        unichar ch2 = (n+1<length) ? [text characterAtIndex:n+1] : '\0';

        if ( [letters characterIsMember:ch0] && [letters characterIsMember:ch1] && ![letters characterIsMember:ch2] ) {
            for ( NSInteger m = 0 ; m < [l1 length] ; m++ ) {
                if ( ch1 == [l1 characterAtIndex:m] ) {
                    ch1 = [l2 characterAtIndex:m];
                    break;
                }
            }
        }
        
        [result appendFormat:@"%C", ch1];
    }
    
    NSLog(@"%@ -> %@", text, result);
    
    return result;
}

@end
