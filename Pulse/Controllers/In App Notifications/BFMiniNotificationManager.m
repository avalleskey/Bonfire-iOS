//
//  BFMiniNotificationManager.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFMiniNotificationManager.h"
#import "Camp.h"
#import "User.h"
#import "Launcher.h"
#import <HapticHelper/HapticHelper.h>

@implementation BFMiniNotificationManager

+ (BFMiniNotificationManager *)sharedInstance {
    static BFMiniNotificationManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (id)init {
    self = [super init];
    
    if (self) {
        self.presenting = false;
        
        self.notifications = [[NSMutableArray alloc] init];
    }
    
    return self;
}

+ (BFMiniNotificationManager *)manager {
    return [BFMiniNotificationManager sharedInstance];
}

- (BOOL)isPresenting {
    return self.presenting;
}

- (void)presentNotification:(BFMiniNotificationObject *)notificationObject completion:(void (^_Nullable)(void))completion {
    BFMiniNotificationView *notificationView = [[BFMiniNotificationView alloc] initWithObject:notificationObject];
    [self presentNotificationView:notificationView completion:completion];
}

- (void)presentNotificationView:(BFMiniNotificationView *)notificationView completion:(void (^ _Nullable)(void))completion {
    self.presenting = true;
    
    CGFloat notificaitonViewHeight = notificationView.frame.size.height;
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;

    CGFloat yTop = (safeAreaInsets.top == 0 ? notificationView.frame.origin.x : safeAreaInsets.top) + 4;
    
    [self.notifications addObject:notificationView];
    
    notificationView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, -1 * (notificaitonViewHeight * 2) - 16);
    
    // add subview to window
    [[[UIApplication sharedApplication] keyWindow] addSubview:notificationView];
    
    [UIView animateWithDuration:1.2 delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        notificationView.center = CGPointMake(notificationView.center.x, yTop + (notificaitonViewHeight / 2));
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
        
        for (BFMiniNotificationView *subview in self.notifications) {
            if (subview != notificationView) {
                // hide subviews behind current one
                [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.7f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    subview.alpha = 0;
                } completion:^(BOOL finished) {
                    [self.notifications removeObject:subview];
                }];
            }
        }
    }];
    
    // set a timer to dismiss the notification view
    [self dismissNotificationView:notificationView delay:3.f];
}
- (void)hideAllNotifications {
    for (BFMiniNotificationView *notificationView in self.notifications) {
        [self dismissNotificationView:notificationView];
    }
    self.presenting = false;
}

- (void)dismissNotificationView:(BFMiniNotificationView *)notificationView {
    [UIView animateWithDuration:1.2 delay:0 usingSpringWithDamping:0.6f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        notificationView.center = CGPointMake(notificationView.center.x, -1 * (notificationView.frame.size.height * 2) - 16);
    } completion:^(BOOL finished) {
        [notificationView removeFromSuperview];
        [self.notifications removeObject:notificationView];
    }];
}
- (void)dismissNotificationView:(BFMiniNotificationView *)notificationView delay:(CGFloat)delay {
    wait(delay, ^{
        if (notificationView.tag != 1) {
            [self dismissNotificationView:notificationView];
        }
        else {
            [self dismissNotificationView:notificationView delay:delay];
        }
    });
}

@end
