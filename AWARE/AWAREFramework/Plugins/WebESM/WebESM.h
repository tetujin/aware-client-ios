//
//  WebESM.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 7/8/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"


@interface WebESM : AWARESensor <AWARESensorDelegate, NSURLSessionDataDelegate> //NSURLSessionTaskDelegate

- (NSArray *) getValidESMsWithDatetime:(NSDate *) datetime;
- (void) setNotificationSchedules;
- (void) removeNotificationSchedules;
- (void) refreshNotifications;
@end
