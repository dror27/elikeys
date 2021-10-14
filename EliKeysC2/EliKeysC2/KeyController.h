//
//  KeyController.h
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#ifndef KeyController_h
#define KeyController_h

@protocol KeyController<NSObject>
-(void)reset;
-(void)keyPress:(NSUInteger)tag;
-(void)keyLongPress:(NSUInteger)tag;
@end

#endif /* KeyController_h */
