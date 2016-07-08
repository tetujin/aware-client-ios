//
//  AWARESensorManager.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// This class manages AWARESensors' start and stop operation.
// And also, you can upload sensor data manually by using this class.
//
//

#import "AWARESensorManager.h"
#import "AWAREStudy.h"
#import "AWAREKeys.h"
#import "AWAREPlugin.h"

// AWARE Sensors
#import "Accelerometer.h"
#import "Gyroscope.h"
#import "Magnetometer.h"
#import "Battery.h"
#import "Barometer.h"
#import "Locations.h"
#import "Network.h"
#import "Wifi.h"
#import "Processor.h"
#import "Gravity.h"
#import "LinearAccelerometer.h"
#import "Bluetooth.h"
#import "AmbientNoise.h"
#import "Screen.h"
#import "NTPTime.h"
#import "Proximity.h"
#import "Timezone.h"
#import "Calls.h"
#import "ESM.h"
#import "PushNotification.h"

// AWARE Plugins
#import "ActivityRecognition.h"
#import "OpenWeather.h"
#import "DeviceUsage.h"
#import "MSBand.h"
#import "GoogleCalPull.h"
#import "GoogleCalPush.h"
#import "GoogleLogin.h"
#import "BalacnedCampusESMScheduler.h"
#import "FusedLocations.h"
#import "Pedometer.h"
#import "BLEHeartRate.h"
#import "Memory.h"
#import "AWAREHealthKit.h"
#import "AmbientNoise.h"

#import "Observer.h"

@implementation AWARESensorManager{
    /** upload timer */
    NSTimer * uploadTimer;
    /** sensor manager */
    NSMutableArray* awareSensors;
    /** aware study */
    AWAREStudy * awareStudy;
    /** lock state*/
    BOOL lock;
    /** progress of manual upload */
    int manualUploadProgress;
    int numberOfSensors;
    BOOL manualUploadResult;
    NSTimer * manualUploadMonitor;
    NSObject * observer;
    NSMutableDictionary * progresses;
    int manualUploadTime;
    BOOL alertState;
    NSDictionary * previousProgresses;
}

/**
 * Init a AWARESensorManager with an AWAREStudy
 * @param   AWAREStudy  An AWAREStudy content
 */
- (instancetype)initWithAWAREStudy:(AWAREStudy *) study {
    self = [super init];
    if (self) {
        awareSensors = [[NSMutableArray alloc] init];
        awareStudy = study;
        lock = false;

        manualUploadProgress = 0;
        numberOfSensors = 0;
        manualUploadTime = 0;
        alertState = NO;
        previousProgresses = [[NSDictionary alloc] init];
    }
    return self;
}


- (void)lock{
    lock = YES;
}

- (void)unlock{
    lock = NO;
}

- (BOOL)isLocked{
    return lock;
}

- (BOOL) startAllSensors{
    return [self startAllSensorsWithStudy:awareStudy];
}

