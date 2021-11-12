//
//  MultitapKeyController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 08/11/2021.
//

#ifndef MultitapKeyController_h
#define MultitapKeyController_h

#import "KeyController.h"
#import "ViewController.h"

@interface LetterGameKeyController : NSObject<KeyController>
-(LetterGameKeyController*)initWith:(ViewController*)vc;
@end

#endif /* MultitapKeyController_h */
