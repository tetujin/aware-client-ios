//
//  MSBand.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBand.h"
#import "AppDelegate.h"
#import "EntityMSBandHR.h"
#import "EntityMSBandUV.h"
#import "EntityMSBandGSR.h"
#import "EntityMSBandCalorie.h"
#import "EntityMSBandDistance.h"
#import "EntityMSBandSkinTemp.h"
#import "EntityMSBandPedometer.h"
#import "EntityMSBandBatteryGauge.h"
#import "EntityMSBandDeviceContact.h"
#import "EntityMSBandRRInterval.h"

#import "MSBandGSR.h"
#import "MSBandUV.h"
#import "MSBandCalorie.h"
#import "MSBandSkinTemp.h"
#import "MSBandDistance.h"
#import "MSBandHR.h"
#import "MSBandPedometer.h"
#import "MSBandDeviceContact.h"
#import "MSBandRRInterval.h"

NSString * const AWARE_PREFERENCES_STATUS_MSBAND = @"status_plugin_msband_sensors";
NSString * const AWARE_PREFERENCES_MSBAND_INTERVAL_TIME_MIN = @"active_time_interval_in_minute";
NSString * const AWARE_PREFERENCES_MSBAND_ACTIVE_TIME_MIN   = @"active_time_in_minute";

@implementation MSBand {
    
    double intervalMin;
    double activeMin;
    
    AWAREStudy * awareStudy;
    
    // sensors
    MSBandGSR           * gsrSensor;
    MSBandUV            * uvSensor;
    MSBandCalorie       * calSensor;
    MSBandSkinTemp      * skinTempSensor;
    MSBandDistance      * distanceSensor;
    MSBandHR            * hrSensor;
    MSBandPedometer     * pedometerSensor;
    MSBandDeviceContact * deviceContactSensor;
    MSBandRRInterval    * rrIntervalSensor;
    
    NSTimer * timer;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          pluginName:SENSOR_PLUGIN_MSBAND
                          entityName:@"---"
                              dbType:dbType];
    
    // AwareDBType currentDBType = [self getDBType];

    // self = [super initWithPluginName:SENSOR_PLUGIN_MSBAND awareStudy:study ];
    awareStudy = study;
    if (self) {
        
        intervalMin = 10;
        activeMin = 2;
        
        [self setTypeAsPlugin];
        
        [self addDefaultSettingWithBool:@NO key:AWARE_PREFERENCES_STATUS_MSBAND desc:@"true or false to activate or deactivate accelerometer sensor."];
        [self addDefaultSettingWithNumber:@10 key:AWARE_PREFERENCES_MSBAND_INTERVAL_TIME_MIN desc:@"Interval between active time (in minutes, default: 10 minutes)"];
        [self addDefaultSettingWithNumber:@2  key:AWARE_PREFERENCES_MSBAND_ACTIVE_TIME_MIN   desc:@"Active Time (in minute, default: 2 minutes)"];
        
        [MSBClientManager sharedManager].delegate = self;
        NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
        self.client = [clients firstObject];
        
        [[MSBClientManager sharedManager] connectClient:self.client];
        NSLog(@"%@",[NSString stringWithFormat:@"Please wait. Connecting to Band <%@>", self.client.name]);
        
        
        // ============================== GSR sensor ==============================
        gsrSensor = [[MSBandGSR alloc] initWithMSBClient:self.client
                                            awareStudy:awareStudy
                                                sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_GSR
                                            dbEntityName:NSStringFromClass([EntityMSBandGSR class])
                                                  dbType:dbType
                                              bufferSize:30];
        [gsrSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)gsrSensor];
        
        
        // ============================== UV sensor ==============================
        uvSensor = [[MSBandUV alloc] initWithMSBClient:self.client
                                            awareStudy:awareStudy
                                            sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_UV
                                          dbEntityName:NSStringFromClass([EntityMSBandUV class])
                                                dbType:dbType
                                            bufferSize:0];
        [uvSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)uvSensor];

        
        // ============================== Cal sensor ==============================
        calSensor = [[MSBandCalorie alloc] initWithMSBClient:self.client
                                                  awareStudy:awareStudy
                                                  sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_CALORIES
                                                dbEntityName:NSStringFromClass([EntityMSBandCalorie class])
                                                      dbType:dbType
                                                  bufferSize:10];
        [calSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)calSensor];
        
        
        // =========================== Skin Temp sensor ================================
        skinTempSensor = [[MSBandSkinTemp alloc] initWithMSBClient:self.client
                                                        awareStudy:awareStudy
                                                        sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_SKINTEMP
                                                      dbEntityName:NSStringFromClass([EntityMSBandSkinTemp class])
                                                            dbType:dbType
                                                        bufferSize:0];
        [skinTempSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)skinTempSensor];
        
        
        
        // ============================== Distance sensor =============================
        distanceSensor = [[MSBandDistance alloc] initWithMSBClient:self.client
                                                        awareStudy:awareStudy
                                                        sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_DISTANCE
                                                      dbEntityName:NSStringFromClass([EntityMSBandDistance class])
                                                            dbType:dbType
                                                        bufferSize:10];
        [distanceSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)distanceSensor];
                          
        
        // ============================== HeartRate sensor ============================
        hrSensor = [[MSBandHR alloc] initWithMSBClient:self.client
                                            awareStudy:awareStudy
                                            sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_HEARTRATE
                                          dbEntityName:NSStringFromClass([EntityMSBandHR class])
                                                dbType:dbType
                                            bufferSize:5];
        [hrSensor trackDebugEvents];
        [hrSensor requestHRUserConsent];
        [super addAnAwareSensor:(AWARESensor *)hrSensor];
       
        
        // ============================= Pedometer ======================================
        pedometerSensor = [[MSBandPedometer alloc] initWithMSBClient:self.client
                                                          awareStudy:awareStudy
                                                          sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_PEDOMETER
                                                        dbEntityName:NSStringFromClass([EntityMSBandPedometer class])
                                                              dbType:dbType
                                                          bufferSize:10];
        [super addAnAwareSensor:(AWARESensor *)pedometerSensor];
        
        
        // =============================== Device Contact ===============================
        deviceContactSensor = [[MSBandDeviceContact alloc] initWithMSBClient:self.client
                                                                  awareStudy:awareStudy
                                                                  sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_DEVICECONTACT
                                                                dbEntityName:NSStringFromClass([EntityMSBandDeviceContact class])
                                                                      dbType:dbType
                                                                  bufferSize:0];
        [deviceContactSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)deviceContactSensor];
        
        
        // ================================ RRInterval sensor ============================
        rrIntervalSensor = [[MSBandRRInterval alloc] initWithMSBClient:self.client
                                                            awareStudy:awareStudy
                                                            sensorName:SENSOR_PLUGIN_MSBAND_SENSORS_RRINTERVAL
                                                          dbEntityName:NSStringFromClass([EntityMSBandRRInterval class])
                                                                dbType:dbType
                                                            bufferSize:10];
        [deviceContactSensor trackDebugEvents];
        [super addAnAwareSensor:(AWARESensor *)rrIntervalSensor];
    }
    return self;
}


