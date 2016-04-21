//
//  MSBand.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBand.h"

@implementation MSBand {
    NSString* PLUGIN_MSBAND_SENSORS_CALORIES;
    NSString* PLUGIN_MSBAND_SENSORS_DEVICECONTACT;
    NSString* PLUGIN_MSBAND_SENSORS_DISTANCE;
    NSString* PLUGIN_MSBAND_SENSORS_HEARTRATE;
    NSString* PLUGIN_MSBAND_SENSORS_PEDOMETER;
    NSString* PLUGIN_MSBAND_SENSORS_SKINTEMP;
    NSString* PLUGIN_MSBAND_SENSORS_UV;
    NSString* PLUGIN_MSBAND_SENSORS_BATTERYGAUGE;
    NSString* PLUGIN_MSBAND_SENSORS_GSR;
    NSString* PLUGIN_MSBAND_SENSORS_ACC;
    NSString* PLUGIN_MSBAND_SENSORS_GYRO;
    NSString* PLUGIN_MSBAND_SENSORS_ALTIMETER;
    NSString* PLUGIN_MSBAND_SENSORS_BAROMETER;
    
    double intervalMin;
    double activeMin;
    
    AWAREStudy * awareStudy;
    
    // sensors
    AWARESensor *calSensor;
    AWARESensor *distanceSensor;
    AWARESensor *gsrSensor;
    AWARESensor *hrSensor;
    AWARESensor *uvSensor;
    AWARESensor *skinTempSensor;
    AWARESensor *pedometerSensor;
    AWARESensor *deviceContactSensor;
    
    NSTimer * timer;
}

- (instancetype)initWithPluginName:(NSString *)pluginName awareStudy:(AWAREStudy *)study{
    self = [super initWithPluginName:pluginName awareStudy:study];
    awareStudy = study;
    if (self) {
        PLUGIN_MSBAND_SENSORS_ACC = @"plugin_msband_sensors_accelerometer";
        PLUGIN_MSBAND_SENSORS_GYRO = @"plugin_msband_sensors_gyroscope";
        PLUGIN_MSBAND_SENSORS_CALORIES = @"plugin_msband_sensors_calories";
        PLUGIN_MSBAND_SENSORS_DEVICECONTACT = @"plugin_msband_sensors_devicecontact";
        PLUGIN_MSBAND_SENSORS_DISTANCE = @"plugin_msband_sensors_distance";
        PLUGIN_MSBAND_SENSORS_HEARTRATE = @"plugin_msband_sensors_heartrate";
        PLUGIN_MSBAND_SENSORS_PEDOMETER = @"plugin_msband_sensors_pedometer";
        PLUGIN_MSBAND_SENSORS_SKINTEMP = @"plugin_msband_sensors_skintemp";
        PLUGIN_MSBAND_SENSORS_UV = @"plugin_msband_sensors_uv";
        
        PLUGIN_MSBAND_SENSORS_BATTERYGAUGE = @"plugin_msband_sensors_batterygauge";
        PLUGIN_MSBAND_SENSORS_GSR = @"plugin_msband_sensors_gsr";
        PLUGIN_MSBAND_SENSORS_ALTIMETER = @"plugin_msband_sensors_altimeter";
        PLUGIN_MSBAND_SENSORS_BAROMETER = @"plugin_msband_sensors_barometer";
        
        intervalMin = 10;
        activeMin = 1;
        
        [MSBClientManager sharedManager].delegate = self;
        NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
        self.client = [clients firstObject];
        
        [[MSBClientManager sharedManager] connectClient:self.client];
        NSLog(@"%@",[NSString stringWithFormat:@"Please wait. Connecting to Band <%@>", self.client.name]);
        
        [self requestHRUserConsent];
        
        // cal sensor
        calSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_CALORIES withAwareStudy:awareStudy];
        [calSensor trackDebugEvents];
        [calSensor setBufferSize:10];
        [super addAnAwareSensor:calSensor];
        
        // distance sensor
        distanceSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_DISTANCE withAwareStudy:awareStudy];
        [distanceSensor setBufferSize:10];
        [distanceSensor trackDebugEvents];
        [super addAnAwareSensor:distanceSensor];
        
        // GSR sensor
        gsrSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_GSR withAwareStudy:awareStudy];
        [gsrSensor setBufferSize:30];
        [gsrSensor trackDebugEvents];
        [super addAnAwareSensor:gsrSensor];
        
        // HeartRate sensor
        hrSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_HEARTRATE withAwareStudy:awareStudy];
        [super addAnAwareSensor:hrSensor];
        [hrSensor setBufferSize:5];
        [hrSensor trackDebugEvents];
        
        // UV sensor
        uvSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_UV withAwareStudy:awareStudy];
