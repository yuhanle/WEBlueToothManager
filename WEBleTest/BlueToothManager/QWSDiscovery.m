//
//  QWSDevControlService.h
//  WEBluetooth
//
//  Created by yuhanle on 15/7/23.
//  Copyright (c) 2015年 yuhanle. All rights reserved.
//

#import "QWSDiscovery.h"

NSString * ACTION_GATT_CONNECTED           = @"com.yuhanle.qws.ble.ACTION_GATT_CONNECTED";
NSString * ACTION_GATT_DISCONNECTED        = @"com.yuhanle.qws.ble.ACTION_GATT_DISCONNECTED";
NSString * ACTION_GATT_SERVICES_DISCOVERED = @"com.yuhanle.qws.ble.ACTION_GATT_SERVICES_DISCOVERED";
NSString * ACTION_DATA_AVAILABLE           = @"com.yuhanle.qws.ble.ACTION_DATA_AVAILABLE";
NSString * ACTION_READ_RSSI                = @"com.yuhanle.qws.ble.ACTION_READ_RSSI";
NSString * ACTION_BLE_ERROR                = @"com.yuhanle.qws.ble.ACTION_BLE_ERROR";
NSString * ACTION_BLE_STATECHANGE          = @"com.yuhanle.qws.ble.ACTION_BLE_STATECHANGE";
NSString * EXTRA_DATA                      = @"com.yuhanle.qws.ble.EXTRA_DATA";
NSString * EXTRA_ADDRESS                   = @"com.yuhanle.qws.ble.EXTRA_ADDRESS";
NSString * EXTRA_ERROR_REASON              = @"com.yuhanle.qws.ble.EXTRA_ERROR_REASON";
NSString * EXTRA_CHAR                      = @"com.yuhanle.qws.ble.EXTRA_CHAR";
NSString * EXTRA_STATUS                    = @"com.yuhanle.qws.ble.EXTRA_STATUS";

int ERROR_REASON_UNKNOWN              = 999;
int ERROR_REASON_WRITE_CHARACTERISTIC = 1000;
int ERROR_REASON_READ_CHARACTERISTIC  = 1001;
int ERROR_REASON_SERVICE_DISCOVERY    = 1002;
int ERROR_REASON_SET_VALUE_FAIL       = 1003;
int ERROR_REASON_DEVICE_BUSY          = 1004;
int ERROR_REASON_DEVICE_AUTH_FAIL     = 1005;

const int STATE_DISCONNECTED          = 0;
const int STATE_CONNECTING            = 1;
const int STATE_DISCONNECTING         = 2;
const int STATE_CONNECTED             = 3;
const int STATE_INVALID               = -1;

static const NSString * TAG = @"QWSDiscovery";

@interface QWSDiscovery () <CBCentralManagerDelegate, CBPeripheralDelegate> {
	CBCentralManager    *centralManager;
}

@end

@implementation QWSDiscovery

@synthesize localStoragePeripherals;

#pragma mark -
#pragma mark Init
/****************************************************************************/
/*									Init									*/
/****************************************************************************/
+ (id) sharedInstance
{
	static QWSDiscovery	*this	= nil;

	if (!this)
		this = [[QWSDiscovery alloc] init];

	return this;
}


- (id) init
{
    self = [super init];
    if (self) {
        centralManager          = [[CBCentralManager alloc] initWithDelegate:self queue:dispatch_get_main_queue()];
        localStoragePeripherals = [[NSMutableDictionary alloc]init];
	}
    
    return self;
}


- (void) dealloc
{
    // We are a singleton and as such, dealloc shouldn't be called.
    assert(NO);
}


#pragma mark -
#pragma mark Restoring
/****************************************************************************/
/*								Settings									*/
/****************************************************************************/
/* Reload from file. */
-(NSDictionary *)loadSavedDevices
{
    return localStoragePeripherals;
}

-(BOOL)addSavedDevice:(QWSDevControlService *)device
{
    NSString * uuid = device.UUIDString;
    if ([self isSaveDeviceExist:uuid]) {
        NSLog(@"重复添加！！！");
        return NO;
    }
    
    [localStoragePeripherals setObject:device forKey:uuid];
    
    return YES;
}

