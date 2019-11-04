//
//  AppDelegate.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "AppDelegate.h"

#import "Session.h"
#import "Launcher.h"
#import "HelloViewController.h"
#import "MyCampsTableViewController.h"
#import "NotificationsTableViewController.h"
#import "MyFeedViewController.h"
#import "CampCardsListCell.h"
#import "MiniAvatarListCell.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "BFNotificationManager.h"

#import <Lockbox/Lockbox.h>
#import <AudioToolbox/AudioServices.h>
#import <Crashlytics/Crashlytics.h>
#import "NSString+Validation.h"
#import <PINCache/PINCache.h>
#import <Shimmer/FBShimmeringView.h>
@import Firebase;

@interface AppDelegate ()

@property (nonatomic, strong) Session *session;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupEnvironment];
    
    self.session = [Session sharedInstance];
    
    NSDictionary *accessToken = [self.session getAccessTokenWithVerification:true];
    NSString *refreshToken = self.session.refreshToken;
    NSLog(@"––––– Session –––––");
    // NSLog(@"self.session.currentUser: %@", self.session.currentUser.identifier);
    NSLog(@"🙎‍♂️ @%@ (id: %@)", [Session sharedInstance].currentUser.attributes.identifier, [Session sharedInstance].currentUser.identifier);
    NSLog(@"🔑 Access token  : %@", accessToken);
    NSLog(@"🌀 Refresh token : %@", refreshToken);
    NSLog(@"🔔 APNS token    : %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]);
    NSLog(@"–––––––––––––––————");

    // show loading
    UIViewController *launchScreen = [[UIStoryboard storyboardWithName:@"LaunchScreen" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"launchScreen"];
    self.window.rootViewController = launchScreen;
    [self.window makeKeyAndVisible];
    
    if ((accessToken != nil || refreshToken != nil) && self.session.currentUser.identifier != nil) {
        [self launchLoggedInWithCompletion:^(BOOL success) {
            if (![[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]) {
                // no apns -> let's check again
                [self requestNotifications];
            }
        }];
    }
    else {
        // launch onboarding
        NSLog(@"launch onboarding");
        [self launchOnboarding];
    }
    
    [FIRApp configure];
    #ifdef DEBUG
    NSLog(@"[DEBUG MODE]");
    #else
    NSLog(@"[RELEASE MODE]");
    // Google Analytics
    //[FIRApp configure];
    #endif
    
    InsightsLogger *logger = [InsightsLogger sharedInstance];
    [logger closeAllPostInsights];
    
    [self setupRoundedCorners];
    
    return YES;
}

- (void)setupRoundedCorners {
    if (!HAS_ROUNDED_CORNERS) {
        [self continuityRadiusForView:[[UIApplication sharedApplication] keyWindow] withRadius:8.f];
    }
}

#pragma mark - Status bar touch tracking
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    #ifdef DEBUG
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    statusBarFrame.origin.x = [UIScreen mainScreen].bounds.size.width / 2 - (100 / 2);
    statusBarFrame.origin.y = statusBarFrame.size.height;
    statusBarFrame.size.width = 100;
    statusBarFrame.size.height = 44;
    
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2) {
        // This will cancel the singleTap action
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        if (CGRectContainsPoint(statusBarFrame, location)) {
            [self statusBarTouchedAction];
        }
    }
    #endif
}

