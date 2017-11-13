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
#import "AWAREUtils.h"

@interface DataVisualizationViewController ()

@end

@implementation DataVisualizationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    NSDate * now = [NSDate new];
    NSNumber * start = [AWAREUtils getUnixTimestamp:[AWAREUtils getTargetNSDate:now hour:0 nextDay:NO]];
    NSNumber * end = [AWAREUtils getUnixTimestamp:[AWAREUtils getTargetNSDate:now hour:0 nextDay:YES]];
    
    AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setEntity:[NSEntityDescription entityForName:NSStringFromClass([EntityBattery class])
                                        inManagedObjectContext:delegate.managedObjectContext]];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(timestamp <= %@) AND (timestamp >= %@)", end, start]];
    NSError *error = nil;
    NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:&error] ;

    NSMutableArray *xArray = [[NSMutableArray alloc] init];
    NSMutableArray * yArray = [[NSMutableArray alloc] init];
    NSMutableArray *labelArray = [[NSMutableArray alloc] init];
    if(results.count > 0){
        for (int i=0; i<results.count; i++) {
            EntityBattery * battery = (EntityBattery*)results[i];
            NSLog(@"[battery level:%d] %@",i,battery.battery_level);
            [yArray addObject:battery.battery_level];
            [xArray addObject:battery.timestamp];
            [labelArray addObject:[NSDate dateWithTimeIntervalSince1970:battery.timestamp.longLongValue].debugDescription];
        }
        //Max
//        NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:@[[NSExpression expressionForConstantValue:yArray]]];
//        id maxValue = [maxExpression expressionValueWithObject:nil context:nil];
//        NSLog(@"Max:%f", [maxValue floatValue]);
//        
//        //Min
//        NSExpression *minExpression = [NSExpression expressionForFunction:@"min:" arguments:@[[NSExpression expressionForConstantValue:yArray]]];
//        id minValue = [minExpression expressionValueWithObject:nil context:nil];
//        NSLog(@"Min:%f", [minValue floatValue]);
        
        /////////////////////////////////////////
        self.scatterChart = [[PNScatterChart alloc] initWithFrame:CGRectMake(0, 135, SCREEN_WIDTH, 200)];
        self.scatterChart.yLabelFormat = @"%f.1";
        [self.scatterChart setAxisXWithMinimumValue:start.integerValue andMaxValue:end.integerValue toTicks:6];
        [self.scatterChart setAxisYWithMinimumValue:0 andMaxValue:100 toTicks:5];
        
        
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
            CGFloat xValue;
            xValue = [XAr1[index] floatValue];
            CGFloat yValue = [YAr1[index] floatValue];
            return [PNScatterChartDataItem dataItemWithX:xValue AndWithY:yValue];
        };
        
        [self.scatterChart setAxisXLabel:labelArray];
        
        [self.scatterChart setup];
        self.scatterChart.chartData = @[data01];
        
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

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
