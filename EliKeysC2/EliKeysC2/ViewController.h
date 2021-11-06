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
#import "EventLogger.h"

@interface ViewController : UIViewController

-(WordsAccumulator*)wacc;
-(ToneGenerator*)tones;
-(SpeechController*)speech;
-(EventLogger*)eventLogger;
-(void)key:(NSString*)key pressed:(BOOL)b;
-(void)controller:(NSUInteger)ctrl changedTo:(NSUInteger)value;
-(void)beepOK;
-(void)beepError;

@end

