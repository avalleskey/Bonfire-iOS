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
//        self.layer.cornerRadius = 10.f;
//        self.layer.masksToBounds = true;
//        self.layer.borderColor = [[UIColor tableViewSeparatorColor] colorWithAlphaComponent:0.75].CGColor;
//        self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
        
        _middleSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 8, (1 / [UIScreen mainScreen].scale), self.frame.size.height - 16)];
        _middleSeparator.layer.cornerRadius = _middleSeparator.frame.size.width / 2;
        _middleSeparator.layer.masksToBounds = true;
        _middleSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        //[self addSubview:_middleSeparator];
        
        _replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _replyButton.frame = CGRectMake(0, 0, 48, 48);
        [_replyButton setImage:[[UIImage imageNamed:@"replyIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _replyButton.adjustsImageWhenHighlighted = false;
        _replyButton.adjustsImageWhenDisabled = false;
        [self addTapHandlersToAction:_replyButton];
        [self addSubview:_replyButton];
        
//        _moreButton = [UIButton buttonWithType:UIButtonTypeCustom];
//        _moreButton.frame = CGRectMake(0, 0, 48, 48);
//        [_moreButton setImage:[[UIImage imageNamed:@"navMoreIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
//        _moreButton.adjustsImageWhenHighlighted = false;
//        [self addTapHandlersToAction:_moreButton];
//        [self addSubview:_moreButton];
        
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
    
    CGFloat buttonWidth = self.frame.size.width / 3;
    _replyButton.frame = CGRectMake(0, 0, buttonWidth, self.frame.size.height);
    _voteButton.frame = CGRectMake(_replyButton.frame.origin.x + _replyButton.frame.size.width, 0, buttonWidth, self.frame.size.height);
    _shareButton.frame = CGRectMake(self.frame.size.width - buttonWidth, 0, buttonWidth, self.frame.size.height);
}

@end
