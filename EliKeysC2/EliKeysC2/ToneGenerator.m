//
//  ToneGenerator.m
//  EliKeysC2
//
//  Created by Dror Kessler on 10/10/2021.
//

#import <Foundation/Foundation.h>
#import "ToneGenerator.h"
#import "TGSineWaveToneGenerator.h"

#define DURATION_SHORT          0.15
#define DURATION_MID            0.3
#define DURATION_LONG           0.45

#define FREQ_KEY_PRESSED        440
#define FREQ_KEY_LONG_PRESSED   880

#define FREQ_TONE_1             440
#define FREQ_TONE_2             880
#define FREQ_TONE_3             1760

#define FREQ_TONE_OK            440
#define FREQ_TONE_ERROR         220


#define FREQ_SCALE_A            @[@440, @466.16, @493.88, @523.25, @554.37, @587.33, @622.25, @659.25, @698.46, @739.99, @783.99, @830.61, @880]



@interface ToneGenerator ()
@property TGSineWaveToneGenerator* gen;
@property float volume;
@end

@implementation ToneGenerator

-(ToneGenerator*)init
{
    self = [super init];
    if (self) {
        _volume = 0.5;
        [self setGen:[[TGSineWaveToneGenerator alloc] initWithChannels:1]];
    }
    return self;
}

-(void)beep:(int)frequency withDuration:(float)duration {
    [_gen stop];
    _gen->_channels[0].frequency = frequency;
    _gen->_channels[0].amplitude = _volume / 2;
    _gen->_channels[0].notes[0].frequency = 0;
    [_gen playForDuration:duration];
}

-(void)beepOK {
    [self beep:FREQ_TONE_OK withDuration:DURATION_MID];
}

-(void)beepError {
    [self beep:FREQ_TONE_ERROR withDuration:DURATION_LONG];
}

-(void)keyPressed {
    [self beep:FREQ_KEY_PRESSED withDuration:DURATION_MID];
}

-(void)keyLongPressed {
    [self beep:FREQ_KEY_LONG_PRESSED withDuration:DURATION_SHORT];
}

-(void)multiTone:(NSArray<NSNumber*>*)notes withDuration:(float)duration {
    [_gen stop];
    assert([notes count] <= SINE_WAVE_TONE_GENERATOR_NOTE_COUNT);
    assert([notes count] > 0);
    _gen->_channels[0].frequency = [[notes objectAtIndex:0] intValue];
    _gen->_channels[0].amplitude = _volume / 2;
    for ( size_t n = 0 ; n < [notes count] ; n++ ) {
        _gen->_channels[0].notes[n].frequency = [[notes objectAtIndex:n] intValue];
        _gen->_channels[0].notes[n].duration = duration;
    }
    if ( [notes count] < SINE_WAVE_TONE_GENERATOR_NOTE_COUNT )
        _gen->_channels[0].notes[[notes count]].frequency = 0;
    [_gen playForDuration:duration * [notes count]];

}

-(void)multiToneRisingShort {
    [self multiTone:@[@FREQ_TONE_1, @FREQ_TONE_2, @FREQ_TONE_3] withDuration:DURATION_SHORT];
}

-(void)twoToneFalling {
    [self multiTone:@[@FREQ_TONE_2, @FREQ_TONE_1] withDuration:DURATION_MID];
}

-(void)chromaticScaleRising:(int)noteCount {
    NSArray<NSNumber*>*     scale = FREQ_SCALE_A;
    
    [self multiTone:[scale subarrayWithRange:NSMakeRange(0, noteCount)] withDuration:DURATION_SHORT / 2];
}


@end
