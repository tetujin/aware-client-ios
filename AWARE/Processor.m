//
//  Processor.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/20/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//
// https://developer.apple.com/library/prerelease/ios/documentation/Cocoa/Reference/Foundation/Classes/NSProcessInfo_Class/index.html#//apple_ref/doc/constant_group/NSProcessInfo_Operating_Systems
//

#import "Processor.h"
#import <sys/sysctl.h>
#import <sys/types.h>
#import <sys/param.h>
#import <sys/mount.h>
#import <mach/mach.h>
#import <mach/processor_info.h>
#import <mach/mach_host.h>

@implementation Processor{
//    NSTimer * uploadTimer;
    NSTimer * sensingTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName withAwareStudy:(AWAREStudy *)study{
    self = [super initWithSensorName:sensorName withAwareStudy:study];
    if (self) {
    }
    return self;
}


- (void) createTable{
    NSLog(@"[%@] Create Table", [self getSensorName]);
    NSString *query = [[NSString alloc] init];
    query = @"_id integer primary key autoincrement,"
    "timestamp real default 0,"
    "device_id text default '',"
    "double_last_user real default 0,"
    "double_last_system real default 0,"
    "double_last_idle real default 0,"
    "double_user_load real default 0,"
    "double_system_load real default 0,"
    "double_idle real default 0,"
    "UNIQUE (timestamp,device_id)";
    [super createTable:query];
}



- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    // Get a sensing frequency
    double frequency = [self getSensorSetting:settings withKey:@"frequency_processor"];
    if(frequency < 1.0f ){
        frequency = 10.0f;
    }
    NSLog(@"[%@] Sensing requency is %f ",[self getSensorName], frequency);
    
    // Set a buffer size for reducing file access
    [self setBufferSize:100];
    
    // Set and start data uploader with a data upload interval
//    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval
//                                                   target:self
//                                                 selector:@selector(syncAwareDB)
//                                                 userInfo:nil
//                                                  repeats:YES];
    
    
    //
    NSLog(@"[%@] Start Processor Sensor", [self getSensorName]);
    sensingTimer = [NSTimer scheduledTimerWithTimeInterval:frequency
                                                    target:self
                                                  selector:@selector(getSensorData)
                                                  userInfo:nil
                                                   repeats:YES];
    return YES;
}

- (void) getSensorData{
    // Get a CPU usage
//    float cpuUsageFloat = [self getCpuUsage];
//    NSNumber *appCpuUsage = [NSNumber numberWithFloat:cpuUsageFloat];
//    NSNumber *idleCpuUsage = [NSNumber numberWithFloat:(100.0f-cpuUsageFloat)];
//
//    // Save sensor data to the local database.
//    NSNumber * unixtime = [AWAREUtils getUnixTimestamp:[NSDate new]];
//    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
//    [dic setObject:unixtime forKey:@"timestamp"];
//    [dic setObject:[self getDeviceId] forKey:@"device_id"];
//    [dic setObject:appCpuUsage forKey:@"double_last_user"]; //double
//    [dic setObject:@0 forKey:@"double_last_system"]; //double
//    [dic setObject:idleCpuUsage forKey:@"double_last_idle"]; //double
//    [dic setObject:@0 forKey:@"double_user_load"];//double
//    [dic setObject:@0 forKey:@"double_system_load"]; //double
//    [dic setObject:@0 forKey:@"double_idle_load"]; //double
//    [self setLatestValue:[NSString stringWithFormat:@"%@ %%",appCpuUsage]];
//    [self saveData:dic toLocalFile:SENSOR_PROCESSOR];
//    
//    malloc(cpuUsageFloat);
}

- (BOOL)stopSensor{
    [sensingTimer invalidate];
    return YES;
}



////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////



- (float) getDeviceCpuUsage{
    
    float userTotalCpuUsage = 0;
    
    processor_info_array_t _cpuInfo, _prevCPUInfo = nil;
    mach_msg_type_number_t _numCPUInfo, _numPrevCPUInfo = 0;
    unsigned _numCPUs;
    NSLock *_cpuUsageLock;
    
    int _mib[2U] = { CTL_HW, HW_NCPU };
    size_t _sizeOfNumCPUs = sizeof(_numCPUs);
    int _status = sysctl(_mib, 2U, &_numCPUs, &_sizeOfNumCPUs, NULL, 0U);
    if(_status)
        _numCPUs = 1;
    
    _cpuUsageLock = [[NSLock alloc] init];
    
    natural_t _numCPUsU = 0U;
    kern_return_t err = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &_numCPUsU, &_cpuInfo, &_numCPUInfo);
    if(err == KERN_SUCCESS) {
        [_cpuUsageLock lock];
        
        for(unsigned i = 0U; i < _numCPUs; ++i) {
            Float32 _inUse, _total;
            if(_prevCPUInfo) {
                _inUse = (
                          (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER]   - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM])
                          + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE])
                          );
                _total = _inUse + (_cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - _prevCPUInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
            } else {
                _inUse = _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_USER] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_NICE];
                _total = _inUse + _cpuInfo[(CPU_STATE_MAX * i) + CPU_STATE_IDLE];
            }
            
            NSLog(@"Core : %u, Usage: %.2f%%", i, _inUse / _total * 100.f);
            userTotalCpuUsage = userTotalCpuUsage + (_inUse / _total * 100.f); // TODO
        }
        userTotalCpuUsage = userTotalCpuUsage/_numCPUs; //TODO
        
        [_cpuUsageLock unlock];
        
        if(_prevCPUInfo) {
            size_t prevCpuInfoSize = sizeof(integer_t) * _numPrevCPUInfo;
            vm_deallocate(mach_task_self(), (vm_address_t)_prevCPUInfo, prevCpuInfoSize);
        }
        
        _prevCPUInfo = _cpuInfo;
        _numPrevCPUInfo = _numCPUInfo;
        
        _cpuInfo = nil;
        _numCPUInfo = 0U;
    } else {
        NSLog(@"Error!");
    }
    return userTotalCpuUsage;
}

- (float) getCpuUsage{
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;
    
    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    
    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;
    
    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;
    
    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads
    
    basic_info = (task_basic_info_t)tinfo;
    
    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;
    
    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;
    
    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }
        
        basic_info_th = (thread_basic_info_t)thinfo;
        
        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->system_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }
        
    } // for each thread
    
    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);
    
//    NSLog(@"%ld, %ld, %f", tot_sec, tot_usec, tot_cpu);
//    NSString* value = [NSString stringWithFormat:@""];
    
    return tot_cpu;
}

- (long) getMemory {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(),
                                   TASK_BASIC_INFO,
                                   (task_info_t)&info,
                                   &size);
    long memoryUsage = 0;
    if( kerr == KERN_SUCCESS ) {
        NSLog(@"Memory in use (in bytes): %lu", info.resident_size);
        memoryUsage = info.resident_size;
    } else {
        NSLog(@"Error with task_info(): %s", mach_error_string(kerr));
    }
    return memoryUsage;
}


@end
