//
//  ShareInTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 12/15/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Camp.h"

NS_ASSUME_NONNULL_BEGIN

@protocol PrivacySelectorDelegate <NSObject>

- (void)privacySelectionDidChange:(Camp * _Nullable)selection;

@end

@interface PrivacySelectorTableViewController : UITableViewController

@property (nonatomic, strong) Camp *currentSelection;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, weak) id <PrivacySelectorDelegate> delegate;

@end

NS_ASSUME_NONNULL_END
