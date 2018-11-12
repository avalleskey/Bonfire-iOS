//
//  RoomMembersViewController.h
//  Pulse
//
//  Created by Austin Valleskey on 11/7/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Room.h"

NS_ASSUME_NONNULL_BEGIN

@interface RoomMembersViewController : UITableViewController

@property (strong, nonatomic) Room *room;
@property (strong, nonatomic) UIColor *theme;

@end

NS_ASSUME_NONNULL_END
