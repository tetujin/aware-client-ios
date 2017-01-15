//
//  Fitbit.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/01/15.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface Fitbit : AWARESensor

+ (BOOL) handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;
+ (void) setFitbitAccessToken:(NSString *)accessToken;
+ (void) setFitbitUserId:(NSString *)userId;
+ (void) setFibitTokenType:(NSString *)tokenType;
+ (NSString *) getFitbitAccessToken;
+ (NSString *) getFitbitUserId;
+ (NSString *) getFibitTokenType;

@end
