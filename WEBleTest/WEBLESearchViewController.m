//
//  ;
//  WEBluetooth
//
//  Created by Tilink on 15/7/27.
//  Copyright (c) 2015年 Tilink. All rights reserved.
//

#import "WEBLESearchViewController.h"

#import "QWSBluetooth.h"

static int WAIT_BIND_COUNT              = 200;// 等待用户确认次数
static const NSInteger kTimeOutSeconds  = 10;
static const NSInteger kTimeInDiscovery = 2;

void MyAlert(NSString * title,NSString * message)
{
    UIAlertView * alert = [[UIAlertView alloc]initWithTitle:title message:message delegate:nil cancelButtonTitle:@"我知道了" otherButtonTitles: nil];
    [alert show];
}

@interface WEBLESearchViewController () <QWSBleHandlerDelegate> {
    NSInteger index;
    BOOL      isOK;
    int       count;
    NSString  *linshiPassword;
    BOOL      decideConnect;
}

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView * activetyIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton * actionButton;
@property (weak, nonatomic) IBOutlet UILabel * devInfoLabel;

@property (strong, nonatomic) QWSBleHelper *mBleHelper;
@property (strong, nonatomic) NSString *authQWSServiceUUID;
@property (strong, nonatomic) NSMutableArray *denyDevices;
@property (strong, nonatomic) NSArray *foundDevices;

@end

@implementation WEBLESearchViewController

@synthesize denyDevices;
@synthesize mBleHelper;

-(void)dealloc {
    if (mBleHelper) {
        mBleHelper = nil;
    }
    
    NSLog(@"B100BlueBindDevViewController已释放");
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view
    
    self.foundDevices = [[NSArray alloc]init];
    denyDevices = [[NSMutableArray alloc]init];
    mBleHelper = [[QWSBleHelper alloc]initWithDelegate:self];
    
    [self startScaningDevice];
}

#pragma mark -
#pragma mark - QWSBleHandlerDelegate
-(void)onBleStateChanged:(CBCentralManagerState)state {
    if (state == CBCentralManagerStatePoweredOn) {
        [self showHint:@"蓝牙已打开"];
        [self startScaningDevice];
    }else if (state == CBCentralManagerStatePoweredOff) {
        [self showHint:@"蓝牙已断开"];
        [self stopScaningDevice];
    }
}
-(void)onConnected:(NSString *)uuid isQwsDevice:(BOOL)isQwsDevice {
    linshiPassword = nil;
    if ([denyDevices containsObject:uuid]) {
        [mBleHelper disconnectAndRm:uuid];
        return;
    }
    
    if (isQwsDevice) {
        if ([uuid isEqualToString:_authQWSServiceUUID]) {
            [mBleHelper requestBindVoice:uuid voice:0];
            [mBleHelper readBindState:uuid];
        }
        
        if (decideConnect) {
            QWSDevControlService * device = [mBleHelper searchDeviceWithUUID:uuid];
            
            if (device == nil && device.peripheral == nil) {
                return;
            }
            
            [self displayCurrentDevice:device];
        }
    }
}
-(void)onDisconnected:(NSString *)uuid {
    linshiPassword = nil;
}
-(void)onError:(NSString *)uuid errReason:(int)errReason status:(int)status {
    linshiPassword = nil;
    
    if (![uuid isEqualToString:_authQWSServiceUUID]) {
        return;
    }
    
    if (errReason == ERROR_REASON_DEVICE_AUTH_FAIL) {
        [self showHint:@"鉴权失败"];
    }else if (errReason == ERROR_REASON_DEVICE_BUSY) {
        [self showHint:@"设备忙 请稍后"];
    }else if (errReason == ERROR_REASON_READ_CHARACTERISTIC) {
        [self showHint:@"读状态错误"];
    }else if (errReason == ERROR_REASON_SERVICE_DISCOVERY) {
        [self showHint:@"发现服务错误"];
    }else if (errReason == ERROR_REASON_SET_VALUE_FAIL) {
        [self showHint:@"设置错误"];
    }else if (errReason == ERROR_REASON_UNKNOWN) {
        [self showHint:@"未知错误"];
    }else if (errReason == ERROR_REASON_WRITE_CHARACTERISTIC) {
        [self showHint:@"写状态错误"];
    }
}
-(void)onGetAuthoried:(NSString *)uuid isSuccess:(BOOL)isSuccess {
    if (![uuid isEqualToString:_authQWSServiceUUID]) {
        return;
    }
    
    if (isSuccess) {
        if (!isOK) {
            isOK = YES;
            NSLog(@"BScan %@：鉴权成功", uuid);
            [self showTextOnly:@"鉴权成功"];
            [self setNameViewController:uuid];
        }
    }else {
        linshiPassword = nil;
        NSLog(@"BScan %@：鉴权失败", uuid);
        [self showTextOnly:@"鉴权失败"];
        [mBleHelper disconnectAndRm:uuid];
    }
}
-(void)onGetBindState:(NSString *)uuid state:(QwsBleDeviceBindState)state {
    if (![uuid isEqualToString:_authQWSServiceUUID]) {
        return;
    }
    
    if (state == kDevStateUnBind) {
        double delayInSeconds = 0.4f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [mBleHelper readBindState:uuid];
        });
        
        NSLog(@"QWSDevControlService 第%d次等待绑定", count);
        if (++count >= WAIT_BIND_COUNT) {
            [mBleHelper disconnectAndRm:uuid];
            count = 0;
        }
    }else if (state == kDevStateBinded) {
        self.authQWSServiceUUID = uuid;
        [self authentication:uuid];
    }else if (state == kDevStateAllowBind) {
        [self writePassword:uuid];
    }
}
-(void)onWritePassword:(NSString *)uuid success:(BOOL)success {
    if (![uuid isEqualToString:_authQWSServiceUUID]) {
        return;
    }
    
    if (success) {
        [self authentication:uuid];
    }else {
        linshiPassword = nil;
    }
}

