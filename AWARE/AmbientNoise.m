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
//    NSTimer *testTimer;
    AudioQueueRef   _queue;     // 音声入力用のキュー
    NSTimer         *_timer;    // 監視タイマー
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
                                             target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    [self startWriteAbleTimer];
//    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:5.0f target:self selector:@selector(getVolume) userInfo:nil repeats:YES];
    //start anbient sensing
    [self startUpdatingVolume];
//    double frequency = [self getSensorSetting:settings withKey:@"frequency_accelerometer"];
    
//    if(frequency != -1){
//        NSLog(@"Accelerometer's frequency is %f !!", frequency);
//        double iOSfrequency = [self convertMotionSensorFrequecyFromAndroid:frequency];
//        manager.accelerometerUpdateInterval = iOSfrequency;
//    }else{
//        manager.accelerometerUpdateInterval = 0.1f; //default value
//    }
    //    manager.accelerometerUpdateInterval = 0.05f; //default value
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
    // 記録するデータフォーマットを決める
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
    
    // レベルの監視を開始する
    AudioQueueNewInput(&dataFormat, AudioInputCallback, (__bridge void *)(self), CFRunLoopGetCurrent(), kCFRunLoopCommonModes, 0, &_queue);
    AudioQueueStart(_queue, NULL);
    
    // レベルメータを有効化する
    UInt32 enabledLevelMeter = true;
    AudioQueueSetProperty(_queue, kAudioQueueProperty_EnableLevelMetering, &enabledLevelMeter, sizeof(UInt32));
    
    // 定期的にレベルメータを監視する
    _timer = [NSTimer scheduledTimerWithTimeInterval:0.5
                                              target:self
                                            selector:@selector(detectVolume:)
                                            userInfo:nil
                                             repeats:YES];
}


- (void)stopUpdatingVolume
{
    // キューを空にして停止
    AudioQueueFlush(_queue);
    AudioQueueStop(_queue, NO);
    AudioQueueDispose(_queue, YES);
}

- (void)detectVolume:(NSTimer *)timer
{
    // レベルを取得
    AudioQueueLevelMeterState levelMeter;
    UInt32 levelMeterSize = sizeof(AudioQueueLevelMeterState);
    AudioQueueGetProperty(_queue, kAudioQueueProperty_CurrentLevelMeterDB, &levelMeter, &levelMeterSize);
    
    
//     最大レベル、平均レベルを表示
//    self.peakTextField.text = [NSString stringWithFormat:@"%.2f", levelMeter.mPeakPower];
//    self.averageTextField.text = [NSString stringWithFormat:@"%.2f", levelMeter.mAveragePower];
    
    double max = levelMeter.mPeakPower;
    double ave = levelMeter.mAveragePower;
//    NSLog(@"max=%f, ave=%f", max, ave);
    
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
    //
    //                                            dispatch_sync(dispatch_get_main_queue(), ^{
    [self saveData:dic toLocalFile:SENSOR_AMBIENT_NOISE];
    //                                            });
    
//    // mPeakPowerが -1.0 以上なら "LOUD!!" と表示
//    self.loudLabel.hidden = (levelMeter.mPeakPower >= -1.0f) ? NO : YES;
}


-(void) uploadSensorData{
    NSString * jsonStr = nil;
    //    @autoreleasepool {
    jsonStr = [self getData:SENSOR_AMBIENT_NOISE withJsonArrayFormat:YES];
    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_AMBIENT_NOISE]];
    //    }
}

@end
