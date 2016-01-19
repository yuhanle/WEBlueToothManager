//
//  ViewController.m
//  WEBluetooth
//
//  Created by Tilink on 15/6/16.
//  Copyright (c) 2015年 Tilink. All rights reserved.
//

#import <CoreBluetooth/CoreBluetooth.h>
#import "WEBLEMyViewController.h"
#import "JSONKit.h"

#define kPeripheralName         @"360qws Electric Bike Service"         //外围设备名称
#define kServiceUUID            @"7CACEB8B-DFC4-4A40-A942-AAD653D174DC" //服务的UUID
#define kCharacteristicUUID     @"282A67B2-8DAB-4577-A42F-C4871A3EEC4F" //特征的UUID

@interface WEBLEMyViewController () <CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDataSource, UITableViewDelegate> {
    int count;
}

@property (strong, nonatomic) NSOperationQueue        *queue;
@property (weak, nonatomic  ) IBOutlet UITableView    *bluetoothTable;
@property (weak, nonatomic  ) IBOutlet UITextView     *resultTextView;

@property (nonatomic, strong) NSTimer                 *timer;
@property (assign, nonatomic) BOOL                    cbReady;
@property (nonatomic, strong) CBCentralManager        *manager;
@property (nonatomic, strong) CBPeripheral            *peripheral;

@property (strong ,nonatomic) CBCharacteristic        *writeCharacteristic;

@property (strong,nonatomic ) NSMutableArray          *nDevices;
@property (strong,nonatomic ) NSMutableArray          *nServices;
@property (strong,nonatomic ) NSMutableArray          *nCharacteristics;
@property (nonatomic,weak   ) IBOutlet UIActivityIndicatorView *activity;

@property (assign, nonatomic) BOOL                    isConnected;
@property (assign, nonatomic) BOOL                    isLocked;

- (IBAction)bluetoothAction:(UIButton *)sender;

@end

@implementation WEBLEMyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    /*
    self.manager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    _cbReady = false;
    _nDevices = [[NSMutableArray alloc]init];
    _nServices = [[NSMutableArray alloc]init];
    _nCharacteristics = [[NSMutableArray alloc]init];
    
    _bluetoothTable.delegate = self;
    _bluetoothTable.dataSource = self;
    
    count = 0;
    
    _isConnected = NO;
     */
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_nDevices count];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identified = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identified];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identified];
    }
    CBPeripheral *p = [_nDevices objectAtIndex:indexPath.row];
    cell.textLabel.text = p.name;
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    _peripheral = [_nDevices objectAtIndex:indexPath.row];
}

//textView更新
-(void)updateLog:(NSString *)s
{
    [_resultTextView setText:[NSString stringWithFormat:@"[ %d ]  %@\r\n%@",count,s,_resultTextView.text]];
    count++;
}

//开始查看服务，蓝牙开启
-(void)centralManagerDidUpdateState:(CBCentralManager *)central
{
    switch (central.state) {
        case CBCentralManagerStatePoweredOn:
        {
            [self updateLog:@"蓝牙已打开,请扫描外设"];
            [_activity startAnimating];
            [_manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FF15"]]  options:@{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]}];
        }
            break;
        case CBCentralManagerStatePoweredOff:
            [self updateLog:@"蓝牙没有打开,请先打开蓝牙"];
            break;
        default:
            break;
    }
}

//查到外设后，停止扫描，连接设备
-(void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    [self updateLog:[NSString stringWithFormat:@"已发现 peripheral: %@ rssi: %@, UUID: %@ advertisementData: %@ ", peripheral, RSSI, peripheral.identifier, advertisementData]];
    
    _peripheral = peripheral;
//    [_manager connectPeripheral:_peripheral options:nil];
    
    [self.manager stopScan];
    [_activity stopAnimating];
    
    BOOL replace = NO;
    // Match if we have this device from before
    for (int i=0; i < _nDevices.count; i++) {
        CBPeripheral *p = [_nDevices objectAtIndex:i];
        if ([p isEqual:peripheral]) {
            [_nDevices replaceObjectAtIndex:i withObject:peripheral];
            replace = YES;
        }
    }
    if (!replace) {
        [_nDevices addObject:peripheral];
        [_bluetoothTable reloadData];
    }
}

//连接外设成功，开始发现服务
- (void)centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral {
    NSLog(@"%@", [NSString stringWithFormat:@"成功连接 peripheral: %@ with UUID: %@",peripheral,peripheral.identifier]);
    [self updateLog:[NSString stringWithFormat:@"成功连接 peripheral: %@ with UUID: %@",peripheral,peripheral.identifier]];
    
    [self.peripheral setDelegate:self];
    [self.peripheral discoverServices:nil];
    [self updateLog:@"扫描服务"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.timer = [NSTimer scheduledTimerWithTimeInterval:3.0f
                                                      target:self
                                                    selector:@selector(detectRSSI)
                                                    userInfo:nil
                                                     repeats:YES];
    });
    
    _isConnected = YES;
}

