//
//  EditCampViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camp.h"
#import "ThemeSelectorCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface EditCampViewController : UITableViewController <ThemeSelectorDelegate>

@property (nonatomic, strong) Camp *camp;

@property (nonatomic, strong) UIView *navigationBackgroundView;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *saveButton;

@property (nonatomic, strong) UIColor *themeColor;

@end

NS_ASSUME_NONNULL_END
