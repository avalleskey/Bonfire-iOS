//
//  TabController.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/20/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "TabController.h"
#import "Session.h"
#import <BlocksKit+UIKit.h>
#import <Tweaks/FBTweakInline.h>
#import "UIColor+Palette.h"

#define IS_IPHONE        (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPHONE_5 ([[UIScreen mainScreen] bounds].size.height == 568.0)
#define IS_IPHONE_X (IS_IPHONE && [[UIScreen mainScreen] bounds].size.height == 812.0)
#define IS_TINY ([[UIScreen mainScreen] bounds].size.height == 480)

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
        
        self.trendingNavVC = [self simpleNavWithRootViewController:@"trending"];
        // [vcArray addObject:self.myFeedNavVC];

        self.searchNavVC = [self searchNavWithRootViewController:@"search"];
        [vcArray addObject:self.searchNavVC];
        
        self.myRoomsNavVC = [self simpleNavWithRootViewController:@"rooms"];
        [vcArray addObject:self.myRoomsNavVC];
        
        self.notificationsNavVC = [self simpleNavWithRootViewController:@"notifs"];
        [vcArray addObject:self.notificationsNavVC];
        
        self.myProfileNavVC = [self simpleNavWithRootViewController:@"me"];
        [vcArray addObject:self.myProfileNavVC];
        
        for (int i = 0; i < [vcArray count]; i++) {
            UINavigationController *navVC = vcArray[i];
            navVC.tabBarItem.title = @"";
            
            navVC.tabBarItem.imageInsets = UIEdgeInsetsMake(5, 0, -5, 0);
            [navVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]}
                                            forState:UIControlStateNormal];
            [navVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]}
                                            forState:UIControlStateHighlighted];
            
            [vcArray replaceObjectAtIndex:i withObject:navVC];
        }
                
        self.viewControllers = vcArray;
        
        NSInteger defaultIndex = 2;
        self.selectedIndex = defaultIndex;
        [self setSelectedViewController:vcArray[defaultIndex]];
    }
    return self;
}
- (SearchNavigationController *)searchNavWithRootViewController:(NSString *)rootID {
    SearchNavigationController *searchNav;
    
    if ([rootID isEqualToString:@"search"]) {
        SearchTableViewController *viewController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        
        searchNav = [[SearchNavigationController alloc] initWithRootViewController:viewController];
    }
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"" image:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-%@", rootID]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] selectedImage:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-%@_selected", rootID]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
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
        
        viewController.tableView.frame = viewController.view.bounds;
    }
    else if ([rootID isEqualToString:@"rooms"]) {
        MyRoomsViewController *viewController = [[MyRoomsViewController alloc] initWithStyle:UITableViewStyleGrouped];
        // viewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        viewController.title = [Session sharedInstance].defaults.home.myRoomsPageTitle;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setRightAction:SNActionTypeAdd];
    }
    else if ([rootID isEqualToString:@"notifs"]) {
        NotificationsTableViewController *viewController = [[NotificationsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.title = @"Notifications";
        viewController.view.backgroundColor = [UIColor whiteColor];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
    }
    else if ([rootID isEqualToString:@"me"]) {
        User *user = [Session sharedInstance].currentUser;
        
        ProfileViewController *viewController = [[ProfileViewController alloc] init];
        viewController.title = @"My Profile";
        NSString *themeCSS = user.attributes.details.color.length == 6 ? user.attributes.details.color : (user.identifier ? @"0076ff" : @"707479");
        viewController.theme = [UIColor fromHex:themeCSS];
        viewController.user = user;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeMore];
        simpleNav.currentTheme = viewController.theme;
    }
    else {
        UIViewController *viewController = [[UIViewController alloc] init];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
    }
    
    UITabBarItem *tabBarItem = [[UITabBarItem alloc] initWithTitle:@"" image:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-%@", rootID]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] selectedImage:[[UIImage imageNamed:[NSString stringWithFormat:@"tabIcon-%@_selected", rootID]] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
    simpleNav.tabBarItem = tabBarItem;
    
    return simpleNav;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.tabIndicator = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 22, 2)];
    self.tabIndicator.layer.cornerRadius = self.tabIndicator.frame.size.height / 2;
    self.tabIndicator.backgroundColor = [Session sharedInstance].themeColor;
    //[self.tabBar addSubview:self.tabIndicator];
    
    [self.tabBar setBackgroundImage:[UIImage new]];
    [self.tabBar setShadowImage:[UIImage new]];
    [self.tabBar setTranslucent:true];
    [self.tabBar setBarTintColor:[UIColor whiteColor]];
    [self.tabBar setTintColor:[Session sharedInstance].themeColor];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height * 2);
    self.blurView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.85f];
    self.blurView.layer.masksToBounds = true;
    [self.tabBar insertSubview:self.blurView atIndex:0];

    self.tabBar.layer.shadowOffset = CGSizeMake(0, -1 * (1.0 / [UIScreen mainScreen].scale));
    self.tabBar.layer.shadowRadius = 0;
    self.tabBar.layer.shadowColor = [UIColor blackColor].CGColor;
    self.tabBar.layer.shadowOpacity = 0.12f;
    self.tabBar.layer.masksToBounds = false;
    
    [self setupNotification];
    [self updateTintColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
}
- (void)setupNotification {
    self.isShowingNotification = false;
    
    self.notificationContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 0)];
    self.notificationContainer.clipsToBounds = true;
    [self.tabBar addSubview:self.notificationContainer];
    
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
- (void)userUpdated:(NSNotification *)notification {
    [self updateTintColor];
}
- (void)updateTintColor {
    if (FBTweakValue(@"Home", @"Tab Bar", @"Uses Theme", YES)) {
        self.tabBar.tintColor = [Session sharedInstance].themeColor;
    }
    else {
        NSLog(@"does not use theme");
        self.tabBar.tintColor = [UIColor colorWithWhite:0.07f alpha:1];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self addTabBarPressEffects];
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
}

