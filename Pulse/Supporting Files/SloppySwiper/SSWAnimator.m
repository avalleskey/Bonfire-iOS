//
//  SSWAnimator.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SSWAnimator.h"
#import "UIColor+Palette.h"

UIViewAnimationOptions const SSWNavigationTransitionCurve = 7 << 16;

@implementation UIView (TransitionShadow)
- (void)addLeftSideShadowWithFading
{
    CGFloat shadowWidth = 1.0f;
    CGFloat shadowVerticalPadding = -20.0f; // negative padding, so the shadow isn't rounded near the top and the bottom
    CGFloat shadowHeight = CGRectGetHeight(self.frame) - 2 * shadowVerticalPadding;
    CGRect shadowRect = CGRectMake(-shadowWidth, shadowVerticalPadding, shadowWidth, shadowHeight);
    UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRect:shadowRect];
    self.layer.shadowPath = [shadowPath CGPath];
    self.layer.shadowRadius = 2;
    self.layer.shadowOpacity = 0.4;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
}
@end

@interface SSWAnimator()
@property (weak, nonatomic) UIViewController *toViewController;
@property (weak, nonatomic) UIViewController *fromViewController;
@end

@implementation SSWAnimator

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext
{
    // Approximated lengths of the default animations.
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    if ([fromViewController isKindOfClass:[UINavigationController class]]) {
        return [transitionContext transitionWasCancelled] ? 1.f : 0.3f;
    }
    else {
        return [transitionContext transitionWasCancelled] ? 1.f : 0.5f;
    }
}

