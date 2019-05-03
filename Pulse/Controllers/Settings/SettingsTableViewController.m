//
//  SettingsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Legal/LegalTableViewController.h"
#import "Notifications/NotificationsSettingsTableViewController.h"
#import "Change Password/ChangePasswordTableViewController.h"

#import <JGProgressHUD/JGProgressHUD.h>
#import <HapticHelper/HapticHelper.h>

@import Firebase;

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self setup];
    
    // Google Analytics
    [FIRAnalytics setScreenName:@"Settings" screenClass:nil];
}

- (void)setup {
    self.title = @"Settings";
    self.navigationController.navigationBar.prefersLargeTitles = true;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.smartListDelegate = self;
    
    [self setJsonFile:@"SettingsModel"];
    
    // remove bonfire beta section if release
    if ([Configuration isRelease] && self.list) {
        NSMutableArray <SmartListSection> *sections = [[NSMutableArray<SmartListSection> alloc] initWithArray:self.list.sections];
        for (NSInteger i = sections.count - 1; i >= 0; i--) {
            SmartListSection *section = sections[i];
            if ([section.identifier isEqualToString:@"bonfire_beta"]) {
                [sections removeObject:section];
            }
        }
        self.list.sections = sections;
        [self.tableView reloadData];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@"edit_profile"]) {
        [[Launcher sharedInstance] openEditProfile];
    }
    if ([rowId isEqualToString:@"change_password"]) {
        // push change password
        ChangePasswordTableViewController *changePasswordTableVC = [[ChangePasswordTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[Launcher sharedInstance] push:changePasswordTableVC animated:YES];
    }
    if ([rowId isEqualToString:@"notifications"]) {
        // push notifications settings
        NotificationsSettingsTableViewController *notificationsTableVC = [[NotificationsSettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[Launcher sharedInstance] push:notificationsTableVC animated:YES];
    }
    if ([rowId isEqualToString:@"get_help"]) {
        Room *room = [[Room alloc] init];
        room.identifier = @"-Rd3XgvQN0zQj";
        [[Launcher sharedInstance] openRoom:room];
    }
    if ([rowId isEqualToString:@"give_feedback"]) {
        Room *room = [[Room alloc] init];
        room.identifier = @"-YPQ10Pr62xZl";
        [[Launcher sharedInstance] openRoom:room];
    }
    if ([rowId isEqualToString:@"rate_app_store"]) {
        [[Launcher sharedInstance] requestAppStoreRating];
    }
    if ([rowId isEqualToString:@"community_guidelines"]) {
        // push community guidelines
        [[Launcher sharedInstance] openURL:@"https://bonfire.camp/community"];
    }
    if ([rowId isEqualToString:@"legal"]) {
        // push legal
        LegalTableViewController *legalTableVC = [[LegalTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        [[Launcher sharedInstance] push:legalTableVC animated:YES];
    }
    if ([rowId isEqualToString:@"sign_out"]) {
        // sign out
        UIAlertController *areYouSure = [UIAlertController alertControllerWithTitle:@"Sign Out?" message:@"Please confirm you would like to sign out" preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [areYouSure dismissViewControllerAnimated:YES completion:nil];
        }];
        [areYouSure addAction:cancel];
        
        UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Sign Out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [[Session sharedInstance] signOut];
            
            [[Launcher sharedInstance] openOnboarding];
        }];
        [areYouSure addAction:confirm];
        
        [self.navigationController presentViewController:areYouSure animated:YES completion:nil];
    }
    if ([rowId isEqualToString:@"invite_friends_beta"]) {
        [FIRAnalytics logEventWithName:@"copy_beta_invite_link"
                            parameters:@{@"location": @"settings"}];
        
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = @"http://testflight.com/bonfire-ios";
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.textLabel.text = @"Copied Beta Link!";
        HUD.vibrancyEnabled = false;
        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        HUD.indicatorView.tintColor = HUD.textLabel.textColor;
        
        [HUD showInView:self.navigationController.view animated:YES];
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        [HUD dismissAfterDelay:1.5f];
    }
    if ([rowId isEqualToString:@"report_bug"]) {
        Room *room = [[Room alloc] init];
        room.identifier = @"-Rd3XgvQN0zQj";
        [[Launcher sharedInstance] openRoom:room];
    }
}

@end
