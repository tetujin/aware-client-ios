//
//  LocalTextStorageHelper.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "LocalFileStorageHelper.h"
#import "AWAREKeys.h"

@implementation LocalFileStorageHelper {

    NSString * KEY_SENSOR_UPLOAD_MARK;
    NSString * KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH;
    
    uint64_t fileSize;
    NSString * sensorName;
    
    bool writeAble;
    NSMutableString *bufferStr;
    
    NSTimer* writeAbleTimer;
    
    Debug * debugSensor;
    
    bool isLock;
}

- (instancetype)initWithStorageName:(NSString *)name{
    if (self = [super init]) {
        isLock = NO;
        sensorName = name;
        KEY_SENSOR_UPLOAD_MARK = [NSString stringWithFormat:@"key_sensor_upload_mark_%@", sensorName];
        KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH = [NSString stringWithFormat:@"key_sensor_upload_losted_text_length_%@", sensorName];
        bufferStr = [[NSMutableString alloc] init];
        writeAble = YES;
        [self createNewFile:sensorName];
    }
    return self;
}



- (void)dbLock{
    isLock = YES;
}

- (void)dbUnlock{
    isLock = NO;
}


- (NSString *) getSensorName {
    if (sensorName == nil) {
        return @"";
    }
    return sensorName;
}


//// save data
- (bool) saveDataWithArray:(NSArray*) array {
    if (array !=nil) {
        return false;
    }
    bool result = false;
    for (NSDictionary *dic in array) {
        result = [self saveData:dic];
    }
    return result;
}


// save data
- (bool) saveData:(NSDictionary *)data{
    return [self saveData:data toLocalFile:[self getSensorName]];
}

// save data with local file
- (bool) saveData:(NSDictionary *)data toLocalFile:(NSString *)fileName{
    
    if (isLock) {
        NSLog(@"[%@] This sensor is Locked now!", [self getSensorName]);
        return NO;
    }
    
    NSError*error=nil;
    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
    NSString* jsonstr = [[NSString alloc] init];
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSString * errorStr = [NSString stringWithFormat:@"[%@] %@", [self getSensorName], [error localizedDescription]];
        // [AWAREUtils sendLocalNotificationForMessage:errorStr soundFlag:YES];
        [self saveDebugEventWithText:errorStr type:DebugTypeError label:@""];
        return NO;
    }
    [bufferStr appendString:[jsonstr copy]];
    [bufferStr appendFormat:@","];
    
    if ( writeAble) {
        [self appendLine:[bufferStr mutableCopy]];
        [bufferStr setString:@""];
        if(writeAbleTimer != nil){
            [self setWriteableNO];
        }
    }
    return YES;
}


- (BOOL) appendLine:(NSString *)line{
//    NSLog(@"[%@] Append Line", [self getSensorName] );
    if (!line) {
        NSLog(@"[%@] Line is null", [self getSensorName] );
        return NO;
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[self getFilePath]];
    if (fh == nil) { // no
        NSString * fileName = [self getSensorName];
        NSString* debugMassage = [NSString stringWithFormat:@"[%@] ERROR: AWARE can not handle the file.", fileName];
        [self saveDebugEventWithText:debugMassage type:DebugTypeError label:fileName];
        return NO;
    }else{
        [fh seekToEndOfFile];
        NSData * tempdataLine = [line dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:tempdataLine];
        
        NSString * oneLine = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", line]];
        NSData *data = [oneLine dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:data];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
    return YES;
}





/** create new file */
-(BOOL)createNewFile:(NSString*) fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        BOOL result = [manager createFileAtPath:path
                                       contents:[NSData data]
                                     attributes:nil];
        if (!result) {
            NSLog(@"[%@] Failed to create the file.", fileName);
            return NO;
        }else{
            NSLog(@"[%@] Create the file.", fileName);
            return YES;
        }
    }
    return NO;
}

