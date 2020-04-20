//
//  TabController.m
//  Hallway App
//
//  Created by Austin Valleskey on 8/20/18.
//  Copyright © 2018 Hallway App. All rights reserved.
//

#import "TabController.h"
#import <BlocksKit/BlocksKit+UIKit.h>
#import "UIColor+Palette.h"
#import "Launcher.h"
#import <HapticHelper/HapticHelper.h>
#import "Session.h"
#import "MyCampsTableViewController.h"

@interface TabController () <UITabBarControllerDelegate>

@end

@implementation TabController

- (id)init {
    self = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"TabController"];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    self.delegate = self;
    
    // setup all the view controllers
    NSMutableArray *vcArray = [[NSMutableArray alloc] init];
    
    self.homeNavVC = [self simpleNavWithRootViewController:@"home"];
    [vcArray addObject:self.homeNavVC];
    
    self.discoverNavVC = [self simpleNavWithRootViewController:@"camps"];
    [vcArray addObject:self.discoverNavVC];
    
    self.storeNavVC = [self simpleNavWithRootViewController:@"discover"];
    [vcArray addObject:self.storeNavVC];
    
    self.notificationsNavVC = [self simpleNavWithRootViewController:@"notifs"];
    [vcArray addObject:self.notificationsNavVC];
    
//    self.myProfileNavVC = [self simpleNavWithRootViewController:@"me"];
//    [vcArray addObject:self.myProfileNavVC];
    
    for (NSInteger i = 0; i < [vcArray count]; i++) {
        UINavigationController *navVC = vcArray[i];
        navVC.tabBarItem.title = @"";

        [vcArray replaceObjectAtIndex:i withObject:navVC];
    }
            
    self.viewControllers = vcArray;
    
    self.badges = [NSMutableDictionary new];
    
    self.pills = [NSMutableDictionary new];
    [self addPillToController:self.storeNavVC title:@"Create Camp" image:[[UIImage imageNamed:@"pillPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
        [Launcher openCreateCamp];
    }];
    if ([Session sharedInstance].currentUser.attributes.summaries.counts.camps < 5) {
        [self addPillToController:self.discoverNavVC title:@"Discover Camps" image:[[UIImage imageNamed:@"discoverCampsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
            TabController *tabVC = (TabController *)[Launcher activeTabController];
            if (tabVC) {
                tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.storeNavVC];
                [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.storeNavVC.tabBarItem];
            }
            else {
                [Launcher openDiscover];
            }
        }];
    }
    [self addPillToController:self.notificationsNavVC title:@"Invite Friends" image:[[UIImage imageNamed:@"inviteFriendIcon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
        [Launcher openInviteFriends:nil];
    }];
    
    NSInteger defaultIndex = 0;
    self.selectedIndex = defaultIndex;
    [self setSelectedViewController:vcArray[defaultIndex]];
    
    self.tabBar.tintColor = [UIColor bonfirePrimaryColor];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan) {
            UIView *exploreTabItemView = [self viewForTabInTabBar:self.tabBar withIndex:[self.tabBar.items indexOfObject:self.storeNavVC.tabBarItem]];
            if (CGRectContainsPoint(exploreTabItemView.frame, location)) {
                [Launcher openSearch];
            }
        }
    }];
    [self.tabBar addGestureRecognizer:longPress];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)userUpdated:(NSNotification *)notification {
    self.tabBar.tintColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    self.tabIndicator.backgroundColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    self.navigationAvatarView.user = [Session sharedInstance].currentUser;
}

