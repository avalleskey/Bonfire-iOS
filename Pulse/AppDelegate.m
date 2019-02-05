//
//  AppDelegate.m
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "AppDelegate.h"
#import <Lockbox/Lockbox.h>
#import "Session.h"
#import "Launcher.h"
#import "SignInViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "SearchNavigationController.h"

#import "MyRoomsViewController.h"
#import "NotificationsTableViewController.h"
#import "SearchTableViewController.h"
#import "FeedViewController.h"
#import "ProfileViewController.h"
#import "RoomCardsListCell.h"
#import <SDWebImageCodersManager.h>
#import <SDWebImageGIFCoder.h>
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>
#import "InsightsLogger.h"

#define IS_IPHONE_X ([[UIScreen mainScreen] bounds].size.height==812)
#define IS_IPHONE_MAX ([[UIScreen mainScreen] bounds].size.height==896)
#define IS_IPHONE_XR ([[UIScreen mainScreen] bounds].size.height==896)
#define HAS_ROUNDED_CORNERS (IS_IPHONE_X || IS_IPHONE_MAX || IS_IPHONE_XR)

@interface AppDelegate ()

@property (strong, nonatomic) Session *session;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupEnvironment];
    
    InsightsLogger *logger = [InsightsLogger sharedInstance];
    [logger closeAllPostInsights];
    
    self.session = [Session sharedInstance];
    
    
    [[SDWebImageCodersManager sharedInstance] addCoder:[SDWebImageGIFCoder sharedCoder]];
    
    //GAI *gai = [GAI sharedInstance];
    //[gai trackerWithTrackingId:@"UA-121431078-1"];
    
    // gai.trackUncaughtExceptions = YES;
    
    NSDictionary *accessToken = [self.session getAccessTokenWithVerification:true];
    NSString *refreshToken = self.session.refreshToken;
    
    if ((accessToken != nil || refreshToken != nil) && self.session.currentUser.identifier != nil) {
        [self launchLoggedIn];
    }
    else {
        [self.session signOut];
    
        [self launchOnboarding];
    }

    [self.window makeKeyAndVisible];
    
    // [self setupLaunchAnimation];
    
    #ifdef DEBUG
    // debug only code
    NSLog(@"[DEBUG MODE]");
    //gai.logger.logLevel = kGAILogLevelError;
    //[[GAI sharedInstance] setDryRun:YES];
    #else
    NSLog(@"[RELEASE MODE]");
    // release only code
    // gai.logger.logLevel = kGAILogLevelNone;
    #endif
    
    //[self setupRoundedCorners];
    
    return YES;
}

- (void)setupRoundedCorners {
    if (HAS_ROUNDED_CORNERS) {
        [self continuityRadiusForView:[[UIApplication sharedApplication] keyWindow] withRadius:32.f];
    }
    else {
        [self continuityRadiusForView:[[UIApplication sharedApplication] keyWindow] withRadius:8.f];
    }
}

#pragma mark - Status bar touch tracking
- (void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    
    CGPoint location = [[[event allTouches] anyObject] locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2) {
        // This will cancel the singleTap action
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        if (CGRectContainsPoint(statusBarFrame, location)) {
            if (location.x < [UIScreen mainScreen].bounds.size.width / 2) {
                // left side
                [[Launcher sharedInstance] openTweaks];
            }
            else {
                // right side
                [self statusBarTouchedAction];
            }
        }
    }
}
- (void)statusBarTouchedAction {
    // use UIAlertController
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"Set API"
                               message:@"Enter in the URL that you would like to prefix any API requests in the app."
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
                                                   //Do Some action here
                                                   UITextField *textField = alert.textFields[0];
                                                   
                                                   // save new development url
                                                   NSMutableDictionary *config = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"config"]];
                                                   NSMutableDictionary *configDevelopment = [[NSMutableDictionary alloc] initWithDictionary:config[@"development"]];
                                                   [configDevelopment setObject:textField.text forKey:@"API_BASE_URI"];
                                                   [config setObject:configDevelopment forKey:@"development"];
                                                   
                                                   [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"config"];
                                               }];
    UIAlertAction *saveAndQuit = [UIAlertAction actionWithTitle:@"Save & Quit" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
                                                   //Do Some action here
                                                   UITextField *textField = alert.textFields[0];
                                                   
                                                   // save new development url
                                                   NSMutableDictionary *config = [[NSMutableDictionary alloc] initWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"config"]];
                                                   NSMutableDictionary *configDevelopment = [[NSMutableDictionary alloc] initWithDictionary:config[@"development"]];
                                                   [configDevelopment setObject:textField.text forKey:@"API_BASE_URI"];
                                                   [config setObject:configDevelopment forKey:@"development"];
                                                   
                                                   [[NSUserDefaults standardUserDefaults] setObject:config forKey:@"config"];
                                                   
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
        textField.placeholder = @"Development URL";
        textField.text = [[NSUserDefaults standardUserDefaults] dictionaryForKey:@"config"][@"development"][@"API_BASE_URI"];
        textField.keyboardType = UIKeyboardTypeURL;
    }];
    
    [[[Launcher sharedInstance] activeViewController] presentViewController:alert animated:YES completion:nil];
}