- (void)statusBarTouchedAction {
    BOOL isDevelopment = [Configuration isDevelopment];
    UIAlertController *options = [UIAlertController alertControllerWithTitle:@"Internal Tools" message:(isDevelopment ? @"Bonfire Development" : @"Bonfire Production") preferredStyle:UIAlertControllerStyleAlert];
    
    if (isDevelopment) {
        UIAlertAction *switchToProduction = [UIAlertAction actionWithTitle:@"Switch to Production Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[Session sharedInstance] signOut];
            
            [Configuration switchToProduction];
            
            [Launcher openOnboarding];
        }];
        [options addAction:switchToProduction];
        
        UIAlertAction *changeURL = [UIAlertAction actionWithTitle:@"Set API URL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use UIAlertController
            UIAlertController *alert= [UIAlertController
                                       alertControllerWithTitle:@"Set API"
                                       message:@"Enter the base URI used when prefixing any API requests in the app."
                                       preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){
                                                           //Do Some action here
                                                           UITextField *textField = alert.textFields[0];
                                                           
                                                           [Configuration replaceDevelopmentURIWith:textField.text];
                                                       }];
            UIAlertAction *saveAndQuit = [UIAlertAction actionWithTitle:@"Save & Quit" style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * action){
                                                                    //Do Some action here
                                                                    UITextField *textField = alert.textFields[0];
                                                                    
                                                                    [Configuration replaceDevelopmentURIWith:textField.text];
                                                                    
                                                                    exit(0);
                                                                }];
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            
            [alert addAction:cancel];
            [alert addAction:ok];
            [alert addAction:saveAndQuit];
            
            [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
                textField.placeholder = @"Development Base URI";
                textField.text = [Configuration DEVELOPMENT_BASE_URI];
                textField.keyboardType = UIKeyboardTypeURL;
            }];
            
            [[Launcher activeViewController] presentViewController:alert animated:YES completion:nil];
        }];
        
        [options addAction:changeURL];
    }
    else {
        UIAlertAction *switchToDevelopmentMode = [UIAlertAction actionWithTitle:@"Switch to Development Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[Session sharedInstance] signOut];
            
            [Configuration switchToDevelopment];
            
            [Launcher openOnboarding];
        }];
        [options addAction:switchToDevelopmentMode];
    }
    
    NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
    if (token != nil) {
        UIAlertAction *apnsToken = [UIAlertAction actionWithTitle:@"View APNS Token" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use UIAlertController
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"APNS Token"
                                        message:token
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){
                                                           UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                           pasteboard.string = token;
                                                       }];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            
            [alert addAction:cancel];
            [alert addAction:ok];
            
            [[Launcher activeViewController] presentViewController:alert animated:YES completion:nil];
        }];
        
        [options addAction:apnsToken];
    }
    
    NSString *sesssionToken = [NSString stringWithFormat:@"%@", [[Session sharedInstance] getAccessTokenWithVerification:true][@"access_token"]];
    if (sesssionToken.length > 0) {
        UIAlertAction *apnsToken = [UIAlertAction actionWithTitle:@"View Access Token" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use UIAlertController
            UIAlertController *alert = [UIAlertController
                                        alertControllerWithTitle:@"Access Token"
                                        message:sesssionToken
                                        preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){
                                                           UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                           pasteboard.string = sesssionToken;
                                                       }];
            
            UIAlertAction *imessage = [UIAlertAction actionWithTitle:@"iMessage" style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction * action){
                                                           [Launcher shareOniMessage:sesssionToken image:nil];
                                                       }];
            
            UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
                                                           handler:^(UIAlertAction * action) {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            
            [alert addAction:cancel];
            [alert addAction:imessage];
            [alert addAction:ok];
            
            [[Launcher activeViewController] presentViewController:alert animated:YES completion:nil];
        }];
        
        [options addAction:apnsToken];
    }
    
    UIAlertAction *clearCache = [UIAlertAction actionWithTitle:@"Clear Home Cache" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[PINCache sharedCache] removeAllObjects];
    }];
    [options addAction:clearCache];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [options addAction:cancel];
    
    [[Launcher topMostViewController] presentViewController:options animated:YES completion:nil];
}

