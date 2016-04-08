//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#import "MSBPageEnums.h"
#import "MSBPageRect.h"
#import "MSBPageMargins.h"
#import "MSBColor.h"

@interface MSBPageElement : NSObject

/**
 * an unique identifier for Band to identify a page element.
 */
@property (nonatomic, assign) MSBPageElementIdentifier      elementId;
@property (nonatomic, strong) MSBPageRect                  *rect;
@property (nonatomic, strong) MSBPageMargins               *margins;
@property (nonatomic, assign) MSBPageHorizontalAlignment    horizontalAlignment;
@property (nonatomic, assign) MSBPageVerticalAlignment      verticalAlignment;
@property (nonatomic, assign) BOOL      visible;

@end
