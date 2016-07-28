//
//  CBUUID+StringExtraction.h
//  B100
//
//  Created by yuhanle on 15/8/19.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>

@interface CBUUID (StringExtraction)

/**
 *  蓝牙UUID to String
 *
 *  @return UUIDString
 */
- (NSString *)representativeString;

@end
