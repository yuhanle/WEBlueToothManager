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

-(instancetype)initWithDelegate:(id<QWSBleHandlerDelegate>)delegate;

-(BOOL)isEnable;
-(BOOL)isBleOpen;
-(BOOL)start;
-(void)stop;

-(NSArray *)foundDevices;
-(QWSDevControlService *)searchDeviceWithUUID:(NSString *)uuid;

-(BOOL)isDeviceAuthoritied:(NSString *)uuid;
-(int)getDeviceState:(NSString *)uuid;
-(BOOL)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect;
-(BOOL)doConnect:(NSString *)uuid autoConnect:(BOOL)autoConnect;

-(void)disconnect:(NSString *)uuid;
-(void)disconnectAndRm:(NSString *)uuid;
-(void)disconnectAll;

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

-(Byte *)hexToBytes:(NSString *)hexString;

@end
