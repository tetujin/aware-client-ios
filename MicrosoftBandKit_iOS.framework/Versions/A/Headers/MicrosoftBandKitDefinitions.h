//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

#ifndef CargoKit_MicrosoftBandKitDefinitions_h
#define CargoKit_MicrosoftBandKitDefinitions_h

#ifdef __OBJC__

#import <Foundation/Foundation.h>

#if (TARGET_OS_MAC && !(TARGET_OS_EMBEDDED || TARGET_OS_IPHONE))
#define TARGET_OSX 1
#define SDK_BUNDLE_IDENTIFIER @"com.microsoft.MicrosoftBandKit-iOS"
#endif

#if (TARGET_OS_IPHONE)
#define TARGET_IOS 1
#define SDK_BUNDLE_IDENTIFIER @"com.microsoft.MicrosoftBandKit-iOS"
#endif

#endif

#endif
