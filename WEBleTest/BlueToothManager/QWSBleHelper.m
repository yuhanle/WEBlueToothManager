//
//  QWSBleHelper.m
//  B100
//
//  Created by yuhanle on 15/8/6.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import "QWSBleHelper.h"
#import "QWSDiscovery.h"
#import "QWSBleHandler.h"
#import "QWSBleDeviceState.h"

Byte CMD_AURTHORITY      = 0x01;
Byte CMD_WRITE_PASSWORD  = 0x02;
Byte CMD_GUARD_ONOFF     = 0x03;
Byte CMD_OPEN_BAG        = 0x04;
Byte CMD_LOCK_CONTROLLER = 0x05;
Byte CMD_SET_CONTROLLER  = 0x06;
Byte CMD_FIND_CAR        = 0x07;
Byte CMD_CLEAR_DIS       = 0x08;
Byte CMD_BIND_VOICE      = 0x09;
Byte CMD_ONEKEY_START    = 0x10;

static const NSString * TAG = @"QwsBleHelper";
NSString * ACTION_RM_ADDRESS = @"ACTION_RM_ADDRESS";
@interface QWSBleHelper () {
    NSMutableSet * mUUIDSet;
    NSMutableSet * mRmUUIDSet;
}

@property (assign, nonatomic) BOOL mBleEnable;
@property (strong, nonatomic) QWSDiscovery  * mDiscovery;
@property (strong, nonatomic) QWSBleHandler * mBleHandler;

@end

@implementation QWSBleHelper

@synthesize mBleEnable;
@synthesize mDiscovery;
@synthesize mBleHandler;

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_BLE_STATECHANGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_DATA_AVAILABLE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_GATT_SERVICES_DISCOVERED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_GATT_CONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_GATT_DISCONNECTED object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_READ_RSSI object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ACTION_RM_ADDRESS object:nil];
}

