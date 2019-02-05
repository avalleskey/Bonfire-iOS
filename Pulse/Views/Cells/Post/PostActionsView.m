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
#import "UIColor+Palette.h"

@implementation PostActionsView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        self.layer.cornerRadius = 10.f;
        self.layer.masksToBounds = true;
        self.backgroundColor = [UIColor whiteColor];
        self.layer.borderColor = [UIColor colorWithWhite:0.92 alpha:1].CGColor;
        self.layer.borderWidth = (1 / [UIScreen mainScreen].scale);
        
        _middleSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2, 8, (1 / [UIScreen mainScreen].scale), self.frame.size.height - 16)];
        _middleSeparator.layer.cornerRadius = _middleSeparator.frame.size.width / 2;
        _middleSeparator.layer.masksToBounds = true;
        _middleSeparator.backgroundColor = [UIColor colorWithWhite:0.92 alpha:1];
        [self addSubview:_middleSeparator];
        
        _shareButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _shareButton.frame = CGRectMake(0, 0, 48, 48);
        [_shareButton setTitle:@"Share" forState:UIControlStateNormal];
        _shareButton.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        [_shareButton setTitleColor:[UIColor bonfireGrayWithLevel:800] forState:UIControlStateNormal];
        [_shareButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 8)];
        [_shareButton setImageEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 10)];
        /*_shareButton.layer.cornerRadius = _shareButton.frame.size.height / 2;
        _shareButton.layer.borderWidth = 1.f;
        _shareButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
        _shareButton.layer.masksToBounds = true;
        _shareButton.backgroundColor = [UIColor whiteColor];*/
        [_shareButton setImage:[[UIImage imageNamed:@"shareIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [_shareButton setTintColor:_shareButton.currentTitleColor];
        _shareButton.adjustsImageWhenHighlighted = false;
        _shareButton.layer.masksToBounds = true;
        [self addSubview:_shareButton];
        
        _sparkButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _sparkButton.frame = CGRectMake(_shareButton.frame.origin.x + _shareButton.frame.size.width + 10, 0, 48, 48);
        [_sparkButton setTitle:[Session sharedInstance].defaults.post.displayVote.text forState:UIControlStateNormal];
        _sparkButton.titleLabel.font = _shareButton.titleLabel.font;
        [_sparkButton setTitleEdgeInsets:UIEdgeInsetsMake(0, 10, 0, 0)];
        [_sparkButton setImageEdgeInsets:UIEdgeInsetsMake(0, 8, 0, 10)];
        /*_sparkButton.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06].CGColor;
        _sparkButton.layer.cornerRadius = _shareButton.layer.cornerRadius;
        _sparkButton.layer.masksToBounds = true;
        _sparkButton.backgroundColor = [UIColor colorWithWhite:0.98 alpha:1];*/
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
        _sparkButton.adjustsImageWhenHighlighted = false;
        [self addSubview:_sparkButton];
        
        _topSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, 0, 1, (1 / [UIScreen mainScreen].scale))];
        _topSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:_topSeparator];
        
        _bottomSeparator = [[UIView alloc] initWithFrame:CGRectMake(self.frame.size.width / 2 - .5, self.frame.size.height - _topSeparator.frame.size.height, 1, (1 / [UIScreen mainScreen].scale))];
        _bottomSeparator.backgroundColor = [UIColor separatorColor];
        [self addSubview:_bottomSeparator];
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
