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
    self.replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.replyButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.replyButton.adjustsImageWhenHighlighted = false;
    self.replyButton.adjustsImageWhenDisabled = false;
    [self.replyButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 5, 0, 0)];
    [self.replyButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    [self.replyButton setImage:[[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.replyButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
    self.replyButton.tintColor = self.replyButton.currentTitleColor;
    [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
    self.replyButton.frame = CGRectMake(0, 0, self.replyButton.intrinsicContentSize.width + self.replyButton.currentImage.size.width - self.replyButton.titleEdgeInsets.left, POST_ACTIONS_VIEW_HEIGHT);
//    self.replyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self addTapHandlersToAction:self.replyButton];
    [self addSubview:self.replyButton];
    
    self.voteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voteButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.voteButton.adjustsImageWhenHighlighted = false;
    [self.voteButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 5, 0, 0)];
    [self.voteButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    [self.voteButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
    [self.voteButton setTitle:@"Spark" forState:UIControlStateNormal];
    [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.voteButton.frame = CGRectMake(68, 0, self.voteButton.intrinsicContentSize.width + self.voteButton.currentImage.size.width - self.voteButton.titleEdgeInsets.left, POST_ACTIONS_VIEW_HEIGHT);
//    self.voteButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self addTapHandlersToAction:self.voteButton];
    [self addSubview:self.voteButton];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shareButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.shareButton.adjustsImageWhenHighlighted = false;
    self.shareButton.adjustsImageWhenDisabled = false;
    [self.shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 5, 0, 0)];
    [self.shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    [self.shareButton setImage:[[UIImage imageNamed:@"postActionShare"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.shareButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
    self.shareButton.tintColor = self.shareButton.currentTitleColor;
    [self.shareButton setTitle:@"Share" forState:UIControlStateNormal];
    self.shareButton.frame = CGRectMake(0, 0, self.shareButton.intrinsicContentSize.width + self.replyButton.currentImage.size.width - self.shareButton.titleEdgeInsets.left, POST_ACTIONS_VIEW_HEIGHT);
//    self.shareButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self addTapHandlersToAction:self.shareButton];
    [self addSubview:self.shareButton];
}
- (void)addTapHandlersToAction:(UIButton *)action {
    [action bk_addEventHandler:^(id sender) {
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

- (void)setSummaries:(PostSummaries *)summaries {
    if (summaries != _summaries) {
        _summaries = summaries;
        
        NSInteger repliesCount = summaries.counts.replies;
        NSArray *summaryReplies = summaries.replies;
        
        [self.repliesSnaphotView removeFromSuperview];
        
        if (repliesCount <= 0 && (!summaryReplies || summaryReplies.count == 0)) {
            return;
        }
        
        NSMutableArray <Post *> *filteredSummaryReplies = [NSMutableArray array];
        if (summaryReplies.count > 1) {
            NSMutableSet *existingCreatorIds = [NSMutableSet set];
            for (Post *object in summaryReplies) {
                if (![existingCreatorIds containsObject:object.attributes.creator.identifier]) {
                    [existingCreatorIds addObject:object.attributes.creator.identifier];
                    [filteredSummaryReplies addObject:object];
                }
            }
        }
        else {
            // don't run the loop since there can't be any duplicates by default
            filteredSummaryReplies = [summaryReplies mutableCopy];
        }
        
        CGFloat repliesSnapshotViewWidth = self.frame.size.width - (self.replyButton.frame.origin.x + self.replyButton.frame.size.width) - 8;
        self.repliesSnaphotView = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width - repliesSnapshotViewWidth, 0, repliesSnapshotViewWidth, POST_ACTIONS_VIEW_HEIGHT)];
        self.repliesSnaphotView.userInteractionEnabled = false;
        [self.repliesSnaphotView.subviews makeObjectsPerformSelector: @selector(removeFromSuperview)];
        
        NSInteger maxAvatars = 3;
        NSInteger avatars = (filteredSummaryReplies.count > maxAvatars ? maxAvatars : filteredSummaryReplies.count);
        CGFloat avatarDiameter = 18;
        NSInteger avatarOffset = 4;
        
//        UILabel *repliesLabel = [[UILabel alloc] init];
//        repliesLabel.textAlignment = NSTextAlignmentRight;
//        repliesLabel.textColor = self.tintColor;
//        repliesLabel.font = [UIFont systemFontOfSize:self.replyButton.titleLabel.font.pointSize weight:UIFontWeightRegular];
//        repliesLabel.text = [NSString stringWithFormat:@"%lu", repliesCount];
//
//        CGFloat repliesLabelWidth = [repliesLabel.text boundingRectWithSize:CGSizeMake(self.repliesSnaphotView.frame.size.width,  self.replyButton.titleLabel.font.lineHeight) options:(NSStringDrawingUsesFontLeading|NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName: repliesLabel.font} context:nil].size.width;
//        repliesLabel.frame = CGRectMake(repliesIcon.frame.origin.x + repliesIcon.frame.size.width + 3, 0, repliesLabelWidth, POST_ACTIONS_VIEW_HEIGHT);
//        repliesSnapshotViewWidth = repliesLabel.frame.origin.x + repliesLabel.frame.size.width;
//        [self.repliesSnaphotView addSubview:repliesLabel];
        
        CGFloat avatarBaselineX = 0;
        for (NSInteger i = 0; i < avatars; i++) {
            BFAvatarView *avatarView = [[BFAvatarView alloc] initWithFrame:CGRectMake(2, 2, avatarDiameter, avatarDiameter)];
            avatarView.user = ((Post *)filteredSummaryReplies[i]).attributes.creatorUser;
            
            UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(avatarBaselineX + (i * avatarOffset), (self.repliesSnaphotView.frame.size.height / 2 - avatarDiameter / 2) - 2, avatarDiameter + 4, avatarDiameter + 4)];
            containerView.backgroundColor = [UIColor contentBackgroundColor];
            containerView.layer.cornerRadius = containerView.frame.size.height / 2;
            containerView.layer.masksToBounds = true;
            [containerView addSubview:avatarView];
            
            repliesSnapshotViewWidth = containerView.frame.origin.x + containerView.frame.size.width - 2;
            
            [self.repliesSnaphotView insertSubview:containerView atIndex:0];
        }
        
        self.repliesSnaphotView.frame = CGRectMake(self.frame.size.width - repliesSnapshotViewWidth, self.repliesSnaphotView.frame.origin.y, repliesSnapshotViewWidth, self.repliesSnaphotView.frame.size.height);
        
//        [self addSubview:self.repliesSnaphotView];
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGFloat buttonWidth = ceilf(self.frame.size.width / 3);
    CGFloat buttonPadding = 8;
    
    SetWidth(self.replyButton, self.replyButton.intrinsicContentSize.width + self.replyButton.currentImage.size.width + (buttonPadding * 2) - self.replyButton.titleEdgeInsets.left);
    SetWidth(self.voteButton, self.voteButton.intrinsicContentSize.width + self.voteButton.currentImage.size.width - self.voteButton.titleEdgeInsets.left);
    SetWidth(self.shareButton, self.shareButton.intrinsicContentSize.width + self.shareButton.currentImage.size.width + (buttonPadding * 2) - self.shareButton.titleEdgeInsets.left);
    
    SetX(self.replyButton, -buttonPadding);
    SetX(self.voteButton, buttonWidth + 4);
    SetX(self.shareButton, self.frame.size.width - self.shareButton.frame.size.width + buttonPadding + self.shareButton.titleEdgeInsets.left);
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.repliesSnaphotView.frame = CGRectMake(self.replyButton.frame.origin.x + self.replyButton.frame.size.width - 10, 0, self.repliesSnaphotView.frame.size.width, POST_ACTIONS_VIEW_HEIGHT);
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
    
    self.replyButton.tintColor = self.tintColor;
    [self.replyButton setTitleColor:self.tintColor forState:UIControlStateNormal];
    
    [self setVoted:self.voted animated:false]; // update colors
}

- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated {
    if (!animated || (isVoted != self.voted)) {
        self.voted = isVoted;
        
        if (animated && self.voted)
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        
        if (self.voted) {
            [self.voteButton setTitleColor:[UIColor bonfireBrand] forState:UIControlStateNormal];
            [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [self.voteButton setTitleColor:self.tintColor forState:UIControlStateNormal];
            [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        self.voteButton.tintColor = self.voteButton.currentTitleColor;
    }
}

- (void)setActionsType:(PostActionsViewType)actionsType {
    if (actionsType != _actionsType) {
        _actionsType = actionsType;
    }
//
//    if (actionsType == PostActionsViewTypeConversation) {
//        [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
//        [self.replyButton setImage:[[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//    }
//    else if (actionsType == PostActionsViewTypeQuote) {
//        [self.replyButton setTitle:@"Quote" forState:UIControlStateNormal];
//        [self.replyButton setImage:[[UIImage imageNamed:@"postActionQuote"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//        self.replyButton.alpha = 1;
//        self.replyButton.userInteractionEnabled = true;
//    }
//    self.replyButton.frame = CGRectMake(self.replyButton.frame.origin.x, 0, self.replyButton.intrinsicContentSize.width + self.replyButton.currentImage.size.width - self.replyButton.titleEdgeInsets.left, POST_ACTIONS_VIEW_HEIGHT);
}

@end
