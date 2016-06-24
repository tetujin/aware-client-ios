//
//  AWARECoreDataUploader.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 4/30/16.
//  Copyright © 2016 Yuuki NISHIYAMA. All rights reserved.
//

#import "AWARECoreDataManager.h"

@implementation AWARECoreDataManager {
    AWAREStudy * awareStudy;
    NSString* entityName;
    NSString* sensorName;
    
    // sync data query
    NSString * syncDataQueryIdentifier;
    NSString * baseSyncDataQueryIdentifier;
    
    // create table query
    NSString * createTableQueryIdentifier;
    NSString * baseCreateTableQueryIdentifier;
    
    // notification identifier
    NSString * dbSessionFinishNotification; // this notification should make by each sensor.
//    [[NSNotificationCenter defaultCenter] removeObserver: name: object:]
//    [[NSNotificationCenter defaultCenter] postNotificationName:object:userInfo:]
    
    NSString * timeMarkerIdentifier;
    double httpStartTimestamp;
    double postedTextLength;
    BOOL isDebug;
    BOOL isUploading;
    BOOL isManualUpload;
    BOOL isSyncWithOnlyBatteryCharging;
    int errorPosts;
    
    NSNumber * unixtimeOfUploadingData;
    
    AwareDBCondition dbCondition;
    
//    int currentCategoryCount;
    int currentRepetitionCounts; // current repetition count
    int repetitionTime;          // max repetition count
    
    double shortDelayForNextUpload; // second
    double longDelayForNextUpload; // second
    int thresholdForNextLongDelay; // count
    
    int bufferCount;
    NSString * syncProgress;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study
                        sensorName:(NSString *)name
                      dbEntityName:(NSString *)entity {
    self = [super initWithAwareStudy:study sensorName:name];
    if(self != nil){
        awareStudy = study;
        sensorName = name;
        entityName = entity;
        isUploading = NO;
        httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
        postedTextLength = 0;
        errorPosts = 0;
        shortDelayForNextUpload = 1; // second
        longDelayForNextUpload = 30; // second
        thresholdForNextLongDelay = 10; // count
        bufferCount = 0; // buffer count
        syncProgress = @"";
        isManualUpload = NO;
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        baseCreateTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        timeMarkerIdentifier = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", sensorName];
        dbSessionFinishNotification = [NSString stringWithFormat:@"aware.db.session.finish.notification.%@", sensorName];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedDbSession:) name:dbSessionFinishNotification object:nil];
        //    [[NSNotificationCenter defaultCenter] removeObserver: name: object:]
        //    [[NSNotificationCenter defaultCenter] postNotificationName:object:userInfo:]
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        isDebug = [userDefaults boolForKey:SETTING_DEBUG_STATE];
        isSyncWithOnlyBatteryCharging = [userDefaults boolForKey:SETTING_SYNC_BATTERY_CHARGING_ONLY];
        
        dbCondition = AwareDBConditionNormal;
        
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        _mainQueueManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_mainQueueManagedObjectContext setPersistentStoreCoordinator:delegate.persistentStoreCoordinator];
      
        NSNumber * timestamp = [userDefaults objectForKey:timeMarkerIdentifier];
        if(timestamp == 0){
            NSLog(@"timestamp == 0");
            [self setTimeMark:[NSDate new]];
        }else{
            NSLog(@"timestamp == %@", timestamp);
        }
    }
    return self;
}

- (bool)isUploading{
    return isUploading;
}

- (void) finishedDbSession:(id) sender {
    dbCondition = AwareDBConditionNormal;
}

- (void) stopStopCoreDataManager {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:dbSessionFinishNotification object:nil];
}

- (void)syncAwareDBInBackground{
    // chekc wifi state
    if(isUploading){
        NSString * message= [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", sensorName];
        NSLog(@"%@", message);
        return;
    }
    
    // chekc wifi state
    if (![awareStudy isWifiReachable]) {
        NSString * message = [NSString stringWithFormat:@"[%@] Wifi is not availabe.", sensorName];
        NSLog(@"%@", message);
        return;
    }
    
    // check battery condition
    if (isSyncWithOnlyBatteryCharging) {
        NSInteger batteryState = [UIDevice currentDevice].batteryState;
        if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
        }else{
            NSString * message = [NSString stringWithFormat:@"[%@] This device is not charginig battery now.", sensorName];
            NSLog(@"%@", message);
            return;
        }
    }
    
    // Get repititon time from CoreData in background.
//    [self getCategoryCountFromTimestamp:[self getTimeMark]]; // <-- get category count and start
    if([NSThread isMainThread]){
        // Make addtional thread
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            [self  setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
        }];
    }else{
        [self  setRepetationCountAfterStartToSyncDB:[self getTimeMark]];
    }
    
    isUploading = YES;
//    [self uploadSensorDataInBackground];
}


//////////////////////////////////////////////////////////////////////////////


