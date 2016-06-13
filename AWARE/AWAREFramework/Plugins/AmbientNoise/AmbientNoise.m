//
//  AmbientNoise.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/26/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "AmbientNoise.h"
#import "AudioAnalysis.h"
#import "AppDelegate.h"

static vDSP_Length const FFTViewControllerFFTWindowSize = 4096;

@implementation AmbientNoise{
    NSString * KEY_AMBIENT_NOISE_TIMESTAMP;
    NSString * KEY_AMBIENT_NOISE_DEVICE_ID;
    NSString * KEY_AMBIENT_NOISE_FREQUENCY;
    NSString * KEY_AMBIENT_NOISE_DECIDELS;
    NSString * KEY_AMBIENT_NOISE_RMS;
    NSString * KEY_AMBIENT_NOISE_SILENT;
    NSString * KEY_AMBIENT_NOISE_SILENT_THRESHOLD;
    NSString * KEY_AMBIENT_NOISE_RAW;
    
    NSString * FREQUENCY_PLUGIN_AMBIENT_NOISE;
    NSString * PLUGIN_AMBIENT_NOISE_SAMPLE_SIZE;
    NSString * PLUGIN_AMBIENT_NOISE_SILENCE_THRESHOLD;
    
    NSTimer *timer;
    
    int frequencyMin;
    int sampleSize;
    int silenceThreshold;
    
    float recordingSampleRate;
    float targetSampleRate;
//    long lastSetAudioSessionTime;
    
    int currentSecond;
    
    float maxFrequency;
    double db;
    double rms;
    
    float lastdb;
}


