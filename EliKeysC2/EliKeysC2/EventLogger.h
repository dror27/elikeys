//
//  EventLogger.h
//  EliKeysC2
//
//  Created by Dror Kessler on 06/11/2021.
//

#ifndef EventLogger_h
#define EventLogger_h

#define EL_TYPE_NONE        '_'
#define EL_SUBTYPE_NONE     '_'

#define EL_TYPE_KEY         'K'
#define EL_SUBTYPE_KEY_PRESS 'P'
#define EL_SUBTYPE_KEY_RELEASE 'R'

#define EL_TYPE_MIDI         'M'
#define EL_SUBTYPE_MIDI_NOTE_ON 'O'
#define EL_SUBTYPE_MIDI_NOTE_OFF 'F'
#define EL_SUBTYPE_MIDI_CTRL 'C'

#define EL_TYPE_FILTER         'F'
#define EL_SUBTYPE_FILTER_FIRE 'F'
#define EL_SUBTYPE_FILTER_PATTERN 'P'

#define EL_TYPE_SPEECH         'T'
#define EL_SUBTYPE_SPEECH_SPEAK 'S'

#define EL_TYPE_WACC           'W'

@interface EventLogger : NSObject
-(void)log:(unichar)type subtype:(unichar)subtype value:(NSString*)value more:(NSString*)more;
-(void)log:(unichar)type subtype:(unichar)subtype intValue:(int)value intMore:(int)more;
-(void)log:(unichar)type subtype:(unichar)subtype uintValue:(NSUInteger)value uintMore:(NSUInteger)more;
@end

#endif /* EventLogger_h */
