//
//  ThreadedPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 2/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BubblePostCell.h"

NS_ASSUME_NONNULL_BEGIN

@interface ThreadedPostCell : BubblePostCell <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *repliesTableView;
@property (strong, nonatomic) NSMutableArray *replies;

@end

NS_ASSUME_NONNULL_END
