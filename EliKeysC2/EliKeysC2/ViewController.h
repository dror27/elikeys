//
//  ViewController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 05/10/2021.
//

#import <UIKit/UIKit.h>
#import "ToneGenerator.h"
#import "SpeechController.h"

@interface ViewController : UIViewController

-(ToneGenerator*)tones;
-(SpeechController*)speech;
-(void)reset;
-(void)keyPress:(NSString*)key;
-(void)keyLongPress:(NSString*)key;
-(float)longKeyPressSecs;

@end

