//
//  HomeViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 9/16/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChannelCell.h"
#import "RoomViewController.h"
#import "TabBarView.h"
#import "MyRoomsViewController.h"
#import "FeedViewController.h"
#import "LauncherNavigationViewController.h"

@interface HomeViewController : UIViewController <UIScrollViewDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) TabBarView *bottomBarContainer;
@property (strong, nonatomic) NSMutableArray *bottomBarButtons;
@property (strong, nonatomic) UIView *bottomBarIndicator;

@property (strong, nonatomic) MyRoomsViewController *myRoomsViewController;
@property (strong, nonatomic) FeedViewController *timelineViewController;
@property (strong, nonatomic) FeedViewController *trendingFeedViewController;

@property (nonatomic) int page;

@end

