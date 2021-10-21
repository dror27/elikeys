//
//  NSMutableArray_Shuffling.h
//  EliKeysC2
//
//  Created by Dror Kessler on 21/10/2021.
//

#ifndef NSMutableArray_Shuffling_h
#define NSMutableArray_Shuffling_h

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#include <Cocoa/Cocoa.h>
#endif

// This category enhances NSMutableArray by providing
// methods to randomly shuffle the elements.
@interface NSMutableArray (Shuffling)
- (void)shuffle;
@end

#endif /* NSMutableArray_Shuffling_h */
