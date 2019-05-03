//
//  PostActionsView.m
//  Pulse
//
//  Created by Austin Valleskey on 4/1/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "PostActionsView.h"
#import "UIColor+Palette.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import <HapticHelper/HapticHelper.h>

@implementation PostActionsView

- (id)init {
    self  = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    /*
     @property (nonatomic, strong) UIButton *replyButton;
     @property (nonatomic, strong) UIButton *sparkButton;
     
     @property (nonatomic, strong) UIView *repliesSnaphotView;
     */
    
    self.replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.replyButton.frame = CGRectMake(2, 0, 57, POST_ACTIONS_VIEW_HEIGHT);
    self.replyButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.replyButton.adjustsImageWhenHighlighted = false;
    [self.replyButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
    [self.replyButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
    [self.replyButton setImage:[[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.replyButton setTitleColor:[UIColor bonfireGray] forState:UIControlStateNormal];
    self.replyButton.tintColor = self.replyButton.currentTitleColor;
    [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
    [self addTapHandlersToAction:self.replyButton];
    [self addSubview:self.replyButton];
    
    self.sparkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sparkButton.frame = CGRectMake(91, 0, 60, POST_ACTIONS_VIEW_HEIGHT);
    self.sparkButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.sparkButton.adjustsImageWhenHighlighted = false;
    [self.sparkButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
    [self.sparkButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
    [self.sparkButton setTitleColor:[UIColor bonfireGray] forState:UIControlStateNormal];
    [self.sparkButton setTitle:@"Spark" forState:UIControlStateNormal];
    [self addTapHandlersToAction:self.sparkButton];
    [self addSubview:self.sparkButton];
}
- (void)addTapHandlersToAction:(UIButton *)action {
    [action bk_addEventHandler:^(id sender) {
        [HapticHelper generateFeedback:FeedbackType_Selection];
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            action.transform = CGAffineTransformMakeScale(0.8, 0.8);
            action.alpha = 0.5;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [action bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            action.transform = CGAffineTransformIdentity;
            action.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

- (void)updateWithSummaries:(PostSummaries *)summaries {
    NSInteger repliesCount = summaries.counts.replies;
    NSArray *summaryReplies = summaries.replies;
        
    [self.repliesSnaphotView removeFromSuperview];
    
    if (repliesCount == 0 && (!summaryReplies || summaryReplies.count == 0)) {
        return;
    }
    
    CGFloat repliesSnapshotViewWidth = self.frame.size.width - (self.replyButton.frame.origin.x + self.replyButton.frame.size.width) - 8;
    self.repliesSnaphotView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - repliesSnapshotViewWidth, 0, repliesSnapshotViewWidth, POST_ACTIONS_VIEW_HEIGHT)];
    self.repliesSnaphotView.userInteractionEnabled = false;
    [self.repliesSnaphotView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
    
    NSInteger maxAvatars = 3;
    NSInteger avatars = (summaryReplies.count > maxAvatars ? maxAvatars : summaryReplies.count);
    CGFloat avatarDiameter = 20;
    NSInteger avatarOffset = 8;
    
    UIImage *conversationIcon = [UIImage imageNamed:@"postConversationIcon"];
    UIImageView *repliesIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, conversationIcon.size.width, self.repliesSnaphotView.frame.size.height)];
    repliesIcon.contentMode = UIViewContentModeCenter;
    repliesIcon.image = [conversationIcon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    repliesIcon.tintColor = [UIColor bonfireGray];
    [self.repliesSnaphotView addSubview:repliesIcon];
    
    UILabel *repliesLabel = [[UILabel alloc] init];
    repliesLabel.textAlignment = NSTextAlignmentRight;
    repliesLabel.textColor = [UIColor bonfireGray];
    repliesLabel.font = [UIFont systemFontOfSize:self.replyButton.titleLabel.font.pointSize weight:UIFontWeightRegular];
    repliesLabel.text = [NSString stringWithFormat:@"%lu", repliesCount];
    
    CGFloat repliesLabelWidth = [repliesLabel.text boundingRectWithSize:CGSizeMake(self.repliesSnaphotView.frame.size.width,  self.replyButton.titleLabel.font.lineHeight) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: repliesLabel.font} context:nil].size.width;
    repliesLabel.frame = CGRectMake(repliesIcon.frame.origin.x + repliesIcon.frame.size.width + 3, 0, repliesLabelWidth, POST_ACTIONS_VIEW_HEIGHT);
    repliesSnapshotViewWidth = repliesLabel.frame.origin.x + repliesLabel.frame.size.width;
    [self.repliesSnaphotView addSubview:repliesLabel];
    
    CGFloat avatarBaselineX = repliesLabel.frame.origin.x + repliesLabel.frame.size.width + 4;
    for (NSInteger i = 0; i < avatars; i++) {
        BFAvatarView *avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(2, 2, avatarDiameter, avatarDiameter)];
        avatarView.user = ((Post *)summaryReplies[i]).attributes.details.creator;
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(avatarBaselineX + (i * avatarOffset), (self.repliesSnaphotView.frame.size.height / 2 - avatarDiameter / 2) - 2, avatarDiameter + 4, avatarDiameter + 4)];
        containerView.backgroundColor = [UIColor whiteColor];
        containerView.layer.cornerRadius = containerView.frame.size.height / 2;
        containerView.layer.masksToBounds = true;
        [containerView addSubview:avatarView];
        
        repliesSnapshotViewWidth = containerView.frame.origin.x + containerView.frame.size.width - 2;
        
        [self.repliesSnaphotView insertSubview:containerView atIndex:0];
    }
    
    self.repliesSnaphotView.frame = CGRectMake(self.frame.size.width - repliesSnapshotViewWidth, self.repliesSnaphotView.frame.origin.y, repliesSnapshotViewWidth, self.repliesSnaphotView.frame.size.height);
    
    [self addSubview:self.repliesSnaphotView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.repliesSnaphotView.frame = CGRectMake(self.frame.size.width - self.repliesSnaphotView.frame.size.width, 0, self.repliesSnaphotView.frame.size.width, POST_ACTIONS_VIEW_HEIGHT);
}

- (void)setSparked:(BOOL)isSparked animated:(BOOL)animated {
    if (!animated || (isSparked != self.sparked)) {
        self.sparked = isSparked;
        
        if (animated && self.sparked)
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        if (self.sparked) {
            [self.sparkButton setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
            [self.sparkButton setImage:[[UIImage imageNamed:@"postActionBolt_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [self.sparkButton setTitleColor:[UIColor bonfireGray] forState:UIControlStateNormal];
            [self.sparkButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        self.sparkButton.tintColor = self.sparkButton.currentTitleColor;
    }
}

@end
