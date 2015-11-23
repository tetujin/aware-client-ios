//
//  AWARESensorViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/19/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MagicalRecord/MagicalRecord.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import "FMDatabase.h" // - Represents a single SQLite database. Used for executing SQL statements.
#import "FMResultSet.h"  //- Represents the results of executing a query on an FMDatabase.
#import "FMDatabaseQueue.h"

@protocol AWARESensorDelegate <NSObject>
//- (BOOL) startSensor:(double) interval withUploadInterval:(double)upInterval;
- (BOOL) startSensor:(double)upInterval withSettings:(NSArray *)settings;
- (BOOL) stopSensor;
- (void) uploadSensorData;
@end

@interface AWARESensor : NSObject <AWARESensorDelegate>



- (instancetype) initWithSensorName:(NSString *) sensorName;

- (void) setBufferLimit:(int) limit;

-(void) setLatestValue:(NSString *) valueStr;

-(NSString *) getLatestValue;

-(NSString *) getDeviceId;

// get generate URL for insert
- (NSString *) getInsertUrl:(NSString *)sensorName;

// get latest sensor data URL
- (NSString *) getLatestDataUrl:(NSString *)sensorName;

// get create table URL
- (NSString *) getCreateTableUrl:(NSString*) sensorName;

// get clear table URL
- (NSString *) getClearTableUrl:(NSString*) sensorName;

- (NSString *) saveData:(NSDictionary*)data toLocalFile:(NSString*)fileName;

- (NSString *) getData:(NSString*)fileName withJsonArrayFormat:(bool)jsonArrayFormat;

// insert sensor data
- (BOOL) insertSensorData:(NSString*)data withDeviceId:(NSString*)deviceId url:(NSString*)url;

// get latest sensor data -> for debug
- (NSString *) getLatestSensorData:(NSString*)deviceId withUrl:(NSString*) url;

- (double) getSensorSetting:(NSArray *)settings withKey:(NSString *)key;

// create new table in the database
- (BOOL) createTable:(NSString *)data withDeviceId:(NSString *)deviceId withUrl:(NSString *)url;

// clear the table in the database
- (BOOL) clearTable:(NSString *)data withDeviceId:(NSString *)deviceId withUrl:(NSString*)url;

- (void) setSensorName:(NSString *) sensorName;

- (double) convertMotionSensorFrequecyFromAndroid:(double)frequency;

- (NSString *) getSensorName;

@end
