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
    NSString* PLUGIN_MSBAND_SENSORS_RRINTERVAL;
    
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
    AWARESensor *rrIntervalSensor;
    
    int reconnectionLimit;
    
    int reconnCountCal;
    int reconnCountDistance;
    int reconnCountGSR;
    int reconnCountHR;
    int reconnCountUV;
    int reconnCountSkinTemp;
    int reconnCountPedometer;
    int reconnCountDeviceContact;
    int reconnCountRRInterval;
    
    NSTimer * timer;
    
    NSString * PLUGIN_MSBAND_KEY_ACTIVE_TIME_INTERVAL_IN_MINUTE;// = @"active_time_interval_in_minute";
    NSString * PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE;// = @"active_time_in_minute"];
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
        PLUGIN_MSBAND_SENSORS_RRINTERVAL = @"plugin_msband_sensors_rrinterval";
        
        PLUGIN_MSBAND_KEY_ACTIVE_TIME_INTERVAL_IN_MINUTE = @"active_time_interval_in_minute";
        PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE = @"active_time_in_minute";
        
        intervalMin = 10;
        activeMin = 1;
        
        reconnectionLimit = 3;
        
        reconnCountCal = 0;
        reconnCountDistance = 0;
        reconnCountGSR = 0;
        reconnCountHR = 0;
        reconnCountUV = 0;
        reconnCountSkinTemp = 0;
        reconnCountPedometer = 0;
        reconnCountDeviceContact = 0;
        reconnCountRRInterval = 0;
        
        [MSBClientManager sharedManager].delegate = self;
        NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
        self.client = [clients firstObject];
        
        [[MSBClientManager sharedManager] connectClient:self.client];
        NSLog(@"%@",[NSString stringWithFormat:@"Please wait. Connecting to Band <%@>", self.client.name]);
        
        [self requestHRUserConsent];
        
        // cal sensor
        calSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                 sensorName:PLUGIN_MSBAND_SENSORS_CALORIES
                                               dbEntityName:NSStringFromClass([EntityMSBandCalorie class])
                                                     dbType:AwareDBTypeCoreData];
        [calSensor trackDebugEvents];
        [calSensor setBufferSize:10];
        [super addAnAwareSensor:calSensor];
        
        // distance sensor
        distanceSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                      sensorName:PLUGIN_MSBAND_SENSORS_DISTANCE
                                                    dbEntityName:NSStringFromClass([EntityMSBandDistance class])
                                                          dbType:AwareDBTypeCoreData];
        [distanceSensor setBufferSize:10];
        [distanceSensor trackDebugEvents];
        [super addAnAwareSensor:distanceSensor];
        
        // GSR sensor
        gsrSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                 sensorName:PLUGIN_MSBAND_SENSORS_GSR
                                               dbEntityName:NSStringFromClass([EntityMSBandGSR class])
                                                     dbType:AwareDBTypeCoreData];
        [gsrSensor setBufferSize:30];
        [gsrSensor trackDebugEvents];
        [super addAnAwareSensor:gsrSensor];
        
        // HeartRate sensor
        hrSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                sensorName:PLUGIN_MSBAND_SENSORS_HEARTRATE
                                              dbEntityName:NSStringFromClass([EntityMSBandHR class])
                                                    dbType:AwareDBTypeCoreData];
        [super addAnAwareSensor:hrSensor];
        [hrSensor setBufferSize:5];
        [hrSensor trackDebugEvents];
        
        // UV sensor
        uvSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                sensorName:PLUGIN_MSBAND_SENSORS_UV
                                              dbEntityName:NSStringFromClass([EntityMSBandUV class])
                                                    dbType:AwareDBTypeCoreData];
        //        [uvSensor setBufferSize:3];
        [uvSensor trackDebugEvents];
        [super addAnAwareSensor:uvSensor];
        
        // Skin Temp sensor
        skinTempSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                      sensorName:PLUGIN_MSBAND_SENSORS_SKINTEMP
                                                    dbEntityName:NSStringFromClass([EntityMSBandSkinTemp class])
                                                          dbType:AwareDBTypeCoreData];