-(instancetype)initWithDelegate:(id<QWSBleHandlerDelegate>)delegate {
    if (self = [super init]) {
        mDiscovery  = [QWSDiscovery sharedInstance];
        mBleHandler = [[QWSBleHandler alloc]init];
        mBleHandler.delegate = delegate;
        
        mUUIDSet = [[NSMutableSet alloc]init];
        mRmUUIDSet = [[NSMutableSet alloc]init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bleStateChanged:) name:ACTION_BLE_STATECHANGE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mGattUpdateReceiver:) name:ACTION_DATA_AVAILABLE object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mGattUpdateReceiver:) name:ACTION_GATT_SERVICES_DISCOVERED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mGattUpdateReceiver:) name:ACTION_GATT_CONNECTED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mGattUpdateReceiver:) name:ACTION_GATT_DISCONNECTED object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mGattUpdateReceiver:) name:ACTION_READ_RSSI object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mGattUpdateReceiver:) name:ACTION_RM_ADDRESS object:nil];
    }
    
    return self;
}
-(void)mGattUpdateReceiver:(NSNotification *)notification {
    NSDictionary * userInfo = [notification userInfo];
    NSString * notiName     = [notification name];
    NSString * uuid         = [userInfo objectForKey:EXTRA_ADDRESS] == nil ? nil : [userInfo objectForKey:EXTRA_ADDRESS];
    
    // 判断关心的设备
    if (![mUUIDSet containsObject:uuid]) {
        return;
    }
    
    if ([notiName isEqualToString:ACTION_GATT_CONNECTED]) {
        // do not call on connect here
    }else if ([notiName isEqualToString:ACTION_GATT_DISCONNECTED]) {
        if ([mRmUUIDSet containsObject:uuid]) {
            [mRmUUIDSet removeObject:uuid];
            [mUUIDSet removeObject:uuid];
        }
        
        if ([mBleHandler.delegate respondsToSelector:@selector(onDisconnected:)]) {
            [mBleHandler.delegate onDisconnected:uuid];
        }
    }else if ([notiName isEqualToString:ACTION_GATT_SERVICES_DISCOVERED]) {
        NSLog(@"%@, ACTION_GATT_SERVICES_DISCOVERED %@", TAG, uuid);
        if ([mDiscovery isQWSBleService:uuid]) {
            [mDiscovery setCharacteristicNotification:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceStateCharacteristicUUIDString enabled:true];
            [mDiscovery setCharacteristicNotification:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceReadCharacteristicUUIDString enabled:true];
            
            if ([mBleHandler.delegate respondsToSelector:@selector(onConnected:isQwsDevice:)]) {
                [mBleHandler.delegate onConnected:uuid isQwsDevice:true];
            }
        }else {
            if ([mBleHandler.delegate respondsToSelector:@selector(onConnected:isQwsDevice:)]) {
                [mBleHandler.delegate onConnected:uuid isQwsDevice:false];
            }
        }
    }else if ([notiName isEqualToString:ACTION_DATA_AVAILABLE]) {
        NSString * characteristic = [userInfo objectForKey:EXTRA_CHAR];
        NSData * data = [userInfo objectForKey:EXTRA_DATA];
        Byte * values = (Byte *)[data bytes];
        
        if ([characteristic isEqualToString:kDevDeviceInfoCharacteristicUUIDString]) {
            if ([mBleHandler.delegate respondsToSelector:@selector(onGetBindState:state:)]) {
                [mBleHandler.delegate onGetBindState:uuid state:values[0]];
            }
        }else if ([characteristic isEqualToString:kDevDeviceReadCharacteristicUUIDString]) {
            if (values[0] == CMD_AURTHORITY) {
                [mDiscovery setDeviceAuthoritied:uuid];
                if ([mBleHandler.delegate respondsToSelector:@selector(onGetAuthoried:isSuccess:)]) {
                    [mBleHandler.delegate onGetAuthoried:uuid isSuccess:values[1]==0];
                }
            }else if (values[0] == CMD_GUARD_ONOFF) {
                if ([mBleHandler.delegate respondsToSelector:@selector(onGuardOnOff:isSuccess:isGuardOn:)]) {
                    [mBleHandler.delegate onGuardOnOff:uuid isSuccess:values[1]==0 isGuardOn:(values[2] == 0 ? false : true)];
                }
            }else if (values[0] == CMD_WRITE_PASSWORD) {
                if ([mBleHandler.delegate respondsToSelector:@selector(onWritePassword:success:)]) {
                    [mBleHandler.delegate onWritePassword:uuid success:values[1]==0];
                }
            }else {
                NSLog(@"%@, Unhandled cmd=%d", TAG, values[0]);
            }
        }else if ([characteristic isEqualToString:kDevDeviceStateCharacteristicUUIDString]) {
            QWSBleDeviceState * state = [[QWSBleDeviceState alloc]initWithValue:values];
            if ([mBleHandler.delegate respondsToSelector:@selector(onGetDeviceState:state:)]) {
                [mBleHandler.delegate onGetDeviceState:uuid state:state];
            }
        }
    }else if ([notiName isEqualToString:ACTION_READ_RSSI]) {
        NSNumber * rssi = userInfo[EXTRA_DATA];
        if ([mBleHandler.delegate respondsToSelector:@selector(onReadRssi:rssi:distance:)]) {
            [mBleHandler.delegate onReadRssi:uuid rssi:[rssi intValue] distance:getDist([rssi intValue])];
        }
    }else if ([notiName isEqualToString:ACTION_BLE_ERROR]) {
        int errReason = [[userInfo objectForKey:EXTRA_ERROR_REASON] intValue];
        int status    = [[userInfo objectForKey:EXTRA_STATUS] intValue];
        
        if ([mBleHandler.delegate respondsToSelector:@selector(onError:errReason:status:)]) {
            [mBleHandler.delegate onError:uuid errReason:errReason status:status];
        }
    }else if ([notiName isEqualToString:ACTION_BLE_STATECHANGE]) {
        CBCentralManagerState state = [[[notification userInfo]objectForKey:EXTRA_DATA] intValue];
        if ([mBleHandler.delegate respondsToSelector:@selector(onBleStateChanged:)]) {
            [mBleHandler.delegate onBleStateChanged:state];
        }
    }else if ([notiName isEqualToString:ACTION_RM_ADDRESS]) {
        [mRmUUIDSet addObject:uuid];
        [self disconnect:uuid];
    }
}

