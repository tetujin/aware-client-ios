//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import <Foundation/Foundation.h>

@class MSBImage;
@class MSBTheme;

@protocol MSBPersonalizationManagerProtocol <NSObject>

/**
 * set the specified image to the band.
 */
- (void)updateMeTileImage:(MSBImage *)image completionHandler:(void (^) (NSError *error))completionHandler;

/**
 * get the current Me Tile image from the band.
 * @return image the current Me Tile Image. if there is no Me Tile on the band, the error and image should both be nil.
 */
- (void)meTileImageWithCompletionHandler:(void (^) ( MSBImage *image, NSError *error))completionHandler;

- (void)updateTheme:(MSBTheme *)theme completionHandler:(void (^) (NSError *error))completionHandler;
- (void)themeWithCompletionHandler:(void (^) (MSBTheme *theme, NSError *error))completionHandler;

@end