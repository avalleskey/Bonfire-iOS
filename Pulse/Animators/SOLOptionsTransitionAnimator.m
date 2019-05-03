//
//  SOLOptionsTransitionAnimator.m
//  PresentingFun
//
//  Created by Jesse Wolff on 10/31/13.
//  Copyright (c) 2013 Soleares, Inc. All rights reserved.
//

#import "SOLOptionsTransitionAnimator.h"
#import <UIKit/UIKit.h>
#import "Session.h"
#import "UIColor+Palette.h"

@implementation SOLOptionsTransitionAnimator

#pragma mark - UIViewControllerAnimatedTransitioning

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    fromView.layer.masksToBounds = true;
    toView.layer.masksToBounds = true;
    
    if (self.appearing) {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.07f alpha:1];
        
        [containerView addSubview:toView];
        
        toView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 32.f : 8.f;
        fromView.layer.cornerRadius = toView.layer.cornerRadius;
        
        CGFloat x = (self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) ? containerView.frame.size.width : 0;
        if (self.direction == SOLTransitionDirectionRight) x = (x * -1);
        
        CGFloat y = (self.direction == SOLTransitionDirectionUp || self.direction == SOLTransitionDirectionDown) ? containerView.frame.size.height : 0;
        if (self.direction == SOLTransitionDirectionDown) y = (y * -1);
        
        toView.frame = CGRectMake(x, y, toView.frame.size.width, toView.frame.size.height);
        
        CGFloat animationDuration = 0.56;
        CGFloat animationDamping = 0.88;
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            fromView.alpha = 0;
            fromView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            
            toView.center = CGPointMake(containerView.frame.size.width / 2, containerView.frame.size.height / 2);
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            toView.layer.cornerRadius = 0;
            fromView.layer.cornerRadius = 0;
        }];
    }
    else {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.07f alpha:1];
        
        [containerView addSubview:toView];
        [containerView bringSubviewToFront:fromView];
        
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        toView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 32.f : 8.f;
        fromView.alpha = 1;
        fromView.layer.cornerRadius = toView.layer.cornerRadius;
        
        CGFloat centerX = containerView.frame.size.width * ((self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) ? 1.5 : 0.5);
        if (self.direction == SOLTransitionDirectionLeft) centerX = (centerX * -1);
        
        CGFloat centerY = containerView.frame.size.height * ((self.direction == SOLTransitionDirectionUp || self.direction == SOLTransitionDirectionDown) ? 1.5 : 0.5);
        if (self.direction == SOLTransitionDirectionDown) centerY = (centerY * -1);
        
        CGFloat animationDuration = 0.7;
        CGFloat animationDamping = 0.75;
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformMakeScale(1, 1);
            
            fromView.transform = CGAffineTransformMakeScale(1, 1);
            fromView.center = CGPointMake(centerX, centerY);
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            toView.layer.cornerRadius = 0;
            fromView.layer.cornerRadius = 0;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.8f;
}

@end
