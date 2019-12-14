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

- (void)addLeftSideShadowWithFading:(UIView *)view
{
    CGFloat shadowWidth = 1.0f;
    CGFloat shadowVerticalPadding = -20.0f; // negative padding, so the shadow isn't rounded near the top and the bottom
    CGFloat shadowHeight = CGRectGetHeight(view.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    view.layer.shadowPath = [shadowPath CGPath];
    view.layer.shadowRadius = 2;
    view.layer.shadowOpacity = 0.4;
    view.layer.shadowColor = [UIColor blackColor].CGColor;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromVC = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIView *fromView = fromVC.view;
    UIView *toView = toVC.view;
    
    if (self.appearing) {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.05f alpha:1];
        
        [containerView addSubview:toView];
        
        CGFloat animationDuration = 0.45;
        CGFloat animationDamping = 0.85;
        if (self.direction == SOLTransitionDirectionUp || self.direction == SOLTransitionDirectionDown) {
            toView.center = CGPointMake(toView.center.x, containerView.frame.size.height * 1.5);
            toView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 32.f : 8.f;
            fromView.layer.masksToBounds = true;
            animationDuration = 0.5;
            animationDamping = 0.98;
            toView.layer.masksToBounds = true;
        }
        else {
            toView.center = CGPointMake(containerView.frame.size.width * 1.5, toView.center.y);
            [self addLeftSideShadowWithFading:toView];
            toView.layer.masksToBounds = false;
        }
        
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            if (self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) {
                fromView.transform = CGAffineTransformMakeTranslation((self.direction == SOLTransitionDirectionLeft ? -1 : 1) * .25 * containerView.frame.size.width, 0);
                fromView.alpha = 0.8;
            }
            else {
                fromView.alpha = 0.8;
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
        
        fromView.alpha = 1;
        
        CGFloat animationDuration;
        
        if (self.direction == SOLTransitionDirectionLeft || self.direction == SOLTransitionDirectionRight) {
            toView.transform = CGAffineTransformMakeTranslation((self.direction == SOLTransitionDirectionLeft ? -1 : 1) * .25 * containerView.frame.size.width, 0);
            [self addLeftSideShadowWithFading:toView];
            fromView.layer.masksToBounds = false;
            toView.alpha = 0.8;
            
            animationDuration = 0.55f;
        }
        else {
            toView.alpha = 0.8;
            fromView.layer.cornerRadius = HAS_ROUNDED_CORNERS ? 32.f : 8.f;
            fromView.layer.masksToBounds = true;
            
            animationDuration = 0.45f;
        }
        
        [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:0.5f options:(UIViewAnimationOptionCurveEaseInOut|UIViewAnimationOptionAllowUserInteraction) animations:^{
            toView.alpha = 1;
            
            if (self.direction == SOLTransitionDirectionUp || self.direction == SOLTransitionDirectionDown) {
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
