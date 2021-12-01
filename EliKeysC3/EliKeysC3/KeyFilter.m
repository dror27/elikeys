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
#define     TIMER_TICKS_TO_IDLE 30

// defaults
#define     DEF_IGNORE_OTHER    FALSE
#define     DEF_TIMELINE_LIMIT  100
#define     DEF_DEBUG           FALSE

@interface KeyFilter ()
@property NSString*       name;
@property NSArray<KeyFilterExpr*>* exprs;
@property (copy) void (^block)(KeyFilter *keyFilter, NSUInteger exprIndex);
@property (nonatomic,weak) EventLogger* eventLogger;


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

-(void)adjust:(NSUInteger)v {
    for ( KeyFilterExpr* expr in _exprs ) {
        [expr adjust:v];
    }
}

-(void)setEventLogger:(EventLogger *)eventLogger {
    _eventLogger = eventLogger;
    for ( KeyFilterExpr* expr in _exprs ) {
        [expr setEventLogger:eventLogger];
    }
}

@end

@interface KeyFilterExpr ()
@property NSRegularExpression*  regex;
@property BOOL                emits;

@property NSUInteger adjLower;
@property NSUInteger adjUpper;
@property NSUInteger adjValue;
@property NSString* adjPattern;
@property NSRange adjRange;
@property (weak) EventLogger* eventLogger;
@end

@implementation KeyFilterExpr

-(KeyFilterExpr*)initWithPattern:(NSString*)pattern {
    
    // check if pattern contains an adjustment clause
    NSUInteger                 adjLower = 0;
    NSUInteger                 adjUpper = 0;
    NSUInteger                 adjValue = 0;
    NSString*                  adjPattern = nil;
    NSRange                    adjRange = NSMakeRange(0, 0);
    NSRegularExpression*        adjRegex = [NSRegularExpression regularExpressionWithPattern:@"(<(\\d+),(\\d+)>)" options:0 error:nil];
    NSTextCheckingResult*       adjResult = [adjRegex firstMatchInString:pattern options:0 range:NSMakeRange(0, [pattern length])];
    if ( adjResult ) {
        adjLower = [[pattern substringWithRange:[adjResult rangeAtIndex:2]] intValue];
        adjUpper = [[pattern substringWithRange:[adjResult rangeAtIndex:3]] intValue];
        adjValue = (adjLower + adjUpper) / 2;
        adjPattern = pattern;
        adjRange = [adjResult range];
        pattern = [pattern stringByReplacingCharactersInRange:adjRange withString:[NSString stringWithFormat:@"%ld", adjValue]];
        NSLog(@"pattern: %@", pattern);
    }
    
    [_eventLogger log:EL_TYPE_FILTER subtype:EL_SUBTYPE_FILTER_PATTERN value:pattern more:nil];
    
    // create pattern
    NSRegularExpression*        regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    KeyFilterExpr*  me = [self initWithRegex:regex];
    
    // copy adjustable properties
    me.adjLower = adjLower;
    me.adjUpper = adjUpper;
    me.adjValue = adjValue;
    me.adjPattern = adjPattern;
    me.adjRange = adjRange;
    return me;
}

-(KeyFilterExpr*)initFromUserData:(NSString*)key withDefaultPattern:(NSString*)pattern {
    NSString*               userPattern = [[NSUserDefaults standardUserDefaults] stringForKey:key];
    if ( !userPattern )
        userPattern = pattern;
    
    return [self initWithPattern:pattern];
}

-(KeyFilterExpr*)initWithRegex:(NSRegularExpression*)regex {
    self = [super init];
    if (self) {
        [self setRegex:regex];
         _emits = TRUE;
    }
    return self;
}

-(BOOL)matches:(NSString*)text {
    return [_regex numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])] > 0;
}

-(void)adjust:(NSUInteger)v {
    
    // adjustable?
    if ( _adjPattern ) {
        
        // calibrate range from 0-127
        NSUInteger  oldValue = _adjValue;
        _adjValue = _adjLower + (_adjUpper - _adjLower) * (v / 127.0);
        
        // new value?
        if ( _adjValue != oldValue ) {
            
            // create new pattern
            NSString* pattern = [_adjPattern stringByReplacingCharactersInRange:_adjRange withString:[NSString stringWithFormat:@"%ld", _adjValue]];
            NSLog(@"pattern: %@", pattern);
            [_eventLogger log:EL_TYPE_FILTER subtype:EL_SUBTYPE_FILTER_PATTERN value:pattern more:[NSString stringWithFormat:@"%lu", v]];

            // create new regex
            _regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        }
    }
}

@end

