//
//  DataVisualizationViewController.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import "DataVisualizationViewController.h"
#import "AppDelegate.h"

#import "EntityAccelerometer.h"
#import "EntityBattery.h"
#import "EntityLocation.h"
#import "EntityWifi.h"
#import "EntityActivityRecognition.h"
#import "EntityBarometer.h"
#import "EntityBluetooth.h"
#import "EntityCall.h"
#import "EntityNetwork.h"
#import "EntityFitbitData+CoreDataClass.h"

#import "AWAREUtils.h"
#import "AWAREUtils.h"
#import <SVProgressHUD.h>

@interface DataVisualizationViewController ()

@end

@implementation DataVisualizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewDidAppear:(BOOL)animated{
    NSDate * now = [NSDate new];
    NSNumber * start = [AWAREUtils getUnixTimestamp:[AWAREUtils getTargetNSDate:now hour:0 nextDay:NO]];
    NSNumber * end = [AWAREUtils getUnixTimestamp:[AWAREUtils getTargetNSDate:now hour:0 nextDay:YES]];
    
    if(_sensor == nil){
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
        label.text = @"The selected sensor is null.";
        [self.view addSubview:label];
        return;
    }
    
    // battery
    // locations
    // google_fused_location
    
    NSLog(@"--> %@",[_sensor getSensorName]);
    
    if([[_sensor getSensorName] isEqualToString:@"battery"]){
        [self showBatteryDataWithStart:start end:end];
    }else if([[_sensor getSensorName] isEqualToString:@"locations"]||
             [[_sensor getSensorName] isEqualToString:@"google_fused_location"]){
        [self showLocationDataOnMapWithStart:start end:end];
    }else if([[_sensor getSensorName] isEqualToString:@"plugin_fitbit"]){
        PNScatterChartData * data00 = [PNScatterChartData new];
        data00.strokeColor = PNGreen;
        data00.fillColor = PNFreshGreen;
        data00.size = 1;
        data00.inflexionPointStyle = PNScatterChartPointStyleCircle;
        [self showFitbitChartWithStart:start
                                   end:end
                                  type:@"heartrate"
                                   key:@"activities-heart-intraday"
                               xLabels:@[@"0:00", @"6:00", @"12:00", @"18:00", @"24:00"]
                               yLabels:nil // @[@"0", @"50", @"100", @"150", @"200"]
                             chartData:data00
                              position:0];
        ////////////////////////
        PNScatterChartData * data01 = [PNScatterChartData new];
        data01.strokeColor = PNRed;
        data01.fillColor = PNRed;
        data01.size = 1;
        data01.inflexionPointStyle = PNScatterChartPointStyleCircle;
        [self showFitbitChartWithStart:start
                                   end:end
                                  type:@"steps"
                                   key:@"activities-steps-intraday"
                               xLabels:@[@"0:00", @"6:00", @"12:00", @"18:00", @"24:00"]
                               yLabels:nil //@[@"0", @"50", @"100", @"150", @"200"]
                             chartData:data01
                              position:1];
        //////////////////////////
        PNScatterChartData * data02 = [PNScatterChartData new];
        data02.strokeColor = PNBlue;
        data02.fillColor = PNDarkBlue;
        data02.size = 1;
        data02.inflexionPointStyle = PNScatterChartPointStyleCircle;
        [self showFitbitChartWithStart:start
                                   end:end
                                  type:@"calories"
                                   key:@"activities-calories-intraday"
                               xLabels:@[@"0:00", @"6:00", @"12:00", @"18:00", @"24:00"]
                               yLabels:nil //@[@"0", @"50", @"100", @"150", @"200"]
                             chartData:data02
                              position:2];
    }else{
        [self showRawDataWithStart:start end:end];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) showFitbitChartWithStart:(NSNumber *)start end:(NSNumber *)end type:(NSString *)type key:(NSString *)key xLabels:(NSArray *) xLabels yLabels:(NSArray *)yLabels chartData:(PNScatterChartData *)chartData position:(int)position{
    [SVProgressHUD showWithStatus:@"Loading"];
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityFitbitData class])
                                        inManagedObjectContext:delegate.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@) AND (timestamp >= %@) AND (fitbit_data_type=%@)", end, start, type]];
    NSSortDescriptor *descriptor=[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
    NSArray *descriptors = [NSArray arrayWithObjects:descriptor,nil];
    [fetchRequest setSortDescriptors:descriptors];
    [fetchRequest setFetchLimit:1];
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error] ;
    if (error) {
        NSLog(@"[error][showFitbitChartWithStart:start:end] %@",error.debugDescription);
    }

    NSMutableArray * xArray = [[NSMutableArray alloc] init];
    NSMutableArray * yArray = [[NSMutableArray alloc] init];
    NSMutableArray * labelArray = [[NSMutableArray alloc] init];
    if(results.count > 0){
        EntityFitbitData * fitbitData = (EntityFitbitData*)[results lastObject];
        if ([fitbitData.fitbit_data_type isEqualToString:type]) {
            NSString * dataStr = fitbitData.fitbit_data;
            if (dataStr!=nil) {
                @try {
                    NSError * error = nil;
                    NSDictionary * dict = [NSJSONSerialization JSONObjectWithData:[dataStr dataUsingEncoding:NSUTF8StringEncoding]
                                                                          options:NSJSONReadingMutableContainers
                                                                            error:&error];
                    if ( error == nil && dict != nil) {
                        if ([dict.allKeys containsObject:key]) {
                            NSDictionary * activities = [dict objectForKey:key];
                            if ([activities.allKeys containsObject:@"dataset"]){
                                NSArray * datasets = [activities objectForKey:@"dataset"];
                                if (datasets!=nil) {
                                    for (NSDictionary * dataset in datasets) {
                                        if ([dataset.allKeys containsObject:@"value"]) {
                                            NSNumber * value = [dataset objectForKey:@"value"];
                                            NSString * time = [dataset objectForKey:@"time"];

                                            NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
                                            [dateFormat setDateFormat:@"YYYY-MM-dd"];
                                            NSString * dateString = [dateFormat stringFromDate:[NSDate new]];
                                            
                                            NSDateFormatter *dateTimeFormat = [[NSDateFormatter alloc] init];
                                            [dateTimeFormat setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
                                            NSDate *datetime = [dateTimeFormat dateFromString:[NSString stringWithFormat:@"%@ %@",dateString,time] ];
                                            NSNumber * timestamp = @(datetime.timeIntervalSince1970 * 1000);
                                            
                                            if(value.intValue >= 0 && value.intValue <= 200 &&
                                               timestamp.integerValue >= start.integerValue && timestamp.integerValue <= end.integerValue){
                                                [yArray addObject:value];
                                                [xArray addObject:timestamp];
                                                [labelArray addObject:time];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                    }else{
                        NSLog(@"[error] %@", error.debugDescription);
                    }
                } @catch (NSException *exception) {
                    
                } @finally {
                    
                }
            }
        }
        if (xArray.count == 0 && yArray.count == 0) {
            return;
        }
        /////////////////////////////////////////
        
        float ymax = -MAXFLOAT;
        float ymin = MAXFLOAT;
        for (NSNumber *num in yArray) {
            float y = num.floatValue;
            if (y < ymin) ymin = y;
            if (y > ymax) ymax = y;
        }
        
        PNScatterChart * scatterChart = [[PNScatterChart alloc] initWithFrame:CGRectMake(0, 100+(200*position), SCREEN_WIDTH, 170)];
        // self.scatterChart.yLabelFormat = @"%f.1";
        [scatterChart setAxisXWithMinimumValue:start.integerValue andMaxValue:end.integerValue toTicks:5];
        [scatterChart setAxisYWithMinimumValue:ymin andMaxValue:ymax toTicks:5];
        
        [scatterChart setHasLegend:YES];
        
        NSArray *data01Array = @[xArray,yArray];
        PNScatterChartData *data01 = chartData;
        data01.itemCount = [data01Array[0] count];
        __block NSMutableArray *XAr1 = [NSMutableArray arrayWithArray:data01Array[0]];
        __block NSMutableArray *YAr1 = [NSMutableArray arrayWithArray:data01Array[1]];
        
        data01.getData = ^(NSUInteger index) {
            CGFloat xValue = [XAr1[index] floatValue];
            CGFloat yValue = [YAr1[index] floatValue];
            return [PNScatterChartDataItem dataItemWithX:xValue AndWithY:yValue];
        };
        
        scatterChart.chartData = @[data01];
        
        if (xLabels) [scatterChart setAxisXLabel:xLabels];
        if (yLabels) [scatterChart setAxisYLabel:yLabels];
        
        [scatterChart setup];
        
        /***
         this is for drawing line to compare
         CGPoint start = CGPointMake(20, 35);
         CGPoint end = CGPointMake(80, 45);
         [self.scatterChart drawLineFromPoint:start ToPoint:end WithLineWith:2 AndWithColor:PNBlack];
         ***/
        // self.scatterChart.delegate = self;
        // self.scatterChart.displayAnimated = NO;
        [self.view addSubview:scatterChart];
        
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 80+(200*position), SCREEN_WIDTH,35)];
        label.text = type;
        [self.view addSubview:label];
    }else{
        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
        label.text = @"The data is empty.";
        [self.view addSubview:label];
    }
    [SVProgressHUD dismiss];
}

////////////
- (void) showBatteryDataWithStart:(NSNumber *)start end:(NSNumber *)end{
    
    [SVProgressHUD showWithStatus:@"Loading"];
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityBattery class])
                                            inManagedObjectContext:delegate.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@) AND (timestamp >= %@)", end, start]];
        NSError *error = nil;
        NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error] ;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            /////////////////////// battery //////////////////////////////
            NSMutableArray * xArray = [[NSMutableArray alloc] init];
            NSMutableArray * yArray = [[NSMutableArray alloc] init];
            // NSMutableArray * labelArray = [[NSMutableArray alloc] init];
            if(results.count > 0){
                for (int i=0; i<results.count; i++) {
                    EntityBattery * battery = (EntityBattery*)results[i];
                    if(battery != nil &&
                       (battery.battery_level.floatValue >= 0 && battery.battery_level.floatValue <= 100 &&
                        battery.timestamp >= start && battery.timestamp <= end)){
                           // NSLog(@"[battery level:%@] %@",battery.timestamp,battery.battery_level);
                           [yArray addObject:battery.battery_level];
                           [xArray addObject:battery.timestamp];
                           // [labelArray addObject:[NSDate dateWithTimeIntervalSince1970:battery.timestamp.longLongValue].debugDescription];
                       }
                }
                /////////////////////////////////////////
                self.scatterChart = [[PNScatterChart alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
                // self.scatterChart.yLabelFormat = @"%f.1";
                [self.scatterChart setAxisXWithMinimumValue:start.integerValue andMaxValue:end.integerValue toTicks:5];
                [self.scatterChart setAxisYWithMinimumValue:0 andMaxValue:100 toTicks:6];
                
                NSArray *data01Array = @[xArray,yArray];
                PNScatterChartData *data01 = [PNScatterChartData new];
                data01.strokeColor = PNGreen;
                data01.fillColor = PNFreshGreen;
                data01.size = 2;
                data01.itemCount = [data01Array[0] count];
                data01.inflexionPointStyle = PNScatterChartPointStyleCircle;
                __block NSMutableArray *XAr1 = [NSMutableArray arrayWithArray:data01Array[0]];
                __block NSMutableArray *YAr1 = [NSMutableArray arrayWithArray:data01Array[1]];
                
                data01.getData = ^(NSUInteger index) {
                    CGFloat xValue = [XAr1[index] floatValue];
                    CGFloat yValue = [YAr1[index] floatValue];
                    return [PNScatterChartDataItem dataItemWithX:xValue AndWithY:yValue];
                };
                
                self.scatterChart.chartData = @[data01];
                
                [self.scatterChart setAxisXLabel:@[@"00:00,06:00,12:00,18:00,24:00"]];
                [self.scatterChart setAxisYLabel:@[@"0",@"20",@"40",@"60",@"80",@"100"]];
                
                
                [self.scatterChart setup];
                /***
                 this is for drawing line to compare
                 CGPoint start = CGPointMake(20, 35);
                 CGPoint end = CGPointMake(80, 45);
                 [self.scatterChart drawLineFromPoint:start ToPoint:end WithLineWith:2 AndWithColor:PNBlack];
                 ***/
                self.scatterChart.delegate = self;
                // self.scatterChart.displayAnimated = NO;
                [self.view addSubview:self.scatterChart];
            }else{
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
                label.text = @"The data is empty.";
                [self.view addSubview:label];
            }
            [SVProgressHUD dismiss];
        });
    }];
}


