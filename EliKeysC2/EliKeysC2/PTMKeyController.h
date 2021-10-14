//
//  PTMKeyController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#ifndef PTMKeyController_h
#define PTMKeyController_h

#import "KeyController.h"

@interface PTMKeyController : NSObject<KeyController>
-(PTMKeyController*)initWith:(ViewController*)vc;
@end

#endif /* PTMKeyController_h */
