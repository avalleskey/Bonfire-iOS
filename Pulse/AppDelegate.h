//
//  AppDelegate.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//
 
@import UIKit;
#import "TabController.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, UITabBarControllerDelegate>

@property (strong, nonatomic) UIWindow *window;
- (void)launchOnboarding;

- (void)launchLoggedIn;
- (TabController *)createTabBarController;

@end