- (NSString *)getEntityName{
    return entityName;
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

- (void) setTimeMark:(NSDate *) timestamp {
    if(timestamp != nil){
        @try {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:[AWAREUtils getUnixTimestamp:timestamp] forKey:timeMarkerIdentifier];
            [userDefaults synchronize];
        } @catch (NSException *exception) {
        }
    }else{
        NSLog(@"===============timestamp is nil============================");
    }
}

- (void) setTimeMarkWithTimestamp:(NSNumber *)timestamp  {
    if(timestamp != nil){
//        NSLog(@"[%@]", [self getEntityName]);
//        NSLog(@"nil? %@", timestamp);
        @try {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setObject:timestamp forKey:timeMarkerIdentifier];
            [userDefaults synchronize];
        }@catch(NSException *exception){
            
        }
    }else{
        NSLog(@"===============timestamp is nil============================");
    }
    
}


- (NSNumber *) getTimeMark {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults synchronize];
    NSNumber * timestamp = [userDefaults objectForKey:timeMarkerIdentifier];
//    NSLog(@"[%@]", [self getEntityName]);
//    NSLog(@"nil? %@", timestamp);
    if(timestamp != nil){
        return timestamp;
    }else{
        NSLog(@"===============timestamp is nil============================");
        return @0;
    }
}



//////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * This method saves data (that is on the RAM) to DB (SQLite).
 * @discussion This method should be called expect for main thread.
 */
- (bool) saveDataToDB {
//    NSLog(@"[%@] buffer count => %d", [self getEntityName], bufferCount);
    
    if(bufferCount > [self getBufferSize]){
        bufferCount = 0;
    }else{
        bufferCount ++;
        return NO;
    }
    
    if(dbCondition == AwareDBConditionCounting || dbCondition == AwareDBConditionFetching){
        NSLog(@"[%@] DB is working for 'counting' or 'fetching' the data.", [self getEntityName]);
        return NO;
    }
    dbCondition = AwareDBConditionInserting;
    @try {
        // If the current thread is main thread, we should make a new thread for saving data
        if([NSThread isMainThread]){
            // Make addtional thread
            [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
                // In the other thread, this method call -saveDataToDB again.
                [self saveDataInBackground];
            }];
        }else{
            [self saveDataInBackground];
        }
    }@catch(NSException *exception) {
        NSLog(@"%@", exception.reason);
        dbCondition = AwareDBConditionNormal;
        return NO;
    }
    return YES;
}

/**
 * Save data to SQLite in the background. NOTE: This method should be called in the background thread.
 */
- (void) saveDataInBackground{
    NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [private setParentContext:_mainQueueManagedObjectContext];
    [private performBlock:^{
        NSError *error = nil;
        if (! [private save:&error]) {
            NSLog(@"Error saving context: %@\n%@",
                  [error localizedDescription], [error userInfo]);
        }
        if(isDebug){
            NSLog(@"Save [%@] to SQLite", [self getEntityName]);
        }
        dbCondition = AwareDBConditionNormal;
    }];
}

//////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////

/**
 * start sync db with timestamp
 * @discussion Please call this method in the background
 */
- (BOOL) setRepetationCountAfterStartToSyncDB:(NSNumber *) timestamp {
    @try {
        if(dbCondition == AwareDBConditionDeleting || dbCondition == AwareDBConditionInserting){
            return NO;
        }else{
            dbCondition = AwareDBConditionCounting;
        }
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:_mainQueueManagedObjectContext];
        [private performBlock:^{
            [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
            [request setIncludesSubentities:NO];
            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];

            NSError* error = nil;
            // Get count of category
            NSInteger count = [private countForFetchRequest:request error:&error];
            if (count == NSNotFound) {
                [self dataSyncIsFinishedCorrectoly];
                dbCondition = AwareDBConditionNormal;
                NSLog(@"[%@] There are no data in this database table",[self getEntityName]);
                return;
            } else if(error != nil){
                [self dataSyncIsFinishedCorrectoly];
                dbCondition = AwareDBConditionNormal;
                NSLog(@"%@", error.description);
                count = 0;
                return;
            }
            // Set repetationCount
            currentRepetitionCounts = 0;
            repetitionTime = (int)count/(int)[self getFetchLimit];
            
            // set db condition as normal
            dbCondition = AwareDBConditionNormal;
            
            // start upload
            [self uploadSensorDataInBackground];
            
            
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectoly];
    } @finally {
        return YES;
    }
    
}


