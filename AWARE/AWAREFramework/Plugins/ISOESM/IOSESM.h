//
//  IOSESM.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 10/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "ESMSchedule.h"

@interface IOSESM : AWARESensor <AWARESensorDelegate>

- (BOOL) setWebESMsWithSchedule:(ESMSchedule *) esmSchedule;
// - (void) setWebESMsWithArray:(NSArray *) webESMArray;

/////////////////////////////////////////////////////////
- (NSArray *) getValidESMsWithDatetime:(NSDate *) datetime;
- (void) saveESMAnswerWithTimestamp:(NSNumber * )timestamp
                           deviceId:(NSString *) deviceId
                            esmJson:(NSString *) esmJson
                         esmTrigger:(NSString *) esmTrigger
             esmExpirationThreshold:(NSNumber *) esmExpirationThreshold
             esmUserAnswerTimestamp:(NSNumber *) esmUserAnswerTimestamp
                      esmUserAnswer:(NSString *) esmUserAnswer
                          esmStatus:(NSNumber *) esmStatus;
- (NSString *) convertNSArraytoJsonStr:(NSArray *)array;
- (void) setNotificationSchedules;
- (void) removeNotificationSchedules;
- (void) refreshNotifications;

/////////////////////////////////
+ (BOOL) isAppearedThisSection;
+ (void) setAppearedState:(BOOL)state;

@end
