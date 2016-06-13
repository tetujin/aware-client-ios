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
    
    NSString * timeMarkerIdentifier;
    double httpStartTimestamp;
    double postedTextLength;
    BOOL isDebug;
    BOOL isUploading;
    BOOL isSyncWithOnlyBatteryCharging;
    int errorPosts;
    
    NSNumber * unixtimeOfUploadingData;
    
    AwareDBCondition dbCondition;
    
    int currentRepetitionCounts; // current repetition count
    int repetitionTime;          // max repetition count
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
        baseSyncDataQueryIdentifier = [NSString stringWithFormat:@"sync_data_query_identifier_%@", sensorName];
        baseCreateTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
        timeMarkerIdentifier = [NSString stringWithFormat:@"uploader_coredata_timestamp_marker_%@", sensorName];
        
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
        [[[NSOperationQueue alloc] init] addOperationWithBlock:^{
            [self startSyncDBwithSetUploadTimes:[self getTimeMark]];
        }];
    }else{
        [self startSyncDBwithSetUploadTimes:[self getTimeMark]];
    }
    
    isUploading = YES;
//    [self uploadSensorDataInBackground];
}


- (BOOL)syncAwareDBInForeground{
    [self syncAwareDBInBackground];
    return YES;
}


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


/////////////////////////////////////////////////
/////////////////////////////////////////////////


- (bool) saveDataToDB {
    if(dbCondition == AwareDBConditionCounting || dbCondition == AwareDBConditionFetching){
        NSLog(@"[%@]DB is woring for 'counting' or 'fetching' the data.", [self getEntityName]);
        return false;
    }
    dbCondition = AwareDBConditionInserting;
    @try {
        NSError *error = nil;
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        if (! [delegate.managedObjectContext save:&error]) {
            NSLog(@"Error saving context: %@\n%@",
                  [error localizedDescription], [error userInfo]);
        }
        if(isDebug){
            NSLog(@"Save [%@] to SQLite", [self getEntityName]);
        }
    }@catch(NSException *exception) {
        NSLog(@"%@", exception.reason);
        dbCondition = AwareDBConditionNormal;
        return false;
    }@finally{
        dbCondition = AwareDBConditionNormal;
    }
    return true;
}


/**
 * start sync db with timestamp
 * @discussion Please call this method in the background
 */
