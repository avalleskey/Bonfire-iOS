//
//  NotificationsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "NotificationsSettingsTableViewController.h"

@import Firebase;

@interface NotificationsSettingsTableViewController ()

@end

@implementation NotificationsSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Settings / Notifications" screenClass:nil];
}

- (void)setup {
    self.title = @"Notifications";
    self.smartListDelegate = self;
    
    [self setJsonFile:@"Notifications"];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    NSArray *comingSoonList = @[@"new_followers_off", @"post_replies_off", @"post_votes_off", @"camp_trending_off", @"new_camp_members_off", @"camp_member_requests_off"];
    if ([comingSoonList containsObject:rowId]) {
        UIAlertController *comingSoon = [UIAlertController alertControllerWithTitle:@"Feature Coming Soon" message:@"We apologize for the inconvenience! The ability to turn off post notifications will be added in a future release." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *close = [UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [comingSoon dismissViewControllerAnimated:YES completion:nil];
        }];
        [comingSoon addAction:close];
        
        [self.navigationController presentViewController:comingSoon animated:YES completion:nil];
    }
}

@end
