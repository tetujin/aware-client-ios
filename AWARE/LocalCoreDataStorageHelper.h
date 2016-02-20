//
//  LocalCoreDataStorageHelper.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/18/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "Debug.h"

@interface LocalCoreDataStorageHelper : NSData

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (instancetype) initWithStorageName:(NSString *) storageName;

/// create file
- (BOOL) createNewFile:(NSString*)fileName;

/// clear file
- (bool) clearFile:(NSString *) fileName;

/// save data
- (bool) saveDataWithArray:(NSArray*) array;
- (bool) saveData:(NSDictionary *)data;
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName;
- (BOOL) appendLine:(NSString *)line;

// get sensor data
- (NSMutableString *) getSensorDataForPost;
- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText;
- (NSInteger) getMaxDateLength;
- (uint64_t) getFileSize;
- (uint64_t) getFileSizeWithName:(NSString*) name;

// set and get mark
- (void) setNextMark;
- (void) restMark;
- (int)  getMarker;

// set and get a losted text length
- (int) getLostedTextLength;
- (void) setLostedTextLength:(int)lostedTextLength;

// set debug tracker
- (void) trackDebugEventsWithDebugSensor:(Debug*)debug;

// get sensor storage name and path
- (NSString *) getSensorName;
- (NSString *) getFilePath;

// set buffer and db lock
- (void) setBufferSize:(int) size;
- (void)dbLock;
- (void)dbUnlock;

@end