// set DB condition as normal after DB session
- (void) setDBConditionAsNormal{
    dbCondition = AwareDBConditionNormal;
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

/**
 * Upload method
 */
- (void) uploadSensorDataInBackground {
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];

    // Get sensor data from CoreData
    if(unixtimeOfUploadingData == nil){
        unixtimeOfUploadingData = [self getTimeMark];
    }

    // check battery condition
    if (isSyncWithOnlyBatteryCharging) {
        NSInteger batteryState = [UIDevice currentDevice].batteryState;
        if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
        }else{
            NSLog(@"[%@] This device is not charginig battery now.", sensorName);
            [self dataSyncIsFinishedCorrectoly];
            return;
        }
    }
    
    if(dbCondition == AwareDBConditionInserting || dbCondition == AwareDBConditionDeleting){
        NSLog(@"[%@]The DB is working for 'inserting' or 'deleting' the data.", [self getEntityName]);
        [self dataSyncIsFinishedCorrectoly];
        [self performSelector:@selector(saveDataToDB) withObject:nil afterDelay:1];
        return;
    }else{
        // Block other connection by other process to this db
        dbCondition = AwareDBConditionFetching;
    }
    
    if(entityName == nil){
        NSLog(@"Entity Name is 'nil'. Please check the initialozation of this class.");
    }
    
    NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
    
    // set a repetation count
    currentRepetitionCounts++;
    
    @try {
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:_mainQueueManagedObjectContext];
        [private performBlock:^{
             NSData* sensorData = nil;
             NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
             [fetchRequest setFetchLimit:[self getFetchLimit]];
             if ([self getFetchBatchSize] != 0) {
                 [fetchRequest setFetchBatchSize:[self getFetchBatchSize]];
             }
             [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
             [fetchRequest setIncludesSubentities:NO];
            
             [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", unixtimeOfUploadingData]];
             
             //Set sort option
             NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
             NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
             [fetchRequest setSortDescriptors:sortDescriptors];
             
            //Get NSManagedObject from managedObjectContext by using fetch setting
            NSArray *results = [private executeFetchRequest:fetchRequest error:nil] ;

            
            if (results.count == 0 || results.count == NSNotFound) {
                [self dataSyncIsFinishedCorrectoly];
                dbCondition = AwareDBConditionNormal;
                NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
                [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
                [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
                [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
                [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                                    object:nil
                                                                  userInfo:userInfo];

                return;
            }
        
            NSMutableArray *array = [[NSMutableArray alloc] init];
            for (NSManagedObject *data in results) {
                NSArray *keys = [[[data entity] attributesByName] allKeys];
                NSDictionary *dict = [data dictionaryWithValuesForKeys:keys];
                unixtimeOfUploadingData = [dict objectForKey:@"timestamp"];
                //        NSLog(@"timestamp: %@", unixtimeOfUploadingData );
                [array addObject:dict];
            }
            
            if (results != nil) {
                NSError * error = nil;
                NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
                if (error == nil && jsonData != nil) {
                    dbCondition = AwareDBConditionNormal;
                    sensorData = jsonData; //[[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (sensorData == nil || sensorData.length == 0 || sensorData.length == 2) { // || [sensorData isEqualToString:@"[]"]) {
                            NSString * message = [NSString stringWithFormat:@"[%@] Data is Null or Length is Zero", sensorName];
                            [self dataSyncIsFinishedCorrectoly];
                            NSLog(@"%@", message);
                            return;
                        }
                        
                        // Set session configuration
                        NSURLSessionConfiguration *sessionConfig = nil;
                        double unxtime = [[NSDate new] timeIntervalSince1970];
                        syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", baseSyncDataQueryIdentifier, unxtime];
                        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:syncDataQueryIdentifier];
                        sessionConfig.timeoutIntervalForRequest = 60 * 3;
                        sessionConfig.HTTPMaximumConnectionsPerHost = 60 * 3;
                        sessionConfig.timeoutIntervalForResource = 60 * 3;
                        sessionConfig.allowsCellularAccess = NO;
                        
                        // set HTTP/POST body information
                        NSString* post = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
                        NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
                        NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
                        [mutablePostData appendData:sensorData];
                        
                        NSString* postLength = [NSString stringWithFormat:@"%ld", [mutablePostData length]];
                        //    NSLog(@"Data Length: %@", postLength);
                        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
                        [request setURL:[NSURL URLWithString:url]];
                        [request setHTTPMethod:@"POST"];
                        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
                        [request setHTTPBody:mutablePostData];
                        
                        NSString * logMessage = [NSString stringWithFormat:@"[%@] This is background task for upload sensor data", sensorName];
                        NSLog(@"%@", logMessage);
                        NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                                              delegate:self
                                                                         delegateQueue:nil];
                        NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
                        
                        [session getTasksWithCompletionHandler:^(NSArray* dataTasks, NSArray* uploadTasks, NSArray* downloadTasks){
                            NSLog(@"Currently suspended tasks");
                            for (NSURLSessionDownloadTask* task in dataTasks) {
                                NSLog(@"Task: %@",[task description]);
                            }
                        }];
                        
                        httpStartTimestamp = [[NSDate new] timeIntervalSince1970];
                        postedTextLength = [[NSNumber numberWithInteger:postData.length] doubleValue];
                        
                        [dataTask resume];
                    });
                }else{
                    dbCondition = AwareDBConditionNormal;
                    return;
                }
            }else{
                dbCondition = AwareDBConditionNormal;
                return;
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectoly];
        dbCondition = AwareDBConditionNormal;
    } @finally {
    }
}

///////////////////////////////////////////////////
///////////////////////////////////////////////////