- (void)launchLoggedInWithCompletion:(void (^_Nullable)(BOOL success))handler; {
    [[Session sharedInstance] getNewAccessToken:^(BOOL success, NSString * _Nonnull newToken) {
        if (success) {
            NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
            launches = launches + 1;
            [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
            
            [Launcher launchLoggedIn:false replaceRootViewController:true];
        }
        else {
            [[Session sharedInstance] signOut];
            
            [Launcher openOnboarding];
            
            handler(false);
        }
    }];
}

- (void)launchOnboarding {
    NSLog(@"self.window.rootviewController: %@", [self.window.rootViewController isKindOfClass:[HelloViewController class]] ? @"YES" : @"NO");
    if (![self.window.rootViewController isKindOfClass:[HelloViewController class]]) {
        HelloViewController *vc = [[HelloViewController alloc] init];
        vc.fromLaunch = true;
        self.window.rootViewController = vc;
        [self.window makeKeyAndVisible];
    }
}

- (void)setupEnvironment {
    // NSLog(@"Current Configuration > %@", [Configuration configuration]);
    
    // clear app's keychain on first launch
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kHasLaunchedBefore"]) {
        [Lockbox archiveObject:nil forKey:@"auth_token"];
        [Lockbox archiveObject:nil forKey:@"login_token"];
    }
}

    
- (NSDictionary *)verifyToken:(NSDictionary *)token {
    NSDate *now = [NSDate date];
    
    // compare dates to make sure both are still active
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *tokenExpiration = [formatter dateFromString:token[@"expires_at"]];
    
    NSLog(@"token app version: %@", token[@"app_version"]);
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([now compare:tokenExpiration] == NSOrderedDescending || ![token[@"app_version"] isEqualToString:version]) {
        // loginExpiration in the future
        token = nil;
        // NSLog(@"token is expired");
        
        if (![token[@"app_version"] isEqualToString:version]) {
            NSLog(@"app version has changed (%@ -> %@)", token[@"app_version"], version);
        }
    }
    
    return token;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    if ([viewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)viewController visibleViewController] isKindOfClass:[NotificationsTableViewController class]]) {
        [(TabController *)(Launcher.activeTabController) setBadgeValue:nil forItem:viewController.tabBarItem];
    }
    
    static UIViewController *previousController = nil;
    if (previousController == viewController) {
        // the same tab was tapped a second time
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *currentNavigationController = (UINavigationController *)viewController;
            if ([currentNavigationController.visibleViewController isKindOfClass:[UITableViewController class]]) {
                UITableViewController *tableViewController = (UITableViewController *)currentNavigationController.visibleViewController;
                
                if (currentNavigationController.navigationBar.prefersLargeTitles) {
                    [tableViewController.tableView setContentOffset:CGPointMake(0, -140) animated:YES];
                    [tableViewController.tableView reloadData];
                    [tableViewController.tableView layoutIfNeeded];
                    [tableViewController.tableView setContentOffset:CGPointZero animated:YES];
                    
                    [tableViewController.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:([tableViewController.tableView numberOfRowsInSection:0] > 0 ? 0 : 1)] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
                else {
                    if ([tableViewController.tableView isKindOfClass:[RSTableView class]]) {
                        [(RSTableView *)tableViewController.tableView scrollToTop];
                    }
                    else {
                        [tableViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
                    }
                }
                
                if ([currentNavigationController.visibleViewController isKindOfClass:[MyFeedViewController class]]) {
                    if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] isKindOfClass:[MiniAvatarListCell class]]) {
                        MiniAvatarListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                        [firstCell.collectionView setContentOffset:CGPointMake(-2, 0) animated:YES];
                    }
                }
                if ([currentNavigationController.visibleViewController isKindOfClass:[MyCampsTableViewController class]]) {
                    MyCampsTableViewController *tableViewController = (MyCampsTableViewController *)currentNavigationController.visibleViewController;
                    
                    for (NSInteger i = 0; i < [tableViewController.tableView numberOfSections]; i++) {
                        if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]] isKindOfClass:[CampCardsListCell class]]) {
                            CampCardsListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
                            [firstCell.collectionView setContentOffset:CGPointMake(-12, 0) animated:YES];
                        }
                    }
                }
            }
            else if ([currentNavigationController.visibleViewController isKindOfClass:[UIViewController class]]) {
                UIViewController *simpleViewController = (UIViewController *)currentNavigationController.visibleViewController;
                if ([simpleViewController.view viewWithTag:101] && [[simpleViewController.view viewWithTag:101] isKindOfClass:[UITableView class]]) {
                    // has a content scroll view
                    UITableView *contentScrollView = (UITableView *)[simpleViewController.view viewWithTag:101];
                    
                    [contentScrollView setContentOffset:CGPointMake(0, -contentScrollView.adjustedContentInset.top) animated:YES];
                }
            }
        }
    }
    else {
        [(TabController *)([Launcher activeTabController]) showPillIfNeeded];
    }
    
    previousController = viewController;
}

//- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
//    NSLog(@"hellllooooooo");
//
//    NSArray *tabViewControllers = tabBarController.viewControllers;
//    UIView *selectedView = tabBarController.selectedViewController.view;
//    UIView *fromView = [selectedView snapshotViewAfterScreenUpdates:true];
//    UIView *toView = viewController.view;
//    [tabBarController.view insertSubview:fromView belowSubview:tabBarController.tabBar];
//    if (fromView == toView)
//        return false;
//    NSUInteger fromIndex = [tabViewControllers indexOfObject:tabBarController.selectedViewController];
//    NSUInteger toIndex = [tabViewControllers indexOfObject:viewController];
//
//    BOOL fromRight = toIndex < fromIndex;
//    fromView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, fromView.center.y);
//    toView.center = CGPointMake([UIScreen mainScreen].bounds.size.width * (fromRight ? -.5 : 1.5), toView.center.y);
//    [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
//        fromView.center = CGPointMake([UIScreen mainScreen].bounds.size.width * (fromRight ? 1.5 : -.5), fromView.center.y);
//        toView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, toView.center.y);
//    } completion:^(BOOL finished) {
//        if (finished && selectedView == tabBarController.selectedViewController.view) {
//           tabBarController.selectedIndex = toIndex;
//            [fromView removeFromSuperview];
//       }
//    }];
//
//    return true;
//}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    // only open if there is a user signed in
    if (![Session sharedInstance].currentUser) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoteNotificationReceived" object:nil userInfo:userInfo];
    
    if ([Launcher tabController]) {
        NSLog(@"userInfo: %@", userInfo);
        TabController *tabVC = [Launcher tabController];
        
        NSString *badgeValue = @"1"; //[NSString stringWithFormat:@"%@", [[userInfo objectForKey:@"aps"] objectForKey:@"badge"]];
        [tabVC setBadgeValue:badgeValue forItem:tabVC.notificationsNavVC.tabBarItem];
        if (badgeValue && badgeValue.length > 0 && [badgeValue intValue] > 0) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
    }
        
    if(application.applicationState == UIApplicationStateActive) {
        // app is currently active, can update badges count here
        NSLog(@"UIApplicationStateActive: tapped notificaiton to open");
        //For notification Banner - when app in foreground
        
        NSString *title;
        NSString *message;
        USER_ACTIVITY_TYPE activityType = 0;
        if (userInfo[@"aps"]) {
            if (userInfo[@"aps"][@"alert"] && [userInfo[@"aps"][@"alert"] isKindOfClass:[NSDictionary class]]) {
                if (userInfo[@"aps"][@"alert"][@"title"]) {
                    title = userInfo[@"aps"][@"alert"][@"title"];
                }
                
                if (userInfo[@"aps"][@"alert"][@"body"]) {
                    message = userInfo[@"aps"][@"alert"][@"body"];
                }
            }
            else if ([userInfo[@"aps"][@"alert"] isKindOfClass:[NSString class]]) {
                message = userInfo[@"aps"][@"alert"];
            }
            
            if (userInfo[@"aps"][@"category"]) {
                activityType = (USER_ACTIVITY_TYPE)[userInfo[@"aps"][@"category"] integerValue];
            }
        }
        
        BFNotificationObject *notificationObject = [BFNotificationObject notificationWithActivityType:activityType title:title text:message action:^{
            NSLog(@"notification tapped");
            [self handleNotificationActionForUserInfo:userInfo];
        }];
        [[BFNotificationManager manager] presentNotification:notificationObject completion:^{
            NSLog(@"presentNotification() completion");
        }];
    }
    else if(application.applicationState == UIApplicationStateInactive) {
        // app is transitioning from background to foreground (user taps notification), do what you need when user taps here
        NSLog(@"UIApplicationStateInactive: tapped notificaiton to open app");
        
        [self handleNotificationActionForUserInfo:userInfo];
    }
}

- (void)handleNotificationActionForUserInfo:(NSDictionary *)userInfo {
    TabController *tabVC = Launcher.tabController;
    if (tabVC) {
        tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.notificationsNavVC];
        [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.notificationsNavVC.tabBarItem];
    }
    
    NSDictionary *data = userInfo[@"data"];
    NSDictionary *formats = [Session sharedInstance].defaults.notifications;
    NSString *key = [NSString stringWithFormat:@"%@", userInfo[@"aps"][@"category"]];
    
    if ([[formats allKeys] containsObject:key]) {
        NSError *error;
        DefaultsNotificationsFormat *notificationFormat = [[DefaultsNotificationsFormat alloc] initWithDictionary:formats[key] error:&error];
        if (!error) {
            if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_ACTIONER] && [data objectForKey:@"actioner"]) {
                User *user = [[User alloc] initWithDictionary:data[@"actioner"] error:nil];
                [Launcher openProfile:user];
            }
            else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_POST] && [data objectForKey:@"post"]) {
                Post *post = [[Post alloc] initWithDictionary:data[@"post"] error:nil];
                [Launcher openPost:post withKeyboard:NO];
            }
            else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_REPLY_POST] && [data objectForKey:@"reply_post"]) {
                Post *post = [[Post alloc] initWithDictionary:data[@"reply_post"] error:nil];
                [Launcher openPost:post withKeyboard:NO];
            }
            else if ([notificationFormat.actionObject isEqualToString:ACTIVITY_ACTION_OBJECT_CAMP] && [data objectForKey:@"camp"]) {
                Camp *camp = [[Camp alloc] initWithDictionary:data[@"camp"] error:nil];
                [Launcher openCamp:camp];
            }
        }
    }
}

