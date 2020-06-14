//
//  MasterViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "MasterViewController.h"
#import "SimpleNavigationController.h"

#import "HomeTableViewController.h"
#import "CampsCollectionViewController.h"
#import "NotificationsTableViewController.h"
#import "CampStoreTableViewController.h"
#import "MyCampsTableViewController.h"

#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "BFAlertController.h"

#import "Launcher.h"
#import "UIColor+Palette.h"

@interface MasterViewController () <UIScrollViewDelegate>

@property (nonatomic) NSInteger activeTab;

// View Controllers
@property (nonatomic, strong) MyCampsTableViewController *myCampsVC;
@property (nonatomic, strong) HomeTableViewController *homeVC;
@property (nonatomic, strong) NotificationsTableViewController *notificationsVC;

// Deprecated
@property (nonatomic, strong) CampsCollectionViewController *homebaseVC;
@property (nonatomic, strong) CampStoreTableViewController *campStoreVC;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor tableViewBackgroundColor];
    
    [self setupNavBar];
    
    [self initPgaedScrollView];
    [self initViewControllers];
    
    [UIView performWithoutAnimation:^{
        [self tabTappedAtIndex:1];
    }];
    
    [self.view bringSubviewToFront:self.navBar];
}

- (void)initPgaedScrollView {
    self.pagedScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(-4, 0, self.view.frame.size.width + (4 * 2), self.view.frame.size.height)];
    self.pagedScrollView.pagingEnabled = true;
    self.pagedScrollView.contentSize = CGSizeMake(0, self.pagedScrollView.frame.size.height);
    self.pagedScrollView.delegate = self;
    self.pagedScrollView.bounces = true;
    self.pagedScrollView.showsVerticalScrollIndicator = false;
    self.pagedScrollView.showsHorizontalScrollIndicator = false;
    [self.view addSubview:self.pagedScrollView];
}
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (scrollView == self.pagedScrollView) {
        CGFloat p = CLAMP(scrollView.contentOffset.x / (scrollView.contentSize.width - scrollView.frame.size.width), 0, 1);
        
//        NSLog(@"p: %f", p);
        
        UIButton *firstButton = [self.tabs firstObject];
        UIButton *lastButton = [self.tabs lastObject];
        
        UIView *selectedBackground = [self.tabControl viewWithTag:5];
        CGFloat newX = firstButton.center.x + ((lastButton.center.x - firstButton.center.x) * p);
        selectedBackground.center = CGPointMake(newX, selectedBackground.center.y);
        
        if ([self.homeVC.composeInputView.textView isFirstResponder]) {
            [self.homeVC.composeInputView.textView resignFirstResponder];
        }
    }
}
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self scrollViewDidStop];
}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self scrollViewDidStop];
}
- (void)scrollViewDidStop {
    NSInteger nextPage = self.pagedScrollView.contentOffset.x / self.pagedScrollView.frame.size.width;
    self.activeTab = nextPage;
    [self updateTabButtonColor];
}

