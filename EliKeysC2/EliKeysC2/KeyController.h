//
//  KeyController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#ifndef KeyController_h
#define KeyController_h

#import "KeyFilter.h"

@protocol KeyController<NSObject>
-(NSArray<KeyFilterExpr*>*)filtersForKey:(NSUInteger)keyTag;
-(void)reset;
-(void)keyPress:(NSUInteger)keyTag keyFilterIndex:(NSUInteger)filterIndex;
-(void)enter;
@end

#endif /* KeyController_h */
