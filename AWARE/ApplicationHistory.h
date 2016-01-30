//
//  ApplicationHistory.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 1/27/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"

@interface ApplicationHistory : AWARESensor <AWARESensorDelegate>

- (bool) storeApplicationEvent:(NSString*) event;

@end
