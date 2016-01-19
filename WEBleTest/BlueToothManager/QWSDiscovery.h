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

+ (id) sharedInstance;

/****************************************************************************/
/*								Actions										*/
/****************************************************************************/
- (void) startScanning:(NSString *)uuidString;
- (void) stopScanning;

/****************************************************************************/
/*							Access to the devices							*/
/****************************************************************************/
@property (strong, nonatomic) NSMutableArray * foundPeripherals;
@property (strong, nonatomic) NSMutableDictionary *localStoragePeripherals;

-(QWSDevControlService *)searchDeviceWithUUID:(NSString *)uuid;

-(void)readCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid;
-(void)writeCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid data:(NSData *)data;

//
-(BOOL)isBTEnable;
-(BOOL)isBleOpen;
-(BOOL)isDeviceServiceDiscoveried:(NSString *)uuid;
-(BOOL)isDeviceAuthoritied:(NSString *)uuid;
-(int)getDeviceState:(NSString *)uuid;
-(int)connect:(NSString *)uuid;
-(int)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect;
-(void)disconnect:(NSString *)uuid;
-(void)disconnectAll;

-(BOOL)isQWSBleService:(NSString *)uuid;
-(void)setDeviceAuthoritied:(NSString *)uuid;
-(void)setCharacteristicNotification:(NSString *)uuid characteristic:(CBCharacteristic *)characteristic enabled:(BOOL)enabled;
-(void)setCharacteristicNotification:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid enabled:(BOOL)enabled;

@end
