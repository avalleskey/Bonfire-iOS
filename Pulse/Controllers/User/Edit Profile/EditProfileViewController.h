//
//  EditProfileViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemeSelectorCell.h"
#import "User.h"
#import "ThemedTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditProfileViewController : ThemedTableViewController <ThemeSelectorDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UIImageView *coverPhotoView;

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@property (strong, nonatomic) UIColor *themeColor;

@property (strong, nonatomic) User *user;

@end

NS_ASSUME_NONNULL_END
