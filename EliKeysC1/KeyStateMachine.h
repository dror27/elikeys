//
//  KeyStateMachine.h
//  EliKeysC1
//
//  Created by Dror Kessler on 20/09/2021.
//

#ifndef KeyStateMachine_h
#define KeyStateMachine_h

#import "ViewController.h"

@interface KeyStateMachine : NSObject
-(KeyStateMachine*)initWith:(ViewController*)viewController;
-(void)process:(int)buttonIndex With:(int)op;
-(void)resetMode;
@end


#endif /* KeyStateMachine_h */
