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

    self.searchNavVC = [self searchNavWithRootViewController:@"search"];
    //[vcArray addObject:self.searchNavVC];
    
    self.storeNavVC = [self simpleNavWithRootViewController:@"discover"];
    [vcArray addObject:self.storeNavVC];
    
    self.notificationsNavVC = [self simpleNavWithRootViewController:@"notifs"];
    [vcArray addObject:self.notificationsNavVC];
    
    self.myProfileNavVC = [self simpleNavWithRootViewController:@"me"];
    [vcArray addObject:self.myProfileNavVC];
    
    for (NSInteger i = 0; i < [vcArray count]; i++) {
        UINavigationController *navVC = vcArray[i];
        navVC.tabBarItem.title = @"";

        [vcArray replaceObjectAtIndex:i withObject:navVC];
    }
            
    self.viewControllers = vcArray;
    
    NSInteger defaultIndex = 0;
    self.selectedIndex = defaultIndex;
    [self setSelectedViewController:vcArray[defaultIndex]];
    
//    [self.tabBar.items objectAtIndex:0].titlePositionAdjustment = UIOffsetMake((self.view.bounds.size.width / 12), 0.0);
//    [self.tabBar.items objectAtIndex:1].titlePositionAdjustment = UIOffsetMake(0, 0.0);
//    [self.tabBar.items objectAtIndex:2].titlePositionAdjustment = UIOffsetMake(-(self.view.bounds.size.width / 12), 0.0);
//    [self.tabBar.items objectAtIndex:3].titlePositionAdjustment = UIOffsetMake(-(self.view.bounds.size.width / 8), 0.0);
    
    self.badges = [NSMutableDictionary new];
    
    self.pills = [NSMutableDictionary new];
    [self addPillToController:self.storeNavVC title:@"Create Camp" image:[[UIImage imageNamed:@"pillPlusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
        [Launcher openCreateCamp];
    }];
//    [self addPillToController:self.discoverNavVC title:@"Discover Camps" image:[UIImage imageNamed:@"discoverCampsIcon"] action:^(void) {
//        [Launcher openDiscover];
//    }];
    
    self.tabBar.tintColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userUpdated:) name:@"UserUpdated" object:nil];
    
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        if (state == UIGestureRecognizerStateBegan) {
            UIView *exploreTabItemView = [self viewForTabInTabBar:self.tabBar withIndex:[self.tabBar.items indexOfObject:self.storeNavVC.tabBarItem]];
            if (CGRectContainsPoint(exploreTabItemView.frame, location)) {
                DLog(@"booooya");
                
                self.selectedIndex = [self.tabBar.items indexOfObject:self.storeNavVC.tabBarItem];
                [self tabBar:self.tabBar didSelectItem:self.storeNavVC.tabBarItem];
                
                [Launcher openSearch];
            }
        }
    }];
    [self.tabBar addGestureRecognizer:longPress];
}