- (instancetype)initWithAwareStudy:(AWAREStudy *)study{
    self = [super initWithAwareStudy:study
                          sensorName:SENSOR_AMBIENT_NOISE
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if (self) {
        KEY_AMBIENT_NOISE_TIMESTAMP = @"timestamp";
        KEY_AMBIENT_NOISE_DEVICE_ID = @"device_id";
        KEY_AMBIENT_NOISE_FREQUENCY = @"double_frequency";
        KEY_AMBIENT_NOISE_DECIDELS = @"double_decibels";
        KEY_AMBIENT_NOISE_RMS = @"double_rms";
        KEY_AMBIENT_NOISE_SILENT = @"is_silent";
        KEY_AMBIENT_NOISE_SILENT_THRESHOLD = @"double_silent_threshold";
        KEY_AMBIENT_NOISE_RAW = @"raw";
        
        /**
         * How frequently do we sample the microphone (default = 5) in minutes
         */
        FREQUENCY_PLUGIN_AMBIENT_NOISE = @"frequency_plugin_ambient_noise";
        
        /**
         * For how long we listen (default = 30) in seconds
         */
        PLUGIN_AMBIENT_NOISE_SAMPLE_SIZE = @"plugin_ambient_noise_sample_size";
        
        /**
         * Silence threshold (default = 50) in dB
         */
        PLUGIN_AMBIENT_NOISE_SILENCE_THRESHOLD = @"plugin_ambient_noise_silence_threshold";
        
        frequencyMin = 5;
        sampleSize = 30;
        silenceThreshold = 50;
        
        currentSecond = 0;
        
        recordingSampleRate = 44100;
        targetSampleRate = 8000;
        
        
        maxFrequency = 0;
        db = 0;
        rms = 0;
        
//        _resampleOutputBuffer.bufferLen = 0;
//        _resampleOutputBuffer.bufferSize = MAX_RESAMPLE_BUF_SIZE;
//        _resampleOutputBuffer.bufferPtr = (float*)malloc(_resampleOutputBuffer.bufferSize * sizeof(float));
        
    }
    return self;
}

- (void)createTable {
    NSMutableString * query = [[NSMutableString alloc] init];
    [query appendFormat:@"_id integer primary key autoincrement,"];
//    AmbientNoise_Data._ID + " integer primary key autoincrement," +
    [query appendFormat:@"%@ real default 0,", KEY_AMBIENT_NOISE_TIMESTAMP];
    //    AmbientNoise_Data.TIMESTAMP + " real default 0," +
    [query appendFormat:@"%@ text default '',", KEY_AMBIENT_NOISE_DEVICE_ID];
//    AmbientNoise_Data.DEVICE_ID + " text default ''," +
    [query appendFormat:@"%@ real default 0,", KEY_AMBIENT_NOISE_FREQUENCY];
//    AmbientNoise_Data.FREQUENCY + " real default 0," +
    [query appendFormat:@"%@ real default 0,", KEY_AMBIENT_NOISE_DECIDELS];
//    AmbientNoise_Data.DECIBELS + " real default 0," +
    [query appendFormat:@"%@ real default 0,", KEY_AMBIENT_NOISE_RMS];
//    AmbientNoise_Data.RMS + " real default 0," +
    [query appendFormat:@"%@ integer default 0,", KEY_AMBIENT_NOISE_SILENT];
//    AmbientNoise_Data.IS_SILENT + " integer default 0," +
    [query appendFormat:@"%@ real default 0,", KEY_AMBIENT_NOISE_SILENT_THRESHOLD];
//    AmbientNoise_Data.SILENCE_THRESHOLD + " real default 0," +
    [query appendFormat:@"%@ blob default null,", KEY_AMBIENT_NOISE_RAW];
//    AmbientNoise_Data.RAW + " blob default null," +
    [query appendFormat:@"UNIQUE (%@,%@)", KEY_AMBIENT_NOISE_TIMESTAMP, KEY_AMBIENT_NOISE_DEVICE_ID];
//    "UNIQUE("+AmbientNoise_Data.TIMESTAMP+","+AmbientNoise_Data.DEVICE_ID+")"
    [super createTable:query];
}


-(BOOL)startSensorWithSettings:(NSArray *)settings{
    NSLog(@"Start Anbient Sensor!");
//    [self setBufferSize:100];
    
    frequencyMin = [self getSensorSetting:settings withKey:FREQUENCY_PLUGIN_AMBIENT_NOISE];
    if (frequencyMin <= 0) {
        frequencyMin = 5;
    }
    
    sampleSize = [self getSensorSetting:settings withKey:PLUGIN_AMBIENT_NOISE_SAMPLE_SIZE];
    if (sampleSize <= 0) {
        sampleSize = 30;
    }
    
    silenceThreshold = [self getSensorSetting:settings withKey:PLUGIN_AMBIENT_NOISE_SILENCE_THRESHOLD];
    if (silenceThreshold <= 0){
        silenceThreshold = 50;
    }
    
    [self setupMicrophone];
    
    currentSecond = 0;
    
    timer = [NSTimer scheduledTimerWithTimeInterval: 60.0f * frequencyMin
                                             target:self
                                           selector:@selector(startRecording:)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
    
    return YES;
}


-(BOOL) stopSensor{
    if(timer != nil){
        [timer invalidate];
        timer = nil;
    }
    return YES;
}


//- (void)syncAwareDB{
////    [uploader syncDBInBackground];
//}
//
//- (BOOL)syncAwareDBInForeground{
////    [uploader syncDBInBackground];
//    return YES;
//}

/////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////

-(void)setupMicrophone {
    //https://github.com/syedhali/EZAudio
    //
    // Setup the AVAudioSession. EZMicrophone will not work properly on iOS
    // if you don't do this!
    //
    AVAudioSession *session = [AVAudioSession sharedInstance];
    NSError *error;
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionInterruptSpokenAudioAndMixWithOthers|
     AVAudioSessionCategoryOptionDefaultToSpeaker | AVAudioSessionCategoryOptionAllowBluetooth error:&error];
    if (error) {
        NSLog(@"Error setting up audio session category: %@", error.localizedDescription);
    }
    [session setActive:YES error:&error];
    if (error) {
        NSLog(@"Error setting up audio session active: %@", error.localizedDescription);
    }
    
    AudioStreamBasicDescription absd = [EZAudioUtilities floatFormatWithNumberOfChannels:1 sampleRate:recordingSampleRate];
    //AudioStreamBasicDescription absd = [self monoSIntFormatWithSampleRate:8000];
    
    self.microphone = [EZMicrophone microphoneWithDelegate:self withAudioStreamBasicDescription:absd];
    
}


/**
 * Start recording ambient noise
 */
- (void) startRecording:(id)sender{
    if (self.microphone == nil) {
        [self setupMicrophone];
    }
    if ([self isDebug] && currentSecond == 0) {
        NSLog(@"Start Recording");
        [AWAREUtils sendLocalNotificationForMessage:@"[Ambient Noise] Start Recording" soundFlag:NO];
    }
    //
    // Create an instance of the EZAudioFFTRolling to keep a history of the incoming audio data and calculate the FFT.
    //
    self.fft = [EZAudioFFTRolling fftWithWindowSize:FFTViewControllerFFTWindowSize
                                         sampleRate:self.microphone.audioStreamBasicDescription.mSampleRate
                                           delegate:self];
    
    [self.microphone startFetchingAudio];
    self.recorder = [EZRecorder recorderWithURL:[self testFilePathURL]
                                   clientFormat:[self.microphone audioStreamBasicDescription]
                                       fileType:EZRecorderFileTypeM4A
                                       delegate:self];
    _isRecording = YES;
    [self performSelector:@selector(stopRecording:) withObject:nil afterDelay:1];
    
}


/**
 * Stop recording ambient noise
 */
- (void) stopRecording:(id)sender{
    // stop fetching audio
    [self.microphone stopFetchingAudio];
    // stop recording audio
    [self.recorder closeAudioFile];
    // Save audio data
    [self saveAudioData];
    
    // init variables
    self.recorder = nil;
    maxFrequency = 0;
    db = 0;
    rms = 0;
    lastdb = 0;
    
    // check a dutyCycle
    if( sampleSize > currentSecond ){
        currentSecond++;
        [self startRecording:nil];
    }else{
        NSLog(@"Stop Recording");
        currentSecond = 0;
        _isRecording = NO;
        if ([self isDebug]) {
            [AWAREUtils sendLocalNotificationForMessage:@"[Ambient Noise] Stop Recording" soundFlag:NO];
        }
    }
}


////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

- (void) saveAudioData {
    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:KEY_AMBIENT_NOISE_TIMESTAMP];
    [dic setObject:[self getDeviceId] forKey:KEY_AMBIENT_NOISE_DEVICE_ID];
    [dic setObject:[NSNumber numberWithFloat:maxFrequency] forKey:KEY_AMBIENT_NOISE_FREQUENCY];
    [dic setObject:[NSNumber numberWithDouble:db] forKey:KEY_AMBIENT_NOISE_DECIDELS];
    [dic setObject:[NSNumber numberWithDouble:rms] forKey:KEY_AMBIENT_NOISE_RMS];
    [dic setObject:[NSNumber numberWithBool:[AudioAnalysis isSilent:rms threshold:silenceThreshold]] forKey:KEY_AMBIENT_NOISE_SILENT];
    [dic setObject:[NSNumber numberWithInteger:silenceThreshold] forKey:KEY_AMBIENT_NOISE_SILENT_THRESHOLD];
//    NSData * data = [NSData dataWithContentsOfURL:[self testFilePathURL]];
//    NSString *base64Encoded = [data base64EncodedStringWithOptions:0];
//    if(base64Encoded != nil){
//        [dic setObject:base64Encoded forKey:KEY_AMBIENT_NOISE_RAW];
//    }else{
        [dic setObject:[[NSNull alloc] init] forKey:KEY_AMBIENT_NOISE_RAW];
//    }
    [self saveData:dic];
    
    
//    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
//    PluginAmbientNoise * ambientNoise = [NSEntityDescription insertNewObjectForEntityForName:@"PluginAmbientNoise"
//                                                inManagedObjectContext:delegate.managedObjectContext];
//    ambientNoise.device_id = [self getDeviceId];
//    ambientNoise.timestamp = unixtime;
//    ambientNoise.double_frequency = [NSNumber numberWithFloat:maxFrequency];
//    ambientNoise.double_decibels = [NSNumber numberWithDouble:db];
//    ambientNoise.double_RMS = [NSNumber numberWithDouble:rms];
//    ambientNoise.is_silent = [NSNumber numberWithBool:[AudioAnalysis isSilent:rms threshold:silenceThreshold]];
//    ambientNoise.silent_threshold = [NSNumber numberWithInteger:silenceThreshold];
//    NSData * data = [NSData dataWithContentsOfURL:[self testFilePathURL]];
////    NSString *base64Encoded = [data base64EncodedStringWithOptions:0];
//    ambientNoise.raw = [data base64EncodedStringWithOptions:0];
    
    [self setLatestValue:[NSString stringWithFormat:@"dB:%f, RMS:%f, Frequency:%f", db, rms, maxFrequency]];
    
    if ([self isDebug] && sampleSize<=currentSecond) {
        [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"dB:%f, RMS:%f, Frequency:%f", db, rms, maxFrequency] soundFlag:NO];
    }
    
