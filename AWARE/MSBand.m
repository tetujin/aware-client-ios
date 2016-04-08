//
//  MSBand.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBand.h"

@implementation MSBand {
//    NSTimer* uploadTimer;
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
    
    AWAREStudy * awareStudy;
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
        PLUGIN_MSBAND_SENSORS_GSR = @"plugin_msband_gsr";
        PLUGIN_MSBAND_SENSORS_ALTIMETER = @"plugin_msband_altimeter";
        PLUGIN_MSBAND_SENSORS_BAROMETER = @"plugin_msband_sensors_barometer";
    }
    return self;
}


- (void)createTable{
    
}

- (BOOL) startAllSensors:(double)upInterval withSettings:(NSArray *)settings {
    NSLog(@"Start MSBand Sensor!");
    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    self.client = [clients firstObject];
    if (self.client == nil) {
        NSLog(@"Failed! No Bands attached.");
        return NO;
    }
    [[MSBClientManager sharedManager] connectClient:self.client];
    NSLog(@"%@",[NSString stringWithFormat:@"Please wait. Connecting to Band <%@>", self.client.name]);
    
    //    [self performSelector:@selector(startMSBSensors) withObject:0 afterDelay:5];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        //        [awareSensor startSensor:uploadTime withSettings:settings];
        [self startMSBSensors:upInterval withSettings:settings];
    });
    
    return YES;
}

- (BOOL) stopAllSensors{
    [self stopMSBSensors];
    return YES;
}


- (void)syncAwareDB{
    [super syncAwareDB];
}

- (BOOL)syncAwareDBInForeground{
    return [super syncAwareDBInForeground];
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



/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

- (void)startMSBSensors:(double)upInterval withSettings:(NSArray *)settings{
    [super addAnAwareSensor:[self getCalorieSensor]];
    [super addAnAwareSensor:[self getDistanceSensor]];
    [super addAnAwareSensor:[self getGSRSensor]]; //x
    [super addAnAwareSensor:[self getHRSensor]];
    [super addAnAwareSensor:[self getSkinTempSensor]];
    [super addAnAwareSensor:[self getUVSensor]];
    [super addAnAwareSensor:[self getBatteryGaugeSensor]];
    
    //    [self startAccelerometer];
    //    [self startAltimeter]; //x
    //    [self startAmbientLight]; //x
    //    [self startBarometer];
    //    [self startPedometer];
    //    [self startRRInterval];
    //    [self startGyroscope];
    
    [super startAllSensors:upInterval withSettings:settings];
}

- (void) stopMSBSensors {
    [super stopAndRemoveAllSensors];
    NSLog(@"Stop all sensors on the MS Band.");
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

//////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

// Sensors


- (AWARESensor *) getCalorieSensor{
    
    AWARESensor *calSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_CALORIES withAwareStudy:awareStudy];
    
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "calories integer default 0,"
    "UNIQUE (timestamp,device_id)";
    [calSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_CALORIES];
    
    NSLog(@"Start a Cal sensor!");
    void (^calHandler)(MSBSensorCaloriesData *, NSError *) = ^(MSBSensorCaloriesData *calData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", calData.calories];
        //        NSLog(@"Cal: %@",data);
        NSNumber* unixtime = [self getUnixTime];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInteger:calData.calories] forKey:@"calories"];
        [calSensor setLatestValue:data];
        [calSensor saveData:dic];
    };
    NSError *stateError;
    if (![self.client.sensorManager startCaloriesUpdatesToQueue:nil errorRef:&stateError withHandler:calHandler]) {
        NSLog(@"Cal sensor is faild: %@", stateError.description);
    }
    [calSensor trackDebugEvents];
    [calSensor setBufferSize:100];
    return calSensor;
}



- (AWARESensor *) getDistanceSensor{
    
    AWARESensor *distanceSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_DISTANCE withAwareStudy:awareStudy];
    
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "distance integer default 0,"
    "motiontype texte default '',"
    "UNIQUE (timestamp,device_id)";
    [distanceSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_DISTANCE];
    
    NSLog(@"Start a Distance Sensor!");
    void (^distanceHandler)(MSBSensorDistanceData *, NSError *) = ^(MSBSensorDistanceData *distanceData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", distanceData.totalDistance];
        //        @property (nonatomic, readonly) NSUInteger totalDistance;
        //        @property (nonatomic, readonly) double speed;
        //        @property (nonatomic, readonly) double pace;
        //        @property (nonatomic, readonly) MSBSensorMotionType motionType;
        //        NSLog(@"Distance: %@",data);
        NSString* motionType = @"";
        switch (distanceData.motionType) {
            case MSBSensorMotionTypeUnknown:
                motionType = @"Unknown";
                break;
            case MSBSensorMotionTypeJogging:
                motionType = @"Jogging";
                break;
            case MSBSensorMotionTypeRunning:
                motionType = @"Running";
                break;
            case MSBSensorMotionTypeIdle:
                motionType = @"Idle";
                break;
            case MSBSensorMotionTypeWalking:
                motionType = @"Walking";
                break;
            default:
                motionType = @"Unkonwn";
                break;
        }
        
//        NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970] * 10000;
        NSNumber* unixtime = [self getUnixTime];//[NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithInteger:distanceData.totalDistance] forKey:@"distance"];
        [dic setObject:motionType forKey:@"motiontype"];
        [distanceSensor setLatestValue:data];
        [distanceSensor saveData:dic];
    };
    NSError *stateError;
    if (![self.client.sensorManager startDistanceUpdatesToQueue:nil errorRef:&stateError withHandler:distanceHandler]) {
        NSLog(@"Distance sensor is faild: %@", stateError.description);
    }
    [distanceSensor setBufferSize:100];
    [distanceSensor trackDebugEvents];
    return distanceSensor;
}

