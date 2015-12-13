//
//  AmbientNoise.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/26/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AmbientNoise.h"


//ambient_noise


@implementation AmbientNoise{
    NSTimer *timer;
    NSTimer *sensingTimer;
    AudioQueueRef _queue;
    NSTimer *_timer;
}


static void AudioInputCallback(
                               void* inUserData,
                               AudioQueueRef inAQ,
                               AudioQueueBufferRef inBuffer,
                               const AudioTimeStamp *inStartTime,
                               UInt32 inNumberPacketDescriptions,
                               const AudioStreamPacketDescription *inPacketDescs)
{
    // This area is necesary for record the sound. In the AWARE-client-iOS not record the anbient sound, then we don't need to record sound.
}


- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName ];
    if (self) {
        [super setSensorName:sensorName];
        AudioStreamBasicDescription dataFormat;
        dataFormat.mSampleRate = 44100.0f;
        dataFormat.mFormatID = kAudioFormatLinearPCM;
        dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
        dataFormat.mBytesPerPacket = 2;
        dataFormat.mFramesPerPacket = 1;
        dataFormat.mBytesPerFrame = 2;
        dataFormat.mChannelsPerFrame = 1;
        dataFormat.mBitsPerChannel = 16;
        dataFormat.mReserved = 0;
        
    }
    return self;
}

-(BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Anbient Sensor!");
    timer = [NSTimer scheduledTimerWithTimeInterval:upInterval
                                             target:self selector:@selector(syncAwareDB) userInfo:nil repeats:YES];
    [self startWriteAbleTimer];
    [self startUpdatingVolume];
//    [audioController setInputEnabled:NO];
//    AudioSessionSetActive(false);
    return YES;
}


-(BOOL) stopSensor{
    [timer invalidate];
    [sensingTimer invalidate];
    [self stopWriteableTimer];
    [self stopUpdatingVolume];
    return YES;
}


- (void)startUpdatingVolume
{
    AudioStreamBasicDescription dataFormat;
    dataFormat.mSampleRate = 44100.0f;
    dataFormat.mFormatID = kAudioFormatLinearPCM;
    dataFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian | kLinearPCMFormatFlagIsSignedInteger | kLinearPCMFormatFlagIsPacked;
    dataFormat.mBytesPerPacket = 2;
    dataFormat.mFramesPerPacket = 1;
    dataFormat.mBytesPerFrame = 2;
    dataFormat.mChannelsPerFrame = 1;
    dataFormat.mBitsPerChannel = 16;
    dataFormat.mReserved = 0;
    
    AudioQueueNewInput(&dataFormat, AudioInputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_queue);
    AudioQueueStart(_queue, NULL);
    
    UInt32 enabledLevelMeter = true;
    AudioQueueSetProperty(_queue, kAudioQueueProperty_EnableLevelMetering, &enabledLevelMeter, sizeof(UInt32));
    

    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                              target:self
                                            selector:@selector(detectVolume:)
                                            userInfo:nil
                                             repeats:YES];
}


- (void)stopUpdatingVolume
{
    AudioQueueFlush(_queue);
    AudioQueueStop(_queue, NO);
    AudioQueueDispose(_queue, YES);
}

- (void)detectVolume:(NSTimer *)timer
{
    // Get noise level
    AudioQueueLevelMeterState levelMeter;
    UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(_queue, kAudioQueueProperty_CurrentLevelMeterDB, &levelMeter, &levelMeterSize);

    double max = levelMeter.mPeakPower;
    double ave = levelMeter.mAveragePower;
    
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:[NSNumber numberWithDouble:max] forKey:@"double_frequency"];
    [dic setObject:[NSNumber numberWithDouble:ave] forKey:@"double_decibels"];
    [dic setObject:@0 forKey:@"double_RMS"];
    [dic setObject:@0 forKey:@"is_silent"];
    [dic setObject:@0 forKey:@"silent_threshold"];
    [dic setObject:@0 forKey:@"raw"];
    [self setLatestValue:[NSString stringWithFormat:
                          @"%f, %f",max, ave]];
    [self saveData:dic];
//    self.loudLabel.hidden = (levelMeter.mPeakPower >= -1.0f) ? NO : YES;
}


@end