- (BOOL)syncDBInForeground{
    return NO;
}



/////////////////////////////////////////////////
/////////////////////////////////////////////////

/* The task has received a response and no further messages will be
 * received until the completion block is called. The disposition
 * allows you to cancel a request or to turn a data task into a
 * download task. This delegate message is optional - if you do not
 * implement it, you can get the response as a property of the task.
 *
 * This method will not be called for background upload tasks (which cannot be converted to download tasks).
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler{
    // test: server peformance
    double diff = [[NSDate new] timeIntervalSince1970] - httpStartTimestamp;
    if (postedTextLength > 0 && diff > 0) {
        double kbs = postedTextLength/diff/1000.0f;
//        NSString *networkPeformance = [NSString stringWithFormat:@"%0.2f KB/s",kbs];
        NSLog(@"[%@] %0.2f KB/s", sensorName, kbs);
        
    }
    
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    completionHandler(NSURLSessionResponseAllow);
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        NSLog(@"[%@] Get response from the server.", sensorName);
        [self receivedResponseFromServer:dataTask.response withData:nil error:nil];
    } else if ( [session.configuration.identifier isEqualToString:createTableQueryIdentifier] ){
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
        int responseCode = (int)[httpResponse statusCode];
        if (responseCode == 200) {
            NSLog(@"[%@] Sucess to create new table on AWARE server.", sensorName);
        }
    } else {
        
    }
}

/* Notification that a data task has become a download task.  No
 * future messages will be sent to the data task.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeDownloadTask:(NSURLSessionDownloadTask *)downloadTask{
    
}

/*
 * Notification that a data task has become a bidirectional stream
 * task.  No future messages will be sent to the data task.  The newly
 * created streamTask will carry the original request and response as
 * properties.
 *
 * For requests that were pipelined, the stream object will only allow
 * reading, and the object will immediately issue a
 * -URLSession:writeClosedForStream:.  Pipelining can be disabled for
 * all requests in a session, or by the NSURLRequest
 * HTTPShouldUsePipelining property.
 *
 * The underlying connection is no longer considered part of the HTTP
 * connection cache and won't count against the total number of
 * connections per host.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
didBecomeStreamTask:(NSURLSessionStreamTask *)streamTask{
    
}

/* Sent when data is available for the delegate to consume.  It is
 * assumed that the delegate will retain and not copy the data.  As
 * the data may be discontiguous, you should use
 * [NSData enumerateByteRangesUsingBlock:] to access it.
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        // If the data is null, this method is not called.
        NSString * result = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] Data is coming! => %@", sensorName, result);

    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSLog(@"[%@] %@",sensorName, newStr);
    }
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    session = nil;
    dataTask = nil;
    data = nil;
}

/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error{
    if (error != nil) {
        NSLog(@"[%@] the session did become invaild with error: %@", sensorName, error.debugDescription);
        [AWAREUtils sendLocalNotificationForMessage:error.debugDescription soundFlag:NO];
    }
    [session invalidateAndCancel];
    [session finishTasksAndInvalidate];
}

//////////////////////////////////////////////
/////////////////////////////////////////////

- (void)receivedResponseFromServer:(NSURLResponse *)response
                          withData:(NSData *)data
                             error:(NSError *)error{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    NSString* newStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"[%@] %d  Response =====> %@",sensorName, responseCode, newStr);
    
    data = nil;
    response = nil;
    error = nil;
    httpResponse = nil;
    
    if ( responseCode == 200 ) {
        
        double progress = (double)currentRepetitionCounts/(double)repetitionTime*100;
        NSLog(@"[%@] Progress: %0.2f %%", [self getEntityName], progress);
        
        if(isDebug){
            if (currentRepetitionCounts > repetitionTime) {
                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Finish to upload data",sensorName] soundFlag:NO];
            }else{
                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Success to upload sensor data to AWARE server with %0.2f%@",sensorName,progress, @"%%"]  soundFlag:NO];
            }
        }
    
        // broad cast current progress of data upload!
        NSNumber *finish = @NO;
        NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
        if (currentRepetitionCounts > repetitionTime) {
            progress = 100;
            finish = @YES;
        }
        [userInfo setObject:@(progress) forKey:@"KEY_UPLOAD_PROGRESS_STR"];
        [userInfo setObject:finish forKey:@"KEY_UPLOAD_FIN"];
        [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
        [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
                                                            object:nil
                                                          userInfo:userInfo];
        
        /** =========== Remove old data ============== */
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:_mainQueueManagedObjectContext];
        [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
        [request setIncludesSubentities:NO];
        
        [private performBlock:^{
            
            // Set time mark
            [self setTimeMarkWithTimestamp: unixtimeOfUploadingData];
            
            cleanOldDataType cleanType = [awareStudy getCleanOldDataType];
            NSDate * clearLimitDate = [NSDate new];
            bool skip = YES;
            switch (cleanType) {
                case cleanOldDataTypeNever:
                    skip = YES;
                    break;
                case cleanOldDataTypeDaily:
                    skip = NO;
                    clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24];
                    break;
                case cleanOldDataTypeWeekly:
                    skip = NO;
                    clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24*7];
                    break;
                case cleanOldDataTypeMonthly:
                    clearLimitDate = [[NSDate alloc] initWithTimeIntervalSinceNow:-1*60*60*24*31];
                    skip = NO;
                    break;
                case cleanOldDataTypeAlways:
                    clearLimitDate = [NSDate new];
                    skip = NO;
                    break;
                default:
                    skip = YES;
                    break;
            }
            if(!skip){
                /** ========== Delete uploaded data ============= */
                NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
                NSNumber * timestamp = unixtimeOfUploadingData; // [self getTimeMark];
                NSNumber * limitTimestamp = [AWAREUtils getUnixTimestamp:clearLimitDate];
                [request setPredicate:[NSPredicate predicateWithFormat:@"(timestamp < %@) AND (timestamp < %@)", timestamp, limitTimestamp]];
                NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
                NSError *deleteError = nil;
                [private executeRequest:delete error:&deleteError];
                if (deleteError != nil) {
                    NSLog(@"%@", deleteError.description);
                }
            }
            dbCondition = AwareDBConditionNormal;
            
            /** =========== Start next data upload =========== */
            if (currentRepetitionCounts > repetitionTime ){
                [self dataSyncIsFinishedCorrectoly];
            }else{
                // Get main queue
                dispatch_async(dispatch_get_main_queue(), ^{
                   //https://developer.apple.com/library/ios/documentation/Performance/Conceptual/EnergyGuide-iOS/WorkLessInTheBackground.html#//apple_ref/doc/uid/TP40015243-CH22-SW1
                    if(isManualUpload){
                        [self performSelector:@selector(uploadSensorDataInBackground) withObject:nil afterDelay:0.5f];
                    }else{
                        if (currentRepetitionCounts%thresholdForNextLongDelay == 0) {
                            [self performSelector:@selector(uploadSensorDataInBackground) withObject:nil afterDelay:longDelayForNextUpload];
                        }else{
                            [self performSelector:@selector(uploadSensorDataInBackground) withObject:nil afterDelay:shortDelayForNextUpload];
                        }
                    }
                });
            }
        }];
    }else{
//        NSLog(@"");
    }
}



