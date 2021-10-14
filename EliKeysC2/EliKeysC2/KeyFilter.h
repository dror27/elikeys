//
//  KeyFilter.h
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#ifndef KeyFilter_h
#define KeyFilter_h

// patterns
#define     KEYFILTER_P_NORMAL            @"P((T)*(I)?)?R$"
#define     KEYFILTER_P_LONG              @"PTTTTT$"
#define     KEYFILTER_P_IMMEDIATE         @"P"

@interface KeyFilter : NSObject
-(KeyFilter*)initName:(NSString*)name andExpressions:(NSArray<NSRegularExpression*>*)exprs usingBlock:(void (NS_NOESCAPE ^)(KeyFilter * keyFilter, NSUInteger exprIndex))block;
-(NSString*)name;
-(void)keyPressed;
-(void)keyReleased;
-(void)otherPressed;
-(void)otherReleased;
@end


#endif /* KeyFilter_h */
