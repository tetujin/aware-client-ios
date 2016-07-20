//
//  AmbientLight.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 3/15/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

//
// https://github.com/kennytm/iphone-private-frameworks/tree/master
// http://iphonedevwiki.net/index.php/IOKit.framework
// http://iphonedevwiki.net/index.php/IOHIDFamily

#import "AmbientLight.h"
//#import "IOHIDEventSystem.h"
//#import "stdio.h"

@implementation AmbientLight

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study sensorName:@"light" dbEntityName:@"light" dbType:dbType];
    if (self) {
        
    }
    return self;
}

- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
    return YES;
}

- (BOOL)stopSensor{
    return YES;
}

/////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////


//void handle_event(void* target, void* refcon, IOHIDServiceRef service, IOHIDEventRef event) {
//    if (IOHIDEventGetType(event) == kIOHIDEventTypeAmbientLightSensor) { // Ambient Light Sensor Event
//        int luxValue = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorLevel); // lux Event Field
//        int channel0 = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorRawChannel0); // ch0 Event Field
//        int channel1 = IOHIDEventGetIntegerValue(event, (IOHIDEventField)kIOHIDEventFieldAmbientLightSensorRawChannel1); // ch1 Event Field
//        
//        NSLog(@"IOHID: ALS Sensor: Lux : %d  ch0 : %d   ch1 : %d", luxValue, channel0, channel1);
//        // lux==0 : no light, lux==1000+ almost direct sunlight
//    }
//}



//int getAmbientLightData(){
//    // Create and open an event system.
//    IOHIDEventSystemRef system = IOHIDEventSystemCreate(NULL);
//    
//    // Set the PrimaryUsagePage and PrimaryUsage for the Ambient Light Sensor Service
//    int page = 0xff00;
//    int usage = 4;
//    
//    // Create a dictionary to match the service with
//    CFStringRef keys[2];
//    CFNumberRef nums[2];
//    keys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
//    keys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);
//    nums[0] = CFNumberCreate(0, kCFNumberSInt32Type, &page);
//    nums[1] = CFNumberCreate(0, kCFNumberSInt32Type, &usage);
//    
//    
//    CFDictionaryRef dict = CFDictionaryCreate(0, (const void**)keys, (const void**)nums, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//    
//    // Get all services matching the above criteria
//    CFArrayRef srvs = (CFArrayRef)IOHIDEventSystemCopyMatchingServices(system, dict, 0, 0, 0,0);
//    
//    
//    // Get the service
//    IOHIDServiceRef serv = (IOHIDServiceRef)CFArrayGetValueAtIndex(srvs, 0);
//    int interval = 1 ;
//    
//    // set the ReportInterval of ALS service to something faster than the default (5428500)
//    IOHIDServiceSetProperty((IOHIDServiceRef)serv, CFSTR("ReportInterval"), CFNumberCreate(0, kCFNumberSInt32Type, &interval));
//    
//    IOHIDEventSystemOpen(system, handle_event, NULL, NULL, NULL);
//    printf("HID Event system should now be running. Hit enter to quit any time.\n");
//    getchar();
//    
//    int defaultInterval=5428500;
//    IOHIDServiceSetProperty((IOHIDServiceRef)serv, CFSTR("ReportInterval"), CFNumberCreate(0, kCFNumberSInt32Type, &defaultInterval));
//    
//    IOHIDEventSystemClose(system, NULL);
//    CFRelease(system);
//    return 0;
//}

@end
