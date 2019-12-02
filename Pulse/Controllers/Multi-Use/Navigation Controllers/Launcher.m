//
//  Launcher.m
//  Pulse
//
//  Created by Austin Valleskey on 11/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "Launcher.h"
#import "SimpleNavigationController.h"
#import "CampMembersViewController.h"
#import "ProfileCampsListViewController.h"
#import "ProfileFollowingListViewController.h"

#import "LinkConversationsViewController.h"

#import "HelloViewController.h"
#import "OnboardingViewController.h"
#import "CreateCampViewController.h"
#import "EditProfileViewController.h"
#import "UIColor+Palette.h"
#import "AppDelegate.h"
#import "SettingsTableViewController.h"
#import "ComposeViewController.h"
#import "SSWDirectionalPanGestureRecognizer.h"
#import "InsightsLogger.h"
#import "QuickReplyViewController.h"
#import "KSPhotoBrowser.h"
#import "OutOfDateClientViewController.h"
#import "ExpandedPostCell.h"
#import "BFTableViewCellExporter.h"
#import "InviteToCampTableViewController.h"
#import "BFBotAttachmentView.h"
#import "BFAlertController.h"
#import "InviteFriendsViewController.h"
#import <SEJSONViewController/SEJSONViewController.h>

#import <SafariServices/SafariServices.h>
#import <StoreKit/StoreKit.h>
#import <JGProgressHUD.h>
@import Firebase;

#if !TARGET_OS_MACCATALYST
#import <Messages/Messages.h>
#import <MessageUI/MessageUI.h>
#endif

#define UIViewParentController(__view) ({ \
    UIResponder *__responder = __view; \
    while ([__responder isKindOfClass:[UIView class]]) \
        __responder = [__responder nextResponder]; \
    (UIViewController *)__responder; \
})

#if TARGET_OS_MACCATALYST
@interface Launcher () <SFSafariViewControllerDelegate>
#else
@interface Launcher () <MFMessageComposeViewControllerDelegate, SFSafariViewControllerDelegate>

#endif
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

//#pragma mark - Push & Pop
//
//- (void)previewingContext:(nonnull id<UIViewControllerPreviewing>)previewingContext commitViewController:(nonnull UIViewController *)viewControllerToCommit {
//    // this is the POP
//    // open the view controller
//    if (viewControllerToCommit) {
//        if ([viewControllerToCommit isKindOfClass:[PostViewController class]]) {
//            viewControllerToCommit.title = @"Conversation";
//            
//            PostViewController *p = (PostViewController *)viewControllerToCommit;
//            
//            SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:p];
//            newNavController.transitioningDelegate = [Launcher sharedInstance];
//            newNavController.view.tag = VIEW_CONTROLLER_PUSH_TAG;
//            [newNavController setLeftAction:SNActionTypeBack];
//            newNavController.currentTheme = p.theme;
//            newNavController.modalPresentationStyle = UIModalPresentationFullScreen;
//            
//            [[Launcher topMostViewController] showViewController:newNavController sender:nil];
//        }
//    }
//}
//
//- (nullable UIViewController *)previewingContext:(nonnull id<UIViewControllerPreviewing>)previewingContext viewControllerForLocation:(CGPoint)location {
//    NSLog(@"location:: (x: %f, y: %f)", location.x, location.y);
//    NSLog(@"sourceView: %@", previewingContext.sourceView);
//    
//    if ([previewingContext.sourceView isKindOfClass:[UITableView class]]) {
//        UITableView *tableView = (UITableView *)previewingContext.sourceView;
//        
//        UITableViewCell *cell = [tableView cellForRowAtIndexPath:[tableView indexPathForRowAtPoint:location]];
//        NSLog(@"table cell class:: %@", cell.class);
//        if ([cell isKindOfClass:[PostCell class]]) {
//            PostCell *postCell = (PostCell *)cell;
//                        
//            if (postCell.post) {
//                previewingContext.sourceRect = [tableView convertRect:postCell.frame fromView:tableView];
//                
//                PostViewController *p = [[PostViewController alloc] init];
//                p.showKeyboardOnOpen = false;
//                
//                Post *post = postCell.post;
//                
//                p.post = post;
//                
//                NSString *themeCSS;
//                if (post.attributes.postedIn != nil) {
//                    themeCSS = [post.attributes.postedIn.attributes.color lowercaseString];
//                }
//                else {
//                    themeCSS = [post.attributes.creator.attributes.color lowercaseString];
//                }
//                p.theme = ([themeCSS isEqualToString:@"ffffff"] || themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
//                
//                return p;
//            }
//        }
//    }
//    else if ([previewingContext.sourceView isKindOfClass:[UICollectionView class]]) {
//        UICollectionView *collectionView = (UICollectionView *)previewingContext.sourceView;
//        
//        UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:[collectionView indexPathForItemAtPoint:location]];
//        NSLog(@"collection cell class:: %@", cell.class);
//    }
//    
//    return nil;
//}

- (UIViewController *)parentViewController {
    if ([Launcher activeTabController]) {
        return [Launcher activeTabController];
    }
    else if ([Launcher activeNavigationController]) {
        return [Launcher activeNavigationController];
    }
    else {
        return [Launcher activeViewController];
    }
}

