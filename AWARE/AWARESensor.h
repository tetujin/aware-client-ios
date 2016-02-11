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
#import "AWAREUtils.h"

@protocol AWARESensorDelegate <NSObject>
- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) stopSensor;
- (void) syncAwareDB;
@end

@interface AWARESensor : NSObject <AWARESensorDelegate, UIAlertViewDelegate>

- (instancetype) initWithSensorName:(NSString *) sensorName;

- (void) sensorLock;
- (void) sensorUnLock;

// for storing debug events
- (void) trackDebugEvents;
- (bool) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;

// for manual data upload
- (NSString *) getNetworkReachabilityAsText;
- (bool) isUploading;

// store data
- (void) startWriteAbleTimer;
- (void) stopWriteableTimer;
- (void) syncAwareDB;
- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;


- (void) setLatestValue:(NSString *) valueStr;
- (NSString *) getLatestValue;
- (NSString *) getDeviceId;

- (BOOL) getDebugState;
- (bool) saveData:(NSDictionary *) data;
- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;
- (bool) saveDataWithArray:(NSArray*) array;

- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString*) sensorName;
//- (NSString *) getLatestSensorData:(NSString*)deviceId withUrl:(NSString*) url;
- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;


- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (void) createTable:(NSString *)query;
- (BOOL) clearTable;


//- (void) setSensorName:(NSString *) sensorName;
- (NSString *) getSensorName;
- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;
- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;

@end
