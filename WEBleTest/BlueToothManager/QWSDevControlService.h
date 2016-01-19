//
//  QWSDevControlService.h
//  WEBluetooth
//
//  Created by yuhanle on 15/7/23.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "CBUUID+StringExtraction.h"

extern NSString *kDevControllServiceUUIDString;                 // 0xFF15
extern NSString *kDevDeviceWriteCharacteristicUUIDString;       // 0xFF01
extern NSString *kDevDeviceReadCharacteristicUUIDString;        // 0xFF02
extern NSString *kDevDeviceSoftVersionCharacteristicUUIDString; // 0xFF03
extern NSString *kDevDeviceInfoCharacteristicUUIDString;        // 0xFF04
extern NSString *kDevDeviceStateCharacteristicUUIDString;       // 0xFF05

extern NSString *kAlarmServiceEnteredBackgroundNotification;
extern NSString *kAlarmServiceEnteredForegroundNotification;

typedef enum {
    kDevStateUnBind = 0,
    kDevStateBinded,
    kDevStateAllowBind,
} QwsBleDeviceBindState;

typedef enum {
    kDevLockStateUnLock = 0,
    kDevLockStateLock,
} QwsBleDeviceState;

@interface QWSDevControlService : NSObject

-(instancetype)initWithPeripheral:(CBPeripheral *)peripheral;
-(void)reset;
-(void)start;

@property (copy, nonatomic  ) NSString     *UUIDString;
@property (strong, nonatomic) CBPeripheral *peripheral;
@property (assign, nonatomic) BOOL         isAutoConnect;
@property (assign, nonatomic) BOOL         isNeedCloseAfterDisconnected;
@property (assign, nonatomic) int          mRetryCount;
@property (assign, nonatomic) BOOL         isServiceDiscovered;
@property (assign, nonatomic) BOOL         isAuthoritied;
@property (copy, nonatomic  ) NSString     *version;

@property (assign, nonatomic) int      mState;
@property (strong, nonatomic) NSNumber *RSSI;// 信号强度

@property (strong, nonatomic) NSOperationQueue *executeQueue;// service的指令队列 读写同队列

-(NSComparisonResult)compareQwsDevControlService:(QWSDevControlService *)device;

-(void)startReadRssi;

-(void)addReadRequest:(CBCharacteristic *)characteristic;
-(void)addWriteRequest:(CBCharacteristic *)characteristic data:(NSData *)data;

@end
