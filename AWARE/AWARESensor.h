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
#import "AWAREStudy.h"

@protocol AWARESensorDelegate <NSObject>
- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) stopSensor;
- (void) syncAwareDB;
- (void) createTable;
- (void) changedBatteryState;
- (void) calledBackgroundFetch;

- (NSString *) getSensorName;

@end

@interface AWARESensor : NSObject <AWARESensorDelegate, UIAlertViewDelegate>

- (instancetype) initWithSensorName:(NSString *) sensorName withAwareStudy:(AWAREStudy *) study;

// save debug events
- (void) trackDebugEvents;
- (bool) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;

// get condition
- (NSString *) getNetworkReachabilityAsText;
- (NSString *) getLatestValue;
- (NSString *) getDeviceId;
- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;
- (bool) isUploading;

// create table
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (void) createTable:(NSString *)query;

// clear table
- (BOOL) clearTable;

// store data
- (void) setBufferSize:(int)size;
- (bool) isDebug;
- (bool) saveData:(NSDictionary *) data;
- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;
- (bool) saveDataWithArray:(NSArray*) array;
- (void) setLatestValue:(NSString *) valueStr;

// sync data
- (void) syncAwareDB;
- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;

// show progress of uploading
- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString*) sensorName;

// lock
- (void) sensorLock;
- (void) sensorUnLock;



// Utils
- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;
- (void) sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;


// url
- (NSString *) getWebserviceUrl;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString *)sensorName;
- (NSString *) getClearTableUrl:(NSString *)sensorName;

@end
