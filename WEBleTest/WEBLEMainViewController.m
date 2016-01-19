//
//  WEBLEMainViewController.m
//  WEBluetooth
//
//  Created by Tilink on 15/7/23.
//  Copyright (c) 2015年 Tilink. All rights reserved.
//

#import "WEBLEMainViewController.h"

#import "QWSBluetooth.h"

@interface WEBLEMainViewController () <UITableViewDataSource, UITableViewDelegate>

@property (strong, nonatomic) QWSDevControlService *currentlyDisplayingService;
@property (strong, nonatomic) NSMutableArray       *connectedServices;
@property (weak, nonatomic) IBOutlet UITableView   *sensorsTable;

@property (strong, nonatomic) NSTimer * distanceTimer;

@end

@implementation WEBLEMainViewController

@synthesize currentlyDisplayingService;
@synthesize connectedServices;
@synthesize sensorsTable;

-(void)dealloc {
    [[QWSDiscovery sharedInstance] stopScanning];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    connectedServices = [NSMutableArray new];
    
    [self.distanceTimer setFireDate:[NSDate distantPast]];
}

#pragma mark - Table view data source
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger	res = 0;
    
    if (section == 0)
        res = [[[QWSDiscovery sharedInstance] foundPeripherals] count];
    else
        res = [[[QWSDiscovery sharedInstance] foundPeripherals] count];
    
    return res;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell	*cell;
    CBPeripheral	*peripheral;
    NSArray			*devices;
    NSInteger		row	= [indexPath row];
    static NSString *cellID = @"DeviceList";
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID];
    
    if ([indexPath section] == 0) {
        devices = [[QWSDiscovery sharedInstance] foundPeripherals];
        peripheral = [(QWSDevControlService*)[devices objectAtIndex:row] peripheral];
        
    } else {
        devices = [[QWSDiscovery sharedInstance] foundPeripherals];
        peripheral = (CBPeripheral*)[devices objectAtIndex:row];
    }
    
    if ([[peripheral name] length])
        [[cell textLabel] setText:[peripheral name]];
    else
        [[cell textLabel] setText:@"Peripheral"];
    
    [[cell detailTextLabel] setText: ([peripheral state] == CBPeripheralStateConnected) ? @"已连接" : @"未连接"];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CBPeripheral	*peripheral;
    NSArray			*devices;
    NSInteger		row	= [indexPath row];
    
    if ([indexPath section] == 0) {
        devices = [[QWSDiscovery sharedInstance] connectedServices];
        peripheral = [(QWSDevControlService*)[devices objectAtIndex:row] peripheral];
    } else {
        devices = [[QWSDiscovery sharedInstance] foundPeripherals];
        peripheral = (CBPeripheral*)[devices objectAtIndex:row];
    }
    
    if ([peripheral state] != CBPeripheralStateConnected) {
        
    }
    
    else {
        
        if ( currentlyDisplayingService != nil ) {
            currentlyDisplayingService = nil;
        }
        
        currentlyDisplayingService = [self serviceForPeripheral:peripheral];
    }
    
    [sensorsTable deselectRowAtIndexPath:indexPath animated:YES];
}

- (QWSDevControlService*) serviceForPeripheral:(CBPeripheral *)peripheral
{
    for (QWSDevControlService *service in connectedServices) {
        if ( [[service peripheral] isEqual:peripheral] ) {
            return service;
        }
    }
    
    return nil;
}

@end
