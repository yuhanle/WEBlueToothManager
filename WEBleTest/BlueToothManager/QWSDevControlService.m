//
//  QWSDevControlService.m
//  WEBluetooth
//
//  Created by yuhanle on 15/7/23.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import "QWSDevControlService.h"
#import "QWSDiscovery.h"

NSString *kDevControllServiceUUIDString                 = @"FF15";
NSString *kDevDeviceWriteCharacteristicUUIDString       = @"FF01";
NSString *kDevDeviceReadCharacteristicUUIDString        = @"FF02";
NSString *kDevDeviceSoftVersionCharacteristicUUIDString = @"FF03";
NSString *kDevDeviceInfoCharacteristicUUIDString        = @"FF04";
NSString *kDevDeviceStateCharacteristicUUIDString       = @"FF05";

NSString *kAlarmServiceEnteredBackgroundNotification    = @"kAlarmServiceEnteredBackgroundNotification";
NSString *kAlarmServiceEnteredForegroundNotification    = @"kAlarmServiceEnteredForegroundNotification";

static const NSString * TAG = @"QwsDevControlService";

@interface QWSDevControlService () <CBPeripheralDelegate> {
@private
    CBPeripheral		*servicePeripheral;
    CBService			*devControllService;
}

@property (strong, nonatomic) NSTimer * distanceTimer;

@end

@implementation QWSDevControlService

-(void)dealloc {
    servicePeripheral = nil;
    
    if ([_distanceTimer isValid]) {
        [_distanceTimer invalidate];
        _distanceTimer = nil;
    }
}


#pragma mark -
#pragma mark Init
/****************************************************************************/
/*								Init										*/
/****************************************************************************/
-(instancetype)initWithPeripheral:(CBPeripheral *)peripheral {
    self = [super init];
    if (self) {
        servicePeripheral        = [peripheral copy];
        self.UUIDString          = peripheral.identifier.UUIDString;
        [servicePeripheral setDelegate:self];
    }
    
    return self;
}

-(void)setPeripheral:(CBPeripheral *)peripheral {
    servicePeripheral = peripheral;
    servicePeripheral.delegate = self;
}

- (void) reset
{
    if ([_distanceTimer isValid]) {
        [_distanceTimer invalidate];
        _distanceTimer = nil;
    }
    
    [_executeQueue cancelAllOperations];
}

#pragma mark -
#pragma mark Service interaction
/****************************************************************************/
/*							Service Interactions							*/
/****************************************************************************/
- (void) start
{
    CBUUID	*serviceUUID	= [CBUUID UUIDWithString:kDevControllServiceUUIDString];
    NSArray	*serviceArray	= [NSArray arrayWithObjects:serviceUUID, nil];
    
    [servicePeripheral discoverServices:serviceArray];
    
    [self startReadRssi];
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error
{
    NSArray		*services   = nil;
 
    if (peripheral != servicePeripheral) {
        NSLog(@"Wrong Peripheral.\n");
        return ;
    }
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
        return ;
    }

    services = [peripheral services];
    if (!services || ![services count]) {
        return ;
    }
    
    devControllService = nil;
    
    for (CBService *service in services) {
        if ([[service UUID] isEqual:[CBUUID UUIDWithString:kDevControllServiceUUIDString]]) {
            devControllService = service;
            break;
        }
    }
    
    if (devControllService) {
        [peripheral discoverCharacteristics:nil forService:devControllService];
        [self onServicesDiscovered:peripheral status:1];
    }else {
        [self onServicesDiscovered:peripheral status:0];
    }
}

