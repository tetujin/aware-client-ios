//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import "MicrosoftBandKitDefinitions.h"
#import <Foundation/Foundation.h>

#if TARGET_IOS
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@class MSBImage;

@interface MSBIcon : NSObject

@property(nonatomic, assign, readonly)      CGSize      size;

+ (MSBIcon *)iconWithMSBImage:(MSBImage *)image error:(NSError **)pError;

#if TARGET_IOS

+ (MSBIcon *)iconWithUIImage:(UIImage *)image error:(NSError **)pError;
- (UIImage *)UIImage;

#else

+ (MSBIcon *)iconWithNSImage:(NSImage *)image error:(NSError **)pError;
- (NSImage *)NSImage;

#endif


@end