//        [uvSensor setBufferSize:3];
        [uvSensor trackDebugEvents];
        [super addAnAwareSensor:uvSensor];
        
        // Skin Temp sensor
        skinTempSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_SKINTEMP  withAwareStudy:awareStudy];
//        [skinTempSensor setBufferSize:3];
        [skinTempSensor trackDebugEvents];
        [super addAnAwareSensor:skinTempSensor];
        
        // Pedometer
        pedometerSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_PEDOMETER withAwareStudy:awareStudy];
        [super addAnAwareSensor:pedometerSensor];
        
        // Device Contact
        deviceContactSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_DEVICECONTACT withAwareStudy:awareStudy];
        [deviceContactSensor setBufferSize:1];
        [deviceContactSensor trackDebugEvents];
        [super addAnAwareSensor:deviceContactSensor];
    }
    return self;
}


- (void)createTable{
    [self createCalorieTable];
    [self createDistanceTable];
    [self createHeartRateTable];
    [self createGSRTable];
    [self createUVTable];
    [self createSkinTempTable];
    [self createPedometerTable];
    [self createDeviceContactTable];
}

- (BOOL) startAllSensors:(double)upInterval withSettings:(NSArray *)settings {
    if (self.client == nil) {
        NSLog(@"Failed! No Bands attached.");
        return NO;
    }else{
        NSLog(@"Start MSBand Sensor!");
    }
    
    // active_time_interval_in_minute
    intervalMin = [self getSensorSetting:settings withKey:@"active_time_interval_in_minute"];
    
    // active_time_in_minute
    activeMin = [self getSensorSetting:settings withKey:@"active_time_in_minute"];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:60.0f * intervalMin
                                             target:self
                                           selector:@selector(startDutyCycle)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
    
    return YES;
}

- (BOOL) stopAllSensors{
    [timer invalidate];
    timer = nil;
    [super stopAndRemoveAllSensors];
    [self stopMSBSensors];
    return YES;
}

- (BOOL)stopSensor{
    return [self stopAllSensors];
}


/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

- (void)startMSBSensors{
    NSString * msg = @"Start all sensors on the MS Band.";
    NSLog(@"%@", msg);
    if ([self isDebug]) {
        [AWAREUtils sendLocalNotificationForMessage:msg soundFlag:NO];
    }
    [self performSelector:@selector(startUVSensor) withObject:nil afterDelay:3];
    [self performSelector:@selector(startSkinTempSensor) withObject:nil afterDelay:6];
    [self performSelector:@selector(startHeartRateSensor) withObject:nil afterDelay:9];
    [self performSelector:@selector(startGSRSensor) withObject:nil afterDelay:12];
    [self performSelector:@selector(startDevicecontactSensor) withObject:nil afterDelay:15];
    [self performSelector:@selector(startCalorieSensor) withObject:nil afterDelay:18];
    [self performSelector:@selector(startDistanceSensor) withObject:nil afterDelay:21];
}