- (SearchNavigationController *)searchNavWithRootViewController:(NSString *)rootID {
    SearchNavigationController *searchNav;
    
    if ([rootID isEqualToString:@"search"]) {
        SearchTableViewController *viewController = [[SearchTableViewController alloc] init];
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
    
    if ([rootID isEqualToString:@"home"]) {
        HomeTableViewController *viewController = [[HomeTableViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.userStream;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeSearch];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.tabBarItem.title = viewController.title;
        simpleNav.shadowOnScroll = false;
        
        viewController.tableView.frame = viewController.view.bounds;
    }
    else if ([rootID isEqualToString:@"camps"]) {
        MyCampsTableViewController *viewController = [[MyCampsTableViewController alloc] init];
        viewController.title = @"My Camps";
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeSearch];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.shadowOnScroll = false;
    }
    else if ([rootID isEqualToString:@"discover"]) {
        CampStoreTableViewController *viewController = [[CampStoreTableViewController alloc] init];
        // viewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.discover;
        [viewController view];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        simpleNav.currentTheme = [UIColor clearColor];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeSearch];
        simpleNav.shadowOnScroll = false;
    }
    else if ([rootID isEqualToString:@"notifs"]) {
        NotificationsTableViewController *viewController = [[NotificationsTableViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.notifications;
        [viewController view];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeProfile];
        [simpleNav setRightAction:SNActionTypeSearch];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.shadowOnScroll = false;
    }
//    else if ([rootID isEqualToString:@"invite"]) {
//        InviteFriendsViewController *viewController = [[InviteFriendsViewController alloc] init];
//        viewController.title = @"Invite Friends";
//        
//        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
//        [simpleNav setLeftAction:SNActionTypeProfile];
//        [simpleNav setRightAction:SNActionTypeCompose];
//        simpleNav.currentTheme = [UIColor clearColor];
//        simpleNav.shadowOnScroll = false;
//    }
    else if ([rootID isEqualToString:@"me"]) {
        User *user = [Session sharedInstance].currentUser;
        
        ProfileViewController *viewController = [[ProfileViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.myProfile;
        NSString *themeCSS = user.attributes.color.length == 6 ? user.attributes.color : @"7d8a99";
        viewController.theme = [UIColor fromHex:themeCSS];
        viewController.user = user;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
//        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeSettings];
        simpleNav.currentTheme = viewController.theme;
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
    
    self.tabIndicator = [[UIView alloc] initWithFrame:CGRectMake(20, 0, 22, 3)];
    self.tabIndicator.layer.cornerRadius = self.tabIndicator.frame.size.height / 2;
    self.tabIndicator.backgroundColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    self.tabIndicator.alpha = 0;
//    [self.tabBar addSubview:self.tabIndicator];
    
    [self.tabBar setBackgroundImage:[UIImage new]];
    [self.tabBar setShadowImage:[UIImage new]];
    [self.tabBar setTranslucent:true];
    self.tabBar.layer.borderWidth = 0.0f;
    self.tabBar.layer.masksToBounds = true;
    [self.tabBar setBarTintColor:[UIColor colorNamed:@"FullContrastColor_inverted"]];
    [self.tabBar setTintColor:[UIColor bonfireBrand]];
    [[UITabBar appearance] setShadowImage:nil];
        
//    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
//    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
//    self.blurView.backgroundColor = [[UIColor contentBackgroundColor] colorWithAlphaComponent:1];
//    self.blurView.contentView.backgroundColor = [UIColor clearColor];
//    self.blurView.layer.masksToBounds = true;
//    self.blurView.tintColor = [UIColor clearColor];
//    [self.tabBar insertSubview:self.blurView atIndex:0];
    self.tabBackgroundView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height + [UIApplication sharedApplication].keyWindow.safeAreaInsets.bottom)];
    self.tabBackgroundView.backgroundColor = [UIColor colorNamed:@"TabBarBackgroundColor"];
    self.tabBackgroundView.layer.masksToBounds = false;
    self.tabBackgroundView.tintColor = [UIColor clearColor];
    [self.tabBar insertSubview:self.tabBackgroundView atIndex:0];

    // tab bar hairline
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, HALF_PIXEL)];
    separator.backgroundColor = [UIColor tableViewSeparatorColor];
//    separator.backgroundColor = [UIColor colorNamed:@"FullContrastColor"];
//    separator.alpha = 0.06;
    [self.tabBar addSubview:separator];
    
//    self.tabBar.clipsToBounds = true;
    self.tabBar.tintColor = [UIColor bonfirePrimaryColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
        // TODO: Verify this prefetches the notification table view
        [self.notificationsNavVC view];
    }
    
    if (self.view.tag != 1) {
        self.view.tag = 1;
        wait(0.3f, ^{
            [self showPillIfNeeded];
        });
        
        NSInteger index = [self.tabBar.items indexOfObject:self.tabBar.selectedItem];
        
        UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:index];
        UIImageView *tabBarImageView = nil;
        for (UIImageView *subview in [tabBarItemView subviews]) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                tabBarImageView = subview;
                break;
            }
        }
                
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x + (tabBarImageView.frame.size.width * .25), 0, tabBarImageView.frame.size.width / 2, 3);
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.35f options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, 0, tabBarImageView.frame.size.width, 3);
            self.tabIndicator.layer.cornerRadius = self.tabIndicator.frame.size.height / 2;
            self.tabIndicator.alpha = 1;
        } completion:nil];
        
        
        // add avatar
        NSInteger meAvatarIndex = [self.viewControllers indexOfObject:self.myProfileNavVC];
        UIView *meTabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:meAvatarIndex];
        UIImageView *meTabBarImageView;
        for (UIImageView *subview in [meTabBarItemView subviews]) {
            if ([subview isKindOfClass:[UIImageView class]]) {
                meTabBarImageView = subview;
                break;
            }
        }
        self.navigationAvatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(meTabBarItemView.frame.origin.x + tabBarItemView.frame.size.width / 2 - 11, self.tabBar.frame.origin.y + tabBarItemView.frame.origin.y + tabBarItemView.frame.size.height / 2 - 11, 22, 22)];
        self.navigationAvatarView.userInteractionEnabled = false;
        self.navigationAvatarView.user = [Session sharedInstance].currentUser;
        for (id interaction in self.navigationAvatarView.interactions) {
            if (@available(iOS 13.0, *)) {
                if ([interaction isKindOfClass:[UIContextMenuInteraction class]]) {
                    [self.navigationAvatarView removeInteraction:interaction];
                }
            }
        }