- (void) showLocationDataOnMapWithStart:(NSNumber *)start end:(NSNumber *)end{
    // init MapView
    // NSLog(@"%@",self.view.frame);
    _mapView = [[MKMapView alloc] initWithFrame:self.view.frame];
    _mapView.delegate = self;
    [self.view addSubview:_mapView];
    
    [SVProgressHUD showWithStatus:@"Loading"];
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityLocation class])
                                            inManagedObjectContext:delegate.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@) AND (timestamp >= %@)", end, start]];
        NSError *error = nil;
        NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error] ;
        
        /////////////////////// locations //////////////////////////////
        dispatch_async(dispatch_get_main_queue(), ^{
            if(results.count > 0){
                for (EntityLocation* location in results) {
                    if (location != nil) {
                        MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
                        double latitude = location.double_latitude.doubleValue;
                        double longitude = location.double_longitude.doubleValue;
                        annotation.coordinate = CLLocationCoordinate2DMake(latitude, longitude);
                        [_mapView addAnnotation:annotation];
                    }
                }
            }else{
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
                label.text = @"The data is empty.";
                [self.view addSubview:label];
            }
            [SVProgressHUD dismiss];
        });
    }];
}


- (void) showRawDataWithStart:(NSNumber *)start end:end {
    
    _textView = [[UITextView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:_textView];

    // [SVProgressHUD show]
    [SVProgressHUD showWithStatus:@"Loading"];
    
    
    [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
        
        // get data
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:[_sensor getEntityName]
                                            inManagedObjectContext:delegate.managedObjectContext]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@) AND (timestamp >= %@)", end, start]];
        NSError *error = nil;
        NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error] ;
        
        dispatch_async(dispatch_get_main_queue(), ^{

            /////////////////////// locations //////////////////////////////
            if(results.count > 0){
                if ([[_sensor getSensorName] isEqualToString:@"wifi"]) {
                    for (EntityWifi * wifi in results) {
                        if (wifi != nil) {
                            NSDate * date = [NSDate dateWithTimeIntervalSince1970:wifi.timestamp.doubleValue/1000];
                            NSString * dateStr = [self getDateWithStringFormat:date];
                            [_textView setText:[_textView.text stringByAppendingFormat:@"%@: %@\n",dateStr,wifi.ssid]];
                        }
                    }
                }else if ([[_sensor getSensorName] isEqualToString:@"plugin_ios_activity_recognition"]) {
                    for (EntityActivityRecognition * activity in results) {
                        if (activity != nil) {
                            NSDate * date = [NSDate dateWithTimeIntervalSince1970:activity.timestamp.doubleValue/1000];
                            NSString * dateStr = [self getDateWithStringFormat:date];
                            [_textView setText:[_textView.text stringByAppendingFormat:@"%@: %@\n",dateStr,activity.activities]];
                        }
                    }
                }else if ([[_sensor getSensorName] isEqualToString:@"barometer"]) {
                    for (EntityBarometer * barometer in results){
                        NSDate * date = [NSDate dateWithTimeIntervalSince1970:barometer.timestamp.doubleValue/1000];
                        NSString * dateStr = [self getDateWithStringFormat:date];
                        [_textView setText:[_textView.text stringByAppendingFormat:@"%@: %@\n",dateStr, barometer.double_values_0]];
                    }
                }else if([[_sensor getSensorName] isEqualToString:@"bluetooth"]){
                    for (EntityBluetooth * bluetooth in results){
                        NSDate * date = [NSDate dateWithTimeIntervalSince1970:bluetooth.timestamp.doubleValue/1000];
                        NSString * dateStr = [self getDateWithStringFormat:date];
                        [_textView setText:[_textView.text stringByAppendingFormat:@"%@: %@ %@ %@\n",dateStr, bluetooth.bt_address, bluetooth.bt_name, bluetooth.bt_rssi]];
                    }
                }else if([[_sensor getSensorName] isEqualToString:@"calls"]){
                    for (EntityCall * call in results){
                        NSDate * date = [NSDate dateWithTimeIntervalSince1970:call.timestamp.doubleValue/1000];
                        NSString * dateStr = [self getDateWithStringFormat:date];
                        [_textView setText:[_textView.text stringByAppendingFormat:@"%@: [%@] %@\n",dateStr,call.call_type, call.trace]];
                    }
                }else if([[_sensor getSensorName] isEqualToString:@"network"]){
                    for (EntityNetwork * network in results){
                        NSDate * date = [NSDate dateWithTimeIntervalSince1970:network.timestamp.doubleValue/1000];
                        NSString * dateStr = [self getDateWithStringFormat:date];
//                        NSLog(@"%@",network.network_subtype);
                        [_textView setText:[_textView.text stringByAppendingFormat:@"%@: %@\n", dateStr, network.network_subtype]];
                        
                    }
                }
            }else{
                UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
                label.text = @"The data is empty.";
                [self.view addSubview:label];
            }
            
            [SVProgressHUD dismiss];
        });
        
    }];

}