- (void)launchLoggedIn {
    NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
    launches = launches + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
    
    TabController *tbc = [[TabController alloc] init];
    tbc.delegate = self;
    self.window.rootViewController = tbc;
}

- (void)launchOnboarding {
    if (![self.window.rootViewController isKindOfClass:[SignInViewController class]]) {
        SignInViewController *vc = [[SignInViewController alloc] init];
        vc.fromLaunch = true;
        self.window.rootViewController = vc;
    }
}

- (void)setupEnvironment {
    [[NSUserDefaults standardUserDefaults] setObject:@"development" forKey:@"environment"];
    
    // clear app's keychain on first launch
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"kFirstLaunch"]) {
        [Lockbox archiveObject:nil forKey:@"auth_token"];
        [Lockbox archiveObject:nil forKey:@"login_token"];
        
        [[NSUserDefaults standardUserDefaults] setBool:TRUE forKey:@"kFirstLaunch"];
        
        [[NSUserDefaults standardUserDefaults] setObject:@{@"development": @{
                                                                   @"API_BASE_URI": @"http://192.168.1.82:3120",
                                                                   @"API_CURRENT_VERSION": @"v1",
                                                                   @"API_KEY": @"999fc321-6924-478d-e66b-4ec06180f843"
                                                                   },
                                                           @"production": @{
                                                                   @"API_BASE_URI": @"https://api.hallway.app",
                                                                   @"API_CURRENT_VERSION": @"v1",
                                                                   @"API_KEY": @"53783d81-a647-4447-b9fe-fdb3723e0664"
                                                                   }
                                                           } forKey:@"config"];
    }
}

    
- (NSDictionary *)verifyToken:(NSDictionary *)token {
    NSDate *now = [NSDate date];
    
    // compare dates to make sure both are still active
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    
    NSDate *tokenExpiration = [formatter dateFromString:token[@"attributes"][@"expires_at"]];
    
    NSString *version = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    if ([now compare:tokenExpiration] == NSOrderedDescending || ![token[@"app_version"] isEqualToString:version]) {
        // loginExpiration in the future
        token = nil;
        //        NSLog(@"token is expired");
    }
    
    return token;
}

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    static UIViewController *previousController = nil;
    if (previousController == viewController) {
        // the same tab was tapped a second time
        if ([viewController isKindOfClass:[UINavigationController class]]) {
            UINavigationController *currentNavigationController = (UINavigationController *)viewController;
            if ([currentNavigationController.visibleViewController isKindOfClass:[UITableViewController class]]) {
                UITableViewController *tableViewController = (UITableViewController *)currentNavigationController.visibleViewController;
                
                if (currentNavigationController.navigationBar.prefersLargeTitles) {
                    [tableViewController.tableView scrollRectToVisible:CGRectMake(0, -64, 1, 1) animated:YES];
                }
                else {
                    [tableViewController.tableView setContentOffset:CGPointMake(0, -tableViewController.tableView.adjustedContentInset.top) animated:YES];
                }
                
                if ([currentNavigationController.visibleViewController isKindOfClass:[MyRoomsViewController class]]) {
                    MyRoomsViewController *tableViewController = (MyRoomsViewController *)currentNavigationController.visibleViewController;
                    
                    if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] isKindOfClass:[RoomCardsListCell class]]) {
                        RoomCardsListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                        [firstCell.collectionView setContentOffset:CGPointMake(-16, 0) animated:YES];
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
    previousController = viewController;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    if ([userActivity.activityType isEqualToString:@"com.Ingenious.bonfire.open-room-activity-type"])
    {
        if ([userActivity.userInfo objectForKey:@"room"] &&
            [userActivity.userInfo[@"room"] isKindOfClass:[NSDictionary class]])
        {
            NSError *error;
            Room *room = [[Room alloc] initWithDictionary:userActivity.userInfo[@"room"] error:&error];
            if (!error) {
                [[Launcher sharedInstance] openRoom:room];
            }
        }
    }
    else if ([userActivity.activityType isEqualToString:@"com.Ingenious.bonfire.open-feed-timeline"] ||
             [userActivity.activityType isEqualToString:@"com.Ingenious.bonfire.open-feed-trending"])
    {
        if ([userActivity.userInfo objectForKey:@"feed"])
        {
            FeedType type = [userActivity.userInfo[@"feed"] intValue];
            if (type == FeedTypeTimeline) {
                // timeline
                [[Launcher sharedInstance] openTimeline];
            }
            else {
                // trending
                [[Launcher sharedInstance] openTrending];
            }
        }
    }
    
    return true;
}

// notifications
- (void)userNotificationCenter:(UNUserNotificationCenter* )center willPresentNotification:(UNNotification* )notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    //For notification Banner - when app in foreground
    completionHandler(UNNotificationPresentationOptionAlert);
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];

    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] != nil &&
        ![[[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"] isEqualToString:token])
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
    if (!url || ![url.scheme isEqualToString:@"bonfireapp"]) {
        return false;
    }
    
    NSURLComponents *components = [NSURLComponents componentsWithString:url.absoluteString];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    for(NSURLQueryItem *item in components.queryItems)
    {
        [params setObject:item.value forKey:item.name];
    }
    
    NSLog(@"let's open this url ya?!");
    NSLog(@"url: %@", url);
    if ([url.host isEqualToString:@"user"]) {
        User *user = [[User alloc] init];
        UserAttributes *attributes = [[UserAttributes alloc] init];
        UserDetails *details = [[UserDetails alloc] init];
        
        if ([params objectForKey:@"id"]) {
            user.identifier = params[@"id"];
        }
        if ([params objectForKey:@"username"]) {
            details.identifier = params[@"username"];
            NSLog(@"username: %@", params[@"username"]);
        }
        
        attributes.details = details;
        user.attributes = attributes;
        
        NSLog(@"user.attributes.details.identifier: %@", user.attributes.details.identifier);
        
        NSLog(@"open user: %@", user);
        [[Launcher sharedInstance] openProfile:user];
    }
    if ([url.host isEqualToString:@"camp"]) {
        Room *room = [[Room alloc] init];
        RoomAttributes *attributes = [[RoomAttributes alloc] init];
        RoomDetails *details = [[RoomDetails alloc] init];
        
        if ([params objectForKey:@"id"]) {
            room.identifier = params[@"id"];
        }
        if ([params objectForKey:@"display_id"]) {
            NSLog(@"display id: %@", params[@"display_id"]);
            details.identifier = [params[@"display_id"] stringByReplacingOccurrencesOfString:@"#" withString:@""];
        }
        
        attributes.details = details;
        room.attributes = attributes;
        
        NSLog(@"room: %@", room);
        
        [[Launcher sharedInstance] openRoom:room];
    }
    if ([url.host isEqualToString:@"post"]) {
        Post *post = [[Post alloc] init];
        if ([params objectForKey:@"id"]) {
            post.identifier = [params[@"id"] integerValue];
        }
        [[Launcher sharedInstance] openPost:post withKeyboard:NO];
    }
    if ([url.host isEqualToString:@"compose"]) {
        Room *room;
        if ([params objectForKey:@"camp_id"]) {
            room = [[Room alloc] init];
            room.identifier = params[@"camp_id"];
        }
        
        Post *replyingTo;
        if ([params objectForKey:@"replying_to_post_id"]) {
            replyingTo = [[Post alloc] init];
            replyingTo.identifier = [params[@"replying_to_post_id"] integerValue];
        }
        
        NSString *message;
        if ([params objectForKey:@"message"]) {
            message = params[@"message"];
        }
        
        [[Launcher sharedInstance] openComposePost:room inReplyTo:replyingTo withMessage:message media:nil];
    }
    
    return true;
}

@end
