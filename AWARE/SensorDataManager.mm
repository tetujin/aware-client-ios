//
//  SensorDataManager.m
//  Sapplication-Client
//
//  Created by Yuuki Nishiyama on 10/23/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "SensorDataManager.h"
#import <math.h>
//#import "pkmFFT.h"   


const NSString *UNIXTIME = @"unixtime";
const NSString *UID = @"uid";
const NSString *AVE_ACC_X = @"aveAccX";
const NSString *AVE_ACC_Y = @"aveAccY";
const NSString *AVE_ACC_Z = @"aveAccZ";
const NSString *AVE_ACC_COMP = @"aveAccComp";
const NSString *AVE_GYRO_X = @"aveGyroX";
const NSString *AVE_GYRO_Y = @"aveGyroY";
const NSString *AVE_GYRO_Z = @"aveGyroZ";
const NSString *AVE_GYRO_COMP = @"aveGyroComp";
const NSString *AVE_MAG_X = @"aveMagX";
const NSString *AVE_MAG_Y = @"aveMagY";
const NSString *AVE_MAG_Z = @"aveMagZ";
const NSString *AVE_MAG_COMP = @"aveMagComp";
const NSString *LAT = @"lat";
const NSString *LON = @"lon";
const NSString *ALT = @"alt";
const NSString *H_ACCURACY = @"hAccuracy";
const NSString *V_ACCURACY = @"vAccuracy";
const NSString *SPEED = @"speed";
const NSString *COURCE = @"cource";
const NSString *MOTION_TYPE = @"motionType";
const NSString *AIR_PRESSURE = @"airPressure";
const NSString *ALT_FROM_AIR_PRESSURE = @"altFromAirPressure";
const NSString *PROXIMIITY = @"proximity";
const NSString *DEVICE_ORIENTATION = @"deviceOrientation";
const NSString *SCREEN_BRIGHTNESS = @"screenBrightness";
const NSString *BATTERY = @"battery";
const NSString *NETWORK_TYPE = @"networkType";
const NSString *HEADING = @"heading";
const NSString *UUID = @"uuid";
const NSString *APP_STATE = @"appState";
const NSString *DATE = @"date";
const NSString *TIME = @"time";

@implementation SensorDataManager{
    /** Database */
    NSString *dbpath;
    
    bool previusUploadingState;
    NSMutableString* tempData;
    
    /** Location Information */
    double lat;
    double lon;
    double alt;
    double hAccuracy;
    double vAccuracy;
    NSDate* gpsTimestamp;
    double speed;
    double cource;
    
    /** Motion Type */
    NSString* motionType;
    /** Motion data */
    
    /** Air Pressure */
    double airPressure;
    double altFromAirPressure;
    
    /** Proximity */
    bool proximity;
    
    /** Device Orientation */
    int deviceOrientation;
    
    /** Brightness */
    double screenBrightness;
    
    /** Battery */
    double battery;
    
    /** Network */
    NSString* networkType;
    
    /** Heading */
    double heading;
    
    /** steps */
//    NSNumber *step;
//    NSNumber *stepDistance;
//    NSString* startDate;
//    NSString *endDate;
//    NSNumber *floorsAscended;// = pedometerData.floorsAscended;
//    NSNumber *floorsDescended;// = pedometerData.floorsDescended;
    
    NSString *filePath;
    
    /** sensor data buffer */
    NSMutableArray* accxBuffer;
    NSMutableArray* accyBuffer;
    NSMutableArray* acczBuffer;
    NSMutableArray* accCompBuffer;
    NSMutableArray* gyroxBuffer;
    NSMutableArray* gyroyBuffer;
    NSMutableArray* gyrozBuffer;
    NSMutableArray* gyroCompBuffer;
    NSMutableArray* magxBuffer;
    NSMutableArray* magyBuffer;
    NSMutableArray* magzBuffer;
    NSMutableArray* magCompBuffer;
    
    /** Device Information */
    NSString* appUID;
    NSString* deviceUUID;//
    NSString* deviceName;//[UIDevice currentDevice].name;
    NSString* systemName;//[UIDevice currentDevice].systemName;
    NSString* systemVersion;//[UIDevice currentDevice].systemVersion;
    NSString* localizeModel;//[UIDevice currentDevice].localizedModel;
    NSString* deviceModel;//[UIDevice currentDevice].model;
    
    NSMutableDictionary* mainDict;
    NSMutableDictionary* pedDict;
}



- (instancetype)init
{
    self = [super init];
    if (self) {
        dbpath = @"mybase.sqlite";
    }
    return self;
}

- (instancetype) initWithDBPath:(NSString *)dbPath
                         userID:(NSString *)uid{
    
    self = [super init];
    appUID = @"";
    appUID = uid;
    
    // get device info -> this information have to save to user table
    deviceUUID = [[UIDevice currentDevice].identifierForVendor UUIDString]; //UUID
    deviceName = [UIDevice currentDevice].name;//[UIDevice currentDevice].name;
    systemName = [UIDevice currentDevice].systemName;;//[UIDevice currentDevice].systemName;
    systemVersion = [UIDevice currentDevice].systemVersion;;//[UIDevice currentDevice].systemVersion;
    localizeModel = [UIDevice currentDevice].localizedModel;;//[UIDevice currentDevice].localizedModel;
    deviceModel =  [UIDevice currentDevice].model;
    motionType = @"unknown";
    networkType = @"";
    
    mainDict =[[NSMutableDictionary alloc] init];
    
//    NSString *homeDir = NSHomeDirectory();
//    filePath = [homeDir stringByAppendingPathComponsent: @"sensor.dat"];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    filePath = [documentsDirectory stringByAppendingPathComponent:@"sensor.dat"];
    // set temp variable
    [self setUploadingState:NO key:filePath];
    previusUploadingState = [self getUploadingStateWithKey:filePath];
    tempData = [[NSMutableString alloc] init];

    [self createNewFileWithPath:filePath];


    [self initBuffers];
    
    return self;
}

