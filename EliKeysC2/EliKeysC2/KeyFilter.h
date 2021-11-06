//
//  KeyFilter.h
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#ifndef KeyFilter_h
#define KeyFilter_h

#import "EventLogger.h"

// patterns
#define     KEYFILTER_P_NORMAL            @"P((T)*(I)?)?R$"    /* requires a push and a release */
#define     KEYFILTER_P_LONG              @"PTTTTT$"           /* triggers 500ms after a push */
#define     KEYFILTER_P_LONG_ADJUST       @"PT{<5,15>}$"       /* triggers <programmable>ms after a push */
#define     KEYFILTER_P_IMMEDIATE         @"P$"                /* triggers immediatly after a push */
#define     KEYFILTER_P_EXCLUSIVE         @"[^rp0-9]{20}$"     /* triggers when a key has been exclusive for 2s */
#define     KEYFILTER_P_EXCLUSIVE_REPEAT  @"(?=[^rp0-9]{20}$)(([^PR]*[PR][^PR]*){4,}$)" /* at least two exclusing RP within a 2s interval */

@interface KeyFilterExpr : NSObject
-(KeyFilterExpr*)initWithPattern:(NSString*)pattern;
-(KeyFilterExpr*)initFromUserData:(NSString*)key withDefaultPattern:(NSString*)pattern;
-(KeyFilterExpr*)initWithRegex:(NSRegularExpression*)regex;
-(BOOL)matches:(NSString*)text;
-(BOOL)emits;
-(void)setEmits:(BOOL)v;
-(void)adjust:(NSUInteger)v;
-(void)setEventLogger:(EventLogger*)eventLogger;
@end

@interface KeyFilter : NSObject
-(KeyFilter*)initName:(NSString*)name andExpressions:(NSArray<KeyFilterExpr*>*)exprs usingBlock:(void (NS_NOESCAPE ^)(KeyFilter * keyFilter, NSUInteger exprIndex))block;
-(NSString*)name;
-(void)keyPressed;
-(void)keyReleased;
-(void)otherPressed;
-(void)otherReleased;
-(void)adjust:(NSUInteger)v;
-(void)setEventLogger:(EventLogger*)eventLogger;

-(void)setDebug:(BOOL)debug;

@end



#endif /* KeyFilter_h */
