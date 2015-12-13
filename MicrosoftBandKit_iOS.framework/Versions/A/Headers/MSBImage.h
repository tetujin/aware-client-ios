//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import <Foundation/Foundation.h>
#import "MicrosoftBandKitDefinitions.h"

#if TARGET_IOS
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@interface MSBImage : NSObject

@property (nonatomic, readonly) CGSize size;

- (instancetype)initWithContentsOfFile:(NSString *)path;

#if TARGET_IOS
- (instancetype)initWithUIImage:(UIImage *)image;
- (UIImage *)UIImage;
#else
- (instancetype)initWithNSImage:(NSImage *)image;
- (NSImage *)NSImage;
#endif

@end