-(void)createNewFileWithPath:(NSString*) path
{
    NSFileManager *manager = [NSFileManager defaultManager];
    if (![manager fileExistsAtPath:path]) { // yes
        // 空のファイルを作成する
        BOOL result = [manager createFileAtPath:path
                                           contents:[NSData data] attributes:nil];
        if (!result) {
            NSLog(@"ファイルの作成に失敗");
            return;
        }else{
            NSLog(@"Created a file");
        }
    }
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
    if (!fh) {
        NSLog(@"ファイルハンドルの作成に失敗");
        return;
    }
    
    [fh closeFile];
}

- (BOOL) appendLine:(NSString *)line path:(NSString*) path {
    if([self getUploadingStateWithKey:path]){
        //TODO
        [tempData appendFormat:@"%@\n", line];
        return YES;
    }else{
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
        if (!fh) { // no
            NSLog(@"Re-create the file! ");
            [self createNewFileWithPath:path];
            fh = [NSFileHandle fileHandleForWritingAtPath:path];
        }else{
            NSLog(@"---");
        }
        [fh seekToEndOfFile];
        //if tempdata has some data
        if (![tempData isEqualToString:@""]) {
            [fh writeData:[tempData dataUsingEncoding:NSUTF8StringEncoding]]; //write temp data to the main file
            tempData = [[NSMutableString alloc] init];// init
            NSLog(@"----> add temp data to the file!!!! ");
        }
        line = [NSString stringWithFormat:@"%@\n", line];
        NSData *data = [line dataUsingEncoding:NSUTF8StringEncoding];
        [fh writeData:data];
        [fh synchronizeFile];
        [fh closeFile];
        return YES;
    }
}

- (void) initBuffers{
    accxBuffer = [[NSMutableArray alloc] init];
    accyBuffer = [[NSMutableArray alloc] init];
    acczBuffer = [[NSMutableArray alloc] init];
    accCompBuffer = [[NSMutableArray alloc] init];
    gyroxBuffer = [[NSMutableArray alloc] init];
    gyroyBuffer = [[NSMutableArray alloc] init];
    gyrozBuffer = [[NSMutableArray alloc] init];
    gyroCompBuffer = [[NSMutableArray alloc] init];
    magxBuffer = [[NSMutableArray alloc] init];
    magyBuffer = [[NSMutableArray alloc] init];
    magzBuffer = [[NSMutableArray alloc] init];
    magCompBuffer = [[NSMutableArray alloc] init];
}

// each sensed timing
- (void) addSensorDataAccx:(double)accx accy:(double)accy accz:(double)accz{
    [accxBuffer addObject:[NSNumber numberWithDouble:accx]];
    [accyBuffer addObject:[NSNumber numberWithDouble:accy]];
    [acczBuffer addObject:[NSNumber numberWithDouble:accz]];
    [accCompBuffer addObject:[NSNumber numberWithDouble:[self calCompFromX:accx y:accy z:accz]]];
}

- (void) addSensorDataGyrox:(double)gyrox gyroy:(double)gyroy gyroz:(double)gyroz{
    [gyroxBuffer addObject:[NSNumber numberWithDouble:gyrox]];
    [gyroyBuffer addObject:[NSNumber numberWithDouble:gyroy]];
    [gyrozBuffer addObject:[NSNumber numberWithDouble:gyroz]];
    [gyroCompBuffer addObject:[NSNumber numberWithDouble:[self calCompFromX:gyrox y:gyroy z:gyroz]]];
}

- (void) addSensorDataMagx:(double)magx magy:(double)magy magz:(double)magz{
    [magxBuffer addObject:[NSNumber numberWithDouble:magx]];
    [magyBuffer addObject:[NSNumber numberWithDouble:magy]];
    [magzBuffer addObject:[NSNumber numberWithDouble:magz]];
    [magCompBuffer addObject:[NSNumber numberWithDouble:[self calCompFromX:magx y:magy z:magz]]];
}


- (void) addLocation: (CLLocation *)location {
    lat = location.coordinate.latitude;
    lon = location.coordinate.longitude;
    alt = location.altitude;
    hAccuracy = location.horizontalAccuracy;
    vAccuracy = location.verticalAccuracy;
    gpsTimestamp = location.timestamp;
    speed = location.speed;
    cource = location.course;
}

- (void)addHeading:(double)headingValue{
    heading = headingValue;
}

- (void) addDeviceMotion: (CMDeviceMotion *) deviceMotion{
//    deviceMotion.magneticField.field.x;
//    deviceMotion.magneticField.field.y;
//    deviceMotion.magneticField.field.z;
//    deviceMotion.magneticField.accuracy;
//    
//        deviceMotion.gravity.x;
//        deviceMotion.gravity.y;
//        deviceMotion.gravity.z;
//    deviceMotion.attitude.pitch;
//    deviceMotion.attitude.roll;
//    deviceMotion.attitude.yaw;
//    deviceMotion.rotationRate.x;
//    deviceMotion.rotationRate.y;
//    deviceMotion.rotationRate.z;
//
//    deviceMotion.timestamp;
//    deviceMotion.userAcceleration.x;
//    deviceMotion.userAcceleration.y;
//    deviceMotion.userAcceleration.z;
}


- (void) addMotionActivity: (CMMotionActivity *) motionActivity{
    if (motionActivity.confidence  == CMMotionActivityConfidenceHigh){
        NSLog(@"Quite probably a new activity.");
//        NSDate *started = motionActivity.startDate;
        if (motionActivity.stationary){
            motionType = @"sationary";
            NSLog(@"Sitting, doing nothing");
        } else if (motionActivity.running){
            motionType = @"running";
            NSLog(@"Active! Running!");
        } else if (motionActivity.automotive){
            motionType = @"automotive";
            NSLog(@"Driving along!");
        } else if (motionActivity.walking){
            motionType = @"walking";
            NSLog(@"Strolling round the city..");
        } else if (motionActivity.cycling){
            motionType = @"cycling";
            NSLog(@"Cycling");
        } else if (motionActivity.unknown){
            motionType = @"unknown";
            NSLog(@"Unknown");
        }
    }
}


