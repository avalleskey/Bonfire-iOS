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
#import "Launcher.h"
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

        self.searchNavVC = [self searchNavWithRootViewController:@"search"];
        //[vcArray addObject:self.searchNavVC];
        
        self.discoverNavVC = [self simpleNavWithRootViewController:@"discover"];
        [vcArray addObject:self.discoverNavVC];
        
        self.notificationsNavVC = [self simpleNavWithRootViewController:@"notifs"];
        [vcArray addObject:self.notificationsNavVC];
        
        self.myProfileNavVC = [self simpleNavWithRootViewController:@"me"];
        //[vcArray addObject:self.myProfileNavVC];
        
        for (NSInteger i = 0; i < [vcArray count]; i++) {
            UINavigationController *navVC = vcArray[i];
            navVC.tabBarItem.title = @"";
            
            if (!IS_IPAD && SYSTEM_VERSION_LESS_THAN(@"13")) {
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
        
        [self.tabBar.items objectAtIndex:0].titlePositionAdjustment = UIOffsetMake(([UIScreen mainScreen].bounds.size.width / 12), 0.0);
        [self.tabBar.items objectAtIndex:1].titlePositionAdjustment = UIOffsetMake(0, 0.0);
        [self.tabBar.items objectAtIndex:2].titlePositionAdjustment = UIOffsetMake(-([UIScreen mainScreen].bounds.size.width / 12), 0.0);
        //[self.tabBar.items objectAtIndex:3].titlePositionAdjustment = UIOffsetMake(-12, 0.0);
        
        self.pills = [[NSMutableDictionary alloc] init];
        [self addPillToController:self.discoverNavVC title:@"Create Camp" image:[[UIImage imageNamed:@"navPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
            [Launcher openCreateCamp];
        }];
        
        self.tabBar.tintColor = [UIColor bonfireBlack];
    }
    return self;
}

- (SearchNavigationController *)searchNavWithRootViewController:(NSString *)rootID {
    SearchNavigationController *searchNav;
    
    if ([rootID isEqualToString:@"search"]) {
        SearchTableViewController *viewController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.title = [rootID isEqualToString:@"search"] ?
        @"" : [Session sharedInstance].defaults.keywords.viewTitles.userStream;
        
        viewController.tableView.frame = viewController.view.bounds;
        
        searchNav = [[SearchNavigationController alloc] initWithRootViewController:viewController];
        searchNav.searchView.openSearchControllerOntap = false;
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
        @"" : [Session sharedInstance].defaults.keywords.viewTitles.userStream;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeCompose];
        simpleNav.currentTheme = [UIColor clearColor];
        
        viewController.tableView.frame = viewController.view.bounds;
    }
    else if ([rootID isEqualToString:@"discover"]) {
        DiscoverViewController *viewController = [[DiscoverViewController alloc] initWithStyle:UITableViewStyleGrouped];
        // viewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.discover;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        simpleNav.currentTheme = [UIColor clearColor];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeSearch];
    }
    else if ([rootID isEqualToString:@"notifs"]) {
        NotificationsTableViewController *viewController = [[NotificationsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.notifications;
        [viewController view];
        
        NSLog(@"view controller table view :: %@", viewController.tableView);
        [viewController.tableView reloadData];
        viewController.view.backgroundColor = [UIColor whiteColor];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeInvite];
        simpleNav.currentTheme = [UIColor clearColor];
    }
    else if ([rootID isEqualToString:@"me"]) {
        User *user = [Session sharedInstance].currentUser;
        
        ProfileViewController *viewController = [[ProfileViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.myProfile;
        NSString *themeCSS = user.attributes.details.color.length == 6 ? user.attributes.details.color : @"7d8a99";
        viewController.theme = [UIColor fromHex:themeCSS];
        viewController.user = user;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        simpleNav.currentTheme = viewController.theme;
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
    [self.tabBar setTintColor:[UIColor bonfireBrand]];
    
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleLight]];
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height + [UIApplication sharedApplication].delegate.window.safeAreaInsets.bottom);
    self.blurView.backgroundColor = [UIColor colorWithWhite:1 alpha:0.6];
    self.blurView.layer.masksToBounds = true;
    [self.tabBar insertSubview:self.blurView atIndex:0];

    // tab bar hairline
    self.tabBar.layer.borderWidth = 0;
    self.tabBar.clipsToBounds = true;
    self.tabBar.tintColor = [UIColor bonfireBlack];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.view.tag != 1) {
        self.view.tag = 1;
    }
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
        [self setBadgeValue:[NSString stringWithFormat:@"%ld", (long)[UIApplication sharedApplication].applicationIconBadgeNumber] forItem:self.notificationsNavVC.tabBarItem];
    }
}

