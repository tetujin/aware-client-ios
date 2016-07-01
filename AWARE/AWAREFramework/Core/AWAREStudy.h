//
//  AWAREStudy.h
//  AWARE for OSX
//
//  Created by Yuuki Nishiyama on 12/5/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <sys/utsname.h>

//    int frequencyCleanOldData; // (0 = never, 1 = weekly, 2 = monthly, 3 = daily, 4 = always)

typedef enum: NSInteger {
    cleanOldDataTypeNever = 0,
    cleanOldDataTypeWeekly = 1,
    cleanOldDataTypeMonthly = 2,
    cleanOldDataTypeDaily = 3,
    cleanOldDataTypeAlways = 4
} cleanOldDataType;

@interface AWAREStudy : NSObject <NSURLSessionDataDelegate, NSURLSessionTaskDelegate>

@property (strong, nonatomic) NSString* getSettingIdentifier;
@property (strong, nonatomic) NSString* makeDeviceTableIdentifier;
@property (strong, nonatomic) NSString* addDeviceTableIdentifier;

- (instancetype) initWithReachability: (BOOL) reachabilityState;

- (BOOL) setStudyInformationWithURL:(NSString*)url;
- (BOOL) refreshStudy;
- (BOOL) clearAllSetting;
- (void) refreshAllSetting;

// Getter
- (NSString *) getDeviceId;
- (NSString* ) getMqttServer;
- (NSString* ) getMqttUserName;
- (NSString* ) getMqttPassowrd;
- (NSNumber* ) getMqttPort;
- (NSNumber* ) getMqttKeepAlive;
- (NSNumber* ) getMqttQos;
- (NSString* ) getStudyId;
- (NSString* ) getWebserviceServer;

- (NSString *) getStudyConfigurationAsText;

// Sensor and plugin infromation
- (NSArray *) getSensors;
- (NSArray *) getPlugins;

// Check some thing
- (BOOL) isAvailable;
- (bool) isWifiReachable;
- (NSString *) getNetworkReachabilityAsText;
- (cleanOldDataType) getCleanOldDataType;
- (NSInteger) getMaxFetchSize;

@end
