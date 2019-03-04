//
//  RoomMembersViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/7/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"
#import "ThemedViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface RoomMembersViewController : ThemedViewController <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *tableView;

@property (strong, nonatomic) Room *room;
@property (strong, nonatomic) UIView *segmentedControl;

@property (strong, nonatomic) UIView *shareView;
@property (strong, nonatomic) UIButton *shareButton;

@end

NS_ASSUME_NONNULL_END
