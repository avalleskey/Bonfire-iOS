//
//  Launcher.m
//  Pulse
//
//  Created by Austin Valleskey on 11/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Launcher.h"
#import "ComplexNavigationController.h"
#import "RoomViewController.h"
#import "RoomMembersViewController.h"
#import "ProfileViewController.h"
#import "PostViewController.h"
#import "OnboardingViewController.h"
#import "CreateRoomViewController.h"
#import "EditProfileViewController.h"
#import "UIColor+Palette.h"
#import "AppDelegate.h"
#import "TabController.h"
#import "InviteFriendTableViewController.h"

#import <Tweaks/FBTweakViewController.h>
#import <Tweaks/FBTweakStore.h>
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})

@interface Launcher () <FBTweakViewControllerDelegate, MFMessageComposeViewControllerDelegate>

@end

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
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    TabController *tbc = [[TabController alloc] init];
    tbc.delegate = ad;
    tbc.transitioningDelegate = launcher;
    
    [[launcher activeViewController] presentViewController:tbc animated:animated completion:^{
        ad.window.rootViewController = tbc;
        [ad.window makeKeyAndVisible];
    }];
}

- (void)openTimeline {
    if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [launcher launchLoggedIn:false];
    }
    NSLog(@"launcher active view controller: %@", [launcher activeViewController]);
    if ([[launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[launcher activeViewController];
        [activeTabBarController setSelectedIndex:0];
    }
}
- (void)openTrending {
    if ([[launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [launcher launchLoggedIn:false];
    }
    NSLog(@"launcher active view controller: %@", [launcher activeViewController]);
    if ([[launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[launcher activeViewController];
        [activeTabBarController setSelectedIndex:1];
    }
}

- (void)openRoom:(Room *)room {
    RoomViewController *r = [[RoomViewController alloc] init];
    
    r.room = room;
    r.theme = [UIColor fromHex:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"707479"];
    
    r.title = r.room.attributes.details.title ? r.room.attributes.details.title : @"Loading...";
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:r];
        [newLauncher.searchView updateSearchText:r.title];
        newLauncher.transitioningDelegate = self;
        
        [newLauncher updateBarColor:r.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [self present:newLauncher animated:YES];
        
        [newLauncher updateNavigationBarItemsWithAnimation:NO];
    }
    else {
        if (activeLauncherNavVC != nil) {
            if (r.room.identifier ||
                r.room.attributes.details.identifier) {
                [activeLauncherNavVC.searchView updateSearchText:r.title];
            }
            else {
                [activeLauncherNavVC.searchView updateSearchText:@"Unkown Room"];
            }
            
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
    RoomMembersViewController *rm = [[RoomMembersViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    rm.room = room;
    rm.theme = [UIColor fromHex:room.attributes.details.color.length == 6 ? room.attributes.details.color : @"0076ff"];
    
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
    ProfileViewController *p = [[ProfileViewController alloc] init];
    
    NSString *themeCSS = user.attributes.details.color.length == 6 ? user.attributes.details.color : (user.identifier ? @"0076ff" : @"707479");
    p.theme = [UIColor fromHex:themeCSS];
    
    p.user = user;
    
    NSString *searchText = @"Unkown User";
    
    if (p.user.attributes.details.displayName != nil) searchText = p.user.attributes.details.displayName;
    if (p.user.attributes.details.identifier != nil) searchText = [NSString stringWithFormat:@"@%@", p.user.attributes.details.identifier];
    
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
- (void)openPost:(Post *)post {
    PostViewController *p = [[PostViewController alloc] init];
    
    p.post = post;
    NSString *themeCSS;
    if (post.attributes.status.postedIn != nil) {
        themeCSS = [post.attributes.status.postedIn.attributes.details.color lowercaseString];
    }
    else {
        themeCSS = [post.attributes.details.creator.attributes.details.color lowercaseString];
    }
    p.theme = [UIColor fromHex:[themeCSS isEqualToString:@"ffffff"]?@"222222":themeCSS];
    p.title = @"Conversation";
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    NSLog(@"---------");
    NSLog(@"activeLauncherNavVC: %@", activeLauncherNavVC);
    NSLog(@"activeTabcontroller: %@", [launcher activeTabController]);
    NSLog(@"---------");
    if ([launcher activeTabController] != nil || activeLauncherNavVC == nil) {
        if (activeLauncherNavVC != nil) {
            [activeLauncherNavVC.searchView updateSearchText:activeLauncherNavVC.topViewController.title];
        }
        
        ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:p];
        newLauncher.searchView.textField.text = p.title;
        [newLauncher.searchView hideSearchIcon:false];
        newLauncher.transitioningDelegate = launcher;
        
        [newLauncher updateBarColor:p.theme withAnimation:0 statusBarUpdateDelay:NO];
        
        [launcher present:newLauncher animated:YES];
        
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
    
    ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
    if (activeLauncherNavVC != nil) {
        activeLauncherNavVC.searchView.textField.text = activeLauncherNavVC.topViewController.title;
    }
    
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:r];
    newLauncher.searchView.textField.placeholder = @"Search Rooms...";
    [newLauncher.searchView updateSearchText:@""];
    newLauncher.isCreatingPost = true;
    newLauncher.transitioningDelegate = self;
    [newLauncher.searchView setPosition:BFSearchTextPositionCenter];
    
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
    OnboardingViewController *o = [[OnboardingViewController alloc] init];
    o.transitioningDelegate = self;
    [launcher present:o animated:YES];
}

- (void)shareOniMessage:(NSString *)message image:(UIImage * _Nullable)image {
    // confirm action
    MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init]; // Create message VC
    messageController.messageComposeDelegate = self; // Set delegate to current instance
    messageController.transitioningDelegate = [Launcher sharedInstance];
    
    messageController.body = message; // Set initial text to example message
    
    if (image != nil) {
        NSData *dataImg = UIImagePNGRepresentation(image);//Add the image as attachment
        [messageController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
    }
    
    //NSData *dataImg = UIImagePNGRepresentation([UIImage imageNamed:@"logoApple"]);//Add the image as attachment
    //[messageController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
    messageController.transitioningDelegate = self;
    [launcher present:messageController animated:YES];
}
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

- (void)openTweaks {
    FBTweakViewController *tweakVC = [[FBTweakViewController alloc] initWithStore:[FBTweakStore sharedInstance]];
    tweakVC.tweaksDelegate = self;
    tweakVC.transitioningDelegate = self;
    // Assuming this is in the app delegate
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:tweakVC animated:YES completion:nil];
}
- (void)tweakViewControllerPressedDone:(FBTweakViewController *)tweakViewController {
    [tweakViewController dismissViewControllerAnimated:YES completion:NULL];
}

- (void)present:(UIViewController *)viewController animated:(BOOL)animated {
    [[launcher activeViewController] presentViewController:viewController animated:YES completion:nil];
}

- (void)push:(UIViewController *)viewController animated:(BOOL)animated {
    if ([launcher canPush]) {        
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
        ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
        if (activeLauncherNavVC != nil) {
            if ([launcher activeTabController]) {
                // hide:
                // 1) profile picture
                // 2) plus icon
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
//                    activeLauncherNavVC.composePostButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
//                    activeLauncherNavVC.composePostButton.alpha = 0;
//
//                    activeLauncherNavVC.inviteFriendButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
//                    activeLauncherNavVC.inviteFriendButton.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
            if ([toVC isKindOfClass:[RoomViewController class]]) {
//                activeLauncherNavVC.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
//                activeLauncherNavVC.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
//                    activeLauncherNavVC.infoButton.alpha = 1;
//                    activeLauncherNavVC.infoButton.transform = CGAffineTransformIdentity;
//
//                    activeLauncherNavVC.backButton.alpha = 1;
//                    activeLauncherNavVC.backButton.transform = CGAffineTransformIdentity;
                    
                    activeLauncherNavVC.searchView.textField.textColor = [UIColor whiteColor];
                    activeLauncherNavVC.searchView.textField.backgroundColor = [UIColor colorWithWhite:1 alpha:0.16f];
                } completion:^(BOOL finished) {
                }];
            }
        }
        
        return [[PushAnimator alloc] init];
    }
    
    if (operation == UINavigationControllerOperationPop) {
        ComplexNavigationController *activeLauncherNavVC = [launcher activeLauncherNavigationController];
        if (activeLauncherNavVC != nil) {
            if ([launcher activeTabController]) {
                activeLauncherNavVC.navigationBar.barStyle = UIBarStyleDefault;
                [activeLauncherNavVC setNeedsStatusBarAppearanceUpdate];
                
//                activeLauncherNavVC.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
//                activeLauncherNavVC.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
                    activeLauncherNavVC.navigationBackgroundView.backgroundColor = [UIColor whiteColor];
                    // self.searchView.textField.text = @"Home";
                    activeLauncherNavVC.searchView.textField.textColor = [UIColor colorWithWhite:0.07f alpha:1];
                    activeLauncherNavVC.searchView.textField.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08f];
                    
//                    activeLauncherNavVC.inviteFriendButton.alpha = 1;
//                    activeLauncherNavVC.inviteFriendButton.transform = CGAffineTransformIdentity;
//
//                    activeLauncherNavVC.composePostButton.alpha = 1;
//                    activeLauncherNavVC.composePostButton.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                }];
            }
            
            if ([fromVC isKindOfClass:[RoomViewController class]]) {
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.72f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
//                    activeLauncherNavVC.infoButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
//                    activeLauncherNavVC.backButton.transform = CGAffineTransformMakeScale(0.1, 0.1);
//                    
//                    activeLauncherNavVC.infoButton.alpha = 0;
//                    activeLauncherNavVC.backButton.alpha = 0;
                } completion:^(BOOL finished) {
                }];
            }
        }
        
        return [[PopAnimator alloc] init];
    }
    
    return nil;
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
