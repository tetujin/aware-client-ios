//
//  LocalTextStorageHelper.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Debug.h"

@interface LocalFileStorageHelper : NSObject

- (instancetype) initWithStorageName:(NSString *) storageName;

- (NSString *) getSensorName;

//// save data
- (bool) saveDataWithArray:(NSArray*) array;

// save data
- (bool) saveData:(NSDictionary *)data;

// save data with local file
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName;


- (BOOL) appendLine:(NSString *)line;
/** create new file */
-(BOOL)createNewFile:(NSString*) fileName;


- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText;

/** clear file */
- (bool) clearFile:(NSString *) fileName;
- (NSInteger) getMaxDateLength;
- (NSMutableString *) getSensorDataForPost;


- (uint64_t) getFileSize;
- (uint64_t) getFileSizeWithName:(NSString*) name;

/**
 * Makers
 */
- (int) getMarker;
- (void) setMarker:(int) intMarker;

/**
 * text legnth
 */
- (int) getLostedTextLength;
- (void) setLostedTextLength:(int)lostedTextLength;

/**
 * Set Debug Sensor
 */
- (void) trackDebugEventsWithDebugSensor:(Debug*)debug;

/**
 * A File access balancer
 */
//- (void) startWriteAbleTimer;
//- (void) stopWriteableTimer;

- (void) setBufferSize:(int) size;

- (NSString *) getFilePath;


- (void)dbLock;
- (void)dbUnlock;

@end
