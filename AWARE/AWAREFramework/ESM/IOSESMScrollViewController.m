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
#import "EntityESMHistory.h"

#import "BaseESMView.h"
#import "ESMFreeTextView.h"
#import "ESMLikertScaleView.h"
#import "ESMRadioView.h"
#import "ESMCheckBoxView.h"
#import "ESMQuickAnswerView.h"
#import "ESMScaleView.h"
#import "ESMDateTimePickerView.h"
#import "ESMNumberView.h"
#import "ESMWebView.h"
#import "ESMPAMView.h"
#import "ESMClockTimePickerView.h"
#import "ESMPictureView.h"
#import "ESMVideoView.h"
#import "ESMAudioView.h"

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
    NSMutableArray* numberViews;
    
    int esmNumber;
    
    // for ESM flows
    // NSMutableArray * nextESMs;
    bool flowsFlag;
    NSNumber * previousInterfaceType;
    
    NSObject * observer;
    NSObject * quickBtnObserver;
    
    NSString * appIntegration;
}
@end

@implementation IOSESMScrollViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    AWARECore * core = delegate.sharedAWARECore;
    study = core.sharedAwareStudy;
    
    flowsFlag = NO;
    
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
                                    
                                    NSLog(@"[App Integration] %@", appIntegration);
                                    
                                    ////////////////////////////////////////////////
                                    // AppIntegration
                                    if (appIntegration != nil) {
                                        NSURL *url = [NSURL URLWithString:appIntegration];
                                        ////////  a valid url scheme /////////
                                        // if ([[UIApplication sharedApplication] canOpenURL:url]) {
                                            
                                            @try {
                                                [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:^(BOOL success) {
                                                    if (success) {
                                                        NSLog(@"App Integration is succeeded.");
                                                    }else{
                                                        NSLog(@"App Integratioin is failed.");
                                                    }
                                                }];
                                            } @catch (NSException *exception) {
                                                NSLog(@"%@", exception.debugDescription);
                                            }
                                            
                                        /////// an invalied url scheme //////////
                                        //}else{
//                                            if(![appIntegration isEqualToString:@""]){
//                                                NSLog(@"%@ is an invalied url scheme.", appIntegration);
//                                                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"App Integration Error"
//                                                                                                 message:[NSString stringWithFormat:@"%@ is an invalid url scheme.",appIntegration]
//                                                                                                delegate:nil
//                                                                                       cancelButtonTitle:@"close"
//                                                                                       otherButtonTitles:nil];
//                                                [alert show];
//                                            }
//                                        }
                                    }
                                    appIntegration = nil;
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
    quickBtnObserver = [[NSNotificationCenter defaultCenter] addObserverForName:ACTION_AWARE_PUSHED_QUICK_ANSWER_BUTTON
                                                                        object:nil
                                                                        queue:nil
                                                                        usingBlock:^(NSNotification *notif) {
                                                                            [self pushedSubmitButton:nil];
                                                                        }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    esmCells = [[NSMutableArray alloc] init];
    // Remove all UIView contents from super view (_mainScrollView).
    for (UIView * view in _mainScrollView.subviews) {
        [view removeFromSuperview];
    }
    totalHight = 0;
    
    freeTextViews = [[NSMutableArray alloc] init];
    sliderViews   = [[NSMutableArray alloc] init];
    numberViews   = [[NSMutableArray alloc] init];
    NSString * finalBtnLabel = @"Submit";
    NSString * cancelBtnLabel = @"Cancel";
    
    bool isQuickAnswer = NO;
    
    ///////////////////////////////////////////////////////////////
    if(!flowsFlag){ /// normal case
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
                previousInterfaceType = @1;
                // Submit button be shown if the element is the last one.
                // [self setSubmitButton];
                self.navigationItem.title = [NSString stringWithFormat:@"%@ - %d/%ld",
                                             esmSchedule.schedule_id,
                                             currentESMScheduleNumber+1,
                                             esmSchedules.count];
                
                
                for (EntityESM * esm in _esms) {
                    [self addAnESM:esm];
                    if([esm.esm_type isEqualToNumber:@5]){
                        isQuickAnswer = YES;
                    }
                }
                /////// interface 0 //////
            }else{
                previousInterfaceType = @0;
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
                if([esm.esm_type isEqualToNumber:@5]){
                    isQuickAnswer = YES;
                }
            }
            
        }
    ///////////////////////////////////////////////////////////////
    }else{ /// ESMs by esm_flows exist
        @try {
            NSArray * nextESMs = [self getNextESMsFromDB];
            
            for (EntityESM * esm in nextESMs) {
                NSLog(@"%@",esm.esm_title);
                [self addAnESM:esm];
                finalBtnLabel = esm.esm_submit;
                if([esm.esm_type isEqualToNumber:@5]){
                    isQuickAnswer = YES;
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@", exception.debugDescription);
        } @finally {
        }
    }
    
    if(!isQuickAnswer){
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
        [cancelBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
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
        [submitBtn.titleLabel setFont:[UIFont systemFontOfSize:20]];
        [submitBtn addTarget:self action:@selector(pushedSubmitButton:) forControlEvents:UIControlEventTouchUpInside];
        [_mainScrollView addSubview:submitBtn];
        
        [self setContentSizeWithAdditionalHeight: 15 + 60 + 20];
    }
}

- (void)viewDidDisappear:(BOOL)animated{
    if (observer != nil) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        [[NSNotificationCenter defaultCenter] removeObserver:quickBtnObserver];
        
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
    } else if(esmType == 4){
        esmView = [[ESMLikertScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 5){
        esmView = [[ESMQuickAnswerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 6){
        esmView = [[ESMScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [sliderViews addObject:esmView];
    } else if(esmType == 7){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100)
                                                           esm:esm uiMode:UIDatePickerModeDateAndTime
                                                       version:1];
    } else if(esmType == 8){
        esmView = [[ESMPAMView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 9){
        esmView = [[ESMNumberView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [numberViews addObject:esmView];
    } else if(esmType == 10){
        esmView = [[ESMWebView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 11){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100)
                                                           esm:esm uiMode:UIDatePickerModeDate
                                                       version:1];
    } else if(esmType == 12){
        esmView = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100)
                                                           esm:esm
                                                        uiMode:UIDatePickerModeTime
                                                       version:1];
    } else if(esmType == 13){
        esmView = [[ESMClockTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 14){ // picture
        esmView = [[ESMPictureView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 15){ // voice
        esmView = [[ESMAudioView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    } else if(esmType == 16){ // video
        esmView = [[ESMVideoView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
    }
    
    
    ////////////////
    
    if(esmView != nil){
        [_mainScrollView addSubview:esmView];
        [self setContentSizeWithAdditionalHeight:esmView.frame.size.height];
        
        [esmCells addObject:esmView];
    }
}


-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    @try {
        for (ESMFreeTextView *freeTextView in freeTextViews) {
            [freeTextView.freeTextView resignFirstResponder];
        }
        
        for (ESMScaleView * scaleView in sliderViews) {
            [scaleView.valueLabel resignFirstResponder];
        }
        
        for (ESMNumberView * numberView in numberViews) {
            [numberView.freeTextView resignFirstResponder];
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
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    NSMergePolicy *originalMergePolicy = context.mergePolicy;
    context.mergePolicy = NSOverwriteMergePolicy;
    
    ///////////////
    // nextESMs = [[NSMutableArray alloc] init];
    [self removeTempESMsFromDB];
    flowsFlag = NO;
    @try {
        EntityESMSchedule * entityESMSchedule = (EntityESMSchedule *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMSchedule class])
                                                                                                    inManagedObjectContext:context];
        entityESMSchedule.temporary = @(YES);
        
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
            
            EntityESMAnswer * answer = (EntityESMAnswer *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMAnswer class])
                                                                                        inManagedObjectContext:context];
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
            
            //////////////////////////////////////////////////
            entityESMSchedule.fire_hour = [esm.fire_hour copy];
            entityESMSchedule.expiration_threshold = [esm.expiration_threshold copy];
            entityESMSchedule.start_date = [esm.start_date copy];
            entityESMSchedule.end_date = [esm.end_date copy];
            entityESMSchedule.notification_title = [esm.notification_title copy];
            entityESMSchedule.noitification_body = [esm.noitification_body copy];
            entityESMSchedule.randomize_schedule = [esm.randomize_schedule copy];
            entityESMSchedule.schedule_id = [esm.schedule_id copy];
            entityESMSchedule.context = [esm.context copy];
            entityESMSchedule.interface = [esm.interface copy];
            
            // NSLog(@"[esm_app_integration] %@", [esmView.esmEntity.esm_app_integration copy]);
            appIntegration = esm.esm_app_integration;
            
            if (esm.esm_flows != nil) {
                bool isFlows = [self addNextESMs:esm withAnswer:answer context:context tempSchedule:entityESMSchedule];
                if (isFlows) {
                    flowsFlag = YES;
                }
            }
        }
            
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.debugDescription);
    } @finally {
        
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
        
        /// for appearing esms by esm_flows ///
        if(flowsFlag){
            [self viewDidAppear:NO];
            return;
        }
        
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
- (bool) addNextESMs:(EntityESM *)esm
          withAnswer:(EntityESMAnswer *) answer
             context:(NSManagedObjectContext *) context
        tempSchedule:(EntityESMSchedule *) entityESMSchedule {
    NSString * flowsStr = esm.esm_flows;
    
    NSError *e = nil;
    NSArray * flowsArray = [NSJSONSerialization JSONObjectWithData:[flowsStr dataUsingEncoding:NSUTF8StringEncoding]
                                                         options:NSJSONReadingAllowFragments
                                                           error:&e];
    if ( e != nil) {
        NSLog(@"ERROR: %@", e.debugDescription);
        return nil;
    }
    if(flowsArray == nil){
        NSLog(@"ERROR: web esm array is null.");
        return nil;
    }
    ////////////////////////////////////////
    bool flag = NO;
    int number = 0;
    // NSMutableArray * tempESMs = [[NSMutableArray alloc] init];
    for (NSDictionary * aFlow in flowsArray) {
        NSDictionary * nextESM   = [aFlow objectForKey:@"next_esm"];
        NSString * triggerAnswer = [aFlow objectForKey:@"user_answer"];
        if (triggerAnswer != nil && answer.esm_user_answer != nil) {
            ////////// if the user_answer and key is the same, an esm in the flows is stored ///////////
            if([triggerAnswer isEqualToString:answer.esm_user_answer] || [triggerAnswer isEqualToString:@"*"]){
                
                NSDictionary * esmDict = [nextESM objectForKey:@"esm"];
                if(esm != nil){
                    // EntityESM * entityEsm = [[EntityESM alloc] init];
                    number++;
                    EntityESM * entityEsm = (EntityESM *) [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESM class])
                                                                                        inManagedObjectContext:context];
                    entityEsm.timestamp = esm.timestamp;
                    entityEsm.esm_type   = [esmDict objectForKey:@"esm_type"];
                    
                    entityEsm.esm_title  = [esmDict objectForKey:@"esm_title"];
                    entityEsm.esm_submit = [esmDict objectForKey:@"esm_submit"];
                    entityEsm.esm_instructions = [esmDict objectForKey:@"esm_instructions"];
                    entityEsm.esm_radios     = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_radios"]];
                    entityEsm.esm_checkboxes = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_checkboxes"]];
                    entityEsm.esm_likert_max = [esmDict objectForKey:@"esm_likert_max"];
                    entityEsm.esm_likert_max_label = [esmDict objectForKey:@"esm_likert_max_label"];
                    entityEsm.esm_likert_min_label = [esmDict objectForKey:@"esm_likert_min_label"];
                    entityEsm.esm_likert_step = [esmDict objectForKey:@"esm_likert_step"];
                    entityEsm.esm_quick_answers = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_quick_answers"]];
                    entityEsm.esm_expiration_threshold = [esmDict objectForKey:@"esm_expiration_threshold"];
                    // entityEsm.esm_status    = [esm objectForKey:@"esm_status"];
                    entityEsm.esm_status = @0;
                    entityEsm.esm_trigger   = [[esmDict objectForKey:@"esm_trigger"] copy];
                    entityEsm.esm_scale_min = [esmDict objectForKey:@"esm_scale_min"];
                    entityEsm.esm_scale_max = [esmDict objectForKey:@"esm_scale_max"];
                    entityEsm.esm_scale_start = [esmDict objectForKey:@"esm_scale_start"];
                    entityEsm.esm_scale_max_label = [esmDict objectForKey:@"esm_scale_max_label"];
                    entityEsm.esm_scale_min_label = [esmDict objectForKey:@"esm_scale_min_label"];
                    entityEsm.esm_scale_step = [esmDict objectForKey:@"esm_scale_step"];
                    entityEsm.esm_json = [self convertNSArraytoJsonStr:@[esmDict]];
                    entityEsm.esm_number = @(number);
                    // for date&time picker
                    entityEsm.esm_start_time = [esmDict objectForKey:@"esm_start_time"];
                    entityEsm.esm_start_date = [esmDict objectForKey:@"esm_start_date"];
                    entityEsm.esm_time_format = [esmDict objectForKey:@"esm_time_format"];
                    entityEsm.esm_minute_step = [esmDict objectForKey:@"esm_minute_step"];
                    // for web ESM url
                    entityEsm.esm_url = [esmDict objectForKey:@"esm_url"];
                    // for na
                    entityEsm.esm_na = @([[esmDict objectForKey:@"esm_na"] boolValue]);
                    entityEsm.esm_flows = [self convertNSArraytoJsonStr:[esmDict objectForKey:@"esm_flows"]];
                    entityEsm.esm_app_integration = [esmDict objectForKey:@"esm_app_integration"];
                    
                    [entityESMSchedule addEsmsObject:entityEsm];
                    
                    flag = YES;
                }
            }
        }
    }
    return flag;
}

///////////////////////////////////////////

- (NSArray *) getNextESMsFromDB {
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *req = [[NSFetchRequest alloc] init];
    [req setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class])
                               inManagedObjectContext:delegate.managedObjectContext]];
    // [req setPredicate:[NSPredicate predicateWithFormat:@"(start_date <= %@) AND (end_date >= %@) OR (expiration_threshold=0)", datetime, datetime]];
    [req setPredicate:[NSPredicate predicateWithFormat:@"(temporary == 1)"]];
    NSSortDescriptor *sort = [[NSSortDescriptor alloc] initWithKey:@"start_date" ascending:NO];
//    NSSortDescriptor *sortBySID = [[NSSortDescriptor alloc] initWithKey:@"schedule_id" ascending:NO];
    [req setSortDescriptors:@[sort]];
    
    NSFetchedResultsController *fetchedResultsController
    = [[NSFetchedResultsController alloc] initWithFetchRequest:req
                                          managedObjectContext:delegate.managedObjectContext
                                            sectionNameKeyPath:nil
                                                     cacheName:nil];
    
    NSError *error = nil;
    if (![fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    NSArray *results = [fetchedResultsController fetchedObjects];
//    for (EntityESMSchedule * s in results) {
//        NSLog(@"%@",s.notification_title);
//    }
    
    if(results != nil){
        NSLog(@"Stored ESM Schedules are %ld", results.count);
        NSMutableArray * esms = [[NSMutableArray alloc] init];
        for (EntityESMSchedule * schedule in results) {
            if (schedule != nil) {
                NSSet * childEsms = schedule.esms;
                NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:@"esm_number" ascending:YES];
                NSArray *sortDescriptors = [NSArray arrayWithObjects:sort,nil];
                NSArray *sortedEsms = [childEsms sortedArrayUsingDescriptors:sortDescriptors];
                [esms addObjectsFromArray:sortedEsms];
            }
        }
        return esms;
    }else{
        NSLog(@"Stored ESM Schedule is Null.");
        return @[];
    }
}


- (bool) removeTempESMsFromDB{
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([EntityESMSchedule class]) inManagedObjectContext:delegate.managedObjectContext];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"temporary==1"];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:predicate];
    
    NSError *error;
    NSArray *items = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    for (NSManagedObject *managedObject in items){
        [delegate.managedObjectContext deleteObject:managedObject];
    }
    
    if (error!= nil) {
        return YES;
    }else{
        NSLog(@"%@",error.debugDescription);
        return NO;
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


- (NSString *) convertNSArraytoJsonStr:(NSArray *)array{
    if(array != nil){
        NSError * error;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
        if(error == nil){
            return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        }
    }
    return @"[]";
}


//////////////////////////////////////////////////////////////////////////////////////

- (void) saveESMHistoryWithScheduleId:(NSString *)scheduleId
                     originalFireDate:(NSNumber *)originalFireDate
                            randomize:(NSNumber *)randomize
                             fireDate:(NSNumber *)fireDate
                  expirationThreshold:(NSNumber *)expirationThreshold

{
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    // the status of the ESM (0-new, 1-dismissed, 2-answered, 3-expired) -> Defualt is zero(0).
    NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    context.persistentStoreCoordinator = delegate.persistentStoreCoordinator;
    
    EntityESMHistory * history = (EntityESMHistory *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([EntityESMHistory class])
                                                                                   inManagedObjectContext:context];
    history.schedule_id = scheduleId;//x
    history.original_fire_date = originalFireDate;//x
    history.randomize = randomize; //x
    history.fire_date = fireDate;
    history.expiration_threshold = expirationThreshold;
    
    NSError * error = nil;
    if(![context save:&error]){
        NSLog(@"%@", error.debugDescription);
    }
}


@end
