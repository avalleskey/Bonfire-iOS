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
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "SearchNavigationController.h"
#import "DiscoverViewController.h"
#import "NotificationsTableViewController.h"
#import "SearchTableViewController.h"
#import "FeedViewController.h"
#import "ProfileViewController.h"
#import "CampCardsListCell.h"
#import "MiniAvatarListCell.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "BFNotificationManager.h"

#import <Lockbox/Lockbox.h>
#import <AudioToolbox/AudioServices.h>
#import <Crashlytics/Crashlytics.h>
#import "NSString+Validation.h"
@import Firebase;

@interface AppDelegate ()

@property (nonatomic, strong) Session *session;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupEnvironment];
    
    InsightsLogger *logger = [InsightsLogger sharedInstance];
    [logger closeAllPostInsights];
    
    self.session = [Session sharedInstance];
    
    NSDictionary *accessToken = [self.session getAccessTokenWithVerification:true];
    NSString *refreshToken = self.session.refreshToken;
    NSLog(@"––––– session –––––");
    // NSLog(@"self.session.currentUser: %@", self.session.currentUser.identifier);
    NSLog(@"user id: %@", [Session sharedInstance].currentUser.identifier);
    NSLog(@"access token: %@", accessToken);
    NSLog(@"refresh token:: %@", refreshToken);
    NSLog(@"–––––––––––––––————");
    NSLog(@"apns token:: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]);
    NSLog(@"–––––––––––––––————");
    
    if ((accessToken != nil || refreshToken != nil) && self.session.currentUser.identifier != nil) {
        [self launchLoggedIn];
    }
    else {
        // launch onboarding
        [self launchOnboarding];
    }

    [self.window makeKeyAndVisible];
    
    // Google Analytics
    [FIRApp configure];
    
    #ifdef DEBUG
    NSLog(@"[DEBUG MODE]");
    #else
    NSLog(@"[RELEASE MODE]");
    #endif
    
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
    
    NSLog(@"location y: %f", location.y);
    NSLog(@"statusBarFrame: %f - %f - %f - %f", statusBarFrame.origin.x, statusBarFrame.origin.y, statusBarFrame.size.width, statusBarFrame.size.height);
    
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
    
    NSString *sesssionToken = [NSString stringWithFormat:@"%@", [[Session sharedInstance] getAccessTokenWithVerification:true][@"attributes"][@"access_token"]];
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
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [options addAction:cancel];
    
    [[Launcher topMostViewController] presentViewController:options animated:YES completion:nil];
}

