//
//  Launcher.m
//  Pulse
//
//  Created by Austin Valleskey on 11/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Launcher.h"
#import "SimpleNavigationController.h"
#import "RoomViewController.h"
#import "RoomMembersViewController.h"
#import "ProfileViewController.h"
#import "ProfileCampsListViewController.h"
#import "ProfileFollowingListViewController.h"
#import "PostViewController.h"
#import "StackedOnboardingViewController.h"
#import "OnboardingViewController.h"
#import "CreateRoomViewController.h"
#import "EditProfileViewController.h"
#import "UIColor+Palette.h"
#import "AppDelegate.h"
#import "InviteFriendTableViewController.h"
#import "SettingsTableViewController.h"
#import "ComposeViewController.h"
#import "SSWDirectionalPanGestureRecognizer.h"
#import "InsightsLogger.h"
#import "QuickReplyViewController.h"

#import <SafariServices/SafariServices.h>
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#import <StoreKit/StoreKit.h>
#import <JGProgressHUD.h>

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})

@interface Launcher () <MFMessageComposeViewControllerDelegate, SFSafariViewControllerDelegate>

@property (nonatomic, strong) SFSafariViewController *safariVC;

@end

@implementation Launcher

static Launcher *launcher;

+ (Launcher *)sharedInstance {
    if (!launcher) {
        launcher = [[Launcher alloc] init];
        
        launcher.animator = [[SOLOptionsTransitionAnimator alloc] init];
    }
    return launcher;
}

- (UIViewController *)parentViewController {
    if ([self activeTabController]) {
        return [self activeTabController];
    }
    else if ([self activeNavigationController]) {
        return [self activeNavigationController];
    }
    else {
        return [launcher activeViewController];
    }
}

- (UINavigationController *)activeNavigationController {
    UIViewController *activeViewController = [launcher activeViewController];
    if ([activeViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)[launcher activeViewController];
    }
    else if ([activeViewController isKindOfClass:[UITabBarController class]]) {
        return (UINavigationController *)(((UITabBarController *)[launcher activeViewController]).selectedViewController);
    }
    else {
        return [launcher activeViewController].navigationController;
    }
}
- (TabController *)tabController {
    if ([[UIApplication sharedApplication].delegate.window.rootViewController isKindOfClass:[TabController class]]) {
        return (TabController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    }
    
    return nil;
}
- (UITabBarController *)activeTabController {
    UIViewController *activeVC = [launcher activeViewController];
    if ([activeVC isKindOfClass:[UITabBarController class]]) {
        return (UITabBarController *)activeVC;
    }
    else if ([activeVC isKindOfClass:[UINavigationController class]]) {
        return ((UITabBarController *)activeVC).tabBarController;
    }
    else if (activeVC.navigationController) {
        return ((UITabBarController *)activeVC).navigationController.tabBarController;
    }
    else {
        return ((UITabBarController *)activeVC).tabBarController;
    }
}

- (ComplexNavigationController *)activeLauncherNavigationController {
    return [[launcher activeViewController] isKindOfClass:[ComplexNavigationController class]] ? (ComplexNavigationController *)[launcher activeViewController] : nil;
}

- (Class)activeViewControllerClass {
    return [[self activeViewController] class];
}
- (UIViewController *)activeViewController {
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (viewController.presentedViewController != NULL) {
        viewController = viewController.presentedViewController;
    }
    
    return viewController;
}

- (BOOL)canPush {
    return [[launcher activeViewController] isKindOfClass:[UINavigationController class]]; // alias
}

- (void)launchLoggedIn:(BOOL)animated {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (![[launcher activeViewController] isKindOfClass:[TabController class]]) {
            AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
            TabController *tbc = [[TabController alloc] init];
            tbc.delegate = ad;
            tbc.transitioningDelegate = launcher;
            
            UIViewController *presentingViewController;
            if ([launcher activeViewController].parentViewController != nil) {
                presentingViewController = [launcher activeViewController].parentViewController;
            }
            else {
                presentingViewController = [launcher activeViewController];
            }
            [presentingViewController presentViewController:tbc animated:animated completion:^{
                // [self setRootViewController:tbc];
            }];
        }
    });
}

