//
//  Launcher.m
//  Pulse
//
//  Created by Austin Valleskey on 11/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Launcher.h"
#import "LauncherNavigationViewController.h"
#import "RoomViewController.h"
#import "RoomMembersViewController.h"
#import "ProfileViewController.h"
#import "PostViewController.h"
#import "OnboardingViewController.h"
#import "CreateRoomViewController.h"
#import "EditProfileViewController.h"
#import "UIColor+Hex.h"
#import "AppDelegate.h"
#import "TabController.h"

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})

@implementation Launcher

static Launcher *launcher;

+ (Launcher *)sharedInstance {
    if (!launcher) {
        launcher = [[Launcher alloc] init];
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
    return [launcher activeViewController].navigationController;
}
- (UITabBarController *)activeTabController {
    return [launcher activeViewController].navigationController.tabBarController;
}

- (LauncherNavigationViewController *)activeLauncherNavigationController {
    return [[launcher activeViewController] isKindOfClass:[LauncherNavigationViewController class]] ? (LauncherNavigationViewController *)[launcher activeViewController] : nil;
}

- (Class)activeViewControllerClass {
    return [[self activeViewController] class];
}
- (UIViewController *)activeViewController {
    UIViewController *viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (viewController.presentedViewController != NULL) {
        viewController = viewController.presentedViewController;
    }
    
    NSLog(@"activeViewController class: %@", [viewController class]);
    
    return viewController;
}

- (BOOL)canPush {
    NSLog(@"can push? %@", [launcher activeViewController]);
    
    return [[launcher activeViewController] isKindOfClass:[UINavigationController class]]; // alias
}

- (void)launchLoggedIn {
    NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
    launches = launches + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
    
    AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    TabController *tbc = [delegate createTabBarController];
    tbc.transitioningDelegate = launcher;
    
    [[launcher activeViewController] presentViewController:tbc animated:YES completion:nil];
}

- (void)openRoom:(Room *)room {
    RoomViewController *r = [[RoomViewController alloc] init];
    
    r.room = room;
    r.theme = [self colorFromHexString:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"707479"];
    
    r.title = r.room.attributes.details.title ? r.room.attributes.details.title : @"Loading...";
    
    LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:r];
        [newLauncher updateSearchText:r.title];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:r.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            if (r.room.identifier ||
                r.room.attributes.details.identifier) {
                [activeLauncherNavVC updateSearchText:r.title];
            }
            else {
                [activeLauncherNavVC updateSearchText:@"Unkown Room"];
            }
            
            [activeLauncherNavVC updateBarColor:r.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [launcher push:r animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
    
    // [self addToRecentlyOpened:[room toDictionary]];
}
- (void)openRoomMembersForRoom:(Room *)room {
    RoomMembersViewController *rm = [[RoomMembersViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    rm.room = room;
    rm.theme = [self colorFromHexString:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"0076ff"];
    
    rm.title = @"Members";
    
    LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:rm];
        newLauncher.textField.text = rm.title;
        [newLauncher hideSearchIcon];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:rm.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.textField.text = rm.title;
            [activeLauncherNavVC hideSearchIcon];
            
            [activeLauncherNavVC updateBarColor:rm.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [self push:rm animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openProfile:(User *)user {
    ProfileViewController *p = [[ProfileViewController alloc] init];
    
    NSString *themeCSS = user.attributes.details.color.length == 6 ? user.attributes.details.color : (user.identifier ? @"0076ff" : @"707479");
    p.theme = [self colorFromHexString:themeCSS];
    
    p.user = user;
    
    LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.textField.text = activeLauncherNavVC.topViewController.title;
        }
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:p];
        [newLauncher updateSearchText:p.user.attributes.details.displayName];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC updateSearchText:p.user.attributes.details.displayName];
            
            [activeLauncherNavVC updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [activeLauncherNavVC pushViewController:p animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openPost:(Post *)post {
    PostViewController *p = [[PostViewController alloc] init];
    
    p.post = post;
    NSString *themeCSS = [post.attributes.status.postedIn.attributes.details.color lowercaseString];
    p.theme = [self colorFromHexString:[themeCSS isEqualToString:@"ffffff"]?@"222222":themeCSS];
    p.title = @"Conversation";
    
    LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    NSLog(@"---------");
    NSLog(@"activeLauncherNavVC: %@", activeLauncherNavVC);
    NSLog(@"activeTabcontroller: %@", [launcher activeTabController]);
    NSLog(@"---------");
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:p];
        newLauncher.textField.text = p.title;
        [newLauncher hideSearchIcon];
        newLauncher.transitioningDelegate = launcher;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [launcher present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            activeLauncherNavVC.textField.text = p.title;
            [activeLauncherNavVC hideSearchIcon];
            
            [activeLauncherNavVC updateBarColor:p.theme withAnimation:2 statusBarUpdateDelay:NO];
            
            [launcher push:p animated:YES];
            
            [activeLauncherNavVC updateNavigationBarItemsWithAnimation:YES];
        }
    }
}
- (void)openCreateRoom {
    CreateRoomViewController *c = [[CreateRoomViewController alloc] init];
    c.transitioningDelegate = launcher;
    [self present:c animated:YES];
}

- (void)openComposePost {
    RoomViewController *r = [[RoomViewController alloc] init];
    
    r.room = nil;
    r.theme = [Session sharedInstance].themeColor;
    r.isCreatingPost = true;
    
    LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if (activeLauncherNavVC != nil) {
        activeLauncherNavVC.textField.text = activeLauncherNavVC.topViewController.title;
    }
    
    LauncherNavigationViewController *newLauncher = [[LauncherNavigationViewController alloc] initWithRootViewController:r];
    newLauncher.textField.text = @"";
    newLauncher.textField.placeholder = @"Search Rooms...";
    newLauncher.isCreatingPost = true;
    newLauncher.transitioningDelegate = self;
    [newLauncher positionTextFieldSearchIcon];
    
    [newLauncher updateBarColor:[UIColor whiteColor] withAnimation:0 statusBarUpdateDelay:NO];
    
    [self present:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
- (void)openEditProfile {
    EditProfileViewController *epvc = [[EditProfileViewController alloc] initWithStyle:UITableViewStyleGrouped];
    epvc.view.tintColor = [Session sharedInstance].themeColor;
    
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = self;
    newNavController.navigationBar.barStyle = UIBarStyleBlack;
    newNavController.navigationBar.translucent = false;
    newNavController.navigationBar.barTintColor = [UIColor whiteColor];
    [newNavController setNeedsStatusBarAppearanceUpdate];
    
    [self present:newNavController animated:YES];
}

- (void)openOnboarding {
    OnboardingViewController *o = [[OnboardingViewController alloc] init];
    o.transitioningDelegate = self;
    [launcher present:o animated:YES];
}

- (void)present:(UIViewController *)viewController animated:(BOOL)animated {
    [[launcher activeViewController] presentViewController:viewController animated:YES completion:nil];
}

- (void)push:(UIViewController *)viewController animated:(BOOL)animated {
    if ([launcher canPush]) {
        NSLog(@"can push");
        
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
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = YES;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}
/*
 Called when dismissing a view controller that has a transitioningDelegate
 */
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    SOLOptionsTransitionAnimator *animator = [[SOLOptionsTransitionAnimator alloc] init];
    animator.appearing = NO;
    animator.duration = 0.3;
    animationController = animator;
    
    return animationController;
}

// PUSH TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
animationControllerForOperation:(UINavigationControllerOperation)operation
fromViewController:(UIViewController*)fromVC
toViewController:(UIViewController*)toVC
{
    if (operation == UINavigationControllerOperationPush) {
        LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
        if (activeLauncherNavVC != nil) {
            if ([launcher activeTabController]) {
                // hide:
                // 1) profile picture
                // 2) plus icon
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    activeLauncherNavVC.composePostButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    activeLauncherNavVC.composePostButton.alpha = 0;
                    
                    activeLauncherNavVC.inviteFriendButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    activeLauncherNavVC.inviteFriendButton.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
            if ([toVC isKindOfClass:[RoomViewController class]]) {
                activeLauncherNavVC.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                activeLauncherNavVC.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    activeLauncherNavVC.infoButton.alpha = 1;
                    activeLauncherNavVC.infoButton.transform = CGAffineTransformIdentity;
                    
                    activeLauncherNavVC.backButton.alpha = 1;
                    activeLauncherNavVC.backButton.transform = CGAffineTransformIdentity;
                    
                    activeLauncherNavVC.textField.textColor = [UIColor whiteColor];
                    activeLauncherNavVC.textField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16f];
                } completion:^(BOOL finished) {
                }];
            }
        }
        
        return [[PushAnimator alloc] init];
    }
    
    if (operation == UINavigationControllerOperationPop) {
        LauncherNavigationViewController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
        if (activeLauncherNavVC != nil) {
            if ([launcher activeTabController]) {
                activeLauncherNavVC.navigationBar.barStyle = UIBarStyleDefault;
                [activeLauncherNavVC setNeedsStatusBarAppearanceUpdate];
                
                activeLauncherNavVC.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                activeLauncherNavVC.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    activeLauncherNavVC.navigationBackgroundView.backgroundColor = [UIColor whiteColor];
                    // self.textField.text = @"Home";
                    activeLauncherNavVC.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
                    activeLauncherNavVC.textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
                    
                    activeLauncherNavVC.inviteFriendButton.alpha = 1;
                    activeLauncherNavVC.inviteFriendButton.transform = CGAffineTransformIdentity;
                    
                    activeLauncherNavVC.composePostButton.alpha = 1;
                    activeLauncherNavVC.composePostButton.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                }];
            }
            
            if ([fromVC isKindOfClass:[RoomViewController class]]) {
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    activeLauncherNavVC.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    activeLauncherNavVC.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                    
                    activeLauncherNavVC.infoButton.alpha = 0;
                    activeLauncherNavVC.backButton.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
        }
        
        return [[PopAnimator alloc] init];
    }
    
    return nil;
}

- (UIColor *)colorFromHexString:(NSString *)hexString {
    unsigned rgbValue = 0;
    if (hexString != nil && hexString.length == 6) {
        NSScanner *scanner = [NSScanner scannerWithString:hexString];
        [scanner setScanLocation:0]; // bypass '#' character
        [scanner scanHexInt:&rgbValue];
        return [UIColor colorWithDisplayP3Red:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
    }
    else {
        return [UIColor colorWithWhite:0.2f alpha:1];
    }
}

@end


@implementation PushAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    UIView *containerView = [transitionContext containerView];
    containerView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    // Presenting
    [containerView addSubview:toView];
    
    fromView.userInteractionEnabled = NO;
    
    // Round the corners
    fromView.layer.masksToBounds = YES;
    toView.layer.masksToBounds = YES;
    
    CGFloat toViewEndY = toView.frame.origin.y;
    toView.frame = CGRectMake(containerView.frame.size.width, toView.frame.origin.y, toView.frame.size.width, toView.frame.size.height);
    toView.layer.masksToBounds = false;
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.78f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        toView.frame = CGRectMake(toView.frame.origin.x, toViewEndY, toView.frame.size.width, toView.frame.size.height);
        fromView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        fromView.layer.cornerRadius = 12.f;
    } completion:^(BOOL finished) {
        fromView.transform = CGAffineTransformMakeScale(1, 1);
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end


@implementation PopAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    toView.transform = CGAffineTransformMakeScale(0.8, 0.8);
    UIView *containerView = [transitionContext containerView];
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    [containerView addSubview:toView];
    [containerView bringSubviewToFront:fromView];
    
    [UIView animateWithDuration:duration delay:0 usingSpringWithDamping:0.78f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
        fromView.frame = CGRectMake(fromView.frame.origin.x, toVC.navigationController.view.frame.size.height, fromView.frame.size.width, fromView.frame.size.height);
        toView.transform = CGAffineTransformMakeScale(1, 1);
        toView.layer.cornerRadius = 0;
    } completion:^(BOOL finished) {
        [fromView removeFromSuperview];
        toView.userInteractionEnabled = YES;
        [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
    }];
}

@end
