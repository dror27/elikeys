//
//  EventLogger.m
//  EliKeysC2
//
//  Created by Dror Kessler on 06/11/2021.
//

#import <Foundation/Foundation.h>
#import <time.h>
#import "EventLogger.h"

@interface EventLogger ()
@property NSString* path;
@property NSFileHandle* handle;
@property NSRegularExpression* quoteChars;
@property NSUInteger lastTimestamp;
@property NSUInteger rowIndex;
@end

@implementation EventLogger

-(EventLogger*)init
{
    self = [super init];
    if (self) {
        [self start];
    }
    return self;
}

-(void)start {

    // establish path
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSLog(@"documentsDirectory: %@", documentsDirectory);
    self.path = [documentsDirectory stringByAppendingPathComponent:[self dateFilenameFor:[NSDate now]]];
    NSLog(@"path: %@", _path);

    // regex for quote characters
    self.quoteChars = [NSRegularExpression regularExpressionWithPattern:@"[ ,\"]" options:0 error:nil];
    self.lastTimestamp = 0;
    self.rowIndex = 0;
    
    // start with an empty file
    [@"" writeToFile:_path atomically:TRUE encoding:NSUTF8StringEncoding error:nil];
    
    // open handle for writing
    self.handle = [NSFileHandle fileHandleForWritingAtPath:_path];
    [_handle seekToEndOfFile];
    [self logHeaders];
}

-(void)stop {
    [_handle closeFile];
}

-(NSString*)dateFilenameFor:(NSDate*)date {
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd-HH-mm-ss";
 
    NSString*     filename = [NSString stringWithFormat:@"%@.csv", [dateFormatter stringFromDate:date]];
    NSLog(@"filename: %@", filename);
    
    return filename;
}

-(void)append:(NSString*)s {
    [_handle writeData:[s dataUsingEncoding:NSUTF8StringEncoding]];
    [_handle synchronizeAndReturnError:nil];
}

-(NSString*)quote:(NSString*)text {
    
    if ( !text )
        return @"";
    
    BOOL        needsQuoting = [_quoteChars numberOfMatchesInString:text options:0 range:NSMakeRange(0, [text length])] > 0;
    
    if ( !needsQuoting )
        return text;
    else
        return [NSString stringWithFormat:@"\"%@\"", [text stringByReplacingOccurrencesOfString:@"\"" withString:@"\"\""]];
}

-(void)logHeaders {
    [self append:@"id,timestamp,timedelta,type,subtype,value,more\n"];
}

-(void)log:(NSString*)type subtype:(NSString*)subtype value:(NSString*)value more:(NSString*)more {
    
    struct timespec     tp;
    clock_gettime(CLOCK_REALTIME, &tp);
    NSUInteger  timestamp = 1000 * tp.tv_sec + tp.tv_nsec / 1000000;
    
    NSUInteger delta = _lastTimestamp ? (timestamp - _lastTimestamp) : 0;
    _rowIndex = _rowIndex + 1;
    
    [self append:[NSString stringWithFormat:@"%ld,%ld,%ld,%@,%@,%@,%@\n",
                 _rowIndex, timestamp, delta, type, subtype, [self quote:value], [self quote:more]]];
    
    _lastTimestamp = timestamp;
}

-(void)log:(NSString*)type subtype:(NSString*)subtype intValue:(int)value intMore:(int)more {
    [self log:type subtype:subtype value:[NSString stringWithFormat:@"%d", value] more:[NSString stringWithFormat:@"%d", more]];
}

-(void)log:(NSString*)type subtype:(NSString*)subtype uintValue:(NSUInteger)value uintMore:(NSUInteger)more {
    [self log:type subtype:subtype value:[NSString stringWithFormat:@"%lu", value] more:[NSString stringWithFormat:@"%lu", more]];
}
@end

