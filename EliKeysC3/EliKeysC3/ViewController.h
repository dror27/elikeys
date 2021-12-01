//
//  ViewController.h
//  EliKeysC3
//
//  Created by Dror Kessler on 01/12/2021.
//

#import <UIKit/UIKit.h>

#import "ToneGenerator.h"
#import "SpeechController.h"
#import "EventLogger.h"

@interface ViewController : UIViewController

-(ToneGenerator*)tones;
-(SpeechController*)speech;
-(EventLogger*)eventLogger;

@property (weak, nonatomic) IBOutlet UILabel *waccControl;
@property (weak, nonatomic) IBOutlet UISlider *slider1Control;
@property (weak, nonatomic) IBOutlet UISlider *slider2Control;
@property (weak, nonatomic) IBOutlet UISlider *slider3Control;

@end