+ (UINavigationController *)activeNavigationController {
    UIViewController *activeViewController = [Launcher activeViewController];
    if ([activeViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)[Launcher activeViewController];
    }
    else if ([activeViewController isKindOfClass:[UITabBarController class]] && [((UITabBarController *)[Launcher activeViewController]).selectedViewController isKindOfClass:[UINavigationController class]]) {
        return (UINavigationController *)(((UITabBarController *)[Launcher activeViewController]).selectedViewController);
    }
    else if ([Launcher activeViewController].navigationController) {
        return [Launcher activeViewController].navigationController;
    }
    
    return nil;
}
+ (TabController *)tabController {
    if ([[UIApplication sharedApplication].delegate.window.rootViewController isKindOfClass:[TabController class]]) {
        return (TabController *)[UIApplication sharedApplication].delegate.window.rootViewController;
    }
    
    return nil;
}
+ (UITabBarController *)activeTabController {
    UIViewController *activeVC = [Launcher activeViewController];
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

+ (ComplexNavigationController *)activeLauncherNavigationController {
    return [[Launcher activeViewController] isKindOfClass:[ComplexNavigationController class]] ? (ComplexNavigationController *)[Launcher activeViewController] : nil;
}

+ (Class)activeViewControllerClass {
    return [[self activeViewController] class];
}
+ (UIViewController *)activeViewController {
    return [self topViewControllerWithRootViewController:[UIApplication sharedApplication].keyWindow.rootViewController];
}
+ (UIViewController *)topMostViewController {
    if ([self activeViewController].tabBarController) {
        return [Launcher activeTabController];
    }
    else if ([self activeViewController].navigationController) {
        return [Launcher activeNavigationController];
    }
    
    return [self activeViewController];
}
+ (UIViewController*)topViewControllerWithRootViewController:(UIViewController*)viewController {
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*)viewController;
        return [self topViewControllerWithRootViewController:tabBarController.selectedViewController];
    } else if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navContObj = (UINavigationController*)viewController;
        return [self topViewControllerWithRootViewController:navContObj.visibleViewController];
    } else if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
        UIViewController* presentedViewController = viewController.presentedViewController;
        return [self topViewControllerWithRootViewController:presentedViewController];
    }
    else {
        for (UIView *view in [viewController.view subviews])
        {
            id subViewController = [view nextResponder];
            if ( subViewController && [subViewController isKindOfClass:[UIViewController class]])
            {
                if ([(UIViewController *)subViewController presentedViewController]  && ![subViewController presentedViewController].isBeingDismissed) {
                    return [self topViewControllerWithRootViewController:[(UIViewController *)subViewController presentedViewController]];
                }
            }
        }
        return viewController;
    }
}

- (BOOL)canPush {
    return [Launcher activeNavigationController]; // alias
}

+ (void)launchLoggedIn:(BOOL)animated replaceRootViewController:(BOOL)replaceRootViewController {
    if (![Launcher activeViewController].navigationController.tabBarController) {
        AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
        
        TabController *tbc = [[TabController alloc] init];
        tbc.delegate = ad;
        tbc.transitioningDelegate = [Launcher sharedInstance];
        tbc.modalPresentationStyle = UIModalPresentationFullScreen;
        
        UIViewController *presentingViewController;
        if ([Launcher activeViewController].parentViewController != nil) {
            presentingViewController = [Launcher activeViewController].parentViewController;
        }
        else {
            presentingViewController = [Launcher activeViewController];
        }
        
        if (replaceRootViewController) {
            [[UIApplication sharedApplication] delegate].window.rootViewController = tbc;
            [[[UIApplication sharedApplication] delegate].window makeKeyAndVisible];
        }
        
        [presentingViewController presentViewController:tbc animated:animated completion:^{
            if ([Launcher sharedInstance].launchAction) {
                NSLog(@"open launch action");
                [Launcher sharedInstance].launchAction();
                [Launcher sharedInstance].launchAction = nil;
            }
        }];
    }
}

