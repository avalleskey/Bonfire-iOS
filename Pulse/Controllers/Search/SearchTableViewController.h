//
//  SearchTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/30/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SearchNavigationController.h"

NS_ASSUME_NONNULL_BEGIN

@interface SearchTableViewController : UITableViewController <UITextFieldDelegate, SearchNavigationControllerDelegate>

@property (nonatomic) CGFloat currentKeyboardHeight;

@property (strong, nonatomic) SearchNavigationController *searchController;

@end

NS_ASSUME_NONNULL_END