- (void)addTabBarPressEffects {
    for (int i = 0; i < self.viewControllers.count; i++) {
        UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:i];
        tabBarItemView.userInteractionEnabled = true;
        
        UILongPressGestureRecognizer *pressRecognizer = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
            if (FBTweakValue(@"Home", @"Tab Bar", @"Pop Effect", YES)) {
                if (state == UIGestureRecognizerStateBegan) {
                    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:1.f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                        sender.view.transform = CGAffineTransformMakeScale(0.8, 0.8);
                    } completion:^(BOOL finished) {
                    }];
                }
                if (state == UIGestureRecognizerStateEnded || state == UIGestureRecognizerStateCancelled) {
                    [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:1.f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                        sender.view.transform = CGAffineTransformIdentity;
                    } completion:^(BOOL finished) {
                    }];
                }
                
                if (state == UIGestureRecognizerStateEnded) {
                    if (self.selectedIndex != i) {
                        self.selectedIndex = i;
                        [self setSelectedViewController:self.viewControllers[i]];
                    }
                    [self.delegate tabBarController:self didSelectViewController:self.selectedViewController];
                }
            }
        }];
        pressRecognizer.minimumPressDuration = CGFLOAT_MIN;
        
        [tabBarItemView addGestureRecognizer:pressRecognizer];
    }
    
//    self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);
//    self.tabIndicator.center = CGPointMake(tabBarItemView.center.x, self.tabIndicator.center.y);
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    
    UIView *tabBarItemView = [self viewForTabInTabBar:tabBar withIndex:index];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
    
    [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x + (tabBarImageView.frame.size.width / 4), self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width / 2, self.tabIndicator.frame.size.height);
    } completion:nil];
    
    /*
    if (FBTweakValue(@"Home", @"Tab Bar", @"Pop Effect", YES)) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:1.f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            tabBarImageView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
        }];
        [UIView animateWithDuration:0.4f delay:0.25f usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            tabBarImageView.transform = CGAffineTransformIdentity;
            self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);
        } completion:^(BOOL finished) {
        }];
    }*/
    
    [self setNeedsStatusBarAppearanceUpdate];
}

- (UIView *)viewForTabInTabBar:(UITabBar* )tabBar withIndex:(NSUInteger)index
{
    NSMutableArray *tabBarItems = [NSMutableArray arrayWithCapacity:[tabBar.items count]];
    for (UIView *view in tabBar.subviews) {
        if ([view isKindOfClass:NSClassFromString(@"UITabBarButton")] && [view respondsToSelector:@selector(frame)]) {
            // check for the selector -frame to prevent crashes in the very unlikely case that in the future
            // objects thar don't implement -frame can be subViews of an UIView
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

- (void)openView:(NSString *)view options:(NSDictionary *)options {
    if ([view isEqualToString:@"report_problem"]) {
        
    }
    else if ([view isEqualToString:@"create_post"]) {
        
    }
    else if ([view isEqualToString:@"bells_settings"]) {
        
    }
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
