//
//  QWSBleDeviceState.m
//  B100
//
//  Created by yuhanle on 15/8/20.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import "QWSBleDeviceState.h"

@implementation QWSBleDeviceState

-(instancetype)initWithValue:(Byte *)values {
    if (self = [super init]) {
        self.lockState = [self byteToInt:values[0]];
        self.accState = [self byteToInt:values[1]];
        
        Byte powerByte[2] = {values[3]&0xF0, values[2]&0xF0};
        NSData *powerData = [[NSData alloc]initWithBytes:powerByte length:2];
        self.power = [self byteToInts:powerData]/100.0;
        
        Byte speedByte[2] = {values[5]&0xF0, values[4]&0xF0};
        NSData *speedData = [[NSData alloc]initWithBytes:speedByte length:2];
        self.speed = [self byteToInts:speedData]/100.0;
        
        Byte errCodeByte[2] = {values[15]&0xF0, values[14]&0xF0};
        NSData *errCodeData = [[NSData alloc]initWithBytes:errCodeByte length:2];
        self.errCode = [self byteToInts:errCodeData];
    }
    
    NSLog(@"\n#####################\n360骑卫士设备状态\n***********************\n当前状态:%d, \n电门状态:%d, \n电量:%lf, \n速度:%lf, \n当前里程:%lf, \n总里程:%lf, \n错误码:%d\n***********************\n", self.lockState, self.accState, self.power, self.speed, self.currentDis, self.totalDis, self.errCode);
    
    return self;
}

-(float)byteToFloat:(NSData *)data {
    Byte * bytes = (Byte *)[data bytes];
    float result = 0.0;
    NSInteger length = [data length];
    
    for (int i = 0; i < length; i++) {
        if (i == length - 1) {
            int tmp = [self byteToInt:bytes[i]];
            result += tmp;
        }else {
            int tmp = [self byteToInt:bytes[i]];
            result += tmp*pow(10, length - i - 2);
        }
    }
    
    return result;
}

-(int)byteToInts:(NSData *)data {
    return [self hexStringToInt:[self byteToHexString:data]];
}

-(int)byteToInt:(Byte)byte {
    Byte tmp[1] = {byte};
    NSData * data = [[NSData alloc]initWithBytes:tmp length:1];
    
    return [self hexStringToInt:[self byteToHexString:data]];
}

-(NSString *)byteToHexString:(NSData *)data {
    Byte * bytes = (Byte *)[data bytes];
    NSInteger length = [data length];
    
    NSString *hexStr = @"";
    for(int i = 0;i < length; i++)
    {
        NSString *newHexStr = [NSString stringWithFormat:@"%x",bytes[i]&0xff];
        if([newHexStr length] == 1)
            hexStr = [NSString stringWithFormat:@"%@0%@",hexStr,newHexStr];
        else
            hexStr = [NSString stringWithFormat:@"%@%@",hexStr,newHexStr];
    }
    
    return hexStr;
}

-(int)hexStringToInt:(NSString *)hexString {
    int sum = 0;
    for (int i = 0; i < [hexString length]; i++) {
        char s = [hexString characterAtIndex:i];
        int tmp = [[NSNumber numberWithChar:s] intValue];
        
        if(s >= '0' && s <= '9')
            tmp = (tmp-48);   // 0 的Ascll - 48
        else if(s >= 'A' && s <= 'F')
            tmp = (tmp-55); // A 的Ascll - 65
        else
            tmp = (tmp-87); // a 的Ascll - 97
        
        sum += tmp*pow(16, [hexString length] - i - 1);
    }
    
    return sum;
}

@end
