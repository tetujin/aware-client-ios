//
//  AWAREDataUploader.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/7/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LocalFileStorageHelper.h"
#import "AWAREStudy.h"

@interface AWAREDataUploader : NSData <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

//- (instancetype) initWithLocalStorage:(LocalFileStorageHelper *)localStorage;
- (instancetype) initWithLocalStorage:(LocalFileStorageHelper *)localStorage withAwareStudy:(AWAREStudy *) study;

- (bool) isUploading;
- (void) setUploadingState:(bool)state;
- (void) lockBackgroundUpload;
- (void) unlockBackgroundUpload;

- (void) allowsCellularAccess;
- (void) forbidCellularAccess;
- (void) allowsDateUploadWithoutBatteryCharging;
- (void) forbidDatauploadWithoutBatteryCharging;

/**
 * Background data upload
 */
- (void) syncAwareDB;
- (void) syncAwareDBWithSensorName:(NSString*) name;
- (void) postSensorDataWithSensorName:(NSString*) name session:(NSURLSession *)oursession;

/**
 * Foreground data upload
 */
- (BOOL) syncAwareDBInForeground;
- (BOOL) syncAwareDBInForegroundWithSensorName:(NSString*) name;
//- (void) postSensorDataForegroundWithSensorName:(NSString* )name;

/**
 * Sync with AWARE database
 */
- (BOOL) syncAwareDBWithData:(NSDictionary *) dictionary;

/**
 * Get progress
 */
- (NSString *) getSyncProgressAsText;
- (NSString *) getSyncProgressAsText:(NSString *)sensorName;
// - (NSString *) getFileStrSize:(double)size;

/**
 * Create Table Methods
 */
- (void) createTable:(NSString*) query;
- (void) createTable:(NSString *)query withTableName:(NSString*) tableName;
- (BOOL) clearTable;

/**
 * Return current network condition with a text
 */
- (NSString *) getNetworkReachabilityAsText;

/**
 * Set Debug Sensor
 */
//- (bool) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label;
- (void) trackDebugEventsWithDebugSensor:(Debug*)debug;

/**
 * AWARE URL makers
 */
- (NSString *) getWebserviceUrl;
- (NSString *) getInsertUrl:(NSString *)sensorName;
- (NSString *) getLatestDataUrl:(NSString *)sensorName;
- (NSString *) getCreateTableUrl:(NSString *)sensorName;
- (NSString *) getClearTableUrl:(NSString *)sensorName;


@end