- (void) addPedometerData: (CMPedometerData *) pedometerData{
    NSNumber* step = pedometerData.numberOfSteps;
    NSNumber* stepDistance = pedometerData.distance;
//    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
//    [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString* startDate = [outputFormatter stringFromDate:pedometerData.startDate];
//    NSString* endDate = [outputFormatter stringFromDate:pedometerData.endDate];
    double startTimestamp = [pedometerData.startDate timeIntervalSince1970];
    double endTimestamp = [pedometerData.endDate timeIntervalSince1970];
    NSNumber* floorsAscended = pedometerData.floorsAscended;
    NSNumber* floorsDescended = pedometerData.floorsDescended;
    
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    [tempDict setObject:[NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]] forKey:@"unixtime"];
    [tempDict setObject:[NSNumber numberWithDouble:startTimestamp] forKey:@"start_unixtime"];
    [tempDict setObject:[NSNumber numberWithDouble:endTimestamp] forKey:@"end_unixtime"];
    [tempDict setObject:step forKey:@"step"];
    [tempDict setObject:stepDistance forKey:@"step_distance"];
    [tempDict setObject:floorsAscended forKey:@"floors_ascended"];
    [tempDict setObject:floorsDescended forKey:@"floors_descended"];
    [tempDict setObject:appUID forKey:@"uid"];
    [tempDict setObject:deviceUUID forKey:@"device_uid"];
}


//- (void) addPedometerData: (CMPedometerData *) pedometerData{
//    NSNumber* step = pedometerData.numberOfSteps;
//    NSNumber* stepDistance = pedometerData.distance;
//    NSDateFormatter *outputFormatter = [[NSDateFormatter alloc] init];
//    [outputFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//    NSString* startDate = [outputFormatter stringFromDate:pedometerData.startDate];
//    NSString* endDate = [outputFormatter stringFromDate:pedometerData.endDate];
//    double startTimestamp = [pedometerData.startDate timeIntervalSince1970];
//    double endTimestamp = [pedometerData.endDate timeIntervalSince1970];
//    NSNumber* floorsAscended = pedometerData.floorsAscended;
//    NSNumber* floorsDescended = pedometerData.floorsDescended;
//    
//    NSString *sql = [NSString stringWithFormat:@"insert into ped ("
//    "unixtime,"
//    "start_unixtime,"
//    "end_unixtime,"
//    "start,"
//    "end,"
//    "step,"
//    "step_distance,"
//    "floors_ascended,"
//    "floors_descended,"
//    "uid,"
//    "uuid"
//    ") values ( %f, %f, %f, '%@', '%@', %d, %d, %d, %d, '%@', '%@');",
//    [[NSDate date] timeIntervalSince1970],
//    startTimestamp,
//    endTimestamp,
//    startDate,
//    endDate,
//    [step intValue],
//    [stepDistance intValue],
//    [floorsAscended intValue],
//    [floorsDescended intValue],
//    appUID,
//    deviceUUID
//    ];
////    NSLog(sql);
//    if ([db open]) {
//        [db executeStatements:sql];
//        [db close];
//    }
//}

- (void) addAltitudeDaat: (CMAltitudeData * )altitudeData {
    airPressure = [altitudeData pressure].doubleValue;
    altFromAirPressure = [altitudeData relativeAltitude].doubleValue;
}

- (void) addDeviceOrientation: (int) orientation{
    deviceOrientation = orientation;
}

- (void) addBrightness: (double) brightness{
    screenBrightness = brightness;
}

- (void) addBattery: (double)batteryLevel{
    battery = batteryLevel;
}


- (void) addNetwork: (NSString *) network{
    networkType = network;
}

- (void)updateUserInfoWithUID:(NSString *)uid
{
    appUID = uid;
}


