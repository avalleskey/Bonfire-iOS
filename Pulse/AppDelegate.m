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
#import "StackedOnboardingViewController.h"
#import "ComplexNavigationController.h"
#import "SimpleNavigationController.h"
#import "SearchNavigationController.h"
#import "MyRoomsViewController.h"
#import "NotificationsTableViewController.h"
#import "SearchTableViewController.h"
#import "FeedViewController.h"
#import "ProfileViewController.h"
#import "RoomCardsListCell.h"
#import "MiniRoomsListCell.h"
#import "UIColor+Palette.h"
#import "InsightsLogger.h"

#import <Lockbox/Lockbox.h>
#import <SDWebImageCodersManager.h>
#import <SDWebImageGIFCoder.h>
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
    
    [[SDWebImageCodersManager sharedInstance] addCoder:[SDWebImageGIFCoder sharedCoder]];

    NSDictionary *accessToken = [self.session getAccessTokenWithVerification:true];
    NSString *refreshToken = self.session.refreshToken;
    NSLog(@"refresh token:: %@", refreshToken);
    NSLog(@"access token: %@", accessToken);
    NSLog(@"self.session.currentUser: %@", self.session.currentUser.identifier);
    
    if ((accessToken != nil || refreshToken != nil) && self.session.currentUser.identifier != nil) {
        NSLog(@"do this at least");
        [self launchLoggedIn];
    }
    else {
        // launch onboarding
        NSLog(@"launch onboarding");
        
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
    UITouch *touch = [touches anyObject];
    if (touch.tapCount == 2) {
        // This will cancel the singleTap action
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        if (CGRectContainsPoint(statusBarFrame, location)) {
            if (location.x < [UIScreen mainScreen].bounds.size.width / 2) {
                // left side
            }
            else {
                // right side
                [self statusBarTouchedAction];
            }
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
            
            [[Launcher sharedInstance] openOnboarding];
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
            
            [[[Launcher sharedInstance] activeViewController] presentViewController:alert animated:YES completion:nil];
        }];
        
        [options addAction:changeURL];
    }
    else {
        UIAlertAction *switchToDevelopmentMode = [UIAlertAction actionWithTitle:@"Switch to Development Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [[Session sharedInstance] signOut];
            
            [Configuration switchToDevelopment];
            
            [[Launcher sharedInstance] openOnboarding];
        }];
        [options addAction:switchToDevelopmentMode];
    }
    
    NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
    if (token != nil) {
        UIAlertAction *apnsToken = [UIAlertAction actionWithTitle:@"View APNS Token" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [options dismissViewControllerAnimated:YES completion:nil];
            
            // use UIAlertController
            NSString *token = [[NSUserDefaults standardUserDefaults] stringForKey:@"device_token"];
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
            
            [[[Launcher sharedInstance] activeViewController] presentViewController:alert animated:YES completion:nil];
        }];
        
        [options addAction:apnsToken];
    }
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
    [options addAction:cancel];
    
    [[[Launcher sharedInstance] activeViewController] presentViewController:options animated:YES completion:nil];
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
    if (![self.window.rootViewController isKindOfClass:[StackedOnboardingViewController class]]) {
        StackedOnboardingViewController *vc = [[StackedOnboardingViewController alloc] init];
        vc.fromLaunch = true;
        self.window.rootViewController = vc;
    }
}

