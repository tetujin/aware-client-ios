//----------------------------------------------------------------
//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//
//----------------------------------------------------------------

typedef NS_ENUM(NSUInteger, MSBNotificationVibrationType)
{
    MSBNotificationVibrationTypeOneTone             = 0x07,
    MSBNotificationVibrationTypeTwoTone             = 0x10,
    MSBNotificationVibrationTypeAlarm               = 0x11,
    MSBNotificationVibrationTypeTimer               = 0x12,
    MSBNotificationVibrationTypeOneToneHigh         = 0x1B,
    MSBNotificationVibrationTypeTwoToneHigh         = 0x1D,
    MSBNotificationVibrationTypeThreeToneHigh       = 0x1C,
    MSBNotificationVibrationTypeRampUp              = 0x05,
    MSBNotificationVibrationTypeRampDown            = 0x04
};


typedef NS_ENUM(UInt8, MSBNotificationMessageFlags)
{
    MSBNotificationMessageFlagsNone                     = 0,
    MSBNotificationMessageFlagsShowDialog               = 1,
};

@protocol MSBNotificationManagerProtocol <NSObject>

/**
 Sent a customized vibration to Band.
 @vibrationType     see MSBVibrationType
 */
- (void)vibrateWithType:(MSBNotificationVibrationType)vibrationType completionHandler:(void (^) (NSError *error))completionHandler;

/**
 Show a pop up Dialog Notification to Band. This dialog will disappear either timeout or user dismiss it.
 @tileID        identifier of the Tile which app has added.
 @title         title of the dialog. see MSBNotificationDialogTitleLengthMax
 @body          body of the dialog. see MSBNotificationDialogBodyLengthMax
 */
- (void)showDialogWithTileID:(NSUUID *)tileID title:(NSString *)title body:(NSString *)body completionHandler:(void (^)(NSError *error))completionHandler;

/**
 Send a Message Notification to a Tile on the Band, with the options to include Pop up Dialog.
 @tileID        identifier of the Tile which app has added.
 @title         title of the message. see MSBNotificationMessageTitleLengthMax
 @body          body of the message. see MSBNotificationMessageBodyLengthMax
 @timeStamp     optional timeStamp of the message. Default to [NSDate date]
 @flags         options of the message. see MSBNotificationMessageFlags
 */
- (void)sendMessageWithTileID:(NSUUID *)tileID title:(NSString *)title body:(NSString *)body timeStamp:(NSDate *)timeStamp flags:(MSBNotificationMessageFlags)flags completionHandler:(void (^)(NSError *error))completionHandler;

/**
 register Push Notifications of the current App to Band, Notifications will be sent to specified Tile
 @tileID        identifier of the Tile which app has added.
 */
- (void)registerNotificationWithTileID:(NSUUID *)tileID completionHandler:(void (^)(NSError *error))completionHandler NS_AVAILABLE_IOS(7_0);

/**
 register Push Notifications of the current App to Band, Notifications will be sent to the Tile created by the app.
 @discussion    use this method is the current App only has one Tile on Band. If the app has added more than one Tile, use -registerNotificationWithTileID:completionHandler:.
 */
- (void)registerNotificationWithCompletionHandler:(void (^)(NSError *error))completionHandler NS_AVAILABLE_IOS(7_0);

/**
 Unregister Push Notifications of the current App from the Band.
 */
- (void)unregisterNotificationWithCompletionHandler:(void (^)(NSError *error))completionHandler NS_AVAILABLE_IOS(7_0);

@end