+ (void)openTimeline {
//    if ([[Launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
//        [Launcher launchLoggedIn:false];
//    }

    if ([[Launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[Launcher activeViewController];
        [activeTabBarController setSelectedIndex:0];
    }
}
+ (void)openTrending {
//    if ([[Launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
//        [Launcher launchLoggedIn:false];
//    }

    if ([[Launcher activeViewController] isKindOfClass:[UITabBarController class]]) {
        UITabBarController *activeTabBarController = (UITabBarController *)[Launcher activeViewController];
        [activeTabBarController setSelectedIndex:0];
    }
}
+ (void)openSearch {
    SearchTableViewController *searchController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    searchController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    searchController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    
    SearchNavigationController *searchNav = [[SearchNavigationController alloc] initWithRootViewController:searchController];
    searchNav.searchView.openSearchControllerOntap = false;
    
    searchNav.searchView.textField.userInteractionEnabled = true;
    [searchNav.searchView.textField becomeFirstResponder];
    
    [Launcher present:searchNav animated:YES];
    
    /* cross dissolve
     SearchTableViewController *searchController = [[SearchTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
     searchController.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
     
     SearchNavigationController *searchNav = [[SearchNavigationController alloc] initWithRootViewController:searchController];
     searchNav.searchView.openSearchControllerOntap = false;
     searchNav.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
     
     searchNav.searchView.textField.userInteractionEnabled = true;
     [searchNav.searchView.textField becomeFirstResponder];
     
     searchNav.modalPresentationStyle = uimodalpresent;
     
     [[Launcher activeViewController] presentViewController:searchNav animated:YES completion:nil];
     */
}
+ (void)openDiscover {
    CampStoreTableViewController *viewController = [[CampStoreTableViewController alloc] init];
    // viewController.view.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
    viewController.title = @"Discover";
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
    simpleNav.currentTheme = [UIColor clearColor];
    [simpleNav setRightAction:SNActionTypeDone];
    simpleNav.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self present:simpleNav animated:YES];
}

+ (void)openCamp:(Camp *)camp {
    BOOL insideCamp = ([Launcher activeNavigationController] &&
                       [[[[Launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[CampViewController class]] &&
                       ([((CampViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).camp.identifier isEqualToString:camp.identifier] ||
                        [[((CampViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).camp.attributes.identifier lowercaseString] isEqualToString:[camp.attributes.identifier lowercaseString]]));
    if (insideCamp) {
        [self shake];
        return;
    }
    
    CampViewController *r = [Launcher campViewControllerForCamp:camp];

    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:r];
    [newLauncher.searchView updateSearchText:r.title];
    [newLauncher updateBarColor:r.theme animated:false];
    newLauncher.modalTransitionStyle = UIModalPresentationCustom;
    [Launcher push:newLauncher animated:YES];
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
    
    // Register Siri intent
    NSUserActivity *activity = [[NSUserActivity alloc] initWithActivityType:@"com.Ingenious.bonfire.open-camp-activity-type"];
    activity.title = [NSString stringWithFormat:@"Open %@", r.title];
    activity.userInfo = @{@"camp": [camp toDictionary]};
    activity.eligibleForSearch = true;
    if (@available(iOS 12.0, *)) {
        activity.eligibleForPrediction = true;
        activity.persistentIdentifier = @"com.Ingenious.bonfire.open-camp-activity-type";
    }
    r.view.userActivity = activity;
    [activity becomeCurrent];
}
+ (CampViewController *)campViewControllerForCamp:(Camp *)camp {
    CampViewController *r = [[CampViewController alloc] init];
    
    r.camp = camp;
    NSString *themeCSS = [camp.attributes.color lowercaseString];
    r.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    if (r.camp.attributes.title) {
        r.title = r.camp.attributes.title;
    }
    else if (r.camp.attributes.identifier) {
        r.title = [NSString stringWithFormat:@"#%@", r.camp.attributes.identifier];
    }
    else {
        r.title = @"Unknown Camp";
    }
    
    return r;
}
+ (void)openCampMembersForCamp:(Camp *)camp {
    CampMembersViewController *rm = [[CampMembersViewController alloc] init];
    
    rm.camp = camp;
    NSString *themeCSS = [camp.attributes.color lowercaseString];
    rm.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    rm.title = @"Members";
    
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:rm];
    newLauncher.searchView.textField.text = rm.title;
    [newLauncher.searchView hideSearchIcon:false];
    newLauncher.transitioningDelegate = [Launcher sharedInstance];
    
    [newLauncher updateBarColor:rm.theme animated:false];
    
    [self push:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
+ (void)openProfile:(User *)user {
    BOOL insideProfile = ([Launcher activeNavigationController] &&
                          [[[[Launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[ProfileViewController class]] &&
                          ([((ProfileViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).user.identifier isEqualToString:user.identifier] ||
                           [[((ProfileViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).user.attributes.identifier lowercaseString] isEqualToString:[user.attributes.identifier lowercaseString]]));
    if (insideProfile) {
        [self shake];
        return;
    }
    
    ProfileViewController *p = [Launcher profileViewControllerForUser:user];
        
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:p];
    [newLauncher.searchView updateSearchText:p.title];
    newLauncher.transitioningDelegate = [Launcher sharedInstance];
    
    [newLauncher updateBarColor:p.theme animated:false];
    
    [self push:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
+ (ProfileViewController *)profileViewControllerForUser:(User *)user {
    ProfileViewController *p = [[ProfileViewController alloc] init];
    
    NSString *themeCSS = [user.attributes.color lowercaseString];
    p.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    p.user = user;
    
    NSString *searchText = @"Unknown User";
    
    if (p.user.attributes.identifier != nil) searchText = [NSString stringWithFormat:@"@%@", p.user.attributes.identifier];
    if (p.user.attributes.displayName != nil) searchText = p.user.attributes.displayName;
    
    p.title = searchText;
    
    return p;
}
+ (void)openBot:(Bot *)bot {
    BOOL insideBot = ([Launcher activeNavigationController] &&
                          [[[[Launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[ProfileViewController class]] &&
                          ([((ProfileViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).bot.identifier isEqualToString:bot.identifier] ||
                           [[((ProfileViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).bot.attributes.identifier lowercaseString] isEqualToString:[bot.attributes.identifier lowercaseString]]));
    if (insideBot) {
        [self shake];
        return;
    }
    
    ProfileViewController *p = [Launcher profileViewControllerForBot:bot];
        
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:p];
    [newLauncher.searchView updateSearchText:p.title];
    newLauncher.transitioningDelegate = [Launcher sharedInstance];
    
    [newLauncher updateBarColor:p.theme animated:false];
    
    [self push:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
+ (ProfileViewController *)profileViewControllerForBot:(Bot *)bot {
    ProfileViewController *b = [[ProfileViewController alloc] init];
    
    NSString *themeCSS = [bot.attributes.color lowercaseString];
    b.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    b.bot = bot;
    
    NSString *searchText = @"Unknown Bot";
    
    if (b.bot.attributes.identifier != nil) searchText = [NSString stringWithFormat:@"@%@", b.bot.attributes.identifier];
    if (b.bot.attributes.displayName != nil) searchText = b.bot.attributes.displayName;
    
    b.title = searchText;
    
    return b;
}
+ (void)shake {
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"position"];
    [animation setDuration:0.16f];
    [animation setRepeatCount:0];
    [animation setAutoreverses:YES];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
    
    UIViewController *activeViewController = [Launcher activeViewController];
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
+ (void)openProfileCampsJoined:(User *)user {
    ProfileCampsListViewController *pc = [[ProfileCampsListViewController alloc] init];
    
    pc.user = user;
    
    NSString *themeCSS = [user.attributes.color lowercaseString];
    pc.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    pc.title = [user.identifier isEqualToString:[Session sharedInstance].currentUser.identifier] ? @"My Camps" : @"Camps Joined";
    
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:pc];
    newLauncher.searchView.textField.text = pc.title;
    [newLauncher.searchView hideSearchIcon:false];
    newLauncher.transitioningDelegate = [Launcher sharedInstance];
    
    [newLauncher updateBarColor:pc.theme animated:false];
    
    [self push:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
+ (void)openProfileUsersFollowing:(User *)user {
    ProfileFollowingListViewController *pf = [[ProfileFollowingListViewController alloc] init];
    
    pf.user = user;
    
    NSString *themeCSS = [user.attributes.color lowercaseString];
    pf.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    pf.title = @"Following";
    
    ComplexNavigationController *newLauncher = [[ComplexNavigationController alloc] initWithRootViewController:pf];
    newLauncher.searchView.textField.text = pf.title;
    [newLauncher.searchView hideSearchIcon:false];
    newLauncher.transitioningDelegate = [Launcher sharedInstance];
    
    [newLauncher updateBarColor:pf.theme animated:false];
    
    [self push:newLauncher animated:YES];
    
    [newLauncher updateNavigationBarItemsWithAnimation:NO];
}
+ (void)openPost:(Post *)post withKeyboard:(BOOL)withKeyboard {
    PostViewController *p = [Launcher postViewControllerForPost:post];
    p.showKeyboardOnOpen = withKeyboard;
    
    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:p];
    newNavController.transitioningDelegate = [Launcher sharedInstance];
    [newNavController setLeftAction:SNActionTypeBack];
//    newNavController.view.tintColor = p.theme;
    newNavController.currentTheme = p.theme;
    
    [Launcher push:newNavController animated:YES];
}
+ (PostViewController *)postViewControllerForPost:(Post *)post {
    PostViewController *p = [[PostViewController alloc] init];
    
    p.post = post;
    
    NSString *themeCSS;
    if (post.attributes.postedIn != nil) {
        themeCSS = [post.attributes.postedIn.attributes.color lowercaseString];
    }
    else {
        themeCSS = [post.attributes.creator.attributes.color lowercaseString];
    }
    p.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    p.title = @"Conversation";
    
    return p;
}
+ (void)openLinkConversations:(BFLink *)link withKeyboard:(BOOL)withKeyboard {
    LinkConversationsViewController *p = [[LinkConversationsViewController alloc] init];
    p.showKeyboardOnOpen = withKeyboard;
    p.link = link;
    
    NSString *themeCSS;
    if (link.attributes.attribution != nil) {
        themeCSS = [link.attributes.attribution.attributes.color lowercaseString];
    }
    p.theme = (themeCSS.length == 0) ? [UIColor bonfireGrayWithLevel:800] : [UIColor fromHex:themeCSS];
    
    p.title = @"Link Conversations";
    
    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:p];
    newNavController.transitioningDelegate = [Launcher sharedInstance];
    [newNavController setLeftAction:SNActionTypeBack];
    newNavController.currentTheme = p.theme;
    
    [Launcher push:newNavController animated:YES];
}
+ (void)openPostReply:(Post *)post sender:(UIView *)sender {
    QuickReplyViewController *quickReplyVC = [[QuickReplyViewController alloc] init];
    quickReplyVC.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    quickReplyVC.modalPresentationStyle = UIModalPresentationFullScreen;
    quickReplyVC.replyingTo = post;
    UIView *senderSuperView = sender.superview;
    quickReplyVC.fromCenter = [senderSuperView convertPoint:sender.center toView:senderSuperView.superview];
    [[Launcher activeViewController] presentViewController:quickReplyVC animated:NO completion:^{
        //[self setRootViewController:vc];
    }];
}
+ (void)openCreateCamp {
    CreateCampViewController *c = [[CreateCampViewController alloc] init];
    c.transitioningDelegate = [Launcher sharedInstance];
    [self present:c animated:YES];
}

+ (void)openComposePost:(Camp * _Nullable)camp inReplyTo:(Post * _Nullable)replyingTo withMessage:(NSString * _Nullable)message media:(NSArray * _Nullable)media quotedObject:(NSObject * _Nullable)quotedObject {
    ComposeViewController *epvc = [[ComposeViewController alloc] init];
    epvc.view.tintColor = [UIColor bonfirePrimaryColor];
    epvc.postingIn = camp;
    epvc.replyingTo = replyingTo;
    epvc.prefillMessage = message;
    epvc.quotedObject = quotedObject;
    
    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = [Launcher sharedInstance];
    [newNavController setLeftAction:SNActionTypeCancel];
    [newNavController setRightAction:SNActionTypeShare];
    newNavController.view.tintColor = epvc.view.tintColor;
    newNavController.currentTheme = [UIColor contentBackgroundColor];
    newNavController.opaqueOnScroll = true;
    newNavController.shadowOnScroll = true;
    [self present:newNavController animated:YES];
}
+ (void)openEditProfile {
    EditProfileViewController *epvc = [[EditProfileViewController alloc] init];
    epvc.view.tintColor = [UIColor bonfirePrimaryColor];
    epvc.themeColor = [UIColor fromHex:[[Session sharedInstance] currentUser].attributes.color];

    SimpleNavigationController *newNavController = [[SimpleNavigationController alloc] initWithRootViewController:epvc];
    newNavController.transitioningDelegate = [Launcher sharedInstance];
    newNavController.modalPresentationStyle = UIModalPresentationFullScreen;
    newNavController.opaqueOnScroll = false;
    newNavController.shadowOnScroll = true;
    newNavController.transparentOnLoad = true;
    
    [self present:newNavController animated:YES];
}

+ (void)openInviteFriends:(id)sender {
    [FIRAnalytics logEventWithName:@"invite_friends"
                                    parameters:@{@"sender_class": [sender class]}];
    
    if ([sender isKindOfClass:[Camp class]]) {
        [self shareCamp:sender];
    }
    else {
//        [self shareOniMessage:[NSString stringWithFormat:@"Join me on Bonfire! 🔥 %@", APP_DOWNLOAD_LINK] image:nil];

        InviteFriendsViewController *inviteFriends = [[InviteFriendsViewController alloc] init];
        [self present:inviteFriends animated:YES];
    }
    
    /*
    InviteFriendTableViewController *ifvc = [[InviteFriendTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    if ([sender isKindOfClass:[Camp class]]) {
        // attach camp as object -> add context to message
        ifvc.sender = sender;
    }
    
    UINavigationController *newNavController = [[UINavigationController alloc] initWithRootViewController:ifvc];
    newNavController.launcher;
    newNavController.navigationBar.barStyle = UIBarStyleBlack;
    newNavController.navigationBar.translucent = false;
    [newNavController setNeedsStatusBarAppearanceUpdate];
    
    [self present:newNavController animated:YES];*/
}

+ (void)openInviteToCamp:(Camp *)camp {
    InviteToCampTableViewController *vc = [[InviteToCampTableViewController alloc] init];
    vc.camp = camp;
    
    SimpleNavigationController *navController = [[SimpleNavigationController alloc] initWithRootViewController:vc];
    navController.transitioningDelegate = [Launcher sharedInstance];
    navController.modalPresentationStyle = UIModalPresentationFullScreen;
    navController.currentTheme = [UIColor clearColor];
    
    [self present:navController animated:YES];
}

+ (void)openOnboarding {
    if (![[Launcher activeViewController] isKindOfClass:[HelloViewController class]] &&
        ![[Launcher activeViewController] isKindOfClass:[OnboardingViewController class]]) {
        HelloViewController *vc = [[HelloViewController alloc] init];
        vc.transitioningDelegate = [Launcher sharedInstance];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        
        [[Launcher topMostViewController] presentViewController:vc animated:YES completion:^{

        }];
    }
}
+ (void)setRootViewController:(UIViewController *)rootViewController {
    AppDelegate *ad = (AppDelegate *)[UIApplication sharedApplication].delegate;
    // dismiss presented view controllers before switch rootViewController to avoid messed up view hierarchy, or even crash
    UIViewController *presentedViewController = [Launcher findPresentedViewControllerStartingFrom:ad.window.rootViewController];
    [ad.window setRootViewController:rootViewController];
    [self dismissPresentedViewController:presentedViewController completionBlock:nil];
}
+ (void)dismissPresentedViewController:(UIViewController *)vc completionBlock:(void(^)(void))completionBlock {
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
+ (UIViewController *)findPresentedViewControllerStartingFrom:(UIViewController *)start {
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

+ (void)openSettings {
    SettingsTableViewController *settingsVC = [[SettingsTableViewController alloc] init];
    
    SimpleNavigationController *simpleNav = [[SimpleNavigationController alloc] initWithRootViewController:settingsVC];
    simpleNav.transitioningDelegate = [Launcher sharedInstance];
    [UIView performWithoutAnimation:^{
        [simpleNav setRightAction:SNActionTypeDone];
    }];
    [Launcher present:simpleNav animated:YES];
}

+ (void)openURL:(NSString *)urlString {
    if (![urlString containsString:@"http://"] &&  ![urlString containsString:@"https://"]) {
        urlString = [@"https://" stringByAppendingString:urlString];
    }
    
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    if ([[UIApplication sharedApplication] canOpenURL:url]) {
        launcher.safariVC = [[SFSafariViewController alloc] initWithURL:url];
        launcher.safariVC.delegate = launcher;
        launcher.safariVC.navigationController.navigationBar.tintColor = [UIColor bonfireBrand];
        launcher.safariVC.modalPresentationStyle = UIModalPresentationFullScreen;
        launcher.safariVC.preferredBarTintColor = [UIColor contentBackgroundColor];
        launcher.safariVC.preferredControlTintColor = [UIColor bonfirePrimaryColor];
        //self.safariVC.preferredStatusBarStyle = UIStatusBarStyleDarkContent;
        [[Launcher topMostViewController] presentViewController:launcher.safariVC animated:YES completion:nil];
    }
}
+ (void)safariViewControllerDidFinish:(SFSafariViewController *)controller {
    if ([[Launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
        [[Launcher activeViewController] setNeedsStatusBarAppearanceUpdate];
    }
    else if ([Launcher activeViewController].navigationController) {
        [[Launcher activeViewController].navigationController setNeedsStatusBarAppearanceUpdate];
    }
}

+ (void)openOutOfDateClient {
    OutOfDateClientViewController *c = [[OutOfDateClientViewController alloc] init];
    c.transitioningDelegate = [Launcher sharedInstance];
    [self present:c animated:YES];
}

+ (void)openDebugView:(id)object {
    #ifdef DEBUG
    SimpleNavigationController *navController;
    if ([object isKindOfClass:[JSONModel class]]) {
        // Initialize the view controller
        SEJSONViewController * jsonViewController = [[SEJSONViewController alloc] init];
        jsonViewController.title = NSStringFromClass([object class]);

        // set the data to browse in the controller
        [jsonViewController setData:[(JSONModel *)object toDictionary]];
        
        // display it inside a UINavigationController
        navController = [[SimpleNavigationController alloc] initWithRootViewController:jsonViewController];
    }
    else {
        UIViewController *viewController = [[UIViewController alloc] init];
        viewController.title = NSStringFromClass([object class]);
        viewController.view.backgroundColor = [UIColor contentBackgroundColor];
        UITextView *textView = [[UITextView alloc] initWithFrame:viewController.view.bounds];
        textView.font = [UIFont systemFontOfSize:12.f];
        textView.text = [NSString stringWithFormat:@"%@", object];
        textView.textColor = [UIColor bonfirePrimaryColor];
        textView.editable = false;
        textView.backgroundColor = [UIColor contentBackgroundColor];
        [viewController.view addSubview:textView];
        [textView setContentOffset:CGPointZero];
        
        navController = [[SimpleNavigationController alloc] initWithRootViewController:viewController];
    }
    [navController setRightAction:SNActionTypeDone];
    
    [Launcher present:navController animated:YES];
    
    #endif
}

+ (void)copyBetaInviteLink {
    [FIRAnalytics logEventWithName:@"copy_beta_invite_link"
                        parameters:@{@"location": @"trending_header"}];
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    pasteboard.string = APP_DOWNLOAD_LINK;
    
    JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
    HUD.textLabel.text = @"Copied Beta Link!";
    HUD.vibrancyEnabled = false;
    HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
    HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
    HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
    
    [HUD showInView:[Launcher topMostViewController].view animated:YES];
    [HapticHelper generateFeedback:FeedbackType_Notification_Success];
    
    [HUD dismissAfterDelay:1.5f];
}

+ (void)openActionsForPost:(Post *)post {
    // Three Categories of Post Actions
    // 1) Any user
    // 2) Creator
    // 3) Admin
    BOOL isCreator = ([post.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]);
    BOOL canDelete = isCreator || [post.attributes.context.post.permissions canDelete];
    BOOL insideCamp = ([Launcher activeNavigationController] &&
                       [[[[Launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[CampViewController class]] &&
                       [((CampViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).camp.identifier isEqualToString:post.attributes.postedIn.identifier]);
    
    // Page action can be shown on
    // A) Any page
    // B) Inside Camp
    
    BFAlertController *actionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];
    
    // 1.B.* -- Any user, outside camp, any following state
    if (post.attributes.postedIn == nil) {
        BOOL insideProfile = ([Launcher activeNavigationController] &&
                              [[[[Launcher activeNavigationController] viewControllers] lastObject] isKindOfClass:[ProfileViewController class]] &&
                              [((ProfileViewController *)[[[Launcher activeNavigationController] viewControllers] lastObject]).user.identifier isEqualToString:post.attributes.creator.identifier]);
        if (!insideProfile && ![post.attributes.creator.identifier isEqualToString:[Session sharedInstance].currentUser.identifier]) {
            BFAlertAction *openProfile = [BFAlertAction actionWithTitle:[NSString stringWithFormat:@"View @%@'s Profile", post.attributes.creator.attributes.identifier] style:BFAlertActionStyleDefault handler:^{
                NSLog(@"open camp");
                
                NSError *error;
                User *user = [[User alloc] initWithDictionary:[post.attributes.creator toDictionary] error:&error];
                
                [Launcher openProfile:user];
            }];
            [actionSheet addAction:openProfile];
        }
    }
    else {
        if (!insideCamp) {
            BFAlertAction *openCamp = [BFAlertAction actionWithTitle:@"Open Camp" style:BFAlertActionStyleDefault handler:^{
                NSLog(@"open camp");
                
                NSError *error;
                Camp *camp = [[Camp alloc] initWithDictionary:[post.attributes.postedIn toDictionary] error:&error];
                
                [Launcher openCamp:camp];
            }];
            [actionSheet addAction:openCamp];
        }
    }
    
    // 1.A.* -- Any user, any page, any following state
    #if !TARGET_OS_MACCATALYST
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    if (hasiMessage) {
        BFAlertAction *shareOniMessage = [BFAlertAction actionWithTitle:@"Share on iMessage" style:BFAlertActionStyleDefault handler:^{
            NSString *url = [NSString stringWithFormat:@"https://bonfire.camp/p/%@", post.identifier];
            
            NSString *message;
            if (post.attributes.message.length > 0) {
                message = [NSString stringWithFormat:@"\"%@\" %@", post.attributes.message, url];
            }
            else {
                message = url;
            }
            
            [Launcher shareOniMessage:message image:nil];
        }];
        [actionSheet addAction:shareOniMessage];
    }
    #endif
    
    // 1.A.* -- Any user, any page, any following state
    BFAlertAction *sharePost = [BFAlertAction actionWithTitle:@"Share via..." style:BFAlertActionStyleDefault handler:^{
        NSLog(@"share post");
        
        [Launcher sharePost:post];
    }];
    [actionSheet addAction:sharePost];
    
    // !2.A.* -- Not Creator, any page, any following state
    if (!isCreator) {
        BFAlertAction *reportPost = [BFAlertAction actionWithTitle:@"Report" style:BFAlertActionStyleDefault handler:^{
            NSLog(@"report post");
            // confirm action
            BFAlertController *confirmReportPostActionSheet = [BFAlertController alertControllerWithTitle:@"Report Post" message:@"Are you sure you want to report this post?" preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *confirmReportPost = [BFAlertAction actionWithTitle:@"Report" style:BFAlertActionStyleDestructive handler:^{
                NSLog(@"confirm report post");
                [BFAPI reportPost:post.identifier completion:^(BOOL success, id responseObject) {
                    NSLog(@"reported post!");
                }];
            }];
            [confirmReportPostActionSheet addAction:confirmReportPost];
            
            BFAlertAction *cancelDeletePost = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [confirmReportPostActionSheet addAction:cancelDeletePost];
            
            [[Launcher topMostViewController] presentViewController:confirmReportPostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:reportPost];
    }
    
    // 2|3.A.* -- Creator or camp admin, any page, any following state
    if (canDelete) {
        BFAlertAction *deletePost = [BFAlertAction actionWithTitle:@"Delete" style:BFAlertActionStyleDefault handler:^{
            NSLog(@"delete post");
            // confirm action
            BFAlertController *confirmDeletePostActionSheet = [BFAlertController alertControllerWithTitle:@"Delete Post" message:@"Are you sure you want to delete this post?" preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *confirmDeletePost = [BFAlertAction actionWithTitle:@"Delete" style:BFAlertActionStyleDestructive handler:^{
                JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
                HUD.textLabel.text = @"Deleting...";
                HUD.vibrancyEnabled = false;
                HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
                HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
                [HUD showInView:[Launcher topMostViewController].view animated:YES];
                
                NSLog(@"confirm delete post");
                [BFAPI deletePost:post completion:^(BOOL success, id responseObject) {
                    if (success) {
                        NSLog(@"deleted post!");
                        
                        // success
                        [HUD dismissAfterDelay:0];
                        
                        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                            if ([[Launcher activeViewController] isKindOfClass:[PostViewController class]]) {
                                PostViewController *postVC = (PostViewController *)[Launcher activeViewController];
                                if ([postVC.post.identifier isEqualToString:post.identifier] || [postVC.post.attributes.parent.identifier isEqualToString:post.identifier]) {
                                    if ([Launcher activeNavigationController] && [Launcher activeNavigationController].viewControllers.count > 1) {
                                        [[Launcher activeNavigationController] popViewControllerAnimated:YES];
                                        
                                        if ([[Launcher activeNavigationController] isKindOfClass:[ComplexNavigationController class]]) {
                                            [(ComplexNavigationController *)[Launcher activeNavigationController] goBack];
                                        }
                                    }
                                    else {
                                        [[Launcher activeViewController] dismissViewControllerAnimated:YES completion:nil];
                                    }
                                }
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
            
            BFAlertAction *cancelDeletePost = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
            [confirmDeletePostActionSheet addAction:cancelDeletePost];
            
            [[Launcher topMostViewController] presentViewController:confirmDeletePostActionSheet animated:YES completion:nil];
        }];
        [actionSheet addAction:deletePost];
    }
    
    #ifdef DEBUG
    BFAlertAction *debugPost = [BFAlertAction actionWithTitle:@"Debug Post" style:BFAlertActionStyleDefault handler:^{
        [Launcher openDebugView:post];
    }];
    [actionSheet addAction:debugPost];
    #endif
        
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [actionSheet addAction:cancel];
    
    [[Launcher topMostViewController] presentViewController:actionSheet animated:true completion:nil];
}
+ (void)sharePost:(Post *)post {
    UIImage *image = [Launcher imageForPost:post];
    
    NSString *url = [NSString stringWithFormat:@"https://bonfire.camp/p/%@", post.identifier];
    
    NSString *message;
    if (post.attributes.message.length > 0) {
        message = [NSString stringWithFormat:@"\"%@\" %@", post.attributes.message, url];
    }
    else {
        message = url;
    }
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[message, image] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [[Launcher topMostViewController] presentViewController:controller animated:YES completion:nil];
}
+ (void)openPostActions:(Post *)post {
    BFAlertController *confirmDeletePostActionSheet = [BFAlertController alertControllerWithTitle:nil message:nil preferredStyle:BFAlertControllerStyleActionSheet];
    
    BFAlertAction *quotePost = [BFAlertAction actionWithTitle:@"Quote Post" style:BFAlertActionStyleDefault handler:^{
        [Launcher openComposePost:nil inReplyTo:nil withMessage:nil media:nil quotedObject:post];
    }];
    [confirmDeletePostActionSheet addAction:quotePost];
    
    BFAlertAction *copyLink = [BFAlertAction actionWithTitle:@"Copy link to Post" style:BFAlertActionStyleDefault handler:^{
        NSString *url = [NSString stringWithFormat:@"https://bonfire.camp/p/%@", post.identifier];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = url;
        
        JGProgressHUD *HUD = [JGProgressHUD progressHUDWithStyle:JGProgressHUDStyleExtraLight];
        HUD.indicatorView = [[JGProgressHUDSuccessIndicatorView alloc] init];
        HUD.tintColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.textLabel.text = @"Copied!";
        HUD.vibrancyEnabled = false;
        HUD.animation = [[JGProgressHUDFadeZoomAnimation alloc] init];
        HUD.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.6f];
        HUD.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
        
        [HUD showInView:[Launcher topMostViewController].view animated:YES];
        [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        [HUD dismissAfterDelay:1.5f];
    }];
    [confirmDeletePostActionSheet addAction:copyLink];
    
    BFAlertAction *shareVia = [BFAlertAction actionWithTitle:@"Share via..." style:BFAlertActionStyleDefault handler:^{
        [Launcher sharePost:post];
    }];
    [confirmDeletePostActionSheet addAction:shareVia];
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [confirmDeletePostActionSheet addAction:cancel];
    
    [[Launcher topMostViewController] presentViewController:confirmDeletePostActionSheet animated:true completion:nil];
}
+ (void)shareIdentity:(Identity *)identity {
    UIImage *image;
    if ([identity.type isEqualToString:@"user"]) {
        image = [Launcher imageForUser:(User *)identity];
    }
    else if ([identity.type isEqualToString:@"bot"]) {
        image = [Launcher imageForBot:(Bot *)identity];
    }
    else {
        return;
    }
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[[NSString stringWithFormat:@"https://bonfire.camp/u/%@", identity.attributes.identifier], image] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [[Launcher topMostViewController] presentViewController:controller animated:YES completion:nil];
}
+ (void)shareCamp:(Camp *)camp {
    UIImage *image = [Launcher imageForCamp:camp];
    
    NSString *identifier = camp.attributes.identifier;
    if (identifier.length == 0) {
        identifier = camp.identifier;
    }
    
    UIActivityViewController *controller = [[UIActivityViewController alloc]initWithActivityItems:@[[NSString stringWithFormat:@"https://bonfire.camp/c/%@", identifier], image] applicationActivities:nil];
    controller.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    
    [[Launcher topMostViewController] presentViewController:controller animated:YES completion:nil];
}
#if !TARGET_OS_MACCATALYST
+ (void)shareOniMessage:(NSString *)message image:(UIImage * _Nullable)image {
    BOOL hasiMessage = [MFMessageComposeViewController canSendText];
    
    if (hasiMessage) {
        // confirm action
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init]; // Create message VC
        messageController.messageComposeDelegate = launcher; // Set delegate to current instance
        messageController.modalPresentationStyle = UIModalPresentationFullScreen;
        messageController.view.tintColor = [UIColor bonfirePrimaryColor];
        messageController.body = message; // Set initial text to example message
        
        if (image != nil) {
            NSData *dataImg = UIImagePNGRepresentation(image);//Add the image as attachment
            [messageController addAttachmentData:dataImg typeIdentifier:@"public.data" filename:@"Image.png"];
        }
        
        [[Launcher topMostViewController] presentViewController:messageController animated:YES completion:nil];
    }
}
#endif
+ (UIImage *)imageForPost:(Post *)post {
    CGRect frame = CGRectMake(0, 0, 420, [ExpandedPostCell heightForPost:post width:420]);
    ExpandedPostCell *cell = [[ExpandedPostCell alloc] initWithFrame:frame];
    Post *postMinusVote = [post copy];
    postMinusVote.attributes.context.post.vote = nil;
    cell.post = postMinusVote;
    cell.lineSeparator.hidden = true;
    cell.moreButton.hidden = true;
    
    return [BFTableViewCellExporter imageForCell:cell size:frame.size];
}
+ (UIImage *)imageForCamp:(Camp *)camp {
    CGRect frame = CGRectMake(0, 0, 360, [BFCampAttachmentView heightForCamp:camp width:360]);
    BFCampAttachmentView *campAttachmentView = [[BFCampAttachmentView alloc] initWithCamp:camp frame:frame];
    campAttachmentView.backgroundColor = [UIColor whiteColor];
    
    return [BFTableViewCellExporter imageForView:campAttachmentView];
}
+ (UIImage *)imageForUser:(User *)user {
    CGRect frame = CGRectMake(0, 0, 360, [BFUserAttachmentView heightForUser:user width:360]);
    BFUserAttachmentView *userAttachmentView = [[BFUserAttachmentView alloc] initWithUser:user frame:frame];
    userAttachmentView.backgroundColor = [UIColor whiteColor];
    
    return [BFTableViewCellExporter imageForView:userAttachmentView];
}
+ (UIImage *)imageForBot:(Bot *)bot {
    CGRect frame = CGRectMake(0, 0, 360, [BFBotAttachmentView heightForBot:bot width:360]);
    BFBotAttachmentView *botAttachmentView = [[BFBotAttachmentView alloc] initWithBot:bot frame:frame];
    botAttachmentView.backgroundColor = [UIColor whiteColor];
    
    return [BFTableViewCellExporter imageForView:botAttachmentView];
}

+ (void)expandImageView:(UIImageView *)imageView {
    NSMutableArray *items = @[].mutableCopy;
    
    KSPhotoItem *item = [KSPhotoItem itemWithSourceView:imageView image:imageView.image];
    [items addObject:item];
    
    KSPhotoBrowser *browser = [KSPhotoBrowser browserWithPhotoItems:items selectedIndex:0];
    browser.bounces = true;
    browser.backgroundStyle = KSPhotoBrowserBackgroundStyleBlack;
    browser.dismissalStyle = KSPhotoBrowserInteractiveDismissalStyleSlide;
    browser.modalPresentationCapturesStatusBarAppearance = true;
    [browser showFromViewController:[Launcher topMostViewController]];
}

+ (void)exapndImageView:(UIImageView *)imageView media:(NSArray *)media imageViews:(NSArray <UIImageView *> *)imageViews selectedIndex:(NSInteger)selectedIndex {
    NSMutableArray *items = @[].mutableCopy;
    
    for (int i = 0; i < media.count; i++) {
        KSPhotoItem *item;
        
        if ([media[i] isKindOfClass:[UIImage class]]) {
            UIImage *image = (UIImage *)media[i];
            item = [KSPhotoItem itemWithSourceView:imageViews[i] image:image];
        }
        else if ([media[i] isKindOfClass:[PostAttachmentsMedia class]]) {
            PostAttachmentsMedia *attachmentMedia = (PostAttachmentsMedia *)media[i];
            NSLog(@"media type: %u", attachmentMedia.attributes.type);
            if (!(attachmentMedia.attributes.type == PostAttachmentMediaTypeImage || attachmentMedia.attributes.type == PostAttachmentMediaTypeGIF || attachmentMedia.attributes.type == PostAttachmentMediaTypeVideo)) {
                continue;
            }
            
            if ([self imageViewHasImage:imageViews[i]]) {
                item = [KSPhotoItem itemWithSourceView:imageViews[i] image:imageViews[i].image];
            }
            else {
                item = [KSPhotoItem itemWithSourceView:imageViews[i] imageUrl:[NSURL URLWithString:attachmentMedia.attributes.hostedVersions.suggested.url]];
            }
        }
        
        if (item != nil) {
            [items addObject:item];
        }
    }
    
    if (items.count > 0) {
        KSPhotoBrowser *browser = [KSPhotoBrowser browserWithPhotoItems:items selectedIndex:(selectedIndex < items.count ? selectedIndex : 0)];
        browser.bounces = true;
        browser.backgroundStyle = KSPhotoBrowserBackgroundStyleBlack;
        browser.dismissalStyle = KSPhotoBrowserInteractiveDismissalStyleSlide;
        browser.modalPresentationCapturesStatusBarAppearance = true;
        [browser showFromViewController:[Launcher topMostViewController]];
    }
}
+ (BOOL)imageViewHasImage:(UIImageView *)imageView {
    return !CGSizeEqualToSize(imageView.image.size, CGSizeZero);
}

+ (void)requestAppStoreRating {
    if (@available(iOS 10.3, *)) {
        [SKStoreReviewController requestReview];
    }
}

+ (void)present:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.transitioningDelegate = [Launcher sharedInstance];
    viewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    if ([[Launcher activeViewController].restorationIdentifier isEqualToString:@"launchScreen"]) {
        launcher.launchAction = ^{
            [[Launcher topMostViewController] presentViewController:viewController animated:YES completion:nil];
        };
        
        NSLog(@"we just set the laucnh action");
    }
    else {
        launcher.launchAction = nil;
        
        [[Launcher topMostViewController] presentViewController:viewController animated:YES completion:nil];
    }
}
+ (void)push:(UIViewController *)viewController animated:(BOOL)animated {
    viewController.view.tag = VIEW_CONTROLLER_PUSH_TAG;
    
    if ([[Launcher activeViewController].restorationIdentifier isEqualToString:@"launchScreen"]) {
        [Launcher sharedInstance].launchAction = ^{
            if ([launcher canPush] && ![viewController isKindOfClass:[UINavigationController class]]) {
                [[Launcher activeNavigationController] pushViewController:viewController animated:YES];
            }
            else {
                [self present:viewController animated:YES];
            }
        };
        
        NSLog(@"we just set the launch action");
    }
    else {
        [Launcher sharedInstance].launchAction = nil;
        
        if ([launcher canPush] && ![viewController isKindOfClass:[UINavigationController class]]) {
            [[Launcher activeNavigationController] pushViewController:viewController animated:YES];
        }
        else {
            [self present:viewController animated:YES];
        }
    }
}

#if !TARGET_OS_MACCATALYST
#pragma mark - MFMessageComposeViewControllerDelegate
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
        if ([[Launcher activeViewController] isKindOfClass:[UINavigationController class]]) {
            [[Launcher activeViewController] setNeedsStatusBarAppearanceUpdate];
        }
        else if ([Launcher activeViewController].navigationController) {
            [[Launcher activeViewController].navigationController setNeedsStatusBarAppearanceUpdate];
        }
    }];
}
#endif

#pragma mark - UIViewControllerTransitioningDelegate
// MODAL TRANSITION
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented
    presentingController:(UIViewController *)presenting
    sourceController:(UIViewController *)source
{
    id<UIViewControllerAnimatedTransitioning> animationController;
        
    launcher.animator.appearing = YES;
    launcher.animator.duration = 0.3;
    
    if (presented.view.tag == VIEW_CONTROLLER_PUSH_TAG) {
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
    
    NSLog(@"dismissed view tag: %lu", dismissed.view.tag);
    
    if (dismissed.view.tag == VIEW_CONTROLLER_PUSH_TAG) {
        launcher.animator.direction = SOLTransitionDirectionLeft;
    }
    else {
        launcher.animator.direction = SOLTransitionDirectionUp;
    }
    animationController = launcher.animator;
    
    return animationController;
}

@end
