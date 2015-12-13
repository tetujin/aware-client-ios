//
//  MSBand.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/8/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "MSBand.h"

@implementation MSBand{
    NSTimer* uploadTimer;
    NSTimer* sensingTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
    }
    return self;
}

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


/** 
 * AWARESensor Delegate
 */
- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start MSBand Sensor!");
    
    //    // Setup View
    //    [self markSampleReady:NO];
    // Setup Band
    [MSBClientManager sharedManager].delegate = self;
    NSArray	*clients = [[MSBClientManager sharedManager] attachedClients];
    self.client = [clients firstObject];
    if (self.client == nil) {
        NSLog(@"Failed! No Bands attached.");
        return NO;
    }
    [[MSBClientManager sharedManager] connectClient:self.client];
    NSLog(@"%@",[NSString stringWithFormat:@"Please wait. Connecting to Band <%@>", self.client.name]);
    
    [self performSelector:@selector(startMSBSensors) withObject:0 afterDelay:5];
    
    return YES;
}





- (void)startMSBSensors{
    /**
     * Initialize sensor on MSBand.
     */
    NSLog(@"Set an Accelerometer Sensor!");
    void (^accelerometerHandler)(MSBSensorAccelerometerData *, NSError *) = ^(MSBSensorAccelerometerData *accelerometerData, NSError *error){
        NSString* data = [NSString stringWithFormat:@"X = %5.2f Y = %5.2f Z = %5.2f",
                          accelerometerData.x,
                          accelerometerData.y,
                          accelerometerData.z];
//        NSLog(@"%@",data);
    };
    
    NSLog(@"Set an Altimeter Sensor!");
    void (^altimeterHandler)(MSBSensorAltimeterData *, NSError *) = ^(MSBSensorAltimeterData *altimeterData, NSError *error){
        NSString* data  = [NSString stringWithFormat:
                                        @"Elevation gained by stepping (cm)   : %u\n"
                                        @"Elevation gained by other means (cm): %u\n",
                                        (unsigned int)altimeterData.steppingGain,
                                        (unsigned int)(altimeterData.totalGain - altimeterData.steppingGain)];
//        NSLog(@"Altimeter: %@",data);
    };
    
    NSLog(@"Set an AmbientLight Sensor!");
    void (^ambientLightHandler)(MSBSensorAmbientLightData *, NSError *) = ^(MSBSensorAmbientLightData *ambientLightData, NSError *error){
        NSString* data = [NSString stringWithFormat:@"AmbientLight: %5d lx", ambientLightData.brightness];
//        NSLog(@"Ambient: %@",data);
    };
    
    NSLog(@"Set a Barometer Sensor!");
    void (^barometerHandler)(MSBSensorBarometerData *, NSError *) = ^(MSBSensorBarometerData *barometerData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%5.2f hPa, %2.1f°C", barometerData.airPressure, barometerData.temperature];
//        NSLog(@"Barometer: %@",data);
    };
    
    NSLog(@"Set a Cal sensor!");
    void (^calHandler)(MSBSensorCaloriesData *, NSError *) = ^(MSBSensorCaloriesData *calData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", calData.calories];
//        NSLog(@"Cal: %@",data);
    };
    
    NSLog(@"Set a Distance Sensor!");
    void (^distanceHandler)(MSBSensorDistanceData *, NSError *) = ^(MSBSensorDistanceData *distanceData, NSError *error) {
        NSString* data =[NSString stringWithFormat:@"%ld", distanceData.totalDistance];
//        @property (nonatomic, readonly) NSUInteger totalDistance;
//        @property (nonatomic, readonly) double speed;
//        @property (nonatomic, readonly) double pace;
//        @property (nonatomic, readonly) MSBSensorMotionType motionType;
//        NSLog(@"Distance: %@",data);
    };
    
    
    NSLog(@"Set a GSR Sensor!");
    void (^gsrHandler)(MSBSensorGSRData *, NSError *error) = ^(MSBSensorGSRData *gsrData, NSError *error){
        NSString *data = [NSString stringWithFormat:@"%8u kOhm", (unsigned int)gsrData.resistance];
//        NSLog(@"GSR: %@",data);
    };
    
    NSLog(@"Set a Gyro Sensor!");
    void (^gyroHandler)(MSBSensorGyroscopeData *, NSError *) = ^(MSBSensorGyroscopeData *gyroData, NSError *error) {
        NSString *data = [NSString stringWithFormat:@"%f, %f, %f", gyroData.x, gyroData.y, gyroData.z];
//        NSLog(@"%@",data);
    };
    

    
    NSLog(@"Set a HeartRate Sensor!");
    [self.client.sensorManager requestHRUserConsentWithCompletion:^(BOOL userConsent, NSError *error) {
        if (userConsent) {
            void (^hrHandler)(MSBSensorHeartRateData *, NSError *) = ^(MSBSensorHeartRateData *heartRateData, NSError *error) {
                NSString * data = [NSString stringWithFormat:@"Heart Rate: %3u %@",
                                   (unsigned int)heartRateData.heartRate,
                                   heartRateData.quality == MSBSensorHeartRateQualityAcquiring ? @"Acquiring" : @"Locked"];
//                NSLog(@"HR: %@", data);
            };
            NSError *stateError;
            if (![self.client.sensorManager startHeartRateUpdatesToQueue:nil errorRef:&stateError withHandler:hrHandler]) {
                NSLog(@"HR sensor is faild: %@", stateError.description);
            }
        } else{
            NSLog(@"User consent declined.");
        }
    }];
    
    
//    NSLog(@"Set a PR Interval Sensor!");
//    void (^prHandler)(MSBSensorRRIntervalData *, NSError *) = ^(MSBSensorRRIntervalData *prIntervalData, NSError *error){
//        NSString *data = [NSString stringWithFormat:@" interval (s): %.2f", prIntervalData.interval];
//        NSLog(@"%@",data);
//    };
    
    NSLog(@"Set a Skin Teamperature Sensor!");
    void (^skinHandler)(MSBSensorSkinTemperatureData *, NSError *) = ^(MSBSensorSkinTemperatureData *skinData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %.2f", skinData.temperature];
//        NSLog(@"Skin: %@",data);
    };
    
    NSLog(@"Set a UV sensor!");
    void (^uvHandler)(MSBSensorUVData *, NSError *) = ^(MSBSensorUVData *uvData,  NSError *error){
        NSString *data = [NSString stringWithFormat:@" interval (s): %ld", uvData.uvIndexLevel];
//        NSLog(@"UV: %@",data);
    };
    
    
    
    
    /**
     * Start sensors on MSBand.
     */
    NSError *stateError;
//    //Start accelerometer sensor on a MSBand.
    if (![self.client.sensorManager startAccelerometerUpdatesToQueue:nil errorRef:&stateError withHandler:accelerometerHandler]) {
        NSLog(@"Accelerometer is faild: %@", stateError.description);
    }
    
    //Start altieter sensor on a MSBand.
    if (![self.client.sensorManager startAltimeterUpdatesToQueue:nil errorRef:&stateError withHandler:altimeterHandler]){
        NSLog(@"Altimeter sensor is faild: %@", stateError.description);
    }
    
    //Start ambient light sensor
    if (![self.client.sensorManager startAmbientLightUpdatesToQueue:nil errorRef:&stateError withHandler:ambientLightHandler]) {
        NSLog(@"Ambient light sensor is faild: %@", stateError.description);
    }
    
    //start barometer sensor
    if (![self.client.sensorManager startBarometerUpdatesToQueue:nil errorRef:&stateError withHandler:barometerHandler]) {
        NSLog(@"Barometer sensor is faild: %@", stateError.description);
    }
    
//    NSLog(@"Set a Cal sensor!");
    if (![self.client.sensorManager startCaloriesUpdatesToQueue:nil errorRef:&stateError withHandler:calHandler]) {
        NSLog(@"Cal sensor is faild: %@", stateError.description);
    }
    
//    NSLog(@"Set a Distance Sensor!");
    if (![self.client.sensorManager startDistanceUpdatesToQueue:nil errorRef:&stateError withHandler:distanceHandler]) {
        NSLog(@"Distance sensor is faild: %@", stateError.description);
    }
    
//    NSLog(@"Set a GSR Sensor!");
    if (![self.client.sensorManager startGSRUpdatesToQueue:nil errorRef:&stateError withHandler:gsrHandler]) {
        NSLog(@"GSE sensor is faild: %@", stateError.description);
    }
    
//    NSLog(@"Set a Gyro Sensor!");
    if (![self.client.sensorManager startGyroscopeUpdatesToQueue:nil errorRef:&stateError withHandler:gyroHandler]) {
        NSLog(@"Gyro sensor is faild: %@", stateError.description);
    }
    
//    NSLog(@"Set a Skin Teamperature Sensor!");
    if (![self.client.sensorManager startSkinTempUpdatesToQueue:nil errorRef:&stateError withHandler:skinHandler]) {
        NSLog(@"Skin sensor is faild: %@");
    }
    
//    NSLog(@"Set a UV sensor!");
    if (![self.client.sensorManager startUVUpdatesToQueue:nil errorRef:&stateError withHandler:uvHandler]) {
        NSLog(@"UV sensor is faild: %@");
    }
}

- (void) stopMSBSensors {
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

@end