- (BOOL)startAllSensorsWithStudy:(AWAREStudy *) study {
    
    if (study != nil){
        awareStudy = study;
    }else{
        return NO;
    }
    
    double initDelay = 0.5;
    if ([AWAREUtils isBackground]){
        initDelay = 3;
    }

    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeBlack];
    
    if ([[awareStudy getStudyId] isEqualToString:@""]) {
        NSLog( @"ERROR: You did not have a StudyID. Please check your study configuration.");
        return NO;
    }
    
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//    double uploadInterval = [userDefaults doubleForKey:SETTING_SYNC_INT];
    
    // sensors settings
    NSArray *sensors = [awareStudy getSensors];
    
    // plugins settings
    NSArray *plugins = [awareStudy  getPlugins];
    
    /// start and make a sensor instance
    AWARESensor* awareSensor = nil;
    for (int i=0; i<sensors.count; i++) {
        
        awareSensor = nil;
        
        NSString * setting = [[sensors objectAtIndex:i] objectForKey:@"setting"];
        NSString * value = [[sensors objectAtIndex:i] objectForKey:@"value"];
        
        if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_ACCELEROMETER]]) {
            awareSensor= [[Accelerometer alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BAROMETER]]){
            awareSensor = [[Barometer alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GYROSCOPE]]){
            awareSensor = [[Gyroscope alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_MAGNETOMETER]]){
            awareSensor = [[Magnetometer alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BATTERY]]){
            awareSensor = [[Battery alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_LOCATIONS]]){
            awareSensor = [[Locations alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_NETWORK]]){
            awareSensor = [[Network alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_WIFI]]){
            awareSensor = [[Wifi alloc] initWithAwareStudy:awareStudy];
        }else if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PROCESSOR]]){
            awareSensor = [[Processor alloc] initWithAwareStudy:awareStudy];
        }else if ([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GRAVITY]]){
            awareSensor = [[Gravity alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_LINEAR_ACCELEROMETER]]){
            awareSensor = [[LinearAccelerometer alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_BLUETOOTH]]){
            awareSensor = [[Bluetooth alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_SCREEN]]){
            awareSensor = [[Screen alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PROXIMITY]]){
            awareSensor = [[Proximity alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_TIMEZONE]]){
            awareSensor = [[Timezone alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_ESMS]]){
            awareSensor = [[ESM alloc] initWithAwareStudy:awareStudy];
        }else if([setting isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_CALLS]]){
            awareSensor = [[Calls alloc] initWithAwareStudy:awareStudy];
        }
        
        if (awareSensor != nil) {
            // Start the sensor
            if ([value isEqualToString:@"true"]) {
                [awareSensor startSensorWithSettings:sensors];
            }
            [awareSensor trackDebugEvents];
            // Add the sensor to the sensor manager
            [self addNewSensor:awareSensor];
        }
    }

    //     Start and make a plugin instance
    for (int i=0; i<plugins.count; i++) {
        NSDictionary *plugin = [plugins objectAtIndex:i];
        NSArray *pluginSettings = [plugin objectForKey:@"settings"];
        for (NSDictionary* pluginSetting in pluginSettings) {
            
            awareSensor = nil;
            NSString *pluginName = [pluginSetting objectForKey:@"setting"];
            
            if ([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_ACTIVITY_RECOGNITION]]) {
                awareSensor = [[ActivityRecognition alloc] initWithAwareStudy:awareStudy];
            } else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_OPEN_WEATHER]]){
                awareSensor = [[OpenWeather alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_DEVICE_USAGE]]){
                awareSensor = [[DeviceUsage alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_NTPTIME]]){
                awareSensor = [[NTPTime alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_MSBAND]]){
                awareSensor = [[MSBand alloc] initWithPluginName:SENSOR_PLUGIN_MSBAND awareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_CAL_PULL]]){
                awareSensor = [[GoogleCalPull alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_CAL_PUSH]]){
                awareSensor = [[GoogleCalPush alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_GOOGLE_LOGIN]]){
                awareSensor = [[GoogleLogin alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_PLUGIN_CAMPUS]]){
                awareSensor = [[BalacnedCampusESMScheduler alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_GOOGLE_FUSED_LOCATION]]){
                awareSensor = [[FusedLocations alloc] initWithAwareStudy:awareStudy];
            }else if([pluginName isEqualToString:[NSString stringWithFormat:@"status_%@",SENSOR_AMBIENT_NOISE]]){
                awareSensor = [[AmbientNoise alloc] initWithAwareStudy:awareStudy];
            }
            
            if(awareSensor != nil){
                bool pluginState = [pluginSetting objectForKey:@"value"];
                if(pluginState){
                    [awareSensor startSensorWithSettings:pluginSettings];
                }
                [awareSensor trackDebugEvents];
                [self addNewSensor:awareSensor];
            }
        }
    }
    
    /**
     * [Additional hidden sensors]
     * You can add your own AWARESensor and AWAREPlugin to AWARESensorManager directly using following source code.
     * The "-addNewSensor" method is versy userful for testing and debuging a AWARESensor without registlating a study.
     */
    
    // Pedometer
//    AWARESensor * steps = [[Pedometer alloc] initWithSensorName:SENSOR_PLUGIN_PEDOMETER withAwareStudy:awareStudy];
//    [steps startSensor:uploadInterval withSettings:nil];
//    [self addNewSensor:steps];
    
    // HealthKit