// every 1 sec.
- (void) saveAllSensorDataToDBWithBufferClean:(bool)state{
    // calcurate averate value ot sensor data
    
//    NSMutableArray *copyedAccXBuffer = [accxBuffer copy];
//    NSMutableArray *copyedAccYBuffer = [accxBuffer copy];
//    NSMutableArray *copyedAccZBuffer = [accxBuffer copy];
//    NSMutableArray *copyedAccCompBuffer = [accxBuffer copy];
    
    double aveAccX = [self calAverageFromArray:accxBuffer];
    double aveAccY = [self calAverageFromArray:accyBuffer];
    double aveAccZ = [self calAverageFromArray:acczBuffer];
    double aveAccComp = [self calDispersionFromArray:accCompBuffer];
    double aveGyroX = [self calAverageFromArray:gyroxBuffer];
    double aveGyroY = [self calAverageFromArray:gyroyBuffer];
    double aveGyroZ = [self calAverageFromArray:gyrozBuffer];
    double aveGyroComp = [self calDispersionFromArray:gyroCompBuffer];
    double aveMagX = [self calAverageFromArray:magxBuffer];
    double aveMagy = [self calAverageFromArray:magyBuffer];
    double aveMagz = [self calAverageFromArray:magzBuffer];
    double aveMagComp = [self calDispersionFromArray:magCompBuffer];
    
//    double dispAccX = [self calDispersionFromArray:accxBuffer];
//    double dispAccY = [self calDispersionFromArray:accyBuffer];
//    double dispAccZ = [self calDispersionFromArray:acczBuffer];
//    double dispAccComp = [self calDispersionFromArray:accCompBuffer];
//    double dispGyroX = [self calDispersionFromArray:gyroxBuffer];
//    double dispGyroY = [self calDispersionFromArray:gyroyBuffer];
//    double dispGyroZ = [self calDispersionFromArray:gyrozBuffer];
//    double dispGyroComp = [self calDispersionFromArray:gyroCompBuffer];
//    double dispMagX = [self calDispersionFromArray:magxBuffer];
//    double dispMagy = [self calDispersionFromArray:magyBuffer];
//    double dispMagz = [self calDispersionFromArray:magzBuffer];
//    double dispMagComp = [self calDispersionFromArray:magCompBuffer];
//    
//    double rmsAccX = [self calRMSFromArray:accxBuffer];
//    double rmsAccY = [self calRMSFromArray:accyBuffer];
//    double rmsAccZ = [self calRMSFromArray:acczBuffer];
//    double rmsAccComp = [self calRMSFromArray:accCompBuffer];
//    double rmsGyroX = [self calRMSFromArray:gyroxBuffer];
//    double rmsGyroY = [self calRMSFromArray:gyroyBuffer];
//    double rmsGyroZ = [self calRMSFromArray:gyrozBuffer];
//    double rmsGyroComp = [self calRMSFromArray:gyroCompBuffer];
//    double rmsMagX = [self calRMSFromArray:magxBuffer];
//    double rmsMagy = [self calRMSFromArray:magyBuffer];
//    double rmsMagz = [self calRMSFromArray:magzBuffer];
//    double rmsMagComp = [self calRMSFromArray:magCompBuffer];
    
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    bool appState = [defaults boolForKey:@"APP_STATE"];
    
    if(appUID == nil){
        appUID = @"";
    }
    NSMutableDictionary *tempDict = [[NSMutableDictionary alloc] init];
    NSDate *date = [[NSDate alloc] init];
    [tempDict setObject:[NSNumber numberWithDouble:[date timeIntervalSince1970]] forKey:UNIXTIME];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
//    [dateFormat setDateFormat:@"YYYY/MM/dd hh:mm:ss"];
    [dateFormat setDateFormat:@"YYYY-MM-dd"];
    NSString *formatedDate = [dateFormat stringFromDate:date];
    [dateFormat setDateFormat:@"hh:mm:ss"];
    NSString *formatedTime = [dateFormat stringFromDate:date];
    [tempDict setObject:formatedDate forKey:DATE];
    [tempDict setObject:formatedTime forKey:TIME];
    [tempDict setObject:appUID forKey:UID];
    [tempDict setObject:[NSNumber numberWithDouble:aveAccX] forKey:AVE_ACC_X];
    [tempDict setObject:[NSNumber numberWithDouble:aveAccY] forKey:AVE_ACC_Y];
    [tempDict setObject:[NSNumber numberWithDouble:aveAccZ] forKey:AVE_ACC_Z];
    [tempDict setObject:[NSNumber numberWithDouble:aveAccComp] forKey:AVE_ACC_COMP];
    [tempDict setObject:[NSNumber numberWithDouble:aveGyroX] forKey:AVE_GYRO_X];
    [tempDict setObject:[NSNumber numberWithDouble:aveGyroY] forKey:AVE_GYRO_Y];
    [tempDict setObject:[NSNumber numberWithDouble:aveGyroZ] forKey:AVE_GYRO_Z];
    [tempDict setObject:[NSNumber numberWithDouble:aveGyroComp] forKey:AVE_GYRO_COMP];
    [tempDict setObject:[NSNumber numberWithDouble:aveMagX] forKey:AVE_MAG_X];
    [tempDict setObject:[NSNumber numberWithDouble:aveMagy] forKey:AVE_MAG_Y];
    [tempDict setObject:[NSNumber numberWithDouble:aveMagz] forKey:AVE_MAG_Z];
    [tempDict setObject:[NSNumber numberWithDouble:aveMagComp] forKey:AVE_MAG_COMP];
    [tempDict setObject:[NSNumber numberWithDouble:lat] forKey:LAT];
    [tempDict setObject:[NSNumber numberWithDouble:lon] forKey:LON];
    [tempDict setObject:[NSNumber numberWithDouble:alt] forKey:ALT];
    [tempDict setObject:[NSNumber numberWithDouble:hAccuracy] forKey:H_ACCURACY];
    [tempDict setObject:[NSNumber numberWithDouble:vAccuracy] forKey:V_ACCURACY];
    [tempDict setObject:[NSNumber numberWithDouble:speed] forKey:SPEED];
    [tempDict setObject:[NSNumber numberWithDouble:cource] forKey:COURCE];
    [tempDict setObject:motionType forKey:MOTION_TYPE];
    [tempDict setObject:[NSNumber numberWithDouble:airPressure] forKey:AIR_PRESSURE];
    [tempDict setObject:[NSNumber numberWithDouble:altFromAirPressure] forKey:ALT_FROM_AIR_PRESSURE];
    [tempDict setObject:[NSNumber numberWithBool:proximity] forKey:PROXIMIITY];
    [tempDict setObject:[NSNumber numberWithInt:deviceOrientation] forKey:DEVICE_ORIENTATION];
    [tempDict setObject:[NSNumber numberWithDouble:screenBrightness] forKey:SCREEN_BRIGHTNESS];
    [tempDict setObject:[NSNumber numberWithDouble:battery] forKey:BATTERY];
    [tempDict setObject:networkType forKey:NETWORK_TYPE];
    [tempDict setObject:[NSNumber numberWithDouble:heading] forKey:HEADING];
    [tempDict setObject:deviceUUID forKey:UUID];
    [tempDict setObject:[NSNumber numberWithBool:appState] forKey:APP_STATE];

    NSError *error;
    NSData *line = [NSJSONSerialization dataWithJSONObject:tempDict
                                                       options:0//NSJSONWritingPrettyPrinted
                        // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    NSString *jsonString = @"";
    if (! line) {
        NSLog(@"Got an error: %@", error);
    } else {
        jsonString = [[NSString alloc] initWithData:line encoding:NSUTF8StringEncoding];
    }
//    NSLog(@"%@", jsonString);

    
    [self appendLine:jsonString path:filePath];
//    NSLog(@"%@",line);
    if (state) {
        [self initBuffers];
    }
}

// every 1 min.
- (bool) uploadSensorDataWithURL:(NSString*)url{
    
    if(![networkType isEqualToString:@"WiFi"]){
        return true;
    }
    
    // ファイルハンドルを作成する
    NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
    if (!fileHandle) {
        NSLog(@"ファイルがありません．");
        return NO;
    }
    // ファイルの末尾まで読み込む
    NSString *str = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    [fileHandle closeFile];
    
    NSMutableString *data = [[NSMutableString alloc] initWithString:@"["];
    // 1行ずつ文字列を列挙
    [str enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
        [data appendString:[NSString stringWithFormat:@"%@,", line]];
    }];
    [data deleteCharactersInRange:NSMakeRange([data length]-1, 1)];
    [data appendString:@"]"];

//    id obj = [NSJSONSerialization JSONObjectWithData:[data dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
//    NSLog(@"%@", obj);
    

    NSString *post = [NSString stringWithFormat:@"data=%@", data];
    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:url]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:postData];

    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    bool appState = [defaults boolForKey:@"APP_STATE"];

    
    if (appState) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
            [self setUploadingState:YES key:filePath];
            int responseCode = [self httpRequst:request];
            dispatch_async(dispatch_get_main_queue(), ^{
                if(responseCode == 200){
                    NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
                    [self removeFileWithURL:filePath];
                    [self setUploadingState:NO key:filePath];
                }
            });
        });
    }else{
        [self setUploadingState:YES key:filePath];
        int responseCode = [self httpRequst:request];
        if (responseCode == 200) {
            NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
            [self removeFileWithURL:filePath];
            [self setUploadingState:NO key:filePath];
        }
//        [self sendLocalNotificationForMessage:[NSString stringWithFormat:@"%d", responseCode] soundFlag:NO];
    }

    return true;
}

