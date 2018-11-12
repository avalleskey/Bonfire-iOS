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
        containerView.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1];
        
        [containerView addSubview:toView];
        
        fromView.layer.cornerRadius = 12.f;
        
        toView.layer.cornerRadius = 24.f;
        toView.frame = CGRectMake(0, toView.frame.size.height, toView.frame.size.width, toView.frame.size.height);
        
        [UIView animateWithDuration:0.6f delay:0 usingSpringWithDamping:0.85 initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromView.alpha = 0.5;
            fromView.layer.cornerRadius = 24.f;
            fromView.transform = CGAffineTransformMakeScale(0.8, 0.8);
            
            toView.center = CGPointMake(containerView.frame.size.width / 2, containerView.frame.size.height / 2);
            toView.layer.cornerRadius = 0;
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.2f alpha:1];
        
        [containerView addSubview:toView];
        [containerView bringSubviewToFront:fromView];
        
        toView.alpha = 0.5;
        toView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        toView.layer.cornerRadius = 24.f;
        fromView.alpha = 1;
        fromView.layer.cornerRadius = 12.f;
        
        [UIView animateWithDuration:0.8f delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformMakeScale(1, 1);
            toView.layer.cornerRadius = 0;
            
            fromView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            fromView.center = CGPointMake(containerView.frame.size.width / 2, containerView.frame.size.height * 1.5);
            fromView.layer.cornerRadius = 24.f;
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.8f;
}

@end