//    if(sampleSize<=currentSecond){
//        NSError * error = nil;
//        [delegate.managedObjectContext save:&error];
//        if (error) {
//            NSLog(@"%@", error.description);
//        }
//    }
}


//////////////////////////////////////////////////////////////////////
// delegate

/**
 Called anytime the EZMicrophone starts or stops.
 @param output The instance of the EZMicrophone that triggered the event.
 @param isPlaying A BOOL indicating whether the EZMicrophone instance is playing or not.
 */
- (void)microphone:(EZMicrophone *)microphone changedPlayingState:(BOOL)isPlaying{
    
}

//------------------------------------------------------------------------------

/**
 Called anytime the input device changes on an `EZMicrophone` instance.
 @param microphone The instance of the EZMicrophone that triggered the event.
 @param device The instance of the new EZAudioDevice the microphone is using to pull input.
 */
- (void)microphone:(EZMicrophone *)microphone changedDevice:(EZAudioDevice *)device{
    // This is not always guaranteed to occur on the main thread so make sure you
    // wrap it in a GCD block
    dispatch_async(dispatch_get_main_queue(), ^{
        // Update UI here
        NSLog(@"Changed input device: %@", device);
    });
}

//------------------------------------------------------------------------------

/**
 Returns back the audio stream basic description as soon as it has been initialized. This is guaranteed to occur before the stream callbacks, `microphone:hasBufferList:withBufferSize:withNumberOfChannels:` or `microphone:hasAudioReceived:withBufferSize:withNumberOfChannels:`
 @param microphone The instance of the EZMicrophone that triggered the event.
 @param audioStreamBasicDescription The AudioStreamBasicDescription that was created for the microphone instance.
 */
