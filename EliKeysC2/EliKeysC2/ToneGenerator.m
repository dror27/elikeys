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


#define AMP_MID                 0.2

@interface ToneGenerator ()
@property TGSineWaveToneGenerator* gen;
@end

@implementation ToneGenerator

-(ToneGenerator*)init
{
    self = [super init];
    if (self) {
        [self setGen:[[TGSineWaveToneGenerator alloc] initWithChannels:1]];
    }
    return self;
}

-(void)beep:(int)frequency withDuration:(float)duration {
    _gen->_channels[0].frequency = frequency;
    _gen->_channels[0].amplitude = AMP_MID;
    [_gen playForDuration:duration];
}


-(void)keyPressed {
    [self beep:FREQ_KEY_PRESSED withDuration:DURATION_MID];
}

-(void)keyLongPressed {
    [self beep:FREQ_KEY_LONG_PRESSED withDuration:DURATION_SHORT];
}


@end
