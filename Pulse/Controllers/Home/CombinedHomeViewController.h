//
//  CombinedHomeViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 7/20/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RSTableView.h"
#import "HomeTableViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface CombinedHomeViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *pagedScrollView;
@property (strong, nonatomic) NSMutableArray *pages;

@property (strong, nonatomic) UIViewController *myCampsVC;
@property (strong, nonatomic) HomeTableViewController *homeVC;

@property (strong, nonatomic) UIVisualEffectView *pageControl;
@property (strong, nonatomic) NSMutableArray *pageControlButtons;

@end

NS_ASSUME_NONNULL_END
