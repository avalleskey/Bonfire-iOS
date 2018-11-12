//
//  PostActionsView.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "PostActionsView.h"
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>
#import "Session.h"

@implementation PostActionsView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        
        _sparkButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_sparkButton setTitle:[Session sharedInstance].defaults.post.displayVote.text forState:UIControlStateNormal];
        _sparkButton.frame = CGRectMake(0, 0, 98, 42);
        _sparkButton.backgroundColor = [UIColor whiteColor];
        _sparkButton.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"star"]) {
            [_sparkButton setImage:[[UIImage imageNamed:@"postActionStar"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"heart"]) {
            [_sparkButton setImage:[[UIImage imageNamed:@"postActionHeart"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"thumb"]) {
            [_sparkButton setImage:[[UIImage imageNamed:@"postActionThumb"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else if ([[Session sharedInstance].defaults.post.displayVote.icon isEqualToString:@"flame"]) {
            [_sparkButton setImage:[[UIImage imageNamed:@"postActionFlame"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        else {
            [_sparkButton setImage:[[UIImage imageNamed:@"postActionBolt"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        [_sparkButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        [_sparkButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
        _sparkButton.adjustsImageWhenHighlighted = false;
        
        [_sparkButton bk_addEventHandler:^(id sender) {
            [self pushButtonDown:self.sparkButton];
        } forControlEvents:UIControlEventTouchDown];
        
        [_sparkButton bk_addEventHandler:^(id sender) {
            [self pushButtonUp:self.sparkButton];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [self addSubview:_sparkButton];
        
        _shareButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _shareButton.frame = CGRectMake(12, 0, (self.frame.size.width - 24) / 2, 44);
        [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
        _shareButton.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightSemibold];
        [_shareButton setTitleColor:[UIColor colorWithWhite:0.47 alpha:1] forState:UIControlStateNormal];
        [_shareButton setImage:[[UIImage imageNamed:@"shareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_shareButton setTintColor:[UIColor colorWithWhite:0.47 alpha:1]];
        [_shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 6, 0, 0)];
        [_shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 6)];
        _shareButton.adjustsImageWhenHighlighted = false;
        _shareButton.layer.masksToBounds = true;
        
        [_shareButton bk_addEventHandler:^(id sender) {
            [self pushButtonDown:self.shareButton];
        } forControlEvents:UIControlEventTouchDown];
        
        [_shareButton bk_addEventHandler:^(id sender) {
            [self pushButtonUp:self.shareButton];
        } forControlEvents:(UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
        [self addSubview:_shareButton];
        
        self.lineSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, 0, 1, self.frame.size.height)];
        self.lineSeparator.backgroundColor = [UIColor colorWithWhite:0.95f alpha:1];
        [self addSubview:self.lineSeparator];
    }
    return self;
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
