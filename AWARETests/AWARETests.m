//
//  AWARETests.m
//  AWARETests
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <XCTest/XCTest.h>

@interface AWARETests : XCTestCase

@end

@implementation AWARETests

- (void)setUp {
    [super setUp];

    // [self removeAllFilesFromDocumentRoot];

//    study = [[AWAREStudy alloc] initWithReachability:YES];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)testExample {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
//    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
//    [tcqMaker addColumn:@"test" type:TCQTypeText default:@"''"];

}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        
        // Put the code you want to measure the time of here.
    }];
}


- (void) testSensingQualityByAllSensor {
    
    // Set a test study URL
//    NSLog(@"--- start aware study ---");
//    [study setStudyInformationWithURL:@"https://aware.ht.sfc.keio.ac.jp/index.php/webservice/index/11/wVupTkDhRy9z"];
//    NSDate * testStartDate = [NSDate new];
//
//    // Set Delegate
//    AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    AWARESensorManager * sensorManager = delegate.sharedAWARECore.sharedSensorManager;
//
//    NSLog(@"--- start all sensors ---");
//    [sensorManager startAllSensorsWithStudy:study];
//
//    NSLog(@"--- upload sensor data ---");
//    [sensorManager syncAllSensorsWithDBInForeground];
//
//    NSLog(@"--- check latest sensor data---");
//    [self checkStoredData:testStartDate];
//
//    NSLog(@"--- stop all sensor ---");
//    [sensorManager stopAndRemoveAllSensors];
//
//    NSLog(@"--- finish a test ---");
}



- (void) checkStoredData:(NSDate *) time {
//    AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//    AWARESensorManager * sensorManager = delegate.sharedAWARECore.sharedSensorManager;
//    for (AWARESensor * sensor in [sensorManager getAllSensors]) {
//        NSData * data = [sensor getLatestData];
//        // XCTAssertNotNil(data);
//        if(data != nil){
//            NSError *error = nil;
//            NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData: data options: NSJSONReadingMutableContainers error: &error];
//            //XCTAssertNotNil(error);
//            if(error != nil){
//                NSLog(@"error: %@", error.debugDescription);
//            }
//            if(jsonArray != nil){
//                for (NSDictionary * dict in jsonArray) {
//                    NSNumber * timestamp = [dict objectForKey:@"timestamp"];
//                    XCTAssertNotNil(timestamp);
//                    if(timestamp != nil){
//                        NSNumber * startTime = [AWAREUtils getUnixTimestamp:time];
//                        NSLog(@"[%@] %@ <---> %@", [sensor getSensorName], timestamp, startTime);
//                        //XCTAssertLessThan(startTime, timestamp);
//                    }
//                }
//            }else{
//                NSLog(@"[%@] ERROR", [sensor getSensorName]);
//            }
//        }else{
//            NSLog(@"[%@] ERROR", [sensor getSensorName]);
//        }
//        // NSLog(@"[%@] %@", [sensor getSensorName], );
//    }
}


- (void) testSensorInitializations {
    
//    // XCTAssertEqualObjects([calcViewController.displayField stringValue], @"8", @"Part 1 failed.");
//    AWARESensor * sensor = [[AWARESensor alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
//    XCTAssertFalse([sensor startSensor]);
//
//    //////////////////////////////////////////////////////////
//    AWARESensor * accSensor = [[Accelerometer alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
//    XCTAssertTrue([accSensor startSensor]);
//    XCTAssertTrue([accSensor stopSensor]);
//    XCTAssertEqual(0, [accSensor getBufferSize]);
//
//    //////////////////////////////////////////////////////////
//    accSensor = [[Accelerometer alloc] initWithAwareStudy:study sensorName:@"accelerometer" dbEntityName:NSStringFromClass([EntityAccelerometer class]) dbType:AwareDBTypeCoreData bufferSize:100];
//    XCTAssertTrue([accSensor startSensor]);
//    XCTAssertTrue([accSensor stopSensor]);
//    // Test buffer settings (check default value)
//    XCTAssertEqual(100, [accSensor getBufferSize]);
//    // Test buffer settings (check user value)
//    [accSensor setBufferSize:10];
//    XCTAssertEqual(10, [accSensor getBufferSize]);
}



//- (void) testInitCoreDataManager {
//
//}
//
//
//
//- (void)removeAllFilesFromDocumentRoot{
//    NSFileManager   *fileManager    = [NSFileManager defaultManager];
//    NSArray         *ducumentDir    =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString        *docRoot        = [ducumentDir objectAtIndex:0];
//    NSError * error = nil;
//    for ( NSString *dirName  in [fileManager contentsOfDirectoryAtPath:docRoot error:&error] )
//        [self removeFilePath:[NSString stringWithFormat:@"%@/%@",docRoot, dirName]];
//}
//
//- (BOOL)removeFilePath:(NSString*)path {
//    NSLog(@"Remove => %@", path);
//    NSFileManager *fileManager = [[NSFileManager alloc] init];
//    return [fileManager removeItemAtPath:path error:NULL];
//}


- (void) testSyncCoreData{
    
//    dispatch_async(dispatch_get_main_queue(), ^{
//        AppDelegate * delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
//        AWAREStudy * study = delegate.sharedAWARECore.sharedAwareStudy;
//
//        [study setCleanOldDataType:cleanOldDataTypeAlways];
//        [study setMaximumNumberOfRecordsForDataUpload:10];
//        
//        AWARESensor * battery = [[Battery alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
//        [battery startSensor];
//
//        for (int i=0; i<10000; i++) {
//            [battery saveDummyData];
//        }
//
//        [battery syncAwareDBInForeground];
//    });
}


@end
