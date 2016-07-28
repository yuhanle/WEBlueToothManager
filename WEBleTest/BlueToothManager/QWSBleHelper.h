//
//  QWSBleHelper.h
//  B100
//
//  Created by yuhanle on 15/8/6.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//
//  每个VC维护一个helper

#import <Foundation/Foundation.h>
#import "QWSBleHandler.h"

extern NSString * ACTION_RM_ADDRESS;
@interface QWSBleHelper : NSObject

/**
 *  快速创建BleHelper实例
 *
 *  @param delegate 代理
 *
 *  @return helper实例
 */
-(instancetype)initWithDelegate:(id<QWSBleHandlerDelegate>)delegate;

/**
 *  蓝牙是否可用
 *
 *  @return YES/NO
 */
-(BOOL)isEnable;
/**
 *  系统蓝牙是否开启
 *
 *  @return YES/NO
 */
-(BOOL)isBleOpen;
/**
 *  开始扫描
 *
 *  @return YES/NO
 */
-(BOOL)start;
/**
 *  停止扫描
 */
-(void)stop;

/**
 *  已经发现的设备
 *
 *  @return 设备数组
 */
-(NSArray *)foundDevices;
/**
 *  从已发现设备中根据uuid查找设备
 *
 *  @param uuid 设备uuid
 *
 *  @return 特殊设备
 */
-(QWSDevControlService *)searchDeviceWithUUID:(NSString *)uuid;

/**
 *  判断设备是否鉴权
 *
 *  @param uuid 设备uuid
 *
 *  @return YES/NO
 */
-(BOOL)isDeviceAuthoritied:(NSString *)uuid;
/**
 *  获取设备状态
 *
 *  @param uuid 设备uuid
 *
 *  @return YES/NO
 */
-(int)getDeviceState:(NSString *)uuid;
/**
 *  连接某个设备
 *
 *  @param uuid        设备uuid
 *  @param autoConnect 是否自动重连
 *
 *  @return YES/NO
 */
-(BOOL)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect;
/**
 *  连接某个设备 （不关系）
 *
 *  @param uuid        设备uuid
 *  @param autoConnect 是否自动重连
 *
 *  @return YES/NO
 */
-(BOOL)doConnect:(NSString *)uuid autoConnect:(BOOL)autoConnect;
/**
 *  断开某设备的连接
 *
 *  @param uuid 设备uuid
 */
-(void)disconnect:(NSString *)uuid;
/**
 *  断开某设备的连接并移除关心
 *
 *  @param uuid 设备uuid
 */
-(void)disconnectAndRm:(NSString *)uuid;
/**
 *  断开所有设备的连接
 */
-(void)disconnectAll;

/** 设备需要的操作*/
-(BOOL)readBindState:(NSString *)uuid;
-(BOOL)readDeviceState:(NSString *)uuid;
-(BOOL)requestWritePassword:(NSString *)uuid oldPassword:(Byte *)oldPassword newPassword:(Byte *)newPassword;
-(BOOL)requestAuthority:(NSString *)uuid password:(Byte *)password;
-(BOOL)requestGuard:(NSString *)uuid isOn:(int)isOn;
-(BOOL)requestOpenBag:(NSString *)uuid isOpen:(BOOL)isOpen;
-(BOOL)requestLockController:(NSString *)uuid isLock:(BOOL)isLock;
-(BOOL)requestSetControllerPassword:(NSString *)uuid oldPassword:(Byte *)oldPassword newPassword:(Byte *)newPassword;
-(BOOL)requestFindCar:(NSString *)uuid;
-(BOOL)requestClearDistance:(NSString *)uuid;
-(BOOL)requestBindVoice:(NSString *)uuid voice:(Byte)voice;
-(BOOL)requestOneKeyStart:(NSString *)uuid;

/**
 *  字符串 to Byte
 *
 *  @param hexString 字符串
 *
 *  @return Byte
 */
-(Byte *)hexToBytes:(NSString *)hexString;

@end