- (int) httpRequst:(NSMutableURLRequest *) request{
    NSError *error = nil;
    NSHTTPURLResponse *response = nil;
    NSData *resData = [NSURLConnection sendSynchronousRequest:request
                                            returningResponse:&response error:&error];
//    NSString* d = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
    int responseCode = (int)[response statusCode];
    return responseCode;
}

- (bool) removeFileWithURL:(NSString *)path {
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    return YES;
}

- (void) setUploadingState:(bool)state key:(NSString *)key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:state forKey:key];
    [defaults synchronize];
    //bool appState = [defaults boolForKey:filePath];
    //return NO;
}

- (bool) getUploadingStateWithKey:(NSString *) key{
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    return [defaults boolForKey:key];
}

/**
 * send ped information
 */
- (bool) uploadPedDataToDBWithURL:(NSString*)url dbClean:(bool)state{
    return true;
}


// calcurate comp
- (double) calCompFromX:(double)x
                      y:(double)y
                      z:(double)z{
    return sqrt(pow(x, 2) + pow(y, 2) + pow(z, 2));
}

// calcurate average data
- (double) calAverageFromArray:(NSMutableArray *) array {
    double totalVal = 0;
    for(int i=0; i<[array count]; i++){
        totalVal += [[array objectAtIndex:i] doubleValue];
    }
    double val = totalVal/[array count];
    if (isnan(val)) {
        return 0;
    }
    return val;
}

// calcurate SD
- (double) calDispersionFromArray:(NSMutableArray *)array {
    double ave = [self calAverageFromArray:array];
    double totalDis = 0;
    for(int i=0; i<[array count]; i++){
        //http://mathtrain.jp/variance
        totalDis += pow( ave - [[array objectAtIndex:i] doubleValue], 2);
    }
    double val = totalDis/[array count];
    if (isnan(val)) {
        return 0;
    }
    return val;
}

// calcurate RMS
- (double) calRMSFromArray:(NSMutableArray *)array{
    double totalVal = 0;
    for(int i=0; i<[array count]; i++){
        //http://mathtrain.jp/variance
        totalVal += pow([[array objectAtIndex:i] doubleValue], 2);
    }
    double val = sqrt(totalVal/[array count]);
    if (isnan(val)) {
        return 0;
    }
    return val;
}

- (NSArray *) calFFT{
    // be sure to either use malloc or __attribute__ ((aligned (16))
//    NSLog(@"go go !");
//    float *sample_data = (float *) malloc (sizeof(float) * 4096);
//    float *allocated_magnitude_buffer =  (float *) malloc (sizeof(float) * 2048);
//    float *allocated_phase_buffer =  (float *) malloc (sizeof(float) * 2048);
//    pkmFFT *fft;
//    fft = new pkmFFT(4096);
//    fft->forward(0, sample_data, allocated_magnitude_buffer, allocated_phase_buffer);
//    fft->inverse(0, sample_data, allocated_magnitude_buffer, allocated_phase_buffer);
//    delete fft;
    return nil;
}


/**
 ローカルプッシュ通知処理
 @param message メッセージ
 @param sound 通知音の設定
 */
//- (void)sendLocalNotificationForMessage:(NSString *)message soundFlag:(BOOL)soundFlag {
//    UILocalNotification *localNotification = [UILocalNotification new];
//    localNotification.alertBody = message;
//    //    localNotification.fireDate = [NSDate date];
//    localNotification.repeatInterval = 0;
//    if(soundFlag) {
//        localNotification.soundName = UILocalNotificationDefaultSoundName;
//    }
//    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
//}


//    "unixtime double,"
//    "uid text, "
//    "aveAccX real, aveAccY real, aveAccZ real, aveAccComp real, "
//    "aveGyroX double, aveGyroY double, aveGyroZ double, aveGyroComp double, "
//    "aveMagX double, aveMagY double, aveMagZ double, aveMagComp double, "
//    "dispAccX double, dispAccY double, dispAccZ double, dispAccComp double, "
//    "dispGyroX double, dispGyroY double, dispGyroZ double, dispGyroComp double, "
//    "dispMagX double, dispMagY double, dispMagZ double, dispMagComp double, "
//    "rmsAccX double, rmsAccY double, rmsAccZ double, rmsAccComp double, "
//    "rmsGyroX double, rmsGyroY double, rmsGyroZ double, rmsGyroComp double, "
//    "rmsMagX double, rmsMagY double, rmsMagZ double, rmsMagComp double, "
//    "lat double, lon double, alt double,"
//    "hAccuracy double, vAccuracy double,"
//    "speed double, cource double,"
//    "motionType text,"
//    "airPressure double, altFromAirPressure double,"
//    "proximity boolean,"
//    "deviceOrientation int,"
//    "screenBrightness double,"
//    "battery double,"
//    "networkType text,"
//    "heading double,"
//    "uuid text,"
//    "appState boolean"