- (AWARESensor *) getGSRSensor { //x
    AWARESensor * gsrSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_GSR withAwareStudy:awareStudy];
    NSLog(@"Start a GSR Sensor!");
    void (^gsrHandler)(MSBSensorGSRData *, NSError *error) = ^(MSBSensorGSRData *gsrData, NSError *error){
        NSString *data = [NSString stringWithFormat:@"%8u kOhm", (unsigned int)gsrData.resistance];
        //        NSLog(@"GSR: %@",data);
    };
    NSError *stateError;
    if (![self.client.sensorManager startGSRUpdatesToQueue:nil errorRef:&stateError withHandler:gsrHandler]) {
        NSLog(@"GSE sensor is faild: %@", stateError.description);
    }
    [gsrSensor setBufferSize:100];
    [gsrSensor trackDebugEvents];
    return gsrSensor;
}


- (AWARESensor *) getHRSensor {
    
    AWARESensor *hrSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_HEARTRATE withAwareStudy:awareStudy];

    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "heartrate integer default 0,"
    "heartrate_quality text default '',"
    "UNIQUE (timestamp,device_id)";
    [hrSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_HEARTRATE];
    
    NSLog(@"Start a HeartRate Sensor!");
    [self.client.sensorManager requestHRUserConsentWithCompletion:^(BOOL userConsent, NSError *error) {
        if (userConsent) {
            void (^hrHandler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
                NSString * data = [NSString stringWithFormat:@"Heart Rate: %3u %@",
                                   (unsigned int)heartRateData.heartRate,
                                   heartRateData.quality == MSBSensorHeartRateQualityAcquiring ? @"Acquiring" : @"Locked"];
                //                NSLog(@"HR: %@", data);
                NSString* quality = @"";
                switch (heartRateData.quality) {
                    case MSBSensorHeartRateQualityAcquiring:
                        quality = @"Acquiring";
                        break;
                    case MSBSensorHeartRateQualityLocked:
                        quality = @"Locked";
                        break;
                    default:
                        quality = @"Unkonwn";
                        break;
                }
//                NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970] * 10000;
                NSNumber* unixtime = [self getUnixTime]; //[NSNumber numberWithDouble:timeStamp];
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                [dic setObject:unixtime forKey:@"timestamp"];
                [dic setObject:[self getDeviceId] forKey:@"device_id"];
                [dic setObject:[NSNumber numberWithDouble:heartRateData.heartRate] forKey:@"heartrate"];
                [dic setObject:quality forKey:@"heartrate_quality"];
                [hrSensor setLatestValue:data];
                [hrSensor saveData:dic toLocalFile:PLUGIN_MSBAND_SENSORS_HEARTRATE];
//                NSLog(@"%@", data);
                [super setLatestValue:data]; //TODO
            };
            NSError *stateError;
            if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:hrHandler]) {
                NSLog(@"HR sensor is faild: %@", stateError.description);
            }
        } else{
            NSLog(@"User consent declined.");
        }
    }];
    [hrSensor setBufferSize:100];
    [hrSensor trackDebugEvents];
    return hrSensor;
}


- (AWARESensor *) getUVSensor {
    AWARESensor *uvSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_UV withAwareStudy:awareStudy];
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "uv real default 0,"
    "UNIQUE (timestamp,device_id)";
    [uvSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_UV];
    NSLog(@"Start a UV sensor!");
    void (^uvHandler)(MSBSensorUVData *, NSError *) = ^(MSBSensorUVData *uvData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %ld", uvData.uvIndexLevel];
        //        NSLog(@"UV: %@",data);
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithDouble:uvData.uvIndexLevel] forKey:@"uv"];
        [uvSensor setLatestValue:data];
        [uvSensor saveData:dic];
    };
    NSError *stateError;
    if (![self.client.sensorManager startUVUpdatesToQueue:nil errorRef:&stateError withHandler:uvHandler]) {
        NSLog(@"UV sensor is faild: %@", stateError.description);
    }
    [uvSensor setBufferSize:100];
    [uvSensor trackDebugEvents];
    return uvSensor;
}

- (AWARESensor *) getBatteryGaugeSensor {
    AWARESensor * batteryGaugeSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_BATTERYGAUGE  withAwareStudy:awareStudy];
    return batteryGaugeSensor;
}


- (AWARESensor *) getSkinTempSensor {
    AWARESensor *skinTempSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_SKINTEMP  withAwareStudy:awareStudy];
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "skintemp real default 0,"
    "UNIQUE (timestamp,device_id)";
    [skinTempSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_SKINTEMP];
    NSLog(@"Start a Skin Teamperature Sensor!");
    void (^skinHandler)(MSBSensorSkinTemperatureData *, NSError *) = ^(MSBSensorSkinTemperatureData *skinData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %.2f", skinData.temperature];
        //        NSLog(@"Skin: %@",data);
        NSNumber* unixtime = [self getUnixTime]; //[NSNumber numberWithDouble:timeStamp];
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:unixtime forKey:@"timestamp"];
        [dic setObject:[self getDeviceId] forKey:@"device_id"];
        [dic setObject:[NSNumber numberWithDouble:skinData.temperature] forKey:@"skintemp"];
        [skinTempSensor setLatestValue:data];
        [skinTempSensor saveData:dic];

    };
    NSError *stateError;
    if (![self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:&stateError withHandler:skinHandler]) {
        NSLog(@"Skin sensor is faild: %@", stateError.description);
    }
    [skinTempSensor setBufferSize:100];
    [skinTempSensor trackDebugEvents];
    return skinTempSensor;
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
        [accSensor setLatestValue:data];
        [accSensor saveData:dic];
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