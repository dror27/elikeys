//
//  BankedKeyController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 16/10/2021.
//

#ifndef BankedKeyController_h
#define BankedKeyController_h

#import "KeyController.h"

@interface BankedKeyController : NSObject<KeyController>
-(BankedKeyController*)initWith:(ViewController*)vc;
@end

#endif /* BankedKeyController_h */
