//
//  SensorDataManager.h
//  Sapplication-Client
//
//  Created by Yuuki Nishiyama on 10/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreMotion/CoreMotion.h>
//#import <MQTTClient/MQTTClient.h>

@interface SensorDataManager : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate >
{
//    NSMutableData *responseData;
}

extern const NSString *UNIXTIME;
extern const NSString *UID;
extern const NSString *AVE_ACC_X;
extern const NSString *AVE_ACC_Y;
extern const NSString *AVE_ACC_Z;
extern const NSString *AVE_ACC_COMP;
extern const NSString *AVE_GYRO_X;
extern const NSString *AVE_GYRO_Y;
extern const NSString *AVE_GYRO_Z;
extern const NSString *AVE_GYRO_COMP;
extern const NSString *AVE_MAG_X;
extern const NSString *AVE_MAG_Y;
extern const NSString *AVE_MAG_Z;
extern const NSString *AVE_MAG_COMP;
extern const NSString *LAT;
extern const NSString *LON;
extern const NSString *ALT;
extern const NSString *H_ACCURACY;
extern const NSString *V_ACCURACY;
extern const NSString *SPEED;
extern const NSString *COURCE;
extern const NSString *MOTION_TYPE;
extern const NSString *AIR_PRESSURE;
extern const NSString *ALT_FROM_AIR_PRESSURE;
extern const NSString *PROXIMIITY;
extern const NSString *DEVICE_ORIENTATION;
extern const NSString *SCREEN_BRIGHTNESS;
extern const NSString *BATTERY;
extern const NSString *NETWORK_TYPE;
extern const NSString *HEADING;
extern const NSString *UUID;
extern const NSString *APP_STATE;
extern const NSString *DATE;
extern const NSString *TIME;


//"\"dispAccX\":%f, \"dispAccY\":%f, \"dispAccZ\":%f, \"dispAccComp\":%f, "
//"\"dispGyroX\":%f, \"dispGyroY\":%f, \"dispGyroZ\":%f, \"dispGyroComp\":%f, "
//"\"dispMagX\":%f, \"dispMagY\":%f, \"dispMagZ:%f, \"dispMagComp\":%f, "
//"\"rmsAccX\":%f, \"rmsAccY\":%f, \"rmsAccZ\":%f, \"rmsAccComp\":%f, "
//"\"rmsGyroX\":%f, \"rmsGyroY\":%f, \"rmsGyroZ\":%f, \"rmsGyroComp\":%f, "
//"\"rmsMagX\":%f, \"rmsMagY\":%f, \"rmsMagZ\":%f, \"rmsMagComp\":%f, "


- (id) initWithDBPath:(NSString *)dbPath userID:(NSString *) uid;

// each sensed timing
- (void) addSensorDataAccx:(double)accx accy:(double)accy accz:(double)accz; //buffer
- (void) addSensorDataGyrox:(double)gyrox gyroy:(double)gyroy gyroz:(double)gyroz; //buffer
- (void) addSensorDataMagx:(double)magx magy:(double)magy magz:(double)magz; //buffer
- (void) addLocation: (CLLocation *)location;
- (void) addDeviceMotion: (CMDeviceMotion *) deviceMotion;
- (void) addMotionActivity: (CMMotionActivity *) motionActivity;
- (void) addPedometerData: (CMPedometerData *) pedometerData;
- (void) addAltitudeDaat: (CMAltitudeData * )altitudeData;
- (void) addDeviceOrientation: (int) orientation;
- (void) addBrightness: (double) brightness;
- (void) addBattery: (double)batteryLevel;
- (void) addNetwork: (NSString *) network;
- (void) addHeading: (double) headingValue;
//- (void) addVisit: (CLVisit *) visitData; //-> how to manage event type data

- (void) updateUserInfoWithUID: (NSString *) uid;

// every 1 sec.
- (void) saveAllSensorDataToDBWithBufferClean:(bool)state;

// every 1 min.
- (bool) uploadSensorDataWithURL:(NSString*)url;

// every 1 min.
- (bool) uploadPedDataToDBWithURL:(NSString*)url dbClean:(bool)state;

@end
