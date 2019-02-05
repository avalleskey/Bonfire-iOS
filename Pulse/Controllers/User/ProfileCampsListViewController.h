//
//  ProfileCampsListViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/7/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "ThemedTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfileCampsListViewController : ThemedTableViewController

@property (strong, nonatomic) User *user;

@end

NS_ASSUME_NONNULL_END
