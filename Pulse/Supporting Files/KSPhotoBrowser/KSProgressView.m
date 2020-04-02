//
//  KSProgressView.m
//  KSPhotoBrowser
//
//  Created by Kyle Sun on 30/12/2016.
//  Copyright © 2016 Kyle Sun. All rights reserved.
//

#import "KSProgressView.h"
#import "UIColor+Palette.h"

@interface KSProgressView ()

@property (nonatomic, assign) BOOL isSpinning;
@property (nonatomic, strong) UIImageView *spinner;

@end

@implementation KSProgressView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.hidden = true;
        self.alpha = 0;
        
        self.spinner = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"spinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.spinner.bounds = self.bounds;
        self.spinner.tintColor = [UIColor colorWithWhite:0.5 alpha:1];
        [self addSubview:self.spinner];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    if (self.isSpinning) {
        [self startSpin];
    }
}

- (void)setIsSpinning:(BOOL)isSpinning {
    if (isSpinning != _isSpinning) {
        _isSpinning = isSpinning;
        
        if (isSpinning) {
            CABasicAnimation *rotationAnimation;
            rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
            rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
            rotationAnimation.duration = 0.8f;
            rotationAnimation.cumulative = YES;
            rotationAnimation.repeatCount = HUGE_VALF;
            [self.spinner.layer addAnimation:rotationAnimation forKey:@"spinning"];
        }
        else {
            [self.spinner.layer removeAnimationForKey:@"spinning"];
        }
    }
}

- (void)startSpin {
    self.isSpinning = YES;
        
    self.hidden = false;
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 0.5;
    } completion:^(BOOL finished) {
        
    }];
}

- (void)stopSpin {
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = true;
        
        self.isSpinning = NO;
    }];
}

@end
