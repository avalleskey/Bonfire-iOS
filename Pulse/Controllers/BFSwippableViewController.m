//
//  BFSwippableViewController.m
//  Pulse
//
//  Created by Austin Valleskey on 5/17/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFSwippableViewController.h"
#import "UIColor+Palette.h"
#import <SKInnerShadowLayer/SKInnerShadowLayer.h>
#import <BlocksKit/BlocksKit.h>
#import <BlocksKit/BlocksKit+UIKit.h>

@interface BFSwippableViewController ()

@property (nonatomic) CGPoint centerBegin;
@property (nonatomic) CGPoint centerFinal;
@property (nonatomic) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) SKInnerShadowLayer *innerShadowLayer;

@property (nonatomic) UIView *senderView_superview;
@property (nonatomic) CGRect senderView_frame;
@property (nonatomic) CGAffineTransform senderView_transform;
@property (nonatomic) BOOL senderView_userInteraction;
@property (nonatomic) CGFloat senderView_alpha;

@property (nonatomic, strong) CAGradientLayer *topGradientLayer;
@property (nonatomic, strong) CAGradientLayer *bottomGradientLayer;

@property (nonatomic) BOOL spinning;

@end

@implementation BFSwippableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initContentView];
    [self initDragToDismiss];
    [self initCloseButton];
    
    if (self.senderView) {
        [self addSenderView];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if ([self isBeingPresented] || [self isMovingToParentViewController]) {
        [self setNeedsStatusBarAppearanceUpdate];
        
        UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
        
        [UIView animateWithDuration:0.4f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1];
        } completion:nil];
        
        self.contentView.frame = CGRectMake(0, 0, self.contentView.frame.size.width, self.contentView.frame.size.height);
        if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
            self.contentView.center = self.centerLaunch;
            self.contentView.transform = CGAffineTransformMakeScale(0.001, 0.001);
            self.contentView.alpha = 0;
        }
        else {
            self.contentView.center = CGPointMake([UIScreen mainScreen].bounds.size.width / 2, [UIScreen mainScreen].bounds.size.height * 1.5);
        }
            
        [UIView animateWithDuration:0.075f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.alpha = 1;
        } completion:nil];
        [UIView animateWithDuration:0.5f delay:0 usingSpringWithDamping:0.85f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.contentView.transform = CGAffineTransformMakeScale(1, 1);
            self.contentView.center = CGPointMake(self.view.frame.size.width / 2, (HAS_ROUNDED_CORNERS ? safeAreaInsets.top : 0) +  ((self.view.frame.size.height - (HAS_ROUNDED_CORNERS ? safeAreaInsets.top + safeAreaInsets.bottom : 0)) / 2));
            
            if (self.senderView) {
                if (self.senderViewFinalState) {
                    self.senderViewFinalState();
                }
                else {
                    self.senderView.alpha = 0;
                    self.senderView.transform = CGAffineTransformMakeScale(0.75, 0.75);
                }
            }
        } completion:^(BOOL finished) {
        }];
    }
    
    if (self.loading) {
        [self.contentView bringSubviewToFront:self.spinner];
        [self.spinner startAnimating];
    }
}
- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if ([self.spinner isAnimating]) {
        [self.spinner stopAnimating];
    }
}

- (void)initContentView {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
    
    UIEdgeInsets safeAreaInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    
    CGFloat cameraHeight = self.view.frame.size.height - (HAS_ROUNDED_CORNERS ? safeAreaInsets.top + safeAreaInsets.bottom : 0);
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.width, self.view.frame.size.width, cameraHeight)];
    [self continuityRadiusForView:self.contentView withRadius:HAS_ROUNDED_CORNERS?32.f:8.f];
    self.contentView.backgroundColor = [UIColor cardBackgroundColor];
    [self.view addSubview:self.contentView];
    
    self.contentOverlayView = [[UIView alloc] initWithFrame:self.contentView.bounds];
    [self.contentView addSubview:self.contentOverlayView];
    
    self.innerShadow = true;
}

