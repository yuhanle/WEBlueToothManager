//
//  ViewController.m
//  WEBleTest
//
//  Created by Tilink on 15/9/9.
//  Copyright (c) 2015年 Jianer. All rights reserved.
//

#import "ViewController.h"

// 包含头文件
#import "QWSBluetooth.h"

@interface ViewController () <QWSBleHandlerDelegate> {
    QWSBleHelper * mBleHelper;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    mBleHelper = [[QWSBleHelper alloc]initWithDelegate:self];
    [mBleHelper start]; // 开始搜索蓝牙设备
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
