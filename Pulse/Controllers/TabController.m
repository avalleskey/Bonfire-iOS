//
//  TabController.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/20/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "TabController.h"
#import "Session.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>

@interface TabController () <UITabBarControllerDelegate>

@end

@implementation TabController

- (id)init {
    self = [super init];
    if (self) {
        // setup all the view controllers
        NSMutableArray *vcArray = [[NSMutableArray alloc] init];
        
        self.myFeedNavVC = [self simpleNavWithRootViewController:@"timeline"];
        [vcArray addObject:self.myFeedNavVC];

        self.discoverNavVC = [self searchNavWithRootViewController:@"discover"];
        [vcArray addObject:self.discoverNavVC];
        
        self.myRoomsNavVC = [self simpleNavWithRootViewController:@"rooms"];
        [vcArray addObject:self.myRoomsNavVC];
        
        self.notificationsNavVC = [self simpleNavWithRootViewController:@"notifs"];
        [vcArray addObject:self.notificationsNavVC];
        
        self.myProfileNavVC = [self simpleNavWithRootViewController:@"me"];
        [vcArray addObject:self.myProfileNavVC];
        
        for (NSInteger i = 0; i < [vcArray count]; i++) {
            UINavigationController *navVC = vcArray[i];
            navVC.tabBarItem.title = @"";
            
            if (!IS_IPAD) {
                navVC.tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            }
            [navVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]}
                                            forState:UIControlStateNormal];
            [navVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]}
                                            forState:UIControlStateSelected];
            
            [vcArray replaceObjectAtIndex:i withObject:navVC];
        }
                
        self.viewControllers = vcArray;
        
        NSInteger defaultIndex = 0;
        self.selectedIndex = defaultIndex;
        [self setSelectedViewController:vcArray[defaultIndex]];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userProfileUpdated:) name:@"UserUpdated" object:nil];
    }
    return self;
}

- (void)userProfileUpdated:(NSNotification *)notification {
    self.avatarTabView.user = [Session sharedInstance].currentUser;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UserUpdated" object:nil];
}