//    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:@"sensor.dat"];
//    [fh seekToEndOfFile];
//    [csvdata appendFormat:@"\n"];
//    NSData *data = [csvdata dataUsingEncoding:NSUTF8StringEncoding];
//    [fh writeData:data];
//    [fh closeFile];

//    [self calFFT];
//    dbpath = dbPath;
/** database */
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *documentsDirectory = [paths objectAtIndex:0];
//    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:dbPath];
//    db = [FMDatabase databaseWithPath:writableDBPath];
//    if (![db open]) {
//    }
//    // https://github.com/ccgus/fmdb
//    [db executeStatements:@"drop table sensordata;"]; // [TODO] This method for dobug
//    // https://www.sqlite.org/datatype3.html
//    NSString *sql = @"create table sensordata (id integer primary key autoincrement,"
//    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, "
//    "unixtime double,"
//    "uid text, "
//    "aveAccX real, aveAccY real, aveAccZ real, aveAccComp real, "
//    "aveGyroX double, aveGyroY double, aveGyroZ double, aveGyroComp double, "
//    "aveMagX double, aveMagY double, aveMagZ double, aveMagComp double, "
//    "dispAccX double, dispAccY double, dispAccZ double, dispAccComp double, "
//    "dispGyroX double, dispGyroY double, dispGyroZ double, dispGyroComp double, "
//    "dispMagX double, dispMagY double, dispMagZ double, dispMagComp double, "
//    "rmsAccX double, rmsAccY double, rmsAccZ double, rmsAccComp double, "
//    "rmsGyroX double, rmsGyroY double, rmsGyroZ double, rmsGyroComp double, "
//    "rmsMagX double, rmsMagY double, rmsMagZ double, rmsMagComp double, "
//    "lat double, lon double, alt double,"
//    "hAccuracy double, vAccuracy double,"
//    "speed double, cource double,"
//    "motionType text,"
//    "airPressure double, altFromAirPressure double,"
//    "proximity boolean,"
//    "deviceOrientation int,"
//    "screenBrightness double,"
//    "battery double,"
//    "networkType text,"
//    "heading double,"
//    "uuid text,"
//    "appState boolean"
//    ");";
//    bool success = [db executeStatements:sql];
//    NSLog(@"--> %d", success);



//    [db executeStatements:@"drop table ped;"]; // [TODO] This method for dobug
//    sql = @"create table ped ("
//    "id integer primary key autoincrement,"
//    "timestamp DATETIME DEFAULT CURRENT_TIMESTAMP, "
//    "unixtime double,"
//    "start_unixtime double,"
//    "end_unixtime double,"
//    "start text,"
//    "end text,"
//    "step int,"
//    "step_distance int,"
//    "floors_ascended int,"
//    "floors_descended int,"
//    "uid text, "
//    "uuid text"
//    ");";
//    success = [db executeStatements:sql];
//    [db close];