/* Sent as the last message related to a specific task.  Error may be
 * nil, which implies that no error occurred and this task is complete.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task
didCompleteWithError:(nullable NSError *)error;
{
    [session finishTasksAndInvalidate];
    [session invalidateAndCancel];
    
    if ([session.configuration.identifier isEqualToString:syncDataQueryIdentifier]) {
        if (error) {
            errorPosts++;
            if (isDebug) {
            }
            if (errorPosts < 3) { //TODO
                [self uploadSensorDataInBackground];
            } else {
                [self dataSyncIsFinishedCorrectoly];
            }
        } else {
            
        }
        NSLog(@"%@", task.description);
        return;
    } else if ([session.configuration.identifier isEqualToString:createTableQueryIdentifier]){
        session = nil;
        task = nil;
    }
}


/**
 * init variables for data upload
 * @discussion This method is called when finish to data upload session
 */
- (void) dataSyncIsFinishedCorrectoly {
    NSLog(@"[%@] Session task finished", sensorName);
    // set uploading state is NO
    isUploading = NO;
    isManualUpload = NO;
    // init error counts
    errorPosts = 0;
    // init repetation time and current count
    repetitionTime = 0;
    currentRepetitionCounts = 0;
}


/////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////

/**
 * AWARE URL makers
 */
- (NSString *)getWebserviceUrl{
    NSString* url = [awareStudy getWebserviceServer];
    if (url == NULL || [url isEqualToString:@""]) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
}


- (NSString *)getDeviceId{
    //    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //    NSString* deviceId = [userDefaults objectForKey:KEY_MQTT_USERNAME];
    NSString * deviceId = [awareStudy getDeviceId];
    return deviceId;
}

- (NSString *)getInsertUrl:(NSString *)name{
    //    - insert: insert new data to the table
    return [NSString stringWithFormat:@"%@/%@/insert", [self getWebserviceUrl], name];
}


- (NSString *)getLatestDataUrl:(NSString *)name{
    //    - latest: returns the latest timestamp on the server, for synching what’s new on the phone
    return [NSString stringWithFormat:@"%@/%@/latest", [self getWebserviceUrl], name];
}


- (NSString *)getCreateTableUrl:(NSString *)name{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], name];
}


- (NSString *)getClearTableUrl:(NSString *)name{
    //    - clear_table: remove a specific device ID data from the database table
    return [NSString stringWithFormat:@"%@/%@/clear_table", [self getWebserviceUrl], name];
}

//////////////////////////////////////////////
/////////////////////////////////////////////


/**
 * Return current network condition with a text
 */
//- (NSString *) getNetworkReachabilityAsText{
//    return [awareStudy getNetworkReachabilityAsText];
//}

