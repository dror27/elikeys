//
//  TGSineWaveToneGenerator.m
//  Tone Generator
//
//  Created by Anthony Picciano on 6/12/13.
//  Copyright (c) 2013 Anthony Picciano. All rights reserved.
//
//  Major contributions and updates by Simon Grätzer on 12/23/14.
//
//  Based upon work by Matt Gallagher on 2010/10/20.
//  Copyright 2010 Matt Gallagher. All rights reserved.
//
//  Permission is given to use this source code file, free of charge, in any
//  project, commercial or otherwise, entirely at your risk, with the condition
//  that any redistribution (in part or whole) of source code must retain
//  this copyright and permission notice. Attribution in compiled projects is
//  appreciated but not required.
//

#import "TGSineWaveToneGenerator.h"
#import <AudioToolbox/AudioToolbox.h>


OSStatus RenderTone(
                    void *inRefCon,
                    AudioUnitRenderActionFlags   *ioActionFlags,
                    const AudioTimeStamp 		*inTimeStamp,
                    UInt32 						inBusNumber,
                    UInt32 						inNumberFrames,
                    AudioBufferList 			*ioData)

{
	// Get the tone parameters out of the object
	TGSineWaveToneGenerator *toneGenerator = (__bridge TGSineWaveToneGenerator *)inRefCon;
    assert(ioData->mNumberBuffers == toneGenerator->_numChannels);
    
    for (size_t chan = 0; chan < toneGenerator->_numChannels; chan++) {
        TGChannelInfo* ci = &toneGenerator->_channels[chan];
        double theta = ci->theta;
        double amplitude = ci->amplitude;
        double theta_increment = 2.0 * M_PI * ci->frequency / toneGenerator->_sampleRate;
        
        Float32 *buffer = (Float32 *)ioData->mBuffers[chan].mData;
        // Generate the samples
        for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
            buffer[frame] = sin(theta) * amplitude;
            
            // in case we are generating notes, adjust
            if ( ci->notes[0].frequency ) {
                
                TGNoteInfo* note = &ci->notes[ci->currentNodeIndex];
                
                // initialize number of samples on current node
                if ( !note->samples ) {
                    note->samples = (NSUInteger)(note->duration * toneGenerator->_sampleRate);
                    note->theta_increment = 2.0 * M_PI * note->frequency / toneGenerator->_sampleRate;
                
                    //NSLog(@"chan: %lu, note: %lu, frame: %d, theta_increment: %f", chan, ci->currentNodeIndex, (int)frame, note->theta_increment);
                }
                
                // update theta_increment
                theta_increment = note->theta_increment;
                ci->currentSampleOnNote++;
                
                // move to next note?
                if ( ci->currentSampleOnNote >= note->samples ) {
                    note->samples = 0;      // this is temp
                    ci->currentNodeIndex++;
                    if ( (ci->currentNodeIndex >= SINE_WAVE_TONE_GENERATOR_NOTE_COUNT)
                        || !ci->notes[ci->currentNodeIndex].frequency ) {
                        ci->currentNodeIndex = 0;
                    }
                    ci->currentSampleOnNote = 0;
                }
            }

            theta += theta_increment;
            // Basically do modulo
            if (theta > 2.0 * M_PI) {
                theta -= 2.0 * M_PI;
            }
            
        }
        
        // Store the theta back in the view controller
        toneGenerator->_channels[chan].theta = theta;
    }
    
	return noErr;
}

@implementation TGSineWaveToneGenerator 

- (id)init
{
    return [self initWithFrequency:SINE_WAVE_TONE_GENERATOR_FREQUENCY_DEFAULT amplitude:SINE_WAVE_TONE_GENERATOR_AMPLITUDE_DEFAULT];
}

