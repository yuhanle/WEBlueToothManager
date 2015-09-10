//
//  QWSBleHandler.h
//  WEBluetooth
//
//  Created by Tilink on 15/7/28.
//  Copyright (c) 2015年 Tilink. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWSDevControlService.h"


@class QWSBleDeviceState;
@protocol QWSBleHandlerDelegate <NSObject>

@optional
-(void)onInitComplete:(BOOL)result;

-(void)onDisconnected:(NSString *)uuid;
-(void)onConnected:(NSString *)uuid isQwsDevice:(BOOL)isQwsDevice;

-(void)onGetBindState:(NSString *)uuid state:(QwsBleDeviceBindState)state;
-(void)onGetDeviceState:(NSString *)uuid state:(QWSBleDeviceState *)state;

-(void)onGetAuthoried:(NSString *)uuid isSuccess:(BOOL)isSuccess;
-(void)onGuardOnOff:(NSString *)uuid isSuccess:(BOOL)isSuccess isGuardOn:(BOOL)isGuardOn;

-(void)onReadRssi:(NSString *)uuid rssi:(int)rssi distance:(int)distance;

-(void)onWritePassword:(NSString *)uuid success:(BOOL)success;

-(void)onError:(NSString *)uuid errReason:(int)errReason status:(int)status;

-(void)onBleStateChanged:(CBCentralManagerState)state;

@end

@interface QWSBleHandler : NSObject

@property (assign, nonatomic) id <QWSBleHandlerDelegate> delegate;

@end