- (void)setInnerShadow:(BOOL)innerShadow {
    if (innerShadow != _innerShadow) {
        _innerShadow = innerShadow;
        
        if (self.innerShadowLayer && !innerShadow) {
            [self.innerShadowLayer removeFromSuperlayer];
            self.innerShadowLayer = nil;
        }
        else if (!self.innerShadowLayer && innerShadow) {
            self.innerShadowLayer = [[SKInnerShadowLayer alloc] init];
            self.innerShadowLayer.frame = self.contentView.bounds;
            self.innerShadowLayer.cornerRadius = HAS_ROUNDED_CORNERS?32.f:8.f;
            self.innerShadowLayer.innerShadowColor = [UIColor whiteColor].CGColor;
            self.innerShadowLayer.innerShadowOffset = CGSizeMake(0, 2);
            self.innerShadowLayer.innerShadowRadius = 3;
            self.innerShadowLayer.innerShadowOpacity = 0.4;
            [self.contentOverlayView.layer addSublayer:self.innerShadowLayer];
        }
    }
}

- (void)initCloseButton {
    self.closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.closeButton setImage:[[UIImage imageNamed:@"navCloseIcon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 44 - 11, 12, 44, 44);
    self.closeButton.tintColor = [UIColor bonfirePrimaryColor];
    self.closeButton.adjustsImageWhenHighlighted = false;
    self.closeButton.contentMode = UIViewContentModeCenter;
    [self.closeButton bk_whenTapped:^{
        [self dismissWithCompletion:nil];
    }];
    [self.contentOverlayView addSubview:self.closeButton];
}
- (void)setShowCloseButtonShadow:(BOOL)showCloseButtonShadow {
    if (showCloseButtonShadow != _showCloseButtonShadow) {
        _showCloseButtonShadow = showCloseButtonShadow;
        
        if (showCloseButtonShadow) {
            self.closeButton.layer.shadowOffset = CGSizeMake(0, 1);
            self.closeButton.layer.shadowColor = [UIColor blackColor].CGColor;
            self.closeButton.layer.shadowOpacity = 0.16;
            self.closeButton.layer.shadowRadius = 2.f;
        }
        else {
            self.closeButton.layer.shadowOpacity = 0;
        }
    }
}

- (void)addSenderView {
    if (!self.senderView) {
        return;
    }
    else if (CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
        self.senderView = nil;
        return;
    }
    
    self.senderView_superview = self.senderView.superview;
    self.senderView_frame = self.senderView.frame;
    self.senderView_transform = self.senderView.transform;
    self.senderView_userInteraction = self.senderView.userInteractionEnabled;
    self.senderView_alpha = self.senderView.alpha;
    
    if (self.senderViewFinalState) {
        self.senderView.frame = [self.senderView_superview convertRect:self.senderView_frame toView:self.view];
        self.senderView.userInteractionEnabled = false;
        [self.contentOverlayView addSubview:self.senderView];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}
- (BOOL)prefersStatusBarHidden {
    return self.hideStatusBar;
}
- (void)setHideStatusBar:(BOOL)hideStatusBar {
    if (hideStatusBar != _hideStatusBar) {
        _hideStatusBar = hideStatusBar;
        
        [self setNeedsStatusBarAppearanceUpdate];
    }
}

- (void)initDragToDismiss {
    self.panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    [self.panRecognizer setMinimumNumberOfTouches:1];
    [self.panRecognizer setMaximumNumberOfTouches:1];
    [self.contentView addGestureRecognizer:self.panRecognizer];
}
- (void)removeDragToDismiss {
    for (UIGestureRecognizer *gestureRecognizer in self.contentView.gestureRecognizers) {
        [self.contentView removeGestureRecognizer:gestureRecognizer];
    }
}
- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.closeButton.alpha = 0;
        } completion:^(BOOL finished) {
            
        }];
        
        self.centerBegin = recognizer.view.center;
        self.centerFinal = CGPointMake(self.centerBegin.x, self.centerBegin.y + (self.contentView.frame.size.height / 6));
    }
    else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:self.view];
        if (translation.y > 0 || recognizer.view.center.y >= self.centerBegin.y) {
            CGFloat newCenterY = recognizer.view.center.y + translation.y;
            CGFloat diff = fabs(_centerBegin.y - newCenterY);
            CGFloat max = self.centerFinal.y - self.centerBegin.y;
            CGFloat percentage = CLAMP(diff / max, 0, 1);
            newCenterY = recognizer.view.center.y + (translation.y / (1 + 6 * percentage));

            recognizer.view.center = CGPointMake(recognizer.view.center.x,
                                                 newCenterY);
            
            [recognizer setTranslation:CGPointMake(0, 0) inView:self.view];
            
            percentage = MAX(0, MIN(1, (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y)));
            
            if (percentage > 0) {
                CGFloat minScale = 0.92;
                CGFloat minAlpha = 0.8;
                
                recognizer.view.transform = CGAffineTransformMakeScale(1.0 - (1.0 - minScale) * percentage, 1.0 - (1.0 - minScale) * percentage);
                self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:1.0 - (1.0 - minAlpha) * percentage];
            }
        }
    }
    else if (recognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint velocity = [recognizer velocityInView:self.view];
        
        CGFloat percentage = (recognizer.view.center.y - self.centerBegin.y) / (self.centerFinal.y - self.centerBegin.y);
        
        CGFloat fromCenterY = fabs(self.centerBegin.y - recognizer.view.center.y);
        CGFloat duration = 0.15+(0.05*(fromCenterY/60));
                
        if (percentage >= 0.35 || velocity.y > self.centerFinal.y - self.centerBegin.y) {
            [self dismissWithCompletion:nil];
        }
        else {
            [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                recognizer.view.center = self.centerBegin;
                recognizer.view.transform = CGAffineTransformIdentity;
                self.view.backgroundColor = [UIColor blackColor];
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
                    self.closeButton.alpha = 1;
                } completion:nil];
            }];
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(draggableView:didPan:)]) {
        [self.delegate draggableView:self.contentView didPan:recognizer];
    }
}

