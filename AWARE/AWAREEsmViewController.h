//
//  AWAREEsmViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 12/15/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AWAREScheduleManager.h"

extern NSString* const KEY_ESM_TYPE;
extern NSString* const KEY_ESM_TITLE;
extern NSString* const KEY_ESM_SUBMIT;
extern NSString* const KEY_ESM_INSTRUCTIONS;
extern NSString* const KEY_ESM_RADIOS;
extern NSString* const KEY_ESM_CHECKBOXES;
extern NSString* const KEY_ESM_LIKERT_MAX;
extern NSString* const KEY_ESM_LIKERT_MAX_LABEL;
extern NSString* const KEY_ESM_LIKERT_MIN_LABEL;
extern NSString* const KEY_ESM_LIKERT_STEP;
extern NSString* const KEY_ESM_QUICK_ANSWERS;
extern NSString* const KEY_ESM_EXPIRATION_THRESHOLD;
extern NSString* const KEY_ESM_STATUS;
extern NSString* const KEY_DOUBLE_ESM_USER_ANSWER_TIMESTAMP;
extern NSString* const KEY_ESM_USER_ANSWER;
extern NSString* const KEY_ESM_TRIGGER;
extern NSString* const KEY_ESM_SCALE_MIN;
extern NSString* const KEY_ESM_SCALE_MAX;
extern NSString* const KEY_ESM_SCALE_START;
extern NSString* const KEY_ESM_SCALE_MAX_LABEL;
extern NSString* const KEY_ESM_SCALE_MIN_LABEL;
extern NSString* const KEY_ESM_SCALE_STEP;

@interface AWAREEsmViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UIGestureRecognizerDelegate>


@property (weak, nonatomic) IBOutlet UIScrollView *mainScrollView;
@property(nonatomic, strong) UITapGestureRecognizer *singleTap;
@property (weak, nonatomic) IBOutlet AWAREScheduleManager* scheduleManager;

@end
