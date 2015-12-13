//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif




@class MSBError;

@interface MSBColor : NSObject<NSCopying>


#if TARGET_OS_IPHONE

+ (instancetype)colorWithUIColor:(UIColor *)color error:(NSError **)pError;
- (UIColor *)UIColor;

#else

+ (instancetype)colorWithNSColor:(NSColor *)color error:(NSError **)pError;
- (NSColor *)NSColor;

#endif

+ (instancetype)colorWithRed:(NSUInteger)red green:(NSUInteger)green blue:(NSUInteger)blue;

- (BOOL)isEqualToColor:(MSBColor *)color;

@end
