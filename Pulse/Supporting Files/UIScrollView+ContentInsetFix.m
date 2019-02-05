//
//  UIScrollView+ContentInsetFix.m
//  Pulse
//
//  Created by Austin Valleskey on 12/27/18.
//  Copyright © 2018 Austin Valleskey. All rights reserved.
//

#import "UIScrollView+ContentInsetFix.h"

#define UIViewParentController(__view) ({ \
                                        UIResponder *__responder = __view; \
                                        while ([__responder isKindOfClass:[UIView class]]) \
                                        __responder = [__responder nextResponder]; \
                                        (UIViewController *)__responder; \
                                        })

@implementation UIScrollView (ContentInsetFix)

- (void)updateContentInsetsWithPadding:(UIEdgeInsets)paddingInsets {
    UIViewController *parentController = UIViewParentController(self);
    UIEdgeInsets windowInsets = [UIApplication sharedApplication].delegate.window.safeAreaInsets;
    
    self.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    UIEdgeInsets baselineInsets = UIEdgeInsetsMake(windowInsets.top + parentController.navigationController.navigationBar.frame.size.height, windowInsets.left, parentController.tabBarController.tabBar.frame.size.height + windowInsets.bottom, windowInsets.right);
    self.contentInset = UIEdgeInsetsMake(baselineInsets.top + paddingInsets.top, baselineInsets.left + paddingInsets.left, baselineInsets.bottom + paddingInsets.bottom, baselineInsets.right + paddingInsets.right);
    self.scrollIndicatorInsets = baselineInsets;
}

@end