-(BOOL)removeSavedDevice:(NSString *) uuid
{
    if (![self isSaveDeviceExist:uuid]) {
        NSLog(@"不存在该设备！！！");
        return NO;
    }
    
    [localStoragePeripherals removeObjectForKey:uuid];
    
    return YES;
}

-(BOOL)isSaveDeviceExist:(NSString *)uuid {
    NSDictionary * localDeviceDict = localStoragePeripherals.copy;
    NSArray * uuidKeys = [localDeviceDict allKeys];
    
    for (NSInteger i = 0; i < [uuidKeys count]; i++) {
        QWSDevControlService * device = [localDeviceDict objectForKey:uuidKeys[i]];
        if ([uuid isEqualToString:device.UUIDString]) {
            return YES;
        }
    }
    
    return NO;
}

-(QWSDevControlService *)searchDeviceWithUUID:(NSString *)uuid {
    NSDictionary * localDeviceDict = localStoragePeripherals.copy;
    NSArray * deviceUUIDKeys = [localDeviceDict allKeys];
    
    for (NSInteger i = 0; i < [deviceUUIDKeys count]; i++) {
        QWSDevControlService * device = [localDeviceDict objectForKey:deviceUUIDKeys[i]];
        if ([uuid isEqualToString:device.UUIDString]) {
            return device;
        }
    }
    
    return nil;
}

-(NSMutableArray *)foundPeripherals {
    NSMutableArray * found = [[NSMutableArray alloc]init];
    NSArray * allKeys = [localStoragePeripherals allKeys];
    
    for (NSString * key in allKeys) {
        QWSDevControlService * device = [localStoragePeripherals objectForKey:key];
        if (!device.isAuthoritied) {
            [found addObject:device];
        }
    }
    
    return found;
}

#pragma mark -
#pragma mark - retrieveConnected
- (void) centralManager:(CBCentralManager *)central willRestoreState:(NSDictionary *)state
{
    NSArray *peripherals = state[CBCentralManagerRestoredStatePeripheralsKey];
    
    CBPeripheral *peripheral;
    
    /* Add to list. */
    for (peripheral in peripherals) {
        [self connectPeripheral:peripheral];
    }
}
- (void) centralManager:(CBCentralManager *)central didRetrieveConnectedPeripherals:(NSArray *)peripherals
{
	CBPeripheral *peripheral;
	
	/* Add to list. */
	for (peripheral in peripherals) {
        if (peripheral) {
            [self connectPeripheral:peripheral];
        }
	}
}
- (void)centralManager:(CBCentralManager *)central didRetrievePeripherals:(NSArray *)peripherals {
    CBPeripheral *peripheral;
    
    /* Add to list. */
    for (peripheral in peripherals) {
        [self connectPeripheral:peripheral];
    }
}


#pragma mark -
#pragma mark Discovery
/****************************************************************************/
/*								Discovery                                   */
/****************************************************************************/
- (void)startScanning:(NSString *)uuidString
{
	NSArray	* uuidArray	= [NSArray arrayWithObjects:[CBUUID UUIDWithString:uuidString], nil];
    NSDictionary	*options	= [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:YES] forKey:CBCentralManagerScanOptionAllowDuplicatesKey];
	[centralManager scanForPeripheralsWithServices:uuidArray options:options];
}

- (void)stopScanning
{
	[centralManager stopScan];
}