- (void)dismissWithCompletion:(void (^ _Nullable)(void))handler {
    self.view.userInteractionEnabled = false;
    if ([self.delegate respondsToSelector:@selector(swipeableViewControllerWillDismiss)]) {
        [self.delegate swipeableViewControllerWillDismiss];
    }
    
    CGPoint centerDestination = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height * 1.5);
    if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
        centerDestination = self.centerLaunch;
        
        [UIView animateWithDuration:0.1f delay:0.25f usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
                self.contentView.alpha = 0;
            }
        } completion:^(BOOL finished) {
        }];
    }
    
    if (self.senderView && self.senderViewFinalState) {
        [self.view addSubview:self.senderView];
        self.senderView.frame = [self.contentView convertRect:self.senderView.frame toView:self.view];
    }
    [UIView animateWithDuration:0.35f delay:0 usingSpringWithDamping:1 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
        self.contentView.center = centerDestination;
        
        if (self.senderView) {
            self.senderView.transform = self.senderView_transform;
            self.senderView.alpha = self.senderView_alpha;
            
            if (self.senderViewFinalState) {
                self.senderView.frame = self.senderView_frame;
                self.senderView.center = self.centerLaunch;
            }
        }
        
        if (!CGPointEqualToPoint(self.centerLaunch, CGPointZero)) {
            self.contentView.transform = CGAffineTransformMakeScale(0.001, 0.001);
        }
    } completion:^(BOOL finished) {
        if (self.senderViewFinalState) {
            self.senderView.frame =  [self.view convertRect:self.senderView.frame toView:self.senderView_superview];
            [self.senderView_superview addSubview:self.senderView];
        }
        
        self.senderView.userInteractionEnabled = self.senderView_userInteraction;
        
        [self dismissViewControllerAnimated:false completion:^{
            if (handler) {
                handler();
            }
            
            if ([self.delegate respondsToSelector:@selector(swipeableViewControllerDidDisappear)]) {
                [self.delegate swipeableViewControllerDidDisappear];
            }
        }];
    }];
}