//    AWARESensor *healthKit = [[AWAREHealthKit alloc] initWithSensorName:@"plugin_health_kit" withAwareStudy:awareStudy];
//    [healthKit startSensor:uploadInterval withSettings:nil];
//    [self addNewSensor:healthKit];
    
    // Memory
//    AWARESensor *memory = [[Memory alloc] initWithSensorName:@"memory" withAwareStudy:awareStudy];
//    [memory startSensor:uploadInterval withSettings:nil];
//    [self addNewSensor:memory];
    
    // BLE Heart Rate
    AWARESensor *bleHeartRate = [[BLEHeartRate alloc] initWithAwareStudy:awareStudy];
    [bleHeartRate startSensorWithSettings:nil];
    [self addNewSensor:bleHeartRate];

    
    // Observer
    AWARESensor *observerSensor = [[Observer alloc] initWithAwareStudy:awareStudy];
    [self addNewSensor:observerSensor];

    // Push Notification
    AWARESensor * pushNotification = [[PushNotification alloc] initWithAwareStudy:awareStudy];
    [pushNotification startSensorWithSettings:nil];
    [self addNewSensor:pushNotification];
    
    /**
     * Debug Sensor
     * NOTE: don't remove this sensor. This sensor collects and upload debug message to the server each 15 min.
     */
    AWARESensor * debug = [[Debug alloc] initWithAwareStudy:awareStudy];
    [debug startSensorWithSettings:nil];
    [self addNewSensor:debug];

    return YES;
}


- (BOOL)createAllTables{
    for(AWARESensor * sensor in awareSensors){
        [sensor createTable];
    }
    return YES;
}


/**
 * Check an existance of a sensor by a sensor name
 * You can find and edit the keys on AWAREKeys.h and AWAREKeys.m
 *
 * @param   key A NSString key for a sensor
 * @return  An existance of the target sensor as a boolean value
 */
- (BOOL) isExist :(NSString *) key {
    if([key isEqualToString:@"location_gps"] || [key isEqualToString:@"location_network"]){
        key = @"locations";
    }
    
    if([key isEqualToString:@"esm"]){
        key = @"esms";
    }
    
    for (AWARESensor* sensor in awareSensors) {
        if([[sensor getSensorName] isEqualToString:key]){
            return YES;
        }
    }
    return NO;
}


/**
 * Add a new sensor to a aware sensor manager
 *
 * @param sensor An AWARESensor object (A null value is not an acceptable)
 */
- (void) addNewSensor : (AWARESensor *) sensor {
    if (sensor == nil) return;
    for(AWARESensor* storedSensor in awareSensors){
        if([storedSensor.getSensorName isEqualToString:sensor.getSensorName]){
            return;
        }
    }
    [awareSensors addObject:sensor];
}


/**
 * Remove all sensors from the manager after stop the sensors
 */
- (void) stopAndRemoveAllSensors {
    [self lock];
    NSString * message = nil;
    @autoreleasepool {
        for (AWARESensor* sensor in awareSensors) {
            message = [NSString stringWithFormat:@"[%@] Stop %@ sensor",[sensor getSensorName], [sensor getSensorName]];
            NSLog(@"%@", message);
            [sensor saveDebugEventWithText:message type:DebugTypeInfo label:@"stop"];
            [sensor stopSensor];
        }
        [awareSensors removeAllObjects];
    }
    [self unlock];
//    awareSensors = [[NSMutableArray alloc] init];
}

/**
 * Stop a sensor with the sensor name.
 * You can find the sensor name (key) on AWAREKeys.h and .m.
 * 
 * @param sensorName A NSString sensor name (key)
 */
- (void) stopASensor:(NSString *)sensorName{
    for (AWARESensor* sensor in awareSensors) {
        if ([sensor.getSensorName isEqualToString:sensorName]) {
            [sensor stopSensor];
        }
        [sensor stopSensor];
    }
}


/**
 * Provide latest sensor data by each sensor as NSString value.
 * You can access the data by using sensor names (keys) on AWAREKeys.h and .m.
 *
 * @param sensorName A NSString sensor name (key)
 * @return A latest sensor value as
 */