static int getDist(int rssi) {
    int A = 71;
    float n = 2.0f;
    int iRssi = abs(rssi);
    float power = (iRssi - A) / (10 * n);
    return (int) (pow(10, power) * 1000);
}

-(void)bleStateChanged:(NSNotification *)notification {
    CBCentralManagerState state = [[[notification userInfo]objectForKey:EXTRA_DATA] intValue];
    if ([mBleHandler.delegate respondsToSelector:@selector(onBleStateChanged:)]) {
        [mBleHandler.delegate onBleStateChanged:state];
    }
}

-(BOOL)isBleOpen {
    if (mDiscovery == nil) {
        return false;
    }
    
    if ([mDiscovery isBleOpen]) {
        return true;
    }
    
    return false;
}

-(BOOL)isEnable {
    if (mDiscovery == nil) {
        return false;
    }
    
    return [mDiscovery isBTEnable];
}

-(BOOL)start {
    [mDiscovery startScanning:kDevControllServiceUUIDString];
    return YES;
}

-(void)stop {
    [mDiscovery stopScanning];
}

-(NSArray *)foundDevices {
    return [mDiscovery foundPeripherals];
}

-(QWSDevControlService *)searchDeviceWithUUID:(NSString *)uuid {
    return [mDiscovery searchDeviceWithUUID:uuid];
}

-(BOOL)isDeviceAuthoritied:(NSString *)uuid {
    return [mDiscovery isDeviceAuthoritied:uuid];
}

-(int)getDeviceState:(NSString *)uuid {
    return [mDiscovery getDeviceState:uuid];
}

-(BOOL)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect {
    if (mDiscovery == nil) {
        NSLog(@"%@, cannot connect when service is not bind", TAG);
        return NO;
    }
    
    [mUUIDSet addObject:uuid];
    return [self doConnect:uuid autoConnect:autoConnect];
}

-(BOOL)doConnect:(NSString *)uuid autoConnect:(BOOL)autoConnect {
    int state = [mDiscovery connect:uuid autoConnect:autoConnect];
    BOOL rlt = true;
    
    if (state == STATE_CONNECTED) {
        if ([mDiscovery isDeviceServiceDiscoveried:uuid]) {
            if ([mBleHandler.delegate respondsToSelector:@selector(onConnected:isQwsDevice:)]) {
                [mBleHandler.delegate onConnected:uuid isQwsDevice:YES];
            }
        }
    }else if (state == STATE_CONNECTING) {
    
    }else if (state == STATE_INVALID) {
        
    }else if (state == STATE_DISCONNECTING) {
        rlt = false;
    }else {
        NSLog(@"%@, ERROR! UNHANDLED STATE", TAG);
    }
    
    return rlt;
}

-(void)disconnect:(NSString *)uuid {
    [mDiscovery disconnect:uuid];
}

-(void)disconnectAndRm:(NSString *)uuid {
    NSDictionary * intent = @{EXTRA_ADDRESS:uuid};
    [[NSNotificationCenter defaultCenter]postNotificationName:ACTION_RM_ADDRESS object:self userInfo:intent];
}

-(void)disconnectAll {
    [mDiscovery disconnectAll];
}