//        [self.tabBar.superview addSubview:self.navigationAvatarView];

        if (!IS_IPAD && SYSTEM_VERSION_LESS_THAN(@"13")) {
            NSMutableArray *vcArray = [[NSMutableArray alloc] initWithArray:self.viewControllers];
            
            for (NSInteger i = 0; i < [vcArray count]; i++) {
                UINavigationController *navVC = vcArray[i];
                UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:i];
                UIImageView *tabBarImageView = nil;
                for (UIImageView *subview in [tabBarItemView subviews]) {
                    if ([subview isKindOfClass:[UIImageView class]]) {
                        tabBarImageView = subview;
                        break;
                    }
                }
                CGFloat offset = (tabBarItemView.frame.size.height / 2) - tabBarImageView.center.y - (!HAS_ROUNDED_CORNERS ? 1 : 0);
                
                NSLog(@"offset: %f", offset);
                navVC.tabBarItem.imageInsets = UIEdgeInsetsMake(offset, 0, -offset, 0);
                
                [navVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]}
                                                forState:UIControlStateNormal];
                [navVC.tabBarItem setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor clearColor]}
                                                forState:UIControlStateSelected];
                
                [vcArray replaceObjectAtIndex:i withObject:navVC];
            }
            
            self.viewControllers = [vcArray copy];
        }
    }
}

