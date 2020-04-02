//
//  BFCameraAnimator.m
//

#import "BFCameraAnimator.h"
#import "UIColor+Palette.h"

@interface BFCameraAnimator()
@property (weak, nonatomic) UIViewController *toViewController;
@property (weak, nonatomic) UIViewController *fromViewController;
@end

@implementation BFCameraAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    if (self.appearing) {
        return [transitionContext transitionWasCancelled] ? 0.5f : 0.8f;
    }
    else {
        return [transitionContext transitionWasCancelled] ? 0.5f : ([transitionContext isInteractive] ? 1.2f : 0);
    }
}

// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *containerView = [transitionContext containerView];
    containerView.backgroundColor = [UIColor redColor];
    
    UIView *fromView = fromViewController.view;
    UIView *toView = toViewController.view;
    fromView.layer.masksToBounds = false;
    toView.layer.masksToBounds = false;
            
    CGFloat animationDamping = 0.9;
    
    [containerView addSubview:toView];
    
    if (self.appearing) {
        toView.alpha = 0;
        toView.transform = CGAffineTransformMakeScale(0.1, 0.1);
        
        // TODO: use actual sender point
        toView.center = CGPointMake(100, [UIScreen mainScreen].bounds.size.height - 300);
        fromView.alpha = 1;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5 options:(UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveLinear) animations:^{
            toView.transform = CGAffineTransformIdentity;
            toView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height / 2);
            toView.alpha = 1;
            
            fromView.alpha = 0;
        } completion:^(BOOL finished) {
            if ([transitionContext transitionWasCancelled]) {
                [toView removeFromSuperview];
            }
            else {
                [fromView removeFromSuperview];
                toView.userInteractionEnabled = YES;
            }
            
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
    else {
        [containerView bringSubviewToFront:fromView];
        
        toView.alpha = 0;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5 options:(UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveLinear) animations:^{
            if ([transitionContext isInteractive]) {
                fromView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height * 0.8);
                fromView.transform = CGAffineTransformMakeScale(0.95, 0.95);
                
                toView.alpha = 0.3;
            }
        } completion:^(BOOL finished) {
            if ([transitionContext transitionWasCancelled]) {
                [toView removeFromSuperview];
            }
            else {
                [fromView removeFromSuperview];
                toView.userInteractionEnabled = YES;
            }
            
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }

    self.fromViewController = fromViewController;
    self.toViewController = toViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was canceled
    if (!transitionCompleted) {
        // NSLog(@"we got canceled rip");
    }
}

@end