// notifications
- (void)userNotificationCenter:(UNUserNotificationCenter* )center willPresentNotification:(UNNotification* )notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    completionHandler(UNNotificationPresentationOptionNone);
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    NSLog(@"token:: %@", token);

    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] == nil || ([[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] != nil &&
        ![[[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] isEqualToString:token]))
    {
        [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"device_token"];
        [[Session sharedInstance] syncDeviceToken];
    }
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    center.delegate = self;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationsDidRegister" object:token];
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    // NSLog(@"failed to register for remote notifications with error: %@", error);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"NotificationsDidFailToRegister" object:error];
}

- (void)requestNotifications {
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert|UNAuthorizationOptionSound|UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        // 1. check if permisisons granted
        if (granted) {
            [[UIApplication sharedApplication] registerForRemoteNotifications];
        }
    }];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[InsightsLogger sharedInstance] closeAllPostInsights];
}
- (void)applicationWillTerminate:(UIApplication *)application {
    [[InsightsLogger sharedInstance] closeAllPostInsights];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}


- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    NSLog(@"continueUserActivity:");
    
    // handle external URL actions
    
    if ([userActivity.activityType isEqualToString:@"com.Ingenious.bonfire.open-camp-activity-type"])
    {
        // only open if there is a user signed in
        if (![Session sharedInstance].currentUser) {
            return false;
        }
        
        if ([userActivity.userInfo objectForKey:@"camp"] &&
            [userActivity.userInfo[@"camp"] isKindOfClass:[NSDictionary class]])
        {
            NSError *error;
            Camp *camp = [[Camp alloc] initWithDictionary:userActivity.userInfo[@"camp"] error:&error];
            if (!error) {
                [Launcher openCamp:camp];
                return true;
            }
        }
    }
    else if ([userActivity.activityType isEqualToString:@"com.Ingenious.bonfire.open-feed-timeline"])
    {
        // only open if there is a user signed in
        if (![Session sharedInstance].currentUser) {
            return false;
        }
        
        if ([userActivity.userInfo objectForKey:@"feed"])
        {
            [Launcher openTimeline];
            
            return true;
        }
    }
    else if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        // only allow universal links to be opened if there is a user signed in
        if (![Session sharedInstance].currentUser) {
            return false;
        }
        
        // Universal Links
        id objectFromURL = [Configuration objectFromExternalBonfireURL:userActivity.webpageURL];
        
        if ([objectFromURL isKindOfClass:[User class]]) {
            [Launcher openProfile:(User *)objectFromURL];
        }
        if ([objectFromURL isKindOfClass:[Camp class]]) {
            [Launcher openCamp:(Camp *)objectFromURL];
        }
        if ([objectFromURL isKindOfClass:[Post class]]) {
            [Launcher openPost:(Post *)objectFromURL withKeyboard:NO];
        }
    }
    
    return false;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    BOOL internalURL = [Configuration isInternalURL:url];
    BOOL externalURL = [Configuration isExternalBonfireURL:url];
    if (!internalURL && !externalURL) {
        return false;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    id objectFromURL;
    if (internalURL) {
        objectFromURL = [Configuration objectFromInternalURL:url];
    }
    else {
        objectFromURL = [Configuration objectFromExternalBonfireURL:url];
    }
    
    if ([objectFromURL isKindOfClass:[User class]]) {
        [Launcher openProfile:(User *)objectFromURL];
    }
    else if ([objectFromURL isKindOfClass:[Camp class]]) {
        [Launcher openCamp:(Camp *)objectFromURL];
    }
    else if ([objectFromURL isKindOfClass:[Post class]]) {
        [Launcher openPost:(Post *)objectFromURL withKeyboard:NO];
    }
    else if (internalURL && [url.host isEqualToString:@"compose"]) {
        Camp *camp;
        if ([params objectForKey:@"camp_id"]) {
            camp = [[Camp alloc] init];
            camp.identifier = params[@"camp_id"];
        }
        
        Post *replyingTo;
        if ([params objectForKey:@"replying_to_post_id"]) {
            replyingTo = [[Post alloc] init];
            replyingTo.identifier = [NSString stringWithFormat:@"%@", params[@"replying_to_post_id"]];
        }
        
        NSString *message;
        if ([params objectForKey:@"message"]) {
            message = params[@"message"];
        }
        
        [Launcher openComposePost:camp inReplyTo:replyingTo withMessage:message media:nil];
    }
    
    return true;
}

@end
