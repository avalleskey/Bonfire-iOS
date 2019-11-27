//
//  ThreadedPostExpandCell.h
//  Pulse
//
//  Created by Austin Valleskey on 2/17/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExpandThreadCell : UITableViewCell

@property (nonatomic, strong) UIImageView *morePostsIcon;
@property (nonatomic, strong) UIView *lineSeparator;

@property (nonatomic, strong) UIView *dotView;

@property (nonatomic) NSInteger levelsDeep;

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
