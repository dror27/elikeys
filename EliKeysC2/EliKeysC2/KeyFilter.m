//
//  KeyFilter.m
//  EliKeysC2
//
//  Created by Dror Kessler on 14/10/2021.
//

#import <Foundation/Foundation.h>
#import "KeyFilter.h"

// events
#define     E_KEY_PRESSED       @"P"
#define     E_KEY_RELEASED      @"R"
#define     E_OTHER_PRESSED     @"p"
#define     E_OTHER_RELEASED    @"r"
#define     E_TIMER_TICK        @"T"
#define     E_TIMER_IDLE        @"I"

// timer settings
#define     TIMER_TICK_DURATION 0.1
#define     TIMER_TICKS_TO_IDLE 10

// defaults
#define     DEF_IGNORE_OTHER    FALSE
#define     DEF_TIMELINE_LIMIT  40
#define     DEF_DEBUG           TRUE

@interface KeyFilter ()
@property NSString*       name;
@property NSArray<KeyFilterExpr*>* exprs;
@property (copy) void (^block)(KeyFilter *keyFilter, NSUInteger exprIndex);


@property NSMutableString*  timeline;
@property NSUInteger    tickCounter;
@property BOOL            ignoreOther;
@property NSUInteger  timelineLimit;
@property BOOL          debug;


-(void)appendAndEval:(NSString*)event;
-(void)startTimer;
-(void)timerTick:(id)arg;
-(void)fire:(NSUInteger)exprIndex;
@end

@implementation KeyFilter

// initilize instance
-(KeyFilter*)initName:(NSString*)name andExpressions:(NSArray<KeyFilterExpr*>*)exprs usingBlock:(void (NS_NOESCAPE ^)(KeyFilter * keyFilter, NSUInteger exprIndex))block
{
    self = [super init];
    if (self) {
        [self setName:name];
        [self setExprs:exprs];
        [self setBlock:block];
        
        _ignoreOther = DEF_IGNORE_OTHER;
        _timelineLimit = DEF_TIMELINE_LIMIT;
        _debug = DEF_DEBUG;
        
        [self setTimeline:[NSMutableString stringWithString:@""]];
    }
    return self;
}

// append event and evaluate the timeline
-(void)appendAndEval:(NSString*)event {
    
    // append and possibly trim
    [_timeline appendString:event];
    if ( _timelineLimit > 0 && [_timeline length] >= _timelineLimit )
        [_timeline deleteCharactersInRange:NSMakeRange(0, [_timeline length] - _timelineLimit)];
    if ( _debug )
        NSLog(@"%@: %@ -> %@", _name, event, _timeline);
    
    // evaluate expressions
    NSUInteger      exprIndex = 0;
    for ( KeyFilterExpr* expr in _exprs ) {
        if ( [expr matches:_timeline] ) {
            [self fire:exprIndex];
            break;
        }
        exprIndex++;
    }
}

-(void)fire:(NSUInteger)exprIndex {
    
    // enter into timeline
    if ( [[_exprs objectAtIndex:exprIndex] emits] )
        [_timeline appendString:[NSString stringWithFormat:@"%ld", exprIndex]];
    
    // invoke block
    _block(self, exprIndex);
}

// key was pressed
-(void)keyPressed {
    
    // append & start timer
    [self startTimer];
    [self appendAndEval:E_KEY_PRESSED];
}

// key was released
-(void)keyReleased {
    [self startTimer];
    [self appendAndEval:E_KEY_RELEASED];
}

// (re)start timer
-(void)startTimer {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timerTick:) object:nil];
    _tickCounter = 0;
    [self performSelector:@selector(timerTick:) withObject:nil afterDelay:TIMER_TICK_DURATION];
}

// process timer tick
-(void)timerTick:(id)arg {
    if ( ++_tickCounter < TIMER_TICKS_TO_IDLE ) {
        [self performSelector:@selector(timerTick:) withObject:nil afterDelay:TIMER_TICK_DURATION];
        [self appendAndEval:E_TIMER_TICK];
    } else {
        [self appendAndEval:E_TIMER_IDLE];
    }
}

// another key was pressed
-(void)otherPressed {
    if ( !_ignoreOther )
        [self appendAndEval:E_OTHER_PRESSED];
}

// another key was released
-(void)otherReleased {
    if ( !_ignoreOther )
        [self appendAndEval:E_OTHER_RELEASED];
}
@end

@interface KeyFilterExpr ()
@property NSRegularExpression*  regex;
@property BOOL                emits;
@end

@implementation KeyFilterExpr

-(KeyFilterExpr*)initWithPattern:(NSString*)pattern {
    self = [super init];
    if (self) {
        [self setRegex:[NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil]];
         _emits = TRUE;
    }
    return self;
}

-(BOOL)matches:(NSString*)text {
    return [_regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])] > 0;
}

@end

