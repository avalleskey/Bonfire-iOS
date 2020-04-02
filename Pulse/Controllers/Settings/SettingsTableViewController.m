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
        [Launcher openEditProfile];
    }
    if ([rowId isEqualToString:@"change_password"]) {
//        // push change password
        ChangePasswordTableViewController *changePasswordTableVC = [[ChangePasswordTableViewController alloc] init];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:changePasswordTableVC];
        [simpleNav setLeftAction:SNActionTypeBack];
        
        [Launcher push:simpleNav animated:YES];
    }
    if ([rowId isEqualToString:@"share_profile"]) {
        [Launcher shareCurrentUser];
    }
    if ([rowId isEqualToString:@"notifications"]) {
        // push notifications settings
        NotificationsSettingsTableViewController *notificationsTableVC = [[NotificationsSettingsTableViewController alloc] init];
        [Launcher push:notificationsTableVC animated:YES];
    }
    if ([rowId isEqualToString:@"get_help"]) {
        Camp *camp = [[Camp alloc] init];
        camp.identifier = @"-5Orj2GW2ywG3";
        camp.attributes = [[CampAttributes alloc] initWithDictionary:@{@"identifier": @"BonfireSupport", @"title": @"Bonfire Support"} error:nil];
        [Launcher openCamp:camp];
    }
    if ([rowId isEqualToString:@"give_feedback"]) {
        Camp *camp = [[Camp alloc] init];
        camp.identifier = @"-mb4egjBg9vYK";
        camp.attributes = [[CampAttributes alloc] initWithDictionary:@{@"identifier": @"BonfireFeedback", @"title": @"Bonfire Feedback"} error:nil];
        [Launcher openCamp:camp];
    }
    if ([rowId isEqualToString:@"rate_app_store"]) {
        [Launcher requestAppStoreRating];
    }
    if ([rowId isEqualToString:@"community_guidelines"]) {
        // push community guidelines
        [Launcher openURL:@"https://bonfire.camp/community"];
    }
    if ([rowId isEqualToString:@"legal"]) {
        // push legal
        LegalTableViewController *legalTableVC = [[LegalTableViewController alloc] init];
        SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:legalTableVC];
        [simpleNav setLeftAction:SNActionTypeBack];
        
        [Launcher push:simpleNav animated:YES];
    }
    if ([rowId isEqualToString:@"sign_out"]) {
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
        
        [self.navigationController presentViewController:areYouSure animated:true completion:nil];
    }
    if ([rowId isEqualToString:@"invite_friends_beta"]) {
        [Launcher copyBetaInviteLink];
    }
    if ([rowId isEqualToString:@"report_bug"]) {
        Camp *camp = [[Camp alloc] init];
        camp.identifier = @"-wWoxVq1VBA6R";
        [Launcher openCamp:camp];
    }
}

- (UIView *)alternativeViewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        BFIdentityAttachmentView *attachmentView = [[BFIdentityAttachmentView alloc] initWithIdentity:[Session sharedInstance].currentUser frame:CGRectMake(0, 0, self.view.frame.size.width, 100)];
        attachmentView.backgroundColor = [UIColor contentBackgroundColor];
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
