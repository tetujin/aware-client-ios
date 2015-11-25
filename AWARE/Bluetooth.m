//
//  bluetooth.m
//  AWARE
//
//  Created by Yuuki Nishiyama on 11/24/15.
//  Copyright © 2015 Yuuki NISHIYAMA. All rights reserved.
//

#import "Bluetooth.h"

@implementation Bluetooth{
    NSTimer * uploadTimer;
}

- (instancetype)initWithSensorName:(NSString *)sensorName{
    self = [super initWithSensorName:sensorName];
    if (self) {
        [super setSensorName:sensorName];
    }
    return self;
}

- (BOOL)startSensor:(double)upInterval withSettings:(NSArray *)settings{
    NSLog(@"Start Blutooth sensing");
    _myCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    uploadTimer = [NSTimer scheduledTimerWithTimeInterval:upInterval target:self selector:@selector(uploadSensorData) userInfo:nil repeats:YES];
    return YES;
}

- (BOOL)stopSensor{
    [_myCentralManager stopScan];
    [uploadTimer invalidate];
    return YES;
}

- (void)uploadSensorData{
    NSString * jsonStr = [self getData:SENSOR_BLUETOOTH withJsonArrayFormat:YES];
    [self insertSensorData:jsonStr withDeviceId:[self getDeviceId] url:[self getInsertUrl:SENSOR_BLUETOOTH]];
}


- (void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    NSLog(@"centralManagerDidUpdateState");
    if([central state] == CBCentralManagerStatePoweredOff){
        NSLog(@"CoreBluetooth BLE hardware is powered off");
    }else if([central state] == CBCentralManagerStatePoweredOn){
        NSLog(@"CoreBluetooth BLE hardware is powered on");
        NSArray *services = @[
                            [CBUUID UUIDWithString:BATTERY_SERVICE],
                            [CBUUID UUIDWithString:BODY_COMPOSITION_SERIVCE],
                            [CBUUID UUIDWithString:CURRENT_TIME_SERVICE],
                            [CBUUID UUIDWithString:DEVICE_INFORMATION],
                            [CBUUID UUIDWithString:ENVIRONMENTAL_SENSING],
                            [CBUUID UUIDWithString:GENERIC_ACCESS],
                            [CBUUID UUIDWithString:GENERIC_ATTRIBUTE],
                            [CBUUID UUIDWithString:MEASUREMENT],
                            [CBUUID UUIDWithString:BODY_LOCATION],
                            [CBUUID UUIDWithString:MANUFACTURER_NAME],
                            [CBUUID UUIDWithString:HEART_RATE_UUID],
                            [CBUUID UUIDWithString:HTTP_PROXY_UUID],
                            [CBUUID UUIDWithString:HUMAN_INTERFACE_DEVICE],
                            [CBUUID UUIDWithString:INDOOR_POSITIONING],
                            [CBUUID UUIDWithString:LOCATION_NAVIGATION ],
                            [CBUUID UUIDWithString:PHONE_ALERT_STATUS],
                            [CBUUID UUIDWithString:REFERENCE_TIME],
                            [CBUUID UUIDWithString:SCAN_PARAMETERS],
                            [CBUUID UUIDWithString:TRANSPORT_DISCOVERY],
                            [CBUUID UUIDWithString:USER_DATA],
                            [CBUUID UUIDWithString:@"AA80"]
                              ];
        [central scanForPeripheralsWithServices:services options:nil];
    }else if([central state] == CBCentralManagerStateUnauthorized){
        NSLog(@"CoreBluetooth BLE hardware is unauthorized");
    }else if([central state] == CBCentralManagerStateUnknown){
        NSLog(@"CoreBluetooth BLE hardware is unknown");
    }else if([central state] == CBCentralManagerStateUnsupported){
        NSLog(@"CoreBluetooth BLE hardware is unsupported on this platform");
    }
}