#pragma mark -
#pragma mark - moveToNext
-(void)setNameViewController:(NSString *)uuid {
    
}

-(void)startScaningDevice {
    if (![mBleHelper isBleOpen]) {
        self.devInfoLabel.hidden = YES;
        MyAlert(@"提示", @"请先开启蓝牙");
    }else {
        index = 0;
        isOK = NO;
        count = 0;
        
        self.devInfoLabel.hidden = YES;
        self.actionButton.hidden = YES;
        
        [mBleHelper start];
        
        [self performSelector:@selector(decidetoConnected) withObject:[NSNumber numberWithBool:YES] afterDelay:kTimeInDiscovery];
        [self performSelector:@selector(stopScaningDevice) withObject:[NSNumber numberWithBool:YES] afterDelay:kTimeOutSeconds];
    }
}

-(void)decidetoConnected {
    _foundDevices = [self sortedByRssi:[mBleHelper foundDevices]];
    
    if ([_foundDevices count]) {
        QWSDevControlService * maxRssiService = nil;
        int max = -127;
        for (NSInteger i = 0; i < [_foundDevices count]; i++) {
            QWSDevControlService * device = (QWSDevControlService*)[_foundDevices objectAtIndex:i];
            int rssi = [device.RSSI intValue];
            
            if (rssi >= max) {
                max = rssi;
                maxRssiService = device;
            }
        }
        
        [self displayCurrentDevice:maxRssiService];
    }else {
        decideConnect = YES;
    }
    
    if ([_foundDevices count]) {
        [self stopScaningDevice];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopScaningDevice) object:[NSNumber numberWithBool:YES]];
    }
}

