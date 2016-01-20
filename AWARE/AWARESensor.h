//
//  AWARESensorViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <Foundation/Foundation.h>
//#import <DeployGateSDK/DeployGateSDK.h>

//#define NSLog DGSLog

@protocol AWARESensorDelegate <NSObject>
//- (BOOL) startSensor:(double) interval withUploadInterval:(double)upInterval;
- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) stopSensor;
@end

@interface AWARESensor : NSObject <AWARESensorDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

- (instancetype) initWithSensorName:(NSString *) sensorName;

@property (strong, nonatomic) NSString * syncDataQueryIdentifier;
@property (strong, nonatomic) NSString * createTableQueryIdentifier;

- (void) setBufferLimit:(int) limit;
- (void) startWriteAbleTimer;
- (void) stopWriteableTimer;
- (void) setLatestValue:(NSString *) valueStr;
- (NSString *) getLatestValue;
- (NSString *) getDeviceId;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString*) sensorName;
- (NSString *) getClearTableUrl:(NSString*) sensorName;
- (BOOL) getDebugState;
- (bool) saveData:(NSDictionary *) data;
- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;
- (bool) saveDataWithArray:(NSArray*) array;
- (void) syncAwareDB;
- (void) syncAwareDBWithSensorName:(NSString*) sensorName;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;
- (NSString *) getLatestSensorData:(NSString*)deviceId withUrl:(NSString*) url;
- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (void) createTable:(NSString *)query;
- (BOOL) clearTable;
- (void) setSensorName:(NSString *) sensorName;
- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;
- (NSString *) getSensorName;

- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;

@end