// Tries to animate a pop transition similarly to the default iOS' pop transition.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    
    UIView *fromView = fromViewController.view;
    UIView *toView = toViewController.view;
    fromView.layer.masksToBounds = false;
    toView.layer.masksToBounds = false;
    
    [[transitionContext containerView] insertSubview:toViewController.view belowSubview:fromViewController.view];
    
    if ([fromViewController isKindOfClass:[UINavigationController class]]) {
        UIView *containerView = [transitionContext containerView];
        containerView.backgroundColor = [UIColor colorWithWhite:0.05f alpha:1];
        
        toView.alpha = 0.8;
        toView.transform = CGAffineTransformMakeTranslation(-.25 * containerView.frame.size.width, 0);
        
        fromView.alpha = 1;
        [fromView addLeftSideShadowWithFading];
        
        CGFloat animationDuration = 0.5;
        CGFloat animationDamping = 0.9;
        
        if ([transitionContext isInteractive]) {
            [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionTransitionNone | UIViewAnimationOptionCurveLinear animations:^{
                toView.alpha = 1;
                toView.transform = CGAffineTransformIdentity;
                
                fromView.center = CGPointMake(containerView.frame.size.width * 1.5, fromView.center.y);
                
                fromView.layer.shadowOpacity = 0;
            } completion:^(BOOL finished) {
                if ([transitionContext transitionWasCancelled]) {
                    [toView removeFromSuperview];
                    
                    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                }
                else {
                    [fromView removeFromSuperview];
                    toView.userInteractionEnabled = YES;
                    
                    [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
                }
            }];
        }
        else {
            [UIView animateWithDuration:animationDuration delay:0 usingSpringWithDamping:animationDamping initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut animations:^{
                toView.alpha = 1;
                toView.transform = CGAffineTransformMakeTranslation(0, 0);
                
                fromView.center = CGPointMake(containerView.frame.size.width * 1.5, fromView.center.y);
                
                fromView.layer.shadowOpacity = 0;
            } completion:^(BOOL finished) {
                [fromView removeFromSuperview];
                toView.userInteractionEnabled = YES;
                
                [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            }];
        }
    }
    else {
        if (toViewController.navigationController != nil) {
            CGFloat yOrigin = toViewController.navigationController.navigationBar.frame.origin.y + toViewController.navigationController.navigationBar.frame.size.height;
            
            if (toViewController.navigationController.navigationBar.isTranslucent) {
                toViewController.view.frame = CGRectMake(toViewController.view.frame.origin.x, 0, toViewController.view.frame.size.width, [transitionContext containerView].frame.size.height);
            }
            else {
                toViewController.view.frame = CGRectMake(toViewController.view.frame.origin.x, yOrigin, toViewController.view.frame.size.width, [transitionContext containerView].frame.size.height - yOrigin);
            }
        }
        
        // parallax effect; the offset matches the one used in the pop animation in iOS 7.1
        CGFloat toViewControllerXTranslation = - CGRectGetWidth([transitionContext containerView].bounds) * 0.3f;
        toViewController.view.transform = CGAffineTransformMakeTranslation(toViewControllerXTranslation, 0);
        
        // add a shadow on the left side of the frontmost view controller
        BOOL previousClipsToBounds = fromViewController.view.clipsToBounds;
        fromViewController.view.clipsToBounds = NO;
        
        // in the default transition the view controller below is a little dimmer than the frontmost one
        UIView *dimmingView = [[UIView alloc] initWithFrame:toViewController.view.bounds];
        CGFloat dimAmount = [self.delegate animatorTransitionDimAmount:self];
        dimmingView.backgroundColor = [UIColor colorWithWhite:0.0f alpha:dimAmount];
        [toViewController.view addSubview:dimmingView];
        
        // fix hidesBottomBarWhenPushed not animated properly
        UITabBarController *tabBarController = toViewController.tabBarController;
        UINavigationController *navController = toViewController.navigationController;
        UITabBar *tabBar = tabBarController.tabBar;
        BOOL shouldAddTabBarBackToTabBarController = NO;
        
        BOOL tabBarControllerContainsToViewController = [tabBarController.viewControllers containsObject:toViewController];
        BOOL tabBarControllerContainsNavController = [tabBarController.viewControllers containsObject:navController];
        BOOL isToViewControllerFirstInNavController = [navController.viewControllers firstObject] == toViewController;
        BOOL shouldAnimateTabBar = [self.delegate animatorShouldAnimateTabBar:self];
        if (shouldAnimateTabBar && tabBar && (tabBarControllerContainsToViewController || (isToViewControllerFirstInNavController && tabBarControllerContainsNavController))) {
            [tabBar.layer removeAllAnimations];
            
            CGRect tabBarRect = tabBar.frame;
            tabBarRect.origin.x = toViewController.view.bounds.origin.x;
            tabBar.frame = tabBarRect;
            
            [toViewController.view addSubview:tabBar];
            shouldAddTabBarBackToTabBarController = YES;
        }
        
        // Uses linear curve for an interactive transition, so the view follows the finger. Otherwise, uses a navigation transition curve.
        UIViewAnimationOptions curveOption = [transitionContext isInteractive] ? UIViewAnimationOptionCurveLinear : SSWNavigationTransitionCurve;
        
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:UIViewAnimationOptionTransitionNone | curveOption animations:^{
            toViewController.view.transform = CGAffineTransformIdentity;
            fromViewController.view.transform = CGAffineTransformMakeTranslation(toViewController.view.frame.size.width, 0);
            dimmingView.alpha = 0.0f;
            
        } completion:^(BOOL finished) {
            if (shouldAddTabBarBackToTabBarController) {
                [tabBarController.view addSubview:tabBar];
                
                CGRect tabBarRect = tabBar.frame;
                tabBarRect.origin.x = tabBarController.view.bounds.origin.x;
                tabBar.frame = tabBarRect;
            }
            
            [dimmingView removeFromSuperview];
            fromViewController.view.transform = CGAffineTransformIdentity;
            fromViewController.view.clipsToBounds = previousClipsToBounds;
            
            toViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }

    self.fromViewController = fromViewController;
    self.toViewController = toViewController;
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    // restore the toViewController's transform if the animation was cancelled
    if (!transitionCompleted) {
        // NSLog(@"we got canceled rip");
    }
}

@end
