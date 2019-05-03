//
//  BFRefreshControl.m
//  Pulse
//
//  Created by Austin Valleskey on 4/6/19.
//  Copyright © 2019 Austin Valleskey. All rights reserved.
//

#import "BFRefreshControl.h"
#import "UIColor+Palette.h"
#import <HapticHelper/HapticHelper.h>

@implementation BFRefreshControl

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    self.firesOnRelease = YES;
    
    self.threshold = -64.f;
    self.referenceContentInsetTop = 0;
    
    self.miniSpinner = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
    self.miniSpinner.contentMode = UIViewContentModeScaleAspectFill;
    self.miniSpinner.image = [[UIImage imageNamed:@"miniSpinner"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.miniSpinner.tintColor = [UIColor bonfireGray];
    [self addSubview:self.miniSpinner];
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    self.backgroundView.backgroundColor = [UIColor separatorColor];
    self.backgroundView.layer.cornerRadius = self.backgroundView.frame.size.height / 2;
    self.backgroundView.layer.masksToBounds = true;
    //[self addSubview:self.backgroundView];
    
    self.progressView = [[UIView alloc] initWithFrame:CGRectMake(0, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height)];
    self.progressView.backgroundColor = [UIColor bonfireBlack];
    self.progressView.layer.cornerRadius = self.progressView.frame.size.height / 2;
    self.progressView.layer.masksToBounds = true;
    //[self.backgroundView addSubview:self.progressView];
    
    currentColor = 0;
    colors = @[[UIColor bonfireBlueWithLevel:500],  // 0
               [UIColor bonfireViolet],  // 1
               [UIColor bonfireRed],  // 2
               [UIColor bonfireOrange],  // 3
               [UIColor colorWithRed:0.16 green:0.72 blue:0.01 alpha:1.00], // cash green
               [UIColor brownColor],  // 5
               [UIColor colorWithRed:0.96 green:0.76 blue:0.23 alpha:1.00],  // 6
               [UIColor bonfireCyanWithLevel:800],  // 7
               [UIColor bonfireGrayWithLevel:900]]; // 8
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.backgroundView.frame = CGRectMake(self.frame.size.width / 2 - self.backgroundView.frame.size.width / 2, self.frame.size.height / 2 - self.backgroundView.frame.size.height / 2, self.backgroundView.frame.size.width, self.backgroundView.frame.size.height);
    self.miniSpinner.center = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
}

#pragma mark - ISAlternativeRefreshControl events

- (void)didChangeProgress
{
    if (self.refreshingState == ISRefreshingStateNormal) {
        CGFloat progress = (self.progress - .5f) / .5f;
        //CGFloat finalTransform = 4.f;
        
        if (progress > 1.f) {
            progress = 1.f;
        }
        
        //CGFloat transform = 1 + ((finalTransform - 1) * progress);
        if (progress == 1 && self.miniSpinner.alpha < 1) {
            [HapticHelper generateFeedback:FeedbackType_Selection];
        }
        
        //self.progressView.transform = CGAffineTransformMakeScale(transform, transform);
        
        CGAffineTransform rotate = CGAffineTransformMakeRotation(M_PI * 2.0 * progress);

        self.miniSpinner.transform = rotate;
        self.miniSpinner.alpha = progress;
    }
}

- (void)willChangeRefreshingState:(ISRefreshingState)refreshingState
{
    switch (refreshingState) {
        case ISRefreshingStateNormal:
            [self stopAnimating];
            self.progressView.transform = CGAffineTransformIdentity;
            break;
            
        case ISRefreshingStateRefreshing:
            [self startAnimating];
            break;
            
        case ISRefreshingStateRefreshed:
            //[self stopAnimating];
            break;
            
        default: break;
    }
}

- (void)startAnimating {
    // [self spawnProgressCircle];
    
    CABasicAnimation *rotationAnimation;
    rotationAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
    rotationAnimation.toValue = [NSNumber numberWithFloat: M_PI * 2.0 /* full rotation*/ * 1 * 1.f ];
    rotationAnimation.duration = 1.f;
    rotationAnimation.cumulative = YES;
    rotationAnimation.repeatCount = HUGE_VALF;
    
    [self.miniSpinner.layer addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}
- (void)spawnProgressCircle {
    UIView *progressCircle = [[UIView alloc] init];
    
    progressCircle.backgroundColor = colors[currentColor];
    currentColor = currentColor + 1;
    
    switch (currentColor % 4) {
        case 0:
            progressCircle.frame = CGRectMake(-self.backgroundView.frame.size.width, 0, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height);
            break;
        case 1:
            progressCircle.frame = CGRectMake(0, -self.backgroundView.frame.size.height, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height);
            break;
        case 2:
            progressCircle.frame = CGRectMake(self.backgroundView.frame.size.width, 0, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height);
            break;
        case 3:
            progressCircle.frame = CGRectMake(0, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height, self.backgroundView.frame.size.height);
            break;
            
        default:
            break;
    }
    
    if (currentColor >= colors.count) currentColor = 0;
    
    progressCircle.layer.cornerRadius = progressCircle.frame.size.height / 2;
    [self.backgroundView addSubview:progressCircle];
    
    [UIView animateWithDuration:0.3f delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        progressCircle.transform = CGAffineTransformMakeScale(4, 4);
    } completion:^(BOOL finished) {
        // remove circle under it, if there is one
        for (UIView *subview in self.backgroundView.subviews) {
            if (subview != progressCircle && subview != self.progressView) {
                [subview removeFromSuperview];
            }
        }
        if (self.refreshingState != ISRefreshingStateNormal) {
            [self spawnProgressCircle];
        }
    }];
}

- (void)stopAnimating {
    [self.miniSpinner.layer removeAllAnimations];
    self.miniSpinner.transform = CGAffineTransformIdentity;
    
    [self.progressView.layer removeAllAnimations];
    self.progressView.transform = CGAffineTransformIdentity;
    currentColor = 0;
    for (UIView *subview in self.backgroundView.subviews) {
        if (subview != self.progressView) {
            [subview removeFromSuperview];
        }
    }
}

- (void)endRefreshingWithDelay:(BOOL)delay {
    double delayInSeconds = delay ? 1.2f : 0.4f;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self endRefreshing];
    });
}

@end