-(void)onServicesDiscovered:(CBPeripheral *)peripheral status:(int)status {
    NSLog(@"%@, onServiceDiscovered() %d", TAG, status);
    
    QWSDevControlService * device = [[QWSDiscovery sharedInstance] searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
    if (device == nil) {
        NSLog(@"%@, info should not be nil", TAG);
        return;
    }
    
    device.isServiceDiscovered = true;
    
    if (!device.isAutoConnect) {
        device.isNeedCloseAfterDisconnected = true;
    }
    
    if (status == 1) {
        [self broadcastUpdate:peripheral action:ACTION_GATT_SERVICES_DISCOVERED];
    }else {
        [self broadcastError:peripheral reason:ERROR_REASON_SERVICE_DISCOVERY status:status];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    NSArray		*characteristics	= [service characteristics];
    CBCharacteristic *characteristic;
    
    if (peripheral != servicePeripheral) {
        NSLog(@"Wrong Peripheral.\n");
        return ;
    }
    
    if (service != devControllService) {
        NSLog(@"Wrong Service.\n");
        return ;
    }
    
    if (error != nil) {
        NSLog(@"Error %@\n", error);
        return ;
    }
    
    for (characteristic in characteristics) {
        if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:kDevDeviceWriteCharacteristicUUIDString]]) {
            
        }
        else if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:kDevDeviceReadCharacteristicUUIDString]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
        else if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:kDevDeviceInfoCharacteristicUUIDString]]) {
            [peripheral readValueForCharacteristic:characteristic];
        }
        else if ([[characteristic UUID] isEqual:[CBUUID UUIDWithString:kDevDeviceStateCharacteristicUUIDString]]) {
            [peripheral setNotifyValue:YES forCharacteristic:characteristic];
        }
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    NSLog(@"\n%@", [NSString stringWithFormat:@"360骑卫士设备:%@,强度:%ddB", peripheral, [RSSI intValue]]);
    self.RSSI = RSSI;
    
    if (_mState == STATE_CONNECTED || _mState == STATE_CONNECTING) {
        [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_READ_RSSI object:self userInfo:@{EXTRA_ADDRESS:peripheral.identifier.UUIDString, EXTRA_DATA:RSSI == nil ? @0 : RSSI}];
    }
}

- (void) peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (peripheral != servicePeripheral) {
        NSLog(@"Wrong peripheral\n");
        return ;
    }
    
    if ([error code] != 0) {
        [self broadcastError:peripheral reason:ERROR_REASON_READ_CHARACTERISTIC status:_mState];
        NSLog(@"Error %@\n", error);
        return ;
    }
    
    [self broadcastUpdate:peripheral action:ACTION_DATA_AVAILABLE characteristic:characteristic];
}

//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        [self broadcastError:peripheral reason:ERROR_REASON_READ_CHARACTERISTIC status:_mState];
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        NSBlockOperation * op = [[NSBlockOperation alloc]init];
        [op addExecutionBlock:^{
            [peripheral readValueForCharacteristic:characteristic];
        }];
        
        [self addQWSOperation:op];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [[QWSDiscovery sharedInstance] disconnect:peripheral.identifier.UUIDString];
    }
}

//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"%@, onCharacteristicWrite() charcteristic=%@, status=%d", TAG, [characteristic.UUID representativeString], -1);
        [self broadcastError:peripheral reason:ERROR_REASON_WRITE_CHARACTERISTIC status:_mState];
    }else{
        NSLog(@"%@, onCharacteristicWrite() charcteristic=%@, status=%d 发送数据成功", TAG, [characteristic.UUID representativeString], -1);
    }
}

-(void)addReadRequest:(CBCharacteristic *)characteristic {
    if (characteristic == nil) {
        NSLog(@"can not read nil characteristic");
        return;
    }
    
    NSBlockOperation * op = [[NSBlockOperation alloc]init];
    [op addExecutionBlock:^{
        [servicePeripheral readValueForCharacteristic:characteristic];
    }];
    
    [self.executeQueue addOperation:op];
}

-(void)addWriteRequest:(CBCharacteristic *)characteristic data:(NSData *)data {
    if (characteristic == nil) {
        NSLog(@"can not read nil characteristic");
        return;
    }
    
    NSBlockOperation * op = [[NSBlockOperation alloc]init];
    [op addExecutionBlock:^{
        [servicePeripheral writeValue:data forCharacteristic:characteristic type:CBCharacteristicWriteWithResponse];
    }];
    
    [self.executeQueue addOperation:op];
}

#pragma mark - 指令队列
-(NSOperationQueue *)executeQueue {
    if (!_executeQueue) {
        self.executeQueue = [[NSOperationQueue alloc]init];
        [self.executeQueue setMaxConcurrentOperationCount:1];
    }
    
    return _executeQueue;
}

-(CBPeripheral *)peripheral {
    if (servicePeripheral) {
        return servicePeripheral;
    }
    
    return nil;
}

#pragma mark - 
#pragma mark - distanceTimer
-(void)startReadRssi {
    [self.distanceTimer setFireDate:[NSDate distantPast]];
}

-(NSTimer *)distanceTimer {
    if (!_distanceTimer) {
        self.distanceTimer = [NSTimer scheduledTimerWithTimeInterval:1.2f target:self selector:@selector(detectRSSI) userInfo:nil repeats:YES];
    }
    
    return _distanceTimer;
}

- (void)detectRSSI
{
    if (servicePeripheral) {
        [servicePeripheral readRSSI];
    }
}