// every 1 sec.
//- (void) saveAllSensorDataToDBWithBufferClean:(bool)state{
//    // calcurate averate value ot sensor data
//    double aveAccX = [self calAverageFromArray:accxBuffer];
//    double aveAccY = [self calAverageFromArray:accyBuffer];
//    double aveAccZ = [self calAverageFromArray:acczBuffer];
//    double aveAccComp = [self calDispersionFromArray:accCompBuffer];
//    double aveGyroX = [self calAverageFromArray:gyroxBuffer];
//    double aveGyroY = [self calAverageFromArray:gyroyBuffer];
//    double aveGyroZ = [self calAverageFromArray:gyrozBuffer];
//    double aveGyroComp = [self calDispersionFromArray:gyroCompBuffer];
//    double aveMagX = [self calAverageFromArray:magxBuffer];
//    double aveMagy = [self calAverageFromArray:magyBuffer];
//    double aveMagz = [self calAverageFromArray:magzBuffer];
//    double aveMagComp = [self calDispersionFromArray:magCompBuffer];
//
//    double dispAccX = [self calDispersionFromArray:accxBuffer];
//    double dispAccY = [self calDispersionFromArray:accyBuffer];
//    double dispAccZ = [self calDispersionFromArray:acczBuffer];
//    double dispAccComp = [self calDispersionFromArray:accCompBuffer];
//    double dispGyroX = [self calDispersionFromArray:gyroxBuffer];
//    double dispGyroY = [self calDispersionFromArray:gyroyBuffer];
//    double dispGyroZ = [self calDispersionFromArray:gyrozBuffer];
//    double dispGyroComp = [self calDispersionFromArray:gyroCompBuffer];
//    double dispMagX = [self calDispersionFromArray:magxBuffer];
//    double dispMagy = [self calDispersionFromArray:magyBuffer];
//    double dispMagz = [self calDispersionFromArray:magzBuffer];
//    double dispMagComp = [self calDispersionFromArray:magCompBuffer];
//
//    double rmsAccX = [self calRMSFromArray:accxBuffer];
//    double rmsAccY = [self calRMSFromArray:accyBuffer];
//    double rmsAccZ = [self calRMSFromArray:acczBuffer];
//    double rmsAccComp = [self calRMSFromArray:accCompBuffer];
//    double rmsGyroX = [self calRMSFromArray:gyroxBuffer];
//    double rmsGyroY = [self calRMSFromArray:gyroyBuffer];
//    double rmsGyroZ = [self calRMSFromArray:gyrozBuffer];
//    double rmsGyroComp = [self calRMSFromArray:gyroCompBuffer];
//    double rmsMagX = [self calRMSFromArray:magxBuffer];
//    double rmsMagy = [self calRMSFromArray:magyBuffer];
//    double rmsMagz = [self calRMSFromArray:magzBuffer];
//    double rmsMagComp = [self calRMSFromArray:magCompBuffer];
//
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    bool appState = [defaults boolForKey:@"APP_STATE"];
//
//    NSString *sql = [NSString stringWithFormat:
//    @"insert into sensordata ("
//    "unixtime, "
//    "uid,"
//    "aveAccX, aveAccY, aveAccZ, aveAccComp, "
//    "aveGyroX, aveGyroY, aveGyroZ, aveGyroComp, "
//    "aveMagX, aveMagY, aveMagZ, aveMagComp, "
//    "dispAccX, dispAccY, dispAccZ, dispAccComp, "
//    "dispGyroX, dispGyroY, dispGyroZ, dispGyroComp, "
//    "dispMagX, dispMagY, dispMagZ, dispMagComp, "
//    "rmsAccX, rmsAccY, rmsAccZ, rmsAccComp, "
//    "rmsGyroX, rmsGyroY, rmsGyroZ, rmsGyroComp, "
//    "rmsMagX, rmsMagY, rmsMagZ, rmsMagComp, "
//    "lat, lon, alt,"
//    "hAccuracy, vAccuracy,"
//    "speed, cource,"
//    "motionType,"
//    "airPressure, altFromAirPressure,"
//    "proximity,"
//    "deviceOrientation,"
//    "screenBrightness,"
//    "battery,"
//    "networkType,"
//    "heading,"
//    "uuid,"
//    "appState) values ("
//    "%f,"
//    "'%@',"
//    "%f,%f,%f,%f," // aveAcc
//    "%f,%f,%f,%f," // aveGyro
//    "%f,%f,%f,%f," // aveMag
//    "%f,%f,%f,%f," // dispAcc
//    "%f,%f,%f,%f," // dispGyrp
//    "%f,%f,%f,%f," // dispMag
//    "%f,%f,%f,%f," // rmsAcc
//    "%f,%f,%f,%f," // rmsGyro
//    "%f,%f,%f,%f," // rmsMag
//    "%f, %f, %f," //location
//    "%f, %f," //accuracy
//    "%f, %f,"
//    "'%@', "
//    "%f, %f,"
//    "%d,"
//    "%d,"
//    "%f,"
//    "%f,"
//    "'%@',"
//    "%f,"
//    "'%@',"
//    "%d"
//    ")",
//    [[NSDate date] timeIntervalSince1970],
//    appUID,
//    aveAccX, aveAccY, aveAccZ, aveAccComp,
//    aveGyroX, aveGyroY, aveGyroZ, aveGyroComp,
//    aveMagX, aveMagy, aveMagz, aveMagComp,
//    dispAccX, dispAccY, dispAccZ, dispAccComp,
//    dispGyroX, dispGyroY, dispGyroZ, dispGyroComp,
//    dispMagX, dispMagy, dispMagz, dispMagComp,
//    rmsAccX, rmsAccY, rmsAccZ, rmsAccComp,
//    rmsGyroX, rmsGyroY, rmsGyroZ, rmsGyroComp,
//    rmsMagX, rmsMagy, rmsMagz, rmsMagComp,
//    lat, lon, alt,
//    hAccuracy, vAccuracy,
//    speed, cource,
//    motionType,
//     airPressure  , altFromAirPressure  ,
//     proximity,
//     deviceOrientation,
//     screenBrightness  ,
//     battery ,
//     networkType,
//     heading,
//     deviceUUID,
//     appState
//    ];
//
//    if ([db open]) {
//        bool success = [db executeStatements:sql];
//        NSLog(@"=====> %d", success);
//        [db close];
//    }
//
//    if (state) {
//        [self initBuffers];
//    }
//}