//连接外设失败
-(void)centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"%@",error);
    _isConnected = NO;
    
    // 销毁时钟
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
}

-(void)peripheral:(CBPeripheral *)peripheral didReadRSSI:(NSNumber *)RSSI error:(NSError *)error {
    NSLog(@"%s,%@",__PRETTY_FUNCTION__,peripheral);

    int rssi = abs([RSSI intValue]);
    NSString *length = [NSString stringWithFormat:@"发现BLT4.0热点:%@,强度:%.1ddb",_peripheral,rssi];
    [self updateLog:[NSString stringWithFormat:@"距离：%@", length]];
    
    if (rssi > 90) {
        // 距离过远 锁车
        [self lock];
    }
}

//已发现服务
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverServices:(NSError *)error{
    
    [self updateLog:@"发现服务."];
    int i=0;
    for (CBService *s in peripheral.services) {
        [self.nServices addObject:s];
    }
    for (CBService *s in peripheral.services) {
        [self updateLog:[NSString stringWithFormat:@"%d :服务 UUID: %@(%@)",i,s.UUID.data,s.UUID]];
        i++;
        [peripheral discoverCharacteristics:nil forService:s];
        
        if ([s.UUID isEqual:[CBUUID UUIDWithString:@"FF15"]]) {
            BOOL replace = NO;
            // Match if we have this device from before
            for (int i=0; i < _nDevices.count; i++) {
                CBPeripheral *p = [_nDevices objectAtIndex:i];
                if ([p isEqual:peripheral]) {
                    [_nDevices replaceObjectAtIndex:i withObject:peripheral];
                    replace = YES;
                }
            }
            if (!replace) {
                [_nDevices addObject:peripheral];
                [_bluetoothTable reloadData];
            }
        }
    }
}

