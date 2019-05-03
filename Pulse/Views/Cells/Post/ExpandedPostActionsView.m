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
        // self.backgroundColor = [UIColor colorWithRed:0.98 green:0.98 blue:0.99 alpha:1.00];
        /*self.layer.cornerRadius = 10.f;
        self.layer.masksToBounds = true;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor colorWithWhite:0.92 alpha:1].CGColor;
        self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);*/
        
        _middleSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 8, (1 / [UIScreen mainScreen].scale), self.frame.size.height - 16)];
        _middleSeparator.layer.cornerRadius = _middleSeparator.frame.size.width / 2;
        _middleSeparator.layer.masksToBounds = true;
        _middleSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        //[self addSubview:_middleSeparator];
        
        _replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _replyButton.frame = CGRectMake(0, 0, 48, 48);
        [_replyButton setImage:[[UIImage imageNamed:@"replyIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _replyButton.adjustsImageWhenHighlighted = false;
        [self addTapHandlersToAction:_replyButton];
        [self addSubview:_replyButton];
        
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _shareButton.frame = CGRectMake(0, 0, 48, 48);
        [_shareButton setImage:[[UIImage imageNamed:@"shareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _shareButton.adjustsImageWhenHighlighted = false;
        [self addTapHandlersToAction:_shareButton];
        [self addSubview:_shareButton];
        
        _sparkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _sparkButton.frame = CGRectMake(_shareButton.frame.origin.x + _shareButton.frame.size.width + 10, 0, 48, 48);
        [_sparkButton setImage:[[UIImage imageNamed:@"boltIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        _sparkButton.adjustsImageWhenHighlighted = false;
        [self addTapHandlersToAction:_sparkButton];
        [self addSubview:_sparkButton];
        
        _topSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, 0, 1, (1 / [UIScreen mainScreen].scale))];
        _topSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08];
        [self addSubview:_topSeparator];
        
        _bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, self.frame.size.height - _topSeparator.frame.size.height, 1, (1 / [UIScreen mainScreen].scale))];
        _bottomSeparator.backgroundColor = [UIColor colorWithWhite:0 alpha:0.08];
        [self addSubview:_bottomSeparator];
    }
    return self;
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

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonWidth = self.frame.size.width / 3;
    _replyButton.frame = CGRectMake(0, 0, buttonWidth, self.frame.size.height);
    _sparkButton.frame = CGRectMake(_replyButton.frame.origin.x + _replyButton.frame.size.width, 0, buttonWidth, self.frame.size.height);
    _shareButton.frame = CGRectMake(self.frame.size.width - buttonWidth, 0, buttonWidth, self.frame.size.height);
    
    
}

- (void)pushButtonDown:(UIButton *)button {
    [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        button.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:nil];
}
- (void)pushButtonUp:(UIButton *)button {
    [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
        button.transform = CGAffineTransformMakeScale(1, 1);
    } completion:nil];
}

@end
