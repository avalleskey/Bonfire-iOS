//
//  TappableView.m
//  Pulse
//
//  Created by Austin Valleskey on 12/14/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "TappableView.h"

@implementation TappableView

- (id)init {
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}
- (id)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}
- (void)setup {
    self.userInteractionEnabled = true;
    
    self.contentView = [[UIView alloc] initWithFrame:self.bounds];
    [self addSubview:self.contentView];
}
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.contentView.frame = self.bounds;
}

-(BOOL) pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
    CGRect newArea = CGRectMake(self.bounds.origin.x - 5, self.bounds.origin.y - 5, self.bounds.size.width + 10, self.bounds.size.height + 10);
    
    return CGRectContainsPoint(newArea, point);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.touchDown = YES;
    
    if (self.shrink) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 0.25;
            self.contentView.transform = CGAffineTransformMakeScale(0.8, 0.8);
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f animations:^{
            self.alpha = 0.25;
        }];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered when touch is released
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Triggered if touch leaves view
    if (self.touchDown) {
        self.touchDown = NO;
        
        [self touchCancel];
    }
}

- (void)touchCancel {
    if (self.shrink) {
        [UIView animateWithDuration:0.4f delay:0 usingSpringWithDamping:0.8f initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 1;
            self.contentView.transform = CGAffineTransformMakeScale(1, 1);
        } completion:nil];
    }
    else {
        [UIView animateWithDuration:0.2f animations:^{
            self.alpha = 1;
        }];
    }
}

@end