- (void) centralManager:(CBCentralManager *)central
  didDiscoverPeripheral:(CBPeripheral *)peripheral
      advertisementData:(NSDictionary *)advertisementData
                   RSSI:(NSNumber *)RSSI
{
    NSLog(@"Discovered %@", peripheral.name);
    NSLog(@"UUID %@", peripheral.identifier);
    NSLog(@"%@", peripheral);
    NSString *name = peripheral.name;
    NSString *uuid = peripheral.identifier.UUIDString;
    if (!name) name = @"";
    if (!uuid) uuid = @"";
    
//    NSLog(@"Discovered characteristic %@", characteristic);
    NSTimeInterval timeStamp = [[NSDate date] timeIntervalSince1970];
    NSNumber* unixtime = [NSNumber numberWithDouble:timeStamp];
    NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
    [dic setObject:unixtime forKey:@"timestamp"];
    [dic setObject:[self getDeviceId] forKey:@"device_id"];
    [dic setObject:uuid forKey:@"bt_address"]; //varchar
    [dic setObject:name forKey:@"bt_name"]; //text
    [dic setObject:RSSI  forKey:@"bt_rssi"]; //int
    [dic setObject:@"BLE" forKey:@"label"]; //text
    [self setLatestValue:[NSString stringWithFormat:@"%@, %@, %@", name, uuid, RSSI]];
    [self saveData:dic toLocalFile:SENSOR_BLUETOOTH];

    // only scan
//    _peripheralDevice = peripheral;
//    _peripheralDevice.delegate = self;
//    [_myCentralManager connectPeripheral:_peripheralDevice options:nil];
}



- (void) centralManager:(CBCentralManager *) central
   didConnectPeripheral:(CBPeripheral *)peripheral
{
    NSLog(@"Peripheral connected");
    peripheral.delegate = self;
    [peripheral discoverServices:nil];
}



- (void)peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    for (CBService *service in peripheral.services) {
        NSLog(@"Discoverd serive %@", service.UUID);
        [peripheral discoverCharacteristics:nil forService:service];
    }
}




- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    for (CBCharacteristic *characteristic in service.characteristics) {
        //[_peripheralDevice readValueForCharacteristic:characteristic];
//        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HUM_CONF]]){ // 湿度
//            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_HUM_DATA from:service]];
//        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_IRT_CONF]]){ //気温
//            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_IRT_DATA from:service]];
//        } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_OPT_CONF]]){ // 温度
//            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_OPT_DATA from:service]];
//        } else if ( [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BAR_CONF]]){ //気圧
//            [peripheral writeValue:enableData forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
//            [peripheral setNotifyValue:YES forCharacteristic:[self getCharateristicWithUUID:UUID_BAR_DATA from:service]];
//        } else if ( [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MOV_CONF]]){ //モーションセン
//        } else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_ID_DATA]]){ // ビープ音
//        }
    }
}



- (CBCharacteristic *) getCharateristicWithUUID:(NSString *)uuid from:(CBService *) cbService
{
    for (CBCharacteristic *characteristic in cbService.characteristics) {
        if([characteristic.UUID isEqual:[CBUUID UUIDWithString:uuid]]){
            return characteristic;
        }
    }
    return nil;
}


- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic
             error:(NSError *)error
{
    NSLog(@"---");
//    if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_MOV_DATA]]){
//        [self getMotionData:characteristic.value];
//    } else if([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_HUM_DATA]]){ // 湿度
//        [self getHumidityData:characteristic.value];
//    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_IRT_DATA]]){ //気温
//        [self getTemperatureData:characteristic.value];
//    } else if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_OPT_DATA]]){ //光 Optical Sensor
//        [self getOpticalData:characteristic.value];
//    } else if ( [characteristic.UUID isEqual:[CBUUID UUIDWithString:UUID_BAR_DATA]]){ //気圧 Barometric Pressure Sensor
//        [self getBmpData:characteristic.value];
//    }
}



@end
