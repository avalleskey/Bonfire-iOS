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
@property (nonatomic, strong) UIButton *voteButton;

@property (nonatomic, strong) UIView *repliesSnaphotView;

@property (nonatomic, strong) PostSummaries *summaries;

@property BOOL voted;
- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated;

typedef enum {
    PostActionsViewTypeConversation,
    PostActionsViewTypeQuote
} PostActionsViewType;
@property (nonatomic) PostActionsViewType actionsType;

@end

NS_ASSUME_NONNULL_END
