//
//  ChangePasswordTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/29/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "SmartListTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface ChangePasswordTableViewController : SmartListTableViewController <SmartListDelegate>

@property (strong, nonatomic) UIBarButtonItem *saveButton;

@end

NS_ASSUME_NONNULL_END