- (SearchNavigationController *)searchNavWithRootViewController:(NSString *)rootID {
    SearchNavigationController *searchNav;
    
    if ([rootID isEqualToString:@"discover"]) {
        FeedType type = [rootID isEqualToString:@"discover"] ? FeedTypeTrending : FeedTypeTimeline;
        FeedViewController *viewController = [[FeedViewController alloc] initWithFeedType:type];
        viewController.title = [rootID isEqualToString:@"discover"] ?
        [Session sharedInstance].defaults.home.discoverPageTitle :
        [Session sharedInstance].defaults.home.feedPageTitle;
        
        viewController.tableView.frame = viewController.view.bounds;
        
        searchNav = [[SearchNavigationController alloc] initWithRootViewController:viewController];
    }
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"" image:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-search"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] selectedImage:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-search_selected"]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    searchNav.tabBarItem = tabBarItem;
    
    return searchNav;
}
- (SimpleNavigationController *)simpleNavWithRootViewController:(NSString *)rootID {
    SimpleNavigationController *simpleNav;
    
    if ([rootID isEqualToString:@"timeline"] || [rootID isEqualToString:@"trending"]) {
        FeedType type = [rootID isEqualToString:@"trending"] ? FeedTypeTrending : FeedTypeTimeline;
        FeedViewController *viewController = [[FeedViewController alloc] initWithFeedType:type];
        viewController.title = [rootID isEqualToString:@"trending"] ?
        [Session sharedInstance].defaults.home.discoverPageTitle :
        [Session sharedInstance].defaults.home.feedPageTitle;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeCompose];
        simpleNav.currentTheme = [UIColor clearColor];
        
        viewController.tableView.frame = viewController.view.bounds;
    }
    else if ([rootID isEqualToString:@"rooms"]) {
        MyRoomsViewController *viewController = [[MyRoomsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        // viewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        viewController.title = [Session sharedInstance].defaults.home.myRoomsPageTitle;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        simpleNav.currentTheme = [UIColor clearColor];
        [simpleNav setRightAction:SNActionTypeAdd];
    }
    else if ([rootID isEqualToString:@"notifs"]) {
        NotificationsTableViewController *viewController = [[NotificationsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.title = @"Notifications";
        viewController.view.backgroundColor = [UIColor whiteColor];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        simpleNav.currentTheme = [UIColor clearColor];
    }
    else if ([rootID isEqualToString:@"me"]) {
        User *user = [Session sharedInstance].currentUser;
        
        ProfileViewController *viewController = [[ProfileViewController alloc] init];
        viewController.title = @"My Profile";
        NSString *themeCSS = user.attributes.details.color.length == 6 ? user.attributes.details.color : @"7d8a99";
        viewController.theme = [UIColor fromHex:themeCSS];
        viewController.user = user;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        simpleNav.currentTheme = viewController.theme;
        [simpleNav setLeftAction:SNActionTypeSettings];
        [simpleNav setRightAction:SNActionTypeCompose];
    }
    else {
        UIViewController *viewController = [[UIViewController alloc] init];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
    }
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"" image:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-%@", rootID]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-%@_selected", rootID]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    simpleNav.tabBarItem = tabBarItem;
    
    return simpleNav;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tabIndicator = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 22, 2.5)];
    self.tabIndicator.layer.cornerRadius = self.tabIndicator.frame.size.height / 2;
    self.tabIndicator.backgroundColor = [UIColor bonfireBlack];
    // [self.tabBar addSubview:self.tabIndicator];
    
    [self.tabBar setBackgroundImage:[UIImage new]];
    [self.tabBar setShadowImage:[UIImage new]];
    [self.tabBar setTranslucent:true];
    [self.tabBar setBarTintColor:[UIColor whiteColor]];
    [self.tabBar setTintColor:[UIColor bonfireBlack]];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height + [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom);
    self.blurView.backgroundColor = [UIColor colorWithWhite:1 alpha:1];
    self.blurView.layer.masksToBounds = true;
    [self.tabBar insertSubview:self.blurView atIndex:0];

    // tab bar hairline
    self.tabBar.layer.shadowOffset = CGSizeMake(0, -1 * (1.0 / [UIScreen mainScreen].scale));
    self.tabBar.layer.shadowRadius = 0;
    self.tabBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tabBar.layer.shadowOpacity = 0.12f;
    self.tabBar.layer.masksToBounds = false;
    self.tabBar.tintColor = [UIColor bonfireBlack];
    
    [self setupNotification];
}
- (void)setupNotification {
    self.isShowingNotification = false;
    
    self.notificationContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
    self.notificationContainer.clipsToBounds = true;
    //[self.tabBar addSubview:self.notificationContainer];
    
    self.notification = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    self.notification.frame = CGRectMake(0, 0, self.view.frame.size.width, 52);
    self.notification.backgroundColor = [UIColor colorWithWhite:1 alpha:0.7f];
    [self.notificationContainer insertSubview:self.notification atIndex:0];
    
    self.notificationLabel = [[UILabel alloc] initWithFrame:self.notification.bounds];
    self.notificationLabel.textAlignment = NSTextAlignmentCenter;
    self.notificationLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
    self.notificationLabel.textColor = [UIColor colorWithHue:(240/360) saturation:0.03f brightness:0.25f alpha:1];
    self.notificationLabel.text = @"Submitting verification request...";
    [self.notification.contentView addSubview:self.notificationLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag != 1) {
        self.view.tag = 1;
        [self addUserProfilePicture];
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)setBadgeValue:(NSString *)badgeValue forItem:(UITabBarItem *)tabBarItem {
    NSUInteger index = [self.tabBar.items indexOfObject:tabBarItem];
    UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:index];
        
    UIView *bubbleView = [tabBarItemView viewWithTag:100];
    
    badgeValue = [NSString stringWithFormat:@"%@", badgeValue];
    if (!badgeValue || badgeValue.length == 0 || [badgeValue intValue] == 0) {
        // hide
        if (!bubbleView) return;
        
        [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.5f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            bubbleView.transform = CGAffineTransformMakeScale(0.01, 0.01);
            bubbleView.alpha = 0;
        } completion:^(BOOL finished) {
            [bubbleView removeFromSuperview];
        }];
    }
    else {
        // show
        if (bubbleView) {
            // just change the number
        }
        else {
            // create bubble view
            bubbleView = [[UIView alloc] initWithFrame:CGRectMake(tabBarItemView.frame.size.width / 2 + 7, 7, 12, 12)];
            bubbleView.tag = 100;
            bubbleView.backgroundColor = [UIColor whiteColor];
            bubbleView.layer.cornerRadius = bubbleView.frame.size.width / 2;
            
            UIView *bubbleViewDot = [[UIView alloc] initWithFrame:CGRectMake(2, 2, bubbleView.frame.size.width - 4, bubbleView.frame.size.height - 4)];
            bubbleViewDot.backgroundColor = [UIColor bonfireBrand];
            bubbleViewDot.layer.cornerRadius = bubbleViewDot.frame.size.width / 2;
            [bubbleView addSubview:bubbleViewDot];
            
            [tabBarItemView addSubview:bubbleView];
            
            // prepare for animations
            bubbleView.transform = CGAffineTransformMakeScale(0.01, 0.01);
            bubbleView.alpha = 0;
            
            [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubbleView.transform = CGAffineTransformMakeScale(1, 1);
                bubbleView.alpha = 1;
            } completion:nil];
        }
    }
}