- (void)hideBadgeForItem:(UITabBarItem *)tabBarItem {
    NSUInteger index = [self.tabBar.items indexOfObject:tabBarItem];
    UIView *bubbleView = [self.badges objectForKey:[NSNumber numberWithInteger:index]];
    
    // hide
    if (!bubbleView) return;
    
    // clear notifications
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        bubbleView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        bubbleView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.badges removeObjectForKey:[NSNumber numberWithInteger:index]];
        [bubbleView removeFromSuperview];
    }];
}
- (void)setBadgeValue:(NSString *)badgeValue forItem:(UITabBarItem *)tabBarItem {
    badgeValue = [NSString stringWithFormat:@"%@", badgeValue];
    
    NSUInteger index = [self.tabBar.items indexOfObject:tabBarItem];
    UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:index];
    UIView *bubbleView = [self.badges objectForKey:[NSNumber numberWithInteger:index]];
    
    if (!badgeValue || badgeValue.length == 0 || (![badgeValue isEqualToString:@" "] && [badgeValue intValue] == 0)) {
        [self hideBadgeForItem:tabBarItem];
    }
    else {
        NSString *badgeText;
        if ([badgeValue intValue] > 9) {
            badgeText = @"9+";
        }
        else if ([badgeValue isEqualToString:@" "]) {
            badgeText = @"";
        }
        else {
            badgeText = [NSString stringWithFormat:@"%i", [badgeValue intValue]];
        }
        
        UIFont *badgeFont = [UIFont systemFontOfSize:MAX(12.f - (2 * (badgeText.length - 1)), 8) weight:UIFontWeightBold];
        BOOL miniDot = badgeText.length == 0;
        CGFloat bubbleDiameter = miniDot ? 6 : 16;
        CGFloat bubbleWidth = bubbleDiameter;
        if (badgeText.length > 1) {
            bubbleWidth = ceilf([badgeText boundingRectWithSize:CGSizeMake(100, bubbleDiameter) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) attributes:@{NSFontAttributeName: badgeFont} context:nil].size.height) + (ceilf(badgeFont.pointSize * 0.5) * 2);
        }
        CGRect bubbleFrame = CGRectMake(tabBarItemView.frame.origin.x + tabBarItemView.frame.size.width / 2 - (bubbleWidth / 2) + (miniDot ? 12 : 10), self.tabBar.frame.origin.y + tabBarItemView.frame.origin.y + tabBarItemView.frame.size.height / 2 - (bubbleDiameter / 2) - (miniDot ? 12 : 10), bubbleWidth, bubbleDiameter);
        CGRect borderViewFrame = CGRectMake(-2, -2, bubbleFrame.size.width + 4, bubbleFrame.size.height + 4);
        
        // show
        UIView *borderView = [bubbleView viewWithTag:101];
        UILabel *label = [bubbleView viewWithTag:10];
        
        if (!bubbleView) {
            // create bubble view
            bubbleView = [[UIView alloc] initWithFrame:bubbleFrame];
            bubbleView.tag = 100;
            bubbleView.backgroundColor = [UIColor bonfireBrand];
            bubbleView.layer.cornerRadius = bubbleView.frame.size.height / 2;
            [self.badges setObject:bubbleView forKey:[NSNumber numberWithInteger:index]];
            [self.view addSubview:bubbleView];
            
            borderView = [[UIView alloc] initWithFrame:borderViewFrame];
            borderView.layer.borderColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"].CGColor;
            borderView.layer.borderWidth = 2;
            borderView.layer.cornerRadius = borderView.frame.size.height / 2;
            borderView.tag = 101;
            [bubbleView addSubview:borderView];
            
            label = [[UILabel alloc] initWithFrame:bubbleView.bounds];
            label.textColor = [UIColor whiteColor];
            label.textAlignment = NSTextAlignmentCenter;
            label.tag = 10;
            [bubbleView addSubview:label];
            
            // prepare for animations
            bubbleView.alpha = 0;
            bubbleView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        }
        
        [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.5f initialSpringVelocity:0.35f options:UIViewAnimationOptionCurveEaseOut animations:^{
            bubbleView.alpha = 1;
            bubbleView.transform = CGAffineTransformMakeScale(1, 1);
            
            bubbleView.frame = bubbleFrame;
            borderView.frame = borderViewFrame;
            
            label.text = badgeText;
            label.font = badgeFont;
            label.frame = bubbleView.bounds;
        } completion:^(BOOL finished) {
        }];
    }
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    for (UIView *bubbleView in [self.badges allValues]) {
        if ([bubbleView isKindOfClass:[UIView class]]) {
            UIView *borderView = [bubbleView viewWithTag:101];
            borderView.layer.borderColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"].CGColor;
        }
    }
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    NSInteger index = [tabBar.items indexOfObject:item];
    
    [self showPillIfNeeded];
    
    UIView *tabBarItemView = [self viewForTabInTabBar:tabBar withIndex:index];
    UIImageView *tabBarImageView = nil;
    for (UIImageView *subview in [tabBarItemView subviews]) {
        if ([subview isKindOfClass:[UIImageView class]]) {
            tabBarImageView = subview;
            break;
        }
    }
    
    [UIView animateWithDuration:0.225 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);
    } completion:nil];
    
    UIView *burst = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    burst.backgroundColor = [UIColor colorNamed:@"FullContrastColor"];
    burst.layer.cornerRadius = burst.frame.size.height / 2;
    burst.center = tabBarItemView.center;
    burst.transform = CGAffineTransformMakeScale(0.01, 0.01);
    burst.alpha = 0;
    [tabBarItemView.superview addSubview:burst];
