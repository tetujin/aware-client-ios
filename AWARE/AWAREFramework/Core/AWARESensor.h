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
#import "AWAREKeys.h"
#import "AWARECoreDataManager.h"
#import "TCQMaker.h"


typedef enum: NSInteger {
    AwareDBTypeUnknown  = 0,
    AwareDBTypeTextFile = 1,
    AwareDBTypeCoreData = 2
} AwareDBType;



@protocol AWARESensorDelegate <NSObject>

- (BOOL) startSensorWithSettings:(NSArray *)settings;
- (BOOL) startSensor;
- (BOOL) stopSensor;
- (void) syncAwareDB;
- (void) createTable;
- (void) changedBatteryState;
- (void) calledBackgroundFetch;
- (void) saveDummyData;

- (NSString *) getSensorName;
- (NSString *) getEntityName;
- (NSInteger) getDBType;

@end


@interface AWARESensor : AWARECoreDataManager <AWARESensorDelegate, UIAlertViewDelegate>

// - (instancetype) initWithAwareStudy:(AWAREStudy *) study;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name dbEntityName:(NSString *)entity;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name dbEntityName:(NSString *)entity dbType:(AwareDBType)dbType;
- (instancetype) initWithAwareStudy:(AWAREStudy *) study sensorName:(NSString *)name dbEntityName:(NSString *)entity dbType:(AwareDBType)dbType bufferSize:(int)buffer;

// save debug events
- (void) trackDebugEvents;
- (bool) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;

// get condition
- (NSString *) getNetworkReachabilityAsText;

- (void) setLatestValue:(NSString *) valueStr;
- (NSString *) getLatestValue;

- (void) setLatestData:(NSDictionary *)dict;
- (NSDictionary *) getLatestData;

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
- (void) setFetchLimit:(int)limit;
- (void) setFetchBatchSize:(int)size;

- (int) getFetchLimit;
- (int) getFetchBatchSize;
- (int) getBufferSize;

- (void) setDataStoring:(BOOL)state;
- (void) startDataStoring;
- (void) stopDataStoring;
- (bool) isDataStoring;

- (bool) isDebug;
- (bool) saveData:(NSDictionary *) data;
- (bool) saveData:(NSDictionary *) data toLocalFile:(NSString*) fileName;
- (bool) saveDataWithArray:(NSArray*) array;
- (bool) saveDataToDB;

- (void) saveDummyData;

// sync data
- (void) syncAwareDB;
- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;

// sync options
- (void) allowsCellularAccess;
- (void) forbidCellularAccess;
- (void) allowsDateUploadWithoutBatteryCharging;
- (void) forbidDatauploadWithoutBatteryCharging;

// show progress of uploading
- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString*) sensorName;

// lock
- (void) lockDB;
- (void) unlockDB;
- (BOOL) isDBLock;

// Utils
- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;
- (void) sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag;


// url
- (NSString *) getWebserviceUrl;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString *)sensorName;
- (NSString *) getClearTableUrl:(NSString *)sensorName;

- (NSManagedObjectContext *) getSensorManagedObjectContext;

- (BOOL) getStatus;

@end
