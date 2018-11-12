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
#import "OnboardingViewController.h"
#import "LauncherNavigationViewController.h"

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
        NSLog(@"sign out");
        
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
            [self statusBarTouchedAction];
        }
    }
}
- (void)statusBarTouchedAction {
    NSLog(@"status bar touched");
    // use UIAlertController
    UIAlertController *alert= [UIAlertController
                               alertControllerWithTitle:@"Change Development URL"
                               message:nil
                               preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Save" style:UIAlertActionStyleDefault
                                               handler:^(UIAlertAction * action){
                                                   //Do Some action here
                                                   UITextField *textField = alert.textFields[0];
                                                   NSLog(@"text was %@", textField.text);
                                                   
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
                                                   NSLog(@"text was %@", textField.text);
                                                   
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
                                                       
                                                       NSLog(@"cancel btn");
                                                       
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
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    
    NSInteger launches = [[NSUserDefaults standardUserDefaults] integerForKey:@"launches"];
    launches = launches + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:launches forKey:@"launches"];
    
    // User is signed in.
    
    self.window.rootViewController = [storyboard instantiateViewControllerWithIdentifier:@"rootVC"];
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

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