- (void)centralManager:(CBCentralManager *)central didDiscoverPeripheral:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI
{
    QWSDevControlService * device = [self searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
    if (!device) {
        device = [[QWSDevControlService alloc] initWithPeripheral:peripheral];
        [self addSavedDevice:device];
    }
    
    device.RSSI = RSSI;
    [self connectPeripheral:peripheral];
    [self onConnectionStateChange:peripheral status:device.mState newState:STATE_CONNECTING];
}


#pragma mark -
#pragma mark Connection/Disconnection
/****************************************************************************/
/*						Connection/Disconnection                            */
/****************************************************************************/
- (void) connectPeripheral:(CBPeripheral*)peripheral
{
    QWSDevControlService * device = [self searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
	if ([peripheral state] != CBPeripheralStateConnected) {
        if (device == nil) {
            device = [[QWSDevControlService alloc]initWithPeripheral:peripheral];
            device.mState = STATE_CONNECTING;
            
            [self addSavedDevice:device];
        }
        
		[centralManager connectPeripheral:peripheral options:nil];
    }else {
        if (device == nil) {
            device = [[QWSDevControlService alloc]initWithPeripheral:peripheral];
            device.mState = STATE_CONNECTED;
            
            [self addSavedDevice:device];
        }
    }
}

- (void) disconnectPeripheral:(CBPeripheral*)peripheral
{
    if (peripheral == nil) {
        NSLog(@"%@, peripheral is nil", TAG);
        return;
    }
    
	[centralManager cancelPeripheralConnection:peripheral];
}


- (void) centralManager:(CBCentralManager *)central didConnectPeripheral:(CBPeripheral *)peripheral
{
    QWSDevControlService *device = [self searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
    if (device == nil) {
        device = [[QWSDevControlService alloc]initWithPeripheral:peripheral];
        [self addSavedDevice:device];
    }
    
    [device start];
    
    [self onConnectionStateChange:peripheral status:device.mState newState:STATE_CONNECTED];
}


- (void) centralManager:(CBCentralManager *)central didFailToConnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    NSLog(@"Attempted connection to peripheral %@ failed: %@", [peripheral name], [error localizedDescription]);
    
    QWSDevControlService *device = [self searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
    if (device == nil) {
        return;
    }
    
    [self onConnectionStateChange:peripheral status:device.mState newState:STATE_INVALID];
}


- (void) centralManager:(CBCentralManager *)central didDisconnectPeripheral:(CBPeripheral *)peripheral error:(NSError *)error
{
    QWSDevControlService *device = [self searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
    if (device == nil) {
        return;
    }
    
    [self onConnectionStateChange:peripheral status:device.mState newState:STATE_DISCONNECTED];
}


- (void) centralManagerDidUpdateState:(CBCentralManager *)central
{
    static int previousState = -1;
    
	switch ([central state]) {
            
        case CBCentralManagerStateUnknown:
        {
            /* Bad news, let's wait for another event. */
            break;
        }
            
        case CBCentralManagerStateResetting:
        {
            break;
        }
            
        case CBCentralManagerStateUnsupported:
        {
            /* Tell user the app is not allowed. */
            break;
        }
            
        case CBCentralManagerStateUnauthorized:
        {
            /* Tell user the app is not allowed. */
            break;
        }
            
		case CBCentralManagerStatePoweredOn:
		{
            /* Tell user to power ON BT for functionality, but not on first run - the Framework will alert in that instance. */
            [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_BLE_STATECHANGE object:nil userInfo:@{EXTRA_DATA:[NSNumber numberWithInt:CBCentralManagerStatePoweredOn]}];
			break;
		}
            
        case CBCentralManagerStatePoweredOff:
        {
            /* Tell user to power ON BT for functionality, but not on first run - the Framework will alert in that instance. */
            if (previousState != -1) {
                [self closeAll];
                
                [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_BLE_STATECHANGE object:nil userInfo:@{EXTRA_DATA:[NSNumber numberWithInt:CBCentralManagerStatePoweredOff]}];
            }
            break;
        }
	}
    
    previousState = [central state];
}

-(void)onConnectionStateChange:(CBPeripheral *)peripheral status:(int)status newState:(int)newState {
    NSString * intentAction = nil;
    QWSDevControlService * device = [self searchDeviceWithUUID:peripheral.identifier.UUIDString];
    
    if (device == nil) {
        NSLog(@"%@, onConnectionStateChange() info should not be null", TAG);
        return;
    }
    
    NSString * uuid = peripheral.identifier.UUIDString;
    NSLog(@"%@, onConnectionStateChange status=%d, newState=%d, uuid=%@", TAG, status, newState, uuid);
    
    if (newState == STATE_CONNECTED) {
        intentAction = ACTION_GATT_CONNECTED;
        device.mState = STATE_CONNECTED;
        
        [self broadcastUpdate:peripheral action:intentAction];
        
        if ([peripheral services]) {
            device.isServiceDiscovered = true;
        }else {
            [self broadcastError:peripheral reason:ERROR_REASON_SERVICE_DISCOVERY status:-1];
        }
    }else if (newState == STATE_DISCONNECTED) {
        NSLog(@"%@, Disconnected from GATT server %@", TAG, uuid);
        intentAction = ACTION_GATT_DISCONNECTED;
        device.mState = STATE_DISCONNECTED;
        
        if (device.isNeedCloseAfterDisconnected) {
            [self broadcastUpdate:peripheral action:intentAction];
            [self close:uuid];
        }else {
            BOOL autoConnect = device.isAutoConnect;
            int retryCount = device.mRetryCount - 1;
            
            if (autoConnect) {
                [self broadcastUpdate:peripheral action:intentAction];
                [self close:uuid];
                [self connect:uuid autoConnect:YES];
            }else {
                if (retryCount >= 0) {
                    [self close:uuid];
                    [self connect:uuid autoConnect:NO retryCount:retryCount];
                }else {
                    [self broadcastUpdate:peripheral action:intentAction];
                    [self close:uuid];
                }
            }
        }
    }
}

#pragma mark -
#pragma mark - 发送通知
-(void)broadcastUpdate:(CBPeripheral *)peripheral action:(NSString *)action {
    NSDictionary * intent = @{EXTRA_ADDRESS : peripheral.identifier.UUIDString};
    [[NSNotificationCenter defaultCenter] postNotificationName:action object:self userInfo:intent];
}
-(void)broadcastError:(CBPeripheral *)peripheral reason:(int)reason status:(int)status {
    NSDictionary * intent = @{EXTRA_ADDRESS : peripheral.identifier.UUIDString,
                              EXTRA_ERROR_REASON : [NSNumber numberWithInt:reason],
                              EXTRA_STATUS : [NSNumber numberWithInt:status]};
    [[NSNotificationCenter defaultCenter] postNotificationName:ACTION_BLE_ERROR object:self userInfo:intent];
}

-(void)broadcastUpdate:(CBPeripheral *)peripheral action:(NSString *)action characteristic:(CBCharacteristic *)characteristic {
    NSMutableDictionary * intent = @{EXTRA_ADDRESS : peripheral.identifier.UUIDString,
                                     EXTRA_CHAR : [characteristic.UUID representativeString]}.mutableCopy;
    
    NSData * data = [characteristic value];
    if (data != nil && sizeof(data) > 0) {
        [intent setObject:EXTRA_DATA forKey:data];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:action object:self userInfo:intent];
}
/**
 * Connects to the GATT server hosted on the Bluetooth LE device.
 *
 * @param address
 *            The device address of the destination device.
 *
 * @return Return true if the connection is initiated successfully. The
 *         connection result is reported asynchronously through the
 *         {@code BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)}
 *         callback.
 */
-(int)connect:(NSString *)uuid {
    return [self connect:uuid autoConnect:false];
}

-(int)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect {
    return [self connect:uuid autoConnect:autoConnect retryCount:3];
}

-(int)connect:(NSString *)uuid autoConnect:(BOOL)autoConnect retryCount:(int)retryCount {
    NSLog(@"%@. connect() %@", TAG, uuid);
    
    if (centralManager == nil || uuid == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized or unspecified address.", TAG);
        return STATE_INVALID;
    }
    
    // Previously connected device. Try to reconnect.
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device != nil && device.peripheral != nil) {
        NSLog(@"%@, Trying to use an existing mBluetoothGatt for connection. state=%d", TAG, device.mState);
        device.isAutoConnect = autoConnect;
        device.isNeedCloseAfterDisconnected = false;
        
        if (device.mState == STATE_CONNECTED) {
            return device.mState;
        }else if (device.mState == STATE_CONNECTING) {
            NSLog(@"%@, connect() STATA_CONNECTING", TAG);
            return device.mState;
        }else if (device.mState == STATE_DISCONNECTING) {
            NSLog(@"%@, connect() STATA_DISCONNECTING", TAG);
            return device.mState;
        }
        
        device.mRetryCount = retryCount;
        device.isAuthoritied = false;
        device.isServiceDiscovered = false;
        
        if ([device.peripheral state] == CBPeripheralStateConnected) {
            NSLog(@"%@, device.peripheral.isConnected STATE_CONNECTING", TAG);
            device.mState = STATE_CONNECTED;
            return device.mState;
        }else if ([device.peripheral state] == CBPeripheralStateConnecting) {
            device.mState = STATE_CONNECTING;
            return device.mState;
        }else {
            NSLog(@"%@, device.peripheral.isConnected STATE_INVALID", TAG);
            return STATE_INVALID;
        }
    }
    
    QWSDevControlService * newDevice = [[QWSDevControlService alloc]init];
    
    newDevice.UUIDString = uuid;
    newDevice.isAutoConnect = autoConnect;
    newDevice.isNeedCloseAfterDisconnected = false;
    newDevice.mRetryCount = retryCount;
    newDevice.isServiceDiscovered = false;
    newDevice.isAuthoritied = false;
    newDevice.mState = STATE_CONNECTING;
    
    [self connectDevices:@[uuid]];
    
    return newDevice.mState;
}

#pragma mark - connection
-(void)connectDevices:(NSArray *)uuids {
    NSArray * retrieveKnowArray = [centralManager retrievePeripheralsWithIdentifiers:uuids];
    if ([retrieveKnowArray count]) {
        for (CBPeripheral * peripheral in retrieveKnowArray) {
            [self connectPeripheral:peripheral];
        }
    }else {
        NSArray * retrieveConnectedArray = [centralManager retrieveConnectedPeripheralsWithServices:@[kDevControllServiceUUIDString]];
        if ([retrieveConnectedArray count]) {
            for (CBPeripheral * peripheral in retrieveConnectedArray) {
                [self connectPeripheral:peripheral];
            }
        }else {
            [self startScanning:kDevControllServiceUUIDString];
        }
    }
}

/**
 * Disconnects an existing connection or cancel a pending connection. The
 * disconnection result is reported asynchronously through the
 * {@code BluetoothGattCallback#onConnectionStateChange(android.bluetooth.BluetoothGatt, int, int)}
 * callback.
 */
-(void)disconnect:(NSString *)uuid {
    NSLog(@"%@, disconnect %@", TAG, uuid);
    
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        return;
    }
    
    switch (device.mState) {
        case STATE_CONNECTED:
            device.isNeedCloseAfterDisconnected = true;
            [self disconnectPeripheral:device.peripheral];
            device.mState = STATE_DISCONNECTED;
            break;
        case STATE_CONNECTING:
            [self disconnectPeripheral:device.peripheral];
            break;
        case STATE_INVALID:
            device.mState = STATE_DISCONNECTED;
            break;
        case STATE_DISCONNECTED:
        case STATE_DISCONNECTING:
            break;
        default:
            break;
    }
}

-(void)disconnectAll {
    if ([localStoragePeripherals count] == 0) {
        NSLog(@"%@, No device info", TAG);
        return;
    }
    
    for (NSString * uuid in [localStoragePeripherals allKeys]) {
        QWSDevControlService * device = [localStoragePeripherals objectForKey:uuid];
        if (device != nil) {
            [self disconnectPeripheral:device.peripheral];
            device.mState = STATE_CONNECTING;
        }
    }
}

/**
 * After using a given BLE device, the app must call this method to ensure
 * resources are released properly.
 */
-(void)close:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return;
    }
    
    device.peripheral = nil;
    [self removeSavedDevice:uuid];
    
    NSLog(@"%@, 关闭并移除连接 %@ %ld", TAG, uuid, (long)[localStoragePeripherals count]);
}

