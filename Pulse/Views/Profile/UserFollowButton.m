//
//  UserFollowButton.m
//  Pulse
//
//  Created by Austin Valleskey on 11/26/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "UserFollowButton.h"
#import "UserContext.h"
#import "Session.h"

@implementation UserFollowButton

- (void)updateStatus:(NSString *)status {
    self.status = status;

    // set icon + title
    if ([status isEqualToString:USER_STATUS_FOLLOWS] ||
        [status isEqualToString:USER_STATUS_FOLLOW_BOTH]) {
        [self setImage:[[UIImage imageNamed:@"checkIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Following" forState:UIControlStateNormal];
    }
    /*
    else if ([status isEqualToString:USER_STATUS_REQUESTED]) {
        [self setImage:[[UIImage imageNamed:@"clockIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Requested" forState:UIControlStateNormal];
    }*/
    else if ([status isEqualToString:USER_STATUS_BLOCKED] ||
             [status isEqualToString:USER_STATUS_BLOCKS] ||
             [status isEqualToString:USER_STATUS_BLOCKS_BOTH]) {
        NSLog(@"blocked!!!! wee ooo wee wooo");
        [self setImage:[[UIImage imageNamed:@"blockedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Blocked" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:USER_STATUS_LOADING]) {
        [self setImage:nil forState:UIControlStateNormal];
        [self setTitle:@"Loading..." forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:USER_STATUS_ME]) {
        [self setImage:nil forState:UIControlStateNormal];
        [self setTitle:@"Edit Profile" forState:UIControlStateNormal];
    }
    else {
        // USER_STATUS_NO_RELATION
        [self setImage:[[UIImage imageNamed:@"plusIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Follow" forState:UIControlStateNormal];
    }
    
    // set filled state + colors
    UIColor *disabledColor = [UIColor colorWithRed:0.52 green:0.53 blue:0.55 alpha:1.0];
    UIColor *themeColor = self.superview.tintColor;
    
    if ([status isEqualToString:USER_STATUS_FOLLOWS] ||
        //[status isEqualToString:USER_STATUS_REQUESTED] ||
        [status isEqualToString:USER_STATUS_BLOCKS_BOTH] ||
        [status isEqualToString:USER_STATUS_BLOCKS] ||
        [status isEqualToString:USER_STATUS_BLOCKED]) {
        self.layer.borderWidth = 0;
        self.tintColor = [UIColor whiteColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        if ([status isEqualToString:USER_STATUS_FOLLOWS]) {
            self.backgroundColor = themeColor;
        }
        else if ([status isEqualToString:USER_STATUS_BLOCKS_BOTH] ||
                 [status isEqualToString:USER_STATUS_BLOCKS] ||
                 [status isEqualToString:USER_STATUS_BLOCKED]) {
            self.backgroundColor = disabledColor;
        }
    }
    else {
        self.layer.borderWidth = 1.f;
        self.backgroundColor = [UIColor clearColor];
        
        if ([status isEqualToString:USER_STATUS_LOADING]) {
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
    
    if (//![self.status isEqualToString:USER_STATUS_REQUESTED] &&
        ![self.status isEqualToString:USER_STATUS_BLOCKS_BOTH] &&
        ![self.status isEqualToString:USER_STATUS_BLOCKS] &&
        ![self.status isEqualToString:USER_STATUS_BLOCKED] &&
        ![self.status isEqualToString:USER_STATUS_LOADING]) {
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

@end