- (NSString*) getLatestSensorData:(NSString *) sensorName {
    if ([self isLocked]) return @"";
    
    if([sensorName isEqualToString:@"location_gps"] || [sensorName isEqualToString:@"location_network"]){
        sensorName = @"locations";
    }
    
    
    for (AWARESensor* sensor in awareSensors) {
        if (sensor.getSensorName != nil) {
            if ([sensor.getSensorName isEqualToString:sensorName]) {
                NSString *sensorValue = [sensor getLatestValue];
                return sensorValue;
            }
        }
    }
    return @"";
}


/**
 * Upload sensor data manually in the foreground
 *
 * NOTE: 
 * This method works in the foreground only, and lock the uploading file.
 * During an uploading process, an AWARE can not access to the file.
 *
 */
- (bool) syncAllSensorsWithDBInForeground {
    
    if(manualUploadMonitor != nil){
        [manualUploadMonitor invalidate];
        manualUploadMonitor = nil;
    }
    
    [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
    [SVProgressHUD showWithStatus:@"Start manual upload"];
    
//    [self stopAndRemoveAllSensors];
//    [self startAllSensors];
    
    manualUploadMonitor = [NSTimer scheduledTimerWithTimeInterval:1
                                                           target:self
                                                         selector:@selector(checkAllSensorsUploadStatus:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        
        // show progress view
        numberOfSensors = (int)awareSensors.count;
        progresses = [[NSMutableDictionary alloc] init];
        for (AWARESensor * sensor in awareSensors) {
            [progresses setObject:@0 forKey:[sensor getSensorName]];
        }
        
        
    

        observer = [[NSNotificationCenter defaultCenter]
                               addObserverForName:ACTION_AWARE_DATA_UPLOAD_PROGRESS
                               object:nil
                               queue:nil
                               usingBlock:^(NSNotification *notif) {
                                   NSDictionary * userInfo = notif.userInfo;
                                   if(userInfo != nil){
                                       NSNumber* progressStr = [userInfo objectForKey:KEY_UPLOAD_PROGRESS_STR];
                                       BOOL isFinish =  [[userInfo objectForKey:KEY_UPLOAD_FIN] boolValue];
                                       BOOL isSuccess = [[userInfo objectForKey:KEY_UPLOAD_SUCCESS] boolValue];
                                       NSString* progressName = [userInfo objectForKey:KEY_UPLOAD_SENSOR_NAME];
                                       [progresses setObject:progressStr forKey:progressName];
                                       // call main thread for UI update
                                       dispatch_sync(dispatch_get_main_queue(), ^{
                                           // update progress
                                           @try {
                                               NSMutableString * result = [[NSMutableString alloc] init];
                                               for (id key in [progresses keyEnumerator]) {
                                                   double progress = [[progresses objectForKey:key] doubleValue];
                                                   [result appendFormat:@"%@ (%.2f %%)\n", key, progress];
                                               }
                                               [SVProgressHUD showWithStatus:result];
                                           } @catch (NSException *exception) {
                                               NSLog(@"%@", exception.debugDescription);
                                           } @finally {
                                               
                                           }
                                           
                                           // stop
                                           if(isFinish == YES && isSuccess == NO){
                                               AudioServicesPlayAlertSound(1324);
                                               if([AWAREUtils isBackground]){
                                                   [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] Fail to upload sensor data. Please try upload again." soundFlag:YES];
                                               }else{
                                                   UIAlertView *alert = [ [UIAlertView alloc]
                                                                         initWithTitle:@""
                                                                         message:@"[Manual Upload] Fail to upload sensor data. Please try upload again."
                                                                         delegate:nil
                                                                         cancelButtonTitle:@"OK"
                                                                         otherButtonTitles:nil];
                                                   [alert show];
                                               }
                                           }
                                       });
                                   }
                               }];
        
        for ( AWARESensor * sensor in awareSensors ) {
            [sensor syncAwareDBInForeground];
        }
        
        
//        for ( int i=0; i < awareSensors.count; i++) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                NSLog(@"%d", [NSThread isMainThread]);
//                @try {
//                    if (i < awareSensors.count ) {
//                        AWARESensor* sensor = [awareSensors objectAtIndex:i];
//                        [sensor  syncAwareDBInForeground];
//                    }else{
//                        NSLog(@"error");
//                    }
//                } @catch (NSException *e) {
//                    NSLog(@"An exception was appeared: %@",e.name);
//                    NSLog(@"The reason: %@",e.reason);
//                }
//            });
//        }

    });
    return YES;
}


- (void) checkAllSensorsUploadStatus:(id)sensder{
    
    BOOL finish = YES;
    for (AWARESensor * sensor in awareSensors) {
        if([sensor isUploading]){
            finish = NO;
        }
    }
    
    if(finish){
        // stop NSTimer
        [manualUploadMonitor invalidate];
        manualUploadMonitor = nil;
        // remove observer from DefaultCenter
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
       
        // check progress of all sensors
        BOOL completion = YES;
        
        @try {
            for (id key in [progresses keyEnumerator]) {
                double progress = [[progresses objectForKey:key] doubleValue];
                NSLog(@"[%@] %f", key ,progress);
                if(progress < 100){
                    completion = NO;
                    break;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception.debugDescription);
        } @finally {
            
        }
        
        
//        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:1.0f];
        [SVProgressHUD dismiss];
        
        if ( completion ){
//            [SVProgressHUD showSuccessWithStatus:@"Success to upload all sensor data!"];
            AudioServicesPlayAlertSound(1000);
            if([AWAREUtils isBackground]){
                [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] Success to upload all sensor data!" soundFlag:YES];
            }else{
                UIAlertView *alert = [ [UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"[Manual Upload] Success to upload all sensor data!"
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alert show];
            }
        } else {
//            [SVProgressHUD showErrorWithStatus:@"Fail to upload sensor data. Please try upload again."];
            AudioServicesPlayAlertSound(1324);
            if([AWAREUtils isBackground]){
                [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] Fail to upload sensor data. Please try upload again." soundFlag:YES];
            }else{
                UIAlertView *alert = [ [UIAlertView alloc]
                                      initWithTitle:@""
                                      message:@"[Manual Upload] Fail to upload sensor data. Please try upload again."
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
                [alert show];
            }
            
        }
    }
    
    /** ========= Freeze Check ======== */
    @try {
        manualUploadTime ++;
        // NSLog(@"%d", manualUploadTime);
        if(manualUploadTime > 60 ){
            manualUploadTime = 0;
            for (id key in [progresses keyEnumerator]) {
                double progress = [[progresses objectForKey:key] doubleValue];
                if(progress == 0 && alertState == NO ){
                    alertState = YES;
                    UIAlertView *alert = [ [UIAlertView alloc]
                                          initWithTitle:@"Manual Upload"
                                          message:@"Do you continue to upload sensor data? Perhaps, this manual upload process occurred an error. Please try manual upload again."
                                          delegate:self
                                          cancelButtonTitle:@"NO"
                                          otherButtonTitles:@"YES",nil];
                    [alert show];
                    break;
                }
            }
            previousProgresses = progresses;
        }
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.debugDescription);
    } @finally {
        
    }
    
    
    /** =======  WiFi network ======= */
//    if(![awareStudy isWifiReachable]){
//        // stop NSTimer
//        [manualUploadMonitor invalidate];
//        manualUploadMonitor = nil;
//        
//        // remove observer from DefaultCenter
//        [[NSNotificationCenter defaultCenter] removeObserver:observer];
//        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
//        AudioServicesPlayAlertSound(1324);
//        
//        if([AWAREUtils isBackground]){
//            [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] WiFi connection is closed. Please try upload again with WiFi." soundFlag:YES];
//        }else{
//            UIAlertView *alert = [ [UIAlertView alloc]
//                                  initWithTitle:@""
//                                  message:@"[Manual Upload] WiFi connection is closed. Please try upload again with WiFi."
//                                  delegate:nil
//                                  cancelButtonTitle:@"OK"
//                                  otherButtonTitles:nil];
//            [alert show];
//        }
//    }
    
    /** =========  Battery Charging  ====== */
//    if( [UIDevice currentDevice].batteryState == UIDeviceBatteryStateUnplugged ){
//        [manualUploadMonitor invalidate];
//        manualUploadMonitor = nil;
//        
//        // remove observer from DefaultCenter
//        [[NSNotificationCenter defaultCenter] removeObserver:observer];
//        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
//        AudioServicesPlayAlertSound(1324);
//        
//        if([AWAREUtils isBackground]){
//            [AWAREUtils sendLocalNotificationForMessage:@"[Manual Upload] The battery is not charged. Please try upload again with battery charging." soundFlag:YES];
//        }else{
//            UIAlertView *alert = [ [UIAlertView alloc]
//                                  initWithTitle:@""
//                                  message:@"[Manual Upload] The battery is not charged. Please try upload again with battery charging."
//                                  delegate:nil
//                                  cancelButtonTitle:@"OK"
//                                  otherButtonTitles:nil];
//            [alert show];
//        }
//    }
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1) {
        // stop NSTimer
        [manualUploadMonitor invalidate];
        manualUploadMonitor = nil;
        // remove observer from DefaultCenter
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        [SVProgressHUD showErrorWithStatus:@"fail to upload your data to the server."];
        AudioServicesPlayAlertSound(1324);
        [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
    }
    alertState = NO;
}


- (bool) syncOldSensorsDataInTextFileWithDBInForeground {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        @autoreleasepool{
            // Show progress bar
            bool sucessOfUpload = true;
            dispatch_sync(dispatch_get_main_queue(), ^{
                [SVProgressHUD showWithMaskType:SVProgressHUDMaskTypeBlack];
            });
            // Sync local stored data with aware server.
            for ( int i=0; i<awareSensors.count; i++) {
                
                AWARESensor* sensor = [awareSensors objectAtIndex:i];
                NSString *message = [NSString stringWithFormat:@"Uploading %@ data %@",
                                     [sensor getSensorName],
                                     [sensor getSyncProgressAsText]];
                [SVProgressHUD setStatus:message];
                
                [sensor sensorLock];
                if (![sensor syncAwareDBInForeground]) {
                    sucessOfUpload = NO;
                }
                [sensor sensorUnLock];
            }
            // Update UI in the main thread.
            dispatch_sync(dispatch_get_main_queue(), ^{
                if (sucessOfUpload) {
                    [SVProgressHUD showSuccessWithStatus:@"Success to upload your data to the server!"];
                    AudioServicesPlayAlertSound(1000);
                }else{
                    [SVProgressHUD showErrorWithStatus:@"Fail to upload your data to the server."];
                    AudioServicesPlayAlertSound(1324);
                }
                [SVProgressHUD performSelector:@selector(dismiss) withObject:nil afterDelay:3.0f];
                
            });
        }
    });
    return YES;
}


/**
 * Sync All Sensors with DB in the bacground
 *
 */
- (bool) syncAllSensorsWithDBInBackground {
    // Sync local stored data with aware server.
    if(awareSensors == nil){
        return NO;
    }
    for ( int i=0; i < awareSensors.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i * 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            @try {
                if (i < awareSensors.count ) {
                    AWARESensor* sensor = [awareSensors objectAtIndex:i];
                    [sensor syncAwareDB];
                }else{
                    NSLog(@"error");
                }
            } @catch (NSException *e) {
                NSLog(@"An exception was appeared: %@",e.name);
                NSLog(@"The reason: %@",e.reason);
            }
        });
    }
    return YES;
}



- (void) startUploadTimerWithInterval:(double) interval {
    if (uploadTimer != nil) {
        [uploadTimer invalidate];
        uploadTimer = nil;
    }
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                   target:self
                                                 selector:@selector(syncAllSensorsWithDBInBackground)
                                                 userInfo:nil
                                                  repeats:YES];
}

- (void) stopUploadTimer{
    [uploadTimer invalidate];
    uploadTimer = nil;
}

- (void)runBatteryStateChangeEvents{
    if(awareSensors == nil) return;
    for (AWARESensor * sensor in awareSensors) {
        [sensor changedBatteryState];
    }
}


@end