////////////////////////////////////////////////
///////////////////////////////////////////////
////////////////////////////////////////////
////////////////////////////////////////////



/**
 * Create Table Methods
 */

- (void) createTable:(NSString*) query {
    [self createTable:query withTableName:sensorName];
}

- (void) createTable:(NSString *)query withTableName:(NSString*) tableName {
    NSString *post = nil;
    NSData *postData = nil;
    NSMutableURLRequest *request = nil;
    __weak NSURLSession *session = nil;
    //    NSURLSession *session = nil;
    NSString *postLength = nil;
    NSURLSessionConfiguration *sessionConfig = nil;
    
    // Make a post query for creating a table
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [self getDeviceId], query];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];
    
    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:tableName]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    
    // Generate an unique identifier for background HTTP/POST on iOS
    double unxtime = [[NSDate new] timeIntervalSince1970];
    createTableQueryIdentifier = [NSString stringWithFormat:@"%@%f", baseCreateTableQueryIdentifier, unxtime];
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:createTableQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 180.0;
    sessionConfig.HTTPMaximumConnectionsPerHost = 60;
    sessionConfig.timeoutIntervalForResource = 60;
    sessionConfig.allowsCellularAccess = YES;
    //    sessionConfig.discretionary = YES;
    
//    NSString * debugMessage = [NSString stringWithFormat:@"[%@] Sent a query for creating a table in the background", sensorName];
    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
    [dataTask resume];
}



/**
 * WIP:
 */
- (BOOL)clearTable{
    return NO;
}



/////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////

