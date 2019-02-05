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
#import <Tweaks/FBTweakInline.h>

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
        
        fromView.layer.cornerRadius = 0;
        
        toView.layer.cornerRadius = 32.f;
        toView.frame = CGRectMake(0, toView.frame.size.height, toView.frame.size.width, toView.frame.size.height);
        
        CGFloat animationDuration = FBTweakValue(@"Transitions", @"View Controller - Appearing", @"Duration", 0.6);
        CGFloat animationDamping = FBTweakValue(@"Transitions", @"View Controller - Appearing", @"Damping", 0.88);
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            fromView.alpha = 0;
            fromView.layer.cornerRadius = 32.f;
            fromView.transform = CGAffineTransformMakeScale(0.88, 0.88);
            
            toView.center = CGPointMake(containerView.frame.size.width / 2, containerView.frame.size.height / 2);
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            toView.layer.cornerRadius = 0;
        }];
    }
    else {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.07f alpha:1];
        
        [containerView addSubview:toView];
        [containerView bringSubviewToFront:fromView];
        
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(0.88, 0.88);
        toView.layer.cornerRadius = 32.f;
        fromView.alpha = 1;
        fromView.layer.cornerRadius = 0;
        
        CGFloat animationDuration = FBTweakValue(@"Transitions", @"View Controller - Dismissing", @"Duration", 0.8);
        CGFloat animationDamping = FBTweakValue(@"Transitions", @"View Controller - Dismissing", @"Damping", 0.75);
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformMakeScale(1, 1);
            toView.layer.cornerRadius = 0;
            
            fromView.layer.cornerRadius = 32.f;
            fromView.transform = CGAffineTransformMakeScale(0.88, 0.88);
            fromView.center = CGPointMake(containerView.frame.size.width / 2, containerView.frame.size.height * 1.5);
            fromView.layer.cornerRadius = 32.f;
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