- (void)addUserProfilePicture {
    UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:[self.tabBar.items count]-1];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
    
    self.avatarTabView = [[BFAvatarView alloc] initWithFrame:CGRectMake(0, 0, tabBarImageView.frame.size.width - 6, tabBarImageView.frame.size.height - 6)];
    self.avatarTabView.center = CGPointMake(tabBarImageView.frame.size.width / 2, tabBarImageView.frame.size.height / 2);
    self.avatarTabView.user = [Session sharedInstance].currentUser;
    [tabBarImageView addSubview:self.avatarTabView];
}
- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    
    if (item == tabBar.selectedItem) {
        [HapticHelper generateFeedback:FeedbackType_Impact_Light];
    }
    else {
        [HapticHelper generateFeedback:FeedbackType_Selection];
    }
    
    UIView *tabBarItemView = [self viewForTabInTabBar:tabBar withIndex:index];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
    
    [UIView animateWithDuration:0.185f delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);

        tabBarImageView.transform = CGAffineTransformMakeScale(1, 1);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.6 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            tabBarImageView.transform = CGAffineTransformIdentity;
        } completion:nil];
    }];
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIView *)viewForTabInTabBar:(UITabBar* )tabBar withIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[tabBar.items count]];
    for (UIView *view in tabBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects that don't implement -frame can be subViews of an UIView
            [tabBarItems addObject:view];
        }
    }
    if ([tabBarItems count] == 0) {
        // no tabBarItems means either no UITabBarButtons were in the subView, or none responded to -frame
        // return CGRectZero to indicate that we couldn't figure out the frame
        return nil;
    }
    
    // sort by origin.x of the frame because the items are not necessarily in the correct order
    [tabBarItems sortUsingComparator:^NSComparisonResult(UIView *view1, UIView *view2) {
        if (view1.frame.origin.x < view2.frame.origin.x) {
            return NSOrderedAscending;
        }
        if (view1.frame.origin.x > view2.frame.origin.x) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    UIView *retVal = nil;
    if (index < [tabBarItems count]) {
        // viewController is in a regular tab
        UIView *tabView = tabBarItems[index];
        if ([tabView respondsToSelector:@selector(frame)]) {
            retVal = tabView;
        }
    }
    else {
        // our target viewController is inside the "more" tab
        UIView *tabView = [tabBarItems lastObject];
        if ([tabView respondsToSelector:@selector(frame)]) {
            retVal = tabView;
        }
    }
    return retVal;
}

- (void)showNotificationWithText:(NSString *)text {
    if (!self.isShowingNotification) {
        self.isShowingNotification = true;
        [UIView animateWithDuration:0.25f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.notificationContainer.frame = CGRectMake(self.notificationContainer.frame.origin.x, -1 * self.notification.frame.size.height, self.notificationContainer.frame.size.width, self.notification.frame.size.height);
        } completion:nil];
    }
}
- (void)dismissNotificationWithText:(NSString *)textBeforeDismissing {
    if (self.isShowingNotification) {
        float delay = 0;
        if (textBeforeDismissing.length > 0) {
            delay = 1.2f;
            
            self.notificationLabel.text = textBeforeDismissing;
        }
        
        [UIView animateWithDuration:0.25f delay:delay options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.notificationContainer.frame = CGRectMake(self.notificationContainer.frame.origin.x, 0, self.notificationContainer.frame.size.width, 0);
        } completion:nil];
    }
}

@end