- (BOOL) startSyncDBwithSetUploadTimes:(NSNumber *) timestamp {
    @try {
        if(dbCondition == AwareDBConditionDeleting || dbCondition == AwareDBConditionInserting){
            return NO;
        }else{
            dbCondition = AwareDBConditionCounting;
        }
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
        [private setParentContext:_mainQueueManagedObjectContext];
        [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
        [request setIncludesSubentities:NO];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];
        
        [private performBlock:^{
            NSError* error = nil;
            // Get count of category
            NSInteger count = [private countForFetchRequest:request error:&error];
            // Set repetationCount
            currentRepetitionCounts = 0;
            repetitionTime = (int)count/(int)[self getFetchLimit];
            [self uploadSensorDataInBackground];
            if (count == NSNotFound) {
                repetitionTime = 0;
                [self dataSyncIsFinishedCorrectoly];
            }
            if(error != nil){
                repetitionTime = 0;
                [self dataSyncIsFinishedCorrectoly];
                NSLog(@"%@", error.description);
                count = 0;
            }
            
            // set db condition as normal
            dbCondition = AwareDBConditionNormal;
            
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



- (void) removeUploadedDate {
    
    if(dbCondition == AwareDBConditionFetching || dbCondition == AwareDBConditionCounting ){
        NSLog(@"[%@]The DB is woring for fetching or counting the record", [self getEntityName]);
        return ;
    }else{
        dbCondition = AwareDBConditionDeleting;
    }
    @try {
        NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
        
        AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:entityName];
        NSNumber * timestamp = [self getTimeMark];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp < %@", timestamp]];
        
        NSBatchDeleteRequest *delete = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
        
        NSError *deleteError = nil;
        [delegate.managedObjectContext executeRequest:delete error:&deleteError];
        if (deleteError != nil) {
            NSLog(@"%@", deleteError.description);
        }
        //    [delegate.managedObjectContext reset];
    } @catch (NSException *exception) {
         NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectoly];
    } @finally {
        dbCondition = AwareDBConditionNormal;
    }
    
}



- (NSUInteger)getCategoryCountFromTimestamp:(NSNumber *) timestamp {
    //    NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
    if(dbCondition == AwareDBConditionInserting || dbCondition == AwareDBConditionDeleting){
        NSLog(@"[%@]DB is woring for 'inserting' or 'deleting' the data.",[self getEntityName]);
        return -1;
    }else{
        dbCondition = AwareDBConditionNormal;
    }
    
    
    NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
    
    NSUInteger count = 0;
    @try {
        NSFetchRequest* request = [[NSFetchRequest alloc] init];
        if([NSThread isMainThread]){
            AppDelegate *delegate=(AppDelegate*)[UIApplication sharedApplication].delegate;
            [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:delegate.managedObjectContext]];
            [request setIncludesSubentities:NO];
            
            //        NSNumber * timestamp = [self getTimeMark];
            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];
            
            NSError* error = nil;
            count = [delegate.managedObjectContext countForFetchRequest:request error:&error];
            if (count == NSNotFound) {
                count = 0;
            }
            if(error != nil){
                NSLog(@"%@", error.description);
                count = 0;
            }
        }else{
            NSLog(@"[%@] This thread is not main thread!",[self getEntityName]);
            //            NSManagedObjectContext *private = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
            //            [private setParentContext:_mainQueueManagedObjectContext];
            //            [request setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:_mainQueueManagedObjectContext]];
            //            [request setIncludesSubentities:NO];
            //
            //            //        NSNumber * timestamp = [self getTimeMark];
            //            [request setPredicate:[NSPredicate predicateWithFormat:@"timestamp >= %@", timestamp]];
            //
            //            [private performBlock:^{
            //                NSError* error = nil;
            //                NSInteger count =
            //                [private countForFetchRequest:request error:&error];
            //                if (count == NSNotFound) {
            //                    count = 0;
            //                }
            //                if(error != nil){
            //                    NSLog(@"%@", error.description);
            //                    count = 0;
            //                }
            //            }];
        }
    }@catch (NSException *exception) {
        NSLog(@"%@", exception.reason);
        [self dataSyncIsFinishedCorrectoly];
    }@finally{
        dbCondition = AwareDBConditionNormal;
    }
    //    [delegate.managedObjectContext reset];
    return count;
    
}


//////////////////////////////////////////////////
//////////////////////////////////////////////////

/**
 * Upload method
 */
- (void) uploadSensorDataInBackground {
    
    currentRepetitionCounts++;
    
    NSString *deviceId = [self getDeviceId];
    NSString *url = [self getInsertUrl:sensorName];
    
    // Get sensor data from CoreData
    if(unixtimeOfUploadingData == nil){
        unixtimeOfUploadingData = [self getTimeMark];
    }
 
    if(dbCondition == AwareDBConditionInserting || dbCondition == AwareDBConditionDeleting){
        NSLog(@"[%@]The DB is working for 'inserting' or 'deleting' the data.", [self getEntityName]);
        return;
    }else{
        // Block other connection by other process to this db
        dbCondition = AwareDBConditionFetching;
    }
        
    if(entityName == nil){
        NSLog(@"Entity Name is 'nil'. Please check the initialozation of this class.");
    }
        
    NSLog(@"[%@] %d", [self getEntityName], [NSThread isMainThread]);
        
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
        NSString *networkPeformance = [NSString stringWithFormat:@"%0.2f KB/s",postedTextLength/diff/1000.0f];
        NSLog(@"[%@] %@", sensorName, networkPeformance);
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
        
        if(isDebug){
            if (currentRepetitionCounts > repetitionTime) {
                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Finish to upload data",sensorName] soundFlag:NO];
            }else{
                [AWAREUtils sendLocalNotificationForMessage:[NSString stringWithFormat:@"[%@] Success to upload sensor data to AWARE server with %d %%",sensorName, (int)(currentRepetitionCounts/repetitionTime*100)]  soundFlag:NO];
            }
        }
    
        if (currentRepetitionCounts > repetitionTime ){
            [self dataSyncIsFinishedCorrectoly];
        }else{
            [self uploadSensorDataInBackground];
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

- (void) dataSyncIsFinishedCorrectoly {
    isUploading = NO;
//    [self removeUploadedDate];
    NSLog(@"[%@] Session task finished correctly.", sensorName);
    errorPosts = 0;
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




@end