- (void)createTable{
    [gsrSensor createTable];
    [uvSensor createTable];
    [calSensor createTable];
    [skinTempSensor createTable];
    [distanceSensor createTable];
    [hrSensor createTable];
    [pedometerSensor createTable];
    [deviceContactSensor createTable];
    [rrIntervalSensor createTable];
}

- (BOOL) startAllSensorsWithSettings:(NSArray *)settings {
    if (self.client == nil) {
        NSLog(@"Failed! No Bands attached.");
        return NO;
    }else{
        NSLog(@"Start MSBand Sensor!");
    }
    
    // active_time_interval_in_minute
    intervalMin = [self getSensorSetting:settings withKey:@"active_time_interval_in_minute"];
    if(intervalMin < 0){
        intervalMin = 10;
    }
    
    // active_time_in_minute
    activeMin = [self getSensorSetting:settings withKey:@"active_time_in_minute"];
    if(activeMin  < 0){
        activeMin = 2;
    }
    
    timer = [NSTimer scheduledTimerWithTimeInterval:intervalMin*60.0f
                                             target:self
                                           selector:@selector(startDutyCycle)
                                           userInfo:nil
                                            repeats:YES];
    [timer fire];
    
    return YES;
}


- (BOOL)stopSensor{
    return [self stopAllSensors];
}

- (BOOL) stopAllSensors{
    [timer invalidate];
    timer = nil;
    [super stopAndRemoveAllSensors];
    // [self stopMSBSensors];
    return YES;
}

///////////////////////////////////////////
///////////////////////////////////////////

- (void) startDutyCycle {
    NSLog(@"Start a duty cycle...");
    [self startMSBSensorsWithActiveTimeInSeconds:activeMin*60.0f];
    // [self performSelector:@selector(stopMSBSensors) withObject:nil afterDelay:activeMin*60.0f];
}