- (void)launchLoggedIn {
    [[Session sharedInstance] getNewAccessToken:^(BOOL success, NSString * _Nonnull newToken) {
        if (success) {
            NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
            launches = launches + 1;
            [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
            
            TabController *tbc = [[TabController alloc] init];
            tbc.delegate = self;
            self.window.rootViewController = tbc;
        }
        else {
            [[Session sharedInstance] signOut];
            
            [self launchOnboarding];
        }
    }];
}

- (void)launchOnboarding {
    if (![self.window.rootViewController isKindOfClass:[HelloViewController class]]) {
        HelloViewController *vc = [[HelloViewController alloc] init];
        vc.fromLaunch = true;
        self.window.rootViewController = vc;
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
    
    NSDate *tokenExpiration = [formatter dateFromString:token[@"attributes"][@"expires_at"]];
    
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
                        [tableViewController.tableView setContentOffset:CGPointMake(0, -tableViewController.tableView.adjustedContentInset.top) animated:YES];
                    }
                }
                
                if ([currentNavigationController.visibleViewController isKindOfClass:[DiscoverViewController class]]) {
                    DiscoverViewController *tableViewController = (DiscoverViewController *)currentNavigationController.visibleViewController;
                    
                    for (NSInteger i = 0; i < [tableViewController.tableView numberOfSections]; i++) {
                        if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]] isKindOfClass:[CampCardsListCell class]]) {
                            CampCardsListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
                            [firstCell.collectionView setContentOffset:CGPointMake(-16, 0) animated:YES];
                        }
                        if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]] isKindOfClass:[MiniAvatarListCell class]]) {
                            MiniAvatarListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
                            [firstCell.collectionView setContentOffset:CGPointMake(-2, 0) animated:YES];
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

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    NSLog(@"continueUserActivity:");
    
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
            FeedType type = [userActivity.userInfo[@"feed"] intValue];
            if (type == FeedTypeTimeline) {
                // timeline
                [Launcher openTimeline];
            }
            else {
                // trending
                [Launcher openTrending];
            }
            
            return true;
        }
    }
    else if ([userActivity.activityType isEqualToString:NSUserActivityTypeBrowsingWeb]) {
        // only allow universal links to be opened if there is a user signed in
        if (![Session sharedInstance].currentUser) {
            return false;
        }
        
        // Universal Links
        NSURL *incomingURL = userActivity.webpageURL;
        NSURLComponents *components = [NSURLComponents componentsWithURL:incomingURL resolvingAgainstBaseURL:true];
        //NSArray<NSURLQueryItem *> *params = components.queryItems;
        NSString *path = components.path;
        
        if (path.length == 0) {
            return false;
        }
        
        NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
        
        // NSLog(@"pathComponents: %@", pathComponents);
        // NSLog(@"path: %@", path);
        // NSLog(@"params: %@", params);
        
        // this should never occur, but don't continue if it does
        // would only occur if given: https://bonfire.camp/
        if (pathComponents.count < 2) return false;
        
        BOOL camp = [pathComponents[1] isEqualToString:@"c"];
        BOOL user = [pathComponents[1] isEqualToString:@"u"];
        BOOL post = [pathComponents[1] isEqualToString:@"p"];
        NSString *parent = pathComponents[2];
        
        /*                     01   2      3      4
         - https://bonfire.camp/c/{camptag}
         - https://bonfire.camp/u/{username}
         - https://bonfire.camp/p/{post_id}
         */
        if (pathComponents.count == 3 && (camp || user || post)) {
            // check for camptag or username
            if (user && [parent validateBonfireUsername] == BFValidationErrorNone) {
                // https://bonfire.camp/u/username
                // valid username
                
                // open username
                User *user = [[User alloc] init];
                UserAttributes *attributes = [[UserAttributes alloc] init];
                UserDetails *details = [[UserDetails alloc] init];
                details.identifier = [parent stringByReplacingOccurrencesOfString:@"@" withString:@""];
                
                attributes.details = details;
                user.attributes = attributes;
                
                NSLog(@"open user: %@", user);
                
                [Launcher openProfile:user];
                
                return true;
            }
            if (camp && [parent validateBonfireCampTag] == BFValidationErrorNone) {
                // https://bonfire.camp/c/camptag
                NSLog(@"valid camp");
                
                Camp *camp = [[Camp alloc] init];
                CampAttributes *attributes = [[CampAttributes alloc] init];
                CampDetails *details = [[CampDetails alloc] init];
                details.identifier = parent;
                
                attributes.details = details;
                camp.attributes = attributes;
                
                NSLog(@"open camp: %@", camp);
                
                [Launcher openCamp:camp];
                
                return true;
            }
            if (post) {
                // https://bonfire.camp/p/{post_id}
                
                if (parent == NULL || parent.length == 0) return false;
                
                // open post
                Post *post =  [[Post alloc] init];
                post.identifier = parent;
                
                NSLog(@"open post: %@", post);
                
                [Launcher openPost:post withKeyboard:false];
                
                return true;
            }
        }
    }
    
    return false;
}


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
            if (userInfo[@"aps"][@"alert"]) {
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
    tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.notificationsNavVC];
    
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

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
    if (!url || ![url.scheme isEqualToString:LOCAL_APP_URI]) {
        return false;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    if ([url.host isEqualToString:@"user"]) {
        User *user = [[User alloc] init];
        UserAttributes *attributes = [[UserAttributes alloc] init];
        UserDetails *details = [[UserDetails alloc] init];
        
        if ([params objectForKey:@"id"]) {
            user.identifier = params[@"id"];
        }
        if ([params objectForKey:@"username"]) {
            details.identifier = params[@"username"];
        }
        
        attributes.details = details;
        user.attributes = attributes;
        
        [Launcher openProfile:user];
    }
    if ([url.host isEqualToString:@"camp"]) {
        Camp *camp = [[Camp alloc] init];
        CampAttributes *attributes = [[CampAttributes alloc] init];
        CampDetails *details = [[CampDetails alloc] init];
        
        if ([params objectForKey:@"id"]) {
            camp.identifier = params[@"id"];
        }
        if ([params objectForKey:@"display_id"]) {
            details.identifier = [params[@"display_id"] stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        
        attributes.details = details;
        camp.attributes = attributes;
        
        [Launcher openCamp:camp];
    }
    if ([url.host isEqualToString:@"post"]) {
        Post *post = [[Post alloc] init];
        if ([params objectForKey:@"id"]) {
            post.identifier = [NSString stringWithFormat:@"%@", params[@"id"]];
        }
        [Launcher openPost:post withKeyboard:NO];
    }
    if ([url.host isEqualToString:@"compose"]) {
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
