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

// int frequencyCleanOldData; // (0 = never, 1 = weekly, 2 = monthly, 3 = daily, 4 = always)

typedef enum: NSInteger {
    cleanOldDataTypeNever = 0,
    cleanOldDataTypeWeekly = 1,
    cleanOldDataTypeMonthly = 2,
    cleanOldDataTypeDaily = 3,
    cleanOldDataTypeAlways = 4
} cleanOldDataType;

/*
typedef enum: NSInteger {
    dataExportTypeUnknown = 0,
    dataExportTypeForAutoSync = 1,
    dataExportTypeAsCSV  = 2,
    dataExportTypeAsJSON = 3
} dataExportType;
*/

typedef enum: NSInteger {
    AwareDBTypeUnknown  = 0,
    AwareDBTypeTextFile = 1,
    AwareDBTypeCoreData = 2
} AwareDBType;

typedef enum: NSInteger{
    AwareUIModeNormal = 0,
    AwareUIModeHideAll = 1,
    AwareUIModeHideSettings = 2
} AwareUIMode;

@interface AWAREStudy : NSObject <NSURLSessionDataDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, NSURLConnectionDownloadDelegate>

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
- (NSString* ) getStudyURL;

- (void) setDeviceName:(NSString *) deviceName;
- (NSString *) getDeviceName;

- (NSString *) getStudyConfigurationAsText;

// Sensor and plugin infromation
- (NSArray *) getSensors;
- (NSArray *) getPlugins;
- (NSArray *) getPluginSettingsWithKey:(NSString *) key;


- (BOOL) isSensorSettingWithKey:(NSString *)key;

// - (void) setUserSettingWithNumber:(NSNumber *)number key:(NSString*)key;
- (void) setUserSensorSettingWithString:(NSString *)str  key:(NSString *)key;
- (void) setUserPluginSettingWithString:(NSString *)str  key:(NSString *)key statusKey:(NSString *)statusKey;

// Check some thing
- (BOOL) isAvailable;
- (bool) isNetworkReachable;
- (bool) isWifiReachable;
- (NSString *) getNetworkReachabilityAsText;


////////////////////////////////////
- (void) setDebugState:(bool)state;
- (void) setDataUploadStateInWifiAndMobileNetwork:(bool)state;
- (void) setDataUploadStateInWifi:(bool)state;
- (void) setDataUploadStateWithOnlyBatterChargning:(bool)state;
- (void) setUploadIntervalWithMinutue:(int)min;
- (void) setMaximumByteSizeForDataUpload:(NSInteger)size;  // for Text File
- (void) setMaximumNumberOfRecordsForDataUpload:(NSInteger)number;  // for SQLite DB
- (void) setDBType:(AwareDBType)type;
- (void) setCleanOldDataType:(cleanOldDataType)type;
- (void) setCSVExport:(bool)state;
- (void) setUIMode:(AwareUIMode) mode;

/////////////////////////////////////
- (bool) getDebugState;
- (bool) getDataUploadStateInWifi;
- (bool) getDataUploadStateWithOnlyBatterChargning;
- (int) getUploadIntervalAsSecond;
- (NSInteger) getMaximumByteSizeForDataUpload;  // for Text File
- (NSInteger) getMaxFetchSize;
- (AwareDBType) getDBType;
- (cleanOldDataType) getCleanOldDataType;
- (bool) getCSVExport;
- (AwareUIMode) getUIMode;

@end
