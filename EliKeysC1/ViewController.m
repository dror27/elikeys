//
//  ViewController.m
//  EliKeysC1
//
//  Created by Dror Kessler on 17/09/2021.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import "KeyStateMachine.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@property (nonatomic) AVSpeechSynthesisVoice* voice;
@property (nonatomic) AVSpeechSynthesizer* synth;
@property (nonatomic) KeyStateMachine* ksm;

@end

@implementation ViewController


- (IBAction)buttonDown:(UIButton *)sender {
    [_ksm process:[sender.titleLabel.text intValue] With:0];
}
- (IBAction)buttonUpInside:(UIButton *)sender {
    [_ksm process:[sender.titleLabel.text intValue] With:1];
}


- (void)viewDidLoad {
    [super viewDidLoad];

    _ksm = [[KeyStateMachine alloc] initWith:self];
    
    NSArray<AVSpeechSynthesisVoice *> * voices = [AVSpeechSynthesisVoice speechVoices];
    for (AVSpeechSynthesisVoice* voice in voices) {
        NSLog(@"voice: %@: %@", [voice name], [voice language]);
    }
    _voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"he-IL"];
    _synth = [[AVSpeechSynthesizer alloc] init];
}

- (void)display:(NSString*)text {
    NSLog(@"display: %@", text);
    [_label setText:text];
}

- (void)beep {
    AudioServicesPlaySystemSound(1003);
}

- (void)beepClear {
    AudioServicesPlaySystemSound(1003);
}
- (void)beepMode:(int)mode {
    AudioServicesPlaySystemSound(1007 + mode);
}

- (void)speak:(NSString*)text {
    
    AVSpeechUtterance*   utterance = [AVSpeechUtterance speechUtteranceWithString:text];
    
    utterance.voice = _voice;
    utterance.rate = 0.37;
    utterance.pitchMultiplier = 0.8;
    utterance.postUtteranceDelay = 0.4;
    utterance.volume = 0.8;
    
    
    [_synth speakUtterance:utterance];
    
    
}


@end
