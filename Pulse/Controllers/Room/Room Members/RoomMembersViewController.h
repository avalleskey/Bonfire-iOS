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

@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) Room *room;
@property (nonatomic, strong) UIView *segmentedControl;

@property (nonatomic, strong) UIView *shareView;
@property (nonatomic, strong) UIButton *shareButton;

@end

NS_ASSUME_NONNULL_END
