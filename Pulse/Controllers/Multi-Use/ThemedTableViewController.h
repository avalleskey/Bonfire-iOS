//
//  ThemedTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 1/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSTableView.h"
#import  "BFComponentTableView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ThemedTableViewController : UIViewController

// views
@property (nonatomic, strong) UITableView * _Nullable tableView;
@property (nonatomic, strong) RSTableView * _Nullable rs_tableView;
@property (nonatomic, strong) BFComponentTableView * _Nullable bf_tableView;
- (UITableView *)activeTableView;

@property (nonatomic, strong) UIRefreshControl * refreshControl;
@property (nonatomic, strong) UIImageView *bigSpinner;

// values
@property (nonatomic, strong) UIColor *theme;
@property (nonatomic) BOOL spinning;
@property (nonatomic) BOOL loading;

// methods
- (void)setSpinning:(BOOL)spinning animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
