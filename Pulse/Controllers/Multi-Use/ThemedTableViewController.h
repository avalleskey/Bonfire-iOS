//
//  ThemedTableViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 1/28/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFComponentTableView.h"
#import "BFComponentSectionTableView.h"
#import "BFActivityIndicatorView.h"

NS_ASSUME_NONNULL_BEGIN

@interface ThemedTableViewController : UIViewController

// views
@property (nonatomic, strong) UITableView * _Nullable tableView;
@property (nonatomic, strong) BFComponentTableView * _Nullable bfTableView;
@property (nonatomic, strong) BFComponentSectionTableView * _Nullable sectionTableView;
- (UITableView * _Nullable)activeTableView;

@property (nonatomic, strong) UIRefreshControl * refreshControl;
@property (nonatomic, strong) BFActivityIndicatorView *bigSpinner;

// values
@property (nonatomic, strong) UIColor *theme;
@property (nonatomic) BOOL spinning;
@property (nonatomic) BOOL loading;
@property (nonatomic) BOOL animateLoading; // default: YES

// methods
- (void)setSpinning:(BOOL)spinning animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