//    [UIView animateWithDuration:0.15 delay:0 usingSpringWithDamping:0.87 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
//        tabBarItemView.transform = CGAffineTransformMakeScale(0.8, 0.8);
//        if (tabBar.selectedItem == self.myProfileNavVC.tabBarItem) {
//            self.navigationAvatarView.transform = CGAffineTransformMakeScale(0.8, 0.8);
//        }
//    } completion:^(BOOL finished) {
//        [UIView animateWithDuration:0.2f delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
//            tabBarItemView.transform = CGAffineTransformIdentity;
//            if (tabBar.selectedItem == self.myProfileNavVC.tabBarItem) {
//                self.navigationAvatarView.transform = CGAffineTransformIdentity;
//            }
//        } completion:^(BOOL finished) {
//            [burst removeFromSuperview];
//        }];
//    }];
    
//    burst.alpha = 0;
//    [UIView animateWithDuration:1.2f delay:0 usingSpringWithDamping:0.92 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
//        burst.transform = CGAffineTransformMakeScale(1, 1);
//    } completion:^(BOOL finished) {
//    }];
//    [UIView animateWithDuration:1.1f delay:0.1f usingSpringWithDamping:0.92 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseIn animations:^{
//        burst.alpha = 0;
//    } completion:^(BOOL finished) {
//        [burst removeFromSuperview];
//    }];
    
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        // run on background thread
//        [HapticHelper generateFeedback:FeedbackType_Selection];
//    });
    
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

- (void)addPillToController:(UIViewController *)controller title:(NSString *)title image:(UIImage * _Nullable)image action:(void (^_Nullable)(void))handler {
    UIButton *pill = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width  / 2 - 78, self.tabBar.frame.origin.y, 156, 40)];
    [pill setTitle:title forState:UIControlStateNormal];
    [pill.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
    pill.adjustsImageWhenHighlighted = false;
    pill.tintColor = [UIColor bonfirePrimaryColor];
    if (image) {
        [pill setImage:image forState:UIControlStateNormal];
        [pill setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
        [pill setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    }
    pill.backgroundColor = [UIColor colorNamed:@"PillBackgroundColor"];
    
    [pill setCornerRadiusType:BFCornerRadiusTypeCircle];
    [pill setElevation:2];
    pill.layer.borderWidth = HALF_PIXEL;
    pill.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.08f].CGColor;
    pill.userInteractionEnabled = true;
    CGFloat intrinsticWidth = pill.intrinsicContentSize.width + (18*2);
    pill.frame = CGRectMake(self.view.frame.size.width / 2 - intrinsticWidth / 2, pill.frame.origin.y, intrinsticWidth, pill.frame.size.height);
    [pill setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
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
        
        if (pill == [self presentedPill]) return;
        
        // hdie other pills
        BOOL previousPill = [self presentedPill] != nil;
        [self hidePill:[self presentedPill]];
        
        [UIView animateWithDuration:0.6f delay:(previousPill ? 0.3f : 0) usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseIn|UIViewAnimationOptionAllowUserInteraction) animations:^{
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
