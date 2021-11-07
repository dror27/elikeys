//
//  EventLogger.h
//  EliKeysC2
//
//  Created by Dror Kessler on 06/11/2021.
//

#ifndef EventLogger_h
#define EventLogger_h

#define EL_TYPE_NONE        @""
#define EL_SUBTYPE_NONE     @""

#define EL_TYPE_KEY         @"Key"
#define EL_SUBTYPE_KEY_PRESS @"Press"
#define EL_SUBTYPE_KEY_RELEASE @"Release"

#define EL_TYPE_MIDI         @"Midi"
#define EL_SUBTYPE_MIDI_NOTE_ON @"On"
#define EL_SUBTYPE_MIDI_NOTE_OFF @"Off"
#define EL_SUBTYPE_MIDI_CTRL @"Ctrl"
#define EL_SUBTYPE_MIDI_PRESSURE @"Pressure"

#define EL_TYPE_FILTER         @"Filter"
#define EL_SUBTYPE_FILTER_FIRE @"Fire"
#define EL_SUBTYPE_FILTER_PATTERN @"Pattern"

#define EL_TYPE_SPEECH         @"Speech"
#define EL_SUBTYPE_SPEECH_SPEAK @"Speak"

#define EL_TYPE_WACC           @"Wacc"

@interface EventLogger : NSObject
-(void)log:(NSString*)type subtype:(NSString*)subtype value:(NSString*)value more:(NSString*)more;
-(void)log:(NSString*)type subtype:(NSString*)subtype intValue:(int)value intMore:(int)more;
-(void)log:(NSString*)type subtype:(NSString*)subtype uintValue:(NSUInteger)value uintMore:(NSUInteger)more;
@end

#endif /* EventLogger_h */
