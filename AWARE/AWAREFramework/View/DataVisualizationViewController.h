//
//  DataVisualizationViewController.h
//  AWARE
//
//  Created by Yuuki Nishiyama on 2017/08/23.
//  Copyright © 2017 Yuuki NISHIYAMA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "PNChart.h"
#import "AWARESensor.h"

@interface DataVisualizationViewController : UIViewController <PNChartDelegate, MKMapViewDelegate>

@property NSManagedObjectContext *mainQueueManagedObjectContext;

@property AWARESensor * sensor;

@property PNLineChart * lineChart;
@property PNScatterChart * scatterChart;

@property UITextView * textView;

@property MKMapView * mapView;

@end
