//
//  ViewController.m
//  EliKeysC1
//
//  Created by Dror Kessler on 17/09/2021.
//

#import "ViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation ViewController

NSString        *en = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
NSString        *he = @"אבגדהוזחטיכלמנסעפצקרשת";

- (IBAction)buttonDown:(UIButton *)sender {
    [self process:[sender.titleLabel.text intValue] With:0];
}
- (IBAction)buttonUpInside:(UIButton *)sender {
    [self process:[sender.titleLabel.text intValue] With:1];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)process:(int)buttonIndex With:(int)op {
    NSLog(@"process: %d (%d)", buttonIndex, op);
    if ( op != 1 )
        return;
    
    // keys 1-12 are letters
    if ( buttonIndex >= 1 && buttonIndex <= 12 ) {
        
        NSString*   text = [NSString stringWithFormat:@"%@%C", _label.text, [he characterAtIndex:buttonIndex - 1]];
        [self display:text];
        
    } else if ( buttonIndex == 16 ) {
        [self display:@""];
        AudioServicesPlaySystemSound(1003);
    } else if ( buttonIndex == 13 ) {
        [self speak];
    }
    
}

- (void)display:(NSString*)text {
    NSLog(@"display: %@", text);
    [_label setText:text];
}

- (void)speak {
    
    AVSpeechUtterance*   utterance = [AVSpeechUtterance speechUtteranceWithString:@"Hello"];
    AVSpeechSynthesisVoice* voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"en-GB"];
    utterance.voice = voice;
    
    AVSpeechSynthesizer* synth = [[AVSpeechSynthesizer alloc] init];
    
    [synth speakUtterance:utterance];
    
    
}


@end