- (void) stopMSBSensors {
    NSString * msg = @"Stop all sensors on the MS Band.";
    NSLog(@"%@", msg);
    if ([self isDebug]) {
        [AWAREUtils sendLocalNotificationForMessage:msg soundFlag:NO];
    }
    [self.client.sensorManager stopAccelerometerUpdatesErrorRef:nil];
    [self.client.sensorManager stopAltimeterUpdatesErrorRef:nil]; //x
    [self.client.sensorManager stopAmbientLightUpdatesErrorRef:nil]; //x
    [self.client.sensorManager stopBandContactUpdatesErrorRef:nil];
    [self.client.sensorManager stopCaloriesUpdatesErrorRef:nil];
    [self.client.sensorManager stopDistanceUpdatesErrorRef:nil];
    [self.client.sensorManager stopGSRUpdatesErrorRef:nil]; //x
    [self.client.sensorManager stopGyroscopeUpdatesErrorRef:nil];
    [self.client.sensorManager stopHeartRateUpdatesErrorRef:nil]; //x
    [self.client.sensorManager stopPedometerUpdatesErrorRef:nil];
    [self.client.sensorManager stopRRIntervalUpdatesErrorRef:nil];
    [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
    [self.client.sensorManager stopUVUpdatesErrorRef:nil];
}



//////////////////////////////////////
/////////////////////////////////////

- (void)syncAwareDB{
    [super syncAwareDB];
}

- (BOOL)syncAwareDBInForeground{
    return [super syncAwareDBInForeground];
}


///////////////////////////////////////////
///////////////////////////////////////////

- (void) startDutyCycle {
    NSLog(@"Start a duty cycle...");
    [self startMSBSensors];
    [self performSelector:@selector(stopMSBSensors) withObject:nil afterDelay:activeMin*60.0f];
}


///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////


/**
 * MSBand Delegate
 */
- (void)clientManager:(MSBClientManager *)clientManager
               client:(MSBClient *)client
didFailToConnectWithError:(NSError *)error{
    
}

- (void) clientManager:(MSBClientManager *)clientManager clientDidConnect:(MSBClient *)client {
    NSLog(@"Microsoft Band is connected!");
}

- (void) clientManager:(MSBClientManager *)clientManager clientDidDisconnect:(MSBClient *)client{
    NSLog(@"Microsoft Band is disconnected!");
}





//////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

- (void) startCalorieSensor{
    NSLog(@"Start a Cal sensor!");
    void (^calHandler)(MSBSensorCaloriesData *, NSError *) = ^(MSBSensorCaloriesData *calData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", calData.calories];
        NSLog(@"Cal: %@",data);
        NSNumber* unixtime = [self getUnixTime];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInteger:calData.calories] forKey:@"calories"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [calSensor setLatestValue:data];
            [calSensor saveData:dic];
        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startCaloriesUpdatesToQueue:nil errorRef:&stateError withHandler:calHandler]) {
        NSLog(@"Cal sensor is failed: %@", stateError.description);
    }
}

- (void) createCalorieTable {
    NSString *query = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "calories integer default 0,"
                        "UNIQUE (timestamp,device_id)";
    [calSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_CALORIES];
}

//////////////////////////////////////////////////
/////////////////////////////////////////////////


- (void) startDistanceSensor{
    NSLog(@"Start a Distance Sensor!");
    void (^distanceHandler)(MSBSensorDistanceData *, NSError *) = ^(MSBSensorDistanceData *distanceData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", distanceData.totalDistance];
        NSLog(@"Distance: %@", data);
        NSString* motionType = @"";
        switch (distanceData.motionType) {
            case MSBSensorMotionTypeUnknown:
                motionType = @"UNKNOWN";
                break;
            case MSBSensorMotionTypeJogging:
                motionType = @"JOGGING";
                break;
            case MSBSensorMotionTypeRunning:
                motionType = @"RUNNING";
                break;
            case MSBSensorMotionTypeIdle:
                motionType = @"IDLE";
                break;
            case MSBSensorMotionTypeWalking:
                motionType = @"WALKING";
                break;
            default:
                motionType = @"UNKNOWN";
                break;
        }
        NSNumber* unixtime = [self getUnixTime];//[NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInteger:distanceData.totalDistance] forKey:@"distance"];
        [dic setObject:motionType forKey:@"motiontype"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [distanceSensor setLatestValue:data];
            [distanceSensor saveData:dic];
        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startDistanceUpdatesToQueue:nil errorRef:&stateError withHandler:distanceHandler]) {
        NSLog(@"Distance sensor is failed: %@", stateError.description);
    }
}

- (void) createDistanceTable{
    NSString *query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "distance integer default 0,"
    "motiontype texte default '',"
    "UNIQUE (timestamp,device_id)";
    [distanceSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_DISTANCE];
}



///////////////////////////////////////////////////////
//////////////////////////////////////////////////////

