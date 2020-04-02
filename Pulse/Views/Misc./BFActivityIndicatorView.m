//
//  BFActivityIndicatorView.m
//  Pulse
//
//  Created by Austin Valleskey on 3/6/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "BFActivityIndicatorView.h"
#import "UIColor+Palette.h"

@interface BFActivityIndicatorView ()

@property (nonatomic, strong) UIImageView *spinnerView;

@property (readwrite, assign, getter=isAnimating) BOOL animating;

@end

@implementation BFActivityIndicatorView

static NSString * const rotationAnimationKey = @"rotationAnimation";

- (id)init {
    return [self initWithStyle:BFActivityIndicatorViewStyleSmall];
}
- (id)initWithStyle:(BFActivityIndicatorViewStyle)style {
    if (self = [super init]) {
        [self setup];
        
        self.frame = CGRectMake(0, 0, self.spinnerView.frame.size.width, self.spinnerView.frame.size.height);
        self.color = [[UIColor bonfireSecondaryColor] colorWithAlphaComponent:0.5];
        
        self.style = style;
    }
    
    return self;
}

- (void)setup {
    self.spinnerView = [[UIImageView alloc] init];
    self.spinnerView.contentMode = UIViewContentModeScaleAspectFill;
    [self addSubview:self.spinnerView];
    
    [self startAnimating];
}

- (void)setColor:(UIColor *)color {
    if (color != _color) {
        _color = color;
        
        self.spinnerView.tintColor = color;
    }
}

- (void)dealloc {
    [self stopAnimating];
    [self removeForegroundObserver];
}

- (void)setStyle:(BFActivityIndicatorViewStyle)style {
    if (style != _style || self.spinnerView.image == nil)  {
        _style = style;
        
        switch (style) {
            case BFActivityIndicatorViewStyleSmall:
                self.spinnerView.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.spinnerView.frame = CGRectMake(0, 0, 22, 22);
                break;
            case BFActivityIndicatorViewStyleLarge:
                self.spinnerView.image = [[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                self.spinnerView.frame = CGRectMake(0, 0, 42, 42);
                break;
                
            default:
                break;
        }
        
        [self layoutSubviews];
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.spinnerView.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

- (BOOL)isAnimating {
    return _animating;
}
- (void)startAnimating {
    if (![self.spinnerView.layer animationForKey:rotationAnimationKey]) {
        self.animating = true;
        
        CABasicAnimation *rotationAnimation;
        rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
        rotationAnimation.duration = 0.75f;
        rotationAnimation.cumulative = YES;
        rotationAnimation.repeatCount = HUGE_VALF;
        
        [self.spinnerView.layer removeAnimationForKey:rotationAnimationKey];
        [self.spinnerView.layer addAnimation:rotationAnimation forKey:rotationAnimationKey];
        
        [self addForegroundObserver];
    }
    
}
- (void)stopAnimating {
    self.animating = false;
    
    [self.spinnerView.layer removeAnimationForKey:rotationAnimationKey];
    
    [self removeForegroundObserver];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];
    
    if (hidden) {
        [self stopAnimating];
    }
    else {
        [self startAnimating];
    }
}

- (void)addForegroundObserver {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnimating) name:@"applicationWillEnterForeground" object:nil];
}
- (void)removeForegroundObserver {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"applicationWillEnterForeground" object:nil];
}

@end
