//
//  ViewController.m
//  EliKeysC2
//
//  Created by Dror Kessler on 05/10/2021.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "PredictionTypingMachine.h"
#import "DBConnection.h"

#define SUGGEST_COUNT       4
#define LONG_PRESS_SECS     1.0
#define SOFTBANK_COUNT      4

@interface ViewController ()
@property AVSpeechSynthesisVoice* voice;
@property AVSpeechSynthesizer* synth;
@property PredictionTypingMachine* ptm;
@property NSArray<NSString*>* suggestions;
@property NSMutableArray<NSString*>* softbanks;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self testDb];
    [self loadVoice];
    [self setPtm:[[PredictionTypingMachine alloc] initWith:SUGGEST_COUNT]];
    [self reset];
    
    [self setSoftbanks:[NSMutableArray array]];
    for ( int n = 0 ; n < SOFTBANK_COUNT ; n++ ) {
        [_softbanks addObject:@""];
    }
    
}

- (IBAction)keyTouchDown:(UIButton*)sender {
    NSLog(@"keyTouchDown: %@", sender.titleLabel.text);
    
    [self performSelector:@selector(keyTimer:) withObject:sender afterDelay:LONG_PRESS_SECS];
    sender.tag = 0;
}

- (IBAction)keyTouchUpInside:(UIButton*)sender {
    if ( sender.tag == 0 ) {
        NSLog(@"keyTouchUpInside: %@", sender.titleLabel.text);
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(keyTimer:) object:sender];
        
        [self keyPress:sender.titleLabel.text];
    }
}

- (void)keyTimer:(UIButton*)sender {
    NSLog(@"keyTimer: %@", sender.titleLabel.text);
    sender.tag = 1;
    [self keyLongPress:sender.titleLabel.text];
}

-(void)keyPress:(NSString*)key {
 
    [self flushSpeechQueue];
    if ( [key isEqualToString:@"C"] ) {
        [self reset];
    } else if ( [key isEqualToString:@"A"] ) {
        [self announce];
    } else if ( [key isEqualToString:@"S"] ) {
        [self space];
    } else if ( [key isEqualToString:@"N"] ) {
        [self next];
    } else if ( [key characterAtIndex:0] == 'B' ) {
        [self bank:[key characterAtIndex:1] - '1'];
    } else {
        [self key:[key intValue] - 1];
    }
}

-(void)keyLongPress:(NSString*)key {
    [self flushSpeechQueue];
    
    if ( [key characterAtIndex:0] == 'B' ) {
        [self setBank:[key characterAtIndex:1] - '1'];
    } else {
        [self keyPress:key];
    }
}

-(void)loadVoice {
    [self setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"he-IL"]];
    [self setSynth:[[AVSpeechSynthesizer alloc] init]];
}

-(void)beepOK {
    AudioServicesPlaySystemSound(1003);
}
-(void)beepError {
    AudioServicesPlaySystemSound(1004);
}

-(void)speak:(NSString*)text {
    
    text = [text stringByReplacingOccurrencesOfString:@"-" withString:@" "];
    
    AVSpeechUtterance*   utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    
    utterance.voice = _voice;
    utterance.rate = 0.5;
    utterance.pitchMultiplier = 0.8;
    utterance.postUtteranceDelay = 0.1;
    utterance.volume = 0.8;
    
    
    [_synth speakUtterance:utterance];
}

-(void)flushSpeechQueue {
    [_synth stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [self loadVoice];
}

-(void)reset {
    [self setSuggestions:[_ptm clear]];
    [self announce];
}

-(void)announce {
    [self speak:[self prepareForSpeech:[_ptm text]]];
    if ( [_suggestions count] ) {
        [self speak:@"לבחירה"];
        for ( NSString* text in _suggestions ) {
            [self speak:text];
        }
    } else {
        [self speak:@"אין מה לבחור"];
    }
}

-(void)space {
    [self setSuggestions:[_ptm append:@" "]];
    [self announce];
}

-(void)next {
    [self setSuggestions:[_ptm next]];
    if ( [_suggestions count] ) {
        for ( NSString* text in _suggestions ) {
            [self speak:text];
        }
    } else {
        [self speak:@"אין מה לבחור"];
    }
}

-(void)key:(int)keyIndex {
    if ( keyIndex < [_suggestions count] ) {;
        NSString*       s = [_suggestions objectAtIndex:keyIndex];
        [self setSuggestions:[_ptm append:s]];
        [self announce];
    } else {
        [self beepError];
    }
}

- (void)bank:(int)bankIndex {
    NSString*   text = [_softbanks objectAtIndex:bankIndex];
    
    if ( [text length] ) {
        [self speak:[self prepareForSpeech:text]];
    } else {
        [self beepError];
    }
}

- (void)setBank:(int)bankIndex {
    NSString*    text = [NSString stringWithString:[_ptm text]];
    [_softbanks setObject:text atIndexedSubscript:bankIndex];
    [self beepOK];
}

- (void)testDb {
    NSMutableArray*    results = [DBConnection fetchResults:@"select word,freq from words limit 1"];
    for ( NSDictionary* obj in results ) {
        NSLog(@"obj: %@", obj);
    }
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