-(BOOL)readBindState:(NSString *)uuid {
    [mDiscovery readCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceInfoCharacteristicUUIDString];
    return true;
}
-(BOOL)readDeviceState:(NSString *)uuid {
    [mDiscovery readCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceStateCharacteristicUUIDString];
    return true;
}
-(BOOL)requestWritePassword:(NSString *)uuid oldPassword:(Byte *)oldPassword newPassword:(Byte *)newPassword {
    
    Byte values[17];
    values[0] = CMD_WRITE_PASSWORD;
    for (int i = 1; i < 9; i++) {
        if (i-1 >= sizeof(oldPassword)) {
            values[i] = 0x00;
        }else {
            values[i] = oldPassword[i-1];
        }
    }
    
    for (int i = 9; i < 17; i++) {
        if (i-9 >= sizeof(newPassword)) {
            values[i] = 0x00;
        }else {
            values[i] = newPassword[i-9];
        }
    }
    
    NSData * data = [NSData dataWithBytes:values length:17];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestAuthority:(NSString *)uuid password:(Byte *)password {
    if ([mDiscovery isDeviceAuthoritied:uuid]) {
        if ([mBleHandler.delegate respondsToSelector:@selector(onGetAuthoried:isSuccess:)]) {
            [mBleHandler.delegate onGetAuthoried:uuid isSuccess:YES];
        }
        
        return true;
    }
    
    Byte values[17];
    values[0] = CMD_AURTHORITY;
    for (int i = 1; i < 9; i++) {
        if (i-1 >= sizeof(values)) {
            values[i] = 0x00;
        }else {
            values[i] = password[i-1];
        }
    }
    
    NSData * data = [NSData dataWithBytes:values length:17];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestGuard:(NSString *)uuid isOn:(int)isOn {
    Byte byte = isOn == 0 ? 0x00 : (isOn == 1 ? 0x01 : 0x02);
    Byte values[2] = {CMD_GUARD_ONOFF, byte};
    
    NSData * data = [NSData dataWithBytes:values length:2];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestOpenBag:(NSString *)uuid isOpen:(BOOL)isOpen {
    Byte values[2] = {CMD_OPEN_BAG, isOpen ? 0x01 : 0x00};
    
    NSData * data = [NSData dataWithBytes:values length:2];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestLockController:(NSString *)uuid isLock:(BOOL)isLock {
    Byte values[2] = {CMD_LOCK_CONTROLLER, isLock ? 0x01 : 0x00};
    
    NSData * data = [NSData dataWithBytes:values length:2];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestSetControllerPassword:(NSString *)uuid oldPassword:(Byte *)oldPassword newPassword:(Byte *)newPassword {
    Byte values[17];
    values[0] = CMD_SET_CONTROLLER;
    for (int i = 1; i < 9; i++) {
        if (i-1 >= sizeof(oldPassword)) {
            values[i] = 0x00;
        }else {
            values[i] = oldPassword[i-1];
        }
    }
    
    for (int i = 9; i < 17; i++) {
        if (i-9 >= sizeof(newPassword)) {
            values[i] = 0x00;
        }else {
            values[i] = newPassword[i-9];
        }
    }
    
    NSData * data = [NSData dataWithBytes:values length:17];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestFindCar:(NSString *)uuid {
    Byte values[1] = {CMD_FIND_CAR};
    
    NSData * data = [NSData dataWithBytes:values length:1];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}
-(BOOL)requestClearDistance:(NSString *)uuid {
    Byte values[1] = {CMD_CLEAR_DIS};
    
    NSData * data = [NSData dataWithBytes:values length:1];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}

-(BOOL)requestBindVoice:(NSString *)uuid voice:(Byte)voice {
    Byte values[2] = {CMD_BIND_VOICE, voice};
    
    NSData * data = [NSData dataWithBytes:values length:2];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}

-(BOOL)requestOneKeyStart:(NSString *)uuid {
    Byte values[1] = {CMD_ONEKEY_START};
    
    NSData * data = [NSData dataWithBytes:values length:1];
    [mDiscovery writeCharacteristic:uuid suuid:kDevControllServiceUUIDString cuuid:kDevDeviceWriteCharacteristicUUIDString data:data];
    
    return true;
}

-(Byte *)hexToBytes:(NSString *)hexString {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx < hexString.length; idx++) {
        NSRange range = NSMakeRange(idx, 1);
        NSString* hexStr = [hexString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    
    Byte * bytes = (Byte *)[data bytes];
    
    return bytes;
}

@end
