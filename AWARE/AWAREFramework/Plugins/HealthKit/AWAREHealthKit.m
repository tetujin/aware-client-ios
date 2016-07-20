//
//  AWAREHealthKit.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2/1/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//
//  http://jademind.com/blog/posts/healthkit-api-tutorial/
//

#import "AWAREHealthKit.h"
#import "AWAREUtils.h"
#import <HealthKit/HealthKit.h>

@implementation AWAREHealthKit{
    NSTimer * timer;
    HKHealthStore *healthStore;
    
    NSString* KEY_DEVICE_ID;
    NSString* KEY_TIMESTAMP;
    NSString* KEY_DATA_TYPE;
    NSString* KEY_VALUE;
    NSString* KEY_UNIT;
    NSString* KEY_START;
    NSString* KEY_END;
    NSString* KEY_DEVICE;
    NSString* KEY_LABLE;
    
//    NSString * KEY_TIMESTAMP_OF_LAST_UPDATE;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study dbType:(AwareDBType)dbType{
    self = [super initWithAwareStudy:study
                          sensorName:@"plugin_health_kit"
                        dbEntityName:nil
                              dbType:AwareDBTypeTextFile];
    if(self){
        KEY_DEVICE_ID = @"device_id";
        KEY_TIMESTAMP =@"timestamp";
        KEY_DATA_TYPE= @"type";
        KEY_VALUE = @"value";
        KEY_UNIT = @"unit";
        KEY_START = @"start";
        KEY_END = @"end";
        KEY_DEVICE = @"device";
        KEY_LABLE = @"label";
//        KEY_TIMESTAMP_OF_LAST_UPDATE = @"key_plugin_sensor_pedometer_last_update_timestamp";
        // Add your HealthKit code here
        healthStore = [[HKHealthStore alloc] init];
        if(NSClassFromString(@"HKHealthStore") && [HKHealthStore isHealthDataAvailable])
        {
            NSSet *readDataTypes = [self allDataTypesToRead];
            
            // Request access
            [healthStore requestAuthorizationToShareTypes:nil
                                                readTypes:readDataTypes
                                               completion:^(BOOL success, NSError *error) {
                                                   
                                                   if(success == YES)
                                                   {
                                                       // ...
                                                       [self readAllDate];
                                                   }
                                                   else
                                                   {
                                                       // Determine if it was an error or if the
                                                       // user just canceld the authorization request
                                                   }
                                                   
                                               }];
        }
    }
    return self;
}



- (void) createTable{
    // Send a table create query
    NSLog(@"[%@] create table!", [self getSensorName]);
    NSMutableString *query = [[NSMutableString alloc] init];
    [query appendString:@"_id integer primary key autoincrement,"];
    [query appendFormat:@"%@ real default 0,", KEY_TIMESTAMP];
    [query appendFormat:@"%@ text default '',", KEY_DEVICE_ID];
    [query appendFormat:@"%@ text default '',", KEY_DATA_TYPE];
    [query appendFormat:@"%@ real default 0,", KEY_VALUE];
    [query appendFormat:@"%@ text default '',", KEY_UNIT];
    [query appendFormat:@"%@ real default 0,", KEY_START];
    [query appendFormat:@"%@ real default 0,", KEY_END];
    [query appendFormat:@"%@ text default '',", KEY_DEVICE];
    [query appendFormat:@"%@ text dedault '',", KEY_LABLE];
    [query appendString:@"UNIQUE (timestamp,device_id)"];
    [super createTable:query];
}


- (BOOL)startSensorWithSettings:(NSArray *)settings{
    
//    [self readAllDate];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:60 * 15 //1hour
                                             target:self
                                           selector:@selector(readAllDate)
                                           userInfo:nil
                                            repeats:YES];
    return YES;
}

- (BOOL)stopSensor{
    [timer invalidate];
    timer = nil;
    healthStore = nil;
    return YES;
}






///////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////

- (void) readAllDate {
    // Set your start and end date for your query of interest
    NSDate *startDate, *endDate;
    startDate = [self getLastUpdate]; //[NSDate dateWithTimeIntervalSinceNow:-60*60*24];
    endDate = [NSDate new];
    [self setLastUpdate:endDate];
    
    // Use the sample type for step count
    HKSampleType *sampleType = [HKSampleType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    // Create a predicate to set start/end date bounds of the query
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:startDate endDate:endDate options:HKQueryOptionStrictStartDate];
    
    // Create a sort descriptor for sorting by start date
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType
                                                                 predicate:predicate
                                                                     limit:HKObjectQueryNoLimit
                                                           sortDescriptors:@[sortDescriptor]
                                                            resultsHandler:^(HKSampleQuery *query, NSArray *results, NSError *error) {
                                                                
                                                                if(!error && results)
                                                                {
                                                                    for(HKQuantitySample *samples in results)
                                                                    {
                                                                        
                                                                        HKSampleType * type = samples.sampleType;
                                                                        // your code here
//                                                                        NSLog(@"%@", samples);
//                                                                        NSLog(@"%@",samples.device.model);
//                                                                        NSLog(@"%@",samples.startDate);
//                                                                        NSLog(@"%@",samples.endDate);
//                                                                        NSLog(@"%@",samples);
//                                                                        NSLog(@"%@",samples.quantity);
                                                                        
                                                                        NSMutableString * quantityStr = [[NSMutableString alloc] initWithString:[samples.quantity description]];
                                                                        NSArray * array = [quantityStr componentsSeparatedByString:@" "];
                                                                        NSNumber * value = @0;
                                                                        NSString * unit = @"";
                                                                        if (array.count > 1) {
                                                                            if(array[0] != nil){
                                                                                value = @([array[0] doubleValue]);
                                                                            }
                                                                            if(array[1] != nil){
                                                                                unit = array[1];
                                                                            }
                                                                        }
                                                                        
                                                                        NSMutableDictionary * dict = [[NSMutableDictionary alloc] init];
                                                                        [dict setObject:[AWAREUtils getUnixTimestamp:[NSDate new]] forKey:KEY_TIMESTAMP];
                                                                        [dict setObject:[self getDeviceId] forKey:KEY_DEVICE_ID];
                                                                        [dict setObject:[NSNumber numberWithInteger:(NSInteger)type] forKey:KEY_DATA_TYPE];
                                                                        [dict setObject:value forKey:KEY_VALUE];
                                                                        [dict setObject:unit forKey:KEY_UNIT];
                                                                        [dict setObject:[AWAREUtils getUnixTimestamp:samples.startDate] forKey:KEY_START];
                                                                        [dict setObject:[AWAREUtils getUnixTimestamp:samples.endDate] forKey:KEY_END];
                                                                        [dict setObject:samples.device.model forKey:KEY_DEVICE];
                                                                        [dict setObject:@"" forKey:KEY_LABLE];
                                                                        
                                                                        [self saveData:dict];
                                                                    }
                                                                }
                                                                
                                                            }];
    
    // Execute the query
    [healthStore executeQuery:sampleQuery];
}


// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)allDataTypesToRead {
    NSSet* characteristicTypesSet = [self characteristicDataTypesToRead];
    NSSet* otherTypesSet = [self dataTypesToRead];
    
    return [otherTypesSet setByAddingObjectsFromSet: characteristicTypesSet];
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)characteristicDataTypesToRead {
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
    // CharacteristicType
    HKCharacteristicType *characteristicType;
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBiologicalSex];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierBloodType];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierDateOfBirth];
    [dataTypesSet addObject:characteristicType];
    characteristicType = [HKCharacteristicType characteristicTypeForIdentifier:HKCharacteristicTypeIdentifierFitzpatrickSkinType];
    [dataTypesSet addObject:characteristicType];
    
    return dataTypesSet;
}

// Returns the types of data that Fit wishes to read from HealthKit.
- (NSSet *)dataTypesToRead {
    NSMutableSet* dataTypesSet = [[NSMutableSet alloc] init];
    
    // QuantityType
    HKQuantityType *quantityType;
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMassIndex];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyFatPercentage];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeight];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyMass];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierLeanBodyMass];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceWalkingRunning];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDistanceCycling];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalEnergyBurned];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierActiveEnergyBurned];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierFlightsClimbed];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierNikeFuel];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierHeartRate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBodyTemperature];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBasalBodyTemperature];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureSystolic];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodPressureDiastolic];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierRespiratoryRate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierOxygenSaturation];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierPeripheralPerfusionIndex];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodGlucose];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierNumberOfTimesFallen];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierElectrodermalActivity];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierInhalerUsage];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierBloodAlcoholContent];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierForcedVitalCapacity];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierForcedExpiratoryVolume1];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierPeakExpiratoryFlowRate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatTotal];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatPolyunsaturated];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatMonounsaturated];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFatSaturated];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCholesterol];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySodium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCarbohydrates];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFiber];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySugar];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryEnergyConsumed];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryProtein];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminA];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminB6];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminB12];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminC];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminD];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminE];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryVitaminK];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCalcium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryIron];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryThiamin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryRiboflavin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryNiacin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryFolate];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryBiotin];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPantothenicAcid];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPhosphorus];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryIodine];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryMagnesium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryZinc];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietarySelenium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCopper];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryManganese];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryChromium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryMolybdenum];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryChloride];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryPotassium];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryCaffeine];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierDietaryWater];
    [dataTypesSet addObject:quantityType];
    quantityType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierUVExposure];
    [dataTypesSet addObject:quantityType];
    
    
    // CategoryType
    HKCategoryType *categoryType;
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSleepAnalysis];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierAppleStandHour];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierCervicalMucusQuality];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierOvulationTestResult];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierMenstrualFlow];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierIntermenstrualBleeding];
    [dataTypesSet addObject:categoryType];
    categoryType = [HKCategoryType categoryTypeForIdentifier:HKCategoryTypeIdentifierSexualActivity];
    [dataTypesSet addObject:categoryType];
    
#ifdef ENABLE_HK_DUMP_TYPE_CORR
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // CorrelationType
    HKCorrelationType *corrType;
    corrType = [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierBloodPressure];
    [dataTypesSet addObject:corrType];
    corrType = [HKCorrelationType correlationTypeForIdentifier:HKCorrelationTypeIdentifierFood];
    [dataTypesSet addObject:corrType];
#endif
    
    ////////////////////////////////////////////////////////////////////////////////////////////////
    // HKWorkoutType
    HKWorkoutType *workoutType = [HKWorkoutType workoutType];
    [dataTypesSet addObject:workoutType];
    
    return dataTypesSet;
}

- (NSDate *) getLastUpdate {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDate * lastUpdate =  [userDefaults objectForKey:@"plugin_health_kit_last_update_timestamp"];
    if(lastUpdate == nil){
        return [NSDate new];
    }else{
        return lastUpdate;
    }
}

- (void) setLastUpdate :(NSDate *) date {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:date forKey:@"plugin_health_kit_last_update_timestamp"];
}

@end