- (void) startGSRSensor { //x
    NSLog(@"Start a GSR Sensor!");
    void (^gsrHandler)(MSBSensorGSRData *, NSError *error) = ^(MSBSensorGSRData *gsrData, NSError *error){
        NSString *data = [NSString stringWithFormat:@"%8u kOhm", (unsigned int)gsrData.resistance];
        NSLog(@"GSR: %@",data);
        NSNumber *gerValue = [NSNumber numberWithUnsignedInteger:gsrData.resistance];
        NSNumber* unixtime = [self getUnixTime];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:gerValue forKey:@"gsr"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [gsrSensor setLatestValue:data];
            [gsrSensor saveData:dic];
        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startGSRUpdatesToQueue:nil errorRef:&stateError withHandler:gsrHandler]) {
        NSLog(@"GSR sensor is failed: %@", stateError.description);
    }
}

- (void) createGSRTable{
    NSString *query = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "gsr integer default 0,"
                        "UNIQUE (timestamp,device_id)";
    [gsrSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_GSR];
}


///////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////


- (void) requestHRUserConsent {
    MSBUserConsent consent = [self.client.sensorManager heartRateUserConsent];
    switch (consent) {
        case MSBUserConsentGranted:
            // user has granted access
            break;
        case MSBUserConsentDeclined:
            // user has declined access
            break;
        case MSBUserConsentNotSpecified:
            // request user consent
            [self.client.sensorManager requestHRUserConsentWithCompletion:^(BOOL userConsent, NSError *error) {
                if (userConsent) {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Alert"
                                                                    message:@"Please push a refresh button on the navigation bar"
                                                                   delegate:self
                                                          cancelButtonTitle:nil
                                                          otherButtonTitles:@"OK", nil];
                        [alert show];
                    });
                } else {
                    // user declined access
                }
            }];
            break;
    }
}

- (void) startHeartRateSensor {
    void (^hrHandler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
        NSString * data = [NSString stringWithFormat:@"Heart Rate: %3u %@",
                           (unsigned int)heartRateData.heartRate,
                           heartRateData.quality == MSBSensorHeartRateQualityAcquiring ? @"Acquiring" : @"Locked"];
        NSLog(@"HR: %@", data);
//        if ([self isDebug]) {
//            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"HR: %@", data] soundFlag:NO];
//        }
        NSString* quality = @"";
        switch (heartRateData.quality) {
            case MSBSensorHeartRateQualityAcquiring:
                quality = @"ACQUIRING";
                break;
            case MSBSensorHeartRateQualityLocked:
                quality = @"LOCKED";
                break;
            default:
                quality = @"UNKNOWN";
                break;
        }
        NSNumber* unixtime = [self getUnixTime];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithDouble:heartRateData.heartRate] forKey:@"heartrate"];
        [dic setObject:quality forKey:@"heartrate_quality"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [hrSensor setLatestValue:data];
            [hrSensor saveData:dic toLocalFile:PLUGIN_MSBAND_SENSORS_HEARTRATE];
            [super setLatestValue:data]; //TODO
        });
    };
    
    NSError *stateError;
    if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:hrHandler]) {
        NSLog(@"HR sensor is failed: %@", stateError.description);
    }
}


- (void) createHeartRateTable {
    NSString *query = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "heartrate integer default 0,"
                        "heartrate_quality text default '',"
                        "UNIQUE (timestamp,device_id)";
    [hrSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_HEARTRATE];
}




//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////


- (void) startUVSensor {
    NSLog(@"Start a UV sensor!");
    void (^uvHandler)(MSBSensorUVData *, NSError *) = ^(MSBSensorUVData *uvData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %ld", uvData.uvIndexLevel];
        NSLog(@"UV: %@",data);
        if ([self isDebug]) {
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"UV: %@", data] soundFlag:NO];
        }
        NSString * uvLevelStr = @"UNKNOWN";
        switch (uvData.uvIndexLevel) {
            case MSBSensorUVIndexLevelNone:
                uvLevelStr = @"NONE";
                break;
            case MSBSensorUVIndexLevelLow:
                uvLevelStr = @"LOW";
                break;
            case MSBSensorUVIndexLevelMedium:
                uvLevelStr = @"MEDIUM";
                break;
            case MSBSensorUVIndexLevelHigh:
                uvLevelStr = @"HIGH";
                break;
            case MSBSensorUVIndexLevelVeryHigh:
                uvLevelStr = @"VERY_HIGH";
            default:
                break;
        }
        
        
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:uvLevelStr forKey:@"uv"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [uvSensor saveData:dic];
        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startUVUpdatesToQueue:nil errorRef:&stateError withHandler:uvHandler]) {
        NSLog(@"UV sensor is failed: %@", stateError.description);
    }
}

