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
#define     KEYFILTER_P_IMMEDIATE         @"P$"
#define     KEYFILTER_P_EXCUSIVE          @"[^rp0-9]{20}$"

@interface KeyFilterExpr : NSObject
-(KeyFilterExpr*)initWithPattern:(NSString*)pattern;
-(KeyFilterExpr*)initFromUserData:(NSString*)key withDefaultPattern:(NSString*)pattern;
-(KeyFilterExpr*)initWithRegex:(NSRegularExpression*)regex;
-(BOOL)matches:(NSString*)text;
-(BOOL)emits;
-(void)setEmits:(BOOL)v;
@end

@interface KeyFilter : NSObject
-(KeyFilter*)initName:(NSString*)name andExpressions:(NSArray<KeyFilterExpr*>*)exprs usingBlock:(void (NS_NOESCAPE ^)(KeyFilter * keyFilter, NSUInteger exprIndex))block;
-(NSString*)name;
-(void)keyPressed;
-(void)keyReleased;
-(void)otherPressed;
-(void)otherReleased;

-(void)setDebug:(BOOL)debug;

@end



#endif /* KeyFilter_h */