-(void)closeAll {
    if ([localStoragePeripherals count] == 0) {
        NSLog(@"%@, No device info", TAG);
        return;
    }
    
    for (NSString * uuid in [localStoragePeripherals allKeys]) {
        QWSDevControlService * device = [localStoragePeripherals objectForKey:uuid];
        if (device != nil) {
            device.peripheral = nil;
        }
    }
    
    [localStoragePeripherals removeAllObjects];
}

/**
 * Request a read on a given {@code BluetoothGattCharacteristic}. The read
 * result is reported asynchronously through the
 * {@code BluetoothGattCallback#onCharacteristicRead(android.bluetooth.BluetoothGatt, android.bluetooth.BluetoothGattCharacteristic, int)}
 * callback.
 *
 * @param characteristic
 *            The characteristic to read from.
 */
#pragma mark -
#pragma mark - 读写方法
-(void)readCharacteristic:(NSString *)uuid characteristic:(CBCharacteristic *)charateristic {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return;
    }
    
    [device addReadRequest:charateristic];
}

-(void)readCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid {
    CBCharacteristic * characterastic = [self getCharacteristic:uuid suuid:suuid cuuid:cuuid];
    
    if (characterastic == nil) {
        NSLog(@"%@, cannot find special characteristic", TAG);
    }
    
    [self readCharacteristic:uuid characteristic:characterastic];
}

