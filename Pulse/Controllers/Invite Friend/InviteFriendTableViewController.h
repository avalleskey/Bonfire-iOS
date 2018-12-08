//
//  InviteFriendTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/21/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFSearchView.h"

NS_ASSUME_NONNULL_BEGIN

@interface InviteFriendTableViewController : UITableViewController <UITextFieldDelegate>

@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *saveButton;

@property (strong, nonatomic) UIVisualEffectView *searchBar;
@property (strong, nonatomic) BFSearchView *searchView;
@property (strong, nonatomic) id sender;

@end

NS_ASSUME_NONNULL_END
