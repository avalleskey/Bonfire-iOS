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
#import "HomeTableViewController.h"
#import "CampCardsListCell.h"
#import "MiniAvatarListCell.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"
#import "BFNotificationManager.h"
#import "BFMiniNotificationManager.h"
#import "BFAlertController.h"
#import "ResetPasswordViewController.h"
#import "HAWebService.h"
#import "BFComponentSectionTableView.h"

#import <Lockbox/Lockbox.h>
#import <AudioToolbox/AudioServices.h>
#import "NSString+Validation.h"
#import <PINCache/PINCache.h>
#import <Shimmer/FBShimmeringView.h>
#import "UIApplication+CFABackgroundTask.h"

@import Firebase;

@interface AppDelegate () <CrashlyticsDelegate>

@property (nonatomic, strong) Session *session;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupEnvironment];
    
    [UNUserNotificationCenter currentNotificationCenter].delegate = self;
    
    self.session = [Session sharedInstance];
    
    NSDictionary *accessToken = [self.session getAccessTokenWithVerification:true];
    NSString *refreshToken = self.session.refreshToken;
    DSpacer();
    // NSLog(@"self.session.currentUser: %@", self.session.currentUser.identifier);
    DSimpleLog(@"[🙎‍♂️] @%@ (id: %@)", [Session sharedInstance].currentUser.attributes.identifier, [Session sharedInstance].currentUser.identifier);
    DSimpleLog(@"[🔑] Access token : %@", accessToken);
    DSimpleLog(@"[🌀] Refresh token : %@", refreshToken);
    DSimpleLog(@"[🔔] APNS token : %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]);
    DSpacer();

    // show loading
    UIViewController *launchScreen = [[UIStoryboard storyboardWithName:@"LaunchScreen" bundle:[NSBundle mainBundle]] instantiateViewControllerWithIdentifier:@"launchScreen"];
    self.window.rootViewController = launchScreen;
    [self.window makeKeyAndVisible];
    
    if ((accessToken != nil || refreshToken != nil) && self.session.currentUser.identifier != nil) {
        [self launchLoggedInWithCompletion:nil];
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
    #endif
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // run on background thread
        InsightsLogger *logger = [InsightsLogger sharedInstance];
        [logger closeAllPostInsights];
    });
    
    [self setupRoundedCorners];
    
    return YES;
}