- (void)              microphone:(EZMicrophone *)microphone
  hasAudioStreamBasicDescription:(AudioStreamBasicDescription)audioStreamBasicDescription{
    
}

///-----------------------------------------------------------
/// @name Audio Data Callbacks
///-----------------------------------------------------------

/**
 This method provides an array of float arrays of the audio received, each float array representing a channel of audio data This occurs on the background thread so any drawing code must explicity perform its functions on the main thread.
 @param microphone       The instance of the EZMicrophone that triggered the event.
 @param buffer           The audio data as an array of float arrays. In a stereo signal buffer[0] represents the left channel while buffer[1] would represent the right channel.
 @param bufferSize       The size of each of the buffers (the length of each float array).
 @param numberOfChannels The number of channels for the incoming audio.
 @warning This function executes on a background thread to avoid blocking any audio operations. If operations should be performed on any other thread (like the main thread) it should be performed within a dispatch block like so: dispatch_async(dispatch_get_main_queue(), ^{ ...Your Code... })
 */
- (void)    microphone:(EZMicrophone *)microphone
      hasAudioReceived:(float **)buffer
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels{
    __weak typeof (self) weakSelf = self;
    // Getting audio data as an array of float buffer arrays that can be fed into the
    // EZAudioPlot, EZAudioPlotGL, or whatever visualization you would like to do with
    // the microphone data.
    
    //
    // Calculate the FFT, will trigger EZAudioFFTDelegate
    //
    [self.fft computeFFTWithBuffer:buffer[0] withBufferSize:bufferSize];
    
    //
    // Calculate the RMS with buffer and bufferSize
    // NOTE: 1000
    //
    rms = [EZAudioUtilities RMS:*buffer length:bufferSize] * 1000;
    // NSLog(@"%f", rms);
    
    //
    // Decibel Calculation.
    // https://github.com/syedhali/EZAudio/issues/50
    //
    float one       = 1.0;
    float meanVal = 0.0;
    float tiny = 0.1;
    
    vDSP_vsq(buffer[0], 1, buffer[0], 1, bufferSize);
    vDSP_meanv(buffer[0], 1, &meanVal, bufferSize);
    vDSP_vdbcon(&meanVal, 1, &one, &meanVal, 1, 1, 0);
    
    float currentdb = 1.0 - (fabs(meanVal)/100);
    
    if (lastdb == INFINITY || lastdb == -INFINITY || isnan(lastdb)) {
        lastdb = 0.0;
    }
    db =   ((1.0 - tiny)*lastdb) + tiny*currentdb;
    lastdb = db;
    
    dispatch_async(dispatch_get_main_queue(),^{
        // Visualize this data brah, buffer[0] = left channel, buffer[1] = right channel
//        [weakSelf.audioPlot updateBuffer:buffer[0] withBufferSize:bufferSize];
        [self setLatestValue:[NSString stringWithFormat:@"dB:%f, RMS:%f, Frequency:%f", db, rms, maxFrequency]];
    });
}

