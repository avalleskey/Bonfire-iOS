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
        containerView.backgroundColor = [UIColor colorWithWhite:0.05f alpha:1];
        
        [containerView addSubview:toView];
        
        CGFloat animationDuration = 0.5;
        CGFloat animationDamping = 0.85;
        if (self.direction == SOLTransitionDirectionUp || self.direction == SOLTransitionDirectionDown) {
            toView.center = CGPointMake(toView.center.x, containerView.frame.size.height * 1.5);
            toView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 32.f : 8.f;
            animationDuration = 0.4;
            animationDamping = 0.98;
        }
        else {
            toView.center = CGPointMake(containerView.frame.size.width * 1.5, toView.center.y);
        }
        
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            fromView.alpha = 0.6;
            if (self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) {
                fromView.transform = CGAffineTransformMakeTranslation((self.direction == SOLTransitionDirectionLeft ? -1 : 1) * .25 * containerView.frame.size.width, 0);
            }
            
            toView.center = CGPointMake(containerView.frame.size.width / 2, containerView.frame.size.height / 2);
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            toView.layer.cornerRadius = 0;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.05f alpha:1];
        
        [containerView addSubview:toView];
        [containerView bringSubviewToFront:fromView];
        
        toView.alpha = 0.6;
        fromView.alpha = 1;
        
        if (self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) {
            toView.transform = CGAffineTransformMakeTranslation((self.direction == SOLTransitionDirectionLeft ? -1 : 1) * .25 * containerView.frame.size.width, 0);
        }
        else {
            fromView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 32.f : 8.f;
            fromView.layer.masksToBounds = true;
        }
        
        CGFloat animationDuration = 0.55f;
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            toView.alpha = 1;
            toView.transform = CGAffineTransformMakeScale(1, 1);
            
            if (self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) {
                toView.transform = CGAffineTransformMakeScale(1, 1);
            }
            else if (self.direction == SOLTransitionDirectionUp || self.direction == SOLTransitionDirectionDown) {
                fromView.center = CGPointMake(fromView.center.x, containerView.frame.size.height * 1.5);
            }
        } completion:^(BOOL finished) {
            [fromView removeFromSuperview];
            toView.userInteractionEnabled = YES;
            fromView.layer.cornerRadius = 0;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    return 0.5f;
}

@end
