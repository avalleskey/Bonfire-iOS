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
    [self.replyButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
    self.replyButton.tintColor = self.replyButton.currentTitleColor;
    [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
    [self.replyButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 5, 0, 0)];
//    self.replyButton.backgroundColor = [[UIColor fromHex:@"9FA6AD"] colorWithAlphaComponent:0.1];
    self.replyButton.layer.borderWidth = HALF_PIXEL;
    [self.replyButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
    [self.replyButton setImage:[[UIImage imageNamed:@"postActionReply"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.replyButton.frame = CGRectMake(0, 0, self.replyButton.intrinsicContentSize.width + self.replyButton.currentImage.size.width - self.replyButton.titleEdgeInsets.left, POST_ACTIONS_VIEW_HEIGHT);
    [self addTapHandlersToAction:self.replyButton];
    [self addSubview:self.replyButton];
    
    self.voteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.voteButton.titleLabel.font = [UIFont systemFontOfSize:14.f weight:UIFontWeightSemibold];
    self.voteButton.adjustsImageWhenHighlighted = false;
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
    
//    self.replyButton.layer.borderWidth = HALF_PIXEL;
    
//    self.voteButton.backgroundColor =
//    self.replyButton.backgroundColor =
//    self.shareButton.backgroundColor = [UIColor bonfireDetailColor];
    
    self.voteButton.layer.cornerRadius =
    self.replyButton.layer.cornerRadius =
    self.shareButton.layer.cornerRadius = 17.f;
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

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    CGFloat buttonPadding = 8;
    CGFloat button1Width;
    CGFloat button2Width;
    CGFloat button3Width;
    
    if (self.voted) {
        CGFloat insideButtonWidth = 40;
        CGFloat outsideButtonWidth = ceilf(self.frame.size.width - (insideButtonWidth * 2) - (buttonPadding * 2));
        button1Width = outsideButtonWidth;
        button2Width = insideButtonWidth;
        button3Width = insideButtonWidth;
    }
    else {
        button1Width = ceilf((self.frame.size.width - (buttonPadding * 2)) / 3);
        button2Width = ceilf((self.frame.size.width - (buttonPadding * 2)) / 3);
        button3Width = ceilf((self.frame.size.width - (buttonPadding * 2)) / 3);
    }
    
    SetWidth(self.replyButton, button1Width);
    SetWidth(self.voteButton, button2Width);
    SetWidth(self.shareButton, button3Width);
    
    SetX(self.replyButton, 0);
    SetX(self.voteButton, self.frame.size.width - button3Width - button2Width - buttonPadding);
    SetX(self.shareButton, self.frame.size.width - button3Width);
}

- (void)layoutSubviews {
    [super layoutSubviews];
        
    self.replyButton.layer.borderColor = [[UIColor colorNamed:@"FullContrastColor"] colorWithAlphaComponent:0.12].CGColor;
}

- (void)setTintColor:(UIColor *)tintColor {
    [super setTintColor:tintColor];
        
    [self setVoted:self.voted animated:false]; // update colors
}

- (void)setVoted:(BOOL)isVoted animated:(BOOL)animated {
    if (!animated || (isVoted != self.voted)) {
        self.voted = isVoted;
        
        if (animated && self.voted) {
            [HapticHelper generateFeedback:FeedbackType_Notification_Success];
        }
            
        if (self.voted) {
            [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt_active"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [self.voteButton setTitle:@"" forState:UIControlStateNormal];
            [self.shareButton setTitle:@"" forState:UIControlStateNormal];
            [self.replyButton setTitle:@"Add a reply..." forState:UIControlStateNormal];
            [self.replyButton setTitleColor:[[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.75] forState:UIControlStateNormal];
            
            [self.voteButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 0, 0, 0)];
            [self.voteButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 0)];
            
            [self.voteButton setTitleColor:[UIColor bonfireSecondaryColor] forState:UIControlStateNormal];
            self.voteButton.tintColor = [UIColor bonfireSecondaryColor];
        }
        else {
            [self.voteButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
            [self.voteButton setTitle:@"Spark" forState:UIControlStateNormal];
            [self.shareButton setTitle:@"Share" forState:UIControlStateNormal];
            [self.replyButton setTitle:@"Reply" forState:UIControlStateNormal];
            [self.replyButton setTitleColor:self.shareButton.currentTitleColor
                                   forState:UIControlStateNormal];
            
            [self.voteButton setTitleEdgeInsets:UIEdgeInsetsMake(1, 5, 0, 0)];
            [self.voteButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 5)];
            self.voteButton.backgroundColor = [UIColor clearColor];
            
            [self.voteButton setTitleColor:self.tintColor forState:UIControlStateNormal];
            self.voteButton.tintColor = self.tintColor;
        }
        self.replyButton.tintColor = self.replyButton.currentTitleColor;
        
        [UIView animateWithDuration:animated?0.35f:0 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self setFrame:self.frame];
        } completion:nil];
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