-(void)writeCharacteristic:(NSString *)uuid characteristic:(CBCharacteristic *)charateristic data:(NSData *)data {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return;
    }
    
    [device addWriteRequest:charateristic data:data];
}

-(void)writeCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid data:(NSData *)data {
    CBCharacteristic * characteristic = [self getCharacteristic:uuid suuid:suuid cuuid:cuuid];
    
    if (characteristic == nil) {
        NSLog(@"%@, can't write to special characteristic", TAG);
        return;
    }
    
    [self writeCharacteristic:uuid characteristic:characteristic data:data];
}


/**
 * Enables or disables notification on a give characteristic.
 *
 * @param characteristic
 *            Characteristic to act on.
 * @param enabled
 *            If true, enable notification. False otherwise.
 */
-(void)setCharacteristicNotification:(NSString *)uuid characteristic:(CBCharacteristic *)characteristic enabled:(BOOL)enabled {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return;
    }
    
    [device.peripheral setNotifyValue:enabled forCharacteristic:characteristic];
}

-(void)setCharacteristicNotification:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid enabled:(BOOL)enabled {
    CBCharacteristic * characteristic = [self getCharacteristic:uuid suuid:suuid cuuid:cuuid];
    
    if (characteristic == nil) {
        NSLog(@"%@, cannot find special characteristic", TAG);
        return;
    }
    
    [self setCharacteristicNotification:uuid characteristic:characteristic enabled:enabled];
}