- (void)initViewControllers {
    self.pagedScrollView.contentSize = CGSizeMake(self.pagedScrollView.frame.size.width * 3, self.pagedScrollView.frame.size.height);
        
    self.viewControllers = [NSMutableArray new];
    
//    [self.viewControllers addObject:[self setupHomebase]];
    [self.viewControllers addObject:[self setupMyCamps]];
    [self.viewControllers addObject:[self setupHome]];
//    [self.viewControllers addObject:[self setupCampStore]];
    [self.viewControllers addObject:[self setupNotifications]];
    
    [self.homebaseVC.view setElevation:1];
    [self.homeVC.view setElevation:1];
    [self.campStoreVC.view setElevation:1];
    
    self.pills = [NSMutableDictionary new];
    [self addPillToController:self.homebaseVC title:@"Discover Camps" image:[[UIImage imageNamed:@"discoverCampsIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
        [Launcher openDiscover];
    }];
    [self addPillToController:self.campStoreVC title:@"Invite Friends" image:[[UIImage imageNamed:@"inviteFriendIcon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] action:^(void) {
        [Launcher openInviteFriends:nil];
    }];
}
- (void)addViewController:(UIViewController *)viewController toView:(UIView *)view {
    [self addChildViewController:viewController];
    [view addSubview:viewController.view];
    [viewController didMoveToParentViewController:self];
}

//- (CampsCollectionViewController *)setupHomebase {
//    self.homebaseVC = [[CampsCollectionViewController alloc] initWithCollectionViewLayout:[CampsCollectionViewController layout]];
//
//    [self addViewController:self.homebaseVC toView:self.pagedScrollView];
//
//    self.homebaseVC.view.frame = CGRectMake(4, self.navBar.frame.size.height, self.view.frame.size.width, self.pagedScrollView.frame.size.height - self.navBar.frame.size.height);
//    self.homebaseVC.collectionView.frame = self.homebaseVC.view.bounds;
//
//    return self.homebaseVC;
//}
- (MyCampsTableViewController *)setupMyCamps {
    self.myCampsVC = [[MyCampsTableViewController alloc] init];
    
    [self addViewController:self.myCampsVC toView:self.pagedScrollView];
    
    self.myCampsVC.view.frame = CGRectMake(4, self.navBar.frame.size.height, self.view.frame.size.width, self.pagedScrollView.frame.size.height - self.navBar.frame.size.height);
    self.myCampsVC.tableView.frame = self.myCampsVC.view.bounds;
    
    return self.myCampsVC;
}
- (HomeTableViewController *)setupHome {
    self.homeVC = [[HomeTableViewController alloc] init];
    
    [self addViewController:self.homeVC toView:self.pagedScrollView];
    
    self.homeVC.view.frame = CGRectMake(self.pagedScrollView.frame.size.width + 4, self.navBar.frame.size.height, self.view.frame.size.width, self.pagedScrollView.frame.size.height - self.navBar.frame.size.height);
    self.homeVC.sectionTableView.scrollIndicatorInsets = UIEdgeInsetsMake(self.homeVC.sectionTableView.contentInset.top, self.homeVC.sectionTableView.scrollIndicatorInsets.left, self.homeVC.sectionTableView.scrollIndicatorInsets.bottom, self.homeVC.sectionTableView.scrollIndicatorInsets.right);
    self.homeVC.sectionTableView.frame = self.homeVC.view.bounds;
        
//    UIView *wrapper = [[UIView alloc] initWithFrame:self.homeVC.view.frame];
//    [wrapper setElevation:2];
//    wrapper.layer.cornerRadius = [self viewControllerCornerRadius];
//    wrapper.layer.masksToBounds = true;
//    self.homeVC.view.frame = CGRectMake(0, 0, self.homeVC.view.frame.size.width, self.homeVC.view.frame.size.height);
//    [self.homeVC.view removeFromSuperview];
//    [wrapper addSubview:self.homeVC.view];
//    [self.pagedScrollView addSubview:wrapper];
    
    return self.homeVC;
}
- (CampStoreTableViewController *)setupCampStore {
    self.campStoreVC = [[CampStoreTableViewController alloc] init];
    self.campStoreVC.title = @"Camp Store";
    
    [self addViewController:self.campStoreVC toView:self.pagedScrollView];
    
    self.campStoreVC.view.frame = CGRectMake(self.pagedScrollView.frame.size.width * 2 + 4, self.navBar.frame.size.height, self.view.frame.size.width, self.pagedScrollView.frame.size.height - self.navBar.frame.size.height);
    self.campStoreVC.tableView.tag = 3;
    self.campStoreVC.tableView.frame = self.campStoreVC.view.bounds;
    
    return self.campStoreVC;
}
- (NotificationsTableViewController *)setupNotifications {
    self.notificationsVC = [[NotificationsTableViewController alloc] init];
    self.notificationsVC.title = @"Notifications";

    [self addViewController:self.notificationsVC toView:self.pagedScrollView];
    
    self.notificationsVC.view.frame = CGRectMake(self.pagedScrollView.frame.size.width * 2 + 4, self.navBar.frame.size.height, self.view.frame.size.width, self.pagedScrollView.frame.size.height - self.navBar.frame.size.height);
    self.notificationsVC.tableView.frame = self.notificationsVC.view.bounds;

    return self.notificationsVC;
}

- (void)setupNavBar {
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    
    CGFloat navHeight = 44;
    CGFloat height = safeAreaInsets.top + navHeight;
    
    self.navBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, height)];
    self.navBar.backgroundColor = [UIColor colorNamed:@"Navigation_ClearBackgroundColor"];
    [self.view addSubview:self.navBar];
    
    BFAvatarView *avatar = [[BFAvatarView alloc] initWithFrame:CGRectMake(16, safeAreaInsets.top + (navHeight / 2) - 32 / 2, 32, 32)];
    avatar.user = [Session sharedInstance].currentUser;
    avatar.openOnTap = true;
    [self.navBar addSubview:avatar];
    
    // setup tabs
    [self setupTabs];
    
    UIButton *searchButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [searchButton setImage:[[UIImage imageNamed:@"navSearchIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    searchButton.tintColor = [UIColor bonfirePrimaryColor];
    searchButton.frame = CGRectMake(self.navBar.frame.size.width - searchButton.intrinsicContentSize.width - (16 * 2), safeAreaInsets.top, searchButton.intrinsicContentSize.width + (16 * 2), navHeight);
    [searchButton bk_whenTapped:^{
        [Launcher openSearch];
    }];
    [self.navBar addSubview:searchButton];
    
    UIView *lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(0, self.navBar.frame.size.height, self.navBar.frame.size.width, HALF_PIXEL)];
    lineSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
    [self.navBar addSubview:lineSeparator];
}
- (void)setupTabs {
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    
    NSArray *tabs = @[@"camps", @"home", @"notifs"];
            
    CGFloat buttonWidth = 64;
    
    self.tabControl = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tabs.count * buttonWidth, 36)];
    self.tabControl.backgroundColor = [UIColor colorNamed:@"BubbleColor"];
    self.tabControl.center = CGPointMake(self.navBar.frame.size.width / 2, safeAreaInsets.top / 2 + self.navBar.frame.size.height / 2);
    self.tabControl.layer.cornerRadius = self.tabControl.frame.size.height / 2;
    [self.navBar addSubview:self.tabControl];
        
    // add segmented control segments
    UIView *selectedBackground = [[UIView alloc] initWithFrame:CGRectMake(2, 2, buttonWidth - 4, self.tabControl.frame.size.height - 4)];
    selectedBackground.layer.cornerRadius = selectedBackground.frame.size.height / 2;
    selectedBackground.backgroundColor = [UIColor contentBackgroundColor];
    [selectedBackground setElevation:2];
    selectedBackground.layer.borderWidth = 0;
    selectedBackground.tag = 5;
    [self.tabControl addSubview:selectedBackground];
    
    NSMutableArray *mutableTabs = [NSMutableArray new];
    CGFloat lastButtonX = 0;
    for (NSInteger i = 0; i < tabs.count; i++) {
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        button.tag = i;
        
        if ([tabs[i] isEqualToString:@"home"]) {
            [button setImage:[[UIImage imageNamed:@"tabIcon-home--small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else if ([tabs[i] isEqualToString:@"camps"]) {
            [button setImage:[[UIImage imageNamed:@"tabIcon-camps--small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else if ([tabs[i] isEqualToString:@"discover"]) {
            [button setImage:[[UIImage imageNamed:@"tabIcon-discover--small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else if ([tabs[i] isEqualToString:@"notifs"]) {
            [button setImage:[[UIImage imageNamed:@"tabIcon-notifs--small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        
        button.frame = CGRectMake(lastButtonX, 0, buttonWidth, self.tabControl.frame.size.height);
        
        [button bk_whenTapped:^{
            [self.view endEditing:TRUE];
            [self tabTappedAtIndex:button.tag];
        }];
        
        [button bk_addEventHandler:^(id sender) {
            [HapticHelper generateFeedback:FeedbackType_Selection];
            
        } forControlEvents:UIControlEventTouchDown];
//        [button bk_addEventHandler:^(id sender) {
//        } forControlEvents:(UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        
        [self.tabControl addSubview:button];
        lastButtonX = button.frame.origin.x + button.frame.size.width;
        
        [mutableTabs addObject:button];
    }
    
    self.tabs = [mutableTabs copy];
    
    [self updateTabButtonColor];
}
- (void)tabTappedAtIndex:(NSInteger)tabIndex {
    [self.pagedScrollView setContentOffset:CGPointMake(tabIndex * self.pagedScrollView.frame.size.width, 0) animated:true];
    
    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
        [self.pagedScrollView setContentOffset:CGPointMake(tabIndex * self.pagedScrollView.frame.size.width, 0) animated:false];
    } completion:^(BOOL finished) {
        [self scrollViewDidStop];
    }];
}
- (void)updateTabButtonColor {
    for (UIButton *button in self.tabControl.subviews) {
        if (![button isKindOfClass:[UIButton class]]) continue;
        
        NSInteger current = self.activeTab;
        [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (button.tag == current) {
                button.tintColor = [UIColor bonfirePrimaryColor];
            }
            else {
                button.tintColor = [UIColor bonfireSecondaryColor];
            }
        } completion:nil];
    }
}

#pragma mark - Pills
- (void)addPillToController:(UIViewController *)controller title:(NSString *)title image:(UIImage * _Nullable)image action:(void (^_Nullable)(void))handler {
    UIButton *pill = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width  / 2 - 78, self.view.frame.size.height, 156, 40)];
    [pill setTitle:title forState:UIControlStateNormal];
    [pill.titleLabel setFont:[UIFont systemFontOfSize:16.f weight:UIFontWeightHeavy]];
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
    
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].keyWindow.safeAreaInsets;
    pill.center = CGPointMake(pill.center.x, controller.view.frame.size.height - 16 - pill.frame.size.height / 2 - safeAreaInsets.bottom);
    pill.transform = CGAffineTransformMakeScale(1, 1);
    pill.alpha = 1;
    
    [controller.view addSubview:pill];
}

@end
