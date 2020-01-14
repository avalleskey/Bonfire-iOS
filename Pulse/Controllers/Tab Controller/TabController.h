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
#import "ComplexNavigationController.h"
#import "SearchTableViewController.h"
#import "CampStoreTableViewController.h"
#import "HomeTableViewController.h"
#import "CombinedHomeViewController.h"
#import "ProfileViewController.h"
#import "NotificationsTableViewController.h"
#import "BFAvatarView.h"

@interface TabController : UITabBarController

@property (nonatomic, strong) SimpleNavigationController *myFeedNavVC;
@property (nonatomic, strong) SimpleNavigationController *homeNavVC;

@property (nonatomic, strong) SearchNavigationController *searchNavVC;
@property (nonatomic, strong) SimpleNavigationController *discoverNavVC;
@property (nonatomic, strong) SimpleNavigationController *storeNavVC;
@property (nonatomic, strong) SimpleNavigationController *notificationsNavVC;
@property (nonatomic, strong) SimpleNavigationController *myProfileNavVC;

@property (nonatomic, strong) BFAvatarView *navigationAvatarView;

@property (nonatomic, strong) UIView *tabIndicator;
//@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *tabBackgroundView;

- (void)setBadgeValue:(NSString *)badgeValue forItem:(UITabBarItem *)tabBarItem;
@property (nonatomic, strong) NSMutableDictionary *badges;

@property (nonatomic, strong) NSMutableDictionary *pills;

- (void)showPillIfNeeded;

@end