- (void)setupEnvironment {
    NSLog(@"Current Configuration > %@", [Configuration configuration]);
    
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
                
                if ([currentNavigationController.visibleViewController isKindOfClass:[MyRoomsViewController class]]) {
                    MyRoomsViewController *tableViewController = (MyRoomsViewController *)currentNavigationController.visibleViewController;
                    
                    for (NSInteger i = 0; i < [tableViewController.tableView numberOfSections]; i++) {
                        if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]] isKindOfClass:[RoomCardsListCell class]]) {
                            RoomCardsListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
                            [firstCell.collectionView setContentOffset:CGPointMake(-16, 0) animated:YES];
                        }
                        if ([[tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]] isKindOfClass:[MiniRoomsListCell class]]) {
                            MiniRoomsListCell *firstCell = [tableViewController.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:i]];
                            [firstCell.collectionView setContentOffset:CGPointMake(-16, 0) animated:YES];
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
    previousController = viewController;
}

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler {
    NSLog(@"continueUserActivity:");
    
    if ([userActivity.activityType isEqualToString:@"com.Ingenious.bonfire.open-room-activity-type"])
    {
        if ([userActivity.userInfo objectForKey:@"room"] &&
            [userActivity.userInfo[@"room"] isKindOfClass:[NSDictionary class]])
        {
            NSError *error;
            Room *room = [[Room alloc] initWithDictionary:userActivity.userInfo[@"room"] error:&error];
            if (!error) {
                [[Launcher sharedInstance] openRoom:room];
                return true;
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
        NSArray<NSURLQueryItem *> *params = components.queryItems;
        NSString *path = components.path;
        
        if (path.length == 0) {
            return false;
        }
        
        NSArray *pathComponents = [path componentsSeparatedByString:@"/"];
        
        NSLog(@"pathComponents: %@", pathComponents);
        NSLog(@"path: %@", path);
        NSLog(@"params: %@", params);
        
        // this should never occur, but don't continue if it does
        // would only occur if given: https://bonfire.camp/
        if (pathComponents.count < 2) return false;
        
        BOOL camp = [pathComponents[1] isEqualToString:@"c"];
        BOOL user = [pathComponents[1] isEqualToString:@"u"];
        NSString *parent = pathComponents[2];
        
        /*                     01   2      3      4
         - https://bonfire.camp/c/{camptag}
         - https://bonfire.camp/u/{username}
         - https://bonfire.camp/c/{camptag}/post/{post_id}
         - https://bonfire.camp/u/{username}/post/{post_id}
         */
        if (pathComponents.count == 3 && (camp || user)) {
            NSLog(@"check for camptag or username");
            if (user && [parent validateBonfireUsername] == BFValidationErrorNone) {
                // https://bonfire.camp/u/username
                NSLog(@"valid username");
                
                // open username
                User *user = [[User alloc] init];
                UserAttributes *attributes = [[UserAttributes alloc] init];
                UserDetails *details = [[UserDetails alloc] init];
                details.identifier = [parent stringByReplacingOccurrencesOfString:@"@" withString:@""];
                
                attributes.details = details;
                user.attributes = attributes;
                
                NSLog(@"user: %@", user);
                
                [[Launcher sharedInstance] openProfile:user];
                
                return true;
            }
            if (camp && [parent validateBonfireRoomTag] == BFValidationErrorNone) {
                // https://bonfire.camp/c/camptag
                NSLog(@"valid room");
                
                Room *room = [[Room alloc] init];
                RoomAttributes *attributes = [[RoomAttributes alloc] init];
                RoomDetails *details = [[RoomDetails alloc] init];
                details.identifier = parent;
                
                attributes.details = details;
                room.attributes = attributes;
                
                NSLog(@"room: %@", room);
                
                [[Launcher sharedInstance] openRoom:room];
                
                return true;
            }
        }
        else if (pathComponents.count == 5 && (camp || user)) {
            // https://bonfire.camp/#camptag/post/{post_id}
            // https://bonfire.camp/@username/post/{post_id}
            BOOL isPost = [pathComponents[3] isEqualToString:@"post"];
            
            NSLog(@"isPost? %@", isPost ? @"YES" : @"NO");
            if (!isPost) return false;
            
            NSInteger postId = [pathComponents[4] integerValue];
            NSLog(@"postId: %ld", (long)postId);
            if (postId == 0) return false;
            
            // open post
            Post *post =  [[Post alloc] init];
            post.identifier = postId;
            PostAttributes *attributes = [[PostAttributes alloc] init];
            
            if (user && [parent validateBonfireUsername] == BFValidationErrorNone) {
                // https://bonfire.camp/u/username
                NSLog(@"valid username");
                
                // open username
                User *user = [[User alloc] init];
                UserAttributes *userAttributes = [[UserAttributes alloc] init];
                UserDetails *userDetails = [[UserDetails alloc] init];
                userDetails.identifier = [parent stringByReplacingOccurrencesOfString:@"@" withString:@""];
                
                userAttributes.details = userDetails;
                user.attributes = userAttributes;
                
                PostDetails *details = [[PostDetails alloc] init];
                details.creator = user;
                attributes.details = details;
            }
            if (camp && [parent validateBonfireRoomTag] == BFValidationErrorNone) {
                // https://bonfire.camp/c/camptag
                NSLog(@"valid room");
                
                Room *room = [[Room alloc] init];
                RoomAttributes *roomAttributes = [[RoomAttributes alloc] init];
                RoomDetails *roomDetails = [[RoomDetails alloc] init];
                roomDetails.identifier = parent;
                
                roomAttributes.details = roomDetails;
                room.attributes = roomAttributes;
                
                PostStatus *status = [[PostStatus alloc] init];
                status.postedIn = room;
                attributes.status = status;
            }
            post.attributes = attributes;
            
            NSLog(@"post to open: %@", post);
            
            [[Launcher sharedInstance] openPost:post withKeyboard:false];
            return true;
        }
    }
    
    return false;
}


- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    if ([[Launcher sharedInstance].activeTabController isKindOfClass:[TabController class]]) {
        NSLog(@"userInfo: %@", userInfo);
        TabController *tabVC = [Launcher sharedInstance].tabController;
        
        NSString *badgeValue = [NSString stringWithFormat:@"%@", [[userInfo objectForKey:@"aps"] objectForKey:@"badge"]];
        [tabVC setBadgeValue:badgeValue forItem:tabVC.notificationsNavVC.tabBarItem];
        if (badgeValue && badgeValue.length > 0 && [badgeValue intValue] > 0) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"RemoteNotificationReceived" object:nil userInfo:userInfo];
    }
}

// notifications
- (void)userNotificationCenter:(UNUserNotificationCenter* )center willPresentNotification:(UNNotification* )notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions options))completionHandler {
    //For notification Banner - when app in foreground
    completionHandler(UNNotificationPresentationOptionNone);
}
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[deviceToken description] stringByTrimmingCharactersInSet: [NSCharacterSet characterSetWithCharactersInString:@"<>"]];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];

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