// network monitoring
- (void)applicationWillEnterForeground:(UIApplication *)application {
    if ([Launcher tabController]) {
        NSArray *notificationNavVCViewControllers = [Launcher tabController].notificationsNavVC.viewControllers;
        if (notificationNavVCViewControllers.count > 0 && [[notificationNavVCViewControllers firstObject] isKindOfClass:[NotificationsTableViewController class]]) {
            // check if there are any new notifications and update the tab bar
            [((NotificationsTableViewController *)[notificationNavVCViewControllers firstObject]) refreshIfNeeded];
        }
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"applicationWillEnterForeground" object:nil];
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
    BFAlertController *options = [BFAlertController alertControllerWithIcon:[UIImage imageNamed:@"alert_icon_settings"] title:@"Internal Tools" message:(isDevelopment ? @"Bonfire Development" : @"Bonfire Production") preferredStyle:BFAlertControllerStyleAlert];
    
    if (isDevelopment) {
        BFAlertAction *switchToProduction = [BFAlertAction actionWithTitle:@"Switch to Production Mode" style:BFAlertActionStyleDefault handler:^{
            [[Session sharedInstance] signOut];
            
            [Configuration switchToProduction];
            
            [Launcher openOnboarding];
        }];
        [options addAction:switchToProduction];
        
        BFAlertAction *changeURL = [BFAlertAction actionWithTitle:@"Set API URL" style:BFAlertActionStyleDefault handler:^{
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use BFAlertController
            BFAlertController *alert= [BFAlertController
                                       alertControllerWithTitle:@"Set API"
                                       message:@"Enter the base URI used when prefixing API requests."
                                       preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *ok = [BFAlertAction actionWithTitle:@"Save" style:BFAlertActionStyleDefault
                                                       handler:^(){
                                                           //Do Some action here
                                                           UITextField *textField = alert.textField;
                                                           
                                                           [Configuration replaceDevelopmentURIWith:textField.text];
                                                       }];
            BFAlertAction *saveAndQuit = [BFAlertAction actionWithTitle:@"Save & Quit" style:BFAlertActionStyleDefault
                                                                handler:^(){
                                                                    //Do Some action here
                                                                    UITextField *textField = alert.textField;
                                                                    
                                                                    [Configuration replaceDevelopmentURIWith:textField.text];
                                                                    
                                                                    exit(0);
                                                                }];
            BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel
                                                           handler:^() {
                                                               [alert dismissViewControllerAnimated:YES completion:nil];
                                                           }];
            
            [alert addAction:ok];
            [alert addAction:saveAndQuit];
            [alert addAction:cancel];
            
            UITextField *textField = [UITextField new];
            textField.placeholder = @"Development Base URI";
            textField.text = [Configuration DEVELOPMENT_BASE_URI];
            textField.keyboardType = UIKeyboardTypeURL;
            [alert setTextField:textField];
            [textField becomeFirstResponder];
            
            [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
        }];
        
        [options addAction:changeURL];
    }
    else {
        BFAlertAction *switchToDevelopmentMode = [BFAlertAction actionWithTitle:@"Switch to Development Mode" style:BFAlertActionStyleDefault handler:^{
            [[Session sharedInstance] signOut];
            
            [Configuration switchToDevelopment];
            
            [Launcher openOnboarding];
        }];
        [options addAction:switchToDevelopmentMode];
    }
    
    NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
    if (token != nil) {
        BFAlertAction *apnsToken = [BFAlertAction actionWithTitle:@"View APNS Token" style:BFAlertActionStyleDefault handler:^{
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use BFAlertController
            BFAlertController *alert = [BFAlertController
                                        alertControllerWithTitle:@"APNS Token"
                                        message:token
                                        preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *ok = [BFAlertAction actionWithTitle:@"Copy" style:BFAlertActionStyleDefault
                                                       handler:^{
                                                           UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                           pasteboard.string = token;
                                                       }];
            
            BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel
                                                           handler:nil];
            
            [alert addAction:ok];
            [alert addAction:cancel];
            
            [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
        }];
        
        [options addAction:apnsToken];
    }
    
    NSString *sesssionToken = [NSString stringWithFormat:@"%@", [[Session sharedInstance] getAccessTokenWithVerification:true][@"access_token"]];
    if (sesssionToken.length > 0) {
        BFAlertAction *apnsToken = [BFAlertAction actionWithTitle:@"View Access Token" style:BFAlertActionStyleDefault handler:^{
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use BFAlertController
            BFAlertController *alert = [BFAlertController
                                        alertControllerWithTitle:@"Access Token"
                                        message:sesssionToken
                                        preferredStyle:BFAlertControllerStyleAlert];
            
            BFAlertAction *copy = [BFAlertAction actionWithTitle:@"Copy" style:BFAlertActionStyleDefault
                                                       handler:^{
                                                           UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
                                                           pasteboard.string = sesssionToken;
                                                       }];
            
            BFAlertAction *imessage = [BFAlertAction actionWithTitle:@"iMessage" style:BFAlertActionStyleDefault
                                                       handler:^{
                                                           [Launcher shareOniMessage:sesssionToken image:nil];
                                                       }];
            
            BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel
                                                           handler:nil];
            
            [alert addAction:imessage];
            [alert addAction:copy];
            [alert addAction:cancel];
            
            [[Launcher topMostViewController] presentViewController:alert animated:true completion:nil];
        }];
        
        [options addAction:apnsToken];
    }
    
    BFAlertAction *clearCache = [BFAlertAction actionWithTitle:@"Clear Cache" style:BFAlertActionStyleDefault handler:^{
        [[PINCache sharedCache] removeAllObjects];
    }];
    [options addAction:clearCache];
    
    BFAlertAction *cancel = [BFAlertAction actionWithTitle:@"Cancel" style:BFAlertActionStyleCancel handler:nil];
    [options addAction:cancel];
    
    [[Launcher topMostViewController] presentViewController:options animated:true completion:nil];
}

- (void)launchLoggedInWithCompletion:(void (^_Nullable)(BOOL success))handler {
    [[Session sharedInstance] getNewAccessToken:^(BOOL success, NSString * _Nonnull newToken) {
        if (success) {
            NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
            launches = launches + 1;
            [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
                        
            NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
            NSString *version = [infoDict objectForKey:@"CFBundleShortVersionString"];
            NSString *buildNumber = [infoDict objectForKey:@"CFBundleVersion"];
            NSString *newVersion = [NSString stringWithFormat:@"%@b%@", version, buildNumber?buildNumber:@"0"];
           
            DLog(@"last version: %@", [[NSUserDefaults standardUserDefaults] stringForKey:@"app_last_version"]);
            DLog(@"newVersion: %@", newVersion);
            
            BOOL versionChange = ![[[NSUserDefaults standardUserDefaults] stringForKey:@"app_last_version"] isEqualToString:newVersion];
            BOOL requestNotifications = (![[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"]) || versionChange;
            
            if (requestNotifications) {
                wait(2.f, ^{
                    [Launcher requestNotifications];
                });
            }
            
            if (versionChange) {
                [[NSUserDefaults standardUserDefaults] setObject:newVersion forKey:@"app_last_version"];
                
                [[PINCache sharedCache] removeAllObjects];
            }
            
            [Launcher launchLoggedIn:false replaceRootViewController:true];
            
            if (handler) {
                handler(true);
            }
        }
        else {
            [[Session sharedInstance] signOut];
            
            [Launcher openOnboarding];
            
            if (handler) {
                handler(false);
            }
        }
    }];
}

- (void)launchOnboarding {
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
    static UIViewController *previousController = nil;
    
    if (!previousController) {
        previousController = tabBarController.selectedViewController;
    }
    
    if (previousController == viewController) {
        // the same tab was tapped a second time
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *currentNavigationController = (UINavigationController *)viewController;
            UITableView *tableView;
            if ([currentNavigationController.visibleViewController isKindOfClass:[UITableViewController class]]) {
                tableView = ((UITableViewController *)currentNavigationController.visibleViewController).tableView;
            }
            else if ([currentNavigationController.visibleViewController isKindOfClass:[ThemedTableViewController class]]) {
                tableView = [((ThemedTableViewController *)currentNavigationController.visibleViewController) activeTableView];
            }
            else if ([currentNavigationController.visibleViewController isKindOfClass:[ProfileViewController class]]) {
                tableView = ((ProfileViewController *)currentNavigationController.visibleViewController).tableView;
            }
            
            if ([currentNavigationController.visibleViewController isKindOfClass:[NotificationsTableViewController class]]) {
                // check if there are any new notifications and update the tab bar
                [((NotificationsTableViewController *)currentNavigationController.visibleViewController) markAllAsRead];
            }
            
            if (tableView) {
                if (currentNavigationController.navigationBar.prefersLargeTitles) {
                    [tableView setContentOffset:CGPointMake(0, -140) animated:YES];
                    [tableView reloadData];
                    [tableView layoutIfNeeded];
                    [tableView setContentOffset:CGPointZero animated:YES];
                    
                    [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:([tableView numberOfRowsInSection:0] > 0 ? 0 : 1)] atScrollPosition:UITableViewScrollPositionTop animated:YES];
                }
                else {
                    if ([currentNavigationController.visibleViewController isKindOfClass:[HomeTableViewController class]]) {
                        HomeTableViewController *homeVC = (HomeTableViewController *)(currentNavigationController.visibleViewController);
                        [homeVC hideMorePostsIndicator:true];
                    }
                    
                    if ([tableView isKindOfClass:[RSTableView class]]) {
                        [(RSTableView *)tableView scrollToTop];
                    }
                    else if ([tableView isKindOfClass:[BFComponentSectionTableView class]]) {
                        [(BFComponentSectionTableView *)tableView scrollToTop];
                    }
                    else {
                        [tableView reloadData];
                        
                        for (NSInteger s = 0; s < [tableView numberOfSections]; s++) {
                            if ([tableView numberOfRowsInSection:s] > 0) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSIndexPath *rowIndexPath = [NSIndexPath indexPathForRow:0 inSection:s];
                                    [tableView scrollToRowAtIndexPath:rowIndexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                                });
                                break;
                            }
                        }
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
        }
    }
    else {
        [(TabController *)([Launcher activeTabController]) showPillIfNeeded];
    }
    
    previousController = viewController;
}

- (void)handleNotificationActionForUserInfo:(NSDictionary *)userInfo {    
    TabController *tabVC = Launcher.tabController;
    if (tabVC) {
        tabVC.selectedIndex = [tabVC.viewControllers indexOfObject:tabVC.notificationsNavVC];
        [tabVC tabBar:tabVC.tabBar didSelectItem:tabVC.notificationsNavVC.tabBarItem];
    }
    
    NSDictionary *data = userInfo[@"data"];
    
    NSObject *object = [data objectForKey:@"target_object"];
    NSString *urlString = [data objectForKey:@"target_url"];
    NSURL *url = [NSURL URLWithString:urlString];
    BOOL appCanOpenURL = ([Configuration isExternalBonfireURL:url] || [Configuration isInternalURL:url]);
    
    if (object && [object isKindOfClass:[NSDictionary class]] && [(NSDictionary *)object objectForKey:@"type"]) {
        NSDictionary *dict = (NSDictionary *)object;
        NSString *type = [dict objectForKey:@"type"];
        if ([type isEqualToString:@"camp"]) {
            Camp *camp = [[Camp alloc] initWithDictionary:dict error:nil];
            [Launcher openCamp:camp];
        }
        else if ([type isEqualToString:@"post"]) {
            Post *post = [[Post alloc] initWithDictionary:dict error:nil];
            [Launcher openPost:post withKeyboard:false];
        }
        else if ([type isEqualToString:@"user"]) {
            User *user = [[User alloc] initWithDictionary:dict error:nil];
            [Launcher openProfile:user];
        }
        else if ([type isEqualToString:@"bot"]) {
            Bot *bot = [[Bot alloc] initWithDictionary:dict error:nil];
            [Launcher openBot:bot];
        }
    }
    else if (appCanOpenURL) {
        [self application:[UIApplication sharedApplication] openURL:url options:@{}];
    }
    else if (urlString && urlString.length > 0) {
        // the URL is not a known Bonfire URL, so open it in a Safari VC
        [Launcher openURL:urlString];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    NSLog( @"Handle push from background or closed" );
    // if you set a member variable in didReceiveRemoteNotification, you  will know if this is from closed or background
    NSLog(@"%@", response.notification.request.content.userInfo);
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    
    [self handleNotificationActionForUserInfo:userInfo];
}

- (void)userNotificationCenter:(UNUserNotificationCenter* )center willPresentNotification:(UNNotification* )notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    NSLog( @"Handle push from foreground" );
    
    NSDictionary *userInfo = notification.request.content.userInfo;
    
    // only open if there is a user signed in
    if (![Session sharedInstance].currentUser) {
        return;
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoteNotificationReceived" object:nil userInfo:userInfo];
    
    if ([Launcher tabController]) {
        NSLog(@"userInfo: %@", userInfo);
        TabController *tabVC = [Launcher tabController];
        
        if ([userInfo objectForKey:@"aps"] && [userInfo[@"aps"] objectForKey:@"badge"]) {
            [tabVC setBadgeValue:[userInfo[@"aps"] objectForKey:@"badge"] forItem:tabVC.notificationsNavVC.tabBarItem];
        }
        else {
            [tabVC setBadgeValue:@"1" forItem:tabVC.notificationsNavVC.tabBarItem];
        }
        
        NSArray *notificationNavVCViewControllers = [Launcher tabController].notificationsNavVC.viewControllers;
        if (notificationNavVCViewControllers.count > 0 && [[notificationNavVCViewControllers firstObject] isKindOfClass:[NotificationsTableViewController class]]) {
            // check if there are any new notifications and update the tab bar
            [((NotificationsTableViewController *)[notificationNavVCViewControllers firstObject]) refresh];
        }
    }
    
    UIApplication *application = [UIApplication sharedApplication];
        
    if (application.applicationState == UIApplicationStateActive) {
        // app is currently active, can update badges count here
        NSLog(@"UIApplicationStateActive: tapped notificaiton to open");
        
        //For notification Banner - when app in foreground
        if (![[Launcher activeViewController] isKindOfClass:[NotificationsTableViewController class]]) {
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
        
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
    }
    else if(application.applicationState == UIApplicationStateInactive) {
        // app is transitioning from background to foreground (user taps notification), do what you need when user taps here
        NSLog(@"UIApplicationStateInactive: tapped notificaiton to open app");
        
        [self handleNotificationActionForUserInfo:userInfo];
    }
    
    completionHandler(UNNotificationPresentationOptionBadge);
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    const unsigned *tokenBytes = [deviceToken bytes];
    NSString *token = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                          ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                          ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                          ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    NSLog(@"token:: %@", token);
    
    [[NSUserDefaults standardUserDefaults] setObject:token forKey:@"device_token"];
    
    #ifdef DEBUG
    #else
    [[Session sharedInstance] syncDeviceToken];
    #endif
    
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
    
    if ([Launcher activeViewController] && [[Launcher activeViewController] isKindOfClass:[HomeTableViewController class]]) {
        [[Launcher activeViewController].view endEditing:false];
    }
    
    // Start the background task
    CFABackgroundTask *task = [UIApplication cfa_backgroundTask];
    [[HAWebService manager].session getTasksWithCompletionHandler:^(NSArray<NSURLSessionDataTask *> * _Nonnull dataTasks, NSArray<NSURLSessionUploadTask *> * _Nonnull uploadTasks, NSArray<NSURLSessionDownloadTask *> * _Nonnull downloadTasks) {
        DLog(@"data tasks: %@", dataTasks);
        DLog(@"upload tasks: %@", uploadTasks);
        DLog(@"data tasks: %@", downloadTasks);
        
        if (dataTasks.count > 0 || uploadTasks.count > 0 || downloadTasks.count > 0) {
            DLog(@"more than one active data task !!!");
            
            for (NSURLSessionDataTask *task in dataTasks) {
                DLog(@"resume this data task!!!");
                DLog(@"state:: %lu", task.state);
                [task resume];
            }
            for (NSURLSessionDataTask *task in uploadTasks) {
                DLog(@"resume this upload task!!!");
                DLog(@"state:: %lu", task.state);
                [task resume];
            }
            for (NSURLSessionDataTask *task in downloadTasks) {
                DLog(@"resume this download task!!!");
                DLog(@"state:: %lu", task.state);
                [task resume];
            }
            
            // Wait 5 seconds….
            float delayInSeconds = 15.f;
            DLog(@"delay time: %f", delayInSeconds);
            
            dispatch_time_t delayTimer = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
            dispatch_after(delayTimer, dispatch_get_main_queue(), ^(void){
                DLog(@"Application state: %ld", [[UIApplication sharedApplication] applicationState]);
                DLog(@"Background Time Remaining: %0.1f", [[UIApplication sharedApplication] backgroundTimeRemaining]);
                
                // End the task
                [task invalidate];
            });
        }
        else {
            DLog(@"no data tasks to resume");
            [task invalidate];
        }
    }];
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
    NSLog(@"useractivity.activitytype: %@", userActivity.activityType);
    
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
    
    BOOL signedIn = [Session sharedInstance].currentUser;
    
    id objectFromURL;
    if (internalURL) {
        objectFromURL = [Configuration objectFromInternalURL:url];
    }
    else {
        objectFromURL = [Configuration objectFromExternalBonfireURL:url];
    }
    
    if (signedIn && [objectFromURL isKindOfClass:[Identity class]]) {
        [Launcher openIdentity:(Identity *)objectFromURL];
    }
    else if (signedIn && [objectFromURL isKindOfClass:[Camp class]]) {
        [Launcher openCamp:(Camp *)objectFromURL];
    }
    else if (signedIn && [objectFromURL isKindOfClass:[Post class]]) {
        [Launcher openPost:(Post *)objectFromURL withKeyboard:NO];
    }
    else if (signedIn && internalURL && [url.host isEqualToString:@"compose"]) {
        NSString *message;
        if ([params objectForKey:@"message"]) {
            message = params[@"message"];
        }
        
        [Launcher openComposePost:nil inReplyTo:nil withMessage:message media:nil quotedObject:nil];
    }
    else if (signedIn && internalURL && [url.host isEqualToString:@"settings"]) {
        [Launcher openSettings];
    }
    else if (internalURL && [url.host isEqualToString:@"reset_password"]) {
        if ([[Launcher activeViewController] isKindOfClass:[ResetPasswordViewController class]]) {
            // already open
            DLog(@"reset password view controller is already open..!");
            if ([url.path isEqualToString:@"/confirm"] && [params objectForKey:@"code"]) {
                DLog(@"prefill with code: %@", params[@"code"]);
                ((ResetPasswordViewController *)[Launcher activeViewController]).prefillCode = params[@"code"];
            }
        }
        else {
            ResetPasswordViewController *resetPasswordVC = [[ResetPasswordViewController alloc] init];
            if ([url.path isEqualToString:@"/confirm"] && [params objectForKey:@"code"]) {
                resetPasswordVC.prefillCode = params[@"code"];
            }
            [Launcher present:resetPasswordVC animated:YES];
        }
    }
    
    return true;
}

@end
