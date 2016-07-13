//
//  AWARETests.m
//  AWARETests
//
//  Created by Yuuki Nishiyama on 11/18/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "AWARESensor.h"
#import "AWAREStudy.h"
#import "Accelerometer.h"
#import "EntityAccelerometer.h"

@interface AWARETests : XCTestCase{
    AWAREStudy * study;
}

@end

@implementation AWARETests

- (void)setUp {
    [super setUp];
    study = [[AWAREStudy alloc] initWithReachability:YES];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

//- (void)testExample {
//    // This is an example of a functional test case.
//    // Use XCTAssert and related functions to verify your tests produce the correct results.
////    TCQMaker * tcqMaker = [[TCQMaker alloc] init];
////    [tcqMaker addColumn:@"test" type:TCQTypeText default:@"''"];
//
//}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        
//        // Put the code you want to measure the time of here.
//    }];
//}

- (void) testSensorInitializations {
    
    // XCTAssertEqualObjects([calcViewController.displayField stringValue], @"8", @"Part 1 failed.");
    AWARESensor * sensor = [[AWARESensor alloc] initWithAwareStudy:study];
    XCTAssertFalse([sensor startSensor]);
    
    //////////////////////////////////////////////////////////
    AWARESensor * accSensor = [[Accelerometer alloc] initWithAwareStudy:study];
    XCTAssertTrue([accSensor startSensor]);
    XCTAssertTrue([accSensor stopSensor]);
    XCTAssertEqual(0, [accSensor getBufferSize]);
    
    //////////////////////////////////////////////////////////
    accSensor = [[Accelerometer alloc] initWithAwareStudy:study sensorName:@"accelerometer" dbEntityName:NSStringFromClass([EntityAccelerometer class]) dbType:AwareDBTypeCoreData bufferSize:100];
    XCTAssertTrue([accSensor startSensor]);
    XCTAssertTrue([accSensor stopSensor]);
    // Test buffer settings (check default value)
    XCTAssertEqual(100, [accSensor getBufferSize]);
    // Test buffer settings (check user value)
    [accSensor setBufferSize:10];
    XCTAssertEqual(10, [accSensor getBufferSize]);
}

- (void) testInitCoreDataManager {

}



@end