//------------------------------------------------------------------------------

/**
 Returns back the buffer list containing the audio received. This occurs on the background thread so any drawing code must explicity perform its functions on the main thread.
 @param microphone       The instance of the EZMicrophone that triggered the event.
 @param bufferList       The AudioBufferList holding the audio data.
 @param bufferSize       The size of each of the buffers of the AudioBufferList.
 @param numberOfChannels The number of channels for the incoming audio.
 @warning This function executes on a background thread to avoid blocking any audio operations. If operations should be performed on any other thread (like the main thread) it should be performed within a dispatch block like so: dispatch_async(dispatch_get_main_queue(), ^{ ...Your Code... })
 */
- (void)    microphone:(EZMicrophone *)microphone
         hasBufferList:(AudioBufferList *)bufferList
        withBufferSize:(UInt32)bufferSize
  withNumberOfChannels:(UInt32)numberOfChannels{
    if (self.isRecording)
    {
        [self.recorder appendDataFromBufferList:bufferList
                                 withBufferSize:bufferSize];
    }
}


///////////////////////////////////////////////
///////////////////////////////////////////////
// EZRecorderDelegate
/**
 Triggers when the EZRecorder is explicitly closed with the `closeAudioFile` method.
 @param recorder The EZRecorder instance that triggered the action
 */
- (void)recorderDidClose:(EZRecorder *)recorder{
    recorder.delegate = nil;
}

/**
 Triggers after the EZRecorder has successfully written audio data from the `appendDataFromBufferList:withBufferSize:` method.
 @param recorder The EZRecorder instance that triggered the action
 */
- (void)recorderUpdatedCurrentTime:(EZRecorder *)recorder{
//    __weak typeof (self) weakSelf = self;
//    NSString *formattedCurrentTime = [recorder formattedCurrentTime];
//    dispatch_async(dispatch_get_main_queue(), ^{
//        weakSelf.currentTimeLabel.text = formattedCurrentTime;
//    });
}


///////////////////////////////////////////////
//////////////////////////////////////////////


- (NSString *)applicationDocumentsDirectory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

- (NSURL *)testFilePathURL
{
    return [NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",
                                   [self applicationDocumentsDirectory],
                                   kAudioFilePath]];
}


/////////////////////////////////////////////
///////////////////////////////////////////////
// FFT delegate
- (void)        fft:(EZAudioFFT *)fft
 updatedWithFFTData:(float *)fftData
         bufferSize:(vDSP_Length)bufferSize
{
    maxFrequency = [fft maxFrequency];
//    NSLog(@"%f", maxFrequency);
//    [self setLatestValue:[NSString stringWithFormat:@"dB:%f, RMS:%f, Frequency:%f", db, rms, maxFrequency]];
}

@end