- (BOOL)syncAwareDBInForeground{
    isManualUpload = YES;
    [self syncAwareDBInBackground];
//    return YES;
//        NSString *deviceId = [self getDeviceId];
//        NSString *url = [self getInsertUrl:sensorName];
//        
//        /**  ======= Check network and device condition ========= */
//        // check uploding state
//        if(isUploading){
//            NSLog(@"%@", [NSString stringWithFormat:@"[%@] Now sendsor data is uploading.", sensorName]);
//            return NO;
//        }
//        
//        // chekc wifi state
//        if (![awareStudy isWifiReachable]) {
//            NSLog(@"%@", [NSString stringWithFormat:@"[%@] Wifi is not availabe.", sensorName]);
//            return NO;
//        }
//        
//        // check battery condition
//        if (isSyncWithOnlyBatteryCharging) {
//            NSInteger batteryState = [UIDevice currentDevice].batteryState;
//            if ( batteryState == UIDeviceBatteryStateCharging || batteryState == UIDeviceBatteryStateFull) {
//            }else{
//                NSLog(@"%@", [NSString stringWithFormat:@"[%@] This device is not charginig battery now.", sensorName]);
//                return NO;
//            }
//        }
//        
//        // ======== start loop for uploadsing data! ===============
//        if(dbCondition == AwareDBConditionDeleting || dbCondition == AwareDBConditionInserting){
//            return NO;
//        }else{
//            dbCondition = AwareDBConditionFetching; // SQLite is **locked**
//        }
//    
//        // 1. get number of entities from SQLite
//        NSFetchRequest* request = [[NSFetchRequest alloc] init];
//        [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
//        [request setIncludesSubentities:NO];
//        [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", [self getTimeMark]]];
//    
//        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [private setParentContext:_mainQueueManagedObjectContext];
//        [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
//        [request setIncludesSubentities:NO];
//        
//        [private performBlock:^{
//            NSError* error = nil;
//            NSInteger count = [private countForFetchRequest:request error:&error];
//            if (count == NSNotFound) { // <- the number of entities is zero(0)
//                [self dataSyncIsFinishedCorrectoly];
//                NSLog(@"[%@] There are no data in this database table",[self getEntityName]);
//                dbCondition = AwareDBConditionNormal;
//                [self dataSyncIsFinishedCorrectoly];
//                [self setTimeMarkWithTimestamp:[self getTimeMark]];
//                
//                NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
//                [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
//                [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
//                [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
//                [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
//                [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
//                                                                    object:nil
//                                                                  userInfo:userInfo];
//                return;
////                return YES;
//            } else if(error != nil){ // <- the query has some error
//                [self dataSyncIsFinishedCorrectoly];
//                NSLog(@"%@", error.description);
//                dbCondition = AwareDBConditionNormal;
//                count = 0;
//                return;
////                return NO;
//            }
//            
//            // 2. set repetation count
//            repetitionTime = (int)count/(int)[self getFetchLimit];
//            
//            /** ============================= */
//            if(entityName == nil){
//                NSLog(@"Entity Name is 'nil'. Please check the initialozation of this class.");
//            }
//            
//            for (int i=0; i<repetitionTime; i++) { // i = current repetation count
//                //3. get sensor data
//                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
//                [fetchRequest setFetchLimit:[self getFetchLimit]];
//                if ([self getFetchBatchSize] != 0) {
//                    [fetchRequest setFetchBatchSize:[self getFetchBatchSize]];
//                }
//                //3.1. set limit option
//                [fetchRequest setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
//                [fetchRequest setIncludesSubentities:NO];
//                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", [self getTimeMark]]];
//                //3.2. set sort option
//                NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
//                NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
//                [fetchRequest setSortDescriptors:sortDescriptors];
//                
//                //4. get entities from managedObjectContext with options
////                AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
////                NSArray *results = [delegate.managedObjectContext executeFetchRequest:fetchRequest error:nil] ;
//                NSArray *results = [private executeFetchRequest:fetchRequest error:nil] ;
//                
//                
//                //4.1. unlock the DB
//                dbCondition = AwareDBConditionNormal;
//                
//                //4.2. check result of the query
//                if (results.count == 0 || results.count == NSNotFound) {
//                    [self dataSyncIsFinishedCorrectoly];
//                    [self setTimeMarkWithTimestamp:[self getTimeMark]];
//                    
//                    NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
//                    [userInfo setObject:@100 forKey:@"KEY_UPLOAD_PROGRESS_STR"];
//                    [userInfo setObject:@YES forKey:@"KEY_UPLOAD_FIN"];
//                    [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
//                    [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
//                                                                        object:nil
//                                                                      userInfo:userInfo];
//                    return;
//    //                return YES;
//                }
//                
//                //4.3. get timestamp from the list
//                NSMutableArray *array = [[NSMutableArray alloc] init];
//                for (NSManagedObject *data in results) {
//                    NSArray *keys = [[[data entity] attributesByName] allKeys];
//                    NSDictionary *dict = [data dictionaryWithValuesForKeys:keys];
//                    unixtimeOfUploadingData = [dict objectForKey:@"timestamp"];
//                    [array addObject:dict];
//                }
//                
//                //5. upload the data
//                if (results != nil) {
//                    NSError * error = nil;
//                    // 5.1. convert array to json data
//                    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:array options:0 error:&error];
//                    if (error == nil && jsonData != nil) {
//                        // 5.2. Set session configuration
//                        NSURLSessionConfiguration *sessionConfig = nil;
//                        double unxtime = [[NSDate new] timeIntervalSince1970];
//                        syncDataQueryIdentifier = [NSString stringWithFormat:@"%@%f", baseSyncDataQueryIdentifier, unxtime];
//                        sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:syncDataQueryIdentifier];
//                        sessionConfig.timeoutIntervalForRequest = 60 * 3;
//                        sessionConfig.HTTPMaximumConnectionsPerHost = 60 * 3;
//                        sessionConfig.timeoutIntervalForResource = 60 * 3;
//                        sessionConfig.allowsCellularAccess = NO;
//                        
//                        // 5.3. set HTTP/POST body information
//                        NSString* post = [NSString stringWithFormat:@"device_id=%@&data=", deviceId];
//                        NSData* postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
//                        NSMutableData * mutablePostData = [[NSMutableData alloc] initWithData:postData];
//                        [mutablePostData appendData:jsonData];
//                        NSString* postLength = [NSString stringWithFormat:@"%ld", [mutablePostData length]];
//                        NSMutableURLRequest* request = [[NSMutableURLRequest alloc] init];
//                        [request setURL:[NSURL URLWithString:url]];
//                        [request setHTTPMethod:@"POST"];
//                        [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
//                        [request setHTTPBody:mutablePostData];
//                        
//                        // 5.4. send query
//                        NSString* responseStr = nil;
//                        int responseCode = 200;
//                        NSError * e;
//                        NSHTTPURLResponse *response = nil;
//                        NSData *resData = [NSURLConnection sendSynchronousRequest:request
//                                                                returningResponse:&response error:&e];
//                        responseStr = [[NSString alloc] initWithData:resData encoding:NSUTF8StringEncoding];
//                        responseCode = (int)[response statusCode];
//                        
//                        // 5.5. show result
//                        if(![responseStr isEqualToString:@""]){
//                            NSLog(@"[%@] %@", [self getEntityName], responseStr);
//                        }
//                        
//                        // 5.6. set current state
//                        double progress = (double)i/(double)repetitionTime*100.0f;
//                        syncProgress = [NSString stringWithFormat:@"[%@] %0.2f %% of data is uploaded", sensorName, progress];
//                        NSLog(@"%@",syncProgress);
//                        
//                        if(responseCode != 200 ){
//                            NSNumber *finish = @NO;
//                            NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
//                            if (i == repetitionTime-1) {
//                                progress = 100;
//                                finish = @YES;
//                            }
//                            [userInfo setObject:@(progress) forKey:@"KEY_UPLOAD_PROGRESS_STR"];
//                            [userInfo setObject:finish forKey:@"KEY_UPLOAD_FIN"];
//                            [userInfo setObject:@NO forKey:@"KEY_UPLOAD_SUCCESS"];
//                            [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
//                                                                                object:nil
//                                                                              userInfo:userInfo];
//                            return;
//                            //                          return NO;
//                        }else{
//                            [self setTimeMarkWithTimestamp:[self getTimeMark]];
//
//                            NSNumber *finish = @NO;
//                            NSMutableDictionary * userInfo = [[NSMutableDictionary alloc] init];
//                            if (i == repetitionTime-1) {
//                                progress = 100;
//                                finish = @YES;
//                            }
//                            [userInfo setObject:@(progress) forKey:@"KEY_UPLOAD_PROGRESS_STR"];
//                            [userInfo setObject:finish forKey:@"KEY_UPLOAD_FIN"];
//                            [userInfo setObject:@YES forKey:@"KEY_UPLOAD_SUCCESS"];
//                            [userInfo setObject:sensorName forKey:@"KEY_UPLOAD_SENSOR_NAME"];
//                            [[NSNotificationCenter defaultCenter] postNotificationName:@"ACTION_AWARE_DATA_UPLOAD_PROGRESS"
//                                                                                object:nil
//                                                                              userInfo:userInfo];
//                        }
//                        
//                    }
//                }
//            }
//        }];
    
    return YES;
}

