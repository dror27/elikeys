//
//  ViewController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 05/10/2021.
//

#import <UIKit/UIKit.h>
#import "ToneGenerator.h"
#import "SpeechController.h"
#import "WordsAccumulator.h"

@interface ViewController : UIViewController

-(WordsAccumulator*)wacc;
-(ToneGenerator*)tones;
-(SpeechController*)speech;
-(void)key:(NSString*)key pressed:(BOOL)b;
-(void)beepOK;
-(void)beepError;

@end