- (void)userUpdated:(NSNotification *)notification {
    self.tabBar.tintColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    self.tabIndicator.backgroundColor = [UIColor bonfirePrimaryColor]; //[UIColor fromHex:[Session sharedInstance].currentUser.attributes.color];
    self.navigationAvatarView.user = [Session sharedInstance].currentUser;
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
    
    if ([rootID isEqualToString:@"home"]) {
        MyFeedViewController *viewController = [[MyFeedViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.userStream;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeCompose];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.tabBarItem.title = viewController.title;
        simpleNav.shadowOnScroll = false;
        
        viewController.tableView.frame = viewController.view.bounds;
    }
    else if ([rootID isEqualToString:@"discover--blah"]) {
        CombinedHomeViewController *viewController = [[CombinedHomeViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.userStream;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeCompose];
        [simpleNav setShadowVisibility:true withAnimation:false];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.shadowOnScroll = false;
    }
    else if ([rootID isEqualToString:@"camps"]) {
        MyCampsTableViewController *viewController = [[MyCampsTableViewController alloc] init];
        viewController.title = @"My Camps";
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeCompose];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.shadowOnScroll = false;
    }
    else if ([rootID isEqualToString:@"discover"]) {
        CampStoreTableViewController *viewController = [[CampStoreTableViewController alloc] init];
        // viewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.discover;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        simpleNav.currentTheme = [UIColor clearColor];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeCompose];
        simpleNav.shadowOnScroll = false;
    }
    else if ([rootID isEqualToString:@"notifs"]) {
        NotificationsTableViewController *viewController = [[NotificationsTableViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.notifications;
        [viewController view];
        
        [viewController.tableView reloadData];
        viewController.view.backgroundColor = [UIColor contentBackgroundColor];
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
        [simpleNav setRightAction:SNActionTypeCompose];
        simpleNav.currentTheme = [UIColor clearColor];
        simpleNav.shadowOnScroll = false;
    }
    else if ([rootID isEqualToString:@"me"]) {
        User *user = [Session sharedInstance].currentUser;
        
        ProfileViewController *viewController = [[ProfileViewController alloc] init];
        viewController.title = [Session sharedInstance].defaults.keywords.viewTitles.myProfile;
        NSString *themeCSS = user.attributes.color.length == 6 ? user.attributes.color : @"7d8a99";
        viewController.theme = [UIColor fromHex:themeCSS];
        viewController.user = user;
        
        simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
        [simpleNav setLeftAction:SNActionTypeInvite];
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
    [self.tabBar addSubview:self.tabIndicator];
    
    [self.tabBar setBackgroundImage:[UIImage new]];
    [self.tabBar setShadowImage:[UIImage new]];
    [self.tabBar setTranslucent:true];
    self.tabBar.layer.borderWidth = 0.0f;
    [self.tabBar setBarTintColor:[UIColor clearColor]];
    [self.tabBar setTintColor:[UIColor bonfireBrand]];
    [[UITabBar appearance] setShadowImage:nil];
        
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleProminent]];
    self.blurView.frame = CGRectMake(0, 0, self.tabBar.frame.size.width, self.tabBar.frame.size.height);
    self.blurView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.01];
    self.blurView.contentView.backgroundColor = [UIColor clearColor];
    self.blurView.layer.masksToBounds = true;
    self.blurView.tintColor = [UIColor clearColor];
    [self.tabBar insertSubview:self.blurView atIndex:0];

    // tab bar hairline
    UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, (1 / [UIScreen mainScreen].scale))];
    separator.backgroundColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.06f];
    //[self.tabBar addSubview:separator];
    
    self.tabBar.clipsToBounds = true;
    self.tabBar.tintColor = [UIColor bonfirePrimaryColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([UIApplication sharedApplication].applicationIconBadgeNumber > 0) {
        [self setBadgeValue:[NSString stringWithFormat:@"%ld", (long)[UIApplication sharedApplication].applicationIconBadgeNumber] forItem:self.notificationsNavVC.tabBarItem];
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
        [self.tabBar.superview addSubview:self.navigationAvatarView];

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
                CGFloat offset = (tabBarItemView.frame.size.height / 2) - tabBarImageView.center.y;
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

- (void)setBadgeValue:(NSString *)badgeValue forItem:(UITabBarItem *)tabBarItem {
    badgeValue = [NSString stringWithFormat:@"%@", badgeValue];
    
    NSUInteger index = [self.tabBar.items indexOfObject:tabBarItem];
    
    UIView *tabBarItemView = [self viewForTabInTabBar:self.tabBar withIndex:index];
    
    UIView *bubbleView = [self.badges objectForKey:[NSNumber numberWithInteger:index]];;
    
    if (!badgeValue || badgeValue.length == 0 || [badgeValue intValue] == 0) {
        // hide
        if (!bubbleView) return;
        
        [UIView animateWithDuration:0.8f delay:0.2f usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            bubbleView.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarItemView.frame.size.width / 2 + tabBarItem.titlePositionAdjustment.horizontal, bubbleView.frame.origin.y, 0, self.tabIndicator.frame.size.height);
            bubbleView.alpha = 0;
        } completion:^(BOOL finished) {
            [self.badges removeObjectForKey:[NSNumber numberWithInteger:index]];
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
            bubbleView = [[UIView alloc] initWithFrame:CGRectMake(tabBarItemView.frame.origin.x + tabBarItemView.frame.size.width / 2 + tabBarItem.titlePositionAdjustment.horizontal, self.tabBar.frame.origin.y + tabBarItemView.frame.origin.y +  tabBarItemView.frame.size.height / 2, 10, 10)];
            bubbleView.tag = 100;
            bubbleView.backgroundColor = [UIColor bonfireSecondaryColor];
            bubbleView.layer.cornerRadius = bubbleView.frame.size.height / 2;
            [self.badges setObject:bubbleView forKey:[NSNumber numberWithInteger:index]];
            [self.view addSubview:bubbleView];
            
            // prepare for animations
            bubbleView.alpha = 0;
            
            [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.5f initialSpringVelocity:0.35f options:UIViewAnimationOptionCurveEaseOut animations:^{
                bubbleView.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarItemView.frame.size.width / 2 + tabBarItem.titlePositionAdjustment.horizontal - 4, self.tabBar.frame.origin.y - 8 - 4, 8, 8);
                bubbleView.layer.cornerRadius = bubbleView.frame.size.height / 2;
                bubbleView.alpha = 1;
                bubbleView.backgroundColor = [UIColor systemRedColor];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.4f delay:0.1f usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    bubbleView.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarItemView.frame.size.width / 2 + tabBarItem.titlePositionAdjustment.horizontal - 4, self.tabBar.frame.origin.y, 8, self.tabIndicator.frame.size.height);
                    bubbleView.layer.cornerRadius = bubbleView.frame.size.height / 2;
                    
                    if (index == self.selectedIndex) {
                        bubbleView.alpha = 0;
                    }
                } completion:^(BOOL finished) {
                    if (index == self.selectedIndex) {
                        [self.badges removeObjectForKey:[NSNumber numberWithInteger:index]];
                        [bubbleView removeFromSuperview];
                    }
                }];
            }];
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
    
    [UIView animateWithDuration:0.225 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.tabIndicator.frame = CGRectMake(tabBarItemView.frame.origin.x + tabBarImageView.frame.origin.x, self.tabIndicator.frame.origin.y, tabBarImageView.frame.size.width, self.tabIndicator.frame.size.height);
    } completion:nil];
    
    [UIView animateWithDuration:0.2 delay:0 usingSpringWithDamping:0.87 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        tabBarItemView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        if (tabBar.selectedItem == self.myProfileNavVC.tabBarItem) {
            self.navigationAvatarView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25f delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            tabBarItemView.transform = CGAffineTransformIdentity;
            if (tabBar.selectedItem == self.myProfileNavVC.tabBarItem) {
                self.navigationAvatarView.transform = CGAffineTransformIdentity;
            }
        } completion:nil];
    }];
    
    [HapticHelper generateFeedback:FeedbackType_Selection];
    
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
    [pill setTitleColor:[UIColor bonfirePrimaryColor] forState:UIControlStateNormal];
    [pill.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightBold]];
    pill.adjustsImageWhenHighlighted = false;
    pill.tintColor = [UIColor bonfirePrimaryColor];
    if (image) {
        [pill setImage:image forState:UIControlStateNormal];
        [pill setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 8)];
        [pill setTitleEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 0)];
    }
    pill.backgroundColor = [[UIColor cardBackgroundColor] colorWithAlphaComponent:0.96];
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
        
        if (pill == [self presentedPill]) return;
        
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
