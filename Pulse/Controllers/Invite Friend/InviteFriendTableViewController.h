//
//  InviteFriendTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface InviteFriendTableViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@property (strong, nonatomic) UIVisualEffectView *searchBar;
@property (strong, nonatomic) UITextField *searchField;

@end

NS_ASSUME_NONNULL_END
