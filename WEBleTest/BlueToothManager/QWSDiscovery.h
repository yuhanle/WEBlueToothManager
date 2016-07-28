//
//  QWSDevControlService.h
//  WEBluetooth
//
//  Created by yuhanle on 15/7/23.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

#import "QWSDevControlService.h"

extern NSString * ACTION_GATT_CONNECTED;
extern NSString * ACTION_GATT_DISCONNECTED;
extern NSString * ACTION_GATT_SERVICES_DISCOVERED;
extern NSString * ACTION_DATA_AVAILABLE;
extern NSString * ACTION_READ_RSSI;
extern NSString * ACTION_BLE_ERROR;
extern NSString * ACTION_BLE_STATECHANGE;
extern NSString * EXTRA_DATA;
extern NSString * EXTRA_ADDRESS;
extern NSString * EXTRA_ERROR_REASON;
extern NSString * EXTRA_CHAR;
extern NSString * EXTRA_STATUS;

extern int ERROR_REASON_UNKNOWN;
extern int ERROR_REASON_WRITE_CHARACTERISTIC;
extern int ERROR_REASON_READ_CHARACTERISTIC;
extern int ERROR_REASON_SERVICE_DISCOVERY;
extern int ERROR_REASON_SET_VALUE_FAIL;
extern int ERROR_REASON_DEVICE_BUSY;
extern int ERROR_REASON_DEVICE_AUTH_FAIL;

extern const int STATE_DISCONNECTED;
extern const int STATE_CONNECTING;
extern const int STATE_DISCONNECTING;
extern const int STATE_CONNECTED;
extern const int STATE_INVALID;

/****************************************************************************/
/*							Discovery class									*/
/****************************************************************************/
@interface QWSDiscovery : NSObject

/**
 *  快速创建蓝牙服务
 *
 *  @return 蓝牙服务
 */
+ (id) sharedInstance;

/****************************************************************************/
/*								Actions										*/
/****************************************************************************/
/**
 *  开始扫描服务某服务特征的蓝牙信号
 *
 *  @param uuidString 服务特征UUID
 */
- (void) startScanning:(NSString *)uuidString;
/**
 *  停止扫描
 */
- (void) stopScanning;

/****************************************************************************/
/*							Access to the devices							*/
/****************************************************************************/
/**
 *  已经发现的蓝牙设备
 */
@property (strong, nonatomic) NSMutableArray * foundPeripherals;
/**
 *  本地存储的蓝牙设备 UUID作为key
 */
@property (strong, nonatomic) NSMutableDictionary *localStoragePeripherals;

/**
 *  从本地根据UUID搜索蓝牙服务
 *
 *  @param uuid 设备uuid
 *
 *  @return 蓝牙模块
 */
-(QWSDevControlService *)searchDeviceWithUUID:(NSString *)uuid;
/**
 *  读某设备某服务的某特征数据
 *
 *  @param uuid  设备uuid
 *  @param suuid 服务uuid
 *  @param cuuid 特征uuid
 */
-(void)readCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid;
/**
 *  写某设备某服务某特征数据
 *
 *  @param uuid  设备uuid
 *  @param suuid 服务uuid
 *  @param cuuid 特征uuid
 *  @param data  二进制数据 < 20 bytes
 */
-(void)writeCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid data:(NSData *)data;

/**
 *  蓝牙是否可用
 *
 *  @return YES/NO
 */
-(BOOL)isBTEnable;
/**
 *  蓝牙是否开启
 *
 *  @return YES/NO
 */
-(BOOL)isBleOpen;
/**
 *  判断某设备服务是否已发现
 *
 *  @param uuid 设备uuid
 *
 *  @return YES/NO
 */
-(BOOL)isDeviceServiceDiscoveried:(NSString *)uuid;
/**
 *  判断某设备是不是已经授权
 *
 *  @param uuid 设备uuid
 *
 *  @return YES/NO
 */
-(BOOL)isDeviceAuthoritied:(NSString *)uuid;
/**
 *  获取设备当前状态
 *
 *  @param uuid 设备uuid
 *
 *  @return 设备状态
 */
-(int)getDeviceState:(NSString *)uuid;
/**
 *  连接某设备
 *
 *  @param uuid 设备uuid
 *
 *  @return 设备连接状态
 */
-(int)connect:(NSString *)uuid;
/**
 *  连接某设备 是否自动重连
 *
 *  @param uuid        设备uuid
 *  @param autoConnect 是否重连
 *
 *  @return 设备连接状态
 */
-(int)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect;
/**
 *  断开某设备连接
 *
 *  @param uuid 设备uuid
 */
-(void)disconnect:(NSString *)uuid;
/**
 *  断开所有设备连接
 */
-(void)disconnectAll;

/**
 *  判断某设备是否是骑卫士设备
 *
 *  @param uuid 设备uuid
 *
 *  @return YES/NO
 */
-(BOOL)isQWSBleService:(NSString *)uuid;
/**
 *  认证某设备
 *
 *  @param uuid 设备uuid
 */
-(void)setDeviceAuthoritied:(NSString *)uuid;
/**
 *  关心某设备某服务某特征
 *
 *  @param uuid           设备uuid
 *  @param characteristic 特征uuid
 *  @param enabled        开启/关闭
 */
-(void)setCharacteristicNotification:(NSString *)uuid characteristic:(CBCharacteristic *)characteristic enabled:(BOOL)enabled;
/**
 *  关心某设备某服务某特征
 *
 *  @param uuid    设备uuid
 *  @param suuid   服务uuid
 *  @param cuuid   特征uuid
 *  @param enabled 开启/关闭
 */
-(void)setCharacteristicNotification:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid enabled:(BOOL)enabled;

@end