- (void)continuityRadiusForView:(UIView *)sender withRadius:(CGFloat)radius {
    CAShapeLayer * maskLayer = [CAShapeLayer layer];
    maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:sender.bounds
                                           byRoundingCorners:UIRectCornerBottomLeft|UIRectCornerBottomRight|UIRectCornerTopLeft|UIRectCornerTopRight
                                                 cornerRadii:CGSizeMake(radius, radius)].CGPath;
    
    sender.layer.mask = maskLayer;
}

- (void)setTopGradientColor:(UIColor *)color length:(CGFloat)length {
    if (self.topGradientLayer) {
        [self.topGradientLayer removeFromSuperlayer];
    }
    else {
        self.topGradientLayer = [CAGradientLayer layer];
        [self.contentOverlayView.layer insertSublayer:self.topGradientLayer atIndex:0];
    }
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)color.CGColor, (id)[color colorWithAlphaComponent:0].CGColor, nil];

    self.topGradientLayer.colors = gradientColors;
    self.topGradientLayer.startPoint = CGPointMake(0, 0);
    self.topGradientLayer.endPoint = CGPointMake(0, length);
    self.topGradientLayer.frame = self.contentView.bounds;
}

- (void)setBottomGradientColor:(UIColor *)color length:(CGFloat)length {
    if (self.bottomGradientLayer) {
        [self.bottomGradientLayer removeFromSuperlayer];
    }
    else {
        self.bottomGradientLayer = [CAGradientLayer layer];
        [self.contentOverlayView.layer insertSublayer:self.bottomGradientLayer atIndex:0];
    }
    
    NSArray *gradientColors = [NSArray arrayWithObjects:(id)color.CGColor, (id)[color colorWithAlphaComponent:0].CGColor, nil];

    self.bottomGradientLayer.colors = gradientColors;
    self.bottomGradientLayer.startPoint = CGPointMake(0, 1);
    self.bottomGradientLayer.endPoint = CGPointMake(0, 1-length);
    self.bottomGradientLayer.frame = self.contentView.bounds;
}

- (void)initSpinner {
    self.spinner = [[BFActivityIndicatorView alloc] initWithStyle:BFActivityIndicatorViewStyleLarge];
    self.spinner.frame = CGRectMake(0, 0, 128, 128);
    self.spinner.color = [UIColor bonfirePrimaryColor];
    self.spinner.center = CGPointMake(self.contentView.frame.size.width / 2, self.contentView.frame.size.height / 2);
    self.spinner.alpha = 0;

    [self.contentView addSubview:self.spinner];
}
- (void)setSpinning:(BOOL)spinning {
    [self setSpinning:spinning animated:false];
}

- (void)setSpinning:(BOOL)spinning animated:(BOOL)animated {
    if (spinning != _spinning) {
        _spinning = spinning;
    }

    if (spinning) {
        [self.contentView bringSubviewToFront:self.spinner];

        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.spinner.alpha = 1;
            self.spinner.transform = CGAffineTransformMakeScale(1, 1);
        } completion:^(BOOL finished) {

        }];
    }
    else {
        [UIView animateWithDuration:animated?0.4f:0 delay:0 usingSpringWithDamping:0.75f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.spinner.alpha = 0;
            self.spinner.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:^(BOOL finished) {
            [self.spinner stopAnimating];
            self.view.userInteractionEnabled = true;
        }];
    }
}

- (void)setLoading:(BOOL)loading {
    if (loading != _loading) {
        _loading = loading;
        
        if (loading && !_spinner) {
            [self initSpinner];
        }
    }

    if (self.spinning != _loading) {
        [self setSpinning:_loading animated:true];
    }
}

@end
