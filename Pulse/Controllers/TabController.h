//
//  TabController.h
//  Hallway App
//
//  Created by Austin Valleskey on 8/20/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchNavigationController.h"
#import "SimpleNavigationController.h"
#import "SearchTableViewController.h"
#import "MyRoomsViewController.h"
#import "FeedViewController.h"
#import "ProfileViewController.h"
#import "NotificationsTableViewController.h"
#import "BFAvatarView.h"

@interface TabController : UITabBarController

@property (nonatomic, strong) SimpleNavigationController *myFeedNavVC;
@property (nonatomic, strong) SearchNavigationController *discoverNavVC;
@property (nonatomic, strong) SimpleNavigationController *myRoomsNavVC;
@property (nonatomic, strong) SimpleNavigationController *notificationsNavVC;
@property (nonatomic, strong) SimpleNavigationController *myProfileNavVC;

@property (nonatomic, strong) BFAvatarView *avatarTabView;

@property (nonatomic, strong) UIView *notificationContainer;
@property (nonatomic, strong) UIVisualEffectView *notification;
@property (nonatomic, strong) UILabel *notificationLabel;
@property (nonatomic, strong) UIView *tabIndicator;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic) BOOL isShowingNotification;

- (void)dismissNotificationWithText:(NSString *)textBeforeDismissing;
- (void)showNotificationWithText:(NSString *)text;

- (void)setBadgeValue:(NSString *)badgeValue forItem:(UITabBarItem *)tabBarItem;

@end
