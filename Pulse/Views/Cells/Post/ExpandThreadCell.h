//
//  ThreadedPostExpandCell.h
//  Pulse
//
//  Created by Austin Valleskey on 2/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#define CONVERSATION_EXPAND_CELL_HEIGHT 48

@interface ExpandThreadCell : UITableViewCell

@property (nonatomic, strong) UIImageView *morePostsIcon;
@property (nonatomic, strong) UIView *lineSeparator;

@end

NS_ASSUME_NONNULL_END
