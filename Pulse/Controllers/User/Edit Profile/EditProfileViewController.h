//
//  EditProfileViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThemeSelectorCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditProfileViewController : UITableViewController

@property (strong, nonatomic) UIView *navigationBackgroundView;

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@property (strong, nonatomic) UIColor *themeColor;

- (void)updateBarColor:(id)newColor withAnimation:(int)animationType statusBarUpdateDelay:(CGFloat)statusBarUpdateDelay;

@end

NS_ASSUME_NONNULL_END