-(void)stopScaningDevice {
    [mBleHelper stop];     // 停止扫描
    
    self.foundDevices = [self sortedByRssi:[mBleHelper foundDevices]];
    self.actionButton.hidden = NO;
    
    if (_foundDevices.count == 0) {
        // 没有搜到 重新搜索
        [self.actionButton setTitle:@"重新搜索" forState:UIControlStateNormal];
    }else if ((_foundDevices.count == 1)) {
        [self.actionButton setTitle:@"不是这个，重新搜索" forState:UIControlStateNormal];
        
        QWSDevControlService * device = [_foundDevices firstObject];
        [self displayCurrentDevice:device];
    }else {
        [self.actionButton setTitle:@"下一个" forState:UIControlStateNormal];
        QWSDevControlService * device = [_foundDevices firstObject];
        [self displayCurrentDevice:device];
    }
}

- (IBAction)actionButtonClickEvent:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"重新搜索"] ||
        [sender.titleLabel.text isEqualToString:@"不是这个，重新搜索"] ||
        [sender.titleLabel.text isEqualToString:@"开始搜索"]) {
        
        _foundDevices = nil;
        [self startScaningDevice];
    }else if ([sender.titleLabel.text isEqualToString:@"下一个"]) {
        index++;
        if (index < _foundDevices.count) {
            QWSDevControlService * device = _foundDevices[index];
            [self displayCurrentDevice:device];
            
            if (index == _foundDevices.count - 1) {
                [self.actionButton setTitle:@"不是这个，重新搜索" forState:UIControlStateNormal];
            }
        }else {
            index = 0;
        }
    }
    
    if (self.authQWSServiceUUID) {
        [denyDevices addObject:_authQWSServiceUUID];
    }
}

// 排序
-(NSArray *)sortedByRssi:(NSArray *)deviceArray {
    NSMutableArray * tmp = [[NSMutableArray alloc]initWithArray:deviceArray];
    if ([tmp count] == 0) {
        return tmp;
    }
    
    for (NSInteger i = 0; i < [tmp count] - 1; i++) {
        QWSDevControlService * device1 = [tmp objectAtIndex:i];
        for (NSInteger j = i + 1; j < [tmp count]; j++) {
            QWSDevControlService * device2 = [tmp objectAtIndex:j];
            if ([device1.RSSI integerValue] < [device2.RSSI integerValue]) {
                [tmp exchangeObjectAtIndex:i withObjectAtIndex:j];
            }
        }
    }
    
    for (NSInteger i = 0; i < [tmp count]; i++) {
        QWSDevControlService * device = [tmp objectAtIndex:i];
        if ([denyDevices containsObject:device.UUIDString]) {
            [mBleHelper disconnectAndRm:device.UUIDString];
            [tmp removeObject:device];
        }
    }
    
    return tmp.copy;
}

-(void)displayCurrentDevice:(QWSDevControlService *)device {
    self.devInfoLabel.hidden = NO;
    
    _authQWSServiceUUID = device.UUIDString;
    [mBleHelper connect:device.UUIDString autoConnect:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark - NSNotificationCenter Method
-(void)authentication:(NSString *)uuid {
    if (!linshiPassword) {
        return;
    }
    
    Byte *newPassword = [mBleHelper hexToBytes:linshiPassword];
    [mBleHelper requestAuthority:uuid password:newPassword];
}

-(void)writePassword:(NSString *)uuid {
    Byte oldPassword[8] = {0,0,0,0,0,0,0,0};
    NSString *tmp = [self randomSome:8];
    
    Byte *newPassword = [mBleHelper hexToBytes:tmp];
    linshiPassword = tmp;
    [mBleHelper requestWritePassword:uuid oldPassword:oldPassword newPassword:newPassword];
}

-(NSString *)randomSome:(int)total {
    if (linshiPassword) {
        return linshiPassword;
    }
    
    NSMutableString * tmp = [[NSMutableString alloc]init];
    for (int i = 0; i < total; i++) {
        int a = random()%9 + 1;
        [tmp appendFormat:@"%d", a];
    }
    
    return tmp.copy;
}

-(void)showHint:(NSString *)hint {
    
}

-(void)showTextOnly:(NSString *)hint {
    
}

- (IBAction)actionButtonClickEvetn:(UIButton *)sender {
    // 重新扫描
    
}

@end