//        [skinTempSensor setBufferSize:3];
        [skinTempSensor trackDebugEvents];
        [super addAnAwareSensor:skinTempSensor];
        
        // Pedometer
        pedometerSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                       sensorName:PLUGIN_MSBAND_SENSORS_PEDOMETER
                                                     dbEntityName:NSStringFromClass([EntityMSBandPedometer class])
                                                           dbType:AwareDBTypeCoreData];
        [super addAnAwareSensor:pedometerSensor];
        
        // Device Contact
        deviceContactSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                           sensorName:PLUGIN_MSBAND_SENSORS_DEVICECONTACT
                                                         dbEntityName:NSStringFromClass([EntityMSBandDeviceContact class])
                                                               dbType:AwareDBTypeCoreData];
        [deviceContactSensor setBufferSize:1];
        [deviceContactSensor trackDebugEvents];
        [super addAnAwareSensor:deviceContactSensor];
        
        // RRInterval sensor
        rrIntervalSensor = [[AWARESensor alloc] initWithAwareStudy:awareStudy
                                                           sensorName:PLUGIN_MSBAND_SENSORS_RRINTERVAL
                                                         dbEntityName:NSStringFromClass([EntityMSBandRRInterval class])
                                                               dbType:AwareDBTypeCoreData];
        [deviceContactSensor setBufferSize:10];
        [deviceContactSensor trackDebugEvents];
        [super addAnAwareSensor:rrIntervalSensor];

        
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
    [self createRRIntervalTable];
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
    
    reconnCountCal = 0;
    reconnCountDistance = 0;
    reconnCountGSR = 0;
    reconnCountHR = 0;
    reconnCountUV = 0;
    reconnCountSkinTemp = 0;
    reconnCountPedometer = 0;
    reconnCountDeviceContact = 0;
    reconnCountRRInterval = 0;
    
    int baseDelaySecond = 3;
    
    NSDictionary * settings = [NSDictionary dictionaryWithObject:@(activeTime) forKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE];
    
    [self performSelector:@selector(startUVSensor:) withObject:settings afterDelay:baseDelaySecond * 1];
    [self performSelector:@selector(startSkinTempSensor:) withObject:settings afterDelay:baseDelaySecond * 2];
    [self performSelector:@selector(startHeartRateSensor:) withObject:settings afterDelay:baseDelaySecond * 3];
    [self performSelector:@selector(startGSRSensor:) withObject:settings afterDelay:baseDelaySecond * 4];
    [self performSelector:@selector(startDevicecontactSensor:) withObject:settings afterDelay:baseDelaySecond * 5];
    [self performSelector:@selector(startCalorieSensor:) withObject:settings afterDelay:baseDelaySecond * 6];
    [self performSelector:@selector(startDistanceSensor:) withObject:settings afterDelay:baseDelaySecond * 7];
    [self performSelector:@selector(startRRIntervalSensor:) withObject:settings afterDelay:baseDelaySecond * 8];
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





//////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

