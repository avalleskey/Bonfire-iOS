//
//  ThreadedPostCell.h
//  Pulse
//
//  Created by Austin Valleskey on 2/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostCell.h"

NS_ASSUME_NONNULL_BEGIN

#define THREADED_POST_EXPAND_CELL_HEIGHT 32
#define THREADED_POST_ADD_REPLY_CELL_HEIGHT 48

@interface ThreadedPostCell : PostCell <UITableViewDelegate, UITableViewDataSource>

@property (strong, nonatomic) UITableView *repliesTableView;
@property (strong, nonatomic) NSMutableArray *replies;

@property (strong, nonatomic) UIView *threadLine;

+ (CGFloat)heightOfRepliesForPost:(Post *)post;

typedef enum {
    PostCellRepliesModeNone = 0,
    PostCellRepliesModeSnapshot = 1,
    PostCellRepliesModeThread = 2
} PostCellRepliesMode;
@property (nonatomic) PostCellRepliesMode repliesMode;

@end

NS_ASSUME_NONNULL_END
