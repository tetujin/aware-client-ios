//
//  IOSESMTableViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/07/30.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "IOSESMScrollViewController.h"

#import "AppDelegate.h"
#import "AWARECore.h"
#import "AWAREStudy.h"
#import "EntityESM+CoreDataClass.h"
#import "IOSESM.h"
#import "EntityESMAnswer.h"

#import "BaseESMView.h"
#import "ESMFreeTextView.h"
#import "ESMLikertScaleView.h"
#import "ESMRadioView.h"
#import "ESMCheckBoxView.h"
#import "ESMQuickAnswerView.h"
#import "ESMScaleView.h"
#import "ESMDateTimePickerView.h"
#import "ESMWebView.h"
#import "ESMPAMView.h"
#import "ESMClockTimePickerView.h"

@interface IOSESMScrollViewController (){
    AWAREStudy * study;
    IOSESM * iOSESM;
    NSArray * esmSchedules;
    NSMutableArray * esmCells;
    int currentESMNumber;
    int currentESMScheduleNumber;
    int totalHight;
    
    // BaseESMView * cv1;
    NSMutableArray* freeTextViews;
    NSMutableArray* sliderViews;
    
    //
    int esmNumber;
    
    NSObject * observer;
}
@end

@implementation IOSESMScrollViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    study = core.sharedAwareStudy;
    
    iOSESM = [[IOSESM alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
    [iOSESM allowsCellularAccess];
    [iOSESM allowsDateUploadWithoutBatteryCharging];
    
    _esms = [[NSMutableArray alloc] init];
    esmSchedules = [[NSArray alloc] init];
    esmCells = [[NSMutableArray alloc] init];
    
    self.singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onSingleTap:)];
    self.singleTap.delegate = self;
    self.singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.singleTap];
    
    
    observer = [[NSNotificationCenter defaultCenter]
                addObserverForName:ACTION_AWARE_DATA_UPLOAD_PROGRESS
                object:nil
                queue:nil
                usingBlock:^(NSNotification *notif) {
                    if ([[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:SENSOR_PLUGIN_WEB_ESM] ||
                        [[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:@"esms"] ||
                        [[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:SENSOR_PLUGIN_IOS_ESM] ||
                        [[notif.userInfo objectForKey:@"KEY_UPLOAD_SENSOR_NAME"] isEqualToString:SENSOR_PLUGIN_CAMPUS]) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            NSLog(@"%@", notif.debugDescription);
                            
                            BOOL uploadSuccess = [[notif.userInfo objectForKey:@"KEY_UPLOAD_SUCCESS"] boolValue];
                            BOOL uploadFin = [[notif.userInfo objectForKey:@"KEY_UPLOAD_FIN"] boolValue];
                            
                            // uploadSuccess = NO; // ** Just for TEST **
                            
                            if( uploadFin == YES && uploadSuccess == YES ){
                                [SVProgressHUD dismiss];
                                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Submission is succeeded!" message:@"Thank you for your submission." preferredStyle:UIAlertControllerStyleAlert];
                                
                                [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                                    esmNumber = 0;
                                    currentESMNumber = 0;
                                    currentESMScheduleNumber = 0;
                                    [self.navigationController popToRootViewControllerAnimated:YES];
                                }]];
                                [self presentViewController:alertController animated:YES completion:nil];
                                
                                //}else if(uploadFin == YES &&  uploadSuccess == NO){
                            }else if(uploadSuccess == NO){
                                [SVProgressHUD dismiss];
                                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"** Submission is failed! **" message:@"Please submit your answer again." preferredStyle:UIAlertControllerStyleAlert];
                                alertController.view.subviews.firstObject.backgroundColor = [UIColor redColor];
                                alertController.view.subviews.firstObject.layer.cornerRadius = 15;
                                alertController.view.subviews.firstObject.tintColor = [UIColor whiteColor];
                                
                                [alertController addAction:[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
                                    // [self.navigationController popToRootViewControllerAnimated:YES];
                                }]];
                                [self presentViewController:alertController animated:YES completion:nil];
                            }else{
                                
                            }
                        });
                    }
                }];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    // Remove all UIView contents from super view (_mainScrollView).
    for (UIView * view in _mainScrollView.subviews) {
        [view removeFromSuperview];
    }
    // NSLog(@"--------");
    totalHight = 0;
    
    freeTextViews = [[NSMutableArray alloc] init];
    sliderViews   = [[NSMutableArray alloc] init];
    NSString * finalBtnLabel = @"Submit";
    NSString * cancelBtnLabel = @"Cancel";
    
    
    // Get ESM using an ESMStorageHelper
    esmSchedules = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
    if(esmSchedules != nil && esmSchedules.count > currentESMScheduleNumber){
        EntityESMSchedule * esmSchedule = esmSchedules[currentESMScheduleNumber];
        NSLog(@"[interface: %@]", esmSchedule.interface);
        NSSet * childEsms = esmSchedule.esms;
        // NSNumber * interface = schedule.interface;
        NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
        NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
        NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
        
        
        _esms = sortedEsms;
        //// interfacce 1 ////////
        if([esmSchedule.interface isEqualToNumber:@1]){
            // Submit button be shown if the element is the last one.
            // [self setSubmitButton];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %d/%ld",
                                         esmSchedule.schedule_id,
                                         currentESMScheduleNumber+1,
                                         esmSchedules.count];
            
            
            for (EntityESM * esm in _esms) {
                [self addAnESM:esm];
            }
        /////// interface 0 //////
        }else{
            // [self setEsm:sortedEsms[currentESMNumber] withTag:0 button:YES];
            EntityESM * esm = sortedEsms[currentESMNumber];
            [self addAnESM:esm];
            finalBtnLabel = esm.esm_submit;
            self.navigationItem.title = [NSString stringWithFormat:@"%@(%d/%ld) - %d/%ld",
                                         esmSchedule.schedule_id,
                                         currentESMNumber+1,
                                         sortedEsms.count,
                                         currentESMScheduleNumber+1,
                                         esmSchedules.count];
        }
        
    }
    
    ////// add a submit (or next) and a cancel button /////////
    // add a cancel btn
    UIButton * cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(10,
                                                                     totalHight + 15,
                                                                     self.view.frame.size.width/5*2-15,
                                                                     60)];
    [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    cancelBtn.layer.borderColor = [UIColor grayColor].CGColor;
    cancelBtn.layer.borderWidth = 2;
    [cancelBtn setTitle:cancelBtnLabel forState:UIControlStateNormal];
    [cancelBtn setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [cancelBtn addTarget:self action:@selector(pushedCancelButton:) forControlEvents:UIControlEventTouchUpInside];
    [_mainScrollView addSubview:cancelBtn];

    // add a submit btn
    UIButton * submitBtn = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/5*2 + 5,
                                                                     totalHight + 15,
                                                                     self.view.frame.size.width/5*3-15,
                                                                     60)];
    [submitBtn setBackgroundColor:[UIColor darkGrayColor]];
    [submitBtn setTitle:finalBtnLabel forState:UIControlStateNormal];
    [submitBtn addTarget:self action:@selector(pushedSubmitButton:) forControlEvents:UIControlEventTouchUpInside];
    [_mainScrollView addSubview:submitBtn];
    
    [self setContentSizeWithAdditionalHeight: 15 + 60 + 20];
}

