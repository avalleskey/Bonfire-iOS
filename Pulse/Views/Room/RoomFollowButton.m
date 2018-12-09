//
//  RoomFollowButton.m
//  Pulse
//
//  Created by Austin Valleskey on 11/26/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "RoomFollowButton.h"
#import "RoomContext.h"
#import "Session.h"

@implementation RoomFollowButton

- (void)updateStatus:(NSString *)status {
    self.status = status;
    // set icon + title
    if ([status isEqualToString:ROOM_STATUS_MEMBER]) {
        [self setImage:[[UIImage imageNamed:@"checkIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:[NSString stringWithFormat:@"%@", [Session sharedInstance].defaults.room.followingVerb] forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:ROOM_STATUS_REQUESTED]) {
        [self setImage:[[UIImage imageNamed:@"clockIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Requested" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:ROOM_STATUS_BLOCKED]) {
        [self setImage:[[UIImage imageNamed:@"blockedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Blocked" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:ROOM_STATUS_ROOM_BLOCKED]) {
        [self setImage:[[UIImage imageNamed:@"blockedIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self setTitle:@"Unavailable" forState:UIControlStateNormal];
    }
    else if ([status isEqualToString:ROOM_STATUS_LOADING]) {
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
    
    if ([status isEqualToString:ROOM_STATUS_MEMBER] ||
        [status isEqualToString:ROOM_STATUS_REQUESTED]) {
        self.layer.borderWidth = 1.f;
        self.backgroundColor = [UIColor clearColor];
        
        self.tintColor = [UIColor colorWithWhite:0.2f alpha:1];
        [self setTitleColor:[UIColor colorWithWhite:0.2f alpha:1] forState:UIControlStateNormal];
    }
    else {
        self.layer.borderWidth = 0;
        self.tintColor = [UIColor whiteColor];
        [self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        
        if ([status isEqualToString:ROOM_STATUS_REQUESTED] ||
                 [status isEqualToString:ROOM_STATUS_BLOCKED] ||
                 [status isEqualToString:ROOM_STATUS_ROOM_BLOCKED] ||
                 [status isEqualToString:ROOM_STATUS_LOADING]) {
            self.backgroundColor = disabledColor;
        }
        else {
            self.backgroundColor = themeColor;
        }
    }
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    if (![self.status isEqualToString:ROOM_STATUS_REQUESTED] &&
        ![self.status isEqualToString:ROOM_STATUS_BLOCKED] &&
        ![self.status isEqualToString:ROOM_STATUS_ROOM_BLOCKED] &&
        ![self.status isEqualToString:ROOM_STATUS_LOADING]) {
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
