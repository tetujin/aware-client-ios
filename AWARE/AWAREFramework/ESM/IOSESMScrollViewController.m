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

#import "BaseESMView.h"
#import "ESMLikertScaleView.h"
#import "ESMRadioView.h"
#import "ESMFreeTextView.h"
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidAppear:(BOOL)animated{
    
    NSLog(@"--------");
    
    freeTextViews = [[NSMutableArray alloc] init];
    
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
        
        /*
        if([esmSchedule.interface isEqualToNumber:@1]){
            if(sortedEsms!=nil){
                _esms = sortedEsms;
            }
            // self.navigationItem.title = esmSchedule.schedule_id;
            // int tag = 0;
            
            for (EntityESM * esm in sortedEsms) {
                // "interface is 1 (multiple esm)"
                EntityESM * loopESM = esm;
                // The loop is broken if this element 's interface is 0.
                [self setEsm:loopESM withTag:tag button:NO];
                tag++;
            }
            // Submit button be shown if the element is the last one.
            [self setSubmitButton];
            self.navigationItem.title = [NSString stringWithFormat:@"%@ - %d/%ld",
                                         esmSchedule.schedule_id,
                                         currentESMScheduleNumber+1,
                                         esmSchedules.count];
         
        }else{
            [self setEsm:sortedEsms[currentESMNumber] withTag:0 button:YES];
            self.navigationItem.title = [NSString stringWithFormat:@"%@(%d/%ld) - %d/%ld",
                                         esmSchedule.schedule_id,
                                         currentESMNumber+1,
                                         sortedEsms.count,
                                         currentESMScheduleNumber+1,
                                         esmSchedules.count];
        }
        */
        
        _esms = sortedEsms;
    }
    
    for (EntityESM * esm in _esms) {
        
        NSLog(@"title: %@", esm.esm_title);
         // cv1 = [[BaseESMView alloc] initWithFrame:CGRectMake(0, totalHight , self.view.frame.size.width, 300) esm:esm];
//         ESMLikertScaleView * cv1 = [[ESMLikertScaleView alloc] initWithFrame:CGRectMake(0, totalHight , self.view.frame.size.width, 200) esm:esm];
//         [_mainScrollView addSubview:cv1];
//         [self setContentSizeWithAdditionalHeight:cv1.frame.size.height];
//         ESMLikertScaleView * cv2 = [[ESMLikertScaleView alloc] initWithFrame:CGRectMake(0, totalHight , self.view.frame.size.width, 200) esm:esm];
//         [_mainScrollView addSubview:cv2];

//        ESMRadioView * esm1 = [[ESMRadioView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//        
//        ESMRadioView * esm2 = [[ESMRadioView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];
        
        
//        ESMFreeTextView * esm1 = [[ESMFreeTextView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//        
//        ESMFreeTextView * esm2 = [[ESMFreeTextView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];
        
        
//        ESMCheckBoxView * esm1 = [[ESMCheckBoxView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//        
//        ESMCheckBoxView * esm2 = [[ESMCheckBoxView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];

        
//        ESMQuickAnswerView * esm1 = [[ESMQuickAnswerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//
//        ESMQuickAnswerView * esm2 = [[ESMQuickAnswerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];
//
        
//        ESMScaleView * esm1 = [[ESMScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//        
//        ESMScaleView * esm2 = [[ESMScaleView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];
        
//        ESMDateTimePickerView * esm1 = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm uiMode:UIDatePickerModeTime];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//
//        ESMDateTimePickerView * esm2 = [[ESMDateTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm uiMode:UIDatePickerModeDate];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];
        
//        ESMWebView * esm1 = [[ESMWebView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//        
//        ESMWebView * esm2 = [[ESMWebView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];

//        ESMPAMView * esm1 = [[ESMPAMView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm1];
//        [self setContentSizeWithAdditionalHeight:esm1.frame.size.height];
//        
//        ESMPAMView * esm2 = [[ESMPAMView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
//        [_mainScrollView addSubview:esm2];
//        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];
        
        
        ESMClockTimePickerView * esm2 = [[ESMClockTimePickerView alloc] initWithFrame:CGRectMake(0, totalHight, self.view.frame.size.width, 100) esm:esm];
        [_mainScrollView addSubview:esm2];
        [self setContentSizeWithAdditionalHeight:esm2.frame.size.height];

        
        // [freeTextViews addObject:esm1];
        
        break;
    }
}


-(void)onSingleTap:(UITapGestureRecognizer *)recognizer {
    // NSLog(@"Single Tap");
    for (ESMFreeTextView *freeTextView in freeTextViews) {
        [freeTextView.freeTextView resignFirstResponder];
    }
}

-(BOOL) gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if (gestureRecognizer == self.singleTap) {
        return YES;
    }
    return NO;
}


/**
 * This method is managing a total height of the ESM elemetns and a size of the base scroll view. You should call this method if you add a new element to the _mainScrollView.
 */
- (void) setContentSizeWithAdditionalHeight:(int) additionalHeight {
    totalHight += additionalHeight;
    [_mainScrollView setContentSize:CGSizeMake(self.view.frame.size.width, totalHight)];
}





@end
