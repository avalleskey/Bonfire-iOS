//
//  SloppySwiper.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SloppySwiper.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"

@interface SloppySwiper() <UIGestureRecognizerDelegate, SSWAnimatorDelegate>
@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (weak, nonatomic) IBOutlet UINavigationController *navigationController;
@property (strong, nonatomic) SSWAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the navigation controller is currently animating a push/pop operation.
@property (nonatomic) BOOL duringAnimation;
@end

@implementation SloppySwiper

#pragma mark - Lifecycle

- (void)dealloc
{
    [_panRecognizer removeTarget:self action:@selector(pan:)];
    [_navigationController.view removeGestureRecognizer:_panRecognizer];
}

- (instancetype)initWithNavigationController:(UINavigationController *)navigationController
{
    NSCParameterAssert(!!navigationController);

    self = [super init];
    if (self) {
        _navigationController = navigationController;
        [self commonInit];
    }

    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self commonInit];
}

- (void)commonInit
{
    SSWDirectionalPanGestureRecognizer *popPanRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    popPanRecognizer.direction = SSWPanDirectionRight;
    popPanRecognizer.maximumNumberOfTouches = 1;
    popPanRecognizer.delegate = self;
    [_navigationController.view addGestureRecognizer:popPanRecognizer];
    _popPanRecognizer = popPanRecognizer;
    
    /*
    SSWDirectionalPanGestureRecognizer *dismissPanRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    dismissPanRecognizer.direction = SSWPanDirectionDown;
    dismissPanRecognizer.maximumNumberOfTouches = 1;
    dismissPanRecognizer.delegate = self;
    [_navigationController.view addGestureRecognizer:dismissPanRecognizer];
    _dismissPanRecognizer = dismissPanRecognizer;*/

    _animator = [[SSWAnimator alloc] init];
    _animator.delegate = self;
}

#pragma mark - SSWAnimatorDelegate

- (BOOL)animatorShouldAnimateTabBar:(SSWAnimator *)animator {
    if ([self.delegate respondsToSelector:@selector(sloppySwiperShouldAnimateTabBar:)]) {
        return [self.delegate sloppySwiperShouldAnimateTabBar:self];
    } else {
        return YES;
    }
}

- (CGFloat)animatorTransitionDimAmount:(SSWAnimator *)animator {
    if ([self.delegate respondsToSelector:@selector(sloppySwiperTransitionDimAmount:)]) {
        return [self.delegate sloppySwiperTransitionDimAmount:self];
    } else {
        return 0.1f;
    }
}

#pragma mark - UIPanGestureRecognizer

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView *view = self.navigationController.view;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        NSLog(@"beginnnn");
        if (!self.duringAnimation) {
            if (recognizer == _popPanRecognizer && self.navigationController.viewControllers.count > 1) {
                self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
                self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
                
                [self.navigationController popViewControllerAnimated:YES];
            }
            /*
            else {
                self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
                self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
            }*/
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:view];
        // Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
        CGFloat d = translation.x > 0 ? translation.x / CGRectGetWidth(view.bounds) : 0;
        [self.interactionController updateInteractiveTransition:d];
    } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        if ([recognizer velocityInView:view].x > 0) {
            NSLog(@"finish interactive");
            [self.interactionController finishInteractiveTransition];
            
            [self.delegate didFinishSwiping];
        } else {
            NSLog(@"cancel interactive");
            [self.interactionController cancelInteractiveTransition];
            // When the transition is cancelled, `navigationController:didShowViewController:animated:` isn't called, so we have to maintain `duringAnimation`'s state here too.
            self.duringAnimation = NO;
        }
        self.interactionController = nil;
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (self.navigationController.viewControllers.count > 0) {
        return YES;
    }
    return NO;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    NSLog(@"operation: %ld", (long)operation);
    if (operation == UINavigationControllerOperationPop) {
        return self.animator;
    }
    return nil;
}
- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed {
    NSLog(@"dismissedddd");
    return self.animator;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    NSLog(@"which interaction controller");
    return self.interactionController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    NSLog(@"will show view controller");
    if (animated) {
        self.duringAnimation = YES;
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.duringAnimation = NO;
    
    self.panRecognizer.enabled = YES;
}

@end
