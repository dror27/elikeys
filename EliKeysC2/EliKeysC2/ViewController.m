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


@interface ViewController ()
@property AVSpeechSynthesisVoice* voice;
@property AVSpeechSynthesizer* synth;
@property PredictionTypingMachine* ptm;
@property NSArray<NSString*>* suggestions;
@end

@implementation ViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    [self testDb];
    [self loadVoice];
    [self setPtm:[[PredictionTypingMachine alloc] init]];
    [self reset];
}

- (IBAction)buttonAction:(UIButton*)sender {
    NSLog(@"sender: %@", sender.titleLabel.text);
    [self flushSpeechQueue];
    if ( [sender.titleLabel.text isEqualToString:@"C"] ) {
        [self reset];
    } else if ( [sender.titleLabel.text isEqualToString:@"A"] ) {
        [self announce];
    } else if ( [sender.titleLabel.text isEqualToString:@"S"] ) {
        [self space];
    } else if ( [sender.titleLabel.text isEqualToString:@"N"] ) {
        [self next];
    } else {
        [self key:[sender.titleLabel.text intValue] - 1];
    }
}

-(void)loadVoice {
    [self setVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"he-IL"]];
    [self setSynth:[[AVSpeechSynthesizer alloc] init]];
}

-(void)beep {
    AudioServicesPlaySystemSound(1003);
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
    [_ptm clear];
    [_ptm updateSuggestions];
    [self setSuggestions:[_ptm nextSuggestionBlock:4]];
    [self announce];
}

-(void)announce {
    [self speak:[self prepForSpeech:[_ptm accumulatorAsString]]];
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
    [_ptm appendSuggestion:@" "];
    [self update];
}

-(void)next {
    [self setSuggestions:[_ptm nextSuggestionBlock:4]];
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
        [_ptm appendSuggestion:s];
        /*
        if ( [s length] > 1 )
            [self beep];
        [_ptm updateSuggestions];
        [self setSuggestions:[_ptm nextSuggestionBlock:4]];
        if ( [_suggestions count] ) {
            [self speak:@"לבחירה"];
            for ( NSString* text in _suggestions ) {
                [self speak:text];
            }
        } else {
            [self speak:@"אין מה לבחור"];
        }
         */
        [self update];
    } else {
        [self beep];
    }
}

-(void)update {
    [_ptm updateSuggestions];
    [self setSuggestions:[_ptm nextSuggestionBlock:4]];
    [self announce];
}

- (void)testDb {
    NSMutableArray*    results = [DBConnection fetchResults:@"select word,freq from words limit 1"];
    for ( NSDictionary* obj in results ) {
        NSLog(@"obj: %@", obj);
    }
}

-(NSString*)prepForSpeech:(NSString*)text {
    
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
