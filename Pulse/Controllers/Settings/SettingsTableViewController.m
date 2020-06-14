//
//  SettingsTableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 12/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "Legal/LegalTableViewController.h"
#import "App Icon/AppIconTableViewController.h"
#import "Notifications/NotificationsSettingsTableViewController.h"
#import "ChangePasswordTableViewController.h"
#import "BFAlertController.h"

#import "BFIdentityAttachmentView.h"
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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
}

- (void)userUpdated:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setup {
    self.title = @"Settings";
    //self.navigationController.navigationBar.prefersLargeTitles = true;
    //self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAutomatic;
    self.smartListDelegate = self;
    
    [self setJsonFile:@"SettingsModel"];
    
    NSMutableArray <SmartListSection> *sections = [[NSMutableArray<SmartListSection> alloc] initWithArray:self.list.sections];
    
    // remove bonfire beta section if release
    if ([Configuration isRelease] && self.list) {
        for (NSInteger i = sections.count - 1; i >= 0; i--) {
            SmartListSection *section = sections[i];
            if ([section.identifier isEqualToString:@"bonfire_beta"]) {
                [sections removeObject:section];
            }
        }
    }
    // remove "Change Password" if they signed up with phone #
    if ([Session sharedInstance].currentUser.attributes.email.length == 0) {
        for (NSInteger i = sections.count - 1; i >= 0; i--) {
            SmartListSection *section = sections[i];

            if ([section.identifier isEqualToString:@"my_account"]) {
                NSMutableArray<SmartListSectionRow *><SmartListSectionRow> *rows = [[NSMutableArray<SmartListSectionRow *><SmartListSectionRow> alloc] initWithArray:section.rows];
                
                if (!rows) continue;
                
                for (NSInteger r = rows.count - 1; r >= 0; r--) {
                    SmartListSectionRow *row = rows[r];
                    if ([row.identifier isEqualToString:@"change_password"]) {
                        [rows removeObject:row];
                    }
                }
                
                section.rows = rows;
            }
        }
    }
    
    self.list.sections = sections;
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didSelectRowWithId:(NSString *)rowId {
    if ([rowId isEqualToString:@"edit_profile"]) {
        [Launcher openEditProfile];
    }
    else if ([rowId isEqualToString:@"app_icon"]) {
        // push notifications settings
        AppIconTableViewController *appIconTableVC = [[AppIconTableViewController alloc] init];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:appIconTableVC];
        [simpleNav setLeftAction:SNActionTypeBack];
        
        [Launcher push:simpleNav animated:YES];
    }
    else if ([rowId isEqualToString:@"change_password"]) {
//        // push change password
        ChangePasswordTableViewController *changePasswordTableVC = [[ChangePasswordTableViewController alloc] init];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:changePasswordTableVC];
        [simpleNav setLeftAction:SNActionTypeBack];
        
        [Launcher push:simpleNav animated:YES];
    }
    else if ([rowId isEqualToString:@"share_profile"]) {
        [Launcher shareCurrentUser];
    }
    else if ([rowId isEqualToString:@"Activity"]) {
        // push notifications settings
        NotificationsSettingsTableViewController *notificationsTableVC = [[NotificationsSettingsTableViewController alloc] init];
        [Launcher push:notificationsTableVC animated:YES];
    }
    else if ([rowId isEqualToString:@"get_help"]) {
        Camp *camp = [[Camp alloc] init];
        camp.identifier = @"-5Orj2GW2ywG3";
        camp.attributes = [[CampAttributes alloc] initWithDictionary:@{@"identifier": @"BonfireSupport", @"title": @"Bonfire Support"} error:nil];
        [Launcher openCamp:camp];
    }
    else if ([rowId isEqualToString:@"give_feedback"]) {
        Camp *camp = [[Camp alloc] init];
        camp.identifier = @"-mb4egjBg9vYK";
        camp.attributes = [[CampAttributes alloc] initWithDictionary:@{@"identifier": @"BonfireFeedback", @"title": @"Bonfire Feedback"} error:nil];
        [Launcher openCamp:camp];
    }
    else if ([rowId isEqualToString:@"rate_app_store"]) {
        [Launcher requestAppStoreRating];
    }
    else if ([rowId isEqualToString:@"community_guidelines"]) {
        // push community guidelines
        [Launcher openURL:@"https://bonfire.camp/legal/community"];
    }
    else if ([rowId isEqualToString:@"legal"]) {
        // push legal
        LegalTableViewController *legalTableVC = [[LegalTableViewController alloc] init];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:legalTableVC];
        [simpleNav setLeftAction:SNActionTypeBack];
        
        [Launcher push:simpleNav animated:YES];
    }
    else if ([rowId isEqualToString:@"sign_out"]) {
        // sign out
        BFAlertController *areYouSure = [BFAlertController alertControllerWithTitle:@"Sign Out?" message:@"Please confirm you would like to sign out" preferredStyle:BFAlertControllerStyleAlert];
        
        BFAlertAction *confirm = [BFAlertAction actionWithTitle:@"Sign Out" style:BFAlertActionStyleDestructive handler:^{
            JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
            HUD.textLabel.text = @"Signing out...";
            HUD.vibrancyEnabled = false;
            HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
            HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
            HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
            HUD.indicatorView = [[JGProgressHUDIndeterminateIndicatorView alloc] init];
            HUD.indicatorView.tintColor = HUD.textLabel.textColor;
            
            [HUD showInView:self.navigationController.view animated:YES];
            
            [[Session sharedInstance] signOut];
        }];
        [areYouSure addAction:confirm];
        
        BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
        [areYouSure addAction:cancel];
        
        [areYouSure show];
    }
    else if ([rowId isEqualToString:@"invite_friends_beta"]) {
        [Launcher copyBetaInviteLink];
    }
    else if ([rowId isEqualToString:@"report_bug"]) {
        Camp *camp = [[Camp alloc] initWithDictionary:@{@"id": @"-wWoxVq1VBA6R", @"attributes": @{@"identifier": @"BonfireBugs", @"title": @"Bonfire Bugs"}} error:nil];
        [Launcher openCamp:camp];
    }
}

- (UIView *)alternativeViewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        BFIdentityAttachmentView *attachmentView = [[BFIdentityAttachmentView alloc] initWithIdentity:[Session sharedInstance].currentUser frame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
        attachmentView.backgroundColor = [UIColor clearColor];
        attachmentView.userInteractionEnabled = false;
        attachmentView.layer.cornerRadius = 0;
        attachmentView.contentView.layer.cornerRadius = 0;
        attachmentView.contentView.layer.borderWidth = 0;
        attachmentView.headerBackdrop.hidden = true;
        attachmentView.showBio = false;
        attachmentView.showDetails = false;
        attachmentView.layer.masksToBounds = false;
        
        UIView *hairline = [[UIView alloc] initWithFrame:CGRectMake(0, -HALF_PIXEL, attachmentView.frame.size.width, HALF_PIXEL)];
        hairline.backgroundColor = [UIColor tableViewSeparatorColor];
        [attachmentView addSubview:hairline];
        
        return attachmentView;
    }
    
    return nil;
}
- (CGFloat)alternativeHeightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [BFIdentityAttachmentView heightForIdentity:[Session sharedInstance].currentUser width:self.view.frame.size.width showBio:false showDetails:false];
    }
    
    return 0;
}

@end
