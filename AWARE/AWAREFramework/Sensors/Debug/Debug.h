//
//  Debug.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/4/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARESensor.h"
#import "AWAREKeys.h"
//#import <CoreData/CoreData.h>

typedef enum: NSInteger {
    DebugTypeUnknown = 0,
    DebugTypeInfo = 1,
    DebugTypeError = 2,
    DebugTypeWarn = 3,
    DebugTypeCrash = 4
} DebugType;


@interface Debug : AWARESensor <AWARESensorDelegate>

- (instancetype) initWithAwareStudy:(AWAREStudy *) study;

- (void) saveDebugEventWithText:(NSString *)eventText type:(NSInteger)type label:(NSString *) label;
@end
