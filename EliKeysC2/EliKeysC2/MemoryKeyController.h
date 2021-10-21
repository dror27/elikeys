//
//  MemoryKeyController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 21/10/2021.
//

#ifndef MemoryKeyController_h
#define MemoryKeyController_h

#import "KeyController.h"
#import "ViewController.h"

@interface MemoryKeyController : NSObject<KeyController>
-(MemoryKeyController*)initWith:(ViewController*)vc;
@end


#endif /* MemoryKeyController_h */