- (void)viewDidDisappear:(BOOL)animated{
    if (observer != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

//////////////////////////////////////////////////////////////

- (void) addAnESM:(EntityESM *)esm {
    int esmType = [esm.esm_type intValue];
    BaseESMView * esmView = nil;
    if (esmType == 1) {
        esmView = [[ESMFreeTextView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [freeTextViews addObject:esmView];
    } else if(esmType == 2){
        esmView = [[ESMRadioView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 3){
        esmView = [[ESMCheckBoxView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 5){
        esmView = [[ESMQuickAnswerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 6){
        esmView = [[ESMScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [sliderViews addObject:esmView];
    } else if(esmType == 7){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm uiMode:UIDatePickerModeDateAndTime];
    } else if(esmType == 8){
        esmView = [[ESMPAMView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 9){
        esmView = [[ESMWebView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 10){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm uiMode:UIDatePickerModeDate];
    } else if(esmType == 11){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm uiMode:UIDatePickerModeTime];
    } else if(esmType == 12){
        esmView = [[ESMClockTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 13){ // picture
        
    } else if(esmType == 14){ // voice
        
    } else if(esmType == 15){ // video
        
    }
    [_mainScrollView addSubview:esmView];
    [self setContentSizeWithAdditionalHeight:esmView.frame.size.height];
    
    [esmCells addObject:esmView];
}


-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    @try {
        for (ESMFreeTextView *freeTextView in freeTextViews) {
            [freeTextView.freeTextView resignFirstResponder];
        }
        
        for (ESMScaleView * scaleView in sliderViews) {
            [scaleView.valueLabel resignFirstResponder];
        }
    } @catch (NSException *exception) {
        
    } @finally {
        
    }
    
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.singleTap) {
        return YES;
    }
    return NO;
}


//////////////////////////////////////////

- (void) pushedCancelButton:(id) senser {
    AudioServicesPlaySystemSound(1105);

    //////  interface = 1   ////////////
    EntityESMSchedule * schedule = esmSchedules[currentESMScheduleNumber];
    if([schedule.interface isEqualToNumber:@1]){
        if(currentESMScheduleNumber > 0){
            currentESMScheduleNumber--;
        }else{
            currentESMScheduleNumber = 0;
        }
        if (currentESMScheduleNumber < esmSchedules.count){
            [self viewDidAppear:NO];
            return;
        }else{
            EntityESMSchedule * previousESMSchedule = esmSchedules[currentESMScheduleNumber];
            if( [previousESMSchedule.interface isEqualToNumber:@0] ){
                if(previousESMSchedule.esms.count > 0){
                    currentESMNumber = (int)previousESMSchedule.esms.count - 1;
                }else{
                    currentESMNumber = 0;
                }
            }else{
                currentESMNumber = 0;
            }
            // isDone = YES;
        }
    
    /////  interface = 0 //////////
    }else{
        currentESMNumber--;
        if (currentESMNumber >= 0 ){
            [self viewDidAppear:NO];
            return;
        }else{
            // currentESMNumber = 0;
            if (currentESMScheduleNumber > 0){
                currentESMScheduleNumber--;
                EntityESMSchedule * previousESMSchedule = esmSchedules[currentESMScheduleNumber];
                if( [previousESMSchedule.interface isEqualToNumber:@0] ){
                    if(previousESMSchedule.esms.count > 0){
                        currentESMNumber = (int)previousESMSchedule.esms.count - 1;
                    }else{
                        currentESMNumber = 0;
                    }
                }else{
                    currentESMNumber = 0;
                }
                [self viewDidAppear:NO];
                return;
            }else{
                NSLog(@"This ESM is the first ESM.");
            }
        }
    }
}


- (void) pushedSubmitButton:(id) senser {
    AudioServicesPlaySystemSound(1104);
//    NSNumber *DISMISSED = @1;
//    NSNumber *ANSWERED = @2;
//    NSString * NA = @"NA";
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = NSOverwriteMergePolicy;
    
    for (BaseESMView *esmView in esmCells) {
        // A status of the ESM (0-new, 1-dismissed, 2-answered, 3-expired) -> Defualt is zero(0).
        NSNumber * esmState = [esmView getESMState];
        // A user ansert of the ESM
        NSString * esmUserAnswer = [esmView getUserAnswer];
        // Current time
        NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
        // Device ID
        NSString * deviceId = [study getDeviceId];
        // EntityESM obj
        EntityESM * esm = esmView.esmEntity;
        
        EntityESMAnswer * answer = (EntityESMAnswer *)
        [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswer class])
                                      inManagedObjectContext:context];
        // add special data to dic from each uielements
        
        answer.device_id = deviceId;
        answer.timestamp = esm.timestamp;
        answer.esm_json = esm.esm_json;
        answer.esm_trigger = esm.esm_trigger;
        answer.esm_expiration_threshold = esm.esm_expiration_threshold;
        answer.double_esm_user_answer_timestamp = unixtime;
        answer.esm_user_answer = esmUserAnswer;
        answer.esm_status = esmState;
        
        NSLog(@"--------[%@]---------", esm.esm_trigger);
        NSLog(@"%@", answer.device_id);
        NSLog(@"%@", answer.timestamp);
        NSLog(@"%@", answer.esm_trigger);
        NSLog(@"%@", answer.esm_json);
        NSLog(@"%@", answer.esm_expiration_threshold);
        NSLog(@"%@", answer.double_esm_user_answer_timestamp);
        NSLog(@"%@", answer.esm_status);
        NSLog(@"%@", answer.esm_user_answer);
        NSLog(@"---------------------");
    }
    
    // Save all data to SQLite
    NSError * error = nil;
    bool result = [context save:&error];
    context.mergePolicy = originalMergePolicy;
    if(error != nil){
        NSLog(@"%@", error);
        
        [delegate.managedObjectContext reset];
        
        iOSESM = [[IOSESM alloc] initWithAwareStudy:study dbType:AwareDBTypeCoreData];
        esmSchedules = [iOSESM getValidESMSchedulesWithDatetime:[NSDate new]];
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"AWARE can not save your answer" message:@"Please push submit button again." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    
    ////////////////////////////////////////
    // Check an exist of next ESM
    if ( result ) {
        //////  interface = 1   ////////////
        EntityESMSchedule * schedule = esmSchedules[currentESMScheduleNumber];
        bool isDone = NO;
        if([schedule.interface isEqualToNumber:@1]){
            currentESMScheduleNumber++;
            if (currentESMScheduleNumber < esmSchedules.count){
                [self viewDidAppear:NO];
                return;
            }else{
                isDone = YES;
            }
            /////  interface = 0 //////////
        }else{
            currentESMNumber++;
            if (currentESMNumber < schedule.esms.count){
                [self viewDidAppear:NO];
                return;
            }else{
                currentESMScheduleNumber++;
                if (currentESMScheduleNumber < esmSchedules.count){
                    currentESMNumber = 0;
                    [self viewDidAppear:NO];
                    return;
                }else{
                    isDone = YES;
                }
            }
        }
        
        ///////////////////////
        
        if(isDone){
            if([study getStudyId] == nil){
                esmNumber = 0;
                currentESMNumber = 0;
                currentESMScheduleNumber = 0;
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Thank you for your answer!"
                                                                message:nil delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
                [alert show];
                [self.navigationController popToRootViewControllerAnimated:YES];
            }else{
                if([delegate.sharedAWARECore.sharedSensorManager isExist:SENSOR_PLUGIN_IOS_ESM]){
                    [SVProgressHUD showWithStatus:@"uploading"];
                    [iOSESM setUploadingState:NO];
                    [iOSESM syncAwareDB];
                    [iOSESM refreshNotifications];
                }
            }
        }
    } else {
        
    }
}

///////////////////////////////////////////


/**
 * This method is managing a total height of the ESM elemetns and a size of the base scroll view. You should call this method if you add a new element to the _mainScrollView.
 */
- (void) setContentSizeWithAdditionalHeight:(int) additionalHeight {
    totalHight += additionalHeight;
    [_mainScrollView setContentSize:CGSizeMake(self.view.frame.size.width, totalHight)];
}





@end
