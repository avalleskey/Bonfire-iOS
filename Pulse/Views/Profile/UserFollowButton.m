//
//  UserFollowButton.m
//  Pulse
//
//  Created by Austin Valleskey on 11/26/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "UserFollowButton.h"
#import "Session.h"
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>

@implementation UserFollowButton

- (void)updateStatus:(NSString *)status {
    self.status = status;
    
    // set icon + title
    if ([status isEqualToString:USER_STATUS_FOLLOWS] ||
        [status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
        [self setImage:[[UIImage imageNamed:@"checkIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:([status isEqualToString:USER_STATUS_FOLLOW_BOTH] ? @"Friends" : @"Subscribed") forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:USER_STATUS_BLOCKED] ||
             [status isEqualToString:USER_STATUS_BLOCKS] ||
             [status isEqualToString:USER_STATUS_BLOCKS_BOTH]) {
        [self setImage:[[UIImage imageNamed:@"blockedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Blocked" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:USER_STATUS_LOADING]) {
        [self setImage:nil forState:UIControlStateNormal];
        [self setTitle:@"Loading..." forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:USER_STATUS_ME]) {
        [self setImage:[[UIImage imageNamed:@"inviteFriendIcon_small"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        
        NSInteger invites = [Session sharedInstance].currentUser.attributes.invites.numAvailable;
        if (invites > 0) {
            [self setTitle:[NSString stringWithFormat:@"%lu Invite%@", invites, (invites == 1 ? @"" : @"s")] forState:UIControlStateNormal];
        }
        else {
            [self setTitle:@"Invite Friends" forState:UIControlStateNormal];
        }
    }
    else {
        // USER_STATUS_NO_RELATION
        [self setImage:[[UIImage imageNamed:@"plusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:([status isEqualToString:USER_STATUS_FOLLOWED]?@"Add Back":@"Add Friend") forState:UIControlStateNormal];
    }
    
    // set filled state + colors
    UIColor *disabledColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
    UIColor *themeColor = self.superview.tintColor;
    
    BOOL userInteractionEnabled = true;
    if ([status isEqualToString:USER_STATUS_FOLLOWS] ||
        [status isEqualToString:USER_STATUS_FOLLOW_BOTH] ||
        [status isEqualToString:USER_STATUS_ME] ||
        [status isEqualToString:USER_STATUS_LOADING] ||
        [status isEqualToString:USER_STATUS_BLOCKS]) {
        self.layer.borderWidth = 1.f;
        self.backgroundColor = [UIColor clearColor];
        
        if ([status isEqualToString:USER_STATUS_LOADING]) {
            self.tintColor = disabledColor;
        }
        else {
            self.tintColor = [UIColor bonfirePrimaryColor];
        }
        [self setTitleColor:self.tintColor forState:UIControlStateNormal];
    }
    else {
        self.layer.borderWidth = 0;
        
        if ([status isEqualToString:USER_STATUS_NO_RELATION] || [status isEqualToString:USER_STATUS_FOLLOWED]) {
            self.backgroundColor = themeColor;
        }
        else if ([status isEqualToString:USER_STATUS_BLOCKS_BOTH] ||
                 [status isEqualToString:USER_STATUS_BLOCKS] ||
                 [status isEqualToString:USER_STATUS_BLOCKED]) {
            self.backgroundColor = disabledColor;
            userInteractionEnabled = false;
        }
        
        if ([UIColor useWhiteForegroundForColor:self.backgroundColor]) {
            self.tintColor = [UIColor whiteColor];
            [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        }
        else {
            self.tintColor = [UIColor blackColor];
            [self setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        }
    }
    
    self.userInteractionEnabled = userInteractionEnabled;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (//![self.status isEqualToString:USER_STATUS_REQUESTED] &&
        ![self.status isEqualToString:USER_STATUS_BLOCKS_BOTH] &&
        ![self.status isEqualToString:USER_STATUS_BLOCKS] &&
        ![self.status isEqualToString:USER_STATUS_BLOCKED] &&
        ![self.status isEqualToString:USER_STATUS_LOADING]) {
        if (highlighted) {
            [UIView animateWithDuration:0.25 delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
//                self.transform = CGAffineTransformMakeScale(0.92, 0.92);
                self.alpha = 0.5;
            } completion:nil];
        }
        else {
            [UIView animateWithDuration:0.25     delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseOut animations:^{
//                self.transform = CGAffineTransformIdentity;
                self.alpha = 1;
            } completion:nil];
        }
    }
}

@end