- (void)openTimeline {
    if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [launcher launchLoggedIn:false];
    }

    if ([[launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[launcher activeViewController];
        [activeTabBarController setSelectedIndex:0];
    }
}
- (void)openTrending {
    if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [launcher launchLoggedIn:false];
    }

    if ([[launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[launcher activeViewController];
        [activeTabBarController setSelectedIndex:0];
    }
}
- (void)openSearch {
    if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [launcher launchLoggedIn:false];
    }
    
    if ([[launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[launcher activeViewController];
        [activeTabBarController setSelectedIndex:1];
    }
}

- (void)openRoom:(Room *)room {
    BOOL insideRoom = ([launcher activeNavigationController] &&
                       [[[[launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[RoomViewController class]] &&
                       [((RoomViewController *)[[[launcher activeNavigationController] viewControllers] lastObject]).room.identifier isEqualToString:room.identifier]);
    if (insideRoom) {
        [self shake];
        return;
    }
    
    RoomViewController *r = [[RoomViewController alloc] init];
    
    // set a fake permissions
    RoomContextPermissions *permissions = [[RoomContextPermissions alloc] init];
    permissions.post = @[BFMediaTypeText];
    permissions.reply = @[BFMediaTypeText];
    permissions.invite = true;
    room.attributes.context.permissions = permissions;
        
    r.room = room;
    r.theme = [UIColor fromHex:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"7d8a99"];
    
    if (r.room.attributes.details.title) {
        r.title = r.room.attributes.details.title;
    }
    else if (r.room.attributes.details.identifier) {
        r.title = [NSString stringWithFormat:@"#%@", r.room.attributes.details.identifier];
    }
    else {
        r.title = @"Unknown Camp";
    }
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:r];
        [newLauncher.searchView updateSearchText:r.title];
        [newLauncher updateBarColor:r.theme withAnimation:0 statusBarUpdateDelay:NO];
        newLauncher.modalTransitionStyle = UIModalPresentationCustom;
        
        [launcher push:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:r.title];
            
            [activeLauncherNavVC updateBarColor:r.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [launcher push:r animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
    
    // Register Siri intent
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.Ingenious.bonfire.open-room-activity-type"];
    activity.title = [NSString stringWithFormat:@"Open %@", r.title];
    activity.userInfo = @{@"room": [room toDictionary]};
    activity.eligibleForSearch = true;
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = true;
    } else {
        // Fallback on earlier versions
    }
    if (@available(iOS 12.0, *)) {
        activity.persistentIdentifier = @"com.Ingenious.bonfire.open-room-activity-type";
    } else {
        // Fallback on earlier versions
    }
    r.view.userActivity = activity;
    [activity becomeCurrent];
}
- (void)openRoomMembersForRoom:(Room *)room {
    RoomMembersViewController *rm = [[RoomMembersViewController alloc] init];
    
    rm.room = room;
    rm.theme = [UIColor fromHex:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"7d8a99"];
    
    rm.title = @"Members";
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:rm.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:rm];
        newLauncher.searchView.textField.text = rm.title;
        [newLauncher.searchView hideSearchIcon:false];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:rm.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.searchView.textField.text = rm.title;
            [activeLauncherNavVC.searchView hideSearchIcon:false];
            
            [activeLauncherNavVC updateBarColor:rm.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [self push:rm animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openProfile:(User *)user {
    BOOL insideProfile = ([launcher activeNavigationController] &&
                          [[[[launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[ProfileViewController class]] &&
                          [((ProfileViewController *)[[[launcher activeNavigationController] viewControllers] lastObject]).user.identifier isEqualToString:user.identifier]);
    if (insideProfile) {
        [self shake];
        return;
    }
    
    ProfileViewController *p = [[ProfileViewController alloc] init];
    
    NSString *themeCSS = user.attributes.details.color.length == 6 ? user.attributes.details.color : @"7d8a99";
    p.theme = [UIColor fromHex:themeCSS];
    
    p.user = user;
    
    NSString *searchText = @"Unkown User";
    
    if (p.user.attributes.details.identifier != nil) searchText = [NSString stringWithFormat:@"@%@", p.user.attributes.details.identifier];
    if (p.user.attributes.details.displayName != nil) searchText = p.user.attributes.details.displayName;
    
    p.title = searchText;
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.searchView.textField.text = activeLauncherNavVC.topViewController.title;
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:p];
        [newLauncher.searchView updateSearchText:searchText];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:searchText];
            
            [activeLauncherNavVC updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [activeLauncherNavVC pushViewController:p animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)shake {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.16f];
    [animation setRepeatCount:0];
    [animation setAutoreverses:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    UIViewController *activeViewController = [launcher activeViewController];
    if ([activeViewController isKindOfClass:[UITabBarController class]]) {
        activeViewController = ((UITabBarController *)activeViewController).selectedViewController;
    }
    
    NSInteger shakeDistance = 3;
    [animation setFromValue:[NSValue valueWithCGPoint:
                             CGPointMake(activeViewController.view.center.x + shakeDistance, activeViewController.view.center.y)]];
    [animation setToValue:[NSValue valueWithCGPoint:
                           CGPointMake(activeViewController.view.center.x - shakeDistance, activeViewController.view.center.y)]];
    [[activeViewController.view layer] addAnimation:animation forKey:@"position"];
}
- (void)openProfileCampsJoined:(User *)user {
    ProfileCampsListViewController *pc = [[ProfileCampsListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    pc.user = user;
    pc.theme = [UIColor fromHex:user.attributes.details.color.length == 6 ? user.attributes.details.color : @"7d8a99"];
    
    pc.title = [user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] ? @"My Camps" : @"Camps Joined";
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:pc.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:pc];
        newLauncher.searchView.textField.text = pc.title;
        [newLauncher.searchView hideSearchIcon:false];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:pc.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.searchView.textField.text = pc.title;
            [activeLauncherNavVC.searchView hideSearchIcon:false];
            
            [activeLauncherNavVC updateBarColor:pc.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [self push:pc animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openProfileUsersFollowing:(User *)user {
    ProfileFollowingListViewController *pf = [[ProfileFollowingListViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    pf.user = user;
    pf.theme = [UIColor fromHex:user.attributes.details.color.length == 6 ? user.attributes.details.color : @"7d8a99"];
    
    pf.title = @"Following";
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:pf.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:pf];
        newLauncher.searchView.textField.text = pf.title;
        [newLauncher.searchView hideSearchIcon:false];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:pf.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.searchView.textField.text = pf.title;
            [activeLauncherNavVC.searchView hideSearchIcon:false];
            
            [activeLauncherNavVC updateBarColor:pf.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [self push:pf animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openPost:(Post *)post withKeyboard:(BOOL)withKeyboard {
    PostViewController *p = [[PostViewController alloc] init];
    p.showKeyboardOnOpen = withKeyboard;
    
    // mock loading with only the identifier
    // post = [[Post alloc] init];
    // post.identifier = 7;
    
    p.post = post;
    NSString *themeCSS;
    if (post.attributes.status.postedIn != nil) {
        NSLog(@"postedIn: %@", post.attributes.status.postedIn);
        themeCSS = [post.attributes.status.postedIn.attributes.details.color lowercaseString];
    }
    else {
        themeCSS = [post.attributes.details.creator.attributes.details.color lowercaseString];
    }
    p.theme = [UIColor fromHex:[themeCSS isEqualToString:@"ffffff"]?@"222222":themeCSS];
    p.title = @"Conversation";
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:p];
        newLauncher.searchView.textField.text = p.title;
        [newLauncher.searchView hideSearchIcon:false];
        newLauncher.transitioningDelegate = launcher;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [launcher push:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.searchView.textField.text = p.title;
            [activeLauncherNavVC.searchView hideSearchIcon:false];
            
            [activeLauncherNavVC updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [launcher push:p animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openPostReply:(Post *)post sender:(UIView *)sender {
    QuickReplyViewController *quickReplyVC = [[QuickReplyViewController alloc] init];
    quickReplyVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    quickReplyVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    quickReplyVC.replyingTo = post;
    UIView *senderSuperView = sender.superview;
    quickReplyVC.fromCenter = [senderSuperView convertPoint:sender.center toView:senderSuperView.superview];
    [[launcher activeViewController] presentViewController:quickReplyVC animated:NO completion:^{
        //[self setRootViewController:vc];
    }];
}
- (void)openCreateRoom {
    CreateRoomViewController *c = [[CreateRoomViewController alloc] init];
    c.transitioningDelegate = launcher;
    [self present:c animated:YES];
}

- (void)openComposePost:(Room * _Nullable)room inReplyTo:(Post * _Nullable)replyingTo withMessage:(NSString * _Nullable)message media:(NSArray * _Nullable)media {
    ComposeViewController *epvc = [[ComposeViewController alloc] init];
    epvc.view.tintColor = [UIColor bonfireBlack];
    epvc.postingIn = room;
    epvc.replyingTo = replyingTo;
    epvc.prefillMessage = message;
    //epvc.media = [[NSMutableArray alloc] initWithArray:media];
    
    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = self;
    [newNavController setLeftAction:SNActionTypeCancel];
    [newNavController setRightAction:SNActionTypeShare];
    newNavController.view.tintColor = epvc.view.tintColor;
    newNavController.currentTheme = [UIColor whiteColor];
    [self present:newNavController animated:YES];
}
- (void)openEditProfile {
    EditProfileViewController *epvc = [[EditProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    epvc.view.tintColor = [UIColor bonfireBlack];
    
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = self;
    newNavController.navigationBar.barStyle = UIBarStyleBlack;
    newNavController.navigationBar.translucent = false;
    newNavController.navigationBar.barTintColor = [UIColor whiteColor];
    [newNavController setNeedsStatusBarAppearanceUpdate];
    
    [self present:newNavController animated:YES];
}

- (void)openInviteFriends:(id)sender {
    InviteFriendTableViewController *ifvc = [[InviteFriendTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    if ([sender isKindOfClass:[Room class]]) {
        // attach room as object -> add context to message
        ifvc.sender = sender;
    }
    
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:ifvc];
    newNavController.transitioningDelegate = launcher;
    newNavController.navigationBar.barStyle = UIBarStyleBlack;
    newNavController.navigationBar.translucent = false;
    [newNavController setNeedsStatusBarAppearanceUpdate];
    
    [launcher present:newNavController animated:YES];
}

- (void)openOnboarding {
    if (![[launcher activeViewController] isKindOfClass:[StackedOnboardingViewController class]] &&
        ![[launcher activeViewController] isKindOfClass:[OnboardingViewController class]]) {
        StackedOnboardingViewController *vc = [[StackedOnboardingViewController alloc] init];
        vc.transitioningDelegate = self;
        
        [[launcher activeViewController] presentViewController:vc animated:YES completion:^{
            //[self setRootViewController:vc];
        }];
    }
}
- (void)setRootViewController:(UIViewController *)rootViewController {
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    // dismiss presented view controllers before switch rootViewController to avoid messed up view hierarchy, or even crash
    UIViewController *presentedViewController = [self findPresentedViewControllerStartingFrom:ad.window.rootViewController];
    [ad.window setRootViewController:rootViewController];
    [self dismissPresentedViewController:presentedViewController completionBlock:nil];
}
- (void)dismissPresentedViewController:(UIViewController *)vc completionBlock:(void(^)(void))completionBlock {
    // if vc is presented by other view controller, dismiss it.
    if ([vc presentingViewController]) {
        __block UIViewController* nextVC = vc.presentingViewController;
        [vc dismissViewControllerAnimated:NO completion:^ {
            // if the view controller which is presenting vc is also presented by other view controller, dismiss it
            if ([nextVC presentingViewController]) {
                [self dismissPresentedViewController:nextVC completionBlock:completionBlock];
            } else {
                if (completionBlock != nil) {
                    completionBlock();
                }
            }
        }];
    } else {
        if (completionBlock != nil) {
            completionBlock();
        }
    }
}
- (UIViewController *)findPresentedViewControllerStartingFrom:(UIViewController *)start {
    if ([start isKindOfClass:[UINavigationController class]]) {
        return [self findPresentedViewControllerStartingFrom:[(UINavigationController *)start topViewController]];
    }
    
    if ([start isKindOfClass:[UITabBarController class]]) {
        return [self findPresentedViewControllerStartingFrom:[(UITabBarController *)start selectedViewController]];
    }
    
    if (start.presentedViewController == nil || start.presentedViewController.isBeingDismissed) {
        return start;
    }
    
    return [self findPresentedViewControllerStartingFrom:start.presentedViewController];
}

- (void)openSettings {
    SettingsTableViewController *settingsVC = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:settingsVC];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    [simpleNav setRightAction:SNActionTypeDone];
    [launcher present:simpleNav animated:YES];
}

- (void)openURL:(NSString *)urlString {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        self.safariVC = [[SFSafariViewController alloc] initWithURL:url];
        self.safariVC.delegate = self;
        self.safariVC.navigationController.navigationBar.tintColor = [UIColor bonfireBrand];
        [[launcher activeViewController] presentViewController:self.safariVC animated:YES completion:nil];
    }
}
- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [[launcher activeViewController] setNeedsStatusBarAppearanceUpdate];
    }
    else if ([launcher activeViewController].navigationController) {
        [[launcher activeViewController].navigationController setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)openActionsForPost:(Post *)post {
    // Three Categories of Post Actions
    // 1) Any user
    // 2) Creator
    // 3) Admin
    BOOL isCreator = ([post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]);
    BOOL isRoomAdmin = false;
    
    // Page action can be shown on
    // A) Any page
    // B) Inside Room
    
    UIAlertController *actionSheet = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    // 1.B.* -- Any user, outside room, any following state
    if (post.attributes.status.postedIn == nil) {
        BOOL insideProfile = ([launcher activeNavigationController] &&
                              [[[[launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[ProfileViewController class]] &&
                              [((ProfileViewController *)[[[launcher activeNavigationController] viewControllers] lastObject]).user.identifier isEqualToString:post.attributes.details.creator.identifier]);
        if (!insideProfile && ![post.attributes.details.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            UIAlertAction *openProfile = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"View @%@'s Profile", post.attributes.details.creator.attributes.details.identifier] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"open camp");
                
                NSError *error;
                User *user = [[User alloc] initWithDictionary:[post.attributes.details.creator toDictionary] error:&error];
                
                [[Launcher sharedInstance] openProfile:user];
            }];
            [actionSheet addAction:openProfile];
        }
    }
    else {
        BOOL insideRoom = ([launcher activeNavigationController] &&
                              [[[[launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[RoomViewController class]] &&
                              [((RoomViewController *)[[[launcher activeNavigationController] viewControllers] lastObject]).room.identifier isEqualToString:post.attributes.status.postedIn.identifier]);
        if (!insideRoom) {
            UIAlertAction *openRoom = [UIAlertAction actionWithTitle:@"Open Camp" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"open camp");
                
                NSError *error;
                Room *room = [[Room alloc] initWithDictionary:[post.attributes.status.postedIn toDictionary] error:&error];
                
                [[Launcher sharedInstance] openRoom:room];
            }];
            [actionSheet addAction:openRoom];
        }
    }
    
    // 1.A.* -- Any user, any page, any following state
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    if (hasiMessage) {
        UIAlertAction *shareOniMessage = [UIAlertAction actionWithTitle:@"Share on iMessage" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *url;
            if (post.attributes.status.postedIn != nil) {
                // posted in a room
                url = [NSString stringWithFormat:@"https://bonfire.camp/c/%@/post/%ld", post.attributes.status.postedIn.attributes.details.identifier, (long)post.identifier];
            }
            else {
                // posted on a profile
                url = [NSString stringWithFormat:@"https://bonfire.camp/u/%@/post/%ld", post.attributes.details.creator.attributes.details.identifier, (long)post.identifier];
            }
            
            NSString *message;
            if (post.attributes.details.message.length > 0) {
                message = [NSString stringWithFormat:@"\"%@\" %@", post.attributes.details.message, url];
            }
            else {
                message = url;
            }
            
            [[Launcher sharedInstance] shareOniMessage:message image:nil];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    
    // 1.A.* -- Any user, any page, any following state
    UIAlertAction *sharePost = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"share post");
        
        [launcher sharePost:post];
    }];
    [actionSheet addAction:sharePost];
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        UIAlertAction *reportPost = [UIAlertAction actionWithTitle:@"Report Post" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"report post");
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Report Post" message:@"Are you sure you want to report this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Report" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"confirm report post");
                [BFAPI reportPost:post.identifier completion:^(BOOL success, id responseObject) {
                    NSLog(@"reported post!");
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel report post");
            }];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [[launcher activeViewController] presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:reportPost];
    }
    
    // 2|3.A.* -- Creator or room admin, any page, any following state
    if (isCreator || isRoomAdmin) {
        UIAlertAction *deletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [actionSheet dismissViewControllerAnimated:YES completion:nil];
            NSLog(@"delete post");
            // confirm action
            UIAlertController *confirmDeletePostActionSheet = [UIAlertController alertControllerWithTitle:@"Delete Post" message:@"Are you sure you want to delete this post?" preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *confirmDeletePost = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
                HUD.textLabel.text = @"Deleting...";
                HUD.vibrancyEnabled = false;
                HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
                HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
                [HUD showInView:[launcher activeViewController].view animated:YES];
                
                NSLog(@"confirm delete post");
                [BFAPI deletePost:post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        NSLog(@"deleted post!");
                        
                        // update room object
                        Room *postedInRoom = post.attributes.status.postedIn;
                        if (postedInRoom) {
                            postedInRoom.attributes.summaries.counts.posts = postedInRoom.attributes.summaries.counts.posts - 1;
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"RoomUpdated" object:postedInRoom];
                            // update post object
                            post.attributes.status.postedIn = postedInRoom;
                        }
                        
                        // success
                        [HUD dismissAfterDelay:0];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if ([launcher activeNavigationController] && [launcher activeNavigationController].viewControllers.count > 1) {
                                [[launcher activeNavigationController] popViewControllerAnimated:YES];
                                
                                if ([[launcher activeNavigationController] isKindOfClass:[ComplexNavigationController class]]) {
                                    [(ComplexNavigationController *)[launcher activeNavigationController] goBack];
                                }
                            }
                            else {
                                [[launcher activeViewController] dismissViewControllerAnimated:YES completion:nil];
                            }
                        });
                    }
                    else {
                        HUD.indicatorView = [[JGProgressHUDErrorIndicatorView alloc] init];
                        HUD.textLabel.text = @"Error Deleting";
                        
                        [HUD dismissAfterDelay:1.f];
                    }
                }];
            }];
            [confirmDeletePostActionSheet addAction:confirmDeletePost];
            
            UIAlertAction *cancelDeletePost = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                NSLog(@"cancel delete post");
            }];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [[launcher activeViewController] presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:deletePost];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"cancel");
    }];
    [actionSheet addAction:cancel];
    
    [[launcher activeViewController] presentViewController:actionSheet animated:YES completion:nil];
}
- (void)sharePost:(Post *)post {
    NSString *url;
    if (post.attributes.status.postedIn != nil) {
        // posted in a room
        url = [NSString stringWithFormat:@"https://bonfire.camp/c/%@/post/%ld", post.attributes.status.postedIn.attributes.details.identifier, (long)post.identifier];
    }
    else {
        // posted on a profile
        url = [NSString stringWithFormat:@"https://bonfire.camp/u/%@/post/%ld", post.attributes.details.creator.attributes.details.identifier, (long)post.identifier];
    }
    
    NSString *message;
    if (post.attributes.details.message.length > 0) {
        message = [NSString stringWithFormat:@"\"%@\" %@", post.attributes.details.message, url];
    }
    else {
        message = url;
    }
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[message] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    
    [[launcher activeViewController] presentViewController:controller animated:YES completion:nil];
}
- (void)shareUser:(User *)user {
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[[NSString stringWithFormat:@"https://bonfire.camp/u/%@", user.attributes.details.identifier]] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    
    [[launcher activeViewController] presentViewController:controller animated:YES completion:nil];
}
- (void)shareRoom:(Room *)room {
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[[NSString stringWithFormat:@"https://bonfire.camp/c/%@", room.attributes.details.identifier]] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationPopover;
    
    [[launcher activeViewController] presentViewController:controller animated:YES completion:nil];
}
- (void)shareOniMessage:(NSString *)message image:(UIImage * _Nullable)image {
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    
    if (hasiMessage) {
        // confirm action
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init]; // Create message VC
        messageController.messageComposeDelegate = self; // Set delegate to current instance
        messageController.transitioningDelegate = [Launcher sharedInstance];
        
        messageController.body = message; // Set initial text to example message
        
        if (image != nil) {
            NSData *dataImg = UIImagePNGRepresentation(image);//Add the image as attachment
            [messageController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
        }
        
        [[launcher activeViewController] presentViewController:messageController animated:YES completion:nil];
    }
}
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    NSLog(@"did finish with result: %ld", (long)result);
    if (result == MessageComposeResultSent) {
        NSLog(@"sent");
    }
    else if (result == MessageComposeResultFailed) {
        NSLog(@"failed");
    }
    else {
        NSLog(@"cancelled");
    }
    [controller dismissViewControllerAnimated:YES completion:^{
        if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
            [[launcher activeViewController] setNeedsStatusBarAppearanceUpdate];
        }
        else if ([launcher activeViewController].navigationController) {
            [[launcher activeViewController].navigationController setNeedsStatusBarAppearanceUpdate];
        }
    }];
}

- (void)expandImageView:(UIImageView *)imageView {
    // Create image info
    JTSImageInfo *imageInfo = [[JTSImageInfo alloc] init];
    imageInfo.image = imageView.image;
    imageInfo.referenceRect = imageView.frame;
    imageInfo.referenceView = imageView.superview;
    
    // Setup view controller
    JTSImageViewController *imageViewer = [[JTSImageViewController alloc]
                                           initWithImageInfo:imageInfo
                                           mode:JTSImageViewControllerMode_Image
                                           backgroundStyle:JTSImageViewControllerBackgroundOption_None];
    UILongPressGestureRecognizer *longPressToSave = [[UILongPressGestureRecognizer alloc] bk_initWithHandler:^(UIGestureRecognizer *sender, UIGestureRecognizerState state, CGPoint location) {
        UIAlertController *shareOptions = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        UIAlertAction *saveAction = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            UIImageWriteToSavedPhotosAlbum(imageViewer.image, nil, nil, nil);
        }];
        UIAlertAction *shareViaAction = [UIAlertAction actionWithTitle:@"Share via..." style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [shareOptions dismissViewControllerAnimated:YES completion:nil];
            
            //create a message
            NSArray *items = @[imageViewer.image];
            
            // build an activity view controller
            UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
            
            // and present it
            controller.modalPresentationStyle = UIModalPresentationPopover;
            [imageViewer presentViewController:controller animated:YES completion:nil];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [shareOptions addAction:saveAction];
        [shareOptions addAction:shareViaAction];
        [shareOptions addAction:cancelAction];
        [imageViewer presentViewController:shareOptions animated:YES completion:nil];
    }];
    [imageViewer.view addGestureRecognizer:longPressToSave];
    
    // Present the view controller.
    [imageViewer showFromViewController:[launcher activeViewController] transition:JTSImageViewControllerTransition_FromOriginalPosition];
}

- (void)requestAppStoreRating {
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

- (void)present:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.transitioningDelegate = self;
    
    [[launcher activeViewController] presentViewController:viewController animated:YES completion:nil];
}
- (void)push:(UIViewController *)viewController animated:(BOOL)animated {
    if ([launcher canPush] && ![viewController isKindOfClass:[UINavigationController class]]) {
        [(UINavigationController *)[launcher activeViewController] pushViewController:viewController animated:YES];
    }
    else {
        [self present:viewController animated:YES];
    }
}

#pragma mark - UIViewControllerTransitioningDelegate

// MODAL TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
    presentingController:(UIViewController *)presenting
    sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    launcher.animator.appearing = YES;
    launcher.animator.duration = 0.3;
    if ([presented isKindOfClass:[ComplexNavigationController class]]) {
        launcher.animator.direction = SOLTransitionDirectionLeft;
    }
    else {
        launcher.animator.direction = SOLTransitionDirectionUp;
    }
    animationController = launcher.animator;
    
    return animationController;
}
/*
 Called when dismissing a view controller that has a transitioningDelegate
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    launcher.animator.appearing = NO;
    launcher.animator.duration = 0.3;
    
    if ([dismissed isKindOfClass:[ComplexNavigationController class]]) {
        launcher.animator.direction = SOLTransitionDirectionLeft;
    }
    else {
        launcher.animator.direction = SOLTransitionDirectionUp;
    }
    animationController = launcher.animator;
    
    return animationController;
}

@end