- (void)setBadgeValue:(NSString *)badgeValue forItem:(UITabBarItem *)tabBarItem {
    badgeValue = [NSString stringWithFormat:@"%@", badgeValue];
    
    NSUInteger index = [self.tabBar.items indexOfObject:tabBarItem];
    
    UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:index];
    
    UIView *bubbleView = [tabBarItemView viewWithTag:100];
    
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
        if (index == self.selectedIndex) {
            if ([self.selectedViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)self.selectedViewController visibleViewController] isKindOfClass:[NotificationsTableViewController class]]) {
                return;
            }
        }
        
        // show
        if (bubbleView) {
            // just change the number
        }
        else {
            // create bubble view
            bubbleView = [[UIView alloc] initWithFrame:CGRectMake(tabBarItemView.frame.size.width / 2 + 7 + tabBarItem.titlePositionAdjustment.horizontal, 6, 10, 10)];
            bubbleView.tag = 100;
            //bubbleView.backgroundColor = [UIColor whiteColor];
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

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    
    if (item != tabBar.selectedItem) {
        [self showPillIfNeeded];
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

- (void)addPillToController:(UIViewController *)controller title:(NSString *)title image:(UIImage *)image action:(void (^_Nullable)(void))handler {
    UIButton *pill = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width  / 2 - 78, self.tabBar.frame.origin.y, 156, 40)];
    [pill setTitle:title forState:UIControlStateNormal];
    [pill setTitleColor:[UIColor bonfireBlack] forState:UIControlStateNormal];
    [pill.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
    pill.adjustsImageWhenHighlighted = false;
    [pill setImage:image forState:UIControlStateNormal];
    pill.tintColor = [UIColor bonfireBlack];
    [pill setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
    [pill setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    pill.backgroundColor = [UIColor colorWithWhite:1 alpha:0.96f];
    pill.layer.cornerRadius = pill.frame.size.height / 2;
    pill.layer.shadowOffset = CGSizeMake(0, 1);
    pill.layer.shadowRadius = 2.f;
    pill.layer.shadowColor = [UIColor colorWithWhite:0 alpha:0.12f].CGColor;
    pill.layer.shadowOpacity = 1.f;
    pill.layer.shouldRasterize = true;
    pill.layer.rasterizationScale = [[UIScreen mainScreen] scale];
    pill.layer.masksToBounds = false;
    pill.userInteractionEnabled = true;
    CGFloat intrinsticWidth = pill.intrinsicContentSize.width + (18*2);
    pill.frame = CGRectMake(self.view.frame.size.width / 2 - intrinsticWidth / 2, pill.frame.origin.y, intrinsticWidth, pill.frame.size.height);
    [self.view insertSubview:pill belowSubview:self.tabBar];
    
    [pill bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            pill.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            
        }];
    } forControlEvents:UIControlEventTouchDown];
    [pill bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.9f initialSpringVelocity:0.4f options:UIViewAnimationOptionCurveEaseOut animations:^{
            pill.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {
            
        }];
    } forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit];
    [pill bk_whenTapped:^{
        handler();
    }];
    
    pill.center = CGPointMake(pill.center.x, self.tabBar.frame.origin.y + self.tabBar.frame.size.height / 2);;
    pill.transform = CGAffineTransformMakeScale(0.6, 0.6);
    pill.alpha = 0;
    
    NSInteger index = [self.tabBar.items indexOfObject:controller.tabBarItem];
    [self.pills setObject:pill forKey:[NSNumber numberWithInteger:index]];
}
- (void)hidePill:(UIButton *)pill {
    if (pill == nil) {
        pill = [self presentedPill];
    }
    [UIView animateWithDuration:0.7f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
        pill.center = CGPointMake(pill.center.x, self.tabBar.frame.origin.y + self.tabBar.frame.size.height / 2);
        pill.transform = CGAffineTransformMakeScale(0.6, 0.6);
        pill.alpha = 0;
    } completion:^(BOOL finished) {
        //        self.addPeriodButton.userInteractionEnabled = false;
    }];
}
- (void)showPill:(BOOL)withDelay {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(withDelay ? 0.4f : 0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self showPillIfNeeded];
    });
}
- (void)showPillIfNeeded {
    NSInteger index = [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
    
    if ([self.pills objectForKey:[NSNumber numberWithInteger:index]]) {
        UIButton *pill = [self currentPill];
        
        // hdie other pills
        BOOL previousPill = [self presentedPill] != nil;
        [self hidePill:[self presentedPill]];
        
        [UIView animateWithDuration:0.6f delay:(previousPill ? 0.3f : 0) usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
            pill.alpha = 1;
            pill.transform = CGAffineTransformIdentity;
            pill.center = CGPointMake(pill.center.x, self.tabBar.frame.origin.y - 16 - pill.frame.size.height / 2);
        } completion:nil];
    }
    else if ([self presentedPill]) {
        [self hidePill:[self presentedPill]];
    }
}
- (UIButton *)currentPill {
    NSInteger index = [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
    
    if ([self.pills objectForKey:[NSNumber numberWithInteger:index]]) {
        // NSLog(@"current pill!");
        return [self.pills objectForKey:[NSNumber numberWithInteger:index]];
    }
    else {
        // NSLog(@"no current pill ;(");
        return nil;
    }
}
- (UIButton *)presentedPill {
    NSArray *pillsKeys = [self.pills allKeys];
    for (int i = 0; i < [pillsKeys count]; i++) {
        UIButton *pill = self.pills[pillsKeys[i]];
        if (pill.alpha == 1) {
            // NSLog(@"presented pill!");
            return pill;
        }
    }
    return nil;
}

@end