-(void)addQWSOperation:(NSOperation *)op {
    if (!_executeQueue) {
        self.executeQueue = [[NSOperationQueue alloc]init];
        [self.executeQueue setMaxConcurrentOperationCount:1];
    }
    
    if(self.executeQueue.operationCount <= 10) {
        [self.executeQueue addOperation:op];
    }else {
        NSLog(@"%@的队列很忙 请稍后！！！", self.peripheral.name);
        [self broadcastError:servicePeripheral reason:ERROR_REASON_DEVICE_BUSY status:STATE_CONNECTED];
        
        [op cancel];
    }
}

#pragma mark -
#pragma mark - 发送通知
-(void)broadcastUpdate:(CBPeripheral *)peripheral action:(NSString *)action {
    NSDictionary * intent = @{EXTRA_ADDRESS : peripheral.identifier.UUIDString};
    [[NSNotificationCenter defaultCenter] postNotificationName:action object:self userInfo:intent];
}
-(void)broadcastError:(CBPeripheral *)peripheral reason:(int)reason status:(int)status {
    NSDictionary * intent = @{EXTRA_ADDRESS : peripheral.identifier.UUIDString,
                              EXTRA_ERROR_REASON : [NSNumber numberWithInt:reason],
                              EXTRA_STATUS : [NSNumber numberWithInt:status]};
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_BLE_ERROR object:self userInfo:intent];
}

-(void)broadcastUpdate:(CBPeripheral *)peripheral action:(NSString *)action characteristic:(CBCharacteristic *)characteristic {
    NSMutableDictionary * intent = @{EXTRA_ADDRESS : peripheral.identifier.UUIDString,
                                     EXTRA_CHAR : [characteristic.UUID representativeString]}.mutableCopy;
    
    NSData * data = [characteristic value];
    if (data != nil && sizeof(data) > 0) {
        [intent setObject:data forKey:EXTRA_DATA];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:action object:self userInfo:intent];
}

#pragma mark - 
#pragma mark - 获取设备特征和服务
-(NSArray *)getSupportedQWSServices {
    if (!self.peripheral) {
        return nil;
    }
    
    return [self.peripheral services];
}

-(CBCharacteristic *)getCharacteristics:(NSString *)suuid cuuid:(NSString *)cuuid {
    if (!self.peripheral) {
        return nil;
    }
    
    CBService * service = nil;
    NSArray * services = [self.peripheral services];
    for (CBService * tmp in services) {
        if ([[tmp UUID] isEqual:[CBUUID UUIDWithString:suuid]]) {
            service = tmp;
            break;
        }
    }
    
    if (service == nil) {
        return nil;
    }
    
    CBCharacteristic * characterastic = nil;
    NSArray * characterastics = [service characteristics];
    for (CBCharacteristic * tmp in characterastics) {
        if ([[tmp UUID] isEqual:[CBUUID UUIDWithString:cuuid]]) {
            characterastic = tmp;
            break;
        }
    }
    
    return characterastic == nil ? nil : characterastic;
}

#pragma mark - 
#pragma mark - 获取360骑卫士的设备状态
-(QwsBleDeviceBindState)readBindState {
    QwsBleDeviceBindState result = -1;
    
    CBCharacteristic * characteristic = [self getCharacteristics:kDevControllServiceUUIDString cuuid:kDevDeviceInfoCharacteristicUUIDString];
    
    if (characteristic) {
        NSData * data = characteristic.value;
        
        if (data == nil) {
            return -1;
        }
        
        Byte * resultByte = (Byte *)[data bytes];
        
        if (resultByte[0] == 0) {
            result = kDevStateUnBind;
        }else if (resultByte[0] == 1) {
            result = kDevStateBinded;
        }else if (resultByte[0] == 2) {
            result = kDevStateAllowBind;
        }
    }
    
    return result;
}

-(QwsBleDeviceState)readDeviceState {
    QwsBleDeviceState result = -1;
    
    CBCharacteristic * characteristic = [self getCharacteristics:kDevControllServiceUUIDString cuuid:kDevDeviceStateCharacteristicUUIDString];
    
    if (characteristic) {
        NSData * data = characteristic.value;
        
        if (data == nil) {
            return -1;
        }
        
        Byte * resultByte = (Byte *)[data bytes];
        
        if (resultByte[0] == 0) {
            result = kDevLockStateUnLock;
        }else if (resultByte[0] == 1) {
            result = kDevLockStateLock;
        }
    }
    
    return result;
}

-(QwsBleDeviceState)lockState {
    return [self readDeviceState];
}

-(NSComparisonResult)compareQwsDevControlService:(QWSDevControlService *)device {
    NSComparisonResult result = [device.RSSI compare:self.RSSI];
    
    if (result == NSOrderedSame) {
        result = [self.UUIDString compare:device.UUIDString];
    }
    
    return result;
}

@end

