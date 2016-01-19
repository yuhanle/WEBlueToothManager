//
//  QWSBleHandler.h
//  WEBluetooth
//
//  Created by yuhanle on 15/7/28.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWSDevControlService.h"


@class QWSBleDeviceState;
@protocol QWSBleHandlerDelegate <NSObject>

@optional
/**
 *  手机端蓝牙初始化完成
 *
 *  @param result YES 初始化完成 NO 初始化失败
 */
-(void)onInitComplete:(BOOL)result;

/**
 *  断开连接
 *
 *  @param uuid 断开连接的设备uuid
 */
-(void)onDisconnected:(NSString *)uuid;
/**
 *  连接成功
 *
 *  @param uuid        连接上的设备uuid
 *  @param isQwsDevice 是否是360骑卫士设备
 */
-(void)onConnected:(NSString *)uuid isQwsDevice:(BOOL)isQwsDevice;

/**
 *  获取设备的绑定状态
 *
 *  @param uuid  设备的uuid
 *  @param state 设备的绑定状态
 */
-(void)onGetBindState:(NSString *)uuid state:(QwsBleDeviceBindState)state;
/**
 *  获取设备的状态
 *
 *  @param uuid  设备的uuid
 *  @param state 设备的状态
 */
-(void)onGetDeviceState:(NSString *)uuid state:(QWSBleDeviceState *)state;

/**
 *  认证结果
 *
 *  @param uuid      设备的uuid
 *  @param isSuccess YES/NO
 */
-(void)onGetAuthoried:(NSString *)uuid isSuccess:(BOOL)isSuccess;
/**
 *  设防撤防结果
 *
 *  @param uuid      设备的uuid
 *  @param isSuccess 设防结果
 *  @param isGuardOn 设防/撤防
 */
-(void)onGuardOnOff:(NSString *)uuid isSuccess:(BOOL)isSuccess isGuardOn:(BOOL)isGuardOn;

/**
 *  设备的信号强度和距离
 *
 *  @param uuid     设备的uuid
 *  @param rssi     设备的信号强度
 *  @param distance 设备的距离
 */
-(void)onReadRssi:(NSString *)uuid rssi:(int)rssi distance:(int)distance;

/**
 *  写入密码
 *
 *  @param uuid    设备的uuid
 *  @param success 写入结果 成功/失败
 */
-(void)onWritePassword:(NSString *)uuid success:(BOOL)success;

/**
 *  错误处理
 *
 *  @param uuid      设备的uuid
 *  @param errReason 错误原因
 *  @param status    错误状态
 */
-(void)onError:(NSString *)uuid errReason:(int)errReason status:(int)status;

/**
 *  BLE状态变化
 *
 *  @param state BLE的状态
 */
-(void)onBleStateChanged:(CBCentralManagerState)state;

@end

@interface QWSBleHandler : NSObject

@property (assign, nonatomic) id <QWSBleHandlerDelegate> delegate;

@end
