//
//  ModifyDefaultsViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 10/24/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModifyDefaultsViewController : UITableViewController

- initWithData:(id) data;
- (void) setData:(id)data;

@property (strong, nonatomic) UIView *navigationBackgroundView;

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@property (strong, nonatomic) UIColor *themeColor;

@end

NS_ASSUME_NONNULL_END
