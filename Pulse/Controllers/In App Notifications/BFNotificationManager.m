//
//  TipsManager.m
//  Pulse
//
//  Created by Austin Valleskey on 5/2/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFNotificationManager.h"
#import "Camp.h"
#import "User.h"
#import "Launcher.h"
#import <HapticHelper/HapticHelper.h>

@implementation BFNotificationManager

+ (BFNotificationManager *)sharedInstance {
    static BFNotificationManager *_sharedInstance = nil;
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

+ (BFNotificationManager *)manager {
    return [BFNotificationManager sharedInstance];
}

- (BOOL)isPresenting {
    return self.presenting;
}

- (void)presentNotification:(BFNotificationObject *)notificationObject completion:(void (^)(void))completion {
    BFNotificationView *notificationView = [[BFNotificationView alloc] initWithObject:notificationObject];
    [self presentNotificationView:notificationView completion:completion];
}

- (void)presentNotificationView:(BFNotificationView *)notificationView completion:(void (^ __nullable)(void))completion {
    self.presenting = true;
    
    CGFloat notificaitonViewHeight = notificationView.frame.size.height;
    UIEdgeInsets safeAreaInsets = [[[UIApplication sharedApplication] delegate] window].safeAreaInsets;

    CGFloat yTop = (safeAreaInsets.top == 0 ? notificationView.frame.origin.x : safeAreaInsets.top);
    
    [self.notifications addObject:notificationView];
    
    notificationView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, -1 * (notificaitonViewHeight * 2) - 16);
    
    // add subview to window
    [[[UIApplication sharedApplication] keyWindow] addSubview:notificationView];
    
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        notificationView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, yTop + (notificaitonViewHeight / 2));
    } completion:^(BOOL finished) {
        completion();
        
        for (BFNotificationView *subview in self.notifications) {
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
    //[HapticHelper generateFeedback:FeedbackType_Impact_Medium];
    
    // set a timer to dismiss the notification view
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.5f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        for (BFNotificationView *subview in self.notifications) {
            if (subview == notificationView) {
                [self dismissNotificationView:notificationView];
            }
        }
    });
}
- (void)hideAllNotifications {
    for (BFNotificationView *notificationView in self.notifications) {
        [self dismissNotificationView:notificationView];
    }
    self.presenting = false;
}

- (void)dismissNotificationView:(BFNotificationView *)notificationView {
    [UIView animateWithDuration:0.8 delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        notificationView.center = CGPointMake(notificationView.center.x, -1 * (notificationView.frame.size.height * 2) - 16);
    } completion:^(BOOL finished) {
        [notificationView removeFromSuperview];
        [self.notifications removeObject:notificationView];
    }];
}

@end