- (void) createUVTable{
    NSString *query = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "uv text default '',"
                        "UNIQUE (timestamp,device_id)";
    [uvSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_UV];
}


////////////////////////////////////////////////
////////////////////////////////////////////////


- (void) startBatteryGaugeSensor {
//    AWARESensor * batteryGaugeSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_BATTERYGAUGE  withAwareStudy:awareStudy];
}



/////////////////////////////////////////////////
////////////////////////////////////////////////


- (void) startSkinTempSensor {
    NSLog(@"Start a Skin Teamperature Sensor!");
    void (^skinHandler)(MSBSensorSkinTemperatureData *, NSError *) = ^(MSBSensorSkinTemperatureData *skinData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %.2f", skinData.temperature];
        NSLog(@"Skin: %@",data);
        if ([self isDebug]) {
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Skin: %@", data] soundFlag:NO];
        }
        NSNumber* unixtime = [self getUnixTime]; //[NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithDouble:skinData.temperature] forKey:@"skintemp"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [skinTempSensor setLatestValue:data];
            [skinTempSensor saveData:dic];
        });

    };
    NSError *stateError;
    if (![self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:&stateError withHandler:skinHandler]) {
        NSLog(@"Skin sensor is failed: %@", stateError.description);
    }
}

- (void) createSkinTempTable {
    NSString *query  = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "skintemp real default 0,"
                        "UNIQUE (timestamp,device_id)";
    [skinTempSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_SKINTEMP];
}


/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

- (void) startPedometerSensor {
    NSLog(@"Start a pedometer Sensor!");
    NSError * error = nil;
    void (^pedometerHandler)(MSBSensorPedometerData *, NSError *) = ^(MSBSensorPedometerData *pedometerData, NSError *error){
        NSNumber* unixtime = [self getUnixTime];
        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInt:pedometerData.totalSteps] forKey:@"pedometer"];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [pedometerSensor saveData:dic];
        });
    };
    
    if(![self.client.sensorManager startPedometerUpdatesToQueue:nil errorRef:&error withHandler:pedometerHandler]){
        NSLog(@"Pedometer is failed: %@", error.description);
    }
}


- (void) createPedometerTable{
    NSString *query = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "pedometer int default 0,"
                        "UNIQUE (timestamp,device_id)";
    [pedometerSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_PEDOMETER];
}

///////////////////////////////////////////////
///////////////////////////////////////////////

- (void) startDevicecontactSensor {
    
    void (^bandHandler)(MSBSensorBandContactData *, NSError*) = ^(MSBSensorBandContactData *contactData, NSError *error) {
        NSString * wornState = @"UNKNOWN";
        switch (contactData.wornState) {
            case MSBSensorBandContactStateWorn:
                wornState = @"WORN";
                break;
            case MSBSensorBandContactStateNotWorn:
                wornState = @"NOT_WORN";
                break;
            case MSBSensorBandContactStateUnknown:
                wornState = @"UNKNOWN";
            default:
                break;
        }
        NSNumber* unixtime = [self getUnixTime]; //[NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:wornState forKey:@"devicecontact"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [deviceContactSensor saveData:dic];
        });
    };
    
    NSError * error = nil;
    if(![self.client.sensorManager startBandContactUpdatesToQueue:nil errorRef:&error withHandler:bandHandler]){
        NSLog(@"ERROR: device contact sensor is failed: %@",error.description);
    }
}

- (void) createDeviceContactTable {
    NSString * query = @"_id integer primary key autoincrement,"
                        "timestamp real default 0,"
                        "device_id text default '',"
                        "devicecontact text default '',"
                        "UNIQUE (timestamp,device_id)";
    [deviceContactSensor createTable:query];
}



///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////



