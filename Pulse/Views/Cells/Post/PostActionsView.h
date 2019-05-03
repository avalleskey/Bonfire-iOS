//
//  PostActionsView.h
//  Pulse
//
//  Created by Austin Valleskey on 4/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BFAvatarView.h"
#import "Post.h"

#define POST_ACTIONS_VIEW_HEIGHT 24

NS_ASSUME_NONNULL_BEGIN

@interface PostActionsView : UIView

@property (nonatomic, strong) UIButton *replyButton;
@property (nonatomic, strong) UIButton *sparkButton;

@property (nonatomic, strong) UIView *repliesSnaphotView;

- (void)updateWithSummaries:(PostSummaries *)summaries;

@property BOOL sparked;
- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
