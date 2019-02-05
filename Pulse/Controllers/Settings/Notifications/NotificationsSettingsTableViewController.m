//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsSettingsTableViewController.h"

@interface NotificationsSettingsTableViewController ()

@end

@implementation NotificationsSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
}

- (void)setup {
    self.title = @"Notifications";
    self.smartListDelegate = self;
    
    [self setJsonFile:@"Notifications"];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@""]) {
        
    }
}

@end
