//
//  UIScrollView+ContentInsetFix.h
//  Pulse
//
//  Created by Austin Valleskey on 12/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIScrollView (ContentInsetFix)

- (void)updateContentInsetsWithPadding:(UIEdgeInsets)paddingInsets;

@end

NS_ASSUME_NONNULL_END
