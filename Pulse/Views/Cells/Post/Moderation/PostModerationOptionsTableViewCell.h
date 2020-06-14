//
//  ReplyUpsellTableViewCell.h
//  Pulse
//
//  Created by Austin Valleskey on 4/1/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PostModerationOptionsTableViewCell : UITableViewCell

@property (nonatomic, strong) UIView *topSeparator;
@property (nonatomic, strong) UIView *bottomSeparator;

@property (nonatomic, strong) UIScrollView *optionsScrollView;
@property (nonatomic, strong) UIStackView *optionsStackView;

typedef enum {
    PostModerationOptionIgnore,
    PostModerationOptionSpam,
    PostModerationOptionDelete,
    PostModerationOptionSilenceUser,
    PostModerationOptionBlockUser
} PostModerationOption;
@property (nonatomic, copy) void (^optionTappedAction)(NSInteger option);

+ (CGFloat)height;

@end

NS_ASSUME_NONNULL_END