//已搜索到Characteristics
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error{
    [self updateLog:[NSString stringWithFormat:@"发现特征的服务:%@ (%@)",service.UUID.data ,service.UUID]];
    
    for (CBCharacteristic *c in service.characteristics) {
        [self updateLog:[NSString stringWithFormat:@"特征 UUID: %@ (%@)",c.UUID.data,c.UUID]];
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FF01"]]) {
            _writeCharacteristic = c;
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FF02"]]) {
            [_peripheral readValueForCharacteristic:c];
            [_peripheral setNotifyValue:YES forCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FF04"]]) {
            [_peripheral readValueForCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FF05"]]) {
            [_peripheral readValueForCharacteristic:c];
            [_peripheral setNotifyValue:YES forCharacteristic:c];
        }
        
        if ([c.UUID isEqual:[CBUUID UUIDWithString:@"FFA1"]]) {
            [_peripheral readRSSI];
        }
        
        [_nCharacteristics addObject:c];
    }
}

- (void)centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error {
    [self updateLog:[NSString stringWithFormat:@"已断开与设备:[%@]的连接", peripheral.name]];
    
    _isConnected = NO;
    
    // 销毁时钟
    if ([_timer isValid]) {
        [_timer invalidate];
        _timer = nil;
    }
    
    [_nDevices removeObject:peripheral];
    [_bluetoothTable reloadData];
}

//获取外设发来的数据，不论是read和notify,获取数据都是从这个方法中读取。
- (void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FF02"]]) {
        NSData * data = characteristic.value;
        Byte * resultByte = (Byte *)[data bytes];
        
        for(int i=0;i<[data length];i++)
            printf("testByteFF02[%d] = %d\n",i,resultByte[i]);
        
        switch (resultByte[0]) {
            case 1: // 鉴权
            {
                if (resultByte[1] == 0) {
                    [self updateLog:@"鉴权成功"];
                    [self writePassword:nil newPw:nil];
                }else if (resultByte[1] == 1) {
                    [self updateLog:@"未知错误"];
                }else if (resultByte[1] == 2) {
                    [self updateLog:@"鉴权失败"];
                }
            }
            case 2: // 写密码
            {
                if (resultByte[1] == 0) {
                    [self updateLog:@"写密码成功"];
                }else if (resultByte[1] == 1) {
                    [self updateLog:@"未知错误"];
                }else if (resultByte[1] == 2) {
                    [self updateLog:@"鉴权失败"];
                }
            }
            case 3: // 加解锁
            {
                if (resultByte[1] == 0) {
                    if (resultByte[2] == 0) {
                        [self updateLog:@"撤防成功!!!"];
                        _isLocked = NO;
                    }else if (resultByte[2] == 1) {
                        [self updateLog:@"设防成功!!!"];
                        _isLocked = YES;
                    }
                }else if (resultByte[1] == 1) {
                    [self updateLog:@"未知错误"];
                }else if (resultByte[1] == 2) {
                    [self updateLog:@"鉴权失败"];
                }
            }
                break;
            case 4: // 开坐桶
            {
                if (resultByte[1] == 0) {
                    if (resultByte[2] == 0) {
                        [self updateLog:@"关坐桶成功!!!"];
                    }else if (resultByte[2] == 1) {
                        [self updateLog:@"开坐桶成功!!!"];
                    }
                }else if (resultByte[1] == 1) {
                    [self updateLog:@"未知错误"];
                }else if (resultByte[1] == 2) {
                    [self updateLog:@"鉴权失败"];
                }
            }
                break;
            case 5: // 锁定电机
            {
                if (resultByte[1] == 0) {
                    if (resultByte[2] == 0) {
                        [self updateLog:@"解锁电机控制器成功!!!"];
                    }else if (resultByte[2] == 1) {
                        [self updateLog:@"锁定电机控制器成功!!!"];
                    }
                }else if (resultByte[1] == 1) {
                    [self updateLog:@"未知错误"];
                }else if (resultByte[1] == 2) {
                    [self updateLog:@"鉴权失败"];
                }
            }
                break;
            default:
                break;
        }
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FF04"]]) {
        NSData * data = characteristic.value;
        Byte * resultByte = (Byte *)[data bytes];
        
        for(int i=0;i<[data length];i++)
            printf("testByteFF04[%d] = %d\n",i,resultByte[i]);
        
        if (resultByte[0] == 0) {
            // 未绑定 -》写鉴权码
            [self updateLog:@"当前车辆未绑定，请鉴权"];
            [self authentication];  // 鉴权
        }else if (resultByte[0] == 1) {
            // 已绑定 -》鉴权
            [self updateLog:@"当前车辆已经绑定，请鉴权"];
            [self writePassword:nil newPw:nil];
        }else if (resultByte[0] == 2) {
            // 允许绑定
            [self updateLog:@"当前车辆允许绑定"];
        }
    }
    
    if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:@"FF05"]]) {
        NSData * data = characteristic.value;
        Byte * resultByte = (Byte *)[data bytes];
        
        for(int i=0;i<[data length];i++)
            printf("testByteFF05[%d] = %d\n",i,resultByte[i]);
        
        if (resultByte[0] == 0) {
            // 设备加解锁状态 0 撤防     1 设防
            [self updateLog:@"当前车辆撤防状态"];
        }else if (resultByte[0] == 1) {
            // 设备加解锁状态 0 撤防     1 设防
            [self updateLog:@"当前车辆设防状态"];
        }
    }
}

