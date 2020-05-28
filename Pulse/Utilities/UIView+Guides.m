//
//  UIView+Guides.m
//  Pulse
//
//  Created by Austin Valleskey on 5/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "UIView+Guides.h"

@implementation UIView (Guides)

- (void)addGuideAtX:(CGFloat)x {
    UIView *controlsGuideLine = [self newLineView];
    controlsGuideLine.userInteractionEnabled = false;
    controlsGuideLine.frame = CGRectMake(x - HALF_PIXEL, 0, HALF_PIXEL * 2, self.frame.size.height);
    [self addSubview:controlsGuideLine];
}
- (void)addGuideAtY:(CGFloat)y {
    UIView *controlsGuideLine = [self newLineView];
    controlsGuideLine.frame = CGRectMake(0, y - HALF_PIXEL, self.frame.size.width, HALF_PIXEL * 2);
    [self addSubview:controlsGuideLine];
}

#pragma mark -
- (UIView *)newLineView {
    UIView *lineView = [UIView new];
    lineView.backgroundColor = [UIColor colorWithRed:1 green:0 blue:0.2 alpha:0.5];
    return lineView;
}

@end
