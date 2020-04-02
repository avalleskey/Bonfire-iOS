//
//  BFCameraSwiper.m
//

#import "BFCameraAnimator.h"
#import "BFCameraSwiper.h"
#import "SSWDirectionalPanGestureRecognizer.h"
#import "UIColor+Palette.h"
#import "Launcher.h"

@interface BFCameraSwiper() <UIGestureRecognizerDelegate, BFCameraAnimatorDelegate>
//@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (weak, readwrite, nonatomic) UIPanGestureRecognizer *dismissRecognizer;
@property (weak, nonatomic) IBOutlet UIViewController *viewController;
@property (strong, nonatomic) BFCameraAnimator *animator;
@property (strong, nonatomic) UIPercentDrivenInteractiveTransition *interactionController;
/// A Boolean value that indicates whether the view controller is currently animating.
@property (nonatomic) BOOL duringAnimation;
@end

@implementation BFCameraSwiper

#pragma mark - Lifecycle

- (void)dealloc
{
    //[_panRecognizer removeTarget:self action:@selector(pan:)];
    //[_navigationController.view removeGestureRecognizer:_panRecognizer];
    
    [_dismissRecognizer removeTarget:self action:@selector(pan:)];
    [_viewController.view removeGestureRecognizer:_dismissRecognizer];
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
    NSCParameterAssert(!!viewController);

    self = [super init];
    if (self) {
        _viewController = viewController;
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
    SSWDirectionalPanGestureRecognizer *dismissRecognizer = [[SSWDirectionalPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
    dismissRecognizer.direction = SSWPanDirectionDown;
    dismissRecognizer.maximumNumberOfTouches = 1;
    dismissRecognizer.delegate = self;

    [_viewController.view addGestureRecognizer:dismissRecognizer];
    _dismissRecognizer = dismissRecognizer;

    _animator = [[BFCameraAnimator alloc] init];
    _animator.delegate = self;
}

#pragma mark - UIPanGestureRecognizer

- (void)pan:(UIPanGestureRecognizer*)recognizer
{
    UIView *view = self.viewController.view;
    
    if (recognizer == self.dismissRecognizer) {
        if (recognizer.state == UIGestureRecognizerStateBegan) {
            if (self.viewController.presentingViewController && !self.duringAnimation) {
                self.interactionController = [[UIPercentDrivenInteractiveTransition alloc] init];
                self.interactionController.completionCurve = UIViewAnimationCurveEaseOut;
                
                [self.viewController dismissViewControllerAnimated:YES completion:nil];
            }
        } else if (recognizer.state == UIGestureRecognizerStateChanged) {
            CGPoint translation = [recognizer translationInView:view];
            // Cumulative translation.x can be less than zero because user can pan slightly to the right and then back to the left.
            CGFloat d = translation.y > 0 ? translation.y / CGRectGetHeight(view.bounds) : 0;
            
            NSLog(@"d: %f", d);
            [self.interactionController updateInteractiveTransition:MIN(1, d)];
        } else if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
            NSLog(@"v: %f", [recognizer velocityInView:view].y);
            if ([recognizer velocityInView:view].y > 0) {
                [self.interactionController finishInteractiveTransition];
            } else {
                [self.interactionController cancelInteractiveTransition];
            }
            self.interactionController = nil;
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

-(BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer == _dismissRecognizer)
        return self.viewController.presentingViewController;
        
    return false;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForPresentedController:(UIViewController *)presented presentingController:(UIViewController *)presenting sourceController:(UIViewController *)source {
    self.animator.appearing = true;
    return self.animator;
}

- (id<UIViewControllerAnimatedTransitioning>)animationControllerForDismissedController:(UIViewController *)dismissed
{
    id<UIViewControllerAnimatedTransitioning> animationController;
    
    self.animator.appearing = false;
    animationController = self.animator;
    
    return animationController;
}

- (id<UIViewControllerInteractiveTransitioning>)interactionControllerForPresentation:(id<UIViewControllerAnimatedTransitioning>)animator {
    return self.interactionController;
}

- (nullable id <UIViewControllerInteractiveTransitioning>)interactionControllerForDismissal:(id <UIViewControllerAnimatedTransitioning>)animator {
    return self.interactionController;
}

@end