- (id)initWithFrequency:(double)hertz amplitude:(double)volume {
    if (self = [super init]) {
        _numChannels = 1;
        _channels = calloc(sizeof(TGChannelInfo), _numChannels);
        if (_channels == NULL) return nil;
        
        _channels[0].frequency = hertz;
        _channels[0].amplitude = volume;
        
        _sampleRate = SINE_WAVE_TONE_GENERATOR_SAMPLE_RATE_DEFAULT;
        [self _setupAudioSession];
//        OSStatus result = AudioSessionInitialize(NULL, NULL, ToneInterruptionListener, (__bridge void *)(self));
//        if (result == kAudioSessionNoError)
//        {
//            UInt32 sessionCategory = kAudioSessionCategory_MediaPlayback;
//            AudioSessionSetProperty(kAudioSessionProperty_AudioCategory, sizeof(sessionCategory), &sessionCategory);
//        }
//        AudioSessionSetActive(true);
    }
    
    return self;
}

- (id)initWithChannels:(UInt32)size {
    if (self = [super init]) {
        _numChannels = size;
        _channels = calloc(sizeof(TGChannelInfo), _numChannels);
        if (_channels == NULL) return nil;
        
        for (size_t i = 0; i < _numChannels; i++) {
            _channels[i].frequency = SINE_WAVE_TONE_GENERATOR_FREQUENCY_DEFAULT / ( i + 0.4);//Just because
            _channels[i].amplitude = SINE_WAVE_TONE_GENERATOR_AMPLITUDE_DEFAULT;
        }
        _sampleRate = SINE_WAVE_TONE_GENERATOR_SAMPLE_RATE_DEFAULT;
        [self _setupAudioSession];
    }
    
    return self;

}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (_channels != NULL) {
        free(_channels);
    }
}

- (void)playForDuration:(NSTimeInterval)time {
    [self play];
    [self performSelector:@selector(stop) withObject:nil afterDelay:time];
}

- (void)play {
    if (!_toneUnit) {
		[self _createToneUnit];
		
		// Stop changing parameters on the unit
		OSErr err = AudioUnitInitialize(_toneUnit);
		NSAssert1(err == noErr, @"Error initializing unit: %hd", err);
		
        // Initialize notes
        for (size_t i = 0; i < _numChannels; i++) {
            _channels[i].currentNodeIndex = 0;
            _channels[i].currentSampleOnNote = 0;
        }
        
        // Start playback
		err = AudioOutputUnitStart(_toneUnit);
		NSAssert1(err == noErr, @"Error starting unit: %hd", err);
	}
}

- (void)stop {
    if (_toneUnit) {
		AudioOutputUnitStop(_toneUnit);
		AudioUnitUninitialize(_toneUnit);
		AudioComponentInstanceDispose(_toneUnit);
		_toneUnit = nil;
	}
}

- (void)_setupAudioSession {
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL ok;
    NSError *setCategoryError = nil;
    ok = [audioSession setCategory:AVAudioSessionCategoryPlayback error:&setCategoryError];
    NSAssert1(ok, @"Audio error %@", setCategoryError);
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(_handleInterruption:)
                                                 name:AVAudioSessionInterruptionNotification
                                               object:audioSession];
}

- (void)_handleInterruption:(id)sender {
    [self stop];
}

- (void)_createToneUnit {
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_RemoteIO;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
	
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	NSAssert(defaultOutput, @"Can't find default output");
	
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &_toneUnit);
	NSAssert1(_toneUnit, @"Error creating unit: %hd", err);
	
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(_toneUnit,
                               kAudioUnitProperty_SetRenderCallback,
                               kAudioUnitScope_Input,
                               0,
                               &input,
                               sizeof(input));
	NSAssert1(err == noErr, @"Error setting callback: %hd", err);
	
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = _sampleRate;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
    kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = _numChannels;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
	err = AudioUnitSetProperty (_toneUnit,
                                kAudioUnitProperty_StreamFormat,
                                kAudioUnitScope_Input,
                                0,
                                &streamFormat,
                                sizeof(AudioStreamBasicDescription));
	NSAssert1(err == noErr, @"Error setting stream format: %hd", err);
}

@end
