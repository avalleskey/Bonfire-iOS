//
//  SloppySwiper.m
//
//  Created by Arkadiusz Holko http://holko.pl on 29-05-14.
//

#import "SloppySwiper.h"
#import "SSWAnimator.h"
#import "SSWDirectionalPanGestureRecognizer.h"
#import "UIColor+Palette.h"

@interface SloppySwiper() <UIGestureRecognizerDelegate, SSWAnimatorDelegate>
//@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *dismissRecognizer;
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
    //[_panRecognizer removeTarget:self action:@selector(pan:)];
    //[_navigationController.view removeGestureRecognizer:_panRecognizer];
    
    [_dismissRecognizer removeTarget:self action:@selector(pan:)];
    [_navigationController.view removeGestureRecognizer:_dismissRecognizer];
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
    /*SSWDirectionalPanGestureRecognizer *panRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    panRecognizer.direction = SSWPanDirectionRight;
    panRecognizer.maximumNumberOfTouches = 1;
    panRecognizer.delegate = self;
    _panRecognizer = panRecognizer;*/
    
    SSWDirectionalPanGestureRecognizer *dismissRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    dismissRecognizer.direction = SSWPanDirectionRight; // SSWPanDirectionDown;
    dismissRecognizer.maximumNumberOfTouches = 1;
    dismissRecognizer.delegate = self;
    NSLog(@"view view view :: %@", _navigationController.view);
    [_navigationController.view addGestureRecognizer:dismissRecognizer];
    _dismissRecognizer = dismissRecognizer;

    _animator = [[SSWAnimator alloc] init];
    _animator.delegate = self;
    
    NSLog(@"dismiss recognizer: : %@", dismissRecognizer);
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
        return 0.2f;
    }
}

#pragma mark - UIPanGestureRecognizer

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView *view = self.navigationController.view;
    
    if (recognizer == self.dismissRecognizer) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if (self.navigationController.presentingViewController && !self.duringAnimation) {
                NSLog(@"UIGestureRecognizerStateBegan");
                self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
                self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
                
                [self.navigationController dismissViewControllerAnimated:YES completion:nil];
            }
        } else if (recognizer.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [recognizer translationInView:view];
            // Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
            // CGFloat d = translation.y > 0 ? translation.y / CGRectGetHeight(view.bounds) : 0;
            CGFloat d = translation.x > 0 ? translation.x / CGRectGetWidth(view.bounds) : 0;
            
            [self.interactionController updateInteractiveTransition:d];
        } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
            if ([recognizer velocityInView:view].x > 0) {
                [self.interactionController finishInteractiveTransition];
            } else {
                [self.interactionController cancelInteractiveTransition];
                self.duringAnimation = NO;
            }
            self.interactionController = nil;
        }
    }
    /*
     else if (recognizer == self.panRecognizer) {
     if (recognizer.state == UIGestureRecognizerStateBegan) {
     if (self.navigationController.viewControllers.count > 1 && !self.duringAnimation) {
     self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
     self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
     
     [self.navigationController popViewControllerAnimated:YES];
     }
     } else if (recognizer.state == UIGestureRecognizerStateChanged) {
     CGPoint translation = [recognizer translationInView:view];
     // Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
     CGFloat d = translation.x > 0 ? translation.x / CGRectGetWidth(view.bounds) : 0;
     [self.interactionController updateInteractiveTransition:d];
     } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
     if ([recognizer velocityInView:view].x > 0) {
     [self.delegate didFinishSwiping];
     
     [self.interactionController finishInteractiveTransition];
     } else {
     [self.interactionController cancelInteractiveTransition];
     // When the transition is cancelled, `navigationController:didShowViewController:animated:` isn't called, so we have to maintain `duringAnimation`'s state here too.
     self.duringAnimation = NO;
     }
     self.interactionController = nil;
     }
     }
     */
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    //if (gestureRecognizer == _panRecognizer)
     //   return self.navigationController.viewControllers.count > 1;
    
    NSLog(@"presenting view controller: %@", self.navigationController.presentingViewController);
    
    if (gestureRecognizer == _dismissRecognizer)
        return self.navigationController.presentingViewController;
        
    return false;
}

#pragma mark - UINavigationControllerDelegate

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController animationControllerForOperation:(UINavigationControllerOperation)operation fromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC
{
    if (operation == UINavigationControllerOperationPop) {
        return self.animator;
    }
    
    return nil;
}

- (id<UIViewControllerInteractiveTransitioning>)navigationController:(UINavigationController *)navigationController interactionControllerForAnimationController:(id<UIViewControllerAnimatedTransitioning>)animationController
{
    NSLog(@"interactionControllerForAnimationController: %@", animationController);
    
    return self.interactionController;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (animated) {
        self.duringAnimation = YES;
    }
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    self.duringAnimation = NO;
    
    navigationController.transitioningDelegate = self;
    
    //self.panRecognizer.enabled = (navigationController.viewControllers.count > 1);
    self.dismissRecognizer.enabled = (navigationController.viewControllers.count == 1);
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    animationController = self.animator;
    
    return animationController;
}
- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    return self.interactionController;
}

@end