//// every 1 min.
//- (bool) uploadSensorDataWithURL:(NSString*)url{
//    //    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//    //    [formatter setDateFormat:@"YYYY-MM-dd HH:MM:SS"];
//    //    NSString *now = [formatter stringFromDate:[NSDate date]];
//    //    NSLog(@"%@",now);
//    double nowUnixtime = [[NSDate new] timeIntervalSince1970];
//    NSString *sql = [NSString stringWithFormat:@"select * from sensordata where unixtime < %f;", nowUnixtime];
//    [db open];
//    NSMutableArray* array = [[NSMutableArray alloc] init];
//    //    [array setValue:@"test" forKey:@"test"];
//    bool success = [db executeStatements:sql withResultBlock:^int(NSDictionary *dictionary) {
//        NSMutableDictionary *mDict = [[NSMutableDictionary alloc] init];
//        NSLog(@"%d", [dictionary count]);
//        for (NSString* key in dictionary) {
//            if ([key isEqualToString:@"uid"] ||
//                [key isEqualToString:@"motionType"] ||
//                [key isEqualToString:@"networkType"] ||
//                [key isEqualToString:@"uuid"] ||
//                [key isEqualToString:@"timestamp"]) {
//                // text
//                // "uid," "motionType," "networkType," "uuid,"
//                NSString *strVal = [dictionary objectForKey:key ];
//                [mDict setValue:strVal forKey:key];
//            }else if([key isEqualToString:@"proximity"] ||
//                     [key isEqualToString:@"deviceOrientation"] ||
//                     [key isEqualToString:@"appState"]){
//                // int
//                // "proximity," "deviceOrientation," "appState
//                NSNumber *intVal = [NSNumber numberWithInt:[[dictionary objectForKey:key] intValue]];
//                [mDict setValue:intVal forKey:key];
//            }else{
//                //                [mDict setObject:[dictionary[key] integerValue] forKey:key];
//                // double
//                NSNumber *doubleVal = [NSNumber numberWithDouble:[[dictionary objectForKey:key] doubleValue]];
//                [mDict setValue:doubleVal forKey:key];
//            }
//        }
//        [array addObject:mDict];
//        return 0;
//    }];
//    [db close];
//    NSLog(@"%d", [array count]);
//    NSError *error;
//    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array
//                                                       options:NSJSONWritingPrettyPrinted
//                        // Pass 0 if you don't care about the readability of the generated string
//                                                         error:&error];
//    NSString *jsonString = @"";
//    if (! jsonData) {
//        NSLog(@"Got an error: %@", error);
//    } else {
//        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//    }
//    NSLog(@"%@", jsonString);
//    NSString *post = [NSString stringWithFormat:@"data=%@", jsonString];
//    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//    [request setURL:[NSURL URLWithString:url]];
//    [request setHTTPMethod:@"POST"];
//    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//    //[request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//    [request setHTTPBody:postData];
//    
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    bool appState = [defaults boolForKey:@"APP_STATE"];
//    
//    //    if (appState) {
//    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//    //
//    //            NSError *error = nil;
//    //            NSHTTPURLResponse *response = nil;
//    //            NSData *resData = [NSURLConnection sendSynchronousRequest:request
//    //                                                    returningResponse:&response error:&error];
//    //            int responseCode = (int)[response statusCode];
//    //            dispatch_async(dispatch_get_main_queue(), ^{
//    //                if(responseCode == 200){
//    //                    NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
//    //                    [db open];
//    //                    NSString * sql = [NSString stringWithFormat:@"delete from sensordata where unixtime < %f;", nowUnixtime];
//    //                    bool success = [db executeStatements:sql];
//    //                    [db close];
//    //                    if (success) {
//    //                        NSLog(@"%d: Old sensor data is removed.", responseCode);
//    //                    }
//    //                }
//    //            });
//    //        });
//    //    }else{
//    //        NSError *error = nil;
//    NSHTTPURLResponse *response = nil;
//    NSData *resData = [NSURLConnection sendSynchronousRequest:request
//                                            returningResponse:&response error:&error];
//    NSString* d = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
//    [self sendLocalNotificationForMessage:d soundFlag:YES];
//    NSLog(@"%@", d);
//    int responseCode = (int)[response statusCode];
//    if(responseCode == 200){
//        NSLog(@"UPLOADED SENSOR DATA TO A SERVER");
//        [db open];
//        NSString * sql = [NSString stringWithFormat:@"delete from sensordata where unixtime < %f;", nowUnixtime];
//        bool success = [db executeStatements:sql];
//        [db close];
//        if (success) {
//            NSLog(@"%d: Old sensor data is removed.", responseCode);
//            return YES;
//        }
//    }
//    return NO;
//    //    }
//}
//
//
///**
// * send ped information
// */
//- (bool) uploadPedDataToDBWithURL:(NSString*)url dbClean:(bool)state{
//    double nowUnixtime = [[NSDate new] timeIntervalSince1970];
//    NSString *sql = [NSString stringWithFormat:@"select * from ped where unixtime < %f;", nowUnixtime];
//    [db open];
//    NSMutableArray* array = [[NSMutableArray alloc] init];
//    bool success = [db executeStatements:sql withResultBlock:^int(NSDictionary *dictionary) {
//        NSMutableDictionary *mDict = [[NSMutableDictionary alloc] init];
//        for (NSString* key in dictionary) {
//            if ([key isEqualToString:@"uid"] ||
//                [key isEqualToString:@"start"] ||
//                [key isEqualToString:@"end"] ||
//                [key isEqualToString:@"uuid"] ||
//                [key isEqualToString:@"timestamp"]) {
//                NSString *strVal = [dictionary objectForKey:key ];
//                [mDict setValue:strVal forKey:key];
//            }else if([key isEqualToString:@"step"] ||
//                     [key isEqualToString:@"step_distance"] ||
//                     [key isEqualToString:@"floors_ascended"] ||
//                     [key isEqualToString:@"floors_descended"]){
//                NSNumber *intVal = [NSNumber numberWithInt:[[dictionary objectForKey:key] intValue]];
//                [mDict setValue:intVal forKey:key];
//            }else{
//                NSNumber *doubleVal = [NSNumber numberWithDouble:[[dictionary objectForKey:key] doubleValue]];
//                [mDict setValue:doubleVal forKey:key];
//            }
//        }
//        [array addObject:mDict];
//        return 0;
//    }];
//    [db close];
//    NSError *error;
//    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array
//                                                        options:0//NSJSONWritingPrettyPrinted
//                         // Pass 0 if you don't care about the readability of the generated string
//                                                          error:&error];
//    NSString* jsonString = @"";
//    if (! jsonData) {
//        NSLog(@"Got an error: %@", error);
//    } else {
//        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
//        NSLog(@"%@", jsonString);
//    }
//    
//    NSString *post = [NSString stringWithFormat:@"data=%@", jsonString];
//    NSData *postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//    NSString *postLength = [NSString stringWithFormat:@"%ld", [postData length]];
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
//    [request setURL:[NSURL URLWithString:url]];
//    [request setHTTPMethod:@"POST"];
//    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//    //        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
//    [request setHTTPBody:postData];
//    
//    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
//    bool appState = [defaults boolForKey:@"APP_STATE"];
//    //    if (appState) {
//    //        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
//    //            NSError *error = nil;
//    //            NSHTTPURLResponse *response = nil;
//    //            NSData *resData = [NSURLConnection sendSynchronousRequest:request
//    //                                                    returningResponse:&response error:&error];
//    //            int responseCode = (int)[response statusCode];
//    //            dispatch_async(dispatch_get_main_queue(), ^{
//    //                if(responseCode == 200){
//    //                    NSLog(@"UPLOADED PED DATA TO A SERVER");
//    //                    [db open];
//    //                    NSString * sql = [NSString stringWithFormat:@"delete from ped where unixtime < %f;", nowUnixtime];
//    //                    bool success = [db executeStatements:sql];
//    //                    [db close];
//    //                    if (success) {
//    //                        NSLog(@"%d: Old ped data is removed.", responseCode);
//    //                    }
//    //                }
//    //            });
//    //        });
//    //    }else{
//    //        NSError *error = nil;
//    NSHTTPURLResponse *response = nil;
//    NSData *resData = [NSURLConnection sendSynchronousRequest:request
//                                            returningResponse:&response error:&error];
//    int responseCode = (int)[response statusCode];
//    if(responseCode == 200){
//        NSLog(@"UPLOADED PED DATA TO A SERVER");
//        [db open];
//        NSString * sql = [NSString stringWithFormat:@"delete from ped where unixtime < %f;", nowUnixtime];
//        bool success = [db executeStatements:sql];
//        [db close];
//        if (success) {
//            NSLog(@"%d: Old ped data is removed.", responseCode);
//            return YES;
//        }
//    }
//    return NO;
//    //    }
//    
//}

@end


