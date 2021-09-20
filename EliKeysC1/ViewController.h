//
//  ViewController.h
//  EliKeysC1
//
//  Created by Dror Kessler on 17/09/2021.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (void)display:(NSString*)text;
- (void)speak:(NSString*)text;
- (void)beep;
- (void)beepClear;
- (void)beepMode:(int)mode;
@end