- (NSNumber *) getUnixTime {
    return [AWAREUtils getUnixTimestamp:[NSDate new]];
}


////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////


/**
 * ========================================
 * WIP: sensors
 * ========================================
 */

- (AWARESensor *) getAccSensor {
    AWARESensor *accSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_ACC  withAwareStudy:awareStudy];
    
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_values_0 real default 0,"
    "double_values_1 real default 0,"
    "double_values_2 real default 0,"
    "accuracy integer default 0,"
    "label text default '',"
    "UNIQUE (timestamp,device_id)";
    [accSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_ACC];
    
    NSLog(@"Start an Accelerometer Sensor!");
    void (^accelerometerHandler)(MSBSensorAccelerometerData *, NSError *) = ^(MSBSensorAccelerometerData *accelerometerData, NSError *error){
        NSString* data = [NSString stringWithFormat:@"X = %5.2f Y = %5.2f Z = %5.2f",
                          accelerometerData.x,
                          accelerometerData.y,
                          accelerometerData.z];
        NSNumber* unixtime = [self getUnixTime];
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithDouble:accelerometerData.x] forKey:@"double_values_0"];
        [dic setObject:[NSNumber numberWithDouble:accelerometerData.y] forKey:@"double_values_1"];
        [dic setObject:[NSNumber numberWithDouble:accelerometerData.z] forKey:@"double_values_2"];
        [dic setObject:@0 forKey:@"accuracy"];
        [dic setObject:@"" forKey:@"label"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [accSensor setLatestValue:data];
            [accSensor saveData:dic];
        });
    };
    NSError *stateError;
    //    //Start accelerometer sensor on a MSBand.
    if (![self.client.sensorManager startAccelerometerUpdatesToQueue:nil errorRef:&stateError withHandler:accelerometerHandler]) {
        NSLog(@"Accelerometer is faild: %@", stateError.description);
    }
    [accSensor setBufferSize:100];
    [accSensor trackDebugEvents];
    return accSensor;
}





