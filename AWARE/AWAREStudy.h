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

@interface AWAREStudy : NSObject

- (BOOL) setStudyInformationWithURL:(NSString*)url;

// for check
- (BOOL) isAvailable;
- (BOOL) clearAllSetting;

// MQTT Information
- (NSString* ) getMqttServer;
- (NSString* ) getMqttUserName;
- (NSString* ) getMqttPassowrd;
- (NSNumber* ) getMqttPort;
- (NSNumber* ) getMqttKeepAlive;
- (NSNumber* ) getMqttQos;

// Study Information
- (NSString* ) getStudyId;
- (NSString* ) getWebserviceServer;

// Sensor Infromation
- (NSArray *) getSensors;
- (NSArray *) getPlugins;

@end