- (NSString *) getSyncProgressAsText:(NSString *)sensorName{
    return syncProgress;
}

- (NSString *)getSyncProgressAsText{
    return syncProgress;
}


//        NSInteger categoryCount = [self getCategoryCountFromTimestamp:unixtimeOfUploadingData];
//        if(isDebug){
//
//            if (categoryCount < [self getFetchLimit]) {
//                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Success to upload sensor data to AWARE server with %d records",sensorName,(int)categoryCount] soundFlag:NO];
//            }else{
//                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Success to upload sensor data to AWARE server with %d/%d records",sensorName,[self getFetchLimit],(int)categoryCount] soundFlag:NO];
//            }
//        }
//
//        if(unixtimeOfUploadingData != nil){ // TODO
//            [self setTimeMarkWithTimestamp:unixtimeOfUploadingData];
//        }
//
//        if(categoryCount == -1){ // TODO
//            [self uploadSensorDataInBackground];
//        }
//
////        NSLog(@"%ld", categoryCount);
//        if (categoryCount < [self getFetchLimit] ){
//            [self dataSyncIsFinishedCorrectoly];
//        }else{
//            [self uploadSensorDataInBackground];
//        }



//- (void) removeUploadedDate {
//
//    if(dbCondition == AwareDBConditionFetching || dbCondition == AwareDBConditionCounting ){
//        NSLog(@"[%@]The DB is woring for fetching or counting the record", [self getEntityName]);
//        return ;
//    }else{
//        dbCondition = AwareDBConditionDeleting;
//    }
//    @try {
//
//        NSFetchRequest* request = [[NSFetchRequest alloc] init];
//        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
//        [private setParentContext:_mainQueueManagedObjectContext];
//        [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
//        [request setIncludesSubentities:NO];
//
//        [private performBlock:^{
//            NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
//
////            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
//
//            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
//            NSNumber * timestamp = [self getTimeMark];
//
//            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp < %@", timestamp]];
//
//            NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
//
//            NSError *deleteError = nil;
//            [private executeRequest:delete error:&deleteError];
//            if (deleteError != nil) {
//                NSLog(@"%@", deleteError.description);
//            }
//            //    [delegate.managedObjectContext reset];
//            dbCondition = AwareDBConditionNormal;
//        }];
//
//    } @catch (NSException *exception) {
//         NSLog(@"%@", exception.reason);
//        [self dataSyncIsFinishedCorrectoly];
//    } @finally {
//
//    }
//
//}



//- (NSUInteger)getCategoryCountFromTimestamp:(NSNumber *) timestamp {
//    //    NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
//    if(dbCondition == AwareDBConditionInserting || dbCondition == AwareDBConditionDeleting){
//        NSLog(@"[%@]DB is woring for 'inserting' or 'deleting' the data.",[self getEntityName]);
//        return -1;
//    }else{
//        dbCondition = AwareDBConditionNormal;
//    }
//
//
//    NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
//
//    NSUInteger count = 0;
//    @try {
//        NSFetchRequest* request = [[NSFetchRequest alloc] init];
//        if([NSThread isMainThread]){
//            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
//            [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:delegate.managedObjectContext]];
//            [request setIncludesSubentities:NO];
//
//            //        NSNumber * timestamp = [self getTimeMark];
//            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];
//
//            NSError* error = nil;
//            count = [delegate.managedObjectContext countForFetchRequest:request error:&error];
//            if (count == NSNotFound) {
//                count = 0;
//            }
//            if(error != nil){
//                NSLog(@"%@", error.description);
//                count = 0;
//            }
//        }else{
//            NSLog(@"[%@] This thread is not main thread!",[self getEntityName]);
//        }
//    }@catch (NSException *exception) {
//        NSLog(@"%@", exception.reason);
//        [self dataSyncIsFinishedCorrectoly];
//    }@finally{
//        dbCondition = AwareDBConditionNormal;
//    }
//    //    [delegate.managedObjectContext reset];
//    return count;
//
//}



@end