//中心读取外设实时数据
- (void)peripheral:(CBPeripheral *)peripheral didUpdateNotificationStateForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error {
    if (error) {
        NSLog(@"Error changing notification state: %@", error.localizedDescription);
    }
    
    // Notification has started
    if (characteristic.isNotifying) {
        [peripheral readValueForCharacteristic:characteristic];
    } else { // Notification has stopped
        // so disconnect from the peripheral
        NSLog(@"Notification stopped on %@.  Disconnecting", characteristic);
        [self updateLog:[NSString stringWithFormat:@"Notification stopped on %@.  Disconnecting", characteristic]];
        [self.manager cancelPeripheralConnection:self.peripheral];
    }
}

//用于检测中心向外设写数据是否成功
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if (error) {
        NSLog(@"=======%@",error.userInfo);
        [self updateLog:[error.userInfo JSONString]];
    }else{
        NSLog(@"发送数据成功");
        [self updateLog:@"发送数据成功"];
    }

    /* When a write occurs, need to set off a re-read of the local CBCharacteristic to update its value */
    [peripheral readValueForCharacteristic:characteristic];
}

- (void)detectRSSI
{
    if (_peripheral && _isConnected) {
        [_peripheral readRSSI];
    }
}

#pragma mark - 蓝牙的相关操作
- (IBAction)bluetoothAction:(UIButton *)sender {
    switch (sender.tag) {
        case 201:
        {   // 搜索设备
            [self updateLog:@"正在扫描外设..."];
            [_activity startAnimating];
            [_manager scanForPeripheralsWithServices:@[[CBUUID UUIDWithString:@"FF15"]]  options:@{CBCentralManagerScanOptionAllowDuplicatesKey : [NSNumber numberWithBool:YES]}];
            
            double delayInSeconds = 30.0;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                [self.manager stopScan];
                [_activity stopAnimating];
                [self updateLog:@"扫描超时,停止扫描"];
            });
        }
            break;
        case 202:
        {   // 连接
            if (_peripheral && _cbReady) {
//                [_manager connectPeripheral:_peripheral options:nil];
                _cbReady = NO;
            }
        }
            break;
        case 203:
        {   // 断开
            if (_peripheral && !_cbReady) {
                [_manager cancelPeripheralConnection:_peripheral];
                _cbReady = YES;
            }
        }
            break;
        case 204:
        {   // 暂停搜索
            [self.manager stopScan];
            [_activity stopAnimating];
        }
            break;
        case 211:
        {   // 车辆上锁
            [self lock];
        }
            break;
        case 212:
        {   // 车辆解锁
            [self unLock];
        }
            break;
        case 213:
        {   // 开启坐桶
            [self open];
        }
            break;
        case 214:
        {   // 立即寻车
            [self find];
        }
            break;
        default:
            break;
    }
}

-(NSOperationQueue *)queue {
    if (!_queue) {  // 请求队列
        self.queue = [[NSOperationQueue alloc]init];
        [self.queue setMaxConcurrentOperationCount:1];
    }
    
    return _queue;
}

#pragma mark -
#pragma mark - 鉴权
-(void)authentication {
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:[self hexToBytes:@"112345678"] forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 写密码 
-(void)writePassword:(NSString *)initialPw newPw:(NSString *)newPw {
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:[self hexToBytes:@"20000000012345678"] forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 车辆上锁
-(void)lock {
    
    if (_isLocked) {
        return;
    }
    
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:[self hexToBytes:@"31"] forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 车辆解锁
-(void)unLock {
    
    if (!_isLocked) {
        return;
    }
    
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:[self hexToBytes:@"30"] forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 开启坐桶
-(void)open {
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:[self hexToBytes:@"41"] forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 立即寻车
-(void)find {
    if (_peripheral.state == CBPeripheralStateConnected) {
        [_peripheral writeValue:[self hexToBytes:@"7"] forCharacteristic:_writeCharacteristic type:CBCharacteristicWriteWithoutResponse];
    }
}

#pragma mark - 其它方法
-(NSData *)hexToBytes:(NSString *)hexString {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx < hexString.length; idx++) {
        NSRange range = NSMakeRange(idx, 1);
        NSString* hexStr = [hexString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    
    return data;
}

@end
