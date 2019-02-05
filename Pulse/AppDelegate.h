//
//  AppDelegate.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "TabController.h"
@import UIKit;
@import UserNotifications;

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate, UNUserNotificationCenterDelegate>

@property (strong, nonatomic) UIWindow *window;

- (void)launchOnboarding;
- (void)launchLoggedIn;

@end

