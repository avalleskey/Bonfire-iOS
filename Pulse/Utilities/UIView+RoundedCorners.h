//
//  UIView+RoundedCorners.h
//  Pulse
//
//  Created by Austin Valleskey on 1/26/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (RoundedCorners)

-(void)setRoundedCorners:(UIRectCorner)corners radius:(CGFloat)radius;

@end

NS_ASSUME_NONNULL_END
