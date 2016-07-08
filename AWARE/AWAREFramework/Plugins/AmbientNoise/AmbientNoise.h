//
//  AmbientNoise.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/26/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
#import <Accelerate/Accelerate.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <GLKit/GLKit.h>
#include <EZAudio/EZAudio.h>

//
// By default this will record a file to the application's documents directory
// (within the application's sandbox)
//
#define kAudioFilePath @"rawAudio.m4a"
#define kRawAudioDirectory @"rawAudioData"

@interface AmbientNoise : AWARESensor <AWARESensorDelegate, EZMicrophoneDelegate, EZRecorderDelegate, EZAudioFFTDelegate>
//
// The microphone component
//
@property (nonatomic, strong) EZMicrophone *microphone;

//
// The recorder component
//
@property (nonatomic, strong) EZRecorder *recorder;

//
// Used to calculate a rolling FFT of the incoming audio data.
//
@property (nonatomic, strong) EZAudioFFTRolling *fft;

//
// A flag indicating whether we are recording or not
//
@property (nonatomic, assign) BOOL isRecording;

- (BOOL) startSensor;
- (BOOL) startSensorWithFrequencyMin:(double)min sampleSize:(double)size silenceThreshold:(double)threshold saveRawData:(BOOL)rawDataState;

@end