/** clear file */
- (bool) clearFile:(NSString *) fileName {
    NSFileManager *manager = [NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",fileName]];
    if ([manager fileExistsAtPath:path]) { // yes
        bool result = [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        if (result) {
            NSLog(@"[%@] Correct to clear sensor data.", fileName);
            return YES;
        }else{
            NSLog(@"[%@] Error to clear sensor data.", fileName);
            return NO;
        }
    }else{
        NSLog(@"[%@] The file is not exist.", fileName);
        [self createNewFile:fileName];
        return NO;
    }
    return NO;
}


- (NSInteger) getMaxDateLength {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSInteger length = [userDefaults integerForKey:KEY_MAX_DATA_SIZE];
    return length;
}

- (NSMutableString *) getSensorDataForPost {
    NSInteger maxLength = [self getMaxDateLength];
    NSUInteger seek = [self getMarker] * maxLength;
    // get sensor data from file
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",[self getSensorName]]];
    NSMutableString *data = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSString * message = [NSString stringWithFormat:@"[%@] AWARE can not handle the file.", [self getSensorName]];
        NSLog(@"%@", message);
        [self saveDebugEventWithText:message type:DebugTypeError label:@""];
        return Nil;
    }
    NSLog(@"--> %ld", seek);
    if (seek > [self getLostedTextLength]) {
        [fileHandle seekToFileOffset:seek-(NSInteger)[self getLostedTextLength]];
    }else{
        [fileHandle seekToFileOffset:seek];
    }
    

    
    NSData *clipedData = [fileHandle readDataOfLength:maxLength];
    [fileHandle closeFile];
    
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
//    lineCount = (int)data.length;
    NSLog(@"[%@] Line lenght is %ld", [self getSensorName], (unsigned long)data.length);
    if (data.length == 0 || data.length < [self getMaxDateLength]) {
        [self setMarker:0];
    }else{
        [self setMarker:([self getMarker]+1)];
    }
    return data;
}




- (NSMutableString *) fixJsonFormat:(NSMutableString *) clipedText {
    // head
    if ([clipedText hasPrefix:@"{"]) {
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"{"];
        if (rangeOfExtraText.location == NSNotFound) {
            //             NSLog(@"[HEAD] There is no extra text");
        }else{
            //            NSLog(@"[HEAD] There is some extra text!");
            NSRange deleteRange = NSMakeRange(0, rangeOfExtraText.location);
            [clipedText deleteCharactersInRange:deleteRange];
        }
    }
    
    // tail
    if ([clipedText hasSuffix:@"}"]){
    }else{
        NSRange rangeOfExtraText = [clipedText rangeOfString:@"}" options:NSBackwardsSearch];
        if (rangeOfExtraText.location == NSNotFound) {
            //             NSLog(@"[TAIL] There is no extra text");
            //            lostedTextLength = 0;
            [self setLostedTextLength:0];
        }else{
            //             NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            [clipedText deleteCharactersInRange:deleteRange];
            //            lostedTextLength = (int)deleteRange.length;
            [self setLostedTextLength:(int) deleteRange.length];
        }
    }
    [clipedText insertString:@"[" atIndex:0];
    [clipedText appendString:@"]"];
    //    NSLog(@"%@", clipedText);
    return clipedText;
}



//////////////////////////////////////
//////////////////////////////////////

- (uint64_t) getFileSize{
    NSString * path = [self getFilePath];
    return [[[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil] fileSize];
}




///////////////////////////////////////
///////////////////////////////////////


/**
 * Makers
 */
- (int) getMarker {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [NSNumber numberWithInteger:[userDefaults integerForKey:KEY_SENSOR_UPLOAD_MARK]];
    return number.intValue;
}

- (void) setMarker:(int) intMarker {
    NSNumber * number = [NSNumber numberWithInt:intMarker];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:number.integerValue forKey:KEY_SENSOR_UPLOAD_MARK];
}

- (int) getLostedTextLength{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber * number = [NSNumber numberWithInteger:[userDefaults integerForKey:KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH]];
    return number.intValue;
}

- (void) setLostedTextLength:(int)lostedTextLength {
    NSNumber * number = [NSNumber numberWithInt:lostedTextLength];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:number.integerValue forKey:KEY_SENSOR_UPLOAD_LOSTED_TEXT_LENGTH];
}



////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////


- (bool)saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *)label{
    if (debugSensor != nil) {
        [debugSensor saveDebugEventWithText:eventText type:type label:label];
        return  YES;
    }
    return NO;
}

/**
 * Set Debug Sensor
 */
- (void) trackDebugEventsWithDebugSensor:(Debug*)debug{
    debugSensor = debug;
}


//////////////////////////////////////////////
/////////////////////////////////////////////

/**
 * A File access balancer
 */
- (void) startWriteAbleTimer {
    writeAbleTimer =  [NSTimer scheduledTimerWithTimeInterval:10.0f
                                                       target:self
                                                     selector:@selector(setWriteableYES)
                                                     userInfo:nil repeats:YES];
    [writeAbleTimer fire];
}


- (void) stopWriteableTimer{
    if (!writeAbleTimer) {
        [writeAbleTimer invalidate];
        writeAble = nil;
    }
}

- (void) setWriteableYES{ writeAble = YES; }

- (void) setWriteableNO{ writeAble = NO; }


//////////////////////////////////////////////
///////////////////////////////////////////////

- (NSString *) getFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",[self getSensorName]]];
    return path;
}


@end