- (void) startCalorieSensor:(NSDictionary *)setting{
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    NSLog(@"Start Calorie Sensor");
    void (^calHandler)(MSBSensorCaloriesData *, NSError *) = ^(MSBSensorCaloriesData *calData, NSError *error) {
//        NSString* cal =[NSString stringWithFormat:@"%ld", calData.calories];
        if ([self isDebug]) {
            NSLog(@"Cal: %ld",calData.calories);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandCalorie * data = (EntityMSBandCalorie *)[NSEntityDescription insertNewObjectForEntityForName:[calSensor getEntityName]
                                                                                              inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.calories = @(calData.calories);
            
            [calSensor saveDataToDB];
        });
//        NSNumber* unixtime = [self getUnixTime];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithInteger:calData.calories] forKey:@"calories"];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [calSensor setLatestValue:data];
//            [calSensor saveData:dic];
//        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startCaloriesUpdatesToQueue:nil errorRef:&stateError withHandler:calHandler]) {
//        if(reconnCountCal < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect Cal sensor (%d) : %@", reconnCountCal, stateError.description);
//            [self performSelector:@selector(startCalorieSensor:) withObject:setting afterDelay:1];
//            reconnCountCal++;
//        }else{
//            NSLog(@"[ERROR] Cal sensor connection is failed: %@", stateError.description);
//            reconnCountCal = 0;
//        }
    }else{
        [self performSelector:@selector(stopCalorieSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopCalorieSensor {
    NSLog(@"Stop Calorie Sensor");
    [self.client.sensorManager stopCaloriesUpdatesErrorRef:nil];
}

//////////////////////////////////////////////////
/////////////////////////////////////////////////


- (void) startDistanceSensor:(NSDictionary *) setting {
    NSLog(@"Start Distance Sensor!");
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    void (^distanceHandler)(MSBSensorDistanceData *, NSError *) = ^(MSBSensorDistanceData *distanceData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", distanceData.totalDistance];
        if ([self isDebug]) {
            NSLog(@"Distance: %@", data);
        }
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
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandDistance * data = (EntityMSBandDistance *)[NSEntityDescription insertNewObjectForEntityForName:[distanceSensor getEntityName]
                                                                                  inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.distance = @(distanceData.totalDistance);
            data.motiontype = motionType;
            
            [distanceSensor saveDataToDB];
        });
//        NSNumber* unixtime = [self getUnixTime];//[NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithInteger:distanceData.totalDistance] forKey:@"distance"];
//        [dic setObject:motionType forKey:@"motiontype"];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [distanceSensor setLatestValue:data];
//            [distanceSensor saveData:dic];
//        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startDistanceUpdatesToQueue:nil errorRef:&stateError withHandler:distanceHandler]) {
//        if(reconnCountDistance < reconnectionLimit ){
//            NSLog(@"[ERROR] Retry to connect Distance sensor (%d) : %@", reconnCountDistance, stateError.description);
//            [self performSelector:@selector(startDistanceSensor:) withObject:setting afterDelay:1];
//            reconnCountDistance++;
//        }else{
//            NSLog(@"[ERROR] Distance sensor connection is failed: %@", stateError.description);
//            reconnCountDistance = 0;
//        }
    }else{
        [self performSelector:@selector(stopDistanceSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopDistanceSensor{
    NSLog(@"Stop Distance Sensor");
    [self.client.sensorManager stopDistanceUpdatesErrorRef:nil];
}


///////////////////////////////////////////////////////
//////////////////////////////////////////////////////

- (void) startGSRSensor:(NSDictionary *) setting { //x
    
    NSLog(@"Start GSR Sensor");
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    void (^gsrHandler)(MSBSensorGSRData *, NSError *error) = ^(MSBSensorGSRData *gsrData, NSError *error){
        NSString *data = [NSString stringWithFormat:@"%8u kOhm", (unsigned int)gsrData.resistance];
        if ([self isDebug]) {
            NSLog(@"GSR: %@", data);
        }
        NSNumber *gsrValue = [NSNumber numberWithUnsignedInteger:gsrData.resistance];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandGSR * data = (EntityMSBandGSR *)[NSEntityDescription insertNewObjectForEntityForName:[gsrSensor getEntityName]
                                                                                                inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.gsr = gsrValue;
            [gsrSensor saveDataToDB];
            
            //        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
            //        [dic setObject:unixtime forKey:@"timestamp"];
            //        [dic setObject:[self getDeviceId] forKey:@"device_id"];
            //        [dic setObject:gsrValue forKey:@"gsr"];
            //
            //        dispatch_async(dispatch_get_main_queue(), ^{
            //            [gsrSensor setLatestValue:data];
            //            [gsrSensor saveData:dic];
            //        });
        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startGSRUpdatesToQueue:nil errorRef:&stateError withHandler:gsrHandler]) {
        //NSLog(@"GSR sensor is failed: %@", stateError.description);
//        if(reconnCountGSR < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect GSR sensor (%d) : %@", reconnCountGSR, stateError.description);
//            [self performSelector:@selector(startGSRSensor:) withObject:setting afterDelay:1];
//            reconnCountGSR++;
//        }else{
//            NSLog(@"[ERROR] GSR sensor connection is failed: %@", stateError.description);
//            reconnCountGSR = 0;
//        }
    }else{
        [self performSelector:@selector(stopGSRSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopGSRSensor{
    NSLog(@"Stop GSR Sensor");
    [self.client.sensorManager stopGSRUpdatesErrorRef:nil];
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

- (void) startHeartRateSensor:(NSDictionary *) setting {
    
    NSLog(@"Start Heart Rate Sensor");
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    void (^hrHandler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
        
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandHR * data = (EntityMSBandHR *)[NSEntityDescription insertNewObjectForEntityForName:[hrSensor getEntityName]
                                                                                                inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.heartrate = @(heartRateData.heartRate);
            data.heartrate_quality = quality;
            
            [hrSensor saveDataToDB];
            
            // set latese sensor value
            NSString * latestValue = [NSString stringWithFormat:@"Heart Rate: %3u %@",
                               (unsigned int)heartRateData.heartRate,
                               heartRateData.quality == MSBSensorHeartRateQualityAcquiring ? @"Acquiring" : @"Locked"];
            if ([self isDebug]) {
                NSLog(@"HR: %@", latestValue);
            }
            [super setLatestValue:latestValue];
        });
        
        
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithDouble:heartRateData.heartRate] forKey:@"heartrate"];
//        [dic setObject:quality forKey:@"heartrate_quality"];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [hrSensor setLatestValue:data];
//            [hrSensor saveData:dic toLocalFile:PLUGIN_MSBAND_SENSORS_HEARTRATE];
//            [super setLatestValue:data]; //TODO
//        });
    };
    
    NSError *stateError;
    if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:hrHandler]) {
        // NSLog(@"HR sensor is failed: %@", stateError.description);
//        if(reconnCountHR < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect HR sensor (%d) : %@", reconnCountHR, stateError.description);
//            [self performSelector:@selector(startHeartRateSensor:) withObject:setting afterDelay:1];
//            reconnCountHR++;
//        }else{
//            NSLog(@"[ERROR] HR sensor connection is failed: %@", stateError.description);
//            reconnCountHR = 0;
//        }
    }else{
        [self performSelector:@selector(stopHeartRateSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopHeartRateSensor {
    NSLog(@"Stop Heart Rate Sensor");
    [self.client.sensorManager stopHeartRateUpdatesErrorRef:nil];
}


//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////


- (void) startUVSensor:(NSDictionary *) setting {
    
    NSLog(@"Start UV sensor");
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    void (^uvHandler)(MSBSensorUVData *, NSError *) = ^(MSBSensorUVData *uvData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %ld", uvData.uvIndexLevel];
        if ([self isDebug]) {
            NSLog(@"UV: %@",data);
        }
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandUV * data = (EntityMSBandUV *)[NSEntityDescription insertNewObjectForEntityForName:[uvSensor getEntityName]
                                                                                    inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.uv = uvLevelStr;
            
            [uvSensor saveDataToDB];
        });
        
        
//        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:uvLevelStr forKey:@"uv"];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [uvSensor saveData:dic];
//        });
    };
    NSError *stateError;
    if (![self.client.sensorManager startUVUpdatesToQueue:nil errorRef:&stateError withHandler:uvHandler]) {
        // NSLog(@"UV sensor is failed: %@", stateError.description);
//        if(reconnCountUV < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect UV sensor (%d) : %@", reconnCountUV, stateError.description);
//            [self performSelector:@selector(startUVSensor:) withObject:setting afterDelay:1];
//            reconnCountUV++;
//        }else{
//            NSLog(@"[ERROR] UV sensor connection is failed: %@", stateError.description);
//            reconnCountUV = 0;
//        }
    }else{
        [self performSelector:@selector(stopUVSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopUVSensor {
    NSLog(@"Stop UV Sensor");
    [self.client.sensorManager stopUVUpdatesErrorRef:nil];
}


////////////////////////////////////////////////
////////////////////////////////////////////////


- (void) startBatteryGaugeSensor {
//    AWARESensor * batteryGaugeSensor = [[AWARESensor alloc] initWithSensorName:PLUGIN_MSBAND_SENSORS_BATTERYGAUGE  withAwareStudy:awareStudy];
}



/////////////////////////////////////////////////
////////////////////////////////////////////////


- (void) startSkinTempSensor:(NSDictionary *) setting {
    NSLog(@"Start Skin Teamperature Sensor");
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    void (^skinHandler)(MSBSensorSkinTemperatureData *, NSError *) = ^(MSBSensorSkinTemperatureData *skinData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %.2f", skinData.temperature];
        if ([self isDebug]) {
            NSLog(@"Skin: %@",data);
        }
        if ([self isDebug]) {
            [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"Skin: %@", data] soundFlag:NO];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandSkinTemp * data = (EntityMSBandSkinTemp *)[NSEntityDescription insertNewObjectForEntityForName:[skinTempSensor getEntityName]
                                                                                    inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.skintemp = @(skinData.temperature);
            
            [skinTempSensor saveDataToDB];
        });
        
//        NSNumber* unixtime = [self getUnixTime]; //[NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithDouble:skinData.temperature] forKey:@"skintemp"];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [skinTempSensor setLatestValue:data];
//            [skinTempSensor saveData:dic];
//        });

    };
    NSError *stateError;
    if (![self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:&stateError withHandler:skinHandler]) {
        // NSLog(@"Skin sensor is failed: %@", stateError.description);
//        if(reconnCountSkinTemp < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect Skin Temp sensor (%d) : %@", reconnCountSkinTemp, stateError.description);
//            [self performSelector:@selector(startSkinTempSensor:) withObject:setting afterDelay:1];
//            reconnCountSkinTemp++;
//        }else{
//            NSLog(@"[ERROR] Skin Temp sensor connection is failed: %@", stateError.description);
//            reconnCountSkinTemp = 0;
//        }
    }else{
        [self performSelector:@selector(stopSkinTempSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopSkinTempSensor{
    NSLog(@"Stop Skin Temp Sensor");
    [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
}

/////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////

- (void) startPedometerSensor:(NSDictionary *) setting {
    NSLog(@"Start Pedometer Sensor");
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    NSError * error = nil;
    void (^pedometerHandler)(MSBSensorPedometerData *, NSError *) = ^(MSBSensorPedometerData *pedometerData, NSError *error){
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandPedometer * data = (EntityMSBandPedometer *)[NSEntityDescription insertNewObjectForEntityForName:[pedometerSensor getEntityName]
                                                                                    inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.pedometer = @(pedometerData.totalSteps);
            
            [pedometerSensor saveDataToDB];
        });
        
//        NSNumber* unixtime = [self getUnixTime];
//        NSMutableDictionary * dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:[NSNumber numberWithInt:pedometerData.totalSteps] forKey:@"pedometer"];
//        
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [pedometerSensor saveData:dic];
//        });
    };
    
    if(![self.client.sensorManager startPedometerUpdatesToQueue:nil errorRef:&error withHandler:pedometerHandler]){
        // NSLog(@"Pedometer is failed: %@", error.description);
//        if(reconnCountPedometer < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect Pedometer sensor (%d) : %@", reconnCountPedometer, error.description);
//            [self performSelector:@selector(startPedometerSensor:) withObject:setting afterDelay:1];
//            reconnCountPedometer++;
//        }else{
//            NSLog(@"[ERROR] Pedometer sensor connection is failed: %@", error.description);
//            reconnCountPedometer  = 0;
//        }
    }else{
        [self performSelector:@selector(stopPedometerSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopPedometerSensor {
    NSLog(@"Stop Pedometer Sensor");
    [self.client.sensorManager stopPedometerUpdatesErrorRef:nil];
}

///////////////////////////////////////////////
///////////////////////////////////////////////

- (void) startDevicecontactSensor:(NSDictionary *) setting{
    
    NSLog(@"Start Device Contact Sensor");
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandDeviceContact * data = (EntityMSBandDeviceContact *)[NSEntityDescription insertNewObjectForEntityForName:[deviceContactSensor getEntityName]
                                                                                    inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.devicecontact = wornState;
            
            [deviceContactSensor saveDataToDB];
    
        });
        
        
//        NSNumber* unixtime = [self getUnixTime]; //[NSNumber numberWithDouble:timeStamp];
//        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//        [dic setObject:unixtime forKey:@"timestamp"];
//        [dic setObject:[self getDeviceId] forKey:@"device_id"];
//        [dic setObject:wornState forKey:@"devicecontact"];
//        
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [deviceContactSensor saveData:dic];
//        });
    };
    
    NSError * error = nil;
    if(![self.client.sensorManager startBandContactUpdatesToQueue:nil errorRef:&error withHandler:bandHandler]){
        // NSLog(@"ERROR: device contact sensor is failed: %@",error.description);
//        if(reconnCountDeviceContact < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect device contact sensor (%d) : %@", reconnCountDeviceContact, error.description);
//            [self performSelector:@selector(startDevicecontactSensor:) withObject:setting afterDelay:1];
//            reconnCountDeviceContact++;
//        }else{
//            NSLog(@"[ERROR] Device Contact sensor connection is failed: %@", error.description);
//            reconnCountDeviceContact = 0;
//        }
    }else{
        [self performSelector:@selector(stopDeviceContactSensor) withObject:nil afterDelay:activeTimeInSec];
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

- (void) stopDeviceContactSensor{
    NSLog(@"Stop Device Contact Sensor");
    [self.client.sensorManager stopBandContactUpdatesErrorRef:nil];
}


///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
- (void) startRRIntervalSensor:(NSDictionary *) setting {
    NSLog(@"Start RRInterval Sensor");
    
    double activeTimeInSec = 2*60;
    if(setting != nil){
        activeTimeInSec = [[setting objectForKey:PLUGIN_MSBAND_KEY_ACTIVE_IN_MINUTE] doubleValue];
    }
    
    void (^handler)(MSBSensorRRIntervalData *, NSError *) = ^(MSBSensorRRIntervalData *rrIntervalData, NSError *error)
    {
        // [weakSelf output:[NSString stringWithFormat:@" interval (s): %.2f", rrIntervalData.interval]];
        if ([self isDebug]) {
            NSLog(@"RRInterval: %.2f", rrIntervalData.interval);
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            EntityMSBandRRInterval * data = (EntityMSBandRRInterval *)[NSEntityDescription insertNewObjectForEntityForName:[rrIntervalSensor getEntityName]
                                                                                                          inManagedObjectContext:delegate.managedObjectContext];
            data.device_id = [self getDeviceId];
            data.timestamp = [self getUnixTime];
            data.rrinterval =  @(rrIntervalData.interval);
            
            [deviceContactSensor saveDataToDB];
        });
        
        
    };
    
    NSError * stateError = nil;
    if (![self.client.sensorManager startRRIntervalUpdatesToQueue:nil errorRef:&stateError withHandler:handler]){
        // NSLog(@"ERROR: RRInterval sensor's connection is failed: %@", stateError.description);
//        if(reconnCountRRInterval < reconnectionLimit){
//            NSLog(@"[ERROR] Retry to connect RRInterval sensor (%d) : %@", reconnCountRRInterval, stateError.description);
//            [self performSelector:@selector(startRRIntervalSensor:) withObject:setting afterDelay:1];
//            reconnCountRRInterval++;
//        }else{
//            NSLog(@"[ERROR] RRInterval sensor connection is failed: %@", stateError.description);
//            reconnCountRRInterval = 0;
//        }
        return;
    }else{
        [self performSelector:@selector(stopRRIntervalSensor) withObject:nil afterDelay:activeTimeInSec];
    }
}

- (void) createRRIntervalTable {
    NSString * query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "rrinterval double default 0,"
    "UNIQUE (timestamp,device_id)";
    [rrIntervalSensor createTable:query];
}

- (void) stopRRIntervalSensor{
    NSLog(@"Stop RRInterval Sensor");
    [self.client.sensorManager stopRRIntervalUpdatesErrorRef:nil];
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

// - (void) stopMSBSensors {
//    NSString * msg = @"Stop all sensors on the MS Band.";
//    NSLog(@"%@", msg);
//    if ([self isDebug]) {
//        [AWAREUtils sendLocalNotificationForMessage:msg soundFlag:NO];
//    }
//    @try {
//        NSArray * allSensors = [super getSensors];
//        for (int i=0; i<allSensors.count; i++) {
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3.0 * i * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
//                NSLog(@"Stop %@ sensor", [[allSensors objectAtIndex:i] getSensorName]);
//                switch (i) {
//                    case 0:
//                        [self.client.sensorManager stopUVUpdatesErrorRef:nil];
//                        break;
//                    case 1:
//                        [self.client.sensorManager stopSkinTempUpdatesErrorRef:nil];
//                        break;
//                    case 2:
//                        [self.client.sensorManager stopHeartRateUpdatesErrorRef:nil];
//                        break;
//                    case 3:
//                        [self.client.sensorManager stopGSRUpdatesErrorRef:nil];
//                        break;
//                    case 4:
//                        [self.client.sensorManager stopBandContactUpdatesErrorRef:nil];
//                        break;
//                    case 5:
//                        [self.client.sensorManager stopCaloriesUpdatesErrorRef:nil];
//                        break;
//                    case 6:
//                        [self.client.sensorManager stopDistanceUpdatesErrorRef:nil];
//                        break;
//                    case 7:
//                        [self.client.sensorManager stopRRIntervalUpdatesErrorRef:nil];
//                        break;
//                    default:
//                        break;
//                }
//
//                // -- not implemented yet--
//                //        [self.client.sensorManager stopAccelerometerUpdatesErrorRef:nil];
//                //        [self.client.sensorManager stopAltimeterUpdatesErrorRef:nil];
//                //        [self.client.sensorManager stopAmbientLightUpdatesErrorRef:nil];
//                //        [self.client.sensorManager stopGyroscopeUpdatesErrorRef:nil];
//                //        [self.client.sensorManager stopPedometerUpdatesErrorRef:nil];
//            });
//        }
//    } @catch (NSException *exception) {
//        NSLog(@"%@", exception.description);
//    } @finally {
//
//    }
// }


@end