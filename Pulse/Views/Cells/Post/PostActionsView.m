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
#import "Launcher.h"

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
    self.voteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voteButton.adjustsImageWhenHighlighted = false;
    self.voteButton.adjustsImageWhenDisabled = false;
    [self.voteButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
    [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.voteButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 0, 0, 0)];
    [self.voteButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
    self.voteButton.frame = CGRectMake(68, 0, self.voteButton.intrinsicContentSize.width + self.voteButton.currentImage.size.width - self.voteButton.titleEdgeInsets.left + (12 * 2), self.frame.size.height);
//    self.voteButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.2f];
    [self addTapHandlersToAction:self.voteButton];
    [self addSubview:self.voteButton];
    
    self.quoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.quoteButton.adjustsImageWhenHighlighted = false;
    self.quoteButton.adjustsImageWhenDisabled = false;
    [self.quoteButton setImage:[[UIImage imageNamed:@"postActionQuote"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.quoteButton.tintColor = [UIColor bonfireSecondaryColor];
    self.quoteButton.frame = CGRectMake(0, 0, self.quoteButton.currentImage.size.width + (12 * 2), POST_ACTIONS_VIEW_HEIGHT);
    [self addTapHandlersToAction:self.quoteButton];
    [self addSubview:self.quoteButton];
    
    self.shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.shareButton.adjustsImageWhenHighlighted = false;
    self.shareButton.adjustsImageWhenDisabled = false;
    [self.shareButton setImage:[[UIImage imageNamed:@"postActionShare"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.shareButton.tintColor = [UIColor bonfireSecondaryColor];
    self.shareButton.frame = CGRectMake(0, 0, self.shareButton.currentImage.size.width + (12 * 2), POST_ACTIONS_VIEW_HEIGHT);
//    self.shareButton.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1f];
    [self addTapHandlersToAction:self.shareButton];
    [self addSubview:self.shareButton];
    
    [self initRepliesSnapshotView];
    [self initReplyActionView];
}
- (void)addTapHandlersToAction:(UIButton *)action {
    [action bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            action.alpha = 0.5;
        } completion:nil];
    } forControlEvents:UIControlEventTouchDown];
    [action bk_addEventHandler:^(id sender) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
            action.alpha = 1;
        } completion:nil];
    } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    SetX(self.shareButton, self.frame.size.width - self.shareButton.frame.size.width + 12);
    SetX(self.voteButton, self.shareButton.frame.origin.x - self.voteButton.frame.size.width);
    SetX(self.quoteButton, self.voteButton.frame.origin.x - self.quoteButton.frame.size.width);
    
    SetWidth(self.repliesSnaphotView, self.replyButton.frame.size.width);
    SetWidth(self.replyActionView, self.repliesSnaphotView.frame.size.width);
    
    self.replyButton.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12].CGColor;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
        
    [self setVoted:self.voted animated:false]; // update colors
}

- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated {
    if (!animated || (isVoted != self.voted)) {
        self.voted = isVoted;
        
        if (self.voted) {
            if (animated) {
                [HapticHelper generateFeedback:FeedbackType_Notification_Success];
            }
            
            [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.voteButton.tintColor = self.tintColor;
            
            if (self.replyActionView.alpha != 1) {
                [self showReplyActionView:animated];
            }
        }
        else {
            [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            self.voteButton.tintColor = [UIColor bonfireSecondaryColor];
        }
        [self.voteButton setTitleColor:self.voteButton.tintColor forState:UIControlStateNormal];
        
        [UIView animateWithDuration:animated?0.35f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self layoutSubviews];
        } completion:nil];
    }
}

- (void)setActionsType:(PostActionsViewType)actionsType {
    if (actionsType != _actionsType) {
        _actionsType = actionsType;
    }
}

