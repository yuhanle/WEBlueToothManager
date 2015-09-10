//
//  QWSBleDeviceState.h
//  B100
//
//  Created by Tilink on 15/8/20.
//  Copyright (c) 2015年 Tilink. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface QWSBleDeviceState : NSObject

@property (assign, nonatomic) int lockState;
@property (assign, nonatomic) int accState;
@property (assign, nonatomic) float power;
@property (assign, nonatomic) float speed;
@property (assign, nonatomic) float currentDis;
@property (assign, nonatomic) float totalDis;
@property (assign, nonatomic) int errCode;

-(instancetype)initWithValue:(Byte *)values;

@end
