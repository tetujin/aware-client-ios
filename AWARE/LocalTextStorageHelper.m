//
//  LocalTextStorageHelper.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/16/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "LocalTextStorageHelper.h"

@implementation LocalTextStorageHelper {
    NSString * storageName;
    NSMutableString* tempData;
    NSMutableString* bufferStr;
    int lostedTextLength;
    
    BOOL fileAccess;
    NSTimer* fileAccessTimer;
    int fileAccessInterval;
}

- (instancetype)initWithStorageName:(NSString *)name{
    if (self = [super init]) {
        NSLog(@"[%@] Initialize an LocalStorage as '%@' ", storageName, name);
        lostedTextLength = 0;
        storageName = name;
        tempData = [[NSMutableString alloc] init];
        bufferStr = [[NSMutableString alloc] init];
        fileAccess = YES;
        fileAccessInterval = 1; //1 sec 1 file access
        fileAccessTimer = [NSTimer scheduledTimerWithTimeInterval:fileAccessInterval
                                                       target:self
                                                         selector:@selector(setFileAccessYES)
                                                         userInfo:nil
                                                          repeats:YES];
        [fileAccessTimer fire];
        BOOL result = [self createLocalStorage:name];
        if (!result) {
            NSLog(@"[%@] Error to create the file", name);
        }else{
            NSLog(@"[%@] Sucess to create the file", name);
        }
     
    }
    return self;
}


/**
 * =============================================
 *  Make Storage
 * =============================================
 */

- (bool) createLocalStorage:(NSString *) name {
    // Make New Local Storage as Text File
    NSString * path = [self getStoragePath:name];
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) { // no
        NSLog(@"[%@] You don't have a file for %@, then system recreated new file!", name, name);
        NSFileManager *manager = [NSFileManager defaultManager];
        if (![manager fileExistsAtPath:path]) { // yes
            BOOL result = [manager createFileAtPath:path
                                        contents:[NSData data] attributes:nil];
            return result;
        }
    }
    return false;
}

- (NSString *)getStorageName{
    return storageName;
}

- (void) fileAccessTimer {
    [fileAccessTimer invalidate];
    fileAccessTimer = nil;
}

- (NSString* )getStoragePath:(NSString *) name{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString * path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.dat",name]];
    return path;
}



/**
 * =============================================
 *  Store Data
 * =============================================
 */

- (bool) saveData:(NSDictionary *)data{
    NSError*error=nil;
    // Convert NSData to JSONObject
    NSData*d=[NSJSONSerialization dataWithJSONObject:data options:2 error:&error];
    NSString* jsonstr = [[NSString alloc] init];
    if (!error) {
        jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
    } else {
        NSLog(@"[%@] %@", [self  getStorageName], [error localizedDescription]);
        return NO;
    }
    [bufferStr appendString:jsonstr];
    [bufferStr appendFormat:@","];
    //write the object to local storage
    if ( fileAccess ) {
        [self appendLine:bufferStr];
        [bufferStr setString:@""];
        [self setFileAccessNO];
    }else{
        NSLog(@"[%@] File access is failed.", [self getStorageName]);
    }
    return YES;
}

- (bool) saveDataWithArray:(NSArray*) array {
    NSError*error=nil;
    for (NSDictionary *dic in array) {
        NSData*d=[NSJSONSerialization dataWithJSONObject:dic options:2 error:&error];
        NSString* jsonstr = [[NSString alloc] init];
        if (!error) {
            jsonstr = [[NSString alloc]initWithData:d encoding:NSUTF8StringEncoding];
        } else {
            NSLog(@"[%@] %@", [self getStorageName], [error localizedDescription]);
//            [self sendLocalNotificationForMessage:errorStr soundFlag:YES];
            return NO;
        }
        [bufferStr appendString:jsonstr];
        [bufferStr appendFormat:@","];
    }
    if (fileAccess) {
        [self appendLine:bufferStr];
        [bufferStr setString:@""];
        [self setFileAccessNO];
    }else{
         NSLog(@"[%@] File access is failed.", [self getStorageName]);
    }
    return YES;
}


- (BOOL) appendLine:(NSString *)line{
    if (!line) {
        NSLog(@"[%@] Line is null", [self getStorageName] );
        return NO;
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:[self getStoragePath:[self getStorageName]]];
    if (fh == nil) { // no
        NSLog(@"[%@] ERROR: AWARE can not handle the file.", [self getStorageName]);
        [self createLocalStorage:[self getStorageName]];
        return NO;
    }else{
        [fh seekToEndOfFile];
        if (![tempData isEqualToString:@""]) {
            NSData * tempdataLine = [tempData dataUsingEncoding:NSUTF8StringEncoding];
            [fh writeData:tempdataLine]; //write temp data to the main file
            [tempData setString:@""];
            NSLog(@"[%@] Add the sensor data to temp variable.", [self getStorageName]);
        }
        NSString * oneLine = [[NSString alloc] initWithString:[NSString stringWithFormat:@"%@", line]];
        NSData *data = [oneLine dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:data];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
    return YES;
}


- (void) setFileAccessYES {
    fileAccess = YES;
}

- (void) setFileAccessNO{
    fileAccess = NO;
}


/**
 * =============================================
 *  Get Sensor Data
 * =============================================
 */
- (NSMutableString *) getSensorDataWithSeek:(NSInteger)seek length:(NSInteger)length {
    // get sensor data from file
    NSString * path = [self getStoragePath:[self getStorageName]];
    NSMutableString *data = nil;
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
    if (!fileHandle) {
        NSLog(@"[%@] AWARE can not handle the file.", [self getStorageName]);
        [self createLocalStorage:[self getStorageName]];
        return [[NSMutableString alloc] init];
    }
    if (seek > lostedTextLength) {
        [fileHandle seekToFileOffset:seek-(NSInteger)lostedTextLength];
    }else{
        [fileHandle seekToFileOffset:seek];
    }
    NSData *clipedData = [fileHandle readDataOfLength:length];
    [fileHandle closeFile];
    
    data = [[NSMutableString alloc] initWithData:clipedData encoding:NSUTF8StringEncoding];
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
            lostedTextLength = 0;
        }else{
            //             NSLog(@"[TAIL] There is some extra text!");
            NSRange deleteRange = NSMakeRange(rangeOfExtraText.location+1, clipedText.length-rangeOfExtraText.location-1);
            [clipedText deleteCharactersInRange:deleteRange];
            lostedTextLength = (int)deleteRange.length;
        }
    }
    [clipedText insertString:@"[" atIndex:0];
    [clipedText appendString:@"]"];
    
    return clipedText;
}



/**
 * =============================================
 *  clear Data
 * =============================================
 */
- (bool) clearStorage {
    NSString * path = [self getStoragePath:[self getStorageName]];
    NSFileManager *manager = [NSFileManager defaultManager];
    if ([manager fileExistsAtPath:path]) { // yes
        bool result = [@"" writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
        if (result) {
            NSLog(@"[%@] Correct to clear sensor data.", [self getStorageName]);
            return YES;
        }else{
            NSLog(@"[%@] Error to clear sensor data.", [self getStorageName]);
            return NO;
        }
    }else{
        NSLog(@"[%@] The file is not exist.", [self getStorageName]);
        [self createLocalStorage:[self getStorageName]];
        return YES;
    }
//    return NO;
}





@end