- (void)initRepliesSnapshotView {
    // need to initialize the snapshot view
    self.repliesSnaphotView = [[UIView alloc] init];
    self.repliesSnaphotView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
//    self.repliesSnaphotView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.15f];
    [self drawRepliesSnapshotSubviews];
    [self addSubview:self.repliesSnaphotView];
}
- (void)initReplyActionView {
    // need to initialize the snapshot view
    self.replyActionView = [[UIView alloc] init];
    self.replyActionView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    self.replyActionView.alpha = 0;
    [self addSubview:self.replyActionView];
    
    self.replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.replyButton.titleLabel.font = [UIFont systemFontOfSize:15.f weight:UIFontWeightSemibold];
    self.replyButton.adjustsImageWhenHighlighted = false;
    self.replyButton.adjustsImageWhenDisabled = false;
    [self.replyButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
    self.replyButton.tintColor = self.replyButton.currentTitleColor;
    [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
    [self.replyButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 5, 0, 0)];
    [self.replyButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    self.replyButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
    [self.replyButton setImage:[[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.replyButton.frame = CGRectMake(-15, 0, self.replyButton.intrinsicContentSize.width + self.replyButton.currentImage.size.width - self.replyButton.titleEdgeInsets.left + (12 * 2), self.replyActionView.frame.size.height);
    [self addTapHandlersToAction:self.replyButton];
    [self.replyActionView addSubview:self.replyButton];
}

- (void)setSummaries:(PostSummaries *)summaries {
    if (summaries != _summaries) {
        _summaries = summaries;
        
        NSArray *summaryReplies = self.summaries.replies;
        
        NSMutableArray <Post *> *filteredSummaryReplies = [NSMutableArray array];
        if (summaryReplies.count > 1) {
            NSMutableSet *existingCreatorIds = [NSMutableSet set];
            for (Post *object in summaryReplies) {
                if (object.attributes.creator.identifier && ![existingCreatorIds containsObject:object.attributes.creator.identifier]) {
                    [existingCreatorIds addObject:object.attributes.creator.identifier];
                    [filteredSummaryReplies addObject:object];
                }
            }
        }
        else {
            // don't run the loop since there can't be any duplicates by default
            filteredSummaryReplies = [summaryReplies mutableCopy];
        }
            
        CGFloat avatars = filteredSummaryReplies.count;
        if (avatars == 0 && summaries.counts.replies > 0) {
            avatars = 1;
            self.repliesSnaphotViewAvatar1.imageView.layer.borderWidth = 0;
            
            self.repliesSnaphotViewAvatar1.superview.hidden = false;
            self.repliesSnaphotViewAvatar2.superview.hidden = true;
            self.repliesSnaphotViewAvatar3.superview.hidden = true;
            
            self.repliesSnaphotViewAvatar1.imageView.contentMode = UIViewContentModeCenter;
            [self.repliesSnaphotViewAvatar1.imageView setImage:[[UIImage imageNamed:@"postRepliesIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
            self.repliesSnaphotViewAvatar1.imageView.tintColor = [UIColor bonfireSecondaryColor];
            self.repliesSnaphotViewAvatar1.imageView.backgroundColor = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.16];
        }
        else {
            self.repliesSnaphotViewAvatar1.imageView.contentMode = UIViewContentModeScaleAspectFill;
            self.repliesSnaphotViewAvatar1.imageView.layer.borderWidth = HALF_PIXEL;
            for (NSInteger i = 0; i < 3; i++) {
                BFAvatarView *avatarView;
                
                if (i == 0) {
                    avatarView = self.repliesSnaphotViewAvatar1;
                }
                else if (i == 1) {
                    avatarView = self.repliesSnaphotViewAvatar2;
                }
                else if (i == 2) {
                    avatarView = self.repliesSnaphotViewAvatar3;
                }
                
                if (avatarView) {
                    if (filteredSummaryReplies.count > i) {
                        // profile pics
                        avatarView.user = filteredSummaryReplies[i].attributes.creatorUser;
                        avatarView.superview.hidden = false;
                    }
                    else {
                        avatarView.user = nil;
                        avatarView.superview.hidden = true;
                    }
                }
            }
        }
        
        NSMutableAttributedString *attributedString = [NSMutableAttributedString new];
        NSDictionary *attributes = @{NSForegroundColorAttributeName: [UIColor bonfireSecondaryColor], NSFontAttributeName: [UIFont systemFontOfSize:15.f weight:UIFontWeightRegular]};
        
        NSInteger replies = summaries.counts.replies;
        
        NSString *replyString = @"Add a reply...";
        if (summaries.counts.replies > 0) {
            replyString = [NSString stringWithFormat:@"%lu Repl%@", (long)replies, (replies == 1 ? @"y" : @"ies")];
        }
            
        NSAttributedString *replyCount = [[NSAttributedString alloc] initWithString:replyString attributes:attributes];
        [attributedString appendAttributedString:replyCount];
        
        self.repliesSnaphotViewLabel.attributedText = attributedString;
        
        CGFloat xEnd = avatars * 28 + 2;
        CGFloat snapshotViewLabelWidth = ceilf([self.repliesSnaphotViewLabel.attributedText boundingRectWithSize:CGSizeMake(self.repliesSnaphotView.frame.size.width, self.frame.size.height) options:(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading) context:nil].size.width);
        self.repliesSnaphotViewLabel.frame = CGRectMake(xEnd + ([self.repliesSnaphotViewAvatar1.superview isHidden] ? 0 : 4), 0, snapshotViewLabelWidth, self.repliesSnaphotView.frame.size.height);
    }
    
    if (summaries.counts.replies <= 1 || self.voted) {
        [self showReplyActionView:false];
    }
    else {
        [self hideReplyActionView:false];
    }
}

- (void)showReplyActionView:(BOOL)animated {
    self.repliesSnaphotView.transform = CGAffineTransformIdentity;
    self.replyActionView.transform = CGAffineTransformMakeTranslation(0, 10);
    
    [UIView animateWithDuration:animated?0.5f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.replyActionView.alpha = 1;
        self.replyActionView.transform = CGAffineTransformIdentity;
        self.repliesSnaphotView.alpha = 0;
        self.repliesSnaphotView.transform = CGAffineTransformMakeTranslation(0, -10);
    } completion:^(BOOL finished) {
        self.repliesSnaphotView.transform = CGAffineTransformIdentity;
    }];
}
- (void)hideReplyActionView:(BOOL)animated {
    self.repliesSnaphotView.transform = CGAffineTransformMakeTranslation(0, -10);
    self.replyActionView.transform = CGAffineTransformIdentity;

    [UIView animateWithDuration:animated?0.35f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.replyActionView.alpha = 0;
        self.replyActionView.transform = CGAffineTransformMakeTranslation(0, 10);
        self.repliesSnaphotView.alpha = 1;
        self.repliesSnaphotView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        self.replyActionView.transform = CGAffineTransformIdentity;
    }];
}

- (void)drawRepliesSnapshotSubviews {
    CGFloat repliesSnapshotViewWidth;
    
    CGFloat avatarDiameter = 28;
    NSInteger avatarOffset = ceilf(avatarDiameter * 0.8);
    
    CGFloat avatarBaselineX = -2;
    for (NSInteger i = 0; i < 3; i++) {
        BFAvatarView *avatarView  = [[BFAvatarView alloc] initWithFrame:CGRectMake(2, 2, avatarDiameter, avatarDiameter)];
        
        if (i == 0) {
            self.repliesSnaphotViewAvatar1 = avatarView;
        }
        else if (i == 1) {
            self.repliesSnaphotViewAvatar2 = avatarView;
        }
        else if (i == 2) {
            self.repliesSnaphotViewAvatar3 = avatarView;
        }
        
        UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(avatarBaselineX + (i * avatarOffset), (self.repliesSnaphotView.frame.size.height / 2 - avatarDiameter / 2) - 2, avatarDiameter + 4, avatarDiameter + 4)];
        containerView.backgroundColor = [UIColor contentBackgroundColor];
        containerView.layer.cornerRadius = containerView.frame.size.height / 2;
        containerView.layer.masksToBounds = true;
        [containerView addSubview:avatarView];
                
        [self.repliesSnaphotView insertSubview:containerView atIndex:0];
    }
    
    self.repliesSnaphotViewLabel = [[UILabel alloc] init];
    self.repliesSnaphotViewLabel.textAlignment = NSTextAlignmentLeft;
    [self.repliesSnaphotView addSubview:self.repliesSnaphotViewLabel];
}

+ (BOOL)showRepliesSnapshotForPost:(Post *)post {
    NSInteger repliesCount = post.attributes.summaries.counts.replies;
    NSInteger summariesCount = post.attributes.summaries.replies.count;
    
    return (repliesCount > 1 && repliesCount > summariesCount);
}

@end