//- (void) startAltimeter {
//    NSString *query = [[NSString alloc] init];
//    query = @"_id integer primary key autoincrement,"
//    "timestamp real default 0,"
//    "device_id text default '',"
//    "elevation_stepping integer default 0,"
//    "elevation_other_means integer default 0,"
//    "accuracy integer default 0,"
//    "label text default '',"
//    "UNIQUE (timestamp,device_id)";
//    [super createTable:query withTableName:PLUGIN_MSBAND_SENSORS_ALTIMETER];
//    
//    NSLog(@"Start an Altimeter Sensor!");
//    void (^altimeterHandler)(MSBSensorAltimeterData *, NSError *) = ^(MSBSensorAltimeterData *altimeterData, NSError *error){
//        NSString* data  = [NSString stringWithFormat:
//                           @"Elevation gained by stepping (cm)   : %u\n"
//                           @"Elevation gained by other means (cm): %u\n",
//                           (unsigned int)altimeterData.steppingGain,
//                           (unsigned int)(altimeterData.totalGain - altimeterData.steppingGain)];
//        //        NSLog(@"Altimeter: %@",data);
//        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//        NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithDouble:altimeterData.steppingGain] forKey:@"elevation_stepping"];
//        [dic setObject:[NSNumber numberWithDouble:(altimeterData.totalGain - altimeterData.steppingGain)] forKey:@"elevation_other_means"];
//        [dic setObject:@0 forKey:@"accuracy"];
//        [dic setObject:@"" forKey:@"label"];
//        [self setLatestValue:data];
//        [self saveData:dic toLocalFile:PLUGIN_MSBAND_SENSORS_ALTIMETER];
//    };
//    
//    NSError *stateError;
//    //Start altieter sensor on a MSBand.
//    if (![self.client.sensorManager startAltimeterUpdatesToQueue:nil errorRef:&stateError withHandler:altimeterHandler]){
//        NSLog(@"Altimeter sensor is faild: %@", stateError.description);
//    }
//}
//
//- (void) startDeviceContact{
//    
//}
//
//- (void) startBarometer {
//    NSString *query = [[NSString alloc] init];
//    query = @"_id integer primary key autoincrement,"
//    "timestamp real default 0,"
//    "device_id text default '',"
//    "airpressure real default 0,"
//    "temperature real default 0,"
//    "accuracy integer default 0,"
//    "label text default '',"
//    "UNIQUE (timestamp,device_id)";
//    [super createTable:query withTableName:PLUGIN_MSBAND_SENSORS_BAROMETER];
//    
//    NSLog(@"Start a Barometer Sensor!");
//    void (^barometerHandler)(MSBSensorBarometerData *, NSError *) = ^(MSBSensorBarometerData *barometerData, NSError *error) {
//        NSString* data =[NSString stringWithFormat:@"%5.2f hPa, %2.1f°C", barometerData.airPressure, barometerData.temperature];
//        //        NSLog(@"Barometer: %@",data);
//        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//        NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithDouble:barometerData.airPressure] forKey:@"airpressure"];
//        [dic setObject:[NSNumber numberWithDouble:barometerData.temperature] forKey:@"temperature"];
//        [dic setObject:@0 forKey:@"accuracy"];
//        [dic setObject:@"" forKey:@"label"];
//        [self setLatestValue:data];
//        [self saveData:dic toLocalFile:PLUGIN_MSBAND_SENSORS_BAROMETER];
//    };
//    NSError *stateError;
//    
//    //start barometer sensor
//    if (![self.client.sensorManager startBarometerUpdatesToQueue:nil errorRef:&stateError withHandler:barometerHandler]) {
//        NSLog(@"Barometer sensor is faild: %@", stateError.description);
//    }
//}
//
//
//
//
//
//
//- (void) startGyroscope{
//    NSString *query = [[NSString alloc] init];
//    query = @"_id integer primary key autoincrement,"
//    "timestamp real default 0,"
//    "device_id text default '',"
//    "double_values_0 real default 0,"
//    "double_values_1 real default 0,"
//    "double_values_2 real default 0,"
//    "accuracy integer default 0,"
//    "label text default '',"
//    "UNIQUE (timestamp,device_id)";
//    [super createTable:query withTableName:PLUGIN_MSBAND_SENSORS_GYRO];
//    
//    NSLog(@"Start a Gyro Sensor!");
//    void (^gyroHandler)(MSBSensorGyroscopeData *, NSError *) = ^(MSBSensorGyroscopeData *gyroData, NSError *error) {
//        NSString *data = [NSString stringWithFormat:@"%f, %f, %f", gyroData.x, gyroData.y, gyroData.z];
//        //        NSLog(@"%@",data);
//        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
//        NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithDouble:gyroData.x] forKey:@"double_values_0"];
//        [dic setObject:[NSNumber numberWithDouble:gyroData.y] forKey:@"double_values_1"];
//        [dic setObject:[NSNumber numberWithDouble:gyroData.z] forKey:@"double_values_2"];
//        [dic setObject:@0 forKey:@"accuracy"];
//        [dic setObject:@"" forKey:@"label"];
//        [self setLatestValue:data];
//        [self saveData:dic toLocalFile:PLUGIN_MSBAND_SENSORS_ACC];
//    };
//    NSError *stateError;
//    if (![self.client.sensorManager startGyroscopeUpdatesToQueue:nil errorRef:&stateError withHandler:gyroHandler]) {
//        NSLog(@"Gyro sensor is faild: %@", stateError.description);
//    }
//
//}
//
//
//
//
//
//
//
//
//- (void) startPedometer{
//    
//}
//
//
//
//
//
//
//
//- (void) startAmbientLight {//x
//    
//    NSLog(@"Start an AmbientLight Sensor!");
//    void (^ambientLightHandler)(MSBSensorAmbientLightData *, NSError *) = ^(MSBSensorAmbientLightData *ambientLightData, NSError *error){
//        NSString* data = [NSString stringWithFormat:@"AmbientLight: %5d lx", ambientLightData.brightness];
//        //        NSLog(@"Ambient: %@",data);
//    };
//    NSError *stateError;
//    if (![self.client.sensorManager startAmbientLightUpdatesToQueue:nil errorRef:&stateError withHandler:ambientLightHandler]) {
//        NSLog(@"Ambient light sensor is faild: %@", stateError.description);
//    }
//}
//
//
//
//- (void) startRRInterval{
//    
//}


@end