/**
 * Retrieves a list of supported GATT services on the connected device. This
 * should be invoked only after {@code BluetoothGatt#discoverServices()}
 * completes successfully.
 *
 * @return A {@code List} of supported services.
 */
-(NSArray *)getSupportedQWSServices:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return nil;
    }
    
    return [device.peripheral services];
}

-(CBCharacteristic *)getCharacteristic:(NSString *)uuid suuid:(NSString *)suuid cuuid:(NSString *)cuuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return nil;
    }
    
    CBService * service = nil;
    NSArray * services = [device.peripheral services];
    for (CBService * tmp in services) {
        if ([[tmp UUID] isEqual:[CBUUID UUIDWithString:suuid]]) {
            service = tmp;
            break;
        }
    }
    
    if (service == nil) {
        return nil;
    }
    
    CBCharacteristic * characterastic = nil;
    NSArray * characterastics = [service characteristics];
    for (CBCharacteristic * tmp in characterastics) {
        if ([[tmp UUID] isEqual:[CBUUID UUIDWithString:cuuid]]) {
            characterastic = tmp;
            break;
        }
    }
    
    return characterastic == nil ? nil : characterastic;
}

-(BOOL)isBTEnable {
    if (centralManager == nil) {
        return false;
    }
    
    return true;
}

-(BOOL)isBleOpen {
    if (centralManager == nil) {
        return false;
    }
    
    if ([centralManager state] == CBCentralManagerStatePoweredOn) {
        return true;
    }
    
    return false;
}

-(BOOL)isQWSBleService:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return false;
    }
    
    for (CBService * tmp in [self getSupportedQWSServices:uuid]) {
        if ([[tmp UUID] isEqual:[CBUUID UUIDWithString:kDevControllServiceUUIDString]]) {
            return true;
        }
    }
    
    return false;
}

-(int)getDeviceState:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, BluetoothAdapter not initialized", TAG);
        return STATE_INVALID;
    }
    
    return device.mState;
}

-(BOOL)isDeviceServiceDiscoveried:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, Device %@ not initialized", TAG, uuid);
        return false;
    }
    
    return device.isServiceDiscovered;
}

-(BOOL)isDeviceAuthoritied:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, isDeviceAuthoritied() Device %@ not initialized", TAG, uuid);
        return false;
    }
    
    return device.isAuthoritied;
}

-(void)setDeviceAuthoritied:(NSString *)uuid {
    QWSDevControlService * device = [self searchDeviceWithUUID:uuid];
    
    if (device == nil || device.peripheral == nil) {
        NSLog(@"%@, isDeviceAuthoritied() Device %@ not initialized", TAG, uuid);
        return;
    }
    
    device.isAuthoritied = true;
}

@end
