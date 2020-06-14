//
//  MasterViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 5/27/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MasterViewController : UIViewController

@property (nonatomic, strong) NSMutableArray *viewControllers;
@property (nonatomic, strong) UIScrollView *pagedScrollView;

@property (nonatomic, strong) UIView *navBar;

@property (nonatomic, strong) UIView *tabControl;
@property (nonatomic, strong) NSArray *tabs;

@property (nonatomic, strong) NSMutableDictionary *pills;

@end

NS_ASSUME_NONNULL_END
