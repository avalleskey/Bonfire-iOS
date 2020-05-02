//
//  ExpandedPostActionsView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "ExpandedPostActionsView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>

@implementation ExpandedPostActionsView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _replyButton.frame = CGRectMake(0, 0, 48, 48);
        [_replyButton setImage:[[UIImage imageNamed:@"replyIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _replyButton.adjustsImageWhenHighlighted = false;
        _replyButton.adjustsImageWhenDisabled = false;
        [self addTapHandlersToAction:_replyButton];
        [self addSubview:_replyButton];
        
        _quoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _quoteButton.frame = CGRectMake(0, 0, 48, 48);
        [_quoteButton setImage:[[UIImage imageNamed:@"quoteIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _quoteButton.adjustsImageWhenHighlighted = false;
        [self addTapHandlersToAction:_quoteButton];
        [self addSubview:_quoteButton];
        
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _shareButton.frame = CGRectMake(0, 0, 48, 48);
        [_shareButton setImage:[[UIImage imageNamed:@"shareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _shareButton.adjustsImageWhenHighlighted = false;
        [self addTapHandlersToAction:_shareButton];
        [self addSubview:_shareButton];
        
        _voteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _voteButton.frame = CGRectMake(_shareButton.frame.origin.x + _shareButton.frame.size.width + 10, 0, 48, 48);
        [_voteButton setImage:[[UIImage imageNamed:@"boltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _voteButton.adjustsImageWhenHighlighted = false;
        [self addTapHandlersToAction:_voteButton];
        [self addSubview:_voteButton];
        
        _topSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, 0, 1, (1 / [UIScreen mainScreen].scale))];
        _topSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        _topSeparator.alpha = 0.75;
        [self addSubview:_topSeparator];
        
        _bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, self.frame.size.height - _topSeparator.frame.size.height, 1, (1 / [UIScreen mainScreen].scale))];
        _bottomSeparator.backgroundColor = [UIColor tableViewSeparatorColor];
        [self addSubview:_bottomSeparator];
    }
    return self;
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
    
    BOOL showReplyButton = true; //_loading || [_replyButton isEnabled];
    BOOL showQuoteButton = true; //_loading || [_quoteButton isEnabled];
    BOOL showVoteButton = true; //_loading || [_voteButton isEnabled];
    BOOL showShareButton = true; //_loading || [_shareButton isEnabled];
    
    NSInteger buttons = 0;
    if (showReplyButton) buttons += 1;
    if (showQuoteButton) buttons += 1;
    if (showVoteButton) buttons += 1;
    if (showShareButton) buttons += 1;
    
    CGFloat lastX = 0;
    CGFloat buttonWidth = self.frame.size.width / buttons;
    
    if (showReplyButton) {
        _replyButton.frame = CGRectMake(lastX, 0, buttonWidth, self.frame.size.height);
        lastX = _replyButton.frame.origin.x + _replyButton.frame.size.width;
    }
    
    if (showQuoteButton) {
        _quoteButton.frame = CGRectMake(lastX, 0, buttonWidth, self.frame.size.height);
        lastX = _quoteButton.frame.origin.x + _quoteButton.frame.size.width;
    }
    
    if (showVoteButton) {
        _voteButton.frame = CGRectMake(lastX, 0, buttonWidth, self.frame.size.height);
        lastX = _voteButton.frame.origin.x + _voteButton.frame.size.width;
    }
    
    if (showShareButton) {
        _shareButton.frame = CGRectMake(lastX, 0, buttonWidth, self.frame.size.height);
        lastX = _shareButton.frame.origin.x + _shareButton.frame.size.width;
    }
}

@end