- (NSString *) getDateWithStringFormat:(NSDate *) date {
    NSCalendar *userCalendar = [NSCalendar currentCalendar];
    NSUInteger flag = NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond;
    NSDateComponents *c = [userCalendar components:flag fromDate:date];
    NSString *dateStr = [NSString stringWithFormat:@"%ld/%ld/%ld %ld:%ld:%ld", (long)[c year], (long)[c month], [c day], [c hour], [c minute], [c second]];
    return dateStr;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/





///////////////////////////////

//self.lineChart = [[PNLineChart alloc] initWithFrame:CGRectMake(0, 135.0, SCREEN_WIDTH, 200.0)];
////self.lineChart.showCoordinateAxis = YES;
//self.lineChart.yLabelFormat = @"%1.1f";
//self.lineChart.xLabelFont = [UIFont fontWithName:@"Helvetica-Light" size:8.0];
//// [self.lineChart setXLabels:@[@"SEP 1", @"SEP 2", @"SEP 3", @"SEP 4", @"SEP 5", @"SEP 6", @"SEP 7"]];
//self.lineChart.yLabelColor = [UIColor blackColor];
//self.lineChart.xLabelColor = [UIColor blackColor];
//
//// added an example to show how yGridLines can be enabled
//// the color is set to clearColor so that the demo remains the same
////self.lineChart.showGenYLabels = NO;
////self.lineChart.showYGridLines = YES;
//
////Use yFixedValueMax and yFixedValueMin to Fix the Max and Min Y Value
////Only if you needed
////        self.lineChart.yFixedValueMax = 3.0;
////        self.lineChart.yFixedValueMin = -3.0;
//////

//NSArray * data01Array = [[yArray reverseObjectEnumerator] allObjects];
//PNLineChartData *data01 = [PNLineChartData new];
//
//data01.dataTitle = @"Battery Consumption";
//data01.color = PNFreshGreen;
//data01.pointLabelColor = [UIColor blackColor];
//data01.alpha = 0.3f;
////data01.showPointLabel = YES;
//data01.pointLabelFont = [UIFont fontWithName:@"Helvetica-Light" size:9.0];
//data01.itemCount = data01Array.count;
//data01.inflexionPointColor = PNRed;
////data01.inflexionPointStyle = PNLineChartPointStyleTriangle;
//data01.getData = ^(NSUInteger index) {
//    CGFloat yValue = [data01Array[index] floatValue];
//    return [PNLineChartDataItem dataItemWithY:yValue];
//};
//
//self.lineChart.chartData = @[data01];
//self.lineChart.xLabels = labelArray;
//[self.lineChart.chartData enumerateObjectsUsingBlock:^(PNLineChartData *obj, NSUInteger idx, BOOL *stop) {
//    obj.pointLabelColor = [UIColor blackColor];
//}];
//
//
//[self.lineChart strokeChart];
//self.lineChart.delegate = self;
//
//[self.view addSubview:self.lineChart];

@end
