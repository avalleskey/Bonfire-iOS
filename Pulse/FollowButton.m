//
//  FollowButton.m
//  Pulse
//
//  Created by Austin Valleskey on 9/20/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "FollowButton.h"
#import "RoomContext.h"
#import "Session.h"

@implementation FollowButton

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 6);
        self.titleEdgeInsets = UIEdgeInsetsMake(0, 6, 0, 0);
        self.titleLabel.font = [UIFont systemFontOfSize:16.f weight:UIFontWeightBold];
        self.adjustsImageWhenHighlighted = false;
        self.backgroundColor = [UIColor colorWithWhite:1.f alpha:0.2f];
        self.layer.cornerRadius = 10.f;
        self.layer.masksToBounds = false;
        self.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.06f].CGColor;
        self.layer.borderWidth = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}

- (void)updateStatus:(NSString *)status {
    NSLog(@"status: %@", status);
    
    self.status = status;
    // set icon + title
    if ([status isEqualToString:STATUS_MEMBER]) {
        [self setImage:[[UIImage imageNamed:@"checkIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:[NSString stringWithFormat:@"%@", [Session sharedInstance].defaults.room.followingVerb] forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:STATUS_REQUESTED]) {
        [self setImage:[[UIImage imageNamed:@"clockIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Requested" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:STATUS_BLOCKED]) {
        NSLog(@"blocked!!!! wee ooo wee wooo");
        [self setImage:[[UIImage imageNamed:@"blockedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Blocked" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:STATUS_ROOM_BLOCKED]) {
        [self setImage:[[UIImage imageNamed:@"blockedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Unavailable" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:STATUS_LOADING]) {
        [self setImage:nil forState:UIControlStateNormal];
        [self setTitle:@"Loading..." forState:UIControlStateNormal];
    }
    else {
        // STATUS_LEFT, STATUS_NO_RELATION, STATUS_INVITED
        [self setImage:[[UIImage imageNamed:@"plusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:[NSString stringWithFormat:@"%@ Room", [Session sharedInstance].defaults.room.followVerb] forState:UIControlStateNormal];
    }
    
    // set filled state + colors
    UIColor *disabledColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
    UIColor *themeColor = self.superview.tintColor;
    
    if ([status isEqualToString:STATUS_MEMBER] ||
        [status isEqualToString:STATUS_REQUESTED] ||
        [status isEqualToString:STATUS_BLOCKED] ||
        [status isEqualToString:STATUS_ROOM_BLOCKED]) {
        self.layer.borderWidth = 0;
        self.tintColor = [UIColor whiteColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        if ([status isEqualToString:STATUS_MEMBER]) {
            self.backgroundColor = themeColor;
        }
        else if ([status isEqualToString:STATUS_REQUESTED] ||
                 [status isEqualToString:STATUS_BLOCKED] ||
                 [status isEqualToString:STATUS_ROOM_BLOCKED]) {
            self.backgroundColor = disabledColor;
        }
    }
    else {
        self.layer.borderWidth = 1.f;
        self.backgroundColor = [UIColor clearColor];
        
        if ([status isEqualToString:STATUS_LOADING]) {
            self.tintColor = disabledColor;
            [self setTitleColor:disabledColor forState:UIControlStateNormal];
        }
        else {
            self.tintColor = themeColor;
            [self setTitleColor:themeColor forState:UIControlStateNormal];
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (![self.status isEqualToString:STATUS_REQUESTED] &&
        ![self.status isEqualToString:STATUS_BLOCKED] &&
        ![self.status isEqualToString:STATUS_ROOM_BLOCKED] ||
        ![self.status isEqualToString:STATUS_LOADING]) {
        if (highlighted) {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformMakeScale(0.92, 0.92);
            } completion:nil];
        }
        else {
            [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.transform = CGAffineTransformIdentity;
            } completion:nil];
        }
    }
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

@end
