//
//  DBTableCreator.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 2018/03/12.
//  Copyright © 2018 Yuuki NISHIYAMA. All rights reserved.
//

#import "DBTableCreator.h"

@implementation DBTableCreator{
    AWAREStudy * awareStudy;
    NSString* entityName;
    NSString* sensorName;
    NSString *tableName;
    NSString * baseCreateTableQueryIdentifier;
    NSMutableData * recievedData;
}

- (instancetype)initWithAwareStudy:(AWAREStudy *)study sensorName:(NSString *)name dbEntityName:(NSString *)entity{
    self = [super init];
    if(self!=nil){
        awareStudy = study;
        sensorName = name;
        tableName = name;
        entityName = entity;
        recievedData = [[NSMutableData alloc] init];
        baseCreateTableQueryIdentifier = [NSString stringWithFormat:@"create_table_query_identifier_%@",  sensorName];
    }
    return self;
}

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
    post = [NSString stringWithFormat:@"device_id=%@&fields=%@", [awareStudy getDeviceId], query];
    postData = [post dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    postLength = [NSString stringWithFormat:@"%ld", [postData length]];

    request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:[self getCreateTableUrl:tableName]]];
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];

    // Generate an unique identifier for background HTTP/POST on iOS
    sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:baseCreateTableQueryIdentifier];
    sessionConfig.timeoutIntervalForRequest = 10;
    sessionConfig.HTTPMaximumConnectionsPerHost = 10;
    sessionConfig.timeoutIntervalForResource = 10;
    sessionConfig.allowsCellularAccess = YES;

    session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:self delegateQueue:nil];
    [session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        if (dataTasks.count == 0) {
            NSURLSessionDataTask* dataTask = [session dataTaskWithRequest:request];
            [dataTask resume];
        }
    }];
}


- (NSString *)getCreateTableUrl:(NSString *)name{
    //    - create_table: creates a table if it doesn’t exist already
    return [NSString stringWithFormat:@"%@/%@/create_table", [self getWebserviceUrl], name];
}

- (NSString *)getWebserviceUrl{
    NSString* url = [awareStudy getWebserviceServer];
    if (url == NULL || [url isEqualToString:@""]) {
        NSLog(@"[Error] You did not have a StudyID. Please check your study configuration.");
        return @"";
    }
    return url;
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler{
    
    completionHandler(NSURLSessionResponseAllow);
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
    int responseCode = (int)[httpResponse statusCode];
    if ( responseCode == 200 ) {
        [session finishTasksAndInvalidate];
    } else {
        [session invalidateAndCancel];
    }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data{
    if (data != nil) {
        [recievedData appendData:data];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    if(error!=nil && recievedData != nil){
        NSString * result = [[NSString alloc] initWithData:recievedData encoding:NSUTF8StringEncoding];
        NSLog(@"%@",result);
    }
}


@end
