//
//  UIView+Guides.h
//  Pulse
//
//  Created by Austin Valleskey on 5/18/20.
//  Copyright © 2020 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (Guides)

- (void)addGuideAtX:(CGFloat)x;
- (void)addGuideAtY:(CGFloat)y;

@end

NS_ASSUME_NONNULL_END
