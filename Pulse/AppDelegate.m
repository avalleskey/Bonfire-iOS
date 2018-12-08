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
#import "OnboardingViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "SearchNavigationController.h"

#import "MyRoomsViewController.h"
#import "NotificationsTableViewController.h"
#import "SearchTableViewController.h"
#import "FeedViewController.h"
#import "ProfileViewController.h"
#import "MyRoomsListCell.h"
#import <SDWebImageCodersManager.h>
#import <SDWebImageGIFCoder.h>
#import "UIColor+Palette.h"
#import <Tweaks/FBTweakInline.h>

@interface AppDelegate ()

@property (strong, nonatomic) Session *session;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // load cache of user
    // [self.session signOut];
    
    // self.window.layer.cornerRadius = 10.f;
    // self.window.layer.masksToBounds = true;
    
    // Override point for customization after application launch.
    [self setupEnvironment];
    self.session = [Session sharedInstance];
    [[SDWebImageCodersManager sharedInstance] addCoder:[SDWebImageGIFCoder sharedCoder]];
    
    //GAI *gai = [GAI sharedInstance];
    //[gai trackerWithTrackingId:@"UA-121431078-1"];
    
    // gai.trackUncaughtExceptions = YES;
    
    NSDictionary *accessToken = [self.session getAccessTokenWithVerification:true];
    NSString *refreshToken = self.session.refreshToken;
    
    if (accessToken != nil || refreshToken != nil) {
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
    
    return YES;
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
                               alertControllerWithTitle:@"Change Development URL"
                               message:nil
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
    
    
    if ([[UIApplication sharedApplication].keyWindow.rootViewController isKindOfClass:[UINavigationController class]]) {
        [((UINavigationController*)self.window.rootViewController).visibleViewController presentViewController:alert animated:YES completion:nil];
    }
    else {
        [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)launchLoggedIn {
    NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
    launches = launches + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
    
    // User is signed in.
    TabController *tabController = [[TabController alloc] init];
    tabController.delegate = self;
    self.window.rootViewController = tabController;
}

- (void)launchOnboarding {
    if (![self.window.rootViewController isKindOfClass:[OnboardingViewController class]]) {
        OnboardingViewController *onboardingVC = [[OnboardingViewController alloc] init];
        self.window.rootViewController = onboardingVC;
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
                [tableViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
                
                if ([currentNavigationController.visibleViewController isKindOfClass:[MyRoomsViewController class]]) {
                    MyRoomsViewController *tableViewController = (MyRoomsViewController *)currentNavigationController.visibleViewController;
                    
                    if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]] isKindOfClass:[MyRoomsListCell class]]) {
                        MyRoomsListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
                        [firstCell.collectionView setContentOffset:CGPointMake(-16, 0) animated:YES];
                    }
                }
            }
            else if ([currentNavigationController.visibleViewController isKindOfClass:[UIViewController class]]) {
                UIViewController *simpleViewController = (UIViewController *)currentNavigationController.visibleViewController;
                if ([simpleViewController.view viewWithTag:101] && [[simpleViewController.view viewWithTag:101] isKindOfClass:[UIScrollView class]]) {
                    // has a content scroll view
                    UIScrollView *contentScrollView = (UIScrollView *)[simpleViewController.view viewWithTag:101];
                    [contentScrollView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:YES];
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
                NSLog(@"open timeline");
                [[Launcher sharedInstance] openTimeline];
            }
            else {
                // trending
                NSLog(@"open trending");
                [[Launcher sharedInstance] openTrending];
            }
        }
    }
    
    return true;
}

@end
