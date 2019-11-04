//
//  AddManagerTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 3/5/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "ThemedTableViewController.h"
#import "Camp.h"
#import "BFSearchView.h"
#import "BFVisualErrorView.h"

NS_ASSUME_NONNULL_BEGIN

@interface AddManagerTableViewController : ThemedTableViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (nonatomic, strong) BFVisualErrorView *errorView;

@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) BFSearchView *searchView;

@property (nonatomic, strong) Camp *camp;

@property (nonatomic) NSString *managerType;

@end

NS_ASSUME_NONNULL_END