/////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////

- (void)startMSBSensorsWithActiveTimeInSeconds:(int)activeTime{
    NSString * msg = @"Start all sensors on the MS Band.";
    NSLog(@"%@", msg);
    if ([self isDebug]) {
        [AWAREUtils sendLocalNotificationForMessage:msg soundFlag:NO];
    }
    
    int baseDelaySecond = 3;
    
    NSDictionary * setting = [NSDictionary dictionaryWithObject:@(activeTime) forKey:SENSOR_PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    NSArray *settings = @[setting];
    
    [uvSensor            performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 1];
    [skinTempSensor      performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 2];
    [hrSensor            performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 3];
    [gsrSensor           performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 4];
    [deviceContactSensor performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 5];
    [calSensor           performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 6];
    [distanceSensor      performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 7];
    [rrIntervalSensor    performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 8];
    [pedometerSensor     performSelector:@selector(startSensorWithSettings:) withObject:settings afterDelay:baseDelaySecond * 9];
    
    [super setLatestValue:[hrSensor getLatestValue]];
}


- (NSString *)getLatestValue{
    return [hrSensor getLatestValue];
}

- (NSData *)getLatestData{
    
    NSString * data = @"";
    data = [[NSString alloc] initWithData:[uvSensor            getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[skinTempSensor      getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[hrSensor            getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[gsrSensor           getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[deviceContactSensor getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[calSensor           getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[distanceSensor      getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[rrIntervalSensor    getLatestData] encoding:NSUTF8StringEncoding];
    NSLog(@"%@", data);
    data = [[NSString alloc] initWithData:[pedometerSensor     getLatestData] encoding:NSUTF8StringEncoding];
    
    return [hrSensor getLatestData];
}


//////////////////////////////////////
/////////////////////////////////////

- (void)syncAwareDB{
    [super syncAwareDB];
}

- (BOOL)syncAwareDBInForeground{
    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
    [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
    [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
    [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
    [userInfo setObject:[self getSensorName] forKey:@"KEY_UPLOAD_SENSOR_NAME"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                        object:nil
                                                      userInfo:userInfo];
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


- (void) startBatteryGaugeSensor {
//    AWARESensor * batteryGaugeSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_BATTERYGAUGE  withAwareStudy:awareStudy];
}



////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

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

//- (AWARESensor *) getAccSensor {
//    AWARESensor *accSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
//                                                          sensorName:PLUGIN_MSBAND_SENSORS_ACC
//                                                        dbEntityName:nil
//                                                              dbType:AwareDBTypeTextFile];
//    
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
//    [accSensor createTable:query withTableName:PLUGIN_MSBAND_SENSORS_ACC];
//    
//    NSLog(@"Start an Accelerometer Sensor!");
//    void (^accelerometerHandler)(MSBSensorAccelerometerData *, NSError *) = ^(MSBSensorAccelerometerData *accelerometerData, NSError *error){
//        NSString* data = [NSString stringWithFormat:@"X = %5.2f Y = %5.2f Z = %5.2f",
//                          accelerometerData.x,
//                          accelerometerData.y,
//                          accelerometerData.z];
//        NSNumber* unixtime = [self getUnixTime];
//        
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithDouble:accelerometerData.x] forKey:@"double_values_0"];
//        [dic setObject:[NSNumber numberWithDouble:accelerometerData.y] forKey:@"double_values_1"];
//        [dic setObject:[NSNumber numberWithDouble:accelerometerData.z] forKey:@"double_values_2"];
//        [dic setObject:@0 forKey:@"accuracy"];
//        [dic setObject:@"" forKey:@"label"];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [accSensor setLatestValue:data];
//            [accSensor saveData:dic];
//        });
//    };
//    NSError *stateError;
//    //    //Start accelerometer sensor on a MSBand.
//    if (![self.client.sensorManager startAccelerometerUpdatesToQueue:nil errorRef:&stateError withHandler:accelerometerHandler]) {
//        NSLog(@"Accelerometer is faild: %@", stateError.description);
//    }
//    [accSensor setBufferSize:100];
//    [accSensor trackDebugEvents];
//    return accSensor;
//}


///////////////////////////////////////////////////////////////


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

////////////////////////////////////////////////////////////

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

//////////////////////////////////////////////////////////////////////////

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

////////////////////////////////////////////////////////////////////////////////////

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


@end
