//
//  UIView+RoundedCorners.m
//  Pulse
//
//  Created by Austin Valleskey on 1/26/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import "UIView+RoundedCorners.h"

@implementation UIView (RoundedCorners)

-(void)setRoundedCorners:(UIRectCorner)corners radius:(CGFloat)radius {
    CGRect rect = self.bounds;

    // Create the path
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];

    // Create the shape layer and set its path
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    maskLayer.frame = rect;
    maskLayer.path = maskPath.CGPath;

    // Set the newly created shape layer as the mask for the view's layer
    self.layer.mask = maskLayer;
}